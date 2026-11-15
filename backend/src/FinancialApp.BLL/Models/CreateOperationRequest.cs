using System.Text.Json;

namespace FinancialApp.BLL.Models;

/// <summary>
/// Body of POST /operations. Any other fields (e.g. a user id) are ignored.
/// WalletId and Amount are kept as raw JSON so a wrong value like "abc" gets a proper field error
/// instead of a generic "could not read the body" error.
/// Type is optional and defaults to "expense". Date is "yyyy-MM-dd" and defaults to today (UTC).
/// </summary>
public record CreateOperationRequest(JsonElement? WalletId, string? Type, JsonElement? Amount, string? Date);
