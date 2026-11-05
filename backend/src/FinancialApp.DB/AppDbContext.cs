using FinancialApp.DB.Configs;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinancialApp.DB;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Currency> Currencies => Set<Currency>();
    public DbSet<Wallet> Wallets => Set<Wallet>();
    public DbSet<AuditLogEntry> AuditLog => Set<AuditLogEntry>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("citext");
        modelBuilder.HasSequence<int>("users_id_seq").StartsAt(IdRanges.UsersStart).HasMax(IdRanges.UsersEnd);
        modelBuilder.HasSequence<int>("wallets_id_seq").StartsAt(IdRanges.WalletsStart).HasMax(IdRanges.WalletsEnd);

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }

    public override int SaveChanges(bool acceptAllChangesOnSuccess)
    {
        TouchUpdatedAt();
        return base.SaveChanges(acceptAllChangesOnSuccess);
    }

    public override Task<int> SaveChangesAsync(bool acceptAllChangesOnSuccess, CancellationToken ct = default)
    {
        TouchUpdatedAt();
        return base.SaveChangesAsync(acceptAllChangesOnSuccess, ct);
    }

    private void TouchUpdatedAt()
    {
        foreach (var e in ChangeTracker.Entries<Wallet>().Where(e => e.State == EntityState.Modified))
            e.Entity.UpdatedAt = DateTime.UtcNow;
    }
}