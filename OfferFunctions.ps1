Function New-Offer{
    param(
        [CmdletBinding()]
        [Parameter(mandatory=$true)]
        [ValidateSet("XCH","wUSDC","wUSDC.b","wUSDT","wmilliETH","wmilliETH.b","DBX","HOA")]
        [string]$offered_coin,
        [Parameter(mandatory=$true)]
        [decimal]$offered_amount,
        [Parameter(mandatory=$true)]
        [ValidateSet("XCH","wUSDC","wUSDC.b","wUSDT","wmilliETH","wmilliETH.b","DBX","HOA")]
        [string]$requested_coin,
        [Parameter(mandatory=$true)]
        [decimal]$requested_amount
    )

    $offer = [ChiaOffer]::new()
    if($offered_coin -eq "XCH"){
        $offer.offerxch($offered_amount)
    } else {
        $offer.offered($offered_coin,$offered_amount)
    }
    if($requested_coin -eq "XCH"){
        $offer.requestxch($requested_amount)
    } else {
        $offer.requested($requested_coin,$requested_amount)
    }
    #$offer.addTimeInMinutes(30)
    if($this.offered_coin -eq 'HOA' -or $this.requested_coin -eq 'HOA' -or $this.requested_coin -eq 'DBX' -or $this.offered_coin -eq 'DBX'){
        #increase the time between hoa and dbx offers
        $offer.setMaxHeight((Get-WalletHeight) + 200 )    
    } else {
        $offer.setMaxHeight(((Get-WalletHeight) + ([int]$config.max_blocks)))
    }
    
    $offer.validateonly()
    $offer.createoffer()
    start-sleep 1
    $offer.postToDexie()
    $trade_id = ($offer.offertext | ConvertFrom-Json).trade_record.trade_id
    $dexie_id = ($offer.dexie_response.Content | ConvertFrom-Json).id
    if(-Not $dexie_id){
        Start-Sleep 1
        $offer.postToDexie()
        $dexie_id = ($offer.dexie_response.Content | ConvertFrom-Json).id
    }
    if($dexie_id -AND $trade_id){
        Insert-TradeRecord -trade_id $trade_id -dexie_id $dexie_id -status Active -requested_coin $requested_coin -requested_amount $requested_amount -offered_coin $offered_coin -offered_amount $offered_amount -expired_block $offer.max_height
    }

    # Cancel-Offer -trade_id $trade_id
    # start-sleep 1
}

Function Create-CoinArray{
    $data = Get-WalletIDs
    $coins = @{}
    foreach($item in $data){
        $coins.($item.name) =@{}
        $coins.($item.name).id = $item.id
    }
    return $coins
} 
Function Get-WalletIDs{
    $data = (chia rpc wallet get_wallets | convertfrom-json).wallets 
    return $data
}

Function Send-Cat{
    param(
        $wallet_id,
        $amount
    )

    $json = @{
        wallet_id = $wallet_id
        fee = 0
        amount = [int64]($amount*1000)
        inner_address = ($config.xch_address)
    } | ConvertTo-Json

    chia rpc wallet cat_spend $json | ConvertFrom-Json
}

Function Take-DexieOffer{
    param(
        [CmdletBinding()]
        [Parameter(Position=0,mandatory=$true)]
        [string]$id
    )

    $uri = -join(' https://api.dexie.space/v1/offers/',$id)
    $dexie_offer = Invoke-RestMethod -Method Get -Uri $uri
    
    if($dexie_offer.success){
        $json = @{
            offer = $dexie_offer.offer.offer
            fee = 0
        } | ConvertTo-Json


        $taken = chia rpc wallet take_offer $json | ConvertFrom-Json
        Insert-TradeRecord -trade_id $taken.trade_record.trade_id -dexie_id $id -status Completed -offered_coin $dexie_offer.offer.requested.code -offered_amount $dexie_offer.offer.requested.amount -requested_amount $dexie_offer.offer.offered.amount -requested_coin $dexie_offer.offer.offered.code
        
    }

}

Function Reset-Offers  {
    
    $wallets = Get-WalletBalances

    $json = @{
            wallet_id = 1
            fee = 0
            amount = ([int64]([decimal]$wallets.XCH * 1000000000000))
            address = ($config.xch_address)
        } | ConvertTo-Json
    chia rpc wallet send_transaction $json | ConvertFrom-Json
            
    Send-Cat -amount $wallets.wUSDC.Etherium -wallet_id $wallets.wallet_ids.wusdc
    
    
    Send-Cat -amount $wallets.wUSDC.Base -wallet_id $wallets.wallet_ids.wusdcb
    

    Send-Cat -amount $wallets.wmilliETH.Etherium -wallet_id $wallets.wallet_ids.wmillieth
    

    Send-Cat -amount $wallets.wmilliETH.Base -wallet_id $wallets.wallet_ids.wmilliethb

}

Function Cancel-Offer {
    param(
        $trade_id
    )
    $json = @{
        secure = $false
        trade_id = $trade_id
        fee = 0
    } | ConvertTo-Json
    chia rpc wallet cancel_offer $json
}

Class ChiaOffer{
    [hashtable]$offer
    $coins
    $fee
    $offertext
    $json
    $dexie_response
    $dexie_url 
    $abandoned_land_response
    $requested_nft_data
    $nft_info
    $max_height
    $max_time
    $validate_only

    ChiaOffer(){
        $this.max_height = 0
        $this.max_time = 0
        $this.coins = Create-CoinArray
        $this.fee = 0
        $this.offer = @{}
        $this.validate_only = $false
        $this.dexie_url = "https://dexie.space/v1/offers"
    }

    setTestNet(){
        $this.dexie_url = "https://api-testnet.dexie.space/v1/offers"
    }

    offerednft($nft_id){
        $data = $this.RPCNFTInfo($nft_id)
        $this.offer.($this.nft_info.launcher_id.substring(2))=-1
    }

    offerednftmg($nft_id){
    
        $uri = -join('https://api.mintgarden.io/nfts/',$nft_id)
        $data = Invoke-RestMethod -Method Get -Uri $uri
        $this.offer.($data.id)=-1
    }

    requestednft($nft_id){
        $this.RPCNFTInfo($nft_id)
        $this.offer.($this.nft_info.launcher_id.substring(2))=1
        $this.BuildDriverDict($this.nft_info)
    }

    requested($coin, $amount){
        $this.offer.([string]$this.coins.$coin.id)=($amount*1000)
    }

    addBlocks($num){
        $this.max_height = (((chia rpc full_node get_blockchain_state) | convertfrom-json).blockchain_state.peak.height) + $num
    }

    setMaxHeight($num){
        $this.max_height = $num
    }
    

    addTimeInMinutes($min){
        $DateTime = (Get-Date).ToUniversalTime()
        $DateTime = $DateTime.AddMinutes($min)
        $this.max_time = [System.Math]::Truncate((Get-Date -Date $DateTime -UFormat %s))
    }

    requestxch($Amount){
        $coin = 'Chia Wallet'
        $this.offer.([string]$this.coins.$coin.id)=([int64]($amount*1000000000000))
        
    }
 

    offerxch($Amount){
        $coin = 'Chia Wallet'
        $this.offer.([string]$this.coins.$coin.id)=([int64]($amount*-1000000000000))
        
    }

    offered($coin, $amount){
        $this.offer.([string]$this.coins.$coin.id)=([int64]($amount*-1000))
    }

    validateonly(){
        $this.validate_only = $true
    }
    
    makejson(){
        if($this.max_time -ne 0){
            $this.json = (
                [ordered]@{
                    "offer"=($this.offer)
                    "fee"=$this.fee
                    "validate_only"=$this.validate_only
                    "reuse_puzhash"=$true
                    "driver_dict"=$this.requested_nft_data
                    "max_time"=$this.max_time
                } | convertto-json -Depth 11)        
        } elseif($this.max_height -ne 0){
            $this.json = (
                [ordered]@{
                    "offer"=($this.offer)
                    "fee"=$this.fee
                    "validate_only"=$this.validate_only
                    "reuse_puzhash"=$true
                    "driver_dict"=$this.requested_nft_data
                    "max_height"=$this.max_height
                } | convertto-json -Depth 11)        
        } else {
            $this.json = (
                [ordered]@{
                    "offer"=($this.offer)
                    "fee"=$this.fee
                    "validate_only"=$this.validate_only
                    "reuse_puzhash"=$true
                    "driver_dict"=$this.requested_nft_data
                } | convertto-json -Depth 11)     
        } 
    } 
    


    createoffer(){
        $this.makejson()
        $this.offertext = chia rpc wallet create_offer_for_ids $this.json
    }

    createofferwithoutjson(){
        $this.offertext = chia rpc wallet create_offer_for_ids $this.json
    }
    
    postToDexie(){
        $data = $this.offertext | convertfrom-json
        $body = @{
            "offer" = $data.offer
            "claim_rewards" = $true
        }
        $contentType = 'application/json' 
        $json_offer = $body | convertto-json
        $this.dexie_response = Invoke-WebRequest -Method POST -body $json_offer -Uri $this.dexie_url -ContentType $contentType
    }
    

    postToDiscord($content){
        $payload = [PSCustomObject]@{
            content = $content
        }
    
    }

    RPCNFTInfo($nft_id){
        $this.nft_info = (chia rpc wallet nft_get_info ([ordered]@{coin_id=$nft_id} | ConvertTo-Json) | Convertfrom-json).nft_info
    }

    BuildDriverDict($data){
    
        $this.requested_nft_data = [ordered]@{($data.launcher_id.substring(2))=[ordered]@{
                    type='singleton';
                    launcher_id=$data.launcher_id;
                    launcher_ph=$data.launcher_puzhash;
                    also=[ordered]@{
                        type='metadata';
                        metadata=$data.chain_info;
                        updater_hash=$data.updater_puzhash;
                        also=[ordered]@{
                            type='ownership';
                            owner=$data.owner_did;
                            transfer_program=[ordered]@{
                                type='royalty transfer program';
                                launcher_id=$data.launcher_id;
                                royalty_address=$data.royalty_puzzle_hash;
                                royalty_percentage=[string]$data.royalty_percentage
                            }
                        }
                    }
                }
            }
        
    }

}