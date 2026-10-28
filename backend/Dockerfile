FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore first so the package layer is cached between builds
COPY global.json ./
COPY src/FinanceTracker.Api/FinanceTracker.Api.csproj src/FinanceTracker.Api/
RUN dotnet restore src/FinanceTracker.Api/FinanceTracker.Api.csproj

COPY src/ src/
RUN dotnet publish src/FinanceTracker.Api/FinanceTracker.Api.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app .
# ASP.NET images listen on 8080 by default
EXPOSE 8080
ENTRYPOINT ["dotnet", "FinanceTracker.Api.dll"]
