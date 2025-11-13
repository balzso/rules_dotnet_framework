using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;

namespace mage_wrapper
{
    /// <summary>
    /// Wrapper around mage.exe (Manifest Generation and Editing Tool)
    /// Used to generate ClickOnce application and deployment manifests for VSTO add-ins
    /// </summary>
    class Program
    {
        static int Main(string[] args)
        {
            if (args.Length < 2)
            {
                Console.WriteLine("Usage: mage_wrapper <mage.exe path> <mage arguments...>");
                Console.WriteLine("Example: mage_wrapper C:\\...\\mage.exe -New Application -ToFile MyApp.exe.manifest");
                return 1;
            }

            string magePath = args[0];

            // Validate mage.exe exists
            if (!File.Exists(magePath))
            {
                Console.Error.WriteLine($"ERROR: mage.exe not found at: {magePath}");
                return 1;
            }

            // Build arguments for mage.exe (skip the first arg which is mage.exe path)
            string mageArguments = string.Join(" ", args.Skip(1));

            try
            {
                using (var process = new Process())
                {
                    process.StartInfo.FileName = magePath;
                    process.StartInfo.Arguments = mageArguments;
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
                        Console.Error.WriteLine($"mage.exe exited with code {exitCode}");
                    }

                    return exitCode;
                }
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"ERROR: Failed to execute mage.exe: {ex.Message}");
                Console.Error.WriteLine($"Stack trace: {ex.StackTrace}");
                return 1;
            }
        }
    }
}
