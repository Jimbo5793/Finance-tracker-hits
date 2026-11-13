using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FinancialApp.DB.Migrations
{
    /// <inheritdoc />
    public partial class AddLogin : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateSequence<int>(
                name: "auth_tokens_id_seq",
                startValue: 14000001L,
                maxValue: 14999999L);

            migrationBuilder.AlterColumn<string>(
                name: "email",
                table: "users",
                type: "citext",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(255)",
                oldMaxLength: 255);

            migrationBuilder.AddColumn<string>(
                name: "password_hash",
                table: "users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "username",
                table: "users",
                type: "citext",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "auth_tokens",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false, defaultValueSql: "nextval('auth_tokens_id_seq')"),
                    user_id = table.Column<int>(type: "integer", nullable: false),
                    jti = table.Column<Guid>(type: "uuid", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamptz", nullable: false, defaultValueSql: "now()"),
                    expires_at = table.Column<DateTime>(type: "timestamptz", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_auth_tokens", x => x.id);
                    table.CheckConstraint("ck_auth_tokens_id_range", "id BETWEEN 14000001 AND 14999999");
                    table.ForeignKey(
                        name: "FK_auth_tokens_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "ux_users_username",
                table: "users",
                column: "username",
                unique: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_email_format",
                table: "users",
                sql: "email LIKE '%@%' AND char_length(email) <= 255");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_username_format",
                table: "users",
                sql: "username IS NULL OR (char_length(username) BETWEEN 3 AND 30 AND username !~ '[@[:space:]]')");

            migrationBuilder.CreateIndex(
                name: "IX_auth_tokens_user_id",
                table: "auth_tokens",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "ux_auth_tokens_jti",
                table: "auth_tokens",
                column: "jti",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "auth_tokens");

            migrationBuilder.DropIndex(
                name: "ux_users_username",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_email_format",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_username_format",
                table: "users");

            migrationBuilder.DropColumn(
                name: "password_hash",
                table: "users");

            migrationBuilder.DropColumn(
                name: "username",
                table: "users");

            migrationBuilder.DropSequence(
                name: "auth_tokens_id_seq");

            migrationBuilder.AlterColumn<string>(
                name: "email",
                table: "users",
                type: "character varying(255)",
                maxLength: 255,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "citext");
        }
    }
}
