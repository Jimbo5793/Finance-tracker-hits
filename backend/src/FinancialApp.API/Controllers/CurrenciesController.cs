using FinancialApp.BLL.Models;
using FinancialApp.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FinancialApp.API.Controllers;

[ApiController]
[Authorize]
[Route("currencies")]
public class CurrenciesController(ICurrencyService service) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<CurrencyDto>>> Get(CancellationToken ct) =>
        Ok(await service.GetAllAsync(ct));
}