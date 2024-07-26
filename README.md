# MarketMaker
 Market maker is a series of scripts to help you locally run an Automated Market Maker (AMM) from your Chia Wallet.  The trading pairs that are currently setup are XCH-USDC, XCH-USDC.B, XCH-Millieth, XCH-Millieth.b.

 ## Prerequisets
 PSSQLite is required to keep track of trades and current coin prices.
```powershell
Install-Module -Name PSSQLite
```
 You'll also want to use PowerShell 7.4 or greater.  PowerShell 5 will not work.

 Get [PowerShell 7.4](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4)



# Warnings
Please make sure you understand what these scripts do.  They will create offers and post them automatically to dexie.  If you enter bad information, or if the coingecko API gives you bad data, then it will sell your xch for way less than you want.   There are some attempts at failsafes, but it's not a guarantee.  Please go though these scripts and verify you are comfortable with the risk before running it.

# Usage
You'll want to CD into the directory for MarketMaker.

You'll want to Dot Source the Boot.ps1 script.  Make sure you start the command with a [.] 
```PowerShell
. .\Boot.ps1
```
This will check your prerequisets and create the database tables needed for the application.

The first time it is ran, it will also copy the Config_Template.ps1 to Config.ps1.  Please edit the Config.ps1 with the paramaters you want.

```PowerShell
$config = @{
    database = 'c:\chia\trades.SQLite' # Change this to a folder and filename you want.   
    use_pushover = $false # Change to $true of you wish to use pushover for notifications of offers taken
    pushover_token = 'API_Token'
    pushover_name = 'User_KEY'
}
```

## Running the AMM

