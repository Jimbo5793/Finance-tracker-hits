using FinancialApp.API.Auth;
using FinancialApp.BLL.Models;
using FinancialApp.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

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
}
