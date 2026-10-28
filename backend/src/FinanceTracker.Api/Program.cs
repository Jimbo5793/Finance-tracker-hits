var builder = WebApplication.CreateBuilder(args);

// Lets the Flutter app call the API from another origin while developing
// (e.g. `flutter run -d chrome` on a random port).
builder.Services.AddCors(options =>
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseCors();
}

app.MapGet("/api/health", () => Results.Ok(new { status = "ok" }));

app.Run();

// Makes Program visible to the integration tests (WebApplicationFactory<Program>).
public partial class Program { }
