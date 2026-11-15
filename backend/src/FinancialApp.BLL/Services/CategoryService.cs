using FinancialApp.BLL.Models;
using FinancialApp.DAL.Repositories;
using FinancialApp.DB.Entities;

namespace FinancialApp.BLL.Services;

public class CategoryService(ICategoryRepository categories) : ICategoryService
{
    public const int MaxNameLength = 30;
    public const int MaxIconLength = 50;

    public async Task<GetCategoriesResult> GetForUserAsync(int userId, string? kind, CancellationToken ct = default)
    {
        string? filter = null;
        if (!string.IsNullOrWhiteSpace(kind))
        {
            filter = FindKind(kind);
            if (filter is null)
                return GetCategoriesResult.Invalid(new Dictionary<string, string[]>
                {
                    ["kind"] = [NotAllowedKindMessage(kind)],
                });
        }

        var list = await categories.GetByUserAsync(userId, filter, ct);
        return GetCategoriesResult.Found(list.Select(ToDto).ToList());
    }

    public async Task<CreateCategoryResult> CreateAsync(int userId, CreateCategoryRequest request, CancellationToken ct = default)
    {
        var errors = new Dictionary<string, List<string>>();
        void Fail(string field, string message)
        {
            if (!errors.TryGetValue(field, out var list)) errors[field] = list = [];
            list.Add(message);
        }

        var kind = ValidateKind(request.Kind, Fail);
        var icon = ValidateIcon(request.Icon, Fail);
        var name = ValidateName(request.Name, Fail);

        // Only check for a duplicate once name and kind are both valid; the same name is fine for another kind.
        if (name is not null && kind is not null && await categories.NameExistsAsync(userId, kind, name, ct))
            Fail("name", NameTakenMessage(name, kind));

        if (errors.Count > 0)
            return Invalid(errors);

        var category = new Category
        {
            UserId = userId, // always the logged-in user, never anything from the request
            Name = name!,
            Icon = icon!,
            Kind = kind!,
        };

        try
        {
            await categories.CreateWithAuditAsync(category, ct);
        }
        catch (CategoryNameTakenException)
        {
            // Someone created the same category between our check and the insert.
            Fail("name", NameTakenMessage(category.Name, category.Kind));
            return Invalid(errors);
        }

        return CreateCategoryResult.Created(ToDto(category));
    }

    private static string? ValidateKind(string? value, Action<string, string> fail)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            fail("kind", $"Kind is required. Allowed kinds: {string.Join(", ", CategoryKinds.All)}.");
            return null;
        }

        var kind = FindKind(value);
        if (kind is null)
            fail("kind", NotAllowedKindMessage(value));
        return kind;
    }

    private static string? ValidateIcon(string? value, Action<string, string> fail)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            fail("icon", "Icon is required.");
            return null;
        }

        var icon = value.Trim();
        if (icon.Length > MaxIconLength)
            fail("icon", $"Icon can be at most {MaxIconLength} characters.");
        return icon;
    }

    private static string? ValidateName(string? value, Action<string, string> fail)
    {
        if (string.IsNullOrEmpty(value))
        {
            fail("name", "Name is required.");
            return null;
        }

        var name = value.Trim();
        if (name.Length == 0)
        {
            fail("name", "Name cannot be only spaces.");
            return null;
        }
        if (name.Length > MaxNameLength)
        {
            fail("name", $"Name can be at most {MaxNameLength} characters.");
            return null;
        }
        return name;
    }

    /// <summary>Accept any capitalisation, return the canonical spelling, or null if not a kind.</summary>
    private static string? FindKind(string value) =>
        CategoryKinds.All.FirstOrDefault(k => string.Equals(k, value.Trim(), StringComparison.OrdinalIgnoreCase));

    private static string NotAllowedKindMessage(string value) =>
        $"\"{value}\" is not an allowed kind. Allowed kinds: {string.Join(", ", CategoryKinds.All)}.";

    private static string NameTakenMessage(string name, string kind) =>
        $"You already have an {kind} category called \"{name}\".";

    private static CategoryDto ToDto(Category c) => new(c.Id, c.Name, c.Icon, c.Kind);

    private static CreateCategoryResult Invalid(Dictionary<string, List<string>> errors) =>
        CreateCategoryResult.Invalid(errors.ToDictionary(e => e.Key, e => e.Value.ToArray()));
}
