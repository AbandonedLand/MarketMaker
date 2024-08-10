Function round($number){
    return [System.Math]::round($number,2)
}

Function Get-WalletBalances{
    $list = (chia rpc wallet get_wallets | ConvertFrom-Json).wallets
    $wallets = @{
        wUSDC = @{
            Base = [decimal]0
            Etherium = [decimal]0
        }
        wmilliETH = @{
            Base = [decimal]0
            Etherium = [decimal]0
        }
        XCH = [decimal]0
        
        DBX = [decimal]0

        HOA = [decimal]0
        
        wallet_ids = @{
            wusdcb = ($list | Where-Object {$_.name -eq 'wUSDC.b'}).id
            wusdc = ($list | Where-Object {$_.name -eq 'wUSDC'}).id
            wmillieth = ($list | Where-Object {$_.name -eq 'wmilliETH'}).id
            wmilliethb = ($list | Where-Object {$_.name -eq 'wmilliETH.b'}).id
            dbx = ($list | Where-Object {$_.name -eq 'DBX'}).id
            hoa = ($list | Where-Object {$_.name -eq 'HOA'}).id
            xch = 1
        }
    }
    
    $json = @{
        wallet_id = ($list | Where-Object {$_.name -eq 'wUSDC.b'}).id
    } | ConvertTo-Json
        
    $wallets.wUSDC.Base = (((chia rpc wallet get_wallet_balance $json | ConvertFrom-Json).wallet_balance).max_send_amount / 1000)

    $json = @{
        wallet_id = ($list | Where-Object {$_.name -eq 'wUSDC'}).id
    } | ConvertTo-Json

    $wallets.wUSDC.Etherium = (((chia rpc wallet get_wallet_balance $json | ConvertFrom-Json).wallet_balance).max_send_amount / 1000)

    $json = @{
        wallet_id = ($list | Where-Object {$_.name -eq 'wmilliETH'}).id
    } | ConvertTo-Json

    $wallets.wmilliETH.Etherium = (((chia rpc wallet get_wallet_balance $json | ConvertFrom-Json).wallet_balance).max_send_amount / 1000)

    $json = @{
        wallet_id = ($list | Where-Object {$_.name -eq 'wmilliETH.b'}).id
    } | ConvertTo-Json

    $wallets.wmilliETH.Base = (((chia rpc wallet get_wallet_balance $json | ConvertFrom-Json).wallet_balance).max_send_amount / 1000)
    
    $json = @{
        wallet_id = 1
    } | ConvertTo-Json
    
    $wallets.XCH = (((chia rpc wallet get_wallet_balance $json | ConvertFrom-Json).wallet_balance).max_send_amount / 1000000000000)

    $json = @{
        wallet_id = ($list | Where-Object {$_.name -eq 'DBX'}).id 
    } | ConvertTo-Json

    $wallets.DBX = (((chia rpc wallet get_wallet_balance $json | ConvertFrom-Json).wallet_balance).max_send_amount / 1000)

    $json = @{
        wallet_id = ($list | Where-Object {$_.name -eq 'HOA'}).id 
    } | ConvertTo-Json

    $wallets.HOA = (((chia rpc wallet get_wallet_balance $json | ConvertFrom-Json).wallet_balance).max_send_amount / 1000)
    return $wallets
}

Function Get-CoinPrice(){


    # Get coinprice from database
    $coinPrice = Get-CoinPriceRecord

    # If there are no entries, create the first entry
    if($null -eq $coinPrice){
        Set-CoinPriceRecord
        $coinPrice = Get-CoinPriceRecord
    }
    # If the result is older than 5 minutes, grab a new result
    if(([datetime]($coinPrice.created_at)).AddMinutes(5) -le (Get-Date)){
        Set-CoinPriceRecord
        $coinPrice = Get-CoinPriceRecord
    } 


    $coinPrice
}

Function Send-PushOverMessage{
    param(
        $message
    )
    $uri = "https://api.pushover.net/1/messages.json"
    $parameters = @{
        token = $config.pushover_token
        user = $config.pushover_name
        message = $message
    }
    
    $parameters | Invoke-RestMethod -Uri $uri -Method Post
}

Function Get-WalletSnapShot {
    
    $coin_prices = Get-CoinPrice
    $wallets = Get-WalletBalances
    return [ordered]@{
        xch_amount = ([System.Math]::Round($wallets.xch,3))
        xch_value = ([System.Math]::Round(($wallets.XCH * $coin_prices.xch),2))
        wUSD_amount = ($wallets.wUSDC.Base + $wallets.wUSDC.Etherium)
        wUSD_value = ($wallets.wUSDC.Base + $wallets.wUSDC.Etherium)
        milliETH_amount = ($wallets.wmilliETH.Base + $wallets.wmilliETH.Etherium)
        milliETH_value = ([System.Math]::Round((($wallets.wmilliETH.Base + $wallets.wmilliETH.Etherium)*$coin_prices.millieth),2))
        DBX_amount = ([System.Math]::Round($wallets.DBX,3))
        DBX_value = ([System.Math]::Round(($wallets.DBX * $coin_prices.dbx),2))
        HOA_amount = ([System.Math]::Round($wallets.HOA,3))
        HOA_value = ([System.Math]::Round(($wallets.HOA * $coin_prices.hoa),2))
        total_value = ([System.Math]::Round([System.Math]::Round((($wallets.wmilliETH.Base + $wallets.wmilliETH.Etherium)*$coin_prices.millieth),2)+($wallets.wUSDC.Base + $wallets.wUSDC.Etherium)+([System.Math]::Round(($wallets.XCH * $coin_prices.xch),2)),2)+([System.Math]::Round(($wallets.DBX * $coin_prices.dbx),2))+([System.Math]::Round(($wallets.HOA * $coin_prices.hoa),2)))
        snapshot_time = (Get-Date)
    }

    
}


Function Rename-Cats{
    chia wallet add_token -id 4cb15a8ecc85068fb1f98c09a5e489d1ad61b2af79690ce00f9fc4803c8b597f -n wmilliETH
    chia wallet add_token -id f322a205c034fe28681829fa5a2e483ac421f0952eb1292945c8db06e0a471a6 -n wmilliETH.b
    chia wallet add_token -id bbb51b246fbec1da1305be31dcf17151ccd0b8231a1ec306d7ce9f5b8c742b9e -n wUSDC
    chia wallet add_token -id fa4a180ac326e67ea289b869e3448256f6af05721f7cf934cb9901baa6b7a99d -n wUSDC.b
    chia wallet add_token -id db1a9020d48d9d4ad22631b66ab4b9ebd3637ef7758ad38881348c5d24c38f20 -n DBX
    chia wallet add_token -id e816ee18ce2337c4128449bc539fbbe2ecfdd2098c4e7cab4667e223c3bdc23d -n HOA
}

Function Get-LastOffers {
    $json = [ordered]@{
        start = [int]0
        end = [int]100
        file_contents = $true
    } | ConvertTo-Json
     
    chia rpc wallet get_all_offers $json | ConvertFrom-Json
}

Function Get-OffersReadable{
    $offers = Get-LastOffers
    $readable_offers = @()
    foreach($offer in $offers.trade_records){
        if($offer.summary.offered.count -eq 1 -AND $offer.summary.requested.count -eq 1){
            $requested = ($offer.summary.requested[0] | Get-Member -MemberType NoteProperty | Select-Object Name).Name
            $offered = ($offer.summary.offered[0] | Get-Member -MemberType NoteProperty | Select-Object Name).Name
            $readable_offers += [PSCustomObject]@{
                id = $offer.trade_id
                requested = (Get-CatList).$requested
                requested_amount = $offer.summary.requested[0].$requested
                offered = (Get-CatList).$offered
                offered_amount = $offer.summary.offered[0].$offered
            }
        }
    }
    $readable_offers
}

Function Check-Offers{
    $uri = 'https://api.mojonode.com/get_blockchain_state'
    $height = (Invoke-RestMethod -Uri $uri -Method Post -body (@{'network'='mainnet'} | convertto-json) -ContentType 'application/json').blockchain_state.peak.height


    $Query = "Select * from TRADES where expired_block <= @height and status = 'Active'"
    $expired =  (Invoke-SqliteQuery -Database (Get-DatabaseConfig).database -Query $Query -SqlParameters @{
        height = $height
    }).count

    if($expired -gt 0){
        Check-OfferStatus
    }

    if(Get-ActiveOffers){
        return $true
    } else {
        return $false
    }


}


Function Get-WalletHeight{
    $height = (chia rpc wallet get_height_info | ConvertFrom-Json)
    if($height){
        return $height.height
    } else {
        return (Get-BlockChainHeight).height
    }
}

Function Get-BlockChainHeight{
    $uri = 'https://api.mojonode.com/get_blockchain_state'
    if($Global:height){
        if($Global:height.date.AddMinutes(1) -lt (Get-Date)){
            $Global:height =  @{
                height = (Invoke-RestMethod -Uri $uri -Method Post -body (@{'network'='mainnet'} | convertto-json) -ContentType 'application/json').blockchain_state.peak.height
                date = Get-Date
            }
            $Global:height
        } else {
            $Global:height
        }
    }
    else {
        $Global:height =  @{
            height = (Invoke-RestMethod -Uri $uri -Method Post -body (@{'network'='mainnet'} | convertto-json) -ContentType 'application/json').blockchain_state.peak.height
            date = Get-Date
        }
        $Global:height
    }
    
}



Function Get-CatList{
    return @{
        'bbb51b246fbec1da1305be31dcf17151ccd0b8231a1ec306d7ce9f5b8c742b9e'='wUSDC'
        'fa4a180ac326e67ea289b869e3448256f6af05721f7cf934cb9901baa6b7a99d'='wUSDC.b'
        '634f9f0de1a6c39a2189948b8e61b6852fbf774f73b0e36e143e841c49a0798c'='wUSDT'
        '4cb15a8ecc85068fb1f98c09a5e489d1ad61b2af79690ce00f9fc4803c8b597f'='wmilliETH'
        'f322a205c034fe28681829fa5a2e483ac421f0952eb1292945c8db06e0a471a6'='wmilliETH.b'
        'XCH'='XCH'
    }
}