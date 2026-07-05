-- SQLite Database Initialization Script
-- For DevSecOpsApp testing

CREATE TABLE IF NOT EXISTS Users (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Username TEXT NOT NULL UNIQUE,
    Password TEXT NOT NULL,
    Email TEXT,
    CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Insert test users for testing SQL Injection
INSERT OR IGNORE INTO Users (Username, Password, Email) VALUES 
    ('admin', 'password123', 'admin@example.com'),
    ('user1', 'user123', 'user1@example.com'),
    ('test', 'test123', 'test@example.com');
