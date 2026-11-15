namespace FinancialApp.BLL.Models;

/// <summary>Either the categories, or the errors per field (field name → messages). Never both.</summary>
public record GetCategoriesResult(IReadOnlyList<CategoryDto>? Categories, IReadOnlyDictionary<string, string[]> Errors)
{
    public bool Succeeded => Categories is not null;

    public static GetCategoriesResult Found(IReadOnlyList<CategoryDto> categories) => new(categories, new Dictionary<string, string[]>());

    public static GetCategoriesResult Invalid(IReadOnlyDictionary<string, string[]> errors) => new(null, errors);
}
