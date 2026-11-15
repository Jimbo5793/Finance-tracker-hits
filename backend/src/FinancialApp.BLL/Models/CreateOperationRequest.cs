using System.Text.Json;

namespace FinancialApp.BLL.Models;

/// <summary>
/// Body of POST /operations. Any other fields (e.g. a user id) are ignored.
/// WalletId, Type and Amount are kept as raw JSON so a wrong value like "abc" gets a proper field error
/// instead of a generic "could not read the body" error.
/// Type is "income" or "expense", optional, and defaults to "expense". Date is "yyyy-MM-dd" and defaults to today (UTC).
/// </summary>
public record CreateOperationRequest(JsonElement? WalletId, JsonElement? Type, JsonElement? Amount, string? Date);
