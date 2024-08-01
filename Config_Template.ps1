$config = @{
    # Database Location and Filename
    database = 'c:\chiaDB\trades.SQLite'

    xch_address = 'Your XCH Address'

    # Pushover notifications settings
    use_pushover = $false
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
    xch_extra_sale_adjustment = 0

    # Same as xch_spread, but for millieth offers.
    millieth_spread = 0.05

    # This will determine the minimum amount of XCH to buy/sell at a time.  It is also the amount of xch to skip for the next offer.
    # Example:  If the xch_step is 1 and you have a total of 100 XCH and a percent of 50,  then the AMM will create 50 offers spaced 1xch apart. 
    # You'd get a 1XCH sell offer for 20.20 usd, and a 2XCH sell offer for 40.40 usd, a 3XCH sell offer for 60.60 usd, etc.
    xch_step = 1

    # Same as xch_step but for millieth
    millieth_step = 5

    # This is used to help dexie register your max offer if your wallet uses the same coins for an offer.
    price_change_per_step = 0.001

    # This is the minimum in USDC you'll want to sell xch for.  This is a fail safe to stop trading below this number.
    min_xch_sell_price = 15

    # This is the minimum in USDC you'll want to sell millieth for.  This is a fail safe to stop trading below this number.
    min_millieth_sell_price = 3

    # This is the maximum in USDC you'll want to buy XCH for.  This is a fail safe to stop trading above this number.
    max_xch_buy_price = 30

    # This is the maximum in USDC you'll want to sell Millieth for.  This is a fail safe to stop trading above this number.
    max_millieth_buy_price = 3.60

    # Max_blocks your offer is good for. There's about 3 blocks per minute in chia.
    max_blocks = 50


    # Max amount of DBX to hold.
    dbx_max_exposure = 5000
    min_dbx_to_xch_buy_price = 1000
    max_dbx_to_xch_sell_price = 700




}