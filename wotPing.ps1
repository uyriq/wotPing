<#
.SYNOPSIS
    Executes ping tests on a set of servers and presents the results in a tabular format.

.DESCRIPTION
    The script accepts a list of server URLs either directly through the `-serverList` parameter or via a JSON file specified with the `-serverListFile` parameter. It performs ping tests on each server, calculates the average response time and dispersion, and identifies the optimal server based on these metrics.

.PARAMETER pingCount
    Specifies how many times to perform the ping test. Defaults to 4 if not provided.

.PARAMETER serverList
    Specifies a list of server URLs to ping. Each server's name is automatically assigned to be the same as its URL.

.PARAMETER serverListFile
    Specifies a JSON file containing a list of servers to ping. The JSON should include `name` and `url` for each server.

.PARAMETER Help
    Displays this help message.

.EXAMPLE
    .\wotPing.ps1 -pingCount 5 -serverList "ya.ru", "google.com" -serverListFile "serverList.json"
    # Pings "ya.ru", "google.com", and all servers listed in "serverList.json" five times each.

.EXAMPLE
    .\wotPing.ps1 -serverList "example.com"
    # Pings "example.com" four times (default ping count).

.EXAMPLE
    .\wotPing.ps1 -serverListFile "serverList.json"
    # Pings all servers listed in "serverList.json" four times each (default ping count).

.NOTES
    Author: Uyriq
    Date: June 2024, Dec 2024
#>
param(
    [switch]$Help,
    [int]$pingCount = 4,
    [string[]]$serverList,
    [string]$serverListFile
)

# Display help and exit if -Help is provided
if ($Help) {
    Get-Help -Full $PSCommandPath
    exit
}

# Check if neither serverList nor serverListFile is provided
if (-not $serverList -and -not $serverListFile) {
    $userInput = Read-Host "WotPing: Check examples with -Help, please provide at least one server URL (comma separated)"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        Write-Error "No server URLs provided. Exiting."
        exit 1
    }
    $serverList = $userInput -split ',' | ForEach-Object { $_.Trim() }
}

# Initialize the server list hashtable
$serverListHash = @{}

# Process servers from the -serverList parameter
if ($serverList) {
    foreach ($server in $serverList) {
        # Trim any whitespace and ensure the server address is valid
        $trimmedServer = $server.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmedServer)) {
            Write-Warning "Encountered an empty server entry in -serverList parameter. Skipping."
            continue
        }

        # Use the server address as both name and address
        $serverListHash[$trimmedServer] = $trimmedServer
    }
}

# Process servers from the -serverListFile parameter
if ($serverListFile) {
    if (-Not (Test-Path -Path $serverListFile)) {
        Write-Error "The server list file '$serverListFile' does not exist."
        exit 1
    }

    try {
        # Read and parse the JSON file
        $jsonContent = Get-Content -Path $serverListFile -Raw | ConvertFrom-Json

        if (-Not $jsonContent.servers) {
            Write-Error "The JSON file '$serverListFile' does not contain a 'servers' array."
            exit 1
        }

        foreach ($server in $jsonContent.servers) {
            if (-Not $server.name -or -Not $server.url) {
                Write-Warning "A server entry in '$serverListFile' is missing 'name' or 'url'. Skipping."
                continue
            }

            # Check for duplicate names
            if ($serverListHash.ContainsKey($server.name)) {
                Write-Warning "Duplicate server name '$($server.name)' found. Overwriting the existing entry."
            }

            $serverListHash[$server.name] = $server.url
        }
    }
    catch {
        Write-Error "Failed to read or parse the JSON file '$serverListFile'. Error: $_"
        exit 1
    }
}

# Ensure that at least one server is provided
if ($serverListHash.Count -eq 0) {
    Write-Error "No servers provided. Please specify at least one server using -serverList or -serverListFile."
    exit 1
}

# Initialize an array to hold the results
$results = @()

# Loop over each DNS record
$counter = 1
# create hashtable for keep dnsDispersion
$serverDispersion = @{}
$serverAveragePing = @{}
foreach ($server in $serverListHash.GetEnumerator()) {
    # Calculate the total number of DNS records
    $totalRecords = $serverListHash.Count
    # Display the current number of $server
    Write-Host "Processing $($counter) of $totalRecords" -ForegroundColor Green
    Write-Host "Host $($server.Value)" -ForegroundColor Yellow
    $counter++

    # Perform the [System.Net.Dns] instead of nslookup 
    try {
        # when loop in foreach, it will output curent number of total
        $ipAddresses = [System.Net.Dns]::GetHostAddresses($server.Value) | ForEach-Object { $_.IPAddressToString }
    }
    catch [System.Net.Sockets.SocketException] {
        Write-Host "Failed to resolve hostname $($server.Value): $($_.Exception.Message)"
        continue
    }
    # Filter out IPv6 addresses
    $ipAddresses = $ipAddresses | Where-Object { $_ -notmatch ":" }

    # Loop over each IP address 
    foreach ($ip in $ipAddresses) {
        # Perform the ping, prefer ipv4 address
        # display current ip
        Write-Host $ip -NoNewline 
        # check if PSVersionTable.PSVersion is 7 or higher
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $pingResult = Test-Connection -ComputerName $ip -Count $pingCount -IPv4  
        }
        else {
            $pingResult = Test-Connection -ComputerName $ip -Count $pingCount   
        }


        # Check if the ping was successful depending of PSVersionTable.PSVersion we do it in two way
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $ping = $null -ne $pingResult
            
        }
        else {
            $ping = $pingResult.IPV4Address.length -ne 0
           
        } 
        
        # Calculate the average response time
        
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $pingAverageTime = ($pingResult.Latency | Measure-Object -Average).Average
            
        }
        else {
            $pingAverageTime = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
        }
        $serverAveragePing[$server.Key] = $pingAverageTime
        # show current average latency value
        if ($pingAverageTime -gt 0) {
            Write-Host " $pingAverageTime" -NoNewline
            Write-Host "ms"
        }

        # Calculate latency dispersion for each ip adress of $server.Value record  depending of PSVersionTable.PSVersion we do it in two way
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $pingDispersion = ($pingResult.Latency | Measure-Object -Minimum -Maximum).Maximum - ($pingResult.Latency | Measure-Object -Minimum -Maximum).Minimum
        }
        else {
            $pingDispersion = ($pingResult | Measure-Object -Property ResponseTime -Minimum -Maximum).Maximum - ($pingResult | Measure-Object -Property ResponseTime -Minimum -Maximum).Minimum
        }
        # affine dnsDispersion over array of $ipAddresses add maximums of dispersion
        if ($serverDispersion.ContainsKey($server.Key) -and $pingDispersion -gt $serverDispersion[$server.Key] ) {
            $serverDispersion[$server.Key] += $pingDispersion
        }
        else {
            $serverDispersion[$server.Key] = $pingDispersion
        } 
        # If the ping was successful, add the average time to the results array
        if ($ping -and $pingAverageTime -gt 0 ) {
            $results += New-Object PSObject -Property ([ordered]@{
                    "Host Cluster Name"  = $server.Key;
                    "IP Address"         = $ip;
                    "Ping Result"        = "Success";
                    "Average Time"       = $pingAverageTime;
                    "Average Dispersion" = $serverDispersion[$server.Key];
                })
        }
        else {
            $results += New-Object PSObject -Property ([ordered]@{
                    "Host Cluster Name"  = $server.Key;
                    "IP Address"         = $ip;
                    "Ping Result"        = "Failure";
                    "Average Time"       = $null;
                    "Average Dispersion" = $null;
                })
        }
    }
}

# Print out the $results array
# $results | Sort-Object 'Average Time' | Format-Table 'Ping Result', 'IP Address', 'Host Name', 'Average Time', 'Average Dispersion' -AutoSize

# Display the results in a table, sorted by Average Time
# Group the results by 'Host Cluster Name' and then sort each group by 'Average Time'
# Sort the results by 'Average Time' and then group by 'Host Cluster Name'
$results | ForEach-Object {
    $_ | Add-Member -NotePropertyName 'Average Dispersion' -NotePropertyValue ([int] $_.'Average Dispersion') -Force -PassThru |
    Add-Member -NotePropertyName 'Average Time' -NotePropertyValue ([int] $_.'Average Time') -Force -PassThru
} | Sort-Object 'Average Time' | Group-Object 'Host Cluster Name' | ForEach-Object {
    $_.Group
} | Format-Table 'Ping Result', 'IP Address', 'Host Cluster Name', 'Average Time', 'Average Dispersion' -AutoSize

Write-Host "Optimal Cluster Based on Average Time and Dispersion: " -ForegroundColor Green -NoNewline

# Group the results by 'Host Cluster Name', calculate the average time and dispersion for each group, and sort the groups by these averages
$results | ForEach-Object {
    $_ | Add-Member -NotePropertyName 'Average Dispersion' -NotePropertyValue ([int] $_.'Average Dispersion') -Force -PassThru |
    Add-Member -NotePropertyName 'Average Time' -NotePropertyValue ([int] $_.'Average Time') -Force -PassThru
} | Group-Object 'Host Cluster Name' | ForEach-Object {
    $averageTime = ($_.Group | Measure-Object 'Average Time' -Average).Average
    $averageDispersion = ($_.Group | Measure-Object 'Average Dispersion' -Average).Average
    [PSCustomObject]@{
        'Host Cluster Name'  = $_.Name
        'Average Time'       = $averageTime
        'Average Dispersion' = $averageDispersion
    }
} | Sort-Object 'Average Time', 'Average Dispersion' | Select-Object -First 1 | Format-Table -HideTableHeaders  -AutoSize
