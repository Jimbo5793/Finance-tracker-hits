namespace FinancialApp.BLL.Models;

public enum CreateOperationOutcome { Created, Invalid, WalletNotFound }

/// <summary>The created operation, the errors per field (field name → messages), or "wallet not found".</summary>
public record CreateOperationResult(
    CreateOperationOutcome Outcome,
    OperationDto? Operation = null,
    IReadOnlyDictionary<string, string[]>? Errors = null)
{
    public static CreateOperationResult Created(OperationDto operation) => new(CreateOperationOutcome.Created, operation);
    public static CreateOperationResult Invalid(IReadOnlyDictionary<string, string[]> errors) => new(CreateOperationOutcome.Invalid, null, errors);
    public static CreateOperationResult WalletNotFound() => new(CreateOperationOutcome.WalletNotFound);
}
