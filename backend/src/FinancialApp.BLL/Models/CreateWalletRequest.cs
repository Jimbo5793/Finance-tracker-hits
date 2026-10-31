using System.Text.Json;

namespace FinancialApp.BLL.Models;

/// <summary>
/// Body of POST /wallets. Any other fields (e.g. a user id) are ignored.
/// StartingBalance is kept as raw JSON so a wrong value like "abc" gets a proper field error
/// instead of a generic "could not read the body" error.
/// </summary>
public record CreateWalletRequest(string? Name, string? Type, string? Currency, JsonElement? StartingBalance);
