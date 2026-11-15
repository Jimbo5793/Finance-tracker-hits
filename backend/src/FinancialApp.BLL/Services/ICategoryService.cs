using FinancialApp.BLL.Models;

namespace FinancialApp.BLL.Services;

public interface ICategoryService
{
    /// <summary>Categories of the user. A null or empty kind means all kinds; an unknown kind is an error.</summary>
    Task<GetCategoriesResult> GetForUserAsync(int userId, string? kind, CancellationToken ct = default);

    Task<CreateCategoryResult> CreateAsync(int userId, CreateCategoryRequest request, CancellationToken ct = default);
}
