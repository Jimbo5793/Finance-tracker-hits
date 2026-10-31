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
[Route("wallets")]
public class WalletsController(IWalletService service) : ControllerBase
{
    /// <summary>Wallets of the logged-in user, oldest first. Empty list if they have none.</summary>
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<WalletDto>>> Get(CancellationToken ct)
    {
        var userId = User.GetUserId();
        if (userId is null) return Unauthorized();

        return Ok(await service.GetForUserAsync(userId.Value, ct));
    }

    /// <summary>
    /// Creates a wallet for the logged-in user. 201 with the new wallet,
    /// or 400 with an "errors" object naming each wrong field. Nothing is saved on 400.
    /// </summary>
    [HttpPost]
    [ProducesResponseType<WalletDto>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<WalletDto>> Create(
        // All validation happens in WalletService, so every error names its field the same way.
        [FromBody, ValidateNever] CreateWalletRequest request,
        CancellationToken ct)
    {
        var userId = User.GetUserId();
        if (userId is null) return Unauthorized();

        var result = await service.CreateAsync(userId.Value, request, ct);
        if (!result.Succeeded)
        {
            var modelState = new ModelStateDictionary();
            foreach (var (field, messages) in result.Errors)
                foreach (var message in messages)
                    modelState.AddModelError(field, message);
            return ValidationProblem(modelState);
        }

        return StatusCode(StatusCodes.Status201Created, result.Wallet);
    }
}
