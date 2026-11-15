using System.Globalization;
using System.Text.Json;
using FinancialApp.BLL.Models;
using FinancialApp.DAL.Repositories;
using FinancialApp.DB.Entities;

namespace FinancialApp.BLL.Services;

public class OperationService(
    IOperationRepository operations,
    IWalletRepository wallets,
    ICategoryRepository categories) : IOperationService
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
        var categoryId = ValidateCategoryId(request.CategoryId, Fail);
        var comment = ValidateComment(request.Comment, Fail);
        var taxAmount = ValidateTaxAmount(request.TaxAmount, errors.ContainsKey("amount") ? null : amount, Fail);

        // The category must be one of the user's own, of the same kind as the operation.
        if (categoryId is not null)
            await ValidateCategoryAsync(categoryId.Value, type, userId, Fail, ct);

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
            CategoryId = categoryId,
            Comment = comment,
            TaxAmount = taxAmount,
        };

        await operations.CreateWithAuditAsync(operation, userId, ct);

        return CreateOperationResult.Created(new OperationDto(
            operation.Id, operation.WalletId, operation.Type, operation.Amount, date,
            operation.CategoryId, operation.Comment, operation.TaxAmount));
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

    /// <summary>"income" or "expense", any capitalisation. A missing type means "expense".</summary>
    private static string? ValidateType(JsonElement? json, Action<string, string> fail)
    {
        if (json is null || json.Value.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null)
            return OperationTypes.Expense;

        var allowed = string.Join(", ", OperationTypes.All);
        if (json.Value.ValueKind != JsonValueKind.String)
        {
            fail("type", $"Type must be text. Allowed types: {allowed}.");
            return null;
        }

        var value = json.Value.GetString()!;
        if (string.IsNullOrWhiteSpace(value))
            return OperationTypes.Expense;

        // Accept any capitalisation, store the canonical spelling
        var type = OperationTypes.All.FirstOrDefault(t => string.Equals(t, value.Trim(), StringComparison.OrdinalIgnoreCase));
        if (type is null)
            fail("type", $"\"{value}\" is not an allowed type. Allowed types: {allowed}.");
        return type;
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

    /// <summary>Optional. Missing or null means no category.</summary>
    private static int? ValidateCategoryId(JsonElement? value, Action<string, string> fail)
    {
        if (value is null || value.Value.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null)
            return null;

        if (value.Value.ValueKind != JsonValueKind.Number || !value.Value.TryGetInt32(out var id))
        {
            fail("categoryId", "Category id must be a whole number.");
            return null;
        }

        return id;
    }

    private async Task ValidateCategoryAsync(
        int categoryId, string? type, int userId, Action<string, string> fail, CancellationToken ct)
    {
        var category = await categories.GetForUserAsync(categoryId, userId, ct);
        if (category is null)
            fail("categoryId", "Category not found.");
        else if (type is not null && category.Kind != type)
            fail("categoryId", $"\"{category.Name}\" is an {category.Kind} category. An {type} needs an {type} category.");
    }

    /// <summary>Optional. Missing, empty or only spaces means no comment.</summary>
    private static string? ValidateComment(string? value, Action<string, string> fail)
    {
        if (string.IsNullOrWhiteSpace(value))
            return null;

        var comment = value.Trim();
        if (comment.Length > Operation.MaxCommentLength)
            fail("comment", $"Comment can be at most {Operation.MaxCommentLength} characters.");
        return comment;
    }

    /// <summary>
    /// Optional. Between 0 and the amount, with at most 2 decimals.
    /// <paramref name="amount"/> is null when the amount itself is wrong; then only the tax amount's own rules are checked.
    /// </summary>
    private static decimal? ValidateTaxAmount(JsonElement? value, decimal? amount, Action<string, string> fail)
    {
        if (value is null || value.Value.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null)
            return null;

        if (value.Value.ValueKind != JsonValueKind.Number || !value.Value.TryGetDecimal(out var tax))
        {
            fail("taxAmount", "Tax amount must be a number.");
            return null;
        }

        if (tax < 0)
            fail("taxAmount", "Tax amount must be 0 or more.");
        else if (tax != decimal.Round(tax, 2))
            fail("taxAmount", "Tax amount can have at most 2 decimals.");
        else if (amount is not null && tax > amount)
            fail("taxAmount", "Tax amount cannot be bigger than the amount.");

        return tax;
    }
}
