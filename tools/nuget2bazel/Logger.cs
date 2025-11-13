using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using NuGet.Common;

namespace nuget2bazel
{
    public class Logger: NuGet.Common.ILogger
    {
        public void LogDebug(string data)
        {
            Log(LogLevel.Debug, data);
        }

        public void LogVerbose(string data)
        {
            Log(LogLevel.Verbose, data);
        }

        public void LogInformation(string data)
        {
            Log(LogLevel.Information, data);
        }

        public void LogMinimal(string data)
        {
            Log(LogLevel.Minimal, data);
        }

        public void LogWarning(string data)
        {
            Log(LogLevel.Warning, data);
        }

        public void LogError(string data)
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine(data);
            Console.ResetColor();
        }

        public void LogInformationSummary(string data)
        {
            Log(LogLevel.Minimal, data);
        }

        public void Log(LogLevel level, string data)
        {
            var color = ConsoleColor.White;

            switch (level)
            {
                case LogLevel.Debug: color = ConsoleColor.DarkBlue;
                    break;
                case LogLevel.Error: color = ConsoleColor.Red;
                    break;
                case LogLevel.Information: color = ConsoleColor.White;
                    break;
                case LogLevel.Minimal: color = ConsoleColor.White;
                    break;
                case LogLevel.Verbose: color = ConsoleColor.Blue;
                    break;
                case LogLevel.Warning: color = ConsoleColor.Yellow;
                    break;
            }

            Console.ForegroundColor = color;
            Console.Write(data);
            Console.ResetColor();
        }

        public Task LogAsync(LogLevel level, string data)
        {
            Log(level, data);
            return Task.CompletedTask;
        }

        public void Log(ILogMessage message)
        {
            Log(message.Level, message.Message);
        }

        public Task LogAsync(ILogMessage message)
        {
            Log(message.Level, message.Message);
            return Task.CompletedTask;
        }
    }
}
