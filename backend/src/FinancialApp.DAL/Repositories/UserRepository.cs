using FinancialApp.DB;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinancialApp.DAL.Repositories;

public class UserRepository(AppDbContext db) : IUserRepository
{
    public async Task<User?> FindByLoginAsync(string login, CancellationToken ct = default) =>
        login.Contains('@')
            ? await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Email == login, ct)
            : await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == login, ct);
}