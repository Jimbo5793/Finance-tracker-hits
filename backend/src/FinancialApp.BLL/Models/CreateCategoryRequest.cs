namespace FinancialApp.BLL.Models;

/// <summary>Body of POST /categories. Any other fields (e.g. a user id) are ignored.</summary>
public record CreateCategoryRequest(string? Name, string? Icon, string? Kind);
