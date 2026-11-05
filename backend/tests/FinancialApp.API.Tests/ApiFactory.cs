using FinancialApp.DB;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Testcontainers.PostgreSql;

namespace FinancialApp.API.Tests;

/// <summary>
/// Starts the real API against a throwaway Postgres in Docker, with all migrations applied.
/// Needs Docker running (Docker Desktop / OrbStack locally; GitHub's ubuntu runners have it).
/// Login is replaced by <see cref="TestAuthHandler"/>: send the user id in the X-Test-User header.
/// </summary>
public class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly PostgreSqlContainer _db = new PostgreSqlBuilder()
        .WithImage("postgres:16-alpine")
        .Build();

    public async Task InitializeAsync()
    {
        await _db.StartAsync();

        using var scope = Services.CreateScope();
        await scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.MigrateAsync();
    }

    public new async Task DisposeAsync()
    {
        await base.DisposeAsync();
        await _db.DisposeAsync();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:Default", _db.GetConnectionString());

        builder.ConfigureTestServices(services =>
            services.AddAuthentication(TestAuthHandler.Scheme)
                .AddScheme<AuthenticationSchemeOptions, TestAuthHandler>(TestAuthHandler.Scheme, _ => { }));
    }

    public HttpClient ClientFor(string? userId)
    {
        var client = CreateClient();
        if (userId is not null)
            client.DefaultRequestHeaders.Add(TestAuthHandler.UserHeader, userId);
        return client;
    }
}
