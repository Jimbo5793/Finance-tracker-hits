FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY global.json ./

COPY src/FinancialApp.API/FinancialApp.API.csproj src/FinancialApp.API/
COPY src/FinancialApp.BLL/FinancialApp.BLL.csproj src/FinancialApp.BLL/
COPY src/FinancialApp.DAL/FinancialApp.DAL.csproj src/FinancialApp.DAL/
COPY src/FinancialApp.DB/FinancialApp.DB.csproj src/FinancialApp.DB/
RUN dotnet restore src/FinancialApp.API/FinancialApp.API.csproj

COPY src/ src/
RUN dotnet publish src/FinancialApp.API/FinancialApp.API.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "FinancialApp.API.dll"]
