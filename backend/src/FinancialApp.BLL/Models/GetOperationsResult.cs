namespace FinancialApp.BLL.Models;

public enum GetOperationsOutcome { Ok, Invalid, WalletNotFound }

public record GetOperationsResult(
    GetOperationsOutcome Outcome,
    IReadOnlyList<OperationDto>? Operations = null,
    IReadOnlyDictionary<string, string[]>? Errors = null)
{
    public static GetOperationsResult Found(IReadOnlyList<OperationDto> operations) =>
        new(GetOperationsOutcome.Ok, operations);

    public static GetOperationsResult Invalid(IReadOnlyDictionary<string, string[]> errors) =>
        new(GetOperationsOutcome.Invalid, null, errors);

    public static GetOperationsResult WalletNotFound() => new(GetOperationsOutcome.WalletNotFound);
}