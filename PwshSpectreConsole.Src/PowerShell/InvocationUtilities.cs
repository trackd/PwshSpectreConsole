using System.Management.Automation;
using Spectre.Console;
using Spectre.Console.Rendering;

namespace PwshSpectreConsole.PowerShell;

public static class InvocationUtilities {
    public static Func<object, int, Color, object?>? PromptOverride { get; set; }
    public static Func<ScriptBlock, object?>? ProgressOverride { get; set; }
    public static Func<string, Spinner, Style, ScriptBlock, object?>? StatusOverride { get; set; }
    public static Func<IRenderable, ScriptBlock, object?>? LiveOverride { get; set; }
    public static object? LastPrompt { get; private set; }
    public static int PromptCallCount { get; private set; }
    public static bool UseTestPromptResult { get; set; }
    public static object? TestPromptResult { get; set; }

    public static object? InvokePrompt(TextPrompt<string> prompt, int timeoutSeconds, Color defaultValueColor)
        => InvokePromptWithOverride(prompt, timeoutSeconds, defaultValueColor);

    public static object? InvokePrompt(SelectionPrompt<string> prompt, int timeoutSeconds, Color defaultValueColor)
        => InvokePromptWithOverride(prompt, timeoutSeconds, defaultValueColor);

    public static object? InvokePrompt(MultiSelectionPrompt<string> prompt, int timeoutSeconds, Color defaultValueColor)
        => InvokePromptWithOverride(prompt, timeoutSeconds, defaultValueColor);

    public static object? StartProgress(ScriptBlock scriptBlock) {
        ArgumentNullException.ThrowIfNull(scriptBlock);
        if (ProgressOverride is not null) return ProgressOverride(scriptBlock);
        object? result = null;
        AnsiConsole.Progress().Start(context => result = scriptBlock.InvokeReturnAsIs(context));
        return result;
    }

    public static object? StartStatus(string title, Spinner spinner, Style spinnerStyle, ScriptBlock scriptBlock) {
        ArgumentNullException.ThrowIfNull(title);
        ArgumentNullException.ThrowIfNull(spinner);
        ArgumentNullException.ThrowIfNull(spinnerStyle);
        ArgumentNullException.ThrowIfNull(scriptBlock);
        if (StatusOverride is not null) return StatusOverride(title, spinner, spinnerStyle, scriptBlock);
        object? result = null;
        AnsiConsole.Status().Start(title, context => {
            context.Spinner = spinner;
            context.SpinnerStyle = spinnerStyle;
            result = scriptBlock.InvokeReturnAsIs(context);
        });
        return result;
    }

    public static object? StartLive(IRenderable data, ScriptBlock scriptBlock) {
        ArgumentNullException.ThrowIfNull(data);
        ArgumentNullException.ThrowIfNull(scriptBlock);
        if (LiveOverride is not null) return LiveOverride(data, scriptBlock);
        ConsoleUtilities.EnsureDimensions();
        object? result = null;
        AnsiConsole.Live(data).Start(context => result = scriptBlock.InvokeReturnAsIs(context));
        return result;
    }

    private static object? InvokePromptCore<T>(IPrompt<T> prompt, int timeoutSeconds, Color defaultValueColor) {
        DateTimeOffset? timeout = timeoutSeconds > 0
            ? DateTimeOffset.Now.AddSeconds(timeoutSeconds)
            : null;

        if (timeout.HasValue) {
            AnsiConsole.Markup($"[{defaultValueColor.ToMarkup()}]This prompt times out in {timeoutSeconds} seconds...[/]{Environment.NewLine}");
        }

        using var cancellation = new CancellationTokenSource();
        Task<T> task = prompt.ShowAsync(AnsiConsole.Console, cancellation.Token);
        try {
            WaitHandle waitHandle = ((IAsyncResult)task).AsyncWaitHandle;
            while (!waitHandle.WaitOne(200)) {
                if (timeout.HasValue && DateTimeOffset.Now >= timeout.Value) {
                    cancellation.Cancel();
                    AnsiConsole.Markup($"{Environment.NewLine}{Environment.NewLine}[{defaultValueColor.ToMarkup()}]Prompt timed out[/]");
                }
            }

            return task.IsCanceled ? null : task.GetAwaiter().GetResult();
        }
        finally {
            cancellation.Cancel();
            task.Dispose();
        }
    }

    private static object? InvokePromptWithOverride<T>(IPrompt<T> prompt, int timeoutSeconds, Color defaultValueColor) {
        LastPrompt = prompt;
        PromptCallCount++;
        if (UseTestPromptResult) return TestPromptResult;
        return PromptOverride is null
            ? InvokePromptCore(prompt, timeoutSeconds, defaultValueColor)
            : PromptOverride(prompt, timeoutSeconds, defaultValueColor);
    }

    public static void ResetTestHooks() {
        PromptOverride = null;
        ProgressOverride = null;
        StatusOverride = null;
        LiveOverride = null;
        LastPrompt = null;
        PromptCallCount = 0;
        UseTestPromptResult = false;
        TestPromptResult = null;
    }
}
