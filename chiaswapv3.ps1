
Function sqrt($num){
    $sq = ([Decimal]::round([Math]::sqrt($num),28))
    return $sq
    
}

Function Get-Xv($L,$Pb){
    Return ($l / ([Math]::sqrt($Pb)))
}

Function Get-LFromDx($Pa,$Pb,$x){
    $xvyv = ((1 / (sqrt($Pa))) - (1/(sqrt($Pb))))
    $data = ($x / $xvyv)
    Return $data
}

Function Get-LFromDy($Pa,$Pb,$y){
    $xvyv = (([math]::sqrt($Pb)) - ([math]::sqrt($Pa)))
    $data = ($y / $xvyv)
    Return $data
}


Function Get-LFromDeltaY($price,$lower_price,$upper_price,$xch_amount){
    $p = $price
    [int64]$y = ($xch_amount*1000000000000)
    $Pb = $upper_price
    $Pa = $lower_price
    [int64]$l = Get-LFromDy -Pa $Pa -Pb $Pb -y $y
    [uint128]$Xv = ($l / (sqrt($Pb)))
    [uint128]$Xr = ($l/(sqrt($Pa)))-($l/(sqrt($Pb)))
    [uint128]$Yv = $l*(sqrt($Pa))
    [uint128]$Yr =  ($l*(sqrt($Pb)))-($l*(sqrt($Pa))) 
    

    [uint128]$l2 = ($xr+$xv)*($yv)

    @{
        l = $l
        Xv = $Xv
        Xr = $Xr
        Yv = $Yv
        Yr = $Yr
        l2 = $l2
    }

}

Function Get-LFromDeltaX($price,$lower_price,$upper_price,$xch_amount){
    $p = $price
    [int64]$x = ($xch_amount*1000000000000)
    $Pb = $upper_price
    $Pa = $lower_price
    [int64]$l = Get-LFromDx -Pa $Pa -Pb $Pb -x $x
    [uint128]$Xv = ($l / (sqrt($Pb)))
    [uint128]$Xr = ($l/(sqrt($Pa)))-($l/(sqrt($Pb)))
    [uint128]$Yv = $l*(sqrt($Pa))
    [uint128]$Yr =  ($l*(sqrt($Pb)))-($l*(sqrt($Pa))) 
    # (Xr + $Xv) * (0 + $Yv) = L2

    [uint128]$l2 = ($xr+$xv)*($yv)

    @{
        l = $l
        Xv = $Xv
        Xr = $Xr
        Yv = $Yv
        Yr = $Yr
        l2 = $l2
    }
}





Class UniSwapV3 {
    [uint128]$p     # Current Price in usd
    [uint128]$stepy # minimum liquidity between between ticks (selling Y amount of XCH per price change)
    $pb    # Lower Price
    $pa    # Upper Price
    [uint128]$x
    [uint128]$y
    [int]$l
    [int64]$ly
    [int64]$lx
    [uint128]$xv
    [uint128]$xr
    [uint128]$yv
    [uint128]$yr 
    [int128]$l2
    [int64]$dy      # Delta Y (Change in amount of USD)
    [int64]$dx    # Delta X (Change in XCH)
    $tick
    [UInt128]$ydecimal = 1000000000000
    [UInt128]$xdecimal = 1000
    [uint128]$pricedecimal 
    [hashtable]$table


    UniSwapV3(){

    }

    UniSwapV3($xch_amount,$price,$lower_price,$upper_price){
        $this.pricedecimal = $this.ydecimal/$this.xdecimal
        $this.p = $price
        $this.pb = $upper_price
        $this.pa = $lower_price
        $this.dy = $xch_amount
        $this.setlx()
        $this.ly   
        $this.setxv($this.ly)
        $this.xv
        #$this.setxr($this.ly)
        $this.xr = 0
        $this.xr
        $this.setyv($this.ly)
        $this.yv
        $this.setyr($this.ly)
        $this.yr
        


    }

    [decimal]sqrt($num){
        return ([Decimal]::round(([math]::sqrt($num)),28))
    }
    

   

    setly(){
        $yxx = ($this.sqrt($this.pb)) - ($this.sqrt($this.pa))
        $this.ly = ($this.dy / $yxx)
        $this.l2 = $this.l * $this.l
    }

    setlx(){
        $xxx = (1/$this.sqrt($this.pa) - (1/$this.sqrt($this.pb)))
        $this.ly = $this.dy / $xxx
        $this.l2 = $this.ly * $this.ly
    }

    [uint128]calcdy($upper,$lower,$l){
       Return $l*(([Decimal]::round(([math]::sqrt($upper)),28)) - ([Decimal]::round(([math]::sqrt($lower)),28)))
    }

    [uint128]calcdx($upper,$lower,$l){
        Return (([Decimal]::round($l/([math]::sqrt($lower)),28)) - ([Decimal]::round($l/([math]::sqrt($upper)),28)))
     }

    [hashtable]pricemap(){

        $localy = 0

        while($localy -lt $this.yr){

            $localy += $this.stepy
        }

        $pricemap = @{}

        return $pricemap
    }

    [int32]getPriceAtYr($yreal){
        $k = $this.ly*$this.ly
        $price = $k
        [int32]$xl = ($this.yv + $yreal)/($this.xv+$this.xr)

        $k / $xl

        return $price
    }


    setxv($l){
       $this.xv = ($l / ([Decimal]::round( ([math]::sqrt($this.pb)) ,28) ) ) 
    }

    setxr($l){
        $this.xr = ($l / ( [Decimal]::round( ([math]::sqrt($this.pa)),28)) - ( $l/([Decimal]::round(([math]::sqrt($this.pb)),28))))
    }

    setyr($l){
        $this.yr = ($l * ( [Decimal]::round( ([math]::sqrt($this.pb)),28)) - ( $l * ( [Decimal]::round( ([math]::sqrt($this.pa)),28) )))
    }

    setyv($l){
        $this.yv = $l * ([Decimal]::round( ([math]::sqrt($this.pa)),28))
    }

    adjustyr($amount){

    }



    [int32]pricemin(){
        return ($this.yv)/($this.xr + $this.xv)
    }

    [int32]pricemax(){
        return ($this.yv + $this.yr)/($this.xv)
    }

    [hashtable]sellxch($amount){

        
        $this.xr = $this.xr+$amount
        $y2 = $this.l2 / ($this.xv+$this.xr)
        $tp=$y2/($this.xr+$this.xv)
        $usd = (($tp*$amount)/$this.ydecimal)
        $usd_fee = [int64]([math]::round(([decimal]$usd*0.01)))
        $xch_fee = [int64]([math]::round([decimal]$amount * 0.01))
        if($amount -gt 0){
            $offer_coin = "xch"
            $offer_amount = $amount
            $requested_coin = "usd"
            $requested_amount =  $usd + $usd_fee
        } else {
            $offer_coin = "usd"
            $offer_amount = $usd*-1
            $requested_coin = "xch"
            $requested_amount =  ($amount + $xch_fee)*-1
        }


        $data =@{
            price = $tp
            xch = $amount
            total_xch = $this.xr
            usd = $usd
            usd_fee = $usd_fee
            xch_fee = $xch_fee
            offered_coin = $offer_coin
            offered_amount = $offer_amount
            requested_coin = $requested_coin
            requested_amount = $requested_amount
        }

        return $data

    }

    [array]buildtable($step){
        $array = @()
        $thisxr = $this.dy
        $txr = 0

        while($txr -lt $thisxr){

            $data = $this.sellxch($step)
            $txr = $data.total_xch
            $array += $data
        }

        return $array
    }


}



$uni = [UniSwapV3]::new(30000000000000,14000,12500,15500) 


# (Xr + $Xv) * (0 + $Yv) = L2

$uni.l2 = $uni.ly*$uni.ly
$x = $uni.xv
$y1 = $uni.yv+$uni.yr
$y1/$x
# Sell .25 XCH
$xr = 250000000000
$x = $uni.xv + $xr
$y2 = $uni.l2 / $x
$y2/$x

