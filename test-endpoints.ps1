#!/usr/bin/env pwsh
# Quick test script for DevSecOpsApp endpoints

Write-Host "?? DevSecOpsApp Endpoint Testing" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080"
$delay = 1

Write-Host "Waiting for application to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds $delay

# Test 1: Weather Forecast (Safe)
Write-Host ""
Write-Host "Test 1: Weather Forecast Endpoint (SAFE)" -ForegroundColor Green
Write-Host "GET $baseUrl/WeatherForecast" -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/WeatherForecast" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "? Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response preview:" -ForegroundColor Gray
    Write-Host ($response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 1) -ForegroundColor White
} catch {
    Write-Host "? Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Login - Valid credentials
Write-Host ""
Write-Host "Test 2: Login Endpoint - Valid Credentials" -ForegroundColor Green
Write-Host "POST $baseUrl/api/login" -ForegroundColor Gray
try {
    $body = @{username="test"; password="test123"} | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/api/login" -Method POST `
        -ContentType "application/json" -Body $body -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "? Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor White
} catch {
    Write-Host "??  Error (expected - database may not have data): $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
}

# Test 3: Login - SQL Injection attempt
Write-Host ""
Write-Host "Test 3: Login Endpoint - SQL Injection Attempt (VULNERABLE)" -ForegroundColor Red
Write-Host "POST $baseUrl/api/login" -ForegroundColor Gray
Write-Host "Payload: {""username"":""admin' OR '1'='1"",""password"":""x""}" -ForegroundColor DarkGray
try {
    $body = @{username="admin' OR '1'='1"; password="x"} | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/api/login" -Method POST `
        -ContentType "application/json" -Body $body -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "??  Status: $($response.StatusCode)" -ForegroundColor Yellow
    Write-Host "Response: $($response.Content)" -ForegroundColor White
} catch {
    Write-Host "??  Response (expected): $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
}

# Test 4: Command Injection attempt
Write-Host ""
Write-Host "Test 4: Command Execution Endpoint - Command Injection (VULNERABLE)" -ForegroundColor Red
Write-Host "POST $baseUrl/api/command/execute" -ForegroundColor Gray
Write-Host "Payload: {""command"":""whoami""}" -ForegroundColor DarkGray
try {
    $body = @{command="whoami"} | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/api/command/execute" -Method POST `
        -ContentType "application/json" -Body $body -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "? Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor White
} catch {
    Write-Host "? Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Swagger UI
Write-Host ""
Write-Host "Test 5: Swagger UI" -ForegroundColor Green
Write-Host "GET $baseUrl/swagger/index.html" -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/swagger/index.html" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "? Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "? Swagger UI is accessible" -ForegroundColor Green
} catch {
    Write-Host "? Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "? Testing Complete!" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
