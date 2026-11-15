using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FinancialApp.DB.Migrations
{
    /// <inheritdoc />
    public partial class AddOperationCategoryCommentTax : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "category_id",
                table: "operations",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "comment",
                table: "operations",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "tax_amount",
                table: "operations",
                type: "numeric(18,2)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "ix_operations_category",
                table: "operations",
                column: "category_id");

            migrationBuilder.AddCheckConstraint(
                name: "ck_operations_comment_length",
                table: "operations",
                sql: "char_length(comment) <= 200");

            migrationBuilder.AddCheckConstraint(
                name: "ck_operations_tax_amount",
                table: "operations",
                sql: "tax_amount IS NULL OR (tax_amount >= 0 AND tax_amount <= amount)");

            migrationBuilder.AddForeignKey(
                name: "FK_operations_categories_category_id",
                table: "operations",
                column: "category_id",
                principalTable: "categories",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_operations_categories_category_id",
                table: "operations");

            migrationBuilder.DropIndex(
                name: "ix_operations_category",
                table: "operations");

            migrationBuilder.DropCheckConstraint(
                name: "ck_operations_comment_length",
                table: "operations");

            migrationBuilder.DropCheckConstraint(
                name: "ck_operations_tax_amount",
                table: "operations");

            migrationBuilder.DropColumn(
                name: "category_id",
                table: "operations");

            migrationBuilder.DropColumn(
                name: "comment",
                table: "operations");

            migrationBuilder.DropColumn(
                name: "tax_amount",
                table: "operations");
        }
    }
}
