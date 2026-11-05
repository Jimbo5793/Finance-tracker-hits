using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinancialApp.DB.Configs;

public class WalletConfig : IEntityTypeConfiguration<Wallet>
{
    public void Configure(EntityTypeBuilder<Wallet> b)
    {
        var types = string.Join(", ", WalletTypes.All.Select(t => $"'{t}'"));

        b.ToTable("wallets", t =>
        {
            t.HasCheckConstraint("ck_wallets_id_range", $"id BETWEEN {IdRanges.WalletsStart} AND {IdRanges.WalletsEnd}");
            t.HasCheckConstraint("ck_wallets_type", $"type IN ({types})");
            t.HasCheckConstraint("ck_wallets_starting_balance", "starting_balance >= 0");
            t.HasCheckConstraint("ck_wallets_name_length", "char_length(name) BETWEEN 1 AND 100");
        });

        b.HasKey(w => w.Id);
        b.Property(w => w.Id).HasColumnName("id").UseSequence("wallets_id_seq");
        b.Property(w => w.UserId).HasColumnName("user_id");
        b.Property(w => w.Name).HasColumnName("name").HasColumnType("citext").IsRequired();
        b.Property(w => w.Type).HasColumnName("type").HasMaxLength(20).IsRequired();
        b.Property(w => w.CurrencyCode).HasColumnName("currency").HasMaxLength(3).IsRequired();
        b.Property(w => w.StartingBalance).HasColumnName("starting_balance").HasColumnType("numeric(18,2)");
        b.Property(w => w.CreatedAt).HasColumnName("created_at")
            .HasColumnType("timestamptz").HasDefaultValueSql("now()");
        b.Property(w => w.UpdatedAt).HasColumnName("updated_at")
            .HasColumnType("timestamptz").HasDefaultValueSql("now()");

        b.HasOne(w => w.User).WithMany().HasForeignKey(w => w.UserId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne(w => w.Currency).WithMany().HasForeignKey(w => w.CurrencyCode).OnDelete(DeleteBehavior.Restrict);
        
        b.HasIndex(w => new { w.UserId, w.Name }).IsUnique().HasDatabaseName("ux_wallets_user_name");
    }
}