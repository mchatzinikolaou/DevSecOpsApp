using Microsoft.AspNetCore.OpenApi;
using Microsoft.AspNetCore.Http.HttpResults;
namespace DevSecOpsApp.RequestObjects
{
    public class LoginRequest
    {
        public string Username { get; set; }
        public string Password { get; set; }
    }
}