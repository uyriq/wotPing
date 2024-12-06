using System;
using System.Collections.Generic;
using System.CommandLine;
using System.Net;  // this for Dns
using System.Net.NetworkInformation;
using System.Text.Json;
using System.Linq;

namespace WotPing
{
    public class ServerEntry
    {
        public required string Name { get; set; }
        public required string Url { get; set; }
    }

    public class ServerList
    {
        public required List<ServerEntry> Servers { get; set; } = new();
    }

    public class PingResult
    {
        public required string HostClusterName { get; set; }
        public required string IpAddress { get; set; }
        public required string Status { get; set; }
        public double? AverageTime { get; set; }
        public double? AverageDispersion { get; set; }
    }

    class Program
    {
        static async Task<int> Main(string[] args)
        {
            var rootCommand = new RootCommand("Server Name Resolving Ping Utility");

            var pingCountOption = new Option<int>(
                "--ping-count",
                getDefaultValue: () => 4,
                description: "Number of pings per server");

            var serverListOption = new Option<string[]>(
                "--server-list",
                    parseArgument: result =>
                    {
                        var values = result.Tokens
                            .Select(t => t.Value)
                            .SelectMany(v => v.Split(',', StringSplitOptions.RemoveEmptyEntries))
                            .Select(s => s.Trim())
                            .ToArray();
                        return values;
                    },
                description: "List of servers to ping");

            var serverListFileOption = new Option<FileInfo>(
                "--server-list-file",
                description: "JSON file containing server list");

            rootCommand.AddOption(pingCountOption);
            rootCommand.AddOption(serverListOption);
            rootCommand.AddOption(serverListFileOption);

            rootCommand.SetHandler(async (pingCount, servers, serverFile) =>
            {
                await RunPingTests(pingCount, servers ?? Array.Empty<string>(), serverFile);
            },
            pingCountOption, serverListOption, serverListFileOption);

            return await rootCommand.InvokeAsync(args);
        }

        static async Task RunPingTests(int pingCount, string[] serverList, FileInfo serverListFile)
        {
            var serverDict = new Dictionary<string, string>();
            Console.WriteLine("Initializing ping tests...");


            // Process direct server list first
            if (serverList?.Length > 0)
            {
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine($"Processing {serverList.Length} servers from command line");
                Console.ResetColor();
                foreach (var server in serverList)
                {
                    if (!string.IsNullOrWhiteSpace(server))
                    {
                        serverDict[server] = server;
                    }
                }
            }


            // Try to process serverListFile if provided    
            // Process JSON file
            if (serverListFile != null && File.Exists(serverListFile.FullName))
            {
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine($"Processing servers from {serverListFile.Name}");
                Console.ResetColor();
                try
                {
                    var jsonContent = await File.ReadAllTextAsync(serverListFile.FullName);
                    //  Console.WriteLine($"Read JSON content: {jsonContent}"); // Debug log

                    var options = new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true,
                        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                    };

                    var servers = JsonSerializer.Deserialize<ServerList>(jsonContent, options);

                    if (servers?.Servers != null)
                    {
                        foreach (var server in servers.Servers)
                        {
                            if (!string.IsNullOrWhiteSpace(server.Name) && !string.IsNullOrWhiteSpace(server.Url))
                            {
                                serverDict[server.Name] = server.Url;
                            }
                        }
                        Console.WriteLine($"Added {servers.Servers.Count} servers from JSON file");
                    }
                    else
                    {
                        Console.WriteLine("Warning: No servers found in JSON file or invalid format");
                    }
                }
                catch (Exception ex)
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine($"Warning: Failed to process server list file: {ex.Message}\nStack trace: {ex.StackTrace}");
                    Console.ResetColor();
                }
            }

            // Only fail if we have no servers from either source
            if (serverDict.Count == 0)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Error: No valid servers provided");
                Console.ResetColor();
                return;
            }
            Console.WriteLine($"\nStarting ping tests for {serverDict.Count} servers, {pingCount} pings each");
            Console.WriteLine(new string('-', 80));
            var results = new List<PingResult>();
            var ping = new Ping();

            foreach (var (name, url) in serverDict)
            {
                Console.WriteLine($"Processing {url}...");

                try
                {
                    var addresses = await Dns.GetHostAddressesAsync(url);
                    var ipv4Addresses = addresses.Where(a => a.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork);

                    foreach (var ip in ipv4Addresses)
                    {
                        var times = new List<long>();

                        for (int i = 0; i < pingCount; i++)
                        {
                            try
                            {
                                var reply = await ping.SendPingAsync(ip, 1000);
                                if (reply.Status == IPStatus.Success)
                                {
                                    times.Add(reply.RoundtripTime);
                                }
                            }
                            catch (Exception ex)
                            {
                                Console.Error.WriteLine($"Ping failed: {ex.Message}");
                            }
                        }

                        if (times.Any())
                        {
                            var avgTime = times.Average();
                            var dispersion = times.Max() - times.Min();

                            results.Add(new PingResult
                            {
                                HostClusterName = name,
                                IpAddress = ip.ToString(),
                                Status = "Success",
                                AverageTime = avgTime,
                                AverageDispersion = dispersion
                            });
                        }
                        else
                        {
                            results.Add(new PingResult
                            {
                                HostClusterName = name,
                                IpAddress = ip.ToString(),
                                Status = "Failure"
                            });
                        }
                    }
                }
                catch (Exception ex)
                {
                    Console.Error.WriteLine($"Failed to resolve {url}: {ex.Message}");
                }
            }

            // Display results
            var successfulResults = results
                .Where(r => r.Status == "Success")
                .OrderBy(r => r.AverageTime);

            Console.WriteLine("\nResults:");
            Console.WriteLine("{0,-20} {1,-15} {2,-10} {3,-15} {4,-15}",
                "Host", "IP", "Result", "Avg Time", "Dispersion");
            Console.WriteLine(new string('-', 75));

            foreach (var result in successfulResults)
            {
                Console.WriteLine("{0,-20} {1,-15} {2,-10} {3,-15:F2} {4,-15:F2}",
                    result.HostClusterName,
                    result.IpAddress,
                    result.Status,
                    result.AverageTime,
                    result.AverageDispersion);
            }

            // Display optimal server
            var optimal = successfulResults.FirstOrDefault();
            if (optimal != null)
            {
                Console.WriteLine($"\nOptimal server: {optimal.HostClusterName} ({optimal.IpAddress})");
                Console.WriteLine($"Average time: {optimal.AverageTime:F2}ms");
                Console.WriteLine($"Dispersion: {optimal.AverageDispersion:F2}ms");
            }
        }
    }
}
