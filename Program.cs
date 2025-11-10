using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using MyApp.Data;

var builder = WebApplication.CreateBuilder(args);

// SQL Server
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Ajouter les services nécessaires
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// ✅ Swagger avec configuration personnalisée
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "MyApp API",
        Version = "v1",
        Description = "API de démonstration pour le déploiement via GitHub Actions sur IIS (srv-staging)",
        Contact = new OpenApiContact
        {
            Name = "Equipe DevOps",
            Email = "support@myapp.local"
        },
        License = new OpenApiLicense
        {
            Name = "MIT License"
        }
    });
});

var app = builder.Build();

// ✅ Activer Swagger seulement en développement
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "MyApp API v1");
        c.RoutePrefix = string.Empty; // Swagger sera accessible directement à la racine "/"
    });
}

app.UseAuthorization();
app.MapControllers();

// ✅ Migration automatique au démarrage
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
}

app.Run();
