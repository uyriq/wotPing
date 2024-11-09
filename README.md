# wotPing.ps1

## Synopsis

This script conducts a ping test on a list of server records provided via parameters or a JSON file and presents the results in a tabular format.

## Description

The script performs ping tests on a customizable list of servers, allowing you to add or remove servers without modifying the script itself. Server information can be provided directly through the `-serverList` parameter or via a JSON file specified with the `-serverListFile` parameter. All World of Tanks (WOT) gaming servers have been moved to a separate JSON file for easier management.

Results include the average response time and latency dispersion, helping you identify the optimal server based on these metrics.

### Server Information Sources

- [Lesta.ru wiki](https://wiki.lesta.ru/ru/%D0%98%D0%B3%D1%80%D0%BE%D0%B2%D1%8B%D0%B5_%D0%BA%D0%BB%D0%B0%D1%81%D1%82%D0%B5%D1%80%D1%8B)
- [Wargaming.net wiki](https://na.wargaming.net/support/en/products/wot/article/10252/)
- [Wargaming.net wiki](https://eu.wargaming.net/support/ru/products/wot/article/15291/)

## Prerequisites

Before you begin, ensure you have met the following requirements:

- You have installed PowerShell version 5.1 or later. You can check your PowerShell version by running the following command in your PowerShell terminal:

```powershell
$PSVersionTable.PSVersion
```

Script execution policy should be enabled. If the execution policy is not set to RemoteSigned or Unrestricted, you can change it using the Set-ExecutionPolicy cmdlet. Note that you may need to run this command as an administrator:

```powershell
Set-ExecutionPolicy RemoteSigned
```

Usage
Providing Server Lists
You can supply servers to the script in two ways:

Using Parameters:

-serverList: Provide a list of server URLs directly.
-serverListFile: Provide a path to a JSON file containing server details.
Using a JSON File:

All gaming WOT servers have been moved to a JSON file (serverList.json). You can modify this file to add or remove gaming servers.

Running the Script
Download the Script:

Go to the wotPing.ps1 file in the GitHub repository.
Click on the Raw button in the top right.
Save the file with a .ps1 extension to your desired location.
Execute the Script in PowerShell:

```Powershell
.\wotPing.ps1 -pingCount 4 -serverList "ya.ru", "google.com" -serverListFile "serverList.json"
```

Parameters:
-pingCount: (Optional) Number of ping attempts per server. Defaults to 4.
-serverList: (Optional) Direct list of server URLs.
-serverListFile: (Optional) Path to a JSON file containing server details.

Example
To ping servers listed in serverList.json with the default ping count:

Editing Server Lists
Direct Parameter Method:

Modify the $serverList hashtable within the script if you prefer hardcoding (not recommended).

JSON File Method:

Edit serverList.json to add or remove servers. Ensure each server entry includes name and url fields.

```JSON
{
  "servers": [
    { "name": "Yandex", "url": "ya.ru" },
    { "name": "LESTA_RU-1", "url": "login.p1.tanki.su" },
    // Add or remove server entries as needed
  ]
}
```

## License

[MIT License](LICENSE)

This script is free to use, as in "free beer". You can use it, modify it, and distribute it as you like. If you find it useful, please consider sharing your improvements.
