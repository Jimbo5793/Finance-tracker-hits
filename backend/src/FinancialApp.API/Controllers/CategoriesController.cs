using FinancialApp.API.Auth;
using FinancialApp.BLL.Models;
using FinancialApp.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.ModelBinding.Validation;

namespace FinancialApp.API.Controllers;

[ApiController]
[Authorize]
[Route("categories")]
public class CategoriesController(ICategoryService service) : ControllerBase
{
    /// <summary>
    /// Categories of the logged-in user, sorted by name. Empty list if they have none.
    /// ?kind=income or ?kind=expense returns only that kind; no kind returns all.
    /// Any other kind is a 400 naming the kind field.
    /// </summary>
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<CategoryDto>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<IReadOnlyList<CategoryDto>>> Get([FromQuery] string? kind, CancellationToken ct)
    {
        var userId = User.GetUserId();
        if (userId is null) return Unauthorized();

        var result = await service.GetForUserAsync(userId.Value, kind, ct);
        if (!result.Succeeded)
            return ValidationProblem(ToModelState(result.Errors));

        return Ok(result.Categories);
    }

    /// <summary>
    /// Creates a category for the logged-in user. 201 with the new category,
    /// or 400 with an "errors" object naming each wrong field. Nothing is saved on 400.
    /// </summary>
    [HttpPost]
    [ProducesResponseType<CategoryDto>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CategoryDto>> Create(
        // All validation happens in CategoryService, so every error names its field the same way.
        [FromBody, ValidateNever] CreateCategoryRequest request,
        CancellationToken ct)
    {
        var userId = User.GetUserId();
        if (userId is null) return Unauthorized();

        var result = await service.CreateAsync(userId.Value, request, ct);
        if (!result.Succeeded)
            return ValidationProblem(ToModelState(result.Errors));

        return StatusCode(StatusCodes.Status201Created, result.Category);
    }

    private static ModelStateDictionary ToModelState(IReadOnlyDictionary<string, string[]> errors)
    {
        var modelState = new ModelStateDictionary();
        foreach (var (field, messages) in errors)
            foreach (var message in messages)
                modelState.AddModelError(field, message);
        return modelState;
    }
}
