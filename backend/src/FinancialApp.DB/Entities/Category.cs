namespace FinancialApp.DB.Entities;

public class Category
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Name { get; set; } = "";
    public string Icon { get; set; } = "";

    public User? User { get; set; }
}