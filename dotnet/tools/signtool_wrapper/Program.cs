using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;

namespace signtool_wrapper
{
    /// <summary>
    /// Wrapper around signtool.exe (Code Signing Tool)
    /// Used to sign ClickOnce manifests and assemblies with Authenticode signatures
    /// </summary>
    class Program
    {
        static int Main(string[] args)
        {
            if (args.Length < 2)
            {
                Console.WriteLine("Usage: signtool_wrapper <signtool.exe path> <signtool arguments...>");
                Console.WriteLine("Example: signtool_wrapper C:\\...\\signtool.exe sign /f cert.pfx /p password file.manifest");
                return 1;
            }

            string signtoolPath = args[0];

            // Validate signtool.exe exists
            if (!File.Exists(signtoolPath))
            {
                Console.Error.WriteLine($"ERROR: signtool.exe not found at: {signtoolPath}");
                return 1;
            }

            // Build arguments for signtool.exe (skip the first arg which is signtool.exe path)
            string signtoolArguments = string.Join(" ", args.Skip(1));

            try
            {
                using (var process = new Process())
                {
                    process.StartInfo.FileName = signtoolPath;
                    process.StartInfo.Arguments = signtoolArguments;
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.RedirectStandardOutput = true;
                    process.StartInfo.RedirectStandardError = true;
                    process.StartInfo.CreateNoWindow = true;

                    // Capture output
                    var outputBuilder = new StringBuilder();
                    var errorBuilder = new StringBuilder();

                    process.OutputDataReceived += (sender, e) =>
                    {
                        if (!string.IsNullOrEmpty(e.Data))
                        {
                            outputBuilder.AppendLine(e.Data);
                            Console.WriteLine(e.Data);
                        }
                    };

                    process.ErrorDataReceived += (sender, e) =>
                    {
                        if (!string.IsNullOrEmpty(e.Data))
                        {
                            errorBuilder.AppendLine(e.Data);
                            Console.Error.WriteLine(e.Data);
                        }
                    };

                    process.Start();
                    process.BeginOutputReadLine();
                    process.BeginErrorReadLine();
                    process.WaitForExit();

                    int exitCode = process.ExitCode;

                    if (exitCode != 0)
                    {
                        Console.Error.WriteLine($"signtool.exe exited with code {exitCode}");
                    }

                    return exitCode;
                }
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"ERROR: Failed to execute signtool.exe: {ex.Message}");
                Console.Error.WriteLine($"Stack trace: {ex.StackTrace}");
                return 1;
            }
        }
    }
}
