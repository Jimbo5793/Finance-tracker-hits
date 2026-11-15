using System.Globalization;
using System.Text.Json;
using FinancialApp.BLL.Models;
using FinancialApp.DAL.Repositories;
using FinancialApp.DB.Entities;

namespace FinancialApp.BLL.Services;

public class OperationService(IOperationRepository operations, IWalletRepository wallets) : IOperationService
{
    public const string DateFormat = "yyyy-MM-dd";

    /// <summary>Largest value that fits the numeric(18,2) column.</summary>
    private const decimal MaxAmount = 9_999_999_999_999_999.99m;

    public async Task<CreateOperationResult> CreateAsync(int userId, CreateOperationRequest request, CancellationToken ct = default)
    {
        var errors = new Dictionary<string, List<string>>();
        void Fail(string field, string message)
        {
            if (!errors.TryGetValue(field, out var list)) errors[field] = list = [];
            list.Add(message);
        }

        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        var walletId = ValidateWalletId(request.WalletId, Fail);
        var type = ValidateType(request.Type, Fail);
        var amount = ValidateAmount(request.Amount, Fail);
        var date = ValidateDate(request.Date, today, Fail);

        if (errors.Count > 0)
            return CreateOperationResult.Invalid(errors.ToDictionary(e => e.Key, e => e.Value.ToArray()));

        // Another user's wallet answers the same as a missing one, so wallet ids of other users can't be probed.
        if (!await wallets.ExistsForUserAsync(walletId!.Value, userId, ct))
            return CreateOperationResult.WalletNotFound();

        var operation = new Operation
        {
            WalletId = walletId.Value,
            Type = type!,
            Amount = amount,
            OccurredAt = date.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc),
        };

        await operations.CreateWithAuditAsync(operation, userId, ct);

        return CreateOperationResult.Created(
            new OperationDto(operation.Id, operation.WalletId, operation.Type, operation.Amount, date));
    }

    private static int? ValidateWalletId(JsonElement? value, Action<string, string> fail)
    {
        if (value is null || value.Value.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null)
        {
            fail("walletId", "Wallet is required.");
            return null;
        }

        if (value.Value.ValueKind != JsonValueKind.Number || !value.Value.TryGetInt32(out var id))
        {
            fail("walletId", "Wallet id must be a whole number.");
            return null;
        }

        return id;
    }

    /// <summary>Only expenses for now. A missing type means "expense".</summary>
    private static string? ValidateType(string? value, Action<string, string> fail)
    {
        if (string.IsNullOrWhiteSpace(value))
            return OperationTypes.Expense;

        if (string.Equals(value.Trim(), OperationTypes.Expense, StringComparison.OrdinalIgnoreCase))
            return OperationTypes.Expense;

        fail("type", $"\"{value}\" is not allowed. Only \"{OperationTypes.Expense}\" can be recorded.");
        return null;
    }

    private static decimal ValidateAmount(JsonElement? value, Action<string, string> fail)
    {
        if (value is null || value.Value.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null)
        {
            fail("amount", "Amount is required.");
            return 0;
        }

        if (value.Value.ValueKind != JsonValueKind.Number || !value.Value.TryGetDecimal(out var amount))
        {
            fail("amount", "Amount must be a number.");
            return 0;
        }

        if (amount <= 0)
            fail("amount", "Amount must be more than 0.");
        else if (amount != decimal.Round(amount, 2))
            fail("amount", "Amount can have at most 2 decimals.");
        else if (amount > MaxAmount)
            fail("amount", "Amount is too large.");

        return amount;
    }

    /// <summary>Missing means today. Otherwise it must be a day of the current month (UTC).</summary>
    private static DateOnly ValidateDate(string? value, DateOnly today, Action<string, string> fail)
    {
        if (string.IsNullOrWhiteSpace(value))
            return today;

        if (!DateOnly.TryParseExact(value.Trim(), DateFormat, CultureInfo.InvariantCulture, DateTimeStyles.None, out var date))
        {
            fail("date", $"Date must be in the format {DateFormat}.");
            return today;
        }

        var firstDay = new DateOnly(today.Year, today.Month, 1);
        var lastDay = firstDay.AddMonths(1).AddDays(-1);
        if (date < firstDay || date > lastDay)
            fail("date", $"Date must be in the current month ({firstDay.ToString(DateFormat, CultureInfo.InvariantCulture)} " +
                         $"to {lastDay.ToString(DateFormat, CultureInfo.InvariantCulture)}).");

        return date;
    }
}
