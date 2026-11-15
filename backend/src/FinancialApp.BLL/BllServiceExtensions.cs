using FinancialApp.BLL.Services;
using FinancialApp.DAL;
using FinancialApp.DB.Entities;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Identity;

namespace FinancialApp.BLL;

public static class BllServiceExtensions
{
    public static IServiceCollection AddBusiness(this IServiceCollection services)
    {
        services.AddDataAccess();
        services.AddScoped<ICurrencyService, CurrencyService>();
        services.AddScoped<IWalletService, WalletService>();
        services.AddScoped<IOperationService, OperationService>();
        services.AddScoped<ICategoryService, CategoryService>();
        services.AddScoped<IWalletBalanceCalculator, WalletBalanceCalculator>();
        services.AddSingleton<IPasswordHasher<User>, PasswordHasher<User>>();
        services.AddScoped<IAuthService, AuthService>();
        return services;
    }
}