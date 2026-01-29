using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using SixLabors.ImageSharp.Processing.Processors.Quantization;

namespace PwshSpectreConsole;

public static class Resizer {
    public static Image<Rgba32> ResizeToCharacterCells(Image<Rgba32> image, (int Width, int Height) imageSize, int maxColors) {
        CellSize cellSize = Compatibility.GetCellSize();

        int targetPixelWidth = imageSize.Width * cellSize.PixelWidth;
        int targetPixelHeight = imageSize.Height * cellSize.PixelHeight;

        if (image.Width != targetPixelWidth || image.Height != targetPixelHeight) {
            image.Mutate(ctx => {
                ctx.Resize(new ResizeOptions() {
                    Mode = ResizeMode.BoxPad,
                    Position = AnchorPositionMode.TopLeft,
                    PadColor = Color.Transparent,
                    Sampler = KnownResamplers.Bicubic,
                    Size = new Size(targetPixelWidth, targetPixelHeight),
                    PremultiplyAlpha = false,
                });

                if (maxColors > 0) {
                    ctx.Quantize(new OctreeQuantizer(new() { MaxColors = maxColors }));
                }
            });
        }
        else if (maxColors > 0) {
            image.Mutate(ctx =>
                ctx.Quantize(new OctreeQuantizer(new() { MaxColors = maxColors })));
        }

        return image;
    }

}
