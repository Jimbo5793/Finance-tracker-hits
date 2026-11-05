using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinancialApp.DB.Configs;

public class CurrencyConfig : IEntityTypeConfiguration<Currency>
{
    public void Configure(EntityTypeBuilder<Currency> b)
    {
        b.ToTable("currencies");
        b.HasKey(c => c.Code);
        
        b.Property(c => c.Code).HasColumnName("code").HasMaxLength(3).IsRequired();
        b.Property(c => c.Name).HasColumnName("name").HasMaxLength(100).IsRequired();
        b.Property(c => c.Symbol).HasColumnName("symbol").HasMaxLength(10).IsRequired();
        
        b.HasData(
            new Currency { Code = "USD", Name = "US Dollar", Symbol = "$" },
            new Currency { Code = "EUR", Name = "Euro", Symbol = "€" },
            new Currency { Code = "RUB", Name = "Russian Ruble", Symbol = "₽" },
            new Currency { Code = "GBP", Name = "British Pound", Symbol = "£" },
            new Currency { Code = "IDR", Name = "Indonesian Rupiah", Symbol = "Rp" });
    }
}