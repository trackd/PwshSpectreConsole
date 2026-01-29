using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Globalization;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using Spectre.Console.Rendering;

namespace PwshSpectreConsole;

/// <summary>
/// Represents a renderable image.
/// </summary>
/// <remarks>
/// Initializes a new instance of the <see cref="SixelImage"/> class.
/// </remarks>
/// <param name="filename">The image filename.</param>
/// <param name="animationDisabled">Whether the image should have animation disabled.</param>
public sealed class BlockImage(string filename, bool animationDisabled = false) : Renderable {
    /// <summary>
    /// Gets the image width in pixels.
    /// </summary>
    public int Width => Image.Width;
    /// <summary>
    /// Gets the image height in pixels.
    /// </summary>
    public int Height => Image.Height;

    /// <summary>
    /// Gets or sets the render width of the canvas in terminal cells.
    /// </summary>
    public int? MaxWidth { get; set; }

    /// <summary>
    /// Gets or sets the render mode for block rendering (HalfBlocks, BlockElements, Braille).
    /// </summary>
    public RenderMode Mode { get; set; } = RenderMode.HalfBlocks;

    /// <summary>
    /// Gets the render width of the canvas. This is hard coded to 1 for sixel images.
    /// </summary>
    public int PixelWidth { get; } = 1;

    /// <summary>
    /// Gets a value indicating whether the image should be animated.
    /// </summary>
    public bool AnimationDisabled { get; init; } = animationDisabled;

    /// <summary>
    /// Gets or sets the current frame of the image.
    /// </summary>
    public int FrameToRender {
        get => _frameToRender;
        set {
            if (value < 0) {
                throw new InvalidOperationException("Frame to render must be greater than zero.");
            }

            if (value >= Image.Frames.Count) {
                throw new InvalidOperationException("Frame to render must be less than the total number of frames in the image.");
            }

            _frameToRender = value;
        }
    }

    internal Image<Rgba32> Image { get; } = SixLabors.ImageSharp.Image.Load<Rgba32>(filename);
    private readonly Dictionary<(int Width, RenderMode Mode), ConsoleImage> _cachedBlocks = [];
    private int _frameToRender;

    /// <inheritdoc/>
    protected override Measurement Measure(RenderOptions options, int maxWidth) {
        // Measure in terminal character cells, not raw pixels. Use SizeHelper
        // to convert the image pixel dimensions to character cell dimensions.
        (int naturalWidthCells, int naturalHeightCells) = SizeHelper.GetCharacterCellSize(Image, ImageTypes.Blocks);

        int targetWidthCells = MaxWidth ?? naturalWidthCells;

        if (Environment.GetEnvironmentVariable("PWSSPECTRE_DEBUG_SIZING") == "1") {
            Console.Error.WriteLine($"[PWSSPECTRE_DEBUG_SIZING] BlockImage.Measure called: maxWidthArg={maxWidth} MaxWidthProp={(MaxWidth?.ToString(System.Globalization.CultureInfo.InvariantCulture) ?? "null")} natural=({naturalWidthCells},{naturalHeightCells}) targetWidthCells={targetWidthCells}");
        }

        // If the available maxWidth is smaller than our target, report that as both min and max.
        var measurement = maxWidth < targetWidthCells ? new Measurement(maxWidth, maxWidth) : new Measurement(targetWidthCells, targetWidthCells);

        if (Environment.GetEnvironmentVariable("PWSSPECTRE_DEBUG_SIZING") == "1") {
            Console.Error.WriteLine($"[PWSSPECTRE_DEBUG_SIZING] BlockImage.Measure returning: min={measurement.Min} max={measurement.Max}");
        }

        return measurement;
    }

    /// <inheritdoc/>
    protected override IEnumerable<Segment> Render(RenderOptions options, int maxWidth) {
        if (MaxWidth != null && MaxWidth < maxWidth) {
            // Got a max width smaller than the render max width?
            maxWidth = MaxWidth.Value;
        }
        if (maxWidth > Console.WindowWidth) {
            // got a max width larger than the console window? resize
            // make some room for spectre renderables that it's probably wrapped in.
            maxWidth = Console.WindowWidth - 10;
        }

        // Write the sixel data as a control segment.
        // Parsing is expensive, cache the result for the current width.
        var cacheKey = (maxWidth, Mode);
        if (!_cachedBlocks.TryGetValue(cacheKey, out ConsoleImage consoleImage)) {
            consoleImage = Blocks.ImageToBlocks(Image, maxWidth, AnimationDisabled, Mode);
            _cachedBlocks.Add(cacheKey, consoleImage);
        }

        // Draw a transparent renderable to take up the space the sixel is drawn in.
        // This allows Spectre.Console to render the image and not write overtop of it with space characters while padding panel borders etc.
        var canvas = new ImageCanvas(consoleImage.CellWidth, consoleImage.CellHeight) {
            MaxWidth = consoleImage.CellWidth,
            PixelWidth = PixelWidth,
            Scale = false,
        };

        // The segment list is a transparent canvas followed by a couple of zero-width control segments for sixel data output.
        // Rendering the sixel data after the canvas allows the canvas to be truncated in a layout without destroying the layout.
        var segments = ((IRenderable)canvas).Render(options, maxWidth).ToList();

        // Remove the final line break from the canvas so the sixel data can be rendered relative to the top left of the canvas.
        // Leaving the line break in means when this is rendered with IAlignable the cursor position after the canvas is in the wrong location.
        Segment finalSegment = segments.TakeLast(1).First();
        if (finalSegment.IsLineBreak) {
            segments.RemoveAt(segments.Count - 1);
        }

        // Build control sequences for sixel rendering so we can debug or reuse them easily.
        // Conservative offsets: move up by CellHeight-1 to reach the top of the canvas
        // and restore by moving down a single line then moving right to the canvas end.
        segments.Add(Segment.Control($"{Constants.ESC}[{consoleImage.CellHeight - 1}A{Constants.ESC}[{consoleImage.CellWidth}D"));
        segments.Add(Segment.Control(consoleImage.BlockStrings[FrameToRender]));
        // Restore cursor: move up a single line (balances the sixel output) then move right to canvas end
        segments.Add(Segment.Control($"{Constants.ESC}[1A{Constants.ESC}[{consoleImage.CellWidth}C"));

        // Move cursor up to the top-left of the canvas, render sixel, then restore cursor to bottom-right.
        // Add the line break stolen from the canvas.
        segments.Add(Segment.LineBreak);

        // Update animation frame.
        FrameToRender = (FrameToRender + 1) % consoleImage.BlockStrings.Length;

        return segments;
    }
}
