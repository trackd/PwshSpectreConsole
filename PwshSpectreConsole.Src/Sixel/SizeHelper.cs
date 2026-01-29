using System;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;

namespace PwshSpectreConsole;

public static class SizeHelper {
    /// <summary>
    /// Converts image dimensions from pixels to terminal character cells.
    /// Accounts for sixel 6px row packing when computing the number of rows occupied.
    /// </summary>
    /// <param name="image">The image to convert.</param>
    /// <param name="protocol">The image protocol being used (affects alignment)</param>
    /// <returns>Image size in terminal character cells.</returns>
    public static (int Width, int Height) ConvertToCharacterCells(Image<Rgba32> image, ImageTypes? protocol)
        => GetCharacterCellSize(image.Width, image.Height, protocol);

    /// <summary>
    /// Converts image dimensions from pixels to terminal character cells.
    /// Accounts for sixel 6px row packing when computing the number of rows occupied.
    /// </summary>
    /// <param name="imageStream">The image stream to convert.</param>
    /// <param name="protocol">The image protocol being used (affects alignment)</param>
    /// <returns>Image size in terminal character cells.</returns>
    public static (int Width, int Height) ConvertToCharacterCells(Stream imageStream, ImageTypes? protocol) {
        using var image = Image.Load<Rgba32>(imageStream);
        return GetCharacterCellSize(image.Width, image.Height, protocol);
    }

    /// <summary>
    /// Gets the current size of an image in terminal character cells (no resizing, just analysis).
    /// Height is computed from the image height rounded up to the nearest multiple of 6 pixels to
    /// match sixel 6px row packing so the number of occupied rows is correct.
    /// </summary>
    /// <param name="pixelWidth"></param>
    /// <param name="pixelHeight"></param>
    /// <param name="protocol">The image protocol being used (affects alignment)</param>
    public static (int Width, int Height) GetCharacterCellSize(int pixelWidth, int pixelHeight, ImageTypes? protocol) {
        CellSize cellSize = Compatibility.GetCellSize();

        // Only apply 6px alignment for Sixel protocol
        if (protocol == ImageTypes.Sixel) {
            // Align image height to a multiple of 6px before converting to rows
            // rows = ceil( ceil(h_px / 6) * 6 / cellHeight_px )
            int effectivePixelHeight = (pixelHeight + 5) / 6 * 6;

            int widthCells = Math.Max(1, (int)Math.Ceiling((double)pixelWidth / cellSize.PixelWidth));
            int heightCells = Math.Max(1, (int)Math.Ceiling((double)effectivePixelHeight / cellSize.PixelHeight));

            if (Environment.GetEnvironmentVariable("PWSSPECTRE_DEBUG_SIZING") == "1") {
                Console.Error.WriteLine($"[PWSSPECTRE_DEBUG_SIZING] GetCharacterCellSize(protocol=Sixel) pixelWidth={pixelWidth} pixelHeight={pixelHeight} effectivePixelHeight={effectivePixelHeight} cellPixelWidth={cellSize.PixelWidth} cellPixelHeight={cellSize.PixelHeight} => cells=({widthCells},{heightCells})");
            }

            return (widthCells, heightCells);
        }
        else {
            // For Kitty and other protocols: no 6px alignment
            int widthCells = Math.Max(1, (int)Math.Ceiling((double)pixelWidth / cellSize.PixelWidth));
            int heightCells = Math.Max(1, (int)Math.Ceiling((double)pixelHeight / cellSize.PixelHeight));
            if (Environment.GetEnvironmentVariable("PWSSPECTRE_DEBUG_SIZING") == "1") {
                Console.Error.WriteLine($"[PWSSPECTRE_DEBUG_SIZING] GetCharacterCellSize(protocol=Other) pixelWidth={pixelWidth} pixelHeight={pixelHeight} cellPixelWidth={cellSize.PixelWidth} cellPixelHeight={cellSize.PixelHeight} => cells=({widthCells},{heightCells})");
            }

            return (widthCells, heightCells);
        }
    }

    /// <summary>
    /// Gets the current size of an image in terminal character cells (no resizing, just analysis).
    /// </summary>
    /// <param name="image"></param>
    /// <param name="protocol">The image protocol being used (affects alignment)</param>
    public static (int Width, int Height) GetCharacterCellSize(Image<Rgba32> image, ImageTypes? protocol)
        => GetCharacterCellSize(image.Width, image.Height, protocol);

    /// <summary>
    /// Gets the resized size in terminal character cells for an image, given max width/height constraints.
    /// Maintains aspect ratio, aligns height to sixel 6px rows, and uses pixel-space math to avoid clipping.
    /// </summary>
    /// <param name="pixelWidth"></param>
    /// <param name="pixelHeight"></param>
    /// <param name="maxCellWidth"></param>
    /// <param name="maxCellHeight"></param>
    /// <param name="protocol">The image protocol being used (affects alignment)</param>
    public static (int Width, int Height) GetResizedCharacterCellSize(int pixelWidth, int pixelHeight, int maxCellWidth, int maxCellHeight, ImageTypes? protocol) {
        CellSize cellSize = Compatibility.GetCellSize();

        if (pixelWidth <= 0 || pixelHeight <= 0) {
            return (1, 1);
        }

        // Treat 0 as "no constraint" instead of clamping to the current window size.
        bool constrainW = maxCellWidth > 0;
        bool constrainH = maxCellHeight > 0;

        // Convert constraints to pixel budgets; Infinity for unconstrained.
        double maxPixelsW = constrainW ? (double)maxCellWidth * cellSize.PixelWidth : double.PositiveInfinity;
        double maxPixelsH = constrainH ? (double)maxCellHeight * cellSize.PixelHeight : double.PositiveInfinity;

        // Respect sixel: when height is constrained, align the pixel budget to a multiple of 6px.
        // Only apply for Sixel protocol
        if (protocol == ImageTypes.Sixel && constrainH) {
            maxPixelsH = Math.Max(6.0, Math.Floor(maxPixelsH / 6.0) * 6.0);
        }

        // Compute scale in pixel space to preserve aspect ratio
        double scaleW = double.IsInfinity(maxPixelsW) ? double.PositiveInfinity : maxPixelsW / pixelWidth;
        double scaleH = double.IsInfinity(maxPixelsH) ? double.PositiveInfinity : maxPixelsH / pixelHeight;
        double scale = Math.Min(scaleW, scaleH);
        if (double.IsInfinity(scale) || scale <= 0) {
            scale = 1.0; // No constraints provided
        }

        // Scaled pixel size
        int scaledPixelW = Math.Max(1, (int)Math.Round(pixelWidth * scale));
        int scaledPixelH = Math.Max(1, (int)Math.Round(pixelHeight * scale));

        // Sixel consumes rows in 6px bands; account for that when converting to terminal rows
        // Only apply for Sixel protocol
        int effectiveScaledPixelH = protocol == ImageTypes.Sixel ? (scaledPixelH + 5) / 6 * 6 : scaledPixelH;

        // Convert scaled pixels to cells. Use Ceil for width to avoid right-edge clipping.
        int cellW = Math.Max(1, (int)Math.Ceiling((double)scaledPixelW / cellSize.PixelWidth));
        int cellH = Math.Max(1, (int)Math.Ceiling((double)effectiveScaledPixelH / cellSize.PixelHeight));

        // Clamp to explicit constraints only
        if (constrainW) {
            cellW = Math.Min(cellW, maxCellWidth);
        }

        if (constrainH) {
            cellH = Math.Min(cellH, maxCellHeight);
        }

        if (Environment.GetEnvironmentVariable("PWSSPECTRE_DEBUG_SIZING") == "1") {
            Console.Error.WriteLine($"[PWSSPECTRE_DEBUG_SIZING] GetResizedCharacterCellSize inputs: pixelW={pixelWidth} pixelH={pixelHeight} maxCellW={maxCellWidth} maxCellH={maxCellHeight} protocol={(protocol?.ToString() ?? "null")}");
            Console.Error.WriteLine($"[PWSSPECTRE_DEBUG_SIZING] cellSize: pixelWidth={cellSize.PixelWidth} pixelHeight={cellSize.PixelHeight} scale={scale} scaledPixelW={scaledPixelW} scaledPixelH={scaledPixelH} effectiveScaledPixelH={effectiveScaledPixelH} => cells=({cellW},{cellH})");
        }

        return (cellW, cellH);
    }

    /// <summary>
    /// Gets the resized size in terminal character cells for an image, given max width/height constraints.
    /// Maintains aspect ratio and ensures proper sixel alignment (multiples of 6 pixels).
    /// </summary>
    /// <param name="image"></param>
    /// <param name="maxCellWidth"></param>
    /// <param name="maxCellHeight"></param>
    /// <param name="protocol">The image protocol being used (affects alignment)</param>
    public static (int Width, int Height) GetResizedCharacterCellSize(Image<Rgba32> image, int maxCellWidth, int maxCellHeight, ImageTypes? protocol)
        => GetResizedCharacterCellSize(image.Width, image.Height, maxCellWidth, maxCellHeight, protocol);

    /// <summary>
    /// Gets the constrained terminal image size for the image, applying width/height constraints.
    /// </summary>
    /// <param name="image"></param>
    /// <param name="maxWidth"></param>
    /// <param name="maxHeight"></param>
    public static (int Width, int Height) GetTerminalImageSize(Image<Rgba32> image, int maxWidth, int maxHeight, ImageTypes? protocol)
        => GetResizedCharacterCellSize(image.Width, image.Height, maxWidth, maxHeight, protocol);

    /// <summary>
    /// Gets the constrained terminal image size for the image, applying width/height constraints.
    /// </summary>
    /// <param name="imageStream"></param>
    /// <param name="maxWidth"></param>
    /// <param name="maxHeight"></param>
    public static (int Width, int Height) GetTerminalImageSize(Stream imageStream, int maxWidth, int maxHeight, ImageTypes? protocol) {
        using var image = Image.Load<Rgba32>(imageStream);
        return GetResizedCharacterCellSize(image.Width, image.Height, maxWidth, maxHeight, protocol);
    }

    /// <summary>
    /// Gets the constrained terminal image size, applying width/height constraints.
    /// </summary>
    /// <param name="pixelWidth"></param>
    /// <param name="pixelHeight"></param>
    /// <param name="maxWidth"></param>
    /// <param name="maxHeight"></param>
    public static (int Width, int Height) GetTerminalImageSize(int pixelWidth, int pixelHeight, int maxWidth, int maxHeight, ImageTypes? protocol)
        => GetResizedCharacterCellSize(pixelWidth, pixelHeight, maxWidth, maxHeight, protocol);

    internal static (int Width, int Height) GetTerminalImageSize(this Image<Rgba32> image, ImageTypes? protocol)
        => ConvertToCharacterCells(image, protocol);

    /// <summary>
    /// Computes a default terminal image size relative to the current window, using true cell size.
    /// When the console is unavailable or redirected, falls back to the natural image size in cells.
    /// </summary>
    /// <param name="image">Loaded image.</param>
    /// <param name="windowScaleFactor">Proportion of window to target (e.g., 0.6 for 60%).</param>
    public static (int Width, int Height) GetDefaultTerminalImageSize(Image<Rgba32> image, ImageTypes? protocol, double windowScaleFactor = 0.6) {
        (int Width, int Height) natural = ConvertToCharacterCells(image, protocol);

        // If console isn't interactive, return natural size
        bool hasConsole = !Console.IsOutputRedirected && !Console.IsInputRedirected;
        if (!hasConsole) {
            return natural;
        }

        // Determine window target in character cells
        int winCols = Math.Max(1, Console.WindowWidth);
        int winRows = Math.Max(1, Console.WindowHeight);
        int targetCols = Math.Max(1, (int)Math.Round(winCols * windowScaleFactor));
        int targetRows = Math.Max(1, (int)Math.Round(winRows * windowScaleFactor));

        // Upscale to meet window-relative targets when natural is smaller
        int applyW = natural.Width < targetCols ? targetCols : natural.Width;
        int applyH = natural.Height < targetRows ? targetRows : natural.Height;

        return GetResizedCharacterCellSize(image.Width, image.Height, applyW, applyH, protocol);
    }

}
