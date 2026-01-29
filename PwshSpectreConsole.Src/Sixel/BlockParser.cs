using System;
using System.Text;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using SixLabors.ImageSharp.Processing.Processors.Quantization;
using Color = SixLabors.ImageSharp.Color;

namespace PwshSpectreConsole;

public enum RenderMode {
    HalfBlocks = 0,
    BlockElements = 1,
    Braille = 2,
}

public static class Blocks {
    public static ConsoleImage ImageToBlocks(Image<Rgba32> image, int cellWidth, bool disableAnimation = false, RenderMode mode = RenderMode.HalfBlocks) {
        // We're going to resize the image when it's rendered, so use a copy to leave the original untouched.
        Image<Rgba32> imageClone = image.Clone();

        // Determine resized target in character cells, then convert to pixel sizes.
        (int targetCellWidth, int targetCellHeight) = SizeHelper.GetResizedCharacterCellSize(imageClone.Width, imageClone.Height, cellWidth, 0, ImageTypes.Blocks);
        int cellPixelWidth = Compatibility.GetCellSize().PixelWidth;
        int cellPixelHeight = Compatibility.GetCellSize().PixelHeight;

        // Preserve aspect ratio in image pixels: scale width to targetCellWidth*cellPixelWidth
        int scaledPixelW = targetCellWidth * cellPixelWidth;
        int scaledPixelH = Math.Max(1, (int)Math.Round((double)imageClone.Height / imageClone.Width * scaledPixelW));

        // Number of terminal character rows needed to display scaledPixelH
        int cellHeight = Math.Max(1, (int)Math.Ceiling((double)scaledPixelH / cellPixelHeight));

        // Resize image to the scaled pixel dimensions (preserve aspect ratio)
        imageClone.Mutate(ctx => {
            ctx.Resize(new ResizeOptions() {
                Size = new Size(scaledPixelW, scaledPixelH),
                PremultiplyAlpha = false,
                Mode = ResizeMode.BoxPad,
                Position = AnchorPositionMode.Center,
                PadColor = Color.Transparent,
                Sampler = KnownResamplers.Bicubic,
            });

            // Quantize colours for terminal-friendly output
            ctx.Quantize(new OctreeQuantizer(new() { MaxColors = 256 }));
        });
        var blockStrings = new List<string>();

        for (int i = 0; i < imageClone.Frames.Count; i++) {
            blockStrings.Add(ProcessFrame(imageClone.Frames[i], cellPixelWidth, cellHeight, mode));
            if (disableAnimation) {
                break;
            }
        }

        return new ConsoleImage(
            scaledPixelW,
            scaledPixelH,
            cellHeight,
            targetCellWidth,
            [.. blockStrings]);
    }
    internal static string ProcessFrame(ImageFrame<Rgba32> frame, int cellPixelWidth, int cellRows, RenderMode mode) {
        return mode switch {
            RenderMode.Braille => ProcessFrameBraille(frame, cellPixelWidth, cellRows),
            RenderMode.BlockElements => ProcessFrameBlockElements(frame, cellPixelWidth, cellRows),
            RenderMode.HalfBlocks => ProcessFrameHalfBlocks(frame, cellPixelWidth, cellRows),
            _ => ProcessFrameHalfBlocks(frame, cellPixelWidth, cellRows),
        };
    }

    private static string ProcessFrameHalfBlocks(ImageFrame<Rgba32> frame, int cellPixelWidth, int cellRows) {
        var _buffer = new StringBuilder();
        int width = frame.Width;
        int height = frame.Height;

        for (int row = 0; row < cellRows; row++) {
            int yTop = Math.Clamp((int)Math.Round((row + 0.25) * height / cellRows), 0, height - 1);
            int yBottom = Math.Clamp((int)Math.Round((row + 0.75) * height / cellRows), 0, height - 1);

            for (int xCell = 0; xCell < width; xCell += cellPixelWidth) {
                int sampleX = xCell + (cellPixelWidth / 2);
                if (sampleX >= width) sampleX = width - 1;

                Rgba32 topPixel = frame[sampleX, yTop];
                Rgba32 bottomPixel = frame[sampleX, yBottom];

                _buffer.ProcessPixelPairs(topPixel, bottomPixel);
            }

            _buffer.AppendLine();
        }

        return _buffer.ToString();
    }

    private static string ProcessFrameBlockElements(ImageFrame<Rgba32> frame, int cellPixelWidth, int cellRows) {
        var _buffer = new StringBuilder();
        int width = frame.Width;
        int height = frame.Height;

        for (int row = 0; row < cellRows; row++) {
            int yTop = Math.Clamp((int)Math.Round((row + 0.25) * height / cellRows), 0, height - 1);
            int yBottom = Math.Clamp((int)Math.Round((row + 0.75) * height / cellRows), 0, height - 1);

            for (int xCell = 0; xCell < width; xCell += cellPixelWidth) {
                int sampleX = xCell + (cellPixelWidth / 2);
                if (sampleX >= width) sampleX = width - 1;

                // sample left/right inside the cell
                int leftX = Math.Clamp(xCell + (cellPixelWidth / 4), 0, width - 1);
                int rightX = Math.Clamp(xCell + (3 * cellPixelWidth / 4), 0, width - 1);

                Rgba32 leftTop = frame[leftX, yTop];
                Rgba32 leftBottom = frame[leftX, yBottom];
                Rgba32 rightTop = frame[rightX, yTop];
                Rgba32 rightBottom = frame[rightX, yBottom];

                bool leftOn = !IsTransparent(leftTop) || !IsTransparent(leftBottom);
                bool rightOn = !IsTransparent(rightTop) || !IsTransparent(rightBottom);

                if (leftOn && rightOn) {
                    (byte lR, byte lG, byte lB) = CompositeOver(leftTop, leftBottom);
                    (byte rR, byte rG, byte rB) = CompositeOver(rightTop, rightBottom);
                    _buffer.Append(Constants.ESC).Append(Constants.VTFG).Append(lR).Append(';').Append(lG).Append(';').Append(lB).Append(';');
                    _buffer.Append(48).Append(';').Append(2).Append(';').Append(rR).Append(';').Append(rG).Append(';').Append(rB).Append('m');
                    _buffer.Append(Constants.LeftHalfBlock);
                    _buffer.Append(Constants.Reset);
                    continue;
                }

                // Fallback to half-block sampling using center X
                Rgba32 topPixel = frame[sampleX, yTop];
                Rgba32 bottomPixel = frame[sampleX, yBottom];
                _buffer.ProcessPixelPairs(topPixel, bottomPixel);
            }

            _buffer.AppendLine();
        }

        return _buffer.ToString();
    }

    private static string ProcessFrameBraille(ImageFrame<Rgba32> frame, int cellPixelWidth, int cellRows) {
        var _buffer = new StringBuilder();
        int width = frame.Width;
        int height = frame.Height;

        for (int row = 0; row < cellRows; row++) {
            for (int xCell = 0; xCell < width; xCell += cellPixelWidth) {
                int baseX = xCell;
                int dotBits = 0;
                int sampleCount = 0;
                int rSum = 0, gSum = 0, bSum = 0;

                for (int dx = 0; dx < 2; dx++) {
                    int sampleX = Math.Clamp(baseX + (int)Math.Round((dx + 0.5) / 2.0 * cellPixelWidth), 0, width - 1);
                    for (int dy = 0; dy < 4; dy++) {
                        int sampleY = Math.Clamp((int)Math.Round((row + (dy + 0.5) / 4.0) * height / cellRows), 0, height - 1);
                        Rgba32 px = frame[sampleX, sampleY];
                        bool on = !IsTransparent(px);
                        if (on) {
                            int dotIndex = dx == 0 ? (dy == 0 ? 0 : dy == 1 ? 1 : dy == 2 ? 2 : 6) : (dy == 0 ? 3 : dy == 1 ? 4 : dy == 2 ? 5 : 7);
                            dotBits |= 1 << dotIndex;
                            rSum += px.R; gSum += px.G; bSum += px.B;
                            sampleCount++;
                        }
                    }
                }

                if (dotBits == 0) {
                    _buffer.Append(' ');
                }
                else {
                    byte R = (byte)(rSum / Math.Max(1, sampleCount));
                    byte G = (byte)(gSum / Math.Max(1, sampleCount));
                    byte B = (byte)(bSum / Math.Max(1, sampleCount));
                    int codepoint = 0x2800 + dotBits;
                    _buffer.Append(Constants.ESC).Append(Constants.VTFG).Append(R).Append(';').Append(G).Append(';').Append(B).Append('m');
                    _buffer.Append(char.ConvertFromUtf32(codepoint));
                    _buffer.Append(Constants.Reset);
                }
            }

            _buffer.AppendLine();
        }

        return _buffer.ToString();
    }

    private static void ProcessPixelPairs(this StringBuilder _buffer, Rgba32 top, Rgba32 bottom) {
        bool topTransparent = IsTransparent(top);
        bool bottomTransparent = IsTransparent(bottom);

        if (topTransparent && bottomTransparent) {
            _buffer.Append(' ');
            return;
        }

        if (topTransparent) {
            (byte R, byte G, byte B) = CompositeOverBlack(bottom);
            _buffer.AppendTopTransparent(R, G, B);
            return;
        }

        if (bottomTransparent) {
            (byte R, byte G, byte B) = CompositeOverBlack(top);
            _buffer.AppendBottomTransparent(R, G, B);
            return;
        }

        // Both pixels present: composite the top pixel over the bottom pixel for the
        // foreground (top) colour, and composite the bottom pixel over black for
        // the background (bottom) colour. This gives a visually-correct result
        // when either pixel has partial transparency.
        (byte R, byte G, byte B) fg = CompositeOver(top, bottom);
        (byte R, byte G, byte B) bg = CompositeOverBlack(bottom);
        _buffer.AppendBlock(fg.R, fg.G, fg.B, bg.R, bg.G, bg.B);
    }

    private static void AppendTopTransparent(this StringBuilder Builder, byte r, byte g, byte b) {
        // => "`e[38;2;{r};{g};{b}m▄`e[0m"
        Builder.
        Append(Constants.ESC).
        Append(Constants.VTFG).
        Append(r).Append(';').
        Append(g).Append(';').
        Append(b).Append('m').
        Append(Constants.LowerHalfBlock).
        Append(Constants.Reset);
    }
    private static void AppendBottomTransparent(this StringBuilder Builder, byte r, byte g, byte b) {
        // => "`e[38;2;{r};{g};{b}m▀`e[0m"
        Builder.
        Append(Constants.ESC).
        Append(Constants.VTFG).
        Append(r).Append(';').
        Append(g).Append(';').
        Append(b).Append('m').
        Append(Constants.UpperHalfBlock).
        Append(Constants.Reset);
    }
    private static void AppendBlock(this StringBuilder Builder, byte TopR, byte TopG, byte TopB, byte BottomR, byte BottomG, byte BottomB) {
        // =>  "`e[38;2;{TopR};{TopG};{TopB};48;2;{BottomR};{BottomG};{BottomB}m▀`e[0m"
        Builder.
        Append(Constants.ESC).
        Append(Constants.VTFG).
        Append(TopR).Append(';').
        Append(TopG).Append(';').
        Append(TopB).Append(';').
        Append(48).Append(';').
        Append(2).Append(';').
        Append(BottomR).Append(';').
        Append(BottomG).Append(';').
        Append(BottomB).Append('m').
        Append(Constants.UpperHalfBlock).
        Append(Constants.Reset);
    }

    private static (byte R, byte G, byte B) CompositeOverBlack(Rgba32 src) {
        // If the source is considered transparent, emit (0,0,0) to indicate
        // a transparent half. Otherwise emit the raw RGB bytes.
        if (IsTransparent(src)) return (0, 0, 0);
        return (src.R, src.G, src.B);
    }

    private static (byte R, byte G, byte B) CompositeOver(Rgba32 src, Rgba32 dst) {
        // Composite src over dst taking both alpha channels into account.
        if (IsTransparent(src) && IsTransparent(dst)) return (0, 0, 0);

        float sa = src.A / 255f;
        float da = dst.A / 255f;

        // Resulting colour components (approximate, no premultiplied linear correction)
        float r = (src.R * sa) + (dst.R * da * (1 - sa));
        float g = (src.G * sa) + (dst.G * da * (1 - sa));
        float b = (src.B * sa) + (dst.B * da * (1 - sa));

        byte R = (byte)Math.Clamp((int)Math.Round(r), 0, 255);
        byte G = (byte)Math.Clamp((int)Math.Round(g), 0, 255);
        byte B = (byte)Math.Clamp((int)Math.Round(b), 0, 255);

        return (R, G, B);
    }
    private static bool IsTransparent(Rgba32 pixel) {
        if (pixel.A == 0) return true;

        float luminance = ((0.299f * pixel.R) + (0.587f * pixel.G) + (0.114f * pixel.B)) / 255f;

        return pixel.A < 8 || (pixel.A < 32 && luminance < 0.15f) ||
            (pixel.A < 64 && pixel.R < 12 && pixel.G < 12 && pixel.B < 12) ||
            (pixel.A < 128 && luminance < 0.05f) || (pixel.A < 240 && luminance < 0.01f);
    }

}
