using FinancialApp.BLL.Models;
using FinancialApp.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.ModelBinding.Validation;

namespace FinancialApp.API.Controllers;

[ApiController]
[Route("auth")]
public class AuthController(IAuthService auth) : ControllerBase
{
    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType<LoginResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<LoginResponse>> Login(
        [FromBody, ValidateNever] LoginRequest request, CancellationToken ct)
    {
        var result = await auth.LoginAsync(request, ct);

        switch (result.Outcome)
        {
            case LoginOutcome.Success:
                return Ok(result.Response);

            case LoginOutcome.Invalid:
            {
                var modelState = new ModelStateDictionary();
                foreach (var (field, messages) in result.Errors!)
                foreach (var message in messages)
                    modelState.AddModelError(field, message);
                return ValidationProblem(modelState);
            }

            default:
                return StatusCode(StatusCodes.Status401Unauthorized, new { title = "Invalid username or password." });
        }
    }
}