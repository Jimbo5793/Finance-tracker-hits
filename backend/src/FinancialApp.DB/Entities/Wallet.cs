namespace FinancialApp.DB.Entities;

public class Wallet
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Name { get; set; } = "";
    public string Type { get; set; } = WalletTypes.Cash;
    public string CurrencyCode { get; set; } = "";
    public decimal StartingBalance { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public User? User { get; set; }
    public Currency? Currency { get; set; }
}