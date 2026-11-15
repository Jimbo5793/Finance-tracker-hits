using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinancialApp.API.Tests;

/// <summary>
/// POST and GET /categories — one test per check in T3FIN-89 (kind), T3FIN-92 (validation),
/// T3FIN-94 (the list) and T3FIN-116 (mandatory flag), plus the audit log.
/// </summary>
[Collection(ApiCollection.Name)]
public class CategoriesTests(ApiFactory api)
{
    [Fact]
    public async Task ValidIncomeCategory_IsCreatedWithKindIncome()
    {
        var userId = await api.CreateUserAsync();

        var response = await PostAsync(userId, """{ "name": "Salary", "icon": "💰", "kind": "income" }""");

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var category = await response.Content.ReadFromJsonAsync<CategoryResponse>();
        Assert.NotNull(category);
        Assert.True(category.Id > 0);
        Assert.Equal("Salary", category.Name);
        Assert.Equal("💰", category.Icon);
        Assert.Equal("income", category.Kind);

        var saved = await api.QueryDbAsync(db => db.Categories.SingleAsync(c => c.Id == category.Id));
        Assert.Equal(userId, saved.UserId);
        Assert.Equal(CategoryKinds.Income, saved.Kind);
        Assert.Equal("💰", saved.Icon);
    }

    [Fact]
    public async Task ValidCategory_IsCreated_AndAnswerContainsId()
    {
        var userId = await api.CreateUserAsync();

        var response = await PostAsync(userId, """{ "name": "Food", "icon": "🍔", "kind": "expense" }""");

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var category = await response.Content.ReadFromJsonAsync<CategoryResponse>();
        Assert.NotNull(category);
        Assert.True(category.Id > 0);
        Assert.Equal("Food", category.Name);
        Assert.Equal("🍔", category.Icon);
        Assert.True(await api.QueryDbAsync(db => db.Categories.AnyAsync(c => c.Id == category.Id && c.UserId == userId)));
    }

    [Theory]
    [InlineData("🍔")]
    [InlineData("🇺🇦")]
    [InlineData("👍🏽")]
    [InlineData("👨‍👩‍👧")]
    [InlineData("❤️")]
    [InlineData("1️⃣")]
    public async Task AnySingleEmoji_IsAcceptedAsIcon(string icon)
    {
        var userId = await api.CreateUserAsync();

        var category = await CreateAsync(userId, $$"""{ "name": "Test", "icon": "{{icon}}", "kind": "expense" }""");

        Assert.Equal(icon, category.Icon);
    }

    [Fact]
    public async Task SameNameForOtherKind_IsAccepted_ButSecondOfSameKind_IsRefused()
    {
        var userId = await api.CreateUserAsync();
        await CreateAsync(userId, """{ "name": "Food", "icon": "🍔", "kind": "expense" }""");

        var income = await PostAsync(userId, """{ "name": "Food", "icon": "🍔", "kind": "income" }""");
        Assert.Equal(HttpStatusCode.Created, income.StatusCode);

        // Names are case-insensitive, like the database column
        var secondIncome = await PostAsync(userId, """{ "name": "food", "icon": "🍔", "kind": "income" }""");
        Assert.Equal(HttpStatusCode.BadRequest, secondIncome.StatusCode);
        Assert.Equal(["name"], await ErrorFieldsAsync(secondIncome));

        Assert.Equal(2, await CategoryCountAsync(userId));
    }

    [Fact]
    public async Task SameNameAndKindAsAnotherUsersCategory_IsAllowed()
    {
        var alice = await api.CreateUserAsync();
        var bob = await api.CreateUserAsync();
        const string body = """{ "name": "Salary", "icon": "💰", "kind": "income" }""";

        await CreateAsync(alice, body);
        var response = await PostAsync(bob, body);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Theory]
    [InlineData("kind", """{ "name": "Salary", "icon": "💰" }""")]
    [InlineData("kind", """{ "name": "Salary", "icon": "💰", "kind": "" }""")]
    [InlineData("kind", """{ "name": "Salary", "icon": "💰", "kind": "transfer" }""")]
    [InlineData("name", """{ "icon": "💰", "kind": "income" }""")]
    [InlineData("name", """{ "name": "", "icon": "💰", "kind": "income" }""")]
    [InlineData("name", """{ "name": "   ", "icon": "💰", "kind": "income" }""")]
    [InlineData("name", """{ "name": "1234567890123456789012345678901", "icon": "💰", "kind": "income" }""")]
    [InlineData("icon", """{ "name": "Salary", "kind": "income" }""")]
    [InlineData("icon", """{ "name": "Salary", "icon": "", "kind": "income" }""")]
    [InlineData("icon", """{ "name": "Salary", "icon": "ab", "kind": "income" }""")]
    [InlineData("icon", """{ "name": "Salary", "icon": "a", "kind": "income" }""")]
    [InlineData("icon", """{ "name": "Salary", "icon": "1", "kind": "income" }""")]
    [InlineData("icon", """{ "name": "Salary", "icon": "🍔🍔", "kind": "income" }""")]
    [InlineData("icon", """{ "name": "Salary", "icon": "🍔a", "kind": "income" }""")]
    [InlineData("icon", """{ "name": "Salary", "icon": "123456789012345678901234567890123456789012345678901", "kind": "income" }""")]
    [InlineData("mandatory", """{ "name": "Salary", "icon": "💰", "kind": "income", "mandatory": true }""")]
    [InlineData("mandatory", """{ "name": "Rent", "icon": "🏠", "kind": "expense", "mandatory": "yes" }""")]
    [InlineData("mandatory", """{ "name": "Rent", "icon": "🏠", "kind": "expense", "mandatory": 1 }""")]
    public async Task InvalidField_Returns400NamingTheField_AndSavesNothing(string field, string body)
    {
        var userId = await api.CreateUserAsync();

        var response = await PostAsync(userId, body);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal([field], await ErrorFieldsAsync(response));
        Assert.Equal(0, await CategoryCountAsync(userId));
        Assert.Equal(0, await api.QueryDbAsync(db => db.AuditLog.CountAsync(a => a.UserId == userId)));
    }

    [Fact]
    public async Task ExpenseCategory_WithMandatoryTrue_IsCreatedAsMandatory()
    {
        var userId = await api.CreateUserAsync();

        var category = await CreateAsync(userId, """{ "name": "Rent", "icon": "🏠", "kind": "expense", "mandatory": true }""");

        Assert.Equal("Rent", category.Name);
        Assert.True(category.Mandatory);
        Assert.True(await api.QueryDbAsync(db => db.Categories.Where(c => c.Id == category.Id).Select(c => c.IsMandatory).SingleAsync()));
    }

    [Theory]
    [InlineData("""{ "name": "Coffee", "icon": "☕", "kind": "expense" }""")]
    [InlineData("""{ "name": "Coffee", "icon": "☕", "kind": "expense", "mandatory": null }""")]
    [InlineData("""{ "name": "Coffee", "icon": "☕", "kind": "expense", "mandatory": false }""")]
    public async Task ExpenseCategory_WithoutMandatory_IsCreatedAsNonMandatory(string body)
    {
        var userId = await api.CreateUserAsync();

        var category = await CreateAsync(userId, body);

        Assert.False(category.Mandatory);
        Assert.False(await api.QueryDbAsync(db => db.Categories.Where(c => c.Id == category.Id).Select(c => c.IsMandatory).SingleAsync()));
    }

    [Theory]
    [InlineData("""{ "name": "Salary", "icon": "💰", "kind": "income" }""")]
    [InlineData("""{ "name": "Salary", "icon": "💰", "kind": "income", "mandatory": null }""")]
    [InlineData("""{ "name": "Salary", "icon": "💰", "kind": "income", "mandatory": false }""")]
    public async Task IncomeCategory_HasNoMandatoryFlag(string body)
    {
        var userId = await api.CreateUserAsync();

        var category = await CreateAsync(userId, body);

        Assert.Null(category.Mandatory);
        Assert.Null(await api.QueryDbAsync(db => db.Categories.Where(c => c.Id == category.Id).Select(c => c.IsMandatory).SingleAsync()));
    }

    [Fact]
    public async Task Get_ShowsFlagOnExpenseCategories_AndNoneOnIncome()
    {
        var userId = await api.CreateUserAsync();
        await CreateAsync(userId, """{ "name": "Rent", "icon": "🏠", "kind": "expense", "mandatory": true }""");
        await CreateAsync(userId, """{ "name": "Coffee", "icon": "☕", "kind": "expense" }""");
        await CreateAsync(userId, """{ "name": "Salary", "icon": "💰", "kind": "income" }""");

        var response = await api.ClientFor(userId.ToString()).GetAsync("/categories");
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var flags = doc.RootElement.EnumerateArray()
            .ToDictionary(c => c.GetProperty("name").GetString()!, c => c.GetProperty("mandatory").ValueKind);

        Assert.Equal(JsonValueKind.False, flags["Coffee"]);
        Assert.Equal(JsonValueKind.True, flags["Rent"]);
        Assert.Equal(JsonValueKind.Null, flags["Salary"]);
    }

    [Fact]
    public async Task KindIsCaseInsensitive_AndStoredLowerCase()
    {
        var userId = await api.CreateUserAsync();

        var category = await CreateAsync(userId, """{ "name": "Salary", "icon": "💰", "kind": "Income" }""");

        Assert.Equal("income", category.Kind);
    }

    [Fact]
    public async Task GetWithKind_ReturnsOnlyThatKind()
    {
        var userId = await api.CreateUserAsync();
        await CreateAsync(userId, """{ "name": "Salary", "icon": "💰", "kind": "income" }""");
        await CreateAsync(userId, """{ "name": "Gifts", "icon": "🎁", "kind": "income" }""");
        await CreateAsync(userId, """{ "name": "Food", "icon": "🍔", "kind": "expense" }""");
        await CreateAsync(userId, """{ "name": "Rent", "icon": "🏠", "kind": "expense" }""");
        await CreateAsync(userId, """{ "name": "Transport", "icon": "🚌", "kind": "expense" }""");

        var income = await GetAsync(userId, "?kind=income");
        Assert.Equal(["Gifts", "Salary"], income.Select(c => c.Name));
        Assert.All(income, c => Assert.Equal("income", c.Kind));

        var expense = await GetAsync(userId, "?kind=expense");
        Assert.Equal(["Food", "Rent", "Transport"], expense.Select(c => c.Name));
        Assert.All(expense, c => Assert.Equal("expense", c.Kind));

        Assert.Equal(5, (await GetAsync(userId, "")).Count);
    }

    [Fact]
    public async Task NewUser_GetsEmptyList()
    {
        var userId = await api.CreateUserAsync();

        var response = await api.ClientFor(userId.ToString()).GetAsync("/categories");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("[]", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Get_ReturnsAllCategories_SortedByName()
    {
        var userId = await api.CreateUserAsync();
        await CreateAsync(userId, """{ "name": "Rent", "icon": "🏠", "kind": "expense" }""");
        await CreateAsync(userId, """{ "name": "Bonus", "icon": "🎉", "kind": "income" }""");
        await CreateAsync(userId, """{ "name": "Food", "icon": "🍔", "kind": "expense" }""");

        var list = await GetAsync(userId, "");

        // by name only, not grouped by kind
        Assert.Equal(["Bonus", "Food", "Rent"], list.Select(c => c.Name));
        Assert.Equal(["🎉", "🍔", "🏠"], list.Select(c => c.Icon));
        Assert.Equal(["income", "expense", "expense"], list.Select(c => c.Kind));
        Assert.All(list, c => Assert.True(c.Id > 0));
    }

    [Fact]
    public async Task Get_SortsByNameIgnoringCase()
    {
        var userId = await api.CreateUserAsync();
        await CreateAsync(userId, """{ "name": "banana", "icon": "🍌", "kind": "expense" }""");
        await CreateAsync(userId, """{ "name": "Cherry", "icon": "🍒", "kind": "expense" }""");
        await CreateAsync(userId, """{ "name": "apple", "icon": "🍎", "kind": "expense" }""");

        var list = await GetAsync(userId, "");

        Assert.Equal(["apple", "banana", "Cherry"], list.Select(c => c.Name));
    }

    [Fact]
    public async Task Get_DoesNotReturnOtherUsersCategories_WithoutKind()
    {
        var first = await api.CreateUserAsync();
        var second = await api.CreateUserAsync();
        await CreateAsync(first, """{ "name": "Food", "icon": "🍔", "kind": "expense" }""");
        await CreateAsync(first, """{ "name": "Salary", "icon": "💰", "kind": "income" }""");
        await CreateAsync(second, """{ "name": "Rent", "icon": "🏠", "kind": "expense" }""");

        var list = await GetAsync(second, "");

        Assert.Equal(["Rent"], list.Select(c => c.Name));
    }

    [Fact]
    public async Task GetWithUnknownKind_Returns400NamingKind()
    {
        var userId = await api.CreateUserAsync();

        var response = await api.ClientFor(userId.ToString()).GetAsync("/categories?kind=transfer");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(["kind"], await ErrorFieldsAsync(response));
    }

    [Fact]
    public async Task Get_DoesNotReturnOtherUsersCategories()
    {
        var me = await api.CreateUserAsync();
        var other = await api.CreateUserAsync();
        await CreateAsync(other, """{ "name": "Salary", "icon": "💰", "kind": "income" }""");

        Assert.Empty(await GetAsync(me, "?kind=income"));
    }

    [Theory]
    [InlineData("GET")]
    [InlineData("POST")]
    public async Task WithoutToken_ReturnsUnauthorized(string method)
    {
        var request = new HttpRequestMessage(new HttpMethod(method), "/categories");
        if (method == "POST")
            request.Content = new StringContent(
                """{ "name": "Salary", "icon": "💰", "kind": "income" }""", Encoding.UTF8, "application/json");

        var response = await api.ClientFor(null).SendAsync(request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task CreatedCategory_IsWrittenToAuditLog()
    {
        var userId = await api.CreateUserAsync();

        var category = await CreateAsync(userId, """{ "name": "Salary", "icon": "💰", "kind": "income" }""");

        var entry = await api.QueryDbAsync(db =>
            db.AuditLog.SingleAsync(a => a.EntityType == "category" && a.EntityId == category.Id));
        Assert.Equal(userId, entry.UserId);
        Assert.Equal(AuditActions.CategoryCreated, entry.Action);

        using var data = JsonDocument.Parse(entry.Data);
        Assert.Equal("Salary", data.RootElement.GetProperty("name").GetString());
        Assert.Equal("💰", data.RootElement.GetProperty("icon").GetString());
        Assert.Equal("income", data.RootElement.GetProperty("kind").GetString());
        Assert.Equal(JsonValueKind.Null, data.RootElement.GetProperty("mandatory").ValueKind);
    }

    [Fact]
    public async Task MandatoryFlag_IsWrittenToAuditLog()
    {
        var userId = await api.CreateUserAsync();

        var category = await CreateAsync(userId, """{ "name": "Rent", "icon": "🏠", "kind": "expense", "mandatory": true }""");

        var entry = await api.QueryDbAsync(db =>
            db.AuditLog.SingleAsync(a => a.EntityType == "category" && a.EntityId == category.Id));
        using var data = JsonDocument.Parse(entry.Data);
        Assert.True(data.RootElement.GetProperty("mandatory").GetBoolean());
    }

    private Task<HttpResponseMessage> PostAsync(int userId, string json) =>
        api.ClientFor(userId.ToString())
            .PostAsync("/categories", new StringContent(json, Encoding.UTF8, "application/json"));

    private async Task<CategoryResponse> CreateAsync(int userId, string json)
    {
        var response = await PostAsync(userId, json);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<CategoryResponse>())!;
    }

    private async Task<List<CategoryResponse>> GetAsync(int userId, string query)
    {
        var response = await api.ClientFor(userId.ToString()).GetAsync($"/categories{query}");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<List<CategoryResponse>>())!;
    }

    private static async Task<string[]> ErrorFieldsAsync(HttpResponseMessage response)
    {
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return doc.RootElement.GetProperty("errors").EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal).ToArray();
    }

    private Task<int> CategoryCountAsync(int userId) =>
        api.QueryDbAsync(db => db.Categories.CountAsync(c => c.UserId == userId));

    private sealed record CategoryResponse(int Id, string Name, string Icon, string Kind, bool? Mandatory);
}
