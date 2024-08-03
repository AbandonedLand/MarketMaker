# GENERIC FUNCTIONS



# XCH FUNCTIONS
Function Buy-XCH{
    param(
        [CmdletBinding()]
        [Parameter(Position=0,mandatory=$true)]
        [decimal]$amount,   
        [Parameter(Position=1,mandatory=$true)]
        [ValidateSet("Base","Etherium")]
        $chain,
        [Parameter(Position=3,mandatory=$true)]
        [decimal]$price_per_xch
    )

    $price = [System.Math]::round($price_per_xch * $amount,3)

    if($chain -eq 'Base'){
        $scriptblock = [scriptblock]::create("New-Offer -offered_coin wUSDC.b -offered_amount $price -requested_coin XCH -requested_amount $amount")
        start-job -InitializationScript $function -ScriptBlock $scriptblock
    }
    if($chain -eq 'Etherium'){
        $scriptblock = [scriptblock]::create("New-Offer -offered_coin wUSDC -offered_amount $price -requested_coin XCH -requested_amount $amount")
        start-job -InitializationScript $function -ScriptBlock $scriptblock
    }

}
Function Sell-XCH{
    param(
        [CmdletBinding()]
        [Parameter(Position=0,mandatory=$true)]
        [decimal]$amount,   
        [Parameter(Position=1,mandatory=$true)]
        [ValidateSet("Base","Etherium")]
        $chain,
        [Parameter(Position=3,mandatory=$true)]
        [decimal]$price_per_xch
    )
    $price = [System.Math]::round($price_per_xch * $amount,3)
    
    if($chain -eq 'Base'){
        $scriptblock = [scriptblock]::create("New-Offer -offered_coin XCH -offered_amount $amount -requested_coin wUSDC.b -requested_amount $price")
        start-job -InitializationScript $function -ScriptBlock $scriptblock
        
    }
    if($chain -eq 'Etherium'){
        $scriptblock = [scriptblock]::create("New-Offer -offered_coin XCH -offered_amount $amount -requested_coin wUSDC -requested_amount $price")
        start-job -InitializationScript $function -ScriptBlock $scriptblock
    }

}
Function Buy-XCHinBulk{
    param(
        [CmdletBinding()] 
        [Parameter(mandatory=$true)]
        [ValidateSet("Base","Etherium")]
        $chain,
        [Parameter(mandatory=$true)]
        [decimal]$starting_price,
        [Parameter(mandatory=$true)]
        [decimal]$price_change_per_step,
        [Parameter(mandatory=$true)]
        [decimal]$step_size,
        [Parameter(mandatory=$true)]
        [int]$max_percent_of_offered_coin,
        [Parameter(mandatory=$true)]
        $wallets
    )

    
    if($chain -eq 'Base'){
        $max = round(($wallets.wUSDC.Base * ($max_percent_of_offered_coin /100)))
    }
    if($chain -eq 'Etherium'){
        $max = round(($wallets.wUSDC.Etherium * ($max_percent_of_offered_coin /100)))
    }
      
    $ppc = $starting_price
    $amount = $step_size

    while(($ppc*$amount) -le $max){
        if($chain -eq 'Base'){
            Write-Host "Buy $amount xch for $ppc "
            Buy-Xch -amount $amount -chain Base -price_per_xch $ppc
        }

        if($chain -eq 'Etherium'){
            Write-Host "Buy $amount xch for $ppc"
            Buy-Xch -amount $amount -chain Etherium -price_per_xch $ppc
        }

        $amount = $amount + $step_size
        
        # Increase the buy price the larger the amount of xch wanted to get the best DBX rewards.
        $ppc = $ppc + $price_change_per_step
    }
     
}
Function Sell-XCHinBulk{
    param(
        [CmdletBinding()] 
        [Parameter(mandatory=$true)]
        [ValidateSet("Base","Etherium")]
        $chain,
        [Parameter(mandatory=$true)]
        [decimal]$starting_price,
        [Parameter(mandatory=$true)]
        [decimal]$price_change_per_step,
        [Parameter(mandatory=$true)]
        [decimal]$step_size,
        [Parameter(mandatory=$true)]
        [int]$max_percent_of_offered_coin,
        [Parameter(mandatory=$true)]
        $wallets
    )

    
    if($chain -eq 'Base'){
        $max = round(($wallets.XCH * ($max_percent_of_offered_coin /100)))
    }
    if($chain -eq 'Etherium'){
        $max = round(($wallets.XCH * ($max_percent_of_offered_coin /100)))
    }
      
    $ppc = $starting_price
    $amount = $step_size

    while(($amount) -le $max){
        if($chain -eq 'Base'){
            Write-Host "Sell $amount xch for $ppc"
            Sell-XCH -amount $amount -chain Base -price_per_xch $ppc
        }

        if($chain -eq 'Etherium'){
            Write-Host "Sell $amount xch for $ppc"
            Sell-XCH -amount $amount -chain Etherium -price_per_xch $ppc
        }

        # Decrease the sale price per chia the more chia sold to get the best xch price.
        $ppc = $ppc - $price_change_per_step
        $amount = $amount + $step_size
    }
    
}

# USDC FUNCTIONS
Function Trade-USDCBulk{
    $wallets = Get-WalletBalances

    $usdc_max = $wallets.wUSDC.Base
    $usdcb_max = $wallets.wUSDC.Etherium

    $amount = 25

    
    while($amount -le $usdc_max){
        Buy-StableCoins -chain Base -amount $amount
        $amount = $amount + 25
        
    }

    $amount = 25
    while($amount -le $usdcb_max){
        Buy-StableCoins -chain Etherium -amount $amount
        $amount = $amount + 25
        
    }
    
}
Function Buy-StableCoins{
    param(
        [CmdletBinding()]
        [Parameter(Position=0,mandatory=$true)]
        [int]$amount,
        [Parameter(Position=1,mandatory=$true)]
        [ValidateSet("Base","Etherium")]
        $chain
    )
    [decimal]$percent = 0.003

    if($chain -eq 'Base'){
        New-Offer -offered_coin wUSDC -offered_amount ($amount * (1-$percent)) -requested_coin wUSDC.b -requested_amount $amount
    }
    if($chain -eq 'Etherium'){
        New-Offer -offered_coin wUSDC.b -offered_amount ($amount * (1-$percent)) -requested_coin wUSDC -requested_amount $amount
    }
    
}
# MILLIETH FUNCTIONS
Function Sell-MilliETHinBulk{
    param(
        [CmdletBinding()] 
        [Parameter(mandatory=$true)]
        [ValidateSet("Base","Etherium")]
        $chain,
        [Parameter(mandatory=$true)]
        [decimal]$starting_price,
        [Parameter(mandatory=$true)]
        [decimal]$price_change_per_step,
        [Parameter(mandatory=$true)]
        [decimal]$step_size,
        [Parameter(mandatory=$true)]
        [int]$max_percent_of_offered_coin,
        [Parameter(mandatory=$true)]
        $wallets
    )


    if($chain -eq 'Base'){
        $max = round(($wallets.wmilliETH.Base * ($max_percent_of_offered_coin /100)))
    }
    if($chain -eq 'Etherium'){
        $max = round(($wallets.wmilliETH.Etherium * ($max_percent_of_offered_coin /100)))
    }
      
    $ppc = $starting_price
    $amount = $step_size

    while(($amount) -le $max){
        if($chain -eq 'Base'){
            Write-Host "Sell $amount millieth for $ppc of Base"
            Sell-MilliEth -amount $amount -chain Base -price_per_millieth $ppc
        }

        if($chain -eq 'Etherium'){
            Write-Host "Sell $amount millieth for $ppc of Etherium"
            Sell-MilliEth -amount $amount -chain Etherium -price_per_millieth $ppc
        }

        $amount = $amount + $step_size
        $ppc = $ppc - $price_change_per_step
    }
    
}

Function Buy-MilliETHinBulk{
    param(
        [CmdletBinding()] 
        [Parameter(mandatory=$true)]
        [ValidateSet("Base","Etherium")]
        $chain,
        [Parameter(mandatory=$true)]
        [decimal]$starting_price,
        [decimal]$price_change_per_step,
        [Parameter(mandatory=$true)]
        [decimal]$step_size,
        [Parameter(mandatory=$true)]
        [int]$max_percent_of_offered_coin,
        [Parameter(mandatory=$true)]
        $wallets
    )

    
    if($chain -eq 'Base'){
        $max = round(($wallets.wUSDC.Base * ($max_percent_of_offered_coin /100)))
    }
    if($chain -eq 'Etherium'){
        $max = round(($wallets.wUSDC.Etherium * ($max_percent_of_offered_coin /100)))
    }
      
    $ppc = $starting_price
    $amount = $step_size

    while(($amount * $ppc) -le $max){
        if($chain -eq 'Base'){
            Write-Host "Buy $amount millieth for $ppc of Base"
            Buy-MilliEth -amount $amount -chain Base -price_per_millieth $ppc
        }

        if($chain -eq 'Etherium'){
            Write-Host "Buy $amount millieth for $ppc of Etherium"
            Buy-MilliEth -amount $amount -chain Etherium -price_per_millieth $ppc
        }

        $amount = $amount + $step_size
        $ppc = $ppc + $price_change_per_step
    }
    
}
Function Sell-MilliEth{
    param(
        [CmdletBinding()]
        [Parameter(Position=0,mandatory=$true)]
        [decimal]$amount,   
        [Parameter(Position=1,mandatory=$true)]
        [ValidateSet("Base","Etherium")]
        $chain,
        [Parameter(Position=3,mandatory=$true)]
        [decimal]$price_per_millieth
    )

    $price = [System.Math]::round($price_per_millieth * $amount,3)
    
    if($chain -eq 'Base'){
        $scriptblock = [scriptblock]::create("New-Offer -offered_coin 'wmilliETH.b' -offered_amount $amount -requested_coin wUSDC.b -requested_amount $price")
        start-job -InitializationScript $function -ScriptBlock $scriptblock
        
    }
    if($chain -eq 'Etherium'){
        $scriptblock = [scriptblock]::create("New-Offer -offered_coin 'wmilliETH' -offered_amount $amount -requested_coin wUSDC -requested_amount $price")
        start-job -InitializationScript $function -ScriptBlock $scriptblock
    }

}
Function Buy-MilliEth{
    param(
        [CmdletBinding()]
        [Parameter(Position=0,mandatory=$true)]
        [decimal]$amount,   
        [Parameter(Position=1,mandatory=$true)]
        [ValidateSet("Base","Etherium")]
        $chain,
        [Parameter(Position=3,mandatory=$true)]
        [decimal]$price_per_millieth
    )

    $price = [System.Math]::round($price_per_millieth * $amount,3)
    
    if($chain -eq 'Base'){
        $scriptblock = [scriptblock]::create("New-Offer -offered_coin wUSDC.b -offered_amount $price -requested_coin wmilliETH.b -requested_amount $amount")
        
        start-job -InitializationScript $function -ScriptBlock $scriptblock
    }
    if($chain -eq 'Etherium'){
        $scriptblock = [scriptblock]::create("New-Offer -offered_coin wUSDC -offered_amount $price -requested_coin wmilliETH -requested_amount $amount")
        start-job -InitializationScript $function -ScriptBlock $scriptblock
    }

}
#


# Buy up to max
Function Buy-DBX{
    param(
        [Parameter(mandatory=$true)]
        $wallets
    )


    #Figure out how much to buy to buy up to the max.
    $amount = [decimal]$config.dbx_max_exposure - [decimal]$wallets.DBX
 
    # check to see if anything should be purchased with a minimum of 20
    if($amount -gt 0){
        $dbx_per_xch = (Get-CATPrice -cat DBX).buy

        $price = [System.Math]::round($amount / $dbx_per_xch ,3)
        if($dbx_per_xch -ge $config.max_dbx_to_xch_sell_price -AND $dbx_per_xch -lt $config.min_dbx_to_xch_buy_price){
            $scriptblock = [scriptblock]::create("New-Offer -offered_coin XCH -offered_amount $price -requested_coin DBX -requested_amount $amount")
            start-job -InitializationScript $function -ScriptBlock $scriptblock
        }
        
    } else{
        
        $amount = ([decimal]$config.dbx_max_exposure * 2) - [decimal]$wallets.DBX

        if($amount -gt 0){

            #get the tibet quick sale price
            
            $dbx_per_xch = (Get-CATPrice -cat DBX).buy

            $price = [System.Math]::round($amount / $dbx_per_xch ,3)

            if($dbx_per_xch -ge $config.max_dbx_to_xch_sell_price -AND $dbx_per_xch -lt $config.min_dbx_to_xch_buy_price){
                $scriptblock = [scriptblock]::create("New-Offer -offered_coin XCH -offered_amount $price -requested_coin DBX -requested_amount $amount")
                start-job -InitializationScript $function -ScriptBlock $scriptblock
            }
        }
    }

    

    

}

Function Sell-DBX{
    param(
        [Parameter(mandatory=$true)]
        $wallets
    )


    #Figure out how much to sell
    if([decimal]$wallets.DBX -gt 5000){
        $amount = 5000
    } else {
        $amount = [decimal]$wallets.DBX
    }
    

    # check to see if anything should be purchased with a minimum of 20
    if($amount -gt 20){
        $dbx_per_xch = (Get-CATPrice -cat DBX).sell
        $price = [System.Math]::round($amount / $dbx_per_xch ,3)
        if($dbx_per_xch -ge $config.max_dbx_to_xch_sell_price -AND $dbx_per_xch -lt $config.min_dbx_to_xch_buy_price){

            $scriptblock = [scriptblock]::create("New-Offer -offered_coin DBX -offered_amount $amount -requested_coin XCH -requested_amount $price")
            start-job -InitializationScript $function -ScriptBlock $scriptblock
        }
    }

   

}


# Buy up to max
Function Buy-HOA{
    param(
        [Parameter(mandatory=$true)]
        $wallets
    )


    #Figure out how much to buy to buy up to the max.
    $amount = [decimal]$config.hoa_max_exposure - [decimal]$wallets.HOA

    # check to see if anything should be purchased with a minimum of 20
    if($amount -gt 20){
        $hoa_per_xch = (Get-CATPrice -cat HOA).buy

        $price = [System.Math]::round($amount / $hoa_per_xch ,3)
        if($hoa_per_xch -ge $config.max_hoa_to_xch_sell_price -AND $hoa_per_xch -lt $config.min_hoa_to_xch_buy_price){
            $scriptblock = [scriptblock]::create("New-Offer -offered_coin XCH -offered_amount $price -requested_coin HOA -requested_amount $amount")
            start-job -InitializationScript $function -ScriptBlock $scriptblock
        }
        
    } else{
        
        $amount = ([decimal]$config.hoa_max_exposure * 2) - [decimal]$wallets.HOA


        if($amount -gt 0){

            $hoa_per_xch = (Get-CATPrice -cat HOA).buy

            $price = [System.Math]::round($amount / $hoa_per_xch ,3)
            #get the tibet quick sale price
            
            if($hoa_per_xch -ge $config.max_hoa_to_xch_sell_price -AND $dbx_per_xch -lt $config.min_hoa_to_xch_buy_price){
                $scriptblock = [scriptblock]::create("New-Offer -offered_coin XCH -offered_amount $price -requested_coin HOA -requested_amount $amount")
                start-job -InitializationScript $function -ScriptBlock $scriptblock
            }
        }
    }


}

Function Sell-HOA{
    param(
        [Parameter(mandatory=$true)]
        $wallets
    )


    #Figure out how much to sell
    if([decimal]$wallets.HOA -gt $config.hoa_max_exposure){
        $amount = $config.hoa_max_exposure
    } else {
        $amount = [decimal]$wallets.HOA
    }
    

    # check to see if anything should be purchased with a minimum of 20
    if($amount -gt 20){
        $hoa_per_xch = (Get-CATPrice -cat HOA).sell
        $price = [System.Math]::round($amount / $hoa_per_xch ,3)
        if($hoa_per_xch -ge $config.max_hoa_to_xch_sell_price -AND $hoa_per_xch -lt $config.min_hoa_to_xch_buy_price){

            $scriptblock = [scriptblock]::create("New-Offer -offered_coin HOA -offered_amount $amount -requested_coin XCH -requested_amount $price")
            start-job -InitializationScript $function -ScriptBlock $scriptblock
        }
    }


}




















