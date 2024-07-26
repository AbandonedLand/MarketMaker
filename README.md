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
    # Database Location and Filename
    database = 'c:\chiaDB\trades.SQLite'

    # Pushover notifications settings
    use_pushover = $true
    pushover_token = 'Api_secret'
    pushover_name = 'api_user_name'
    
    # Traded pairs -  To turn off a pair, change it to $false from $true.
    trading_pair_xch_usdc = $true
    trading_pair_xch_usdcb = $true
    trading_pair_usdc_millieth = $true
    trading_pair_usdcb_milliethb = $true

    # Trading Config

    # Percent is the maximun percent of funds you wish to trade with at a time.  
    # Example: If you have 50 xch and 300 USDC.B and put 50 as the percent, you will create offers to sell upto 25xch and to buy upto 150 with of xch.
    percent = 50

    # The xch_spread is the amount in USDC you wish to add to your sell offers or subtract from your buy offers.   
    # Example: If the current XCH price from coingecko is $20 and you have a 0.2 xch_spread, you will create a sell offer for $20.20 per xch and a buy offer of $19.80 per xch.
    xch_spread = 0.2

    # Same as xch_spread, but for millieth offers.
    millieth_spread = 0.05

    # This will determine the minimum amount of XCH to buy/sell at a time.  It is also the amount of xch to skip for the next offer.
    # Example:  If the xch_step is 1 and you have a total of 100 XCH and a percent of 50,  then the AMM will create 50 offers spaced 1xch apart. 
    # You'd get a 1XCH sell offer for 20.20 usd, and a 2XCH sell offer for 40.40 usd, a 3XCH sell offer for 60.60 usd, etc.
    xch_step = 1

    # Same as xch_step but for millieth
    millieth_step = 5

    price_change_per_step = 0.001

    # This is the minimum in USDC you'll want to sell xch for.  This is a fail safe to stop trading below this number.
    min_xch_sell_price = 15

    # This is the minimum in USDC you'll want to sell millieth for.  This is a fail safe to stop trading below this number.
    min_millieth_sell_price = 3

    # This is the maximum in USDC you'll want to buy XCH for.  This is a fail safe to stop trading above this number.
    max_xch_buy_price = 30

    # This is the maximum in USDC you'll want to sell Millieth for.  This is a fail safe to stop trading above this number.
    max_millieth_buy_price = 3.60



}
```

## Running the AMM
To start the AMM running, simply run
```PowerShell
Run-AMM
```
It should boot up and start running.
