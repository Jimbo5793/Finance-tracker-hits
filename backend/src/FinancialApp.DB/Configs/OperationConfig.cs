using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinancialApp.DB.Configs;

public class OperationConfig : IEntityTypeConfiguration<Operation>
{
    public void Configure(EntityTypeBuilder<Operation> b)
    {
        var types = string.Join(", ", OperationTypes.All.Select(t => $"'{t}'"));

        b.ToTable("operations", t =>
        {
            t.HasCheckConstraint("ck_operations_id_range",
                $"id BETWEEN {IdRanges.OperationsStart} AND {IdRanges.OperationsEnd}");
            t.HasCheckConstraint("ck_operations_type", $"type IN ({types})");
            t.HasCheckConstraint("ck_operations_amount", "amount > 0");
        });

        b.HasKey(o => o.Id);
        b.Property(o => o.Id).HasColumnName("id").UseSequence("operations_id_seq");
        b.Property(o => o.WalletId).HasColumnName("wallet_id");
        b.Property(o => o.Type).HasColumnName("type").HasMaxLength(10).IsRequired();
        b.Property(o => o.Amount).HasColumnName("amount").HasColumnType("numeric(18,2)");
        b.Property(o => o.OccurredAt).HasColumnName("occurred_at")
            .HasColumnType("timestamptz").HasDefaultValueSql("now()");

        b.HasOne(o => o.Wallet).WithMany().HasForeignKey(o => o.WalletId).OnDelete(DeleteBehavior.Restrict);
        b.HasIndex(o => new { o.WalletId, o.OccurredAt }).HasDatabaseName("ix_operations_wallet_date");
    }
}