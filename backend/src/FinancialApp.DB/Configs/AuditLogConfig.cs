using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinancialApp.DB.Configs;

public class AuditLogConfig : IEntityTypeConfiguration<AuditLogEntry>
{
    public void Configure(EntityTypeBuilder<AuditLogEntry> b)
    {
        b.ToTable("audit_log");
        b.HasKey(a => a.Id);
        b.Property(a => a.Id).HasColumnName("id").UseIdentityAlwaysColumn();
        b.Property(a => a.UserId).HasColumnName("user_id");
        b.Property(a => a.Action).HasColumnName("action").HasMaxLength(50).IsRequired();
        b.Property(a => a.EntityType).HasColumnName("entity_type").HasMaxLength(50).IsRequired();
        b.Property(a => a.EntityId).HasColumnName("entity_id");
        b.Property(a => a.Data).HasColumnName("data").HasColumnType("jsonb").IsRequired();
        b.Property(a => a.CreatedAt).HasColumnName("created_at")
            .HasColumnType("timestamptz").HasDefaultValueSql("now()");

        b.HasOne(a => a.User).WithMany().HasForeignKey(a => a.UserId).OnDelete(DeleteBehavior.Restrict);
        b.HasIndex(a => new { a.EntityType, a.EntityId }).HasDatabaseName("ix_audit_log_entity");
    }
}
