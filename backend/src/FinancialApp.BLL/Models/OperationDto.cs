namespace FinancialApp.BLL.Models;

/// <summary>Amounts are in the wallet's own currency. Date is serialized as "yyyy-MM-dd".</summary>
public record OperationDto(
    int Id,
    int WalletId,
    string Type,
    decimal Amount,
    DateOnly Date,
    int? CategoryId,
    string? Comment,
    decimal? TaxAmount);
