using System.Reflection;
using Spectre.Console;

namespace PwshSpectreConsole.PowerShell;

public static class ColorUtilities {
    private static readonly IReadOnlyDictionary<int, string> ConsoleColors = new Dictionary<int, string> {
        [30] = "Black", [31] = "DarkRed", [32] = "DarkGreen", [33] = "DarkYellow",
        [34] = "DarkBlue", [35] = "DarkMagenta", [36] = "DarkCyan", [37] = "Gray",
        [40] = "Black", [41] = "DarkRed", [42] = "DarkGreen", [43] = "DarkYellow",
        [44] = "DarkBlue", [45] = "DarkMagenta", [46] = "DarkCyan", [47] = "Gray",
        [90] = "DarkGray", [91] = "Red", [92] = "Green", [93] = "Yellow",
        [94] = "Blue", [95] = "Magenta", [96] = "Cyan", [97] = "White",
        [100] = "DarkGray", [101] = "Red", [102] = "Green", [103] = "Yellow",
        [104] = "Blue", [105] = "Magenta", [106] = "Cyan", [107] = "White"
    };

    public static Color ToColor(object color) {
        ArgumentNullException.ThrowIfNull(color);
        if (color is Color spectreColor) {
            return spectreColor;
        }

        string value = color as string
            ?? throw new ArgumentException($"Cannot convert {color.GetType().FullName} '{color}' to [Spectre.Console.Color]");

        if (value.StartsWith('#')) {
            byte[] bytes = Convert.FromHexString(value[1..]);
            if (bytes.Length != 3) {
                throw new ArgumentException($"Cannot convert '{value}' to [Spectre.Console.Color]");
            }

            return new Color(bytes[0], bytes[1], bytes[2]);
        }

        PropertyInfo? property = typeof(Color).GetProperty(value, BindingFlags.Public | BindingFlags.Static | BindingFlags.IgnoreCase);
        return property?.PropertyType == typeof(Color)
            ? (Color)property.GetValue(null)!
            : throw new ArgumentException($"Cannot convert '{value}' to [Spectre.Console.Color]");
    }

    public static Color ToColorOrDefault(object color, Color fallback) {
        try {
            return ToColor(color);
        }
        catch (ArgumentException) {
            return fallback;
        }
        catch (FormatException) {
            return fallback;
        }
    }

    public static string? FromConsoleColor(int color)
        => ConsoleColors.GetValueOrDefault(color);

    public static int[] HslToRgb(int hue, int saturation, int lightness) {
        ArgumentOutOfRangeException.ThrowIfNegative(hue);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(hue, 360);
        ArgumentOutOfRangeException.ThrowIfNegative(saturation);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(saturation, 100);
        ArgumentOutOfRangeException.ThrowIfNegative(lightness);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(lightness, 100);

        double huePercent = hue / 360.0;
        double saturationPercent = saturation / 100.0;
        double lightnessPercent = lightness / 100.0;

        double red;
        double green;
        double blue;
        if (saturationPercent == 0) {
            red = green = blue = lightnessPercent;
        }
        else {
            double q = lightnessPercent < 0.5
                ? lightnessPercent * (1 + saturationPercent)
                : lightnessPercent + saturationPercent - (lightnessPercent * saturationPercent);
            double p = (2 * lightnessPercent) - q;
            red = PqtToRgb(p, q, huePercent + (1.0 / 3.0));
            green = PqtToRgb(p, q, huePercent);
            blue = PqtToRgb(p, q, huePercent - (1.0 / 3.0));
        }

        return [Convert.ToInt32(red * 255), Convert.ToInt32(green * 255), Convert.ToInt32(blue * 255)];
    }

    public static double PqtToRgb(double p, double q, double t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1.0 / 6.0) return p + ((q - p) * 6 * t);
        if (t < 1.0 / 2.0) return q;
        if (t < 2.0 / 3.0) return p + ((q - p) * ((2.0 / 3.0) - t) * 6);
        return p;
    }

    public static int[] RgbToHsv(int red, int green, int blue) {
        double redPercent = red / 255.0;
        double greenPercent = green / 255.0;
        double bluePercent = blue / 255.0;
        double max = Math.Max(Math.Max(redPercent, greenPercent), bluePercent);
        double min = Math.Min(Math.Min(redPercent, greenPercent), bluePercent);
        double delta = max - min;

        double hue = 0;
        if (delta != 0) {
            if (max == redPercent) hue = 60 * (((greenPercent - bluePercent) / delta) % 6);
            else if (max == greenPercent) hue = 60 * (((bluePercent - redPercent) / delta) + 2);
            else hue = 60 * (((redPercent - greenPercent) / delta) + 4);
        }

        if (hue < 0) hue += 360;
        double saturation = max == 0 ? 0 : (delta / max) * 100;
        double value = max * 100;
        return [Convert.ToInt32(hue), Convert.ToInt32(saturation), Convert.ToInt32(value)];
    }

    public static double GetLightness(int red, int green, int blue) {
        double redPercent = red / 255.0;
        double greenPercent = green / 255.0;
        double bluePercent = blue / 255.0;
        return (Math.Max(Math.Max(redPercent, greenPercent), bluePercent)
            + Math.Min(Math.Min(redPercent, greenPercent), bluePercent)) / 2;
    }

    public static string? GetCategory(int hue, int saturation, int value) {
        if (saturation < 15) {
            return value < 40 ? "00 Grey" : "00 GreyZMud";
        }

        return hue switch {
            >= 0 and <= 20 or >= 350 and <= 360 => "02 Red",
            >= 21 and <= 45 => "03 Orange",
            >= 46 and <= 60 => "04 Yellow",
            >= 61 and <= 108 => "05 Green",
            >= 109 and <= 150 => "06 Green2",
            >= 151 and <= 190 => "07 Cyan",
            >= 191 and <= 220 => "08 Blue",
            >= 221 and <= 240 => "09 Blue2",
            >= 241 and <= 280 => "10 Purple",
            >= 281 and <= 300 => "11 Pink1",
            >= 301 and < 350 => "12 Pink",
            _ => null
        };
    }
}
