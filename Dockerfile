# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# This stage is used when running from VS in fast mode (Default for Debug configuration)
# UPDATE: Using .NET 8.0 instead of 5.0
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base

# Install sqlite3 for database initialization
RUN apt-get update && apt-get install -y sqlite3 && rm -rf /var/lib/apt/lists/*

USER $APP_UID
WORKDIR /app
EXPOSE 8080


# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["DevSecOpsApp.csproj", "."]
RUN dotnet restore "./DevSecOpsApp.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "./DevSecOpsApp.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./DevSecOpsApp.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
COPY init-db.sql .
RUN sqlite3 app.db < init-db.sql
ENTRYPOINT ["dotnet", "DevSecOpsApp.dll"]