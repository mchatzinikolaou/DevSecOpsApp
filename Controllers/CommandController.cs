using Microsoft.AspNetCore.Mvc;
using DevSecOpsApp.RequestObjects;
using System.Diagnostics;

namespace DevSecOpsApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CommandController : ControllerBase
    {
        private readonly ILogger<CommandController> _logger;

        public CommandController(ILogger<CommandController> logger)
        {
            _logger = logger;
        }

        [HttpPost("execute")]
        public IActionResult ExecuteCommand([FromBody] CustomCommandRequest request)
        {
            try
            {
                // INTENTIONAL VULNERABILITY: Command Injection
                // User input is directly passed to Process.Start without any sanitization
                var processInfo = new ProcessStartInfo
                {
                    FileName = "/bin/bash",
                    Arguments = $"-c \"{request.Command}\"",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using var process = Process.Start(processInfo);
                process?.WaitForExit();

                string output = process?.StandardOutput.ReadToEnd() ?? "No output";
                string error = process?.StandardError.ReadToEnd() ?? "";

                return Ok(new { Output = output, Error = error });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Command execution failed");
                return BadRequest(new { Message = ex.Message });
            }
        }
    }
}
