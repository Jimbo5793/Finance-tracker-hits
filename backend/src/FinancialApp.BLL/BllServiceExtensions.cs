using FinancialApp.BLL.Services;
using FinancialApp.DAL;
using Microsoft.Extensions.DependencyInjection;

namespace FinancialApp.BLL;

public static class BllServiceExtensions
{
    public static IServiceCollection AddBusiness(this IServiceCollection services)
    {
        services.AddDataAccess();
        services.AddScoped<ICurrencyService, CurrencyService>();
        services.AddScoped<IWalletService, WalletService>();
        services.AddSingleton<IWalletBalanceCalculator, WalletBalanceCalculator>();
        return services;
    }
}