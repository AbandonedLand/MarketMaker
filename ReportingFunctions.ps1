Function New-TradeReport {
    $result = Get-CompletedOffers | Where-Object {$_.requested_coin -eq 'wUSDC.b' -or $_.offered_coin -eq 'wUSDC.b' -or $_.requested_coin -eq 'wUSDC' -or $_.offered_coin -eq 'wUSDC'}

    $sold_amount = (($result | Where-Object {$_.offered_coin -eq 'XCH'}).offered_amount | Measure-Object -Sum).Sum
    $sold_value = (($result | Where-Object {$_.offered_coin -eq 'XCH'}).requested_amount | Measure-Object -Sum).Sum
    $bought_amount = (($result | Where-Object {$_.requested_coin -eq 'XCH'}).requested_amount | Measure-Object -Sum).Sum
    $bought_value = (($result | Where-Object {$_.requested_coin -eq 'XCH'}).offered_amount | Measure-Object -Sum).Sum

    $stats= [PSCustomObject][ordered]@{
        sold = [PSCustomObject][ordered]@{
            amount = $sold_amount
            value = [System.Math]::Round($sold_value)
            avg = [System.Math]::Round($sold_value/$sold_amount,2)
        }
        bought = [PSCustomObject][ordered]@{
            amount = $bought_amount
            value = [System.Math]::Round($bought_value)
            avg = [System.Math]::Round($bought_value/$bought_amount)
        }
    }

    $min_calc_value = ([System.Math]::Min($stats.sold.amount,$stats.bought.amount))
    
    $report = [PSCustomObject][ordered]@{
        profit = [PSCustomObject][ordered]@{
            total = (($min_calc_value * $stats.sold.avg) - ($min_calc_value * $stats.bought.avg))
            per_xch = ((($min_calc_value * $stats.sold.avg) - ($min_calc_value * $stats.bought.avg))/$min_calc_value)
        }

    }

    $stats | Add-Member -MemberType NoteProperty -Name profit -Value $report.profit

    return $stats
}

Function Get-DexieData($requested,$offered){
    $base = 'https://api.dexie.space/v1/offers/'
    $uri = -join($base,'?status=0&offered=',$offered,'&requested=',$requested,'&compact=true&page_size=10')
    $data = Invoke-RestMethod -Method Get -Uri $uri
    return $data.offers
}

Function Get-DexieMarket(){

        
    [ordered]@{
        # USD Markets
        wusdc_wusdcb = Get-DexieData -requested wUSDC -offered "wUSDC.b"
        wusdc_wusdt = Get-DexieData -requested wUSDC -offered wUSDT

        wusdcb_wusdc = Get-DexieData -requested "wUSDC.b" -offered wUSDC
        wusdcb_wusdt = Get-DexieData -requested "wUSDC.b" -offered wUSDT

        wusdt_wusdc = Get-DexieData -requested wUSDT -offered wUSDC
        wusdt_wusdcb = Get-DexieData -requested "wUSDT" -offered "wUSDC.b"
        
        # USD _ XCH Markets
        wusdc_xch = Get-DexieData -requested wUSDC -offered xch
        wusdcb_xch = Get-DexieData -requested "wUSDC.b" -offered xch
        wusdt_xch = Get-DexieData -requested wUSDT -offered xch

        xch_wusdc = Get-DexieData -requested xch -offered wUSDC
        xch_wusdcb = Get-DexieData -requested xch -offered "wUSDC.b"
        xch_wusdt = Get-DexieData -requested xch -offered wUSDT

        # XCH _ ETH

        xch_wmillieth = Get-DexieData -requested xch -offered wmillieth
        xch_wmilliethb = Get-DexieData -requested xch -offered wmillieth.b

        wmillieth_xch = Get-DexieData -requested wmillieth -offered xch
        wmilliethb_xch = Get-DexieData -requested wmillieth.b -offered xch

    }

}


Function Convert-CodeToUSD($code,$amount){
    [decimal]$code_usd_value = 0
    $prices = Get-CoinPrice
    if($code -eq 'XCH'){
        $code_usd_value = $prices.xch * $amount
    }
    if($code -eq 'wUSDC' -OR $code -eq 'wUSDC.b' -OR $code -eq 'wUSDT'){
        $code_usd_value = 1 * $amount
    }
    if($code -eq 'wmilliETH' -OR $code -eq 'wmilliETH.b'){
        $code_usd_value = $prices.millieth * $amount
    }

    return $code_usd_value
}
<#
    Takes the input from dexieMarket and then creates a custom object for easy reading.
#>
Function Convert-MarketDataToTable($marketData){
    
    return [PSCustomObject][ordered]@{
        Trade_id =  $marketData.id
        Requested_Code = $marketData.requested.code
        Requested_Amout = $marketData.requested.amount
        Requested_USD = (Convert-CodeToUSD -code $marketData.requested.code -amount $marketData.requested.amount)
        Offered_Code =  $marketData.offered.code
        Offered_Amount = $marketData.offered.amount
        Offered_USD = (Convert-CodeToUSD -code $marketData.offered.code -amount $marketData.offered.amount)
        Trade_Value = ((Convert-CodeToUSD -code $marketData.offered.code -amount $marketData.offered.amount) - (Convert-CodeToUSD -code $marketData.requested.code -amount $marketData.requested.amount))
    }
}

Function Check-OfferStatus {
    $trades = Get-ActiveOffers
    $updates = @()
    foreach($trade in $trades){
        $uri = -join('https://api.dexie.space/v1/offers/',$trade.dexie_id)
        $dexie = Invoke-RestMethod -Uri $uri

        if($dexie.offer.status -eq 4){
            
            # Send Message over Pushover if configured
            if($config.use_pushover){
                $message = -join('Offer Taken: https://dexie.space/offers/',$trade.dexie_id)
                Send-PushOverMessage -message $message
            }

            $query = "Update TRADES SET status='Completed' WHERE dexie_id=@dexie"
            Invoke-SqliteQuery -Query $query -Database (Get-DatabaseConfig).database -SqlParameters @{dexie=$trade.dexie_id}
            $updates += $dexie.trade_id
        }
        if($dexie.offer.status -eq 3 -or $dexie.offer.status -eq 6 -OR $dexie.offer.status -eq 2){
            $query = "DELETE FROM TRADES WHERE dexie_id=@dexie"
            Invoke-SqliteQuery -Query $query -Database (Get-DatabaseConfig).database -SqlParameters @{dexie=$trade.dexie_id}
            
        }
        
    }
    if($updates.count -gt 0){
        Set-WalletSnapShot
    }
    
    
}



Function Show-TradeDisplay {
    $dexieMarket = Get-dexieMarket
    $table = @()
    foreach($key in $dexieMarket.Keys){
        foreach($trade in $dexieMarket.$key){
            $table += Convert-MarketDataToTable($trade)
        }
    }

    return $table | Sort-Object {$_.Trade_value} -Descending  | Select-Object -First 10 | Format-Table

}


Function Get-DexiePairData{
    param(
        # formated as CAT_XCH
        $ticker_id
    )
    # Dexie ticker data uri
    $uri = -join("https://api.dexie.space/v2/prices/tickers?ticker_id=",$ticker_id)
    $data = Invoke-RestMethod -Method Get -Uri $uri


    $data.tickers[0]

}

Function Get-DBXPrice{
    $price = @{
        bid = 0
        buy = 0
        ask = 0
        sell = 0
        
    }

    $data = Get-DexiePairData -ticker_id DBX_XCH
    
    $bid = [Math]::round((1/$data.bid),3)
    $ask = [Math]::round((1/$data.ask),3)
    $mid = [Math]::round((1/$data.current_avg_price),3)

    $delta = [Math]::round(($bid - $ask) / 3)

    $price.sell = [decimal]($mid - $delta)
    $price.buy = [decimal]($mid + $delta)
    $price.bid = [decimal]$data.bid
    $price.ask = [decimal]$data.ask

    $price
}