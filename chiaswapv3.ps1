
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
    
    $pb    # Upper Price
    $pa    # Lower Price
    [uint128]$x
    [uint128]$y
    [int64]$l
    [int64]$ly
    [int64]$lx
    [uint128]$xv
    [uint128]$xr
    [uint128]$yv
    [uint128]$yr 
    [uint128]$l2
    [int64]$dy      # Delta Y (Change in amount of XCH)
    [int64]$dx    # Delta X (Change in USD)
    $tick
    [UInt128]$ydecimal = 1000000000000
    [UInt128]$xdecimal = 1000
    [uint128]$pricedecimal 


    UniSwapV3(){

    }

    UniSwapV3($xch_amount,$price,$lower_price,$upper_price){
        $this.pricedecimal = $this.ydecimal/$this.xdecimal
        $this.p = $price
        $this.pb = $upper_price
        $this.pa = $lower_price
        $this.dy = $xch_amount
        $this.setly()
        $this.ly   
        $this.setxv($this.ly)
        $this.xv
        $this.setxr($this.ly)
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

    }

    [uint128]calcdy($upper,$lower,$l){
       Return $l*(([Decimal]::round(([math]::sqrt($upper)),28)) - ([Decimal]::round(([math]::sqrt($lower)),28)))
    }

    [uint128]calcdx($upper,$lower,$l){
        Return (([Decimal]::round($l/([math]::sqrt($lower)),28)) - ([Decimal]::round($l/([math]::sqrt($upper)),28)))
     }

    getXtokens(){

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


        $data =@{

        }
        return $data

    }

}



$uni = [UniSwapV3]::new(30000000000000,14000,12500,15500) 
# (Xr + $Xv) * (0 + $Yv) = L2