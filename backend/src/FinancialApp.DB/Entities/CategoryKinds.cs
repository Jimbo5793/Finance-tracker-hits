namespace FinancialApp.DB.Entities;

public static class CategoryKinds
{
    public const string Income = "income";
    public const string Expense = "expense";

    public static readonly string[] All = [Income, Expense];
}