using FinancialApp.API.Auth;
using FinancialApp.BLL;
using FinancialApp.DB;
using FinancialApp.DB.Entities;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Token"
    });

    c.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = []
    });
});

builder.Services.AddDbContext<AppDbContext>(o =>
    o.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

var authDisabled = builder.Configuration.GetValue<bool>("Auth:Disabled");

if (authDisabled)
{
    builder.Services
        .AddAuthentication(DevAuthHandler.Scheme)
        .AddScheme<AuthenticationSchemeOptions, DevAuthHandler>(DevAuthHandler.Scheme, null);
}
else
{
    builder.Services.AddAuthentication().AddJwtBearer();
}
builder.Services.AddAuthorization();
builder.Services.AddBusiness();

var app = builder.Build();

if (authDisabled)
    app.Logger.LogWarning("AUTH IS DISABLED (Auth:Disabled=true). Every request runs as the dev user. Never use this in production.");

if (builder.Configuration.GetValue<bool>("Database:AutoMigrate"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();

    if (authDisabled && !await db.Users.AnyAsync(u => u.Email == "dev@local.test"))
    {
        db.Users.Add(new User { Email = "dev@local.test" });
        await db.SaveChangesAsync();
    }
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

// Lets the integration tests start the app (WebApplicationFactory<Program>).
public partial class Program { }
