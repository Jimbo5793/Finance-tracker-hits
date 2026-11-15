namespace FinancialApp.BLL.Models;

/// <summary>Amount is in the wallet's own currency. Date is serialized as "yyyy-MM-dd".</summary>
public record OperationDto(int Id, int WalletId, string Type, decimal Amount, DateOnly Date);
