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
[Route("operations")]
public class OperationsController(IOperationService service) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<OperationDto>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IReadOnlyList<OperationDto>>> Get(
        [FromQuery] string? walletId,
        [FromQuery] string? type,
        [FromQuery] string? limit,
        [FromQuery] string? offset,
        CancellationToken ct)
    {
        var userId = User.GetUserId();
        if (userId is null) return Unauthorized();

        var result = await service.GetAsync(userId.Value, walletId, type, limit, offset, ct);

        switch (result.Outcome)
        {
            case GetOperationsOutcome.Ok:
                return Ok(result.Operations);

            case GetOperationsOutcome.Invalid:
            {
                var modelState = new ModelStateDictionary();
                foreach (var (field, messages) in result.Errors!)
                foreach (var message in messages)
                    modelState.AddModelError(field, message);
                return ValidationProblem(modelState);
            }

            default:
                return NotFound(new { title = "Wallet not found." });
        }
    }
    
    /// Records an income or an expense in one of the logged-in user's wallets. 201 with the new operation,
    /// 400 with an "errors" object naming each wrong field, or 404 if the wallet is not the user's.
    /// Nothing is saved on 400 or 404.
    /// </summary>
    [HttpPost]
    [ProducesResponseType<OperationDto>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<OperationDto>> Create(
        // All validation happens in OperationService, so every error names its field the same way.
        [FromBody, ValidateNever] CreateOperationRequest request,
        CancellationToken ct)
    {
        var userId = User.GetUserId();
        if (userId is null) return Unauthorized();

        var result = await service.CreateAsync(userId.Value, request, ct);

        switch (result.Outcome)
        {
            case CreateOperationOutcome.Created:
                return StatusCode(StatusCodes.Status201Created, result.Operation);

            case CreateOperationOutcome.Invalid:
            {
                var modelState = new ModelStateDictionary();
                foreach (var (field, messages) in result.Errors!)
                    foreach (var message in messages)
                        modelState.AddModelError(field, message);
                return ValidationProblem(modelState);
            }

            default:
                return NotFound(new { title = "Wallet not found." });
        }
    }
}
