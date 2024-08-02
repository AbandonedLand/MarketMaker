$tibet_pools = @{
    dbx = 'c0952d9c3761302a5545f4c04615a855396b1570be5c61bfd073392466d2a973'
    hoa = 'ad79860e5020dcdac84336a5805537cbc05f954c44caf105336226351d2902c0'
    sbx = '1a6d4f404766f984d014a3a7cab15021e258025ff50481c73ea7c48927bd28af'
}

Function Sell-Token {
    param(
        [string]$cat,
        [UInt64]$amount
    )
    [string]$cat = $cat.tolower()
    $amount = $amount * 1000
    $uri = -join('https://api.v2.tibetswap.io/quote/',($tibet_pools.$cat),"?amount_in=",$amount,"&xch_is_input=false&estimate_fee=false")
    
    $responce = Invoke-RestMethod -Uri $uri
    $responce.amount_out = $responce.amount_out / 1000000000000
    $responce
}