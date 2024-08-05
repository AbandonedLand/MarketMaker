

Function Get-CompletedOffers{
    $Query = "Select * from TRADES where status = 'Completed'"
    return Invoke-SqliteQuery -Query $Query -DataSource (Get-DatabaseConfig).database
}

Function Get-ActiveOffers{
    $query = 'Select * from TRADES where status="Active"'
    return Invoke-SqliteQuery -Query $query -Database (Get-DatabaseConfig).database
}

Function Insert-TradeRecord{
    param(
        $trade_id,
        $dexie_id,
        $status,
        $expired_block,
        $offered_coin,
        $offered_amount,
        $requested_coin,
        $requested_amount
    )


    $Query = "INSERT INTO TRADES (trade_id, dexie_id, status, expired_block, offered_coin, offered_amount, requested_coin, requested_amount) VALUES (@trade_id, @dexie_id, @status, @expired_block, @offered_coin, @offered_amount, @requested_coin, @requested_amount)"
    Invoke-SqliteQuery -Database (Get-DatabaseConfig).database -Query $Query -SqlParameters @{
        trade_id = $trade_id
        dexie_id = $dexie_id
        status = $status
        expired_block = $expired_block
        offered_coin = $offered_coin
        offered_amount = $offered_amount
        requested_coin = $requested_coin
        requested_amount = $requested_amount
    }


}

Function Get-CoinPriceRecord {
    $Query = "SELECT * FROM COINPRICE ORDER BY created_at DESC LIMIT 1"
    Invoke-SqliteQuery -DataSource (Get-DatabaseConfig).database -Query $Query
}

Function Set-CoinPriceRecord(){
    

    $xch_uri = 'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=chia'
    $eth_uri = 'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=ethereum'
    $eth_data = (Invoke-RestMethod -Method Get -Uri $eth_uri)[0]
    $xch_data = (Invoke-RestMethod -Method Get -Uri $xch_uri)[0]
    $dbx_usd = (Get-CATPrice -cat DBX).bid * $xch_data.current_price
    $hoa_usd = (Get-CATPrice -cat HOA).bid * $xch_data.current_price
    $millieth_usd = $eth_data.current_price / 1000
    $xch_usd = $xch_data.current_price
    $Query = "INSERT INTO COINPRICE (xch,millieth,dbx,hoa,created_at) VALUES (@xch,@millieth,@dbx,@hoa,@created_at)"
    $sqlparam = [ordered]@{
        millieth = $millieth_usd
        xch = $xch_usd
        dbx = $dbx_usd
        hoa = $hoa_usd
        created_at = (Get-Date)
    }
    Invoke-SqliteQuery -DataSource (Get-DatabaseConfig).database -Query $Query -SqlParameters $sqlparam

}



Function Set-WalletSnapShot{
    $sqlparam = Get-WalletSnapShot
    $Query = "INSERT INTO WALLET (xch_amount, xch_value, wUSD_amount, wUSD_value, milliETH_amount, milliETH_value, DBX_amount, DBX_value, HOA_amount, HOA_value, total_value, snapshot_time) VALUES (@xch_amount, @xch_value, @wUSD_amount, @wUSD_value, @milliETH_amount, @milliETH_value, @DBX_amount, @DBX_value, @HOA_amount,@HOA_value, @total_value, @snapshot_time)"
    Invoke-SqliteQuery -DataSource (Get-DatabaseConfig).database -Query $Query -SqlParameters $sqlparam
}

Function Add-LiquidityRewardToTrade{
    param(
        $dexie_id,
        $liquidity_coin,
        $liquidity_amount
    )

    $query = -join("Update TRADES set liquidity_coin = ",$liquidity_coin,", liquidity_amount = ",$liquidity_amount," where dexie_id = ",$dexie_id)
    Invoke-sqliteQuery -Query $Query -Database (Get-DatabaseConfig).database

}

Function Create-XCHTradeLogDatabase{

    $Query = "CREATE TABLE TRADES (trade_id VARCHAR(100) PRIMARY KEY, dexie_id VARCHAR(100), status VARCHAR(20), expired_block BIGINT, offered_coin VARCHAR(20), offered_amount DECIMAL(10,3), requested_coin VARCHAR(20), requested_amount DECIMAL(10,3), liquidity_coin VARCHAR(20), liquidity_amount DECIMAL(10,3))"
    Invoke-sqliteQuery -Query $Query -Database (Get-DatabaseConfig).database
    $Query = "CREATE TABLE WALLET (id INTEGER PRIMARY KEY, xch_amount DECIMAL(10,3), xch_value DECIMAL(10,3), wUSD_amount DECIMAL(10,3), wUSD_value DECIMAL(10,3), milliETH_amount DECIMAL(10,3), milliETH_value DECIMAL(10,3), total_value DECIMAL(10,3), DBX_amount DECIMAL(10,3), DBX_value DECIMAL(10,3), HOA_amount DECIMAL(10,3), HOA_value DECIMAL(10,3), snapshot_time DEFAULT CURRENT_TIMESTAMP )"
    Invoke-sqliteQuery -Query $Query -Database (Get-DatabaseConfig).database
    $Query = "CREATE TABLE COINPRICE (id INTEGER PRIMARY KEY, xch DECIMAL(10,3), millieth DECIMAL(10,3), dbx DECIMAL(20,17), hoa DECIMAL(20,17), created_at DEFAULT CURRENT_TIMESTAMP)"
    Invoke-sqliteQuery -Query $Query -Database (Get-DatabaseConfig).database
}

Function Get-DatabaseConfig{
    return $config
}



