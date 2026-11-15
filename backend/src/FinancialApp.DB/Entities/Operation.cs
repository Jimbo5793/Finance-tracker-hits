namespace FinancialApp.DB.Entities;

public class Operation
{
    public const int MaxCommentLength = 200;

    public int Id { get; set; }
    public int WalletId { get; set; }
    public string Type { get; set; } = OperationTypes.Expense;
    public decimal Amount { get; set; }
    public DateTime OccurredAt { get; set; }
    public int? CategoryId { get; set; }
    public string? Comment { get; set; }
    /// <summary>The part of Amount that is tax. Between 0 and Amount.</summary>
    public decimal? TaxAmount { get; set; }

    public Wallet? Wallet { get; set; }
    public Category? Category { get; set; }
}