namespace FinancialApp.BLL.Models;

/// <summary>Either the created category, or the errors per field (field name → messages). Never both.</summary>
public record CreateCategoryResult(CategoryDto? Category, IReadOnlyDictionary<string, string[]> Errors)
{
    public bool Succeeded => Category is not null;

    public static CreateCategoryResult Created(CategoryDto category) => new(category, new Dictionary<string, string[]>());

    public static CreateCategoryResult Invalid(IReadOnlyDictionary<string, string[]> errors) => new(null, errors);
}
