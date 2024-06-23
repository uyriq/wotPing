# wotPing.ps1

## Synopsis

This script conducts a ping test on a predefined list of server records and presents the results in a tabular format.

## Description

The script establishes a list of host records in the `$serverList` variable, each with a cluster field. It then resolves and performs a ping test on each record's IP. The script filters out IPv6 addresses and computes the average response time for each successful ping. The results are displayed in real-time and are finally summarized in a table, sorted by average response time. The optimal cluster is selected based on the minimum average time and minimum dispersion.

The script uses server information from the following sources:

- [Lesta.ru wiki](https://wiki.lesta.ru/ru/%D0%98%D0%B3%D1%80%D0%BE%D0%B2%D1%8B%D0%B5_%D0%BA%D0%BB%D0%B0%D1%81%D1%82%D0%B5%D1%80%D1%8B)

```txt
RU1 — Россия Россия, Москва
(login.p1.tanki.su)

RU2 — Россия Россия, Москва
(login.p2.tanki.su)

RU4 — Россия Россия, Екатеринбург
(login.p4.tanki.su)

RU6 — Россия Россия, Москва
(login.p6.tanki.su)

RU7 — Россия Россия, Санкт-Петербург
(login.p7.tanki.su)

RU8 — Россия Россия, Красноярск
(login.p8.tanki.su)

RU9 — Россия Россия, Хабаровск
(login.p9.tanki.su)
```

- [Wargaming.net wiki](https://na.wargaming.net/support/en/products/wot/article/10252/)
- [Wargaming.net wiki](https://eu.wargaming.net/support/ru/products/wot/article/15291/)

```txt
World of Tanks
EU_1: login.p1.worldoftanks.eu
EU_2: login.p2.worldoftanks.eu
EU_3: login.p3.worldoftanks.eu
EU_4: login.p4.worldoftanks.eu
World of Tanks: Blitz
EU_1: login0.wotblitz.eu
EU_2: login1.wotblitz.eu
EU_3: login2.wotblitz.eu
EU_4: login3.wotblitz.eu
EU_5: login4.wotblitz.eu
World of Warplanes	EU: login-eu.worldofwarplanes.com
World of Warships	EU_1: login1.worldofwarships.eu
EU_2: login2.worldofwarships.eu
```

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

## Usage

Go to the file wotPing.ps1
Click it to view the contents within the GitHub UI.
In the top right, right click the Raw button.
Save as... somewhere you like, with the .ps1 extension.

Run the script in PowerShell:

```powershell
.\wotPing.ps1
```

feel free to add or remove servers from the list. for doing so, you can edit the `$serverList` variable in the script.

```powershell

$serverList = @{
    # feel free to comment/uncomment/change this list
    # "Yandex"     = "ya.ru";
    "LESTA_RU-1" = "login.p1.tanki.su"
    "LESTA_RU-2" = "login.p2.tanki.su"
    "LESTA_RU-4" = "login.p4.tanki.su"
    "LESTA_RU-6" = "login.p6.tanki.su"
     "LESTA_RU-7" = "login.p7.tanki.su"
    "LESTA_RU-8" = "login.p8.tanki.su"
     "LESTA_RU-9" = "login.p9.tanki.su"
  #   "WOT_EU_1"       = "login.p1.worldoftanks.eu"
  #   "WOT_EU_2"       = "login.p2.worldoftanks.eu"
  #  "WOT_EU_3"       = "login.p3.worldoftanks.eu"
    # "WOT_EU_4"       = "login.p4.worldoftanks.eu"
    # "WOT_Blitz_EU_1" = "login0.wotblitz.eu"
     # "WOT_Blitz_EU_2" = "login1.wotblitz.eu"
    # "WOT_Blitz_EU_3" = "login2.wotblitz.eu"
    # "WOT_Blitz_EU_4" = "login3.wotblitz.eu"
    # "WOT_Blitz_EU_5" = "login4.wotblitz.eu"
}
```

LICENCE MIT

This script is free to use, as in "free beer". You can use it, modify it, and distribute it as you like. If you find it useful, please consider sharing your improvements.
