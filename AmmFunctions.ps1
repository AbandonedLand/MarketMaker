Function Start-AMM {

    $wallets = Get-WalletBalances
    
    Check-OfferStatus

    # get pricing for wallet
    Set-WalletSnapShot

    # Spread is the difference between buy and sell from the current exchange price.
    


    # Percent is the max percent of your supply you'll offer up.
    $active = Get-ActiveOffers

    # Get Price
    $price = Get-CoinPrice

    
    # Failsafe to stop low offers if price is not pulled.  It will only list if the xch price and the millieth price is greater than 0.
    if($price.xch -gt 0 -AND $price.millieth -gt 0){

        [decimal]$xch_buy_price = $price.xch - ([decimal]$config.xch_spread)
        [decimal]$xch_sell_price = $price.xch + ([decimal]$config.xch_spread) + ([decimal]$config.xch_extra_sale_adjustment)
        [decimal]$millieth_buy_price = $price.millieth - ([decimal]$config.millieth_spread)
        [decimal]$millieth_sell_price = $price.millieth + ([decimal]$config.millieth_spread)
    
        # Check if the current Buy Price is less than your max buy price
        if($xch_buy_price -lt ([decimal]$config.max_xch_buy_price)){
            # Check if bot is trading the XCH_USDCB Pair
            if([Boolean]$config.trading_pair_xch_usdcb){
                # Check if there are no active offers
                $check = ($active | Where-Object {$_.offered_coin -eq 'wUSDC.b' -AND $_.requested_coin -eq 'XCH'})

                if($check.count -eq 0){
                    Buy-XCHinBulk -chain Base -starting_price $xch_buy_price -step_size ([decimal]$config.xch_step) -max_percent_of_offered_coin ([decimal]$config.percent) -price_change_per_step ([decimal]$config.price_change_per_step) -wallets $wallets
                }
                
            }
            # Check if bot is trading the XCH_USDC Pair
            if([Boolean]$config.trading_pair_xch_usdc){
                # Check if there are no active offers
                $check = ($active | Where-Object {$_.offered_coin -eq 'wUSDC' -AND $_.requested_coin -eq 'XCH'})
                
                if($check.count -eq 0){
                    Buy-XCHinBulk -chain Etherium -starting_price $xch_buy_price -step_size ([decimal]$config.xch_step) -max_percent_of_offered_coin ([decimal]$config.percent) -price_change_per_step ([decimal]$config.price_change_per_step) -wallets $wallets
                }
            }
        } 
        
    
        # Check if current Sell Price is greater than your minimum sell price
        if($xch_sell_price -gt ([decimal]$config.min_xch_sell_price)){
            # Check if bot is trading the XCH_USDCB Pair
            if([Boolean]$config.trading_pair_xch_usdcb){
                $check = ($active | Where-Object {$_.offered_coin -eq 'XCH' -AND $_.requested_coin -eq 'wUSDC.b'})
                
                if($check.count -eq 0){
                    Sell-XCHinBulk -chain Base -starting_price $xch_sell_price -step_size ([decimal]$config.xch_step) -max_percent_of_offered_coin ([decimal]$config.percent) -price_change_per_step ([decimal]$config.price_change_per_step) -wallets $wallets
                }
            }
            # Check if bot is trading the XCH_USDC Pair
            if([Boolean]$config.trading_pair_xch_usdc){
                $check = ($active | Where-Object {$_.offered_coin -eq 'XCH' -AND $_.requested_coin -eq 'wUSDC'})
                
                if($check.count -eq 0){
                    Sell-XCHinBulk -chain Etherium -starting_price $xch_sell_price -step_size ([decimal]$config.xch_step) -max_percent_of_offered_coin ([decimal]$config.percent) -price_change_per_step ([decimal]$config.price_change_per_step) -wallets $wallets
                }
            }
        } 
    
        # Check if the current millieth buy price is less than your max buy price

        if($millieth_buy_price -lt [decimal]$config.max_millieth_buy_price){
            # Check if bot is trading the MilliEthB USDCB Pair
            if([Boolean]$config.trading_pair_usdcb_milliethb){
                $check = ($active | Where-Object {$_.offered_coin -eq 'wmilliETH.b' -AND $_.requested_coin -eq 'wUSDC.b'})

                if($check.count -eq 0){
                    Buy-MilliETHinBulk -chain Base -starting_price $millieth_buy_price -step_size ([decimal]$config.millieth_step) -max_percent_of_offered_coin ([decimal]$config.percent) -price_change_per_step ([decimal]$config.price_change_per_step) -wallets $wallets
                }
            }
            # Check if bot is trading the MilliEth USDC Pair
            if([Boolean]$config.trading_pair_usdc_millieth){
                $check = ($active | Where-Object {$_.offered_coin -eq 'wmilliETH' -AND $_.requested_coin -eq 'wUSDC'})

                if($check.count -eq 0){
                    Buy-MilliETHinBulk -chain Etherium -starting_price $millieth_buy_price -step_size ([decimal]$config.millieth_step) -max_percent_of_offered_coin ([decimal]$config.percent) -price_change_per_step ([decimal]$config.price_change_per_step) -wallets $wallets
                }
            }

        }

        # Check to see if the current millieth sell price is greater than your minimum sell price
        if($millieth_sell_price -gt [decimal]$config.min_millieth_sell_price){
            # Check if bot is trading the MilliEthB USDCB Pair
            if([Boolean]$config.trading_pair_usdcb_milliethb){
                $check = ($active | Where-Object {$_.offered_coin -eq 'wUSDC.b' -AND $_.requested_coin -eq 'wmilliETH.b'})

                if($check.count -eq 0){
                    Sell-MilliETHinBulk -chain Base -starting_price $millieth_sell_price -step_size ([decimal]$config.millieth_step) -max_percent_of_offered_coin ([decimal]$config.percent) -price_change_per_step ([decimal]$config.price_change_per_step ) -wallets $wallets  
                }
            }
            # Check if bot is trading the MilliEth USDC Pair
            if([Boolean]$config.trading_pair_usdc_millieth){
                $check = ($active | Where-Object {$_.offered_coin -eq 'wUSDC' -AND $_.requested_coin -eq 'wmilliETH'})

                if($check.count -eq 0){
                    Sell-MilliETHinBulk -chain Etherium -starting_price $millieth_sell_price -step_size ([decimal]$config.millieth_step) -max_percent_of_offered_coin ([decimal]$config.percent) -price_change_per_step ([decimal]$config.price_change_per_step ) -wallets $wallets
                }
            }

        }
        

        $check = ($active | Where-Object {$_.offered_coin -eq 'XCH' -AND $_.requested_coin -eq 'DBX'})

        if($check.count -eq 0){
            Buy-DBX -wallets $wallets
        }

        $check = ($active | Where-Object {$_.offered_coin -eq 'XCH' -AND $_.requested_coin -eq 'HOA'})

        if($check.count -eq 0){
            Buy-HOA -wallets $wallets
        }

        $check = ($active | Where-Object {$_.offered_coin -eq 'DBX' -AND $_.requested_coin -eq 'XCH'})
        if($check.count -eq 0){
            Sell-DBX -wallets $wallets
        }

        $check = ($active | Where-Object {$_.offered_coin -eq 'HOA' -AND $_.requested_coin -eq 'XCH'})
        if($check.count -eq 0){
            Sell-HOA -wallets $wallets
        }

        Sell-DACs
    }

    
}

Function Run-Amm{
    
    while($true){
        
        <#if(Check-Offers){
            Write-Host "Sleeping"
            Start-Sleep 60
        } else {
            Write-Host "Creating Offers"
            Get-Job | Remove-Job
            Start-AMM 
        }#>
        Write-Host "Attempting to create offers"
        Start-AMM
        Write-Host "Sleeping for 1 min"
        Start-Sleep 60
        Write-Host "Clearning Jobs"
        Get-Job | Remove-Job
        
    }
}