using System.Collections;
using System.Management.Automation;
using Spectre.Console;

namespace PwshSpectreConsole.PowerShell;

public static class TreeUtilities {
    public static Hashtable TransformTreeItem(object treeItem) {
        if (treeItem is PSObject psObject) treeItem = psObject.BaseObject;
        if (treeItem is not IDictionary dictionary) {
            throw new ArgumentException("Input for Spectre Tree must be a hashtable with 'Value' (and the optional 'Children') keys");
        }

        bool hasValue = dictionary.Contains("Value");
        bool hasLabel = dictionary.Contains("Label");
        if (!hasValue && !hasLabel) {
            throw new ArgumentException("Input for Spectre Tree must be a hashtable with 'Value' (and the optional 'Children') keys");
        }

        object? value = dictionary[hasValue ? "Value" : "Label"];
        if (value is null) {
            throw new ArgumentException("Spectre tree value cannot be null");
        }

        var result = new Hashtable(StringComparer.OrdinalIgnoreCase) {
            ["Value"] = value,
            ["Children"] = Array.Empty<object>()
        };

        if (dictionary.Contains("Children")) {
            object? children = dictionary["Children"];
            if (children is not object[]) {
                throw new ArgumentException("Children must be an array of tree items (hashtables with 'Value' and 'Children' keys)");
            }

            result["Children"] = ((object[])children).Select(child => (object)TransformTreeItem(child)).ToArray();
        }

        return result;
    }

    public static void AddNodes(IHasTreeNodes node, IEnumerable children) {
        foreach (object child in children) {
            object unwrapped = child is PSObject psObject ? psObject.BaseObject : child;
            object? value = GetValue(unwrapped, "Value") ?? GetValue(unwrapped, "Label");
            TreeNode newNode = value is IRenderable renderable
                ? HasTreeNodeExtensions.AddNode(node, renderable)
                : HasTreeNodeExtensions.AddNode(node, value?.ToString() ?? string.Empty);
            object? childItems = GetValue(unwrapped, "Children");
            if (childItems is IEnumerable enumerable && enumerable.Cast<object>().Any()) {
                AddNodes(newNode, enumerable);
            }
        }
    }

    private static object? GetValue(object value, string key) {
        if (value is IDictionary dictionary && dictionary.Contains(key)) return dictionary[key];
        return PSObject.AsPSObject(value).Properties[key]?.Value;
    }
}
