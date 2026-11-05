using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinancialApp.DB.Configs;

public class UserConfig : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> b)
    {
        b.ToTable("users", t =>
            t.HasCheckConstraint("ck_users_id_range", $"id BETWEEN {IdRanges.UsersStart} AND {IdRanges.UsersEnd}"));
        b.HasKey(u => u.Id);
        b.Property(u => u.Id).HasColumnName("id").UseSequence("users_id_seq");
        b.Property(u => u.Email).HasColumnName("email").HasMaxLength(255).IsRequired();
        b.HasIndex(u => u.Email).IsUnique();
        b.Property(u => u.CreatedAt).HasColumnName("created_at")
            .HasColumnType("timestamptz").HasDefaultValueSql("now()");
    }
}