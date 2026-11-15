using System.Text.Json;
using FinancialApp.DB;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace FinancialApp.DAL.Repositories;

public class CategoryRepository(AppDbContext db) : ICategoryRepository
{
    public async Task<IReadOnlyList<Category>> GetByUserAsync(int userId, string? kind, CancellationToken ct = default) =>
        await db.Categories.AsNoTracking()
            .Where(c => c.UserId == userId && (kind == null || c.Kind == kind))
            .OrderBy(c => c.Name) // citext, so "apple" comes before "Banana"
            .ThenBy(c => c.Kind)  // the same name can exist once per kind
            .ToListAsync(ct);

    // name is citext, so this comparison is case-insensitive in the database
    public Task<bool> NameExistsAsync(int userId, string kind, string name, CancellationToken ct = default) =>
        db.Categories.AnyAsync(c => c.UserId == userId && c.Kind == kind && c.Name == name, ct);

    public async Task CreateWithAuditAsync(Category category, CancellationToken ct = default)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);

        db.Categories.Add(category);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException e) when (e.InnerException is PostgresException
                                          {
                                              SqlState: PostgresErrorCodes.UniqueViolation,
                                              ConstraintName: "ux_categories_user_kind_name"
                                          })
        {
            throw new CategoryNameTakenException(category.Name, category.Kind, e);
        }

        db.AuditLog.Add(new AuditLogEntry
        {
            UserId = category.UserId,
            Action = AuditActions.CategoryCreated,
            EntityType = "category",
            EntityId = category.Id,
            Data = JsonSerializer.Serialize(new
            {
                category.Name,
                category.Icon,
                category.Kind,
            }, JsonSerializerOptions.Web),
        });
        await db.SaveChangesAsync(ct);

        await tx.CommitAsync(ct);
    }
}
