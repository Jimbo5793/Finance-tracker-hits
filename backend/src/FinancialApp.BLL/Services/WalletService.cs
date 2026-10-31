using System.Text.Json;
using FinancialApp.BLL.Models;
using FinancialApp.DAL.Repositories;
using FinancialApp.DB.Entities;

namespace FinancialApp.BLL.Services;

public class WalletService(
    IWalletRepository wallets,
    ICurrencyRepository currencies,
    IWalletBalanceCalculator balances) : IWalletService
{
    public const int MaxNameLength = 50;

    /// <summary>Largest value that fits the numeric(18,2) column.</summary>
    private const decimal MaxBalance = 9_999_999_999_999_999.99m;

    public async Task<IReadOnlyList<WalletDto>> GetForUserAsync(int userId, CancellationToken ct = default)
    {
        var list = await wallets.GetByUserAsync(userId, ct);
        var balanceById = await balances.GetBalancesAsync(list, ct);

        return list
            .Select(w => new WalletDto(w.Id, w.Name, w.Type, w.CurrencyCode, balanceById[w.Id]))
            .ToList();
    }

    public async Task<CreateWalletResult> CreateAsync(int userId, CreateWalletRequest request, CancellationToken ct = default)
    {
        var errors = new Dictionary<string, List<string>>();
        void Fail(string field, string message)
        {
            if (!errors.TryGetValue(field, out var list)) errors[field] = list = [];
            list.Add(message);
        }

        var type = ValidateType(request.Type, Fail);
        var currency = await ValidateCurrencyAsync(request.Currency, Fail, ct);
        var startingBalance = ValidateStartingBalance(request.StartingBalance, Fail);

        var existingNames = await wallets.GetNamesAsync(userId, ct);
        var name = ValidateName(request.Name, type, existingNames, Fail);

        if (errors.Count > 0)
            return Invalid(errors);

        var wallet = new Wallet
        {
            UserId = userId, // always the logged-in user, never anything from the request
            Name = name!,
            Type = type!,
            CurrencyCode = currency!,
            StartingBalance = startingBalance,
        };

        try
        {
            await wallets.CreateWithAuditAsync(wallet, ct);
        }
        catch (WalletNameTakenException)
        {
            // Someone created a wallet with the same name between our check and the insert.
            Fail("name", NameTakenMessage(wallet.Name));
            return Invalid(errors);
        }

        var balanceById = await balances.GetBalancesAsync([wallet], ct);
        return CreateWalletResult.Created(
            new WalletDto(wallet.Id, wallet.Name, wallet.Type, wallet.CurrencyCode, balanceById[wallet.Id]));
    }

    private static string? ValidateType(string? value, Action<string, string> fail)
    {
        var allowed = string.Join(", ", WalletTypes.All);
        if (string.IsNullOrWhiteSpace(value))
        {
            fail("type", $"Type is required. Allowed types: {allowed}.");
            return null;
        }

        // Accept any capitalisation, store the canonical spelling
        var type = WalletTypes.All.FirstOrDefault(t => string.Equals(t, value.Trim(), StringComparison.OrdinalIgnoreCase));
        if (type is null)
            fail("type", $"\"{value}\" is not an allowed type. Allowed types: {allowed}.");
        return type;
    }

    private async Task<string?> ValidateCurrencyAsync(string? value, Action<string, string> fail, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            fail("currency", "Currency is required.");
            return null;
        }

        var all = await currencies.GetAllAsync(ct);
        var code = all.Select(c => c.Code)
            .FirstOrDefault(c => string.Equals(c, value.Trim(), StringComparison.OrdinalIgnoreCase));
        if (code is null)
            fail("currency", $"\"{value}\" is not in the currency list. Allowed: {string.Join(", ", all.Select(c => c.Code))}.");
        return code;
    }

    private static decimal ValidateStartingBalance(JsonElement? value, Action<string, string> fail)
    {
        if (value is null || value.Value.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null)
        {
            fail("startingBalance", "Starting balance is required.");
            return 0;
        }

        if (value.Value.ValueKind != JsonValueKind.Number || !value.Value.TryGetDecimal(out var amount))
        {
            fail("startingBalance", "Starting balance must be a number.");
            return 0;
        }

        if (amount < 0)
            fail("startingBalance", "Starting balance must be 0 or more.");
        else if (amount != decimal.Round(amount, 2))
            fail("startingBalance", "Starting balance can have at most 2 decimals.");
        else if (amount > MaxBalance)
            fail("startingBalance", "Starting balance is too large.");

        return amount;
    }

    private static string? ValidateName(
        string? value, string? type, IReadOnlySet<string> existingNames, Action<string, string> fail)
    {
        // Missing or empty: generate "[Type] #n". Needs a valid type; if the type is wrong, that error is enough.
        if (string.IsNullOrEmpty(value))
            return type is null ? null : DefaultName(type, existingNames);

        var name = value.Trim();
        if (name.Length == 0)
            fail("name", "Name cannot be only spaces.");
        else if (name.Length > MaxNameLength)
            fail("name", $"Name can be at most {MaxNameLength} characters.");
        else if (existingNames.Contains(name))
            fail("name", NameTakenMessage(name));

        return name;
    }

    /// <summary>"[Type] #n" with the smallest n, starting at 1, that this user hasn't used yet.</summary>
    private static string DefaultName(string type, IReadOnlySet<string> existingNames)
    {
        var label = char.ToUpperInvariant(type[0]) + type[1..]; // "cash" → "Cash", "bank card" → "Bank card"
        for (var n = 1; ; n++)
        {
            var candidate = $"{label} #{n}";
            if (!existingNames.Contains(candidate))
                return candidate;
        }
    }

    private static string NameTakenMessage(string name) => $"You already have a wallet called \"{name}\".";

    private static CreateWalletResult Invalid(Dictionary<string, List<string>> errors) =>
        CreateWalletResult.Invalid(errors.ToDictionary(e => e.Key, e => e.Value.ToArray()));
}
