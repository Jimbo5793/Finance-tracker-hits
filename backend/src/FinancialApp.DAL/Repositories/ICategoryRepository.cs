using FinancialApp.DB.Entities;

namespace FinancialApp.DAL.Repositories;

public interface ICategoryRepository
{
    /// <summary>Categories of one user, sorted by name (case-insensitive). A null kind means all kinds.</summary>
    Task<IReadOnlyList<Category>> GetByUserAsync(int userId, string? kind, CancellationToken ct = default);

    /// <summary>The category, or null if it does not exist or belongs to another user.</summary>
    Task<Category?> GetForUserAsync(int categoryId, int userId, CancellationToken ct = default);

    /// <summary>True if the user has a category of this kind with this name. Case-insensitive, like the database column.</summary>
    Task<bool> NameExistsAsync(int userId, string kind, string name, CancellationToken ct = default);

    /// <summary>
    /// Saves the category and its audit log entry in one transaction: either both are saved or neither.
    /// Throws <see cref="CategoryNameTakenException"/> if the user already has a category of this kind with this name.
    /// </summary>
    Task CreateWithAuditAsync(Category category, CancellationToken ct = default);
}
