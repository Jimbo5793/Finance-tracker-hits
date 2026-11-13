using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinancialApp.DB.Configs;

public class UserConfig : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> b)
    {
        b.ToTable("users", t =>
        {
            t.HasCheckConstraint("ck_users_id_range", $"id BETWEEN {IdRanges.UsersStart} AND {IdRanges.UsersEnd}");
            t.HasCheckConstraint("ck_users_email_format", "email LIKE '%@%' AND char_length(email) <= 255");
            t.HasCheckConstraint("ck_users_username_format",
                "username IS NULL OR (char_length(username) BETWEEN 3 AND 30 AND username !~ '[@[:space:]]')");
        });
        b.HasKey(u => u.Id);
        b.Property(u => u.Id).HasColumnName("id").UseSequence("users_id_seq");
        b.Property(u => u.Email).HasColumnName("email").HasColumnType("citext").IsRequired();
        b.Property(u => u.Username).HasColumnName("username").HasColumnType("citext");
        b.Property(u => u.PasswordHash).HasColumnName("password_hash");
        b.HasIndex(u => u.Email).IsUnique();
        b.HasIndex(u => u.Username).IsUnique().HasDatabaseName("ux_users_username");
        b.Property(u => u.CreatedAt).HasColumnName("created_at")
            .HasColumnType("timestamptz").HasDefaultValueSql("now()");
    }
}