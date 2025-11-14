using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;

namespace wix_wrapper
{
    /// <summary>
    /// Wrapper around wix.exe (WiX Toolset v5)
    /// Used to build Windows Installer packages (.msi) from WiX source files (.wxs)
    /// </summary>
    class Program
    {
        /// <summary>
        /// Quotes an argument if it contains spaces or special characters.
        /// This ensures proper parsing by the command line processor.
        /// </summary>
        static string QuoteArgumentIfNeeded(string arg)
        {
            // If argument is empty, quote it
            if (string.IsNullOrEmpty(arg))
                return "\"\"";

            // Check if quoting is needed
            bool needsQuoting = arg.Contains(" ") || arg.Contains("\t") || arg.Contains("\"");

            if (!needsQuoting)
                return arg;

            // Build quoted argument with escaped internal quotes
            var result = new StringBuilder();
            result.Append("\"");

            for (int i = 0; i < arg.Length; i++)
            {
                char c = arg[i];

                // Escape backslashes that precede quotes
                if (c == '\\')
                {
                    int numBackslashes = 1;
                    while (i + 1 < arg.Length && arg[i + 1] == '\\')
                    {
                        numBackslashes++;
                        i++;
                    }

                    // If followed by quote, double the backslashes
                    if (i + 1 < arg.Length && arg[i + 1] == '\"')
                    {
                        result.Append('\\', numBackslashes * 2);
                    }
                    else
                    {
                        result.Append('\\', numBackslashes);
                    }
                }
                // Escape quotes
                else if (c == '\"')
                {
                    result.Append("\\\"");
                }
                else
                {
                    result.Append(c);
                }
            }

            result.Append("\"");
            return result.ToString();
        }

        static int Main(string[] args)
        {
            if (args.Length < 2)
            {
                Console.WriteLine("Usage: wix_wrapper <wix.exe path> <wix arguments...>");
                Console.WriteLine("Example: wix_wrapper C:\\...\\wix.exe build -out Product.msi Product.wxs");
                return 1;
            }

            string wixPath = args[0];

            // Validate wix.exe exists
            if (!File.Exists(wixPath))
            {
                Console.Error.WriteLine($"ERROR: wix.exe not found at: {wixPath}");
                return 1;
            }

            // Build arguments for wix.exe (skip the first arg which is wix.exe path)
            // Properly quote arguments that contain spaces or quotes
            string wixArguments = string.Join(" ", args.Skip(1).Select(QuoteArgumentIfNeeded));

            try
            {
                using (var process = new Process())
                {
                    process.StartInfo.FileName = wixPath;
                    process.StartInfo.Arguments = wixArguments;
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
                        Console.Error.WriteLine($"wix.exe exited with code {exitCode}");
                    }

                    return exitCode;
                }
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"ERROR: Failed to execute wix.exe: {ex.Message}");
                Console.Error.WriteLine($"Stack trace: {ex.StackTrace}");
                return 1;
            }
        }
    }
}
