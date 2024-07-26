# Create Config file if it doesn't exist.
if(!(Test-Path -Path ./config.ps1)){
    Copy-Item -Path ./Config_Template.ps1 -Destination ./Config.ps1
}

# Test for PSSQLite module
$mod = Get-InstalledModule -Name PSSQLite
if($null -eq $mod){

    # Module not installed
    Write-Host "Please install the module PSSQLite by running the following command"
    Write-Host -ForegroundColor Yellow "Install-Module -Name PSSQLite"

} else {

    # Module is Installed

    Function Boot-AMM{
        . .\Config.ps1
        . .\DatabaseFunctions.ps1
        . .\HelperFunctions.ps1
        . .\OfferFunctions.ps1
        . .\ReportingFunctions.ps1
        . .\TradeingFunctions.ps1
        . .\AmmFunctions.ps1
        
    
    }
    
    . Boot-AMM
    

    # Check database
    if(-Not (Test-Path -Path (Get-DatabaseConfig).database)){
        Write-Host -ForegroundColor Red "No Database Detected"
        Write-Host -ForegroundColor Yellow "Creating Database"

        # Checking if Folder Exists
        $directory = Split-Path $config.database -Parent
        if(-NOT (Test-Path -Path $directory)){
            New-Item -ItemType Directory -Path $directory
        }

        # Creating Tables in database
        Create-XCHTradeLogDatabase
    }

    # This section is needed for the PowerShell Jobs to function correctly
    $function = {
        . .\Config.ps1
        . .\DatabaseFunctions.ps1
        . .\HelperFunctions.ps1
        . .\OfferFunctions.ps1
        . .\ReportingFunctions.ps1
        . .\TradeingFunctions.ps1
        . .\AmmFunctions.ps1
    }

}

