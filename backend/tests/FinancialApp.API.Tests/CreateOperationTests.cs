using System.Globalization;
using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinancialApp.API.Tests;

/// <summary>POST /operations for an expense — one test per check in the task, plus the audit log.</summary>
[Collection(ApiCollection.Name)]
public class CreateOperationTests(ApiFactory api)
{
    private static DateOnly Today => DateOnly.FromDateTime(DateTime.UtcNow);
    private static DateOnly FirstOfMonth => new(Today.Year, Today.Month, 1);

    [Fact]
    public async Task ValidExpense_IsSaved_AndReturnsIdAndValues()
    {
        var userId = await api.CreateUserAsync();
        var walletId = await CreateWalletAsync(userId, startingBalance: 100);
        var date = Iso(FirstOfMonth);

        var response = await PostAsync(userId,
            $$"""{ "walletId": {{walletId}}, "type": "expense", "amount": 30, "date": "{{date}}" }""");

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var operation = await response.Content.ReadFromJsonAsync<OperationResponse>();
        Assert.NotNull(operation);
        Assert.True(operation.Id > 0);
        Assert.Equal(walletId, operation.WalletId);
        Assert.Equal("expense", operation.Type);
        Assert.Equal(30m, operation.Amount);
        Assert.Equal(date, operation.Date);

        var saved = await api.QueryDbAsync(db => db.Operations.SingleAsync(o => o.Id == operation.Id));
        Assert.Equal(walletId, saved.WalletId);
        Assert.Equal(OperationTypes.Expense, saved.Type);
        Assert.Equal(30m, saved.Amount);
        Assert.Equal(FirstOfMonth, DateOnly.FromDateTime(saved.OccurredAt));

        // and the wallet balance goes down by the expense
        var wallets = await api.ClientFor(userId.ToString()).GetFromJsonAsync<List<WalletResponse>>("/wallets");
        Assert.Equal(70m, Assert.Single(wallets!).Balance);
    }

    [Fact]
    public async Task WithoutDate_SavesToday()
    {
        var userId = await api.CreateUserAsync();
        var walletId = await CreateWalletAsync(userId);

        var operation = await CreateAsync(userId, $$"""{ "walletId": {{walletId}}, "amount": 12.5 }""");

        Assert.Equal(Iso(Today), operation.Date);
        var saved = await api.QueryDbAsync(db => db.Operations.SingleAsync(o => o.Id == operation.Id));
        Assert.Equal(Today, DateOnly.FromDateTime(saved.OccurredAt));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("expense")]
    [InlineData("Expense")]
    public async Task TypeMissingOrExpense_IsSavedAsExpense(string? type)
    {
        var userId = await api.CreateUserAsync();
        var walletId = await CreateWalletAsync(userId);
        var typeJson = type is null ? "" : $"\"type\": \"{type}\", ";

        var operation = await CreateAsync(userId, $$"""{ {{typeJson}}"walletId": {{walletId}}, "amount": 5 }""");

        Assert.Equal("expense", operation.Type);
    }

    public static TheoryData<string, string> InvalidBodies()
    {
        var lastMonth = Iso(FirstOfMonth.AddMonths(-1));
        var nextMonth = Iso(FirstOfMonth.AddMonths(1));
        // {wallet} is replaced by the id of a wallet of the user
        return new TheoryData<string, string>
        {
            { "amount", """{ "walletId": {wallet}, "amount": 0 }""" },
            { "amount", """{ "walletId": {wallet}, "amount": "abc" }""" },
            { "amount", """{ "walletId": {wallet}, "amount": 10.123 }""" },
            { "amount", """{ "walletId": {wallet}, "amount": -5 }""" },
            { "amount", """{ "walletId": {wallet} }""" },
            { "type", """{ "walletId": {wallet}, "type": "income", "amount": 10 }""" },
            { "type", """{ "walletId": {wallet}, "type": "transfer", "amount": 10 }""" },
            { "date", $$"""{ "walletId": {wallet}, "amount": 10, "date": "{{lastMonth}}" }""" },
            { "date", $$"""{ "walletId": {wallet}, "amount": 10, "date": "{{nextMonth}}" }""" },
            { "date", """{ "walletId": {wallet}, "amount": 10, "date": "tomorrow" }""" },
            { "walletId", """{ "amount": 10 }""" },
            { "walletId", """{ "walletId": "abc", "amount": 10 }""" },
        };
    }

    [Theory]
    [MemberData(nameof(InvalidBodies))]
    public async Task InvalidField_Returns400NamingTheField_AndSavesNothing(string field, string body)
    {
        var userId = await api.CreateUserAsync();
        var walletId = await CreateWalletAsync(userId);

        var response = await PostAsync(userId, body.Replace("{wallet}", walletId.ToString()));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal([field], await ErrorFieldsAsync(response));
        Assert.Equal(0, await OperationCountAsync(walletId));
        Assert.Equal(0, await OperationAuditCountAsync(userId));
    }

    [Fact]
    public async Task SeveralWrongFields_AreAllReported()
    {
        var userId = await api.CreateUserAsync();

        var response = await PostAsync(userId, """{ "walletId": "x", "type": "income", "amount": 0, "date": "2000-01-01" }""");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(["amount", "date", "type", "walletId"], await ErrorFieldsAsync(response));
    }

    [Fact]
    public async Task WalletOfAnotherUser_Returns404_AndSavesNothing()
    {
        var me = await api.CreateUserAsync();
        var other = await api.CreateUserAsync();
        var othersWallet = await CreateWalletAsync(other);

        var response = await PostAsync(me, $$"""{ "walletId": {{othersWallet}}, "amount": 30 }""");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal(0, await OperationCountAsync(othersWallet));
        Assert.Equal(0, await OperationAuditCountAsync(me));
    }

    [Fact]
    public async Task WalletThatDoesNotExist_Returns404()
    {
        var userId = await api.CreateUserAsync();

        var response = await PostAsync(userId, """{ "walletId": 11999999, "amount": 30 }""");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task WithoutToken_ReturnsUnauthorized()
    {
        var userId = await api.CreateUserAsync();
        var walletId = await CreateWalletAsync(userId);
        var content = new StringContent($$"""{ "walletId": {{walletId}}, "amount": 30 }""", Encoding.UTF8, "application/json");

        var response = await api.ClientFor(null).PostAsync("/operations", content);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        Assert.Equal(0, await OperationCountAsync(walletId));
    }

    [Fact]
    public async Task EachSavedExpense_IsWrittenToAuditLog()
    {
        var userId = await api.CreateUserAsync();
        var walletId = await CreateWalletAsync(userId);
        var before = DateTime.UtcNow.AddMinutes(-1);

        var first = await CreateAsync(userId, $$"""{ "walletId": {{walletId}}, "amount": 30 }""");
        var second = await CreateAsync(userId, $$"""{ "walletId": {{walletId}}, "amount": 4.99 }""");

        foreach (var operation in new[] { first, second })
        {
            var entry = await api.QueryDbAsync(db =>
                db.AuditLog.SingleAsync(a => a.EntityType == "operation" && a.EntityId == operation.Id));
            Assert.Equal(userId, entry.UserId);
            Assert.Equal(AuditActions.OperationCreated, entry.Action);
            Assert.True(entry.CreatedAt > before);

            using var data = JsonDocument.Parse(entry.Data);
            Assert.Equal(walletId, data.RootElement.GetProperty("walletId").GetInt32());
            Assert.Equal("expense", data.RootElement.GetProperty("type").GetString());
            Assert.Equal(operation.Amount, data.RootElement.GetProperty("amount").GetDecimal());
            Assert.Equal(operation.Date, data.RootElement.GetProperty("date").GetString());
        }
        Assert.Equal(2, await OperationAuditCountAsync(userId));
    }

    private async Task<int> CreateWalletAsync(int userId, decimal startingBalance = 0)
    {
        var response = await api.ClientFor(userId.ToString()).PostAsync("/wallets", new StringContent(
            $$"""{ "type": "cash", "currency": "EUR", "startingBalance": {{startingBalance.ToString(CultureInfo.InvariantCulture)}} }""",
            Encoding.UTF8, "application/json"));
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<WalletResponse>())!.Id;
    }

    private Task<HttpResponseMessage> PostAsync(int userId, string json) =>
        api.ClientFor(userId.ToString())
            .PostAsync("/operations", new StringContent(json, Encoding.UTF8, "application/json"));

    private async Task<OperationResponse> CreateAsync(int userId, string json)
    {
        var response = await PostAsync(userId, json);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<OperationResponse>())!;
    }

    private static async Task<string[]> ErrorFieldsAsync(HttpResponseMessage response)
    {
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return doc.RootElement.GetProperty("errors").EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal).ToArray();
    }

    private Task<int> OperationCountAsync(int walletId) =>
        api.QueryDbAsync(db => db.Operations.CountAsync(o => o.WalletId == walletId));

    private Task<int> OperationAuditCountAsync(int userId) =>
        api.QueryDbAsync(db => db.AuditLog.CountAsync(a => a.UserId == userId && a.EntityType == "operation"));

    private static string Iso(DateOnly date) => date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);

    private sealed record OperationResponse(int Id, int WalletId, string Type, decimal Amount, string Date);

    private sealed record WalletResponse(int Id, string Name, string Type, string Currency, decimal Balance);
}
