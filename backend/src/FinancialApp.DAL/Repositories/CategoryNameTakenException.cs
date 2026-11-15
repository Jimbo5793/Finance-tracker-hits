namespace FinancialApp.DAL.Repositories;

/// <summary>The user already has a category of this kind with this name (caught by the database's unique index).</summary>
public class CategoryNameTakenException(string name, string kind, Exception inner)
    : Exception($"An {kind} category called \"{name}\" already exists for this user.", inner);
