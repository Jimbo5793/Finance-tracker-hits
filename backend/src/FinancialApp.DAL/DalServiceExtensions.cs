using FinancialApp.DAL.Repositories;
using Microsoft.Extensions.DependencyInjection;

namespace FinancialApp.DAL;

public static class DalServiceExtensions
{
    public static IServiceCollection AddDataAccess(this IServiceCollection services)
    {
        services.AddScoped<ICurrencyRepository, CurrencyRepository>();
        services.AddScoped<IWalletRepository, WalletRepository>();
        return services;
    }
}