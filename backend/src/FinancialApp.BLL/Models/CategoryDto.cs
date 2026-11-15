namespace FinancialApp.BLL.Models;

/// <summary>Mandatory is true or false for expense categories and null for income categories.</summary>
public record CategoryDto(int Id, string Name, string Icon, string Kind, bool? Mandatory);
