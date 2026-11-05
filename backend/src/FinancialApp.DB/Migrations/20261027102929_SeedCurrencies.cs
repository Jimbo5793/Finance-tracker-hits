using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace FinancialApp.DB.Migrations
{
    /// <inheritdoc />
    public partial class SeedCurrencies : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "currencies",
                columns: new[] { "code", "name", "symbol" },
                values: new object[,]
                {
                    { "EUR", "Euro", "€" },
                    { "GBP", "British Pound", "£" },
                    { "IDR", "Indonesian Rupiah", "Rp" },
                    { "RUB", "Russian Ruble", "₽" },
                    { "USD", "US Dollar", "$" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "currencies",
                keyColumn: "code",
                keyValue: "EUR");

            migrationBuilder.DeleteData(
                table: "currencies",
                keyColumn: "code",
                keyValue: "GBP");

            migrationBuilder.DeleteData(
                table: "currencies",
                keyColumn: "code",
                keyValue: "IDR");

            migrationBuilder.DeleteData(
                table: "currencies",
                keyColumn: "code",
                keyValue: "RUB");

            migrationBuilder.DeleteData(
                table: "currencies",
                keyColumn: "code",
                keyValue: "USD");
        }
    }
}
