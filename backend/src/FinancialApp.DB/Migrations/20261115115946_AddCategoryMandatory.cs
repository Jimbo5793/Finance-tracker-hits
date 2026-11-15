using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FinancialApp.DB.Migrations
{
    /// <inheritdoc />
    public partial class AddCategoryMandatory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "is_mandatory",
                table: "categories",
                type: "boolean",
                nullable: true);

            // Existing expense categories become non-mandatory, so they pass the check below.
            migrationBuilder.Sql("UPDATE categories SET is_mandatory = false WHERE kind = 'expense';");

            migrationBuilder.AddCheckConstraint(
                name: "ck_categories_mandatory",
                table: "categories",
                sql: "(kind = 'expense' AND is_mandatory IS NOT NULL) OR (kind = 'income' AND is_mandatory IS NULL)");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_categories_mandatory",
                table: "categories");

            migrationBuilder.DropColumn(
                name: "is_mandatory",
                table: "categories");
        }
    }
}
