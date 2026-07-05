using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Configuration;
using DevSecOpsApp.RequestObjects;

namespace DevSecOpsApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")] 
    public class LoginController : ControllerBase
    {
        private readonly IConfiguration _config;


        public LoginController(IConfiguration config)
        {
            _config = config;
        }

        [HttpPost]
        public IActionResult CreateLoginRequest([FromBody] LoginRequest model)
        {
            try
            {
                string connectionString = _config.GetConnectionString("DefaultConnection")
                                          ?? "Data Source=app.db";

                using var connection = new SqliteConnection(connectionString);
                connection.Open();

                // INTENTIONAL VULNERABILITY: SQL Injection
                string query = $"SELECT Password FROM Users WHERE Username = '{model.Username}'";

                using var command = new SqliteCommand(query, connection);
                using var reader = command.ExecuteReader();

                if (reader.Read())
                {
                    // Get the plain text password from the database
                    string retrievedPassword = reader.GetString(0);

                    // INTENTIONAL VULNERABILITY: Plaintext password comparison
                    if (model.Password == retrievedPassword)
                    {
                        return Ok(new { Message = "Login successful", Token = Guid.NewGuid().ToString() });
                    }
                }

                return Unauthorized(new { Message = "Invalid credentials" });
            }
            catch (Exception ex)
            {
                // Return unauthorized on any error (database not initialized, etc.)
                return Unauthorized(new { Message = "Authentication failed", Details = ex.Message });
            }
        }
    }
}