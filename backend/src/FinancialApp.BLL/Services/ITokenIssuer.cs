namespace FinancialApp.BLL.Services;

public record IssuedToken(string Token, Guid Jti, DateTime ExpiresAt);

public interface ITokenIssuer
{
    IssuedToken Issue(int userId);
}