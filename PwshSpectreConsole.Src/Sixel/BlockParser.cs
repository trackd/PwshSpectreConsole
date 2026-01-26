using System.Text;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using SixLabors.ImageSharp.Processing.Processors.Quantization;
// using Color = SixLabors.ImageSharp.Color;

namespace PwshSpectreConsole;

public static class Blocks {
    public static ConsoleImage ImageToBlocks(Image<Rgba32> image, int cellWidth, bool disableAnimation = false) {
        // We're going to resize the image when it's rendered, so use a copy to leave the original untouched.
        Image<Rgba32> imageClone = image.Clone();

        // Convert to pixel sizes.
        int pixelWidth = cellWidth * Compatibility.GetCellSize().PixelWidth;
        int pixelHeight = (int)Math.Round((double)imageClone.Height / imageClone.Width * pixelWidth);

        imageClone.Mutate(ctx => {
            // Resize the image to the target size
            ctx.Resize(new ResizeOptions() {
                Sampler = KnownResamplers.Bicubic,
                Mode = ResizeMode.BoxPad,
                Position = AnchorPositionMode.TopLeft,
                PadColor = Color.Transparent,
                // * 2 because each cell is 2 pixels high for blocks
                Size = new Size(pixelWidth, pixelHeight * 2),
                PremultiplyAlpha = false,
            });

            // Sixel supports 256 colors max
            ctx.Quantize(new OctreeQuantizer(new() {
                MaxColors = 256,
            }));
        });
        ImageFrame<Rgba32> firstFrame = imageClone.Frames[0];
        int cellPixelHeight = Compatibility.GetCellSize().PixelHeight;
        int cellHeight = (int)Math.Ceiling((double)pixelHeight / cellPixelHeight);
        var blockStrings = new List<string>();

        for (int i = 0; i < imageClone.Frames.Count; i++) {
            blockStrings.Add(ProcessFrame(imageClone.Frames[i]));
            if (disableAnimation) {
                break;
            }
        }

        return new ConsoleImage(
            pixelWidth,
            pixelHeight,
            cellHeight,
            cellWidth,
            [.. blockStrings]);
    }

    internal static string ProcessFrame(ImageFrame<Rgba32> frame) {
        var _buffer = new StringBuilder();
        Rgba32 _backgroundColor = GetConsoleBackgroundColor();
        // Rgba32 _backgroundColor = Color.Transparent.ToPixel<Rgba32>();

        for (int y = 0; y < frame.Height; y += 2) {
            if (y + 1 >= frame.Height) {
                _buffer.AppendLine();
                break;
            }

            for (int x = 0; x < frame.Width; x++) {
                Rgba32 topPixel = frame[x, y];
                Rgba32 bottomPixel = frame[x, y + 1];

                _buffer.ProcessPixelPairs(topPixel, bottomPixel, _backgroundColor);
            }
            _buffer.AppendLine();
        }
        return _buffer.ToString();
    }
    private static void ProcessPixelPairs(this StringBuilder _buffer, Rgba32 top, Rgba32 bottom, Rgba32 _backgroundColor) {
        bool topTransparent = IsTransparent(top);
        bool bottomTransparent = IsTransparent(bottom);

        if (topTransparent && bottomTransparent) {
            _buffer.Append(' ');
        }
        else if (topTransparent) {
            // (byte R, byte G, byte B) = BlendPixels(bottom, _backgroundColor);
            // _buffer.AppendTopTransparent(R, G, B);
            Rgba32 blend = BlendPixelsColor(bottom, _backgroundColor);
            _buffer.AppendTopTransparent(blend.R, blend.G, blend.B);
        }
        else if (bottomTransparent) {
            // (byte R, byte G, byte B) = BlendPixels(top, _backgroundColor);
            // _buffer.AppendBottomTransparent(R, G, B);
            Rgba32 blend = BlendPixelsColor(top, _backgroundColor);
            _buffer.AppendBottomTransparent(blend.R, blend.G, blend.B);
        }
        else {
            // (byte R, byte G, byte B) = BlendPixels(top, _backgroundColor);
            // (byte R, byte G, byte B) bottomRgb = BlendPixels(bottom, _backgroundColor);
            // _buffer.AppendBlock(R, G, B, bottomRgb.R, bottomRgb.G, bottomRgb.B);
            Rgba32 rtop = BlendPixelsColor(top, _backgroundColor);
            Rgba32 rbot = BlendPixelsColor(bottom, _backgroundColor);
            _buffer.AppendBlock(rtop.R, rtop.G, rtop.B, rbot.R, rbot.G, rbot.B);
        }
    }
    private static void AppendTopTransparent(this StringBuilder Builder, byte r, byte g, byte b) {
        // "`e[38;2;{r};{g};{b}m▄`e[0m"
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
        // "`e[38;2;{r};{g};{b}m▀`e[0m"
        Builder.
        Append(Constants.ESC).
        Append(Constants.VTFG).
        Append(r).Append(';').
        Append(g).Append(';').
        Append(b).Append('m').
        Append(Constants.UpperHalfBlock).
        Append(Constants.Reset);
    }
    private static void AppendBlock(this StringBuilder Builder, byte tr, byte tg, byte tb, byte br, byte bg, byte bb) {
        // "`e[38;2;{tr};{tg};{tb};48;2;{br};{bg};{bb}m▀`e[0m"
        Builder.
        Append(Constants.ESC).
        Append(Constants.VTFG).
        Append(tr).Append(';').
        Append(tg).Append(';').
        Append(tb).Append(Constants.VTBG).
        Append(br).Append(';').
        Append(bg).Append(';').
        Append(bb).Append('m').
        Append(Constants.UpperHalfBlock).
        Append(Constants.Reset);
    }
    private static (byte R, byte G, byte B) BlendPixels(Rgba32 pixel, Rgba32 _backgroundColor) {
        // If pixel is fully transparent, return the background color
        if (IsTransparent(pixel)) {
            return (_backgroundColor.R, _backgroundColor.G, _backgroundColor.B);
        }

        float amount = pixel.A / 255f;

        byte r = (byte)((pixel.R * amount) + (_backgroundColor.R * (1 - amount)));
        byte g = (byte)((pixel.G * amount) + (_backgroundColor.G * (1 - amount)));
        byte b = (byte)((pixel.B * amount) + (_backgroundColor.B * (1 - amount)));

        return (r, g, b);
    }
    private static Rgba32 BlendPixelsColor(Rgba32 pixel, Rgba32 _backgroundColor) {
        // If pixel is fully transparent, return the background color
        if (IsTransparent(pixel)) {
            // return (_backgroundColor.R, _backgroundColor.G, _backgroundColor.B);
            // return Color.Transparent;
            return Color.Transparent.ToPixel<Rgba32>();
        }

        float amount = pixel.A / 255f;

        byte r = (byte)((pixel.R * amount) + (_backgroundColor.R * (1 - amount)));
        byte g = (byte)((pixel.G * amount) + (_backgroundColor.G * (1 - amount)));
        byte b = (byte)((pixel.B * amount) + (_backgroundColor.B * (1 - amount)));

        return Color.FromRgb(r, g, b).ToPixel<Rgba32>();
    }
    private static bool IsTransparent(Rgba32 pixel) {
        if (pixel.A == 0) return true;

        // Calculate luminance for better edge artifact detection
        float luminance = ((0.299f * pixel.R) + (0.587f * pixel.G) + (0.114f * pixel.B)) / 255f;

        // Consider pixels transparent if:
        // 1. Alpha is very low (traditional transparency)
        // 2. Alpha is low and pixel is very dark (common resizing artifacts)
        // 3. Alpha is moderate and luminance is extremely low (aggressive edge artifact removal)
        // 4. Alpha is low and color is close to pure black (black edge artifacts)
        // 5. Very aggressive: moderately transparent with low luminance (catches most edge cases)
        return pixel.A < 8 ||
                (pixel.A < 32 && luminance < 0.15f) ||
                (pixel.A < 64 && pixel.R < 12 && pixel.G < 12 && pixel.B < 12) ||
                (pixel.A < 128 && luminance < 0.05f) ||
                (pixel.A < 240 && luminance < 0.01f);
    }
    private static Rgba32 GetConsoleBackgroundColor() {
        if (Console.IsOutputRedirected || Console.IsInputRedirected) {
            return Color.Black.ToPixel<Rgba32>();
        }
        var bg = Spectre.Console.Color.FromConsoleColor(Console.BackgroundColor);
        var color = Color.FromRgb(bg.R, bg.G, bg.B);
        // Color color = Console.BackgroundColor switch {
        //     ConsoleColor.Black => Color.FromRgb(0, 0, 0),
        //     ConsoleColor.Blue => Color.FromRgb(0, 0, 170),
        //     ConsoleColor.Cyan => Color.FromRgb(0, 170, 170),
        //     ConsoleColor.DarkBlue => Color.FromRgb(0, 0, 85),
        //     ConsoleColor.DarkCyan => Color.FromRgb(0, 85, 85),
        //     ConsoleColor.DarkGray => Color.FromRgb(85, 85, 85),
        //     ConsoleColor.DarkGreen => Color.FromRgb(0, 85, 0),
        //     ConsoleColor.DarkMagenta => Color.FromRgb(85, 0, 85),
        //     ConsoleColor.DarkRed => Color.FromRgb(85, 0, 0),
        //     ConsoleColor.DarkYellow => Color.FromRgb(85, 85, 0),
        //     ConsoleColor.Gray => Color.FromRgb(170, 170, 170),
        //     ConsoleColor.Green => Color.FromRgb(0, 170, 0),
        //     ConsoleColor.Magenta => Color.FromRgb(170, 0, 170),
        //     ConsoleColor.Red => Color.FromRgb(170, 0, 0),
        //     ConsoleColor.White => Color.FromRgb(255, 255, 255),
        //     ConsoleColor.Yellow => Color.FromRgb(170, 170, 0),
        //     _ => Color.Transparent,
        // };
        return color.ToPixel<Rgba32>();
    }

}
