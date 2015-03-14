<# 
 .Synopsis
  This module can send service status and information message to Dashing dashboard.

 .DeScription
  This module can send service status and information message to Dashing dashboard.

  I use this to control scripts execution from Dashing.
  (http://dashing.io/ or https://github.com/Shopify/dashing )

  Also I make the module "public" (all PS scripts can import it).
  For this:
  1. clone the module to folder C:\Program Files\Common Files\Modules\ 
  (file DashingLogger.psm1 is located on C:\Program Files\Common Files\Modules\DashingLogger\DashingLogger.psm1 )
  
  2. run the command:
  [Environment]::SetEnvironmentVariable("PSModulePath", $CurrentValue + ";C:\Program Files\Common Files\Modules\", "Machine")

 .Version
  0.1

 .Example
   # Import module
   Import-Module DashingLogger
   # Init (in asynchron mode)
   Set-Dashing -Service SomeSerive -Url SomeUrl -Token SomeToken -Asynchron
   # Send status
   Write-Dashing -Status ok -Message "All is ok"
   # or
   Write-DashingOk "All is ok"

#>

[String]$Script:Service
[String]$Script:Url
[String]$Script:Token

[Bool]$Script:Uninitialized = $true
[Bool]$Script:Asynchron

Function Set-Dashing {
    Param (
        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]
        [String]$Service,

        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]
        [String]$Url,

        [Parameter()]
        [String]$Token = "",

        [Parameter()]
        [Switch]$Asynchron 
    )

    $Script:Service = $Service
    $Script:Url = $Url
    $Script:Token = $Token
    $Script:Asynchron = $Asynchron

    $Script:Uninitialized = $false
}

Function Error-NeedSet-Dashing{
    Write-Error "You need init service with command Set-Dashing -Service ServiceName -Url SomeUrl -Token SomeToken"
}


Function Write-Dashing {
    Param (
        [Parameter(Mandatory=$true)] [ValidateSet(“ok”, “running”, "warning", "critical", "unknown")]
        [String]$Status,

        [Parameter()]
        [String]$Message = ""
    )

    if ($Script:Uninitialized){
        Error-NeedSet-Dashing
        Return
    }

    $PostParams = ( @{ auth_token=$Script:Token; status=$Status; message=$Message}  | ConvertTo-Json)
    $Url = "$Script:Url/$Script:Service"

    if ($Script:Asynchron){
        Start-Job -ScriptBlock {Invoke-WebRequest -Uri $args[0] -Method Post -Body $args[1]} -ArgumentList $Url,$PostParams
    } else {
        Invoke-WebRequest -Uri $Url -Method Post -Body $PostParams | Out-Null
    }    
}


# Status helpers
Function Write-DashingOk([String]$Message) {
    if ($Script:Uninitialized){
        Error-NeedSet-Dashing
        Return
    }

    Write-Dashing -Status ok -Message $Message 

}

Function Write-DashingRunning([String]$Message) {
    if ($Script:Uninitialized){
        Error-NeedSet-Dashing
        Return
    }

    Write-Dashing -Status running -Message $Message 

}

Function Write-DashingWarning([String]$Message) {
    if ($Script:Uninitialized){
        Error-NeedSet-Dashing
        Return
    }

    Write-Dashing -Status warning -Message $Message 

}

Function Write-DashingCritical([String]$Message) {
    if ($Script:Uninitialized){
        Error-NeedSet-Dashing
        Return
    }

    Write-Dashing -Status critical -Message $Message 

}

Function Write-DashingUnknown([String]$Message) {
    if ($Script:Uninitialized){
        Error-NeedSet-Dashing
        Return
    }

    Write-Dashing -Status unknown -Message $Message 

}

# Make a function public 
Export-ModuleMember -function Set-Dashing,Write-Dashing
Export-ModuleMember -function Write-DashingOk,Write-DashingRunning,Write-DashingWarning,Write-DashingCritical,Write-DashingUnknown
