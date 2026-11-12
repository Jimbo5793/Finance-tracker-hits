using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FinancialApp.DB.Migrations
{
    /// <inheritdoc />
    public partial class CreateCategories : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateSequence<int>(
                name: "categories_id_seq",
                startValue: 12000001L,
                maxValue: 12999999L);

            migrationBuilder.CreateTable(
                name: "categories",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false, defaultValueSql: "nextval('categories_id_seq')"),
                    user_id = table.Column<int>(type: "integer", nullable: false),
                    name = table.Column<string>(type: "citext", nullable: false),
                    icon = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_categories", x => x.id);
                    table.CheckConstraint("ck_categories_id_range", "id BETWEEN 12000001 AND 12999999");
                    table.CheckConstraint("ck_categories_name_length", "char_length(name) BETWEEN 1 AND 50");
                    table.ForeignKey(
                        name: "FK_categories_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "ux_categories_user_name",
                table: "categories",
                columns: new[] { "user_id", "name" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "categories");

            migrationBuilder.DropSequence(
                name: "categories_id_seq");
        }
    }
}
