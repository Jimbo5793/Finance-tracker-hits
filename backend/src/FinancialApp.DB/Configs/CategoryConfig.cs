using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinancialApp.DB.Configs;

public class CategoryConfig : IEntityTypeConfiguration<Category>
{
    public void Configure(EntityTypeBuilder<Category> b)
    {
        b.ToTable("categories", t =>
        {
            t.HasCheckConstraint("ck_categories_id_range",
                $"id BETWEEN {IdRanges.CategoriesStart} AND {IdRanges.CategoriesEnd}");
            t.HasCheckConstraint("ck_categories_name_length", "char_length(name) BETWEEN 1 AND 50");
        });

        b.HasKey(c => c.Id);
        b.Property(c => c.Id).HasColumnName("id").UseSequence("categories_id_seq");
        b.Property(c => c.UserId).HasColumnName("user_id");
        b.Property(c => c.Name).HasColumnName("name").HasColumnType("citext").IsRequired();
        b.Property(c => c.Icon).HasColumnName("icon").HasMaxLength(50).IsRequired();

        b.HasOne(c => c.User).WithMany().HasForeignKey(c => c.UserId).OnDelete(DeleteBehavior.Restrict);
        b.HasIndex(c => new { c.UserId, c.Name }).IsUnique().HasDatabaseName("ux_categories_user_name");
    }
}