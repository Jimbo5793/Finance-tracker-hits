using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FinancialApp.DB;
using FinancialApp.DB.Entities;
using Microsoft.Extensions.DependencyInjection;

namespace FinancialApp.API.Tests;

/// <summary>GET /wallets — one test per check in the task, plus sorting.</summary>
[Collection(ApiCollection.Name)]
public class WalletsEndpointTests(ApiFactory api)
{
    [Fact]
    public async Task NewUser_GetsEmptyList()
    {
        var userId = await CreateUserAsync();

        var response = await api.ClientFor(userId.ToString()).GetAsync("/wallets");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var wallets = await response.Content.ReadFromJsonAsync<List<WalletResponse>>();
        Assert.NotNull(wallets);
        Assert.Empty(wallets);
    }

    [Fact]
    public async Task ReturnsEachWallet_WithItsOwnCurrencyAndBalance()
    {
        var userId = await CreateUserAsync();
        await CreateWalletAsync(userId, "Euro card", "EUR", 100m, WalletTypes.BankCard);
        await CreateWalletAsync(userId, "Rubles", "RUB", 5000m, WalletTypes.Cash);

        var wallets = await api.ClientFor(userId.ToString()).GetFromJsonAsync<List<WalletResponse>>("/wallets");

        Assert.NotNull(wallets);
        Assert.Equal(2, wallets.Count);

        var eur = Assert.Single(wallets, w => w.Currency == "EUR");
        Assert.Equal("Euro card", eur.Name);
        Assert.Equal(WalletTypes.BankCard, eur.Type);
        Assert.Equal(100m, eur.Balance);

        var rub = Assert.Single(wallets, w => w.Currency == "RUB");
        Assert.Equal("Rubles", rub.Name);
        Assert.Equal(WalletTypes.Cash, rub.Type);
        Assert.Equal(5000m, rub.Balance);
    }

    [Fact]
    public async Task Response_IsAPlainList_WithNoTotalOrConvertedAmounts()
    {
        var userId = await CreateUserAsync();
        await CreateWalletAsync(userId, "Euro card", "EUR", 100m);
        await CreateWalletAsync(userId, "Rubles", "RUB", 5000m);

        var json = await api.ClientFor(userId.ToString()).GetStringAsync("/wallets");
        using var doc = JsonDocument.Parse(json);

        Assert.Equal(JsonValueKind.Array, doc.RootElement.ValueKind);
        string[] expected = ["balance", "currency", "id", "name", "type"];
        foreach (var item in doc.RootElement.EnumerateArray())
        {
            var fields = item.EnumerateObject().Select(p => p.Name).Order().ToArray();
            Assert.Equal(expected, fields);
        }
    }

    [Fact]
    public async Task DoesNotReturnOtherUsersWallets()
    {
        var alice = await CreateUserAsync();
        var bob = await CreateUserAsync();
        await CreateWalletAsync(alice, "Alice's wallet", "EUR", 100m);
        var bobsWallet = await CreateWalletAsync(bob, "Bob's wallet", "RUB", 5000m);

        var wallets = await api.ClientFor(bob.ToString()).GetFromJsonAsync<List<WalletResponse>>("/wallets");

        Assert.NotNull(wallets);
        var only = Assert.Single(wallets);
        Assert.Equal(bobsWallet, only.Id);
    }

    [Fact]
    public async Task IsSortedByCreationTime_OldestFirst()
    {
        var userId = await CreateUserAsync();
        var now = DateTime.UtcNow;
        // Inserted out of order on purpose
        var middle = await CreateWalletAsync(userId, "Middle", "EUR", 1m, createdAt: now.AddHours(-2));
        var newest = await CreateWalletAsync(userId, "Newest", "EUR", 1m, createdAt: now.AddHours(-1));
        var oldest = await CreateWalletAsync(userId, "Oldest", "EUR", 1m, createdAt: now.AddHours(-3));

        var wallets = await api.ClientFor(userId.ToString()).GetFromJsonAsync<List<WalletResponse>>("/wallets");

        Assert.NotNull(wallets);
        Assert.Equal([oldest, middle, newest], wallets.Select(w => w.Id).ToArray());
    }

    [Fact]
    public async Task WithoutToken_ReturnsUnauthorized()
    {
        var response = await api.ClientFor(null).GetAsync("/wallets");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task TokenWithoutValidUserId_ReturnsUnauthorized()
    {
        var response = await api.ClientFor("not-a-user-id").GetAsync("/wallets");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private async Task<int> CreateUserAsync()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var user = new User { Email = $"{Guid.NewGuid():N}@test.local" };
        db.Users.Add(user);
        await db.SaveChangesAsync();
        return user.Id;
    }

    private async Task<int> CreateWalletAsync(
        int userId, string name, string currency, decimal startingBalance,
        string type = WalletTypes.Cash, DateTime? createdAt = null)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var wallet = new Wallet
        {
            UserId = userId,
            Name = name,
            Type = type,
            CurrencyCode = currency,
            StartingBalance = startingBalance,
            CreatedAt = createdAt ?? default, // default = let the database set now()
        };
        db.Wallets.Add(wallet);
        await db.SaveChangesAsync();
        return wallet.Id;
    }

    private sealed record WalletResponse(int Id, string Name, string Type, string Currency, decimal Balance);
}
