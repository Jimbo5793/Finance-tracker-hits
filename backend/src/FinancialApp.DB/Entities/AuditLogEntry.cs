namespace FinancialApp.DB.Entities;

/// <summary>One row per audited change: who did what, when, to which record, with which values.</summary>
public class AuditLogEntry
{
    public long Id { get; set; }
    public int UserId { get; set; }
    public string Action { get; set; } = "";
    public string EntityType { get; set; } = "";
    public int EntityId { get; set; }
    /// <summary>The values involved, as JSON.</summary>
    public string Data { get; set; } = "{}";
    public DateTime CreatedAt { get; set; }

    public User? User { get; set; }
}
