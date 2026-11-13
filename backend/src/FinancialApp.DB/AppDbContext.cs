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
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Operation> Operations => Set<Operation>();
    public DbSet<AuthToken> AuthTokens => Set<AuthToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("citext");
        modelBuilder.HasSequence<int>("users_id_seq").StartsAt(IdRanges.UsersStart).HasMax(IdRanges.UsersEnd);
        modelBuilder.HasSequence<int>("wallets_id_seq").StartsAt(IdRanges.WalletsStart).HasMax(IdRanges.WalletsEnd);

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
        modelBuilder.HasSequence<int>("categories_id_seq").StartsAt(IdRanges.CategoriesStart).HasMax(IdRanges.CategoriesEnd);
        modelBuilder.HasSequence<int>("operations_id_seq").StartsAt(IdRanges.OperationsStart).HasMax(IdRanges.OperationsEnd);
        modelBuilder.HasSequence<int>("auth_tokens_id_seq").StartsAt(IdRanges.AuthTokensStart).HasMax(IdRanges.AuthTokensEnd);
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