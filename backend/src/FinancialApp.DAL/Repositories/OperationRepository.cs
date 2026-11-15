using System.Text.Json;
using FinancialApp.DB;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinancialApp.DAL.Repositories;

public class OperationRepository(AppDbContext db) : IOperationRepository
{
    public async Task<IReadOnlyDictionary<int, decimal>> GetNetByWalletAsync(
        IReadOnlyCollection<int> walletIds, CancellationToken ct = default)
    {
        var ids = walletIds.ToArray();

        var rows = await db.Operations.AsNoTracking()
            .Where(o => ids.Contains(o.WalletId))
            .GroupBy(o => o.WalletId)
            .Select(g => new
            {
                WalletId = g.Key,
                Net = g.Sum(o => o.Type == OperationTypes.Income ? o.Amount : -o.Amount)
            })
            .ToListAsync(ct);

        return rows.ToDictionary(r => r.WalletId, r => r.Net);
    }

    public async Task CreateWithAuditAsync(Operation operation, int userId, CancellationToken ct = default)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);

        db.Operations.Add(operation);
        await db.SaveChangesAsync(ct);

        db.AuditLog.Add(new AuditLogEntry
        {
            UserId = userId,
            Action = AuditActions.OperationCreated,
            EntityType = "operation",
            EntityId = operation.Id,
            Data = JsonSerializer.Serialize(new
            {
                operation.WalletId,
                operation.Type,
                operation.Amount,
                Date = DateOnly.FromDateTime(operation.OccurredAt),
                operation.CategoryId,
                operation.Comment,
                operation.TaxAmount,
            }, JsonSerializerOptions.Web),
        });
        await db.SaveChangesAsync(ct);

        await tx.CommitAsync(ct);
    }
}