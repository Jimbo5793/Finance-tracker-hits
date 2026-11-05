namespace FinancialApp.BLL.Models;

/// <summary>Balance is in the wallet's own currency. Nothing is converted.</summary>
public record WalletDto(int Id, string Name, string Type, string Currency, decimal Balance);
