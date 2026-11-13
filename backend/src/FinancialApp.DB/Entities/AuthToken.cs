namespace FinancialApp.DB.Entities;

public class AuthToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public Guid Jti { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }

    public User? User { get; set; }
}