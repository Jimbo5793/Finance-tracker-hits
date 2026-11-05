namespace FinancialApp.BLL.Models;

/// <summary>Either the created wallet, or the errors per field (field name → messages). Never both.</summary>
public record CreateWalletResult(WalletDto? Wallet, IReadOnlyDictionary<string, string[]> Errors)
{
    public bool Succeeded => Wallet is not null;

    public static CreateWalletResult Created(WalletDto wallet) => new(wallet, new Dictionary<string, string[]>());

    public static CreateWalletResult Invalid(IReadOnlyDictionary<string, string[]> errors) => new(null, errors);
}
