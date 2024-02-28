using Spectre.Console;

namespace PwshSpectreConsole
{
    public static class Helpers
    {
        // https://github.com/spectreconsole/spectre.console/blob/main/examples/Shared/ColorBox.cs
        // https://github.com/spectreconsole/spectre.console/blob/main/examples/Shared/Extensions/ColorExtensions.cs
        public static Color GetInvertedColor(this Color color)
        {
            return GetLuminance(color) < 140 ? Color.White : Color.Black;
        }

        public static float GetLuminance(this Color color)
        {
            return (float)((0.2126 * color.R) + (0.7152 * color.G) + (0.0722 * color.B));
        }
        public static (float, float, float) ColorFromHSL(double h, double l, double s)
        {
            double r = 0, g = 0, b = 0;
            if (l != 0)
            {
                if (s == 0)
                {
                    r = g = b = l;
                }
                else
                {
                    double temp2;
                    if (l < 0.5)
                    {
                        temp2 = l * (1.0 + s);
                    }
                    else
                    {
                        temp2 = l + s - (l * s);
                    }

                    var temp1 = 2.0 * l - temp2;

                    r = GetColorComponent(temp1, temp2, h + 1.0 / 3.0);
                    g = GetColorComponent(temp1, temp2, h);
                    b = GetColorComponent(temp1, temp2, h - 1.0 / 3.0);
                }
            }

            return ((float)r, (float)g, (float)b);

        }
        private static double GetColorComponent(double temp1, double temp2, double temp3)
        {
            if (temp3 < 0.0)
            {
                temp3 += 1.0;
            }
            else if (temp3 > 1.0)
            {
                temp3 -= 1.0;
            }

            if (temp3 < 1.0 / 6.0)
            {
                return temp1 + (temp2 - temp1) * 6.0 * temp3;
            }
            else if (temp3 < 0.5)
            {
                return temp2;
            }
            else if (temp3 < 2.0 / 3.0)
            {
                return temp1 + ((temp2 - temp1) * ((2.0 / 3.0) - temp3) * 6.0);
            }
            else
            {
                return temp1;
            }
        }
    }
}
