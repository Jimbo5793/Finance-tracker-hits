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
            t.HasCheckConstraint("ck_categories_name_length", "char_length(name) BETWEEN 1 AND 30");
            var kinds = string.Join(", ", CategoryKinds.All.Select(k => $"'{k}'"));
            t.HasCheckConstraint("ck_categories_kind", $"kind IN ({kinds})");
            t.HasCheckConstraint("ck_categories_mandatory",
                $"(kind = '{CategoryKinds.Expense}' AND is_mandatory IS NOT NULL) OR (kind = '{CategoryKinds.Income}' AND is_mandatory IS NULL)");
        });

        b.HasKey(c => c.Id);
        b.Property(c => c.Id).HasColumnName("id").UseSequence("categories_id_seq");
        b.Property(c => c.UserId).HasColumnName("user_id");
        b.Property(c => c.Name).HasColumnName("name").HasColumnType("citext").IsRequired();
        b.Property(c => c.Icon).HasColumnName("icon").HasMaxLength(50).IsRequired();
        b.Property(c => c.Kind).HasColumnName("kind").HasMaxLength(10).IsRequired()
            .HasDefaultValue(CategoryKinds.Expense);
        b.Property(c => c.IsMandatory).HasColumnName("is_mandatory");

        b.HasOne(c => c.User).WithMany().HasForeignKey(c => c.UserId).OnDelete(DeleteBehavior.Restrict);
        b.HasIndex(c => new { c.UserId, c.Kind, c.Name }).IsUnique().HasDatabaseName("ux_categories_user_kind_name");    }
}