using System.Text.Json;

namespace FinancialApp.BLL.Models;

/// <summary>
/// Body of POST /categories. Any other fields (e.g. a user id) are ignored.
/// Mandatory is optional, only for expense categories, and kept as raw JSON so a wrong value gets a proper field error.
/// </summary>
public record CreateCategoryRequest(string? Name, string? Icon, string? Kind, JsonElement? Mandatory = null);
