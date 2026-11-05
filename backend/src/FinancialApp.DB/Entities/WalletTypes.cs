namespace FinancialApp.DB.Entities;

public static class WalletTypes
{
    public const string Cash = "cash";
    public const string BankCard = "bank card";
    public const string PayPal = "PayPal";
    public const string EWallet = "e-wallet";
    public const string Savings = "savings";

    public static readonly string[] All = [Cash, BankCard, PayPal, EWallet, Savings];
}