using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FinancialApp.DB.Migrations
{
    /// <inheritdoc />
    public partial class CreateWallets : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateSequence<int>(
                name: "wallets_id_seq",
                startValue: 11000001L,
                maxValue: 11999999L);

            migrationBuilder.CreateTable(
                name: "wallets",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false, defaultValueSql: "nextval('wallets_id_seq')"),
                    user_id = table.Column<int>(type: "integer", nullable: false),
                    name = table.Column<string>(type: "citext", nullable: false),
                    type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false),
                    starting_balance = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamptz", nullable: false, defaultValueSql: "now()"),
                    updated_at = table.Column<DateTime>(type: "timestamptz", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_wallets", x => x.id);
                    table.CheckConstraint("ck_wallets_id_range", "id BETWEEN 11000001 AND 11999999");
                    table.CheckConstraint("ck_wallets_name_length", "char_length(name) BETWEEN 1 AND 100");
                    table.CheckConstraint("ck_wallets_starting_balance", "starting_balance >= 0");
                    table.CheckConstraint("ck_wallets_type", "type IN ('cash', 'bank card', 'PayPal', 'e-wallet', 'savings')");
                    table.ForeignKey(
                        name: "FK_wallets_currencies_currency",
                        column: x => x.currency,
                        principalTable: "currencies",
                        principalColumn: "code",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_wallets_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_wallets_currency",
                table: "wallets",
                column: "currency");

            migrationBuilder.CreateIndex(
                name: "ux_wallets_user_name",
                table: "wallets",
                columns: new[] { "user_id", "name" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "wallets");

            migrationBuilder.DropSequence(
                name: "wallets_id_seq");
        }
    }
}
