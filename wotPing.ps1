<#
.SYNOPSIS
    This script executes a ping test on a set of cluster host records and presents the results in a tabular format. It is compatible with PowerShell version 5.1 and above.

.DESCRIPTION
    The script establishes a list of DNS records and conducts a ping test on each one. It excludes IPv6 addresses and computes the average response time for each successful ping. The results are then organized in a table and sorted by the average response time. The server information used in this script is sourced from:

    - [Lesta.ru wiki](https://wiki.lesta.ru/ru/%D0%98%D0%B3%D1%80%D0%BE%D0%B2%D1%8B%D0%B5_%D0%BA%D0%BB%D0%B0%D1%81%D1%82%D0%B5%D1%80%D1%8B)
    - [Wargaming.net](https://na.wargaming.net/support/en/products/wot/article/10252/)

.PARAMETER None
    This script does not require any parameters.

.EXAMPLE
    .\wotPing.ps1
    # This command runs the script and executes a ping test on the predefined host records.

.NOTES
    Author: Uyriq
    Date: June 2024
#>
#requires -Version 5.1

# The host records are defined below.
$serverList = @{
    # feel free to comment/uncomment/change this list
    "Yandex"     = "ya.ru";
    "LESTA_RU-1" = "login.p1.tanki.su"
    "LESTA_RU-2" = "login.p2.tanki.su"	
    "LESTA_RU-4" = "login.p4.tanki.su"
    "LESTA_RU-6" = "login.p6.tanki.su"
    "LESTA_RU-7" = "login.p7.tanki.su"
    "LESTA_RU-8" = "login.p8.tanki.su"
    "LESTA_RU-9" = "login.p9.tanki.su"
    # "WOT_EU_1"       = "login.p1.worldoftanks.eu"
    # "WOT_EU_2"       = "login.p2.worldoftanks.eu"
    # "WOT_EU_3"       = "login.p3.worldoftanks.eu"
    # "WOT_EU_4"       = "login.p4.worldoftanks.eu"
    # "WOT_Blitz_EU_1" = "login0.wotblitz.eu"
    # "WOT_Blitz_EU_2" = "login1.wotblitz.eu"
    # "WOT_Blitz_EU_3" = "login2.wotblitz.eu"
    # "WOT_Blitz_EU_4" = "login3.wotblitz.eu"
    # "WOT_Blitz_EU_5" = "login4.wotblitz.eu"

    
}

# Initialize an array to hold the results
$results = @()

# Loop over each DNS record
$counter = 1
# create hashtable for keep dnsDispersion
$serverDispersion = @{}
$serverAveragePing = @{}
foreach ($server in $serverList.GetEnumerator()) {
    # Calculate the total number of DNS records
    $totalRecords = $serverList.Count
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
            $pingResult = Test-Connection -ComputerName $ip -Count 4 -IPv4  
        }
        else {
            $pingResult = Test-Connection -ComputerName $ip -Count 4  
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
