using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using Spectre.Console;
using Spectre.Console.Rendering;

namespace PwshSpectreConsole
{
    [Cmdlet(VerbsData.ConvertTo, "SpectreDecoration")]
    /// <summary>
    /// Converts a VT decorated string to Spectre.Colors
    /// does not support multi-colored strings,
    /// in order to be able to use Spectre.Console.Text
    /// </summary>
    public sealed class ConvertToSpectreDecorationCmdlet : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
        public string String { get; set; }
        [Parameter()]
        [Alias("AllowMarkup")]
        public SwitchParameter ToMarkUp { get; set; }
        [Parameter()]
        public SwitchParameter Raw { get; set; }
        [Parameter()]
        public SwitchParameter AsHashtable { get; set; }

        protected override void ProcessRecord()
        {
            try
            {
                List<IVT> lookup = Decoder.Parse(String);
                if (Raw)
                {
                    WriteObject(lookup, enumerateCollection: true);
                    return;
                }
                Hashtable ht = (Hashtable)Transform.Map(lookup);

                ht["String"] = Transform.ToCleanString(String, true);

                if (AsHashtable)
                {
                    WriteObject(ht);
                    return;
                }
                if (ToMarkUp)
                {
                    Markup _markup = new Markup((string)ht["String"], new Style((Color?)ht["fg"], (Color?)ht["bg"], (Decoration?)ht["decoration"]));
                    WriteObject(_markup);
                    return;
                }
                Text _text = new Text((string)ht["String"], new Style((Color?)ht["fg"], (Color?)ht["bg"], (Decoration?)ht["decoration"]));
                WriteObject(_text);
                return;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                WriteObject(ex);
            }
        }
    }
    // broken
    // [Cmdlet(VerbsData.ConvertTo, "SpectreMarkUp")]
    // ///<summary>
    // /// converts a VT decorated string to Spectre Console
    // /// default outputs a spectre markdown object
    // ///
    // public sealed class ConvertToSpectreMarkUpCmdlet : PSCmdlet
    // {
    //     [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
    //     public string String { get; set; }

    //     [Parameter()]
    //     public SwitchParameter AsString { get; set; }
    //     protected override void ProcessRecord()
    //     {
    //         if (AsString)
    //         {
    //             object sresult = Transform.ToMarkUp(String, true);
    //             string _string = sresult as string;
    //             WriteObject(_string);
    //             return;
    //         }
    //         // for VT decorated strings
    //         object mresult = Transform.ToMarkUp(String);
    //         Markup _markup = mresult as Markup;
    //         WriteObject(_markup);
    //         return;
    //     }
    // }
    [Cmdlet(VerbsCommunications.Write, "SpectreRender")]
    /// <summary>
    /// writes a renderable object to the pipeline
    /// <summary>
    public sealed class RenderSpectre : PSCmdlet
    {
        [Parameter(Position = 0, ValueFromPipeline = true)]
        public Renderable Renderable { get; set; }

        [Parameter()]
        public String String { get; set; }
        protected override void ProcessRecord()
        {
            if (null != String)
            {
                WriteObject(Transform.Render(new Markup(String)));
                return;
            }
            WriteObject(Transform.Render(Renderable));
            return;
        }
    }
    [Cmdlet(VerbsData.ConvertTo, "SpectreMultiColor")]
    ///<summary>
    /// converts a VT decorated string to Spectre Console
    /// default outputs a spectre markdown object
    ///
    public sealed class ConvertToSpectreMultiColorCmdlet : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
        public string String { get; set; }

        [Parameter()]
        public SwitchParameter AsString { get; set; }
        protected override void ProcessRecord()
        {
            if (AsString)
            {
                // returns a string
                var _string = Transform.FromVTToSpectre(String, true);
                WriteObject(_string);
                return;
            }
            // returns a markup object, use Write-SpectreRender to render
            var _markup = Transform.FromVTToSpectre(String);
            WriteObject(_markup);
            return;
        }
    }
}
