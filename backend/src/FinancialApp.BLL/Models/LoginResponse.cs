namespace FinancialApp.BLL.Models;

public record LoginResponse(string Token, DateTime ExpiresAt);