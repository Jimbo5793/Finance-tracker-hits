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
            t.HasCheckConstraint("ck_operations_tax_amount", "tax_amount IS NULL OR (tax_amount >= 0 AND tax_amount <= amount)");
            t.HasCheckConstraint("ck_operations_comment_length", $"char_length(comment) <= {Operation.MaxCommentLength}");
        });

        b.HasKey(o => o.Id);
        b.Property(o => o.Id).HasColumnName("id").UseSequence("operations_id_seq");
        b.Property(o => o.WalletId).HasColumnName("wallet_id");
        b.Property(o => o.Type).HasColumnName("type").HasMaxLength(10).IsRequired();
        b.Property(o => o.Amount).HasColumnName("amount").HasColumnType("numeric(18,2)");
        b.Property(o => o.OccurredAt).HasColumnName("occurred_at")
            .HasColumnType("timestamptz").HasDefaultValueSql("now()");
        b.Property(o => o.CategoryId).HasColumnName("category_id");
        b.Property(o => o.Comment).HasColumnName("comment").HasMaxLength(Operation.MaxCommentLength);
        b.Property(o => o.TaxAmount).HasColumnName("tax_amount").HasColumnType("numeric(18,2)");

        b.HasOne(o => o.Wallet).WithMany().HasForeignKey(o => o.WalletId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne(o => o.Category).WithMany().HasForeignKey(o => o.CategoryId).OnDelete(DeleteBehavior.Restrict);
        b.HasIndex(o => new { o.WalletId, o.OccurredAt }).HasDatabaseName("ix_operations_wallet_date");
        b.HasIndex(o => o.CategoryId).HasDatabaseName("ix_operations_category");
    }
}