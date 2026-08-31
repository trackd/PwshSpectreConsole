using System.Collections;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Reflection;
using Spectre.Console;

namespace PwshSpectreConsole;

public sealed class ArgumentCompletionsSpectreColorsAttribute : ArgumentCompleterAttribute {
    public ArgumentCompletionsSpectreColorsAttribute() : base(typeof(SpectreColorCompleter)) {
    }
}

public sealed class SpectreColorCompleter : IArgumentCompleter {
    public IEnumerable<CompletionResult> CompleteArgument(
        string commandName,
        string parameterName,
        string wordToComplete,
        CommandAst commandAst,
        IDictionary fakeBoundParameters) {
        return typeof(Color).GetProperties(BindingFlags.Public | BindingFlags.Static)
            .Where(property => property.PropertyType == typeof(Color) && property.Name.StartsWith(wordToComplete, StringComparison.OrdinalIgnoreCase))
            .Select(property => new CompletionResult(property.Name, property.Name, CompletionResultType.ParameterValue, property.Name));
    }
}

public abstract class StaticPropertyValidateSet<T> : IValidateSetValuesGenerator {
    public string[] GetValidValues()
        => typeof(T).GetProperties(BindingFlags.Public | BindingFlags.Static)
            .Where(property => property.PropertyType == typeof(T))
            .Select(property => property.Name)
            .ToArray();
}

public sealed class SpectreConsoleTableBorder : StaticPropertyValidateSet<TableBorder> {
}

public sealed class SpectreConsoleBoxBorder : StaticPropertyValidateSet<BoxBorder> {
}

public sealed class SpectreConsoleTreeGuide : StaticPropertyValidateSet<TreeGuide> {
}

public sealed class SpectreConsoleSpinner : IValidateSetValuesGenerator {
    public string[] GetValidValues()
        => typeof(Spinner.Known).GetProperties(BindingFlags.Public | BindingFlags.Static)
            .Where(property => property.PropertyType == typeof(Spinner))
            .Select(property => property.Name)
            .ToArray();
}

public sealed class SpectreConsoleExceptionFormats : IValidateSetValuesGenerator {
    public string[] GetValidValues() => Enum.GetNames<ExceptionFormats>();
}

public sealed class SpectreConsoleJustify : IValidateSetValuesGenerator {
    public string[] GetValidValues() => Enum.GetNames<Justify>();
}

public sealed class SpectreConsoleHorizontalAlignment : IValidateSetValuesGenerator {
    public string[] GetValidValues() => Enum.GetNames<HorizontalAlignment>();
}

public sealed class SpectreConsoleVerticalAlignment : IValidateSetValuesGenerator {
    public string[] GetValidValues() => Enum.GetNames<VerticalAlignment>();
}
