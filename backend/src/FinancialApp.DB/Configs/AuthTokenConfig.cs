using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinancialApp.DB.Configs;

public class AuthTokenConfig : IEntityTypeConfiguration<AuthToken>
{
    public void Configure(EntityTypeBuilder<AuthToken> b)
    {
        b.ToTable("auth_tokens", t =>
            t.HasCheckConstraint("ck_auth_tokens_id_range",
                $"id BETWEEN {IdRanges.AuthTokensStart} AND {IdRanges.AuthTokensEnd}"));

        b.HasKey(a => a.Id);
        b.Property(a => a.Id).HasColumnName("id").UseSequence("auth_tokens_id_seq");
        b.Property(a => a.UserId).HasColumnName("user_id");
        b.Property(a => a.Jti).HasColumnName("jti");
        b.Property(a => a.CreatedAt).HasColumnName("created_at")
            .HasColumnType("timestamptz").HasDefaultValueSql("now()");
        b.Property(a => a.ExpiresAt).HasColumnName("expires_at").HasColumnType("timestamptz");

        b.HasOne(a => a.User).WithMany().HasForeignKey(a => a.UserId).OnDelete(DeleteBehavior.Restrict);
        b.HasIndex(a => a.Jti).IsUnique().HasDatabaseName("ux_auth_tokens_jti");
    }
}