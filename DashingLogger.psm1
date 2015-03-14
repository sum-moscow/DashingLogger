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
        0.2

    .Example (Only Dashing)
        # Import module
        Import-Module DashingLogger
        # Init (in asynchron mode)
        Set-Dashing -Service SomeSerive -Url SomeUrl -Token SomeToken -Asynchron
        # Send status
        Write-Dashing -Status ok -Message "All is ok"
        # or
        Write-DashingOk "All is ok"

    .Example (as logger)
        # Import module
        Import-Module DashingLogger
        # Init
        Log-Set -Service SomeSerive -Url SomeUrl -Token SomeToken 
        # Begin logging
        Log-Begin
        # Write [ok] log
        Log("SomeMessage") # in this equal function: Write-DashingRunning -Message "SomeMessage"
        # Write warning log
        Log-Warning("Something Is Bad")
        # Write critical log and end logging
        Log-Critical("Fatality") -End # equal: Log-Critical("Fatality"); Log-End

#>

[String]$Script:Service
[String]$Script:Url
[String]$Script:Token

[Bool]$Script:Uninitialized = $true
[Bool]$Script:Asynchron
[Bool]$Script:Echo = $true

[Int]$Script:Oks = 0
[Int]$Script:Warnings = 0
[Int]$Script:Criticals = 0

# For Log-* functions
[Bool]$Script:ScriptRunning = $false

Function Set-Dashing {
    Param (
        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]
        [String]$Service,

        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]
        [String]$Url,

        [Parameter()]
        [String]$Token = "",

        [Parameter()]
        [Switch]$Asynchron,

        [Parameter()]
        [Switch]$NoEcho 
    )

    $Script:Service = $Service
    $Script:Url = $Url
    $Script:Token = $Token
    $Script:Asynchron = $Asynchron
    $Script:Echo = !$NoEcho

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

    if ($Script:Echo){
        Echo $Message
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

# Log function
Function Log-Begin([String]$Message) {
    $Script:Ok = 0
    $Script:Warnings = 0
    $Script:Criticals = 0

    $Script:ScriptRunning = $true
    Write-DashingRunning 
}

Function Log-Ok([String]$Message) {
    $Script:Oks++
    if ($Script:ScriptRunning){
        Write-DashingRunning -Message $Message
    } else {
        Write-DashingOk -Message $Message
    }
}

Function Log-Warning([String]$Message) {
    $Script:Warnings++
    if ($Script:ScriptRunning){
        Write-DashingRunning -Message "Warning: $Message"
    } else {
        Write-DashingWarning -Message $Message
    }
}

Function Log-Critical([String]$Message,[Switch]$End) {
    $Script:Criticals++

    if ($End){
        $Script:ScriptRunning = $false
    }

    if ($Script:ScriptRunning){
        Write-DashingRunning -Message "Critical: $Message"
    } else {
        Write-DashingCritical -Message $Message
    }
}

Function Log-End([String]$Message,[Switch]$Statistic) {
    if ($Statistic){
        if (!$Message) { $Message = "" }
        $Message += "Oks: $($Script:Ok)`n"
        $Message += "Warnings: $($Script:Warnings)`n"
        $Message += "Criticals: $($Script:Criticals)`n"
    }

    if ($Script:Criticals -gt 0){
        Write-DashingCritical -Message $Message
    } elseif ($Script:Warnings -gt 0){
        Write-DashingWarning -Message $Message
    } else {
        Write-DashingOk -Message $Message
    }

    $Script:ScriptRunning = $false
}

# Create aliases
New-Alias -Name Log-Set -Value Set-Dashing

New-Alias -Name Log -Value Log-Ok
New-Alias -Name Log-Stop -Value Log-End

# Make a function public 
Export-ModuleMember -Function Set-Dashing,Write-Dashin,Write-DashingResult -Alias Log-Set
Export-ModuleMember -Function Write-DashingOk,Write-DashingRunning,Write-DashingWarning,Write-DashingCritical,Write-DashingUnknown
Export-ModuleMember -Function Log-Begin,Log-Ok,Log-Warning,Log-Critical,Log-End -Alias Log,Log-Stop 
