namespace FinancialApp.DB.Entities;

public class Operation
{
    public int Id { get; set; }
    public int WalletId { get; set; }
    public string Type { get; set; } = OperationTypes.Expense;
    public decimal Amount { get; set; }
    public DateTime OccurredAt { get; set; }

    public Wallet? Wallet { get; set; }
}