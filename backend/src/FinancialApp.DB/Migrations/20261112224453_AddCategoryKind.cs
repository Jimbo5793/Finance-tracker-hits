using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FinancialApp.DB.Migrations
{
    /// <inheritdoc />
    public partial class AddCategoryKind : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ux_categories_user_name",
                table: "categories");

            migrationBuilder.DropCheckConstraint(
                name: "ck_categories_name_length",
                table: "categories");

            migrationBuilder.AddColumn<string>(
                name: "kind",
                table: "categories",
                type: "character varying(10)",
                maxLength: 10,
                nullable: false,
                defaultValue: "expense");

            migrationBuilder.CreateIndex(
                name: "ux_categories_user_kind_name",
                table: "categories",
                columns: new[] { "user_id", "kind", "name" },
                unique: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_categories_kind",
                table: "categories",
                sql: "kind IN ('income', 'expense')");

            migrationBuilder.AddCheckConstraint(
                name: "ck_categories_name_length",
                table: "categories",
                sql: "char_length(name) BETWEEN 1 AND 30");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ux_categories_user_kind_name",
                table: "categories");

            migrationBuilder.DropCheckConstraint(
                name: "ck_categories_kind",
                table: "categories");

            migrationBuilder.DropCheckConstraint(
                name: "ck_categories_name_length",
                table: "categories");

            migrationBuilder.DropColumn(
                name: "kind",
                table: "categories");

            migrationBuilder.CreateIndex(
                name: "ux_categories_user_name",
                table: "categories",
                columns: new[] { "user_id", "name" },
                unique: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_categories_name_length",
                table: "categories",
                sql: "char_length(name) BETWEEN 1 AND 50");
        }
    }
}
