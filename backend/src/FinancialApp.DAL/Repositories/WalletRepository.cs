using System.Text.Json;
using FinancialApp.DB;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace FinancialApp.DAL.Repositories;

public class WalletRepository(AppDbContext db) : IWalletRepository
{
    public async Task<IReadOnlyList<Wallet>> GetByUserAsync(int userId, CancellationToken ct = default) =>
        await db.Wallets.AsNoTracking()
            .Where(w => w.UserId == userId)
            .OrderBy(w => w.CreatedAt)
            .ThenBy(w => w.Id) // wallets created in the same transaction share created_at
            .ToListAsync(ct);

    public async Task<IReadOnlySet<string>> GetNamesAsync(int userId, CancellationToken ct = default)
    {
        var names = await db.Wallets.AsNoTracking()
            .Where(w => w.UserId == userId)
            .Select(w => w.Name)
            .ToListAsync(ct);
        return new HashSet<string>(names, StringComparer.OrdinalIgnoreCase);
    }

    public async Task CreateWithAuditAsync(Wallet wallet, CancellationToken ct = default)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);

        db.Wallets.Add(wallet);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException e) when (e.InnerException is PostgresException
                                          {
                                              SqlState: PostgresErrorCodes.UniqueViolation,
                                              ConstraintName: "ux_wallets_user_name"
                                          })
        {
            throw new WalletNameTakenException(wallet.Name, e);
        }

        db.AuditLog.Add(new AuditLogEntry
        {
            UserId = wallet.UserId,
            Action = AuditActions.WalletCreated,
            EntityType = "wallet",
            EntityId = wallet.Id,
            Data = JsonSerializer.Serialize(new
            {
                wallet.Name,
                wallet.Type,
                Currency = wallet.CurrencyCode,
                wallet.StartingBalance,
            }, JsonSerializerOptions.Web),
        });
        await db.SaveChangesAsync(ct);

        await tx.CommitAsync(ct);
    }
}
