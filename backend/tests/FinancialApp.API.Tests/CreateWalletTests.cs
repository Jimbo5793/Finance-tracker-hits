using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinancialApp.API.Tests;

/// <summary>POST /wallets — one test per check in the task, plus the audit log.</summary>
[Collection(ApiCollection.Name)]
public class CreateWalletTests(ApiFactory api)
{
    [Fact]
    public async Task ValidPostWithName_CreatesWallet_AndReturnsIdAndName()
    {
        var userId = await api.CreateUserAsync();

        var response = await PostAsync(userId,
            """{ "name": "Euro card", "type": "bank card", "currency": "EUR", "startingBalance": 100 }""");

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var wallet = await response.Content.ReadFromJsonAsync<WalletResponse>();
        Assert.NotNull(wallet);
        Assert.True(wallet.Id > 0);
        Assert.Equal("Euro card", wallet.Name);
        Assert.Equal("bank card", wallet.Type);
        Assert.Equal("EUR", wallet.Currency);
        Assert.Equal(100m, wallet.Balance);

        // and GET /wallets shows it
        var list = await api.ClientFor(userId.ToString()).GetFromJsonAsync<List<WalletResponse>>("/wallets");
        Assert.Equal(wallet.Id, Assert.Single(list!).Id);
    }

    [Fact]
    public async Task StartingBalance_IsExactlyWhatWasSent()
    {
        var userId = await api.CreateUserAsync();

        var wallet = await CreateAsync(userId, """{ "type": "cash", "currency": "RUB", "startingBalance": 1234.56 }""");

        Assert.Equal(1234.56m, wallet.Balance);
    }

    [Fact]
    public async Task CashWithoutName_IsCalledCash1_ThenCash2()
    {
        var userId = await api.CreateUserAsync();
        const string body = """{ "type": "cash", "currency": "RUB", "startingBalance": 0 }""";

        var first = await CreateAsync(userId, body);
        var second = await CreateAsync(userId, body);

        Assert.Equal("Cash #1", first.Name);
        Assert.Equal("Cash #2", second.Name);
    }

    [Fact]
    public async Task EmptyName_GetsDefaultName_UsingSmallestFreeNumber()
    {
        var userId = await api.CreateUserAsync();
        await CreateAsync(userId, """{ "name": "Bank card #1", "type": "cash", "currency": "EUR", "startingBalance": 0 }""");
        await CreateAsync(userId, """{ "name": "Bank card #3", "type": "cash", "currency": "EUR", "startingBalance": 0 }""");

        var wallet = await CreateAsync(userId, """{ "name": "", "type": "bank card", "currency": "EUR", "startingBalance": 0 }""");

        Assert.Equal("Bank card #2", wallet.Name);
    }

    [Theory]
    [InlineData("name", """{ "name": "123456789012345678901234567890123456789012345678901", "type": "cash", "currency": "EUR", "startingBalance": 10 }""")]
    [InlineData("name", """{ "name": "     ", "type": "cash", "currency": "EUR", "startingBalance": 10 }""")]
    [InlineData("type", """{ "name": "Test", "type": "crypto", "currency": "EUR", "startingBalance": 10 }""")]
    [InlineData("type", """{ "name": "Test", "currency": "EUR", "startingBalance": 10 }""")]
    [InlineData("currency", """{ "name": "Test", "type": "cash", "currency": "XXX", "startingBalance": 10 }""")]
    [InlineData("currency", """{ "name": "Test", "type": "cash", "startingBalance": 10 }""")]
    [InlineData("startingBalance", """{ "name": "Test", "type": "cash", "currency": "EUR", "startingBalance": "abc" }""")]
    [InlineData("startingBalance", """{ "name": "Test", "type": "cash", "currency": "EUR", "startingBalance": -5 }""")]
    [InlineData("startingBalance", """{ "name": "Test", "type": "cash", "currency": "EUR", "startingBalance": 10.123 }""")]
    [InlineData("startingBalance", """{ "name": "Test", "type": "cash", "currency": "EUR" }""")]
    public async Task InvalidField_Returns400NamingTheField_AndSavesNothing(string field, string body)
    {
        var userId = await api.CreateUserAsync();

        var response = await PostAsync(userId, body);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal([field], await ErrorFieldsAsync(response));
        Assert.Equal(0, await WalletCountAsync(userId));
    }

    [Fact]
    public async Task NameAlreadyUsed_Returns400OnName_AndSavesNothing()
    {
        var userId = await api.CreateUserAsync();
        await CreateAsync(userId, """{ "name": "Groceries", "type": "cash", "currency": "EUR", "startingBalance": 10 }""");

        // Names are case-insensitive, like the database column
        var response = await PostAsync(userId,
            """{ "name": "groceries", "type": "cash", "currency": "EUR", "startingBalance": 10 }""");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(["name"], await ErrorFieldsAsync(response));
        Assert.Equal(1, await WalletCountAsync(userId));
    }

    [Fact]
    public async Task SameNameAsAnotherUsersWallet_IsAllowed()
    {
        var alice = await api.CreateUserAsync();
        var bob = await api.CreateUserAsync();
        const string body = """{ "name": "Groceries", "type": "cash", "currency": "EUR", "startingBalance": 10 }""";

        await CreateAsync(alice, body);
        var response = await PostAsync(bob, body);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task SeveralWrongFields_AreAllReported()
    {
        var userId = await api.CreateUserAsync();

        var response = await PostAsync(userId,
            """{ "name": "   ", "type": "crypto", "currency": "XXX", "startingBalance": -5 }""");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(["currency", "name", "startingBalance", "type"], await ErrorFieldsAsync(response));
    }

    [Fact]
    public async Task UserIdInBody_IsIgnored_WalletBelongsToLoggedInUser()
    {
        var me = await api.CreateUserAsync();
        var other = await api.CreateUserAsync();

        var wallet = await CreateAsync(me,
            $$"""{ "userId": {{other}}, "name": "Mine", "type": "cash", "currency": "EUR", "startingBalance": 10 }""");

        var owner = await api.QueryDbAsync(db => db.Wallets.Where(w => w.Id == wallet.Id).Select(w => w.UserId).SingleAsync());
        Assert.Equal(me, owner);
        Assert.Equal(0, await WalletCountAsync(other));
    }

    [Fact]
    public async Task WithoutToken_ReturnsUnauthorized()
    {
        var content = new StringContent(
            """{ "name": "Test", "type": "cash", "currency": "EUR", "startingBalance": 10 }""", Encoding.UTF8, "application/json");

        var response = await api.ClientFor(null).PostAsync("/wallets", content);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task CreatedWallet_IsWrittenToAuditLog()
    {
        var userId = await api.CreateUserAsync();
        var before = DateTime.UtcNow.AddMinutes(-1);

        var wallet = await CreateAsync(userId,
            """{ "name": "Audited", "type": "savings", "currency": "GBP", "startingBalance": 42.5 }""");

        var entry = await api.QueryDbAsync(db => db.AuditLog.SingleAsync(a => a.EntityType == "wallet" && a.EntityId == wallet.Id));
        Assert.Equal(userId, entry.UserId);
        Assert.Equal(AuditActions.WalletCreated, entry.Action);
        Assert.True(entry.CreatedAt > before);

        using var data = JsonDocument.Parse(entry.Data);
        Assert.Equal("Audited", data.RootElement.GetProperty("name").GetString());
        Assert.Equal("savings", data.RootElement.GetProperty("type").GetString());
        Assert.Equal("GBP", data.RootElement.GetProperty("currency").GetString());
        Assert.Equal(42.5m, data.RootElement.GetProperty("startingBalance").GetDecimal());
    }

    [Fact]
    public async Task FailedCreate_IsNotWrittenToAuditLog()
    {
        var userId = await api.CreateUserAsync();

        await PostAsync(userId, """{ "name": "Test", "type": "crypto", "currency": "EUR", "startingBalance": 10 }""");

        Assert.Equal(0, await api.QueryDbAsync(db => db.AuditLog.CountAsync(a => a.UserId == userId)));
    }

    private Task<HttpResponseMessage> PostAsync(int userId, string json) =>
        api.ClientFor(userId.ToString())
            .PostAsync("/wallets", new StringContent(json, Encoding.UTF8, "application/json"));

    private async Task<WalletResponse> CreateAsync(int userId, string json)
    {
        var response = await PostAsync(userId, json);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<WalletResponse>())!;
    }

    private static async Task<string[]> ErrorFieldsAsync(HttpResponseMessage response)
    {
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return doc.RootElement.GetProperty("errors").EnumerateObject().Select(p => p.Name).Order().ToArray();
    }

    private Task<int> WalletCountAsync(int userId) =>
        api.QueryDbAsync(db => db.Wallets.CountAsync(w => w.UserId == userId));

    private sealed record WalletResponse(int Id, string Name, string Type, string Currency, decimal Balance);
}
