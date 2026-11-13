using FinancialApp.DB;
using FinancialApp.DB.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace FinancialApp.API.Auth;

public static class UserSeeder
{
    private static readonly (string Username, string Email)[] Users =
    [
        ("dev", "dev@local.test"),
        ("demo", "demo@local.test"),
    ];

    public static async Task SeedAsync(AppDbContext db, IPasswordHasher<User> hasher, string password)
    {
        foreach (var (username, email) in Users)
        {
            var user = await db.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (user is null)
            {
                user = new User { Email = email };
                db.Users.Add(user);
            }

            if (user.PasswordHash is null)
            {
                user.Username = username;
                user.PasswordHash = hasher.HashPassword(user, password);
            }

            await db.SaveChangesAsync();
        }
    }
}