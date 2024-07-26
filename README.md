# MarketMaker
 Market maker is a series of scripts to help you locally run an Automated Market Maker (AMM) from your Chia Wallet.  The trading pairs that are currently setup are XCH-USDC, XCH-USDC.B, XCH-Millieth, XCH-Millieth.b.

 It will take your configuration and run an AMM based on what you're wanting to accomplish.  For example, you can run a script that will put in a series of buy/sell orders for XCH_USDCb with a $0.30 spread.  It will expire the offers every so many blocks (configurable with the $config variable).  It also automatically posts the offers to dexie with an auto-claim dbx reward flag so you'll get a stream of dbx for your offers.

 The currently configured trading pairs are:
 XCH_USDC
 XCH_USDCb
 USDC_MilliEth
 USDCb_MilliEthb


 ## Prerequisets
 PSSQLite is required to keep track of trades and current coin prices.
```powershell
Install-Module -Name PSSQLite
```
 You'll also want to use PowerShell 7.4 or greater.  PowerShell 5 will not work.

 Get [PowerShell 7.4](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4)

You'll also want to set the reuse_public_key_for_change setting in the config.yaml for your chia client. 
[Reuse Public Key](https://docs.chia.net/faq/?_highlight=reuse#how-can-i-configure-chia-to-reuse-the-same-receive-address)


# Warnings
Please make sure you understand what these scripts do.  They will create offers and post them automatically to dexie.  If you enter bad information, or if the coingecko API gives you bad data, then it will sell your xch for way less than you want.   There are some attempts at failsafes, but it's not a guarantee.  Please go though these scripts and verify you are comfortable with the risk before running it.

# More Warnings
This script gets around the coin locks of the default wallet by using the Validate_Only feature of the wallet RPC.  This makes it so the chia wallet doesn't actually record the offer in it's list of items.   It also uses the same coin for trades.  What does this mean??  It means that your chia wallet reporting is going to be very wrong.  Your coin history is going to be wrong.  Your Coin Amounts will be correct.  Since it never registers the offer file in the wallet, when a trade is accepted it only records 1/2 of the transaction.  The second half updates in a coin amount, but the entry doesn't get made in the client.

Why is this done?  It makes it much easier to create a spread of offers.  You can assign a max percent of your total XCH/MilliEth/USDC you want to trade with and you don't have to worrie about coin splits to create your whole range of trades.  You just have to Run-Amm and it will handle the rest.  Hopefully future updates to the Chia Wallet will allow this to be done easily.

Only use this if you're ok with doing some manual accounting.   The trade history is captured a sqlite database that is stored on your pc.  This is configurable in the $config settings.



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
