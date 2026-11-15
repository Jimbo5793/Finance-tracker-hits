namespace FinancialApp.DB.Entities;

public class Category
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Name { get; set; } = "";
    public string Icon { get; set; } = "";
    public string Kind { get; set; } = CategoryKinds.Expense;
    /// <summary>True or false for expense categories, always null for income categories.</summary>
    public bool? IsMandatory { get; set; }

    public User? User { get; set; }
}