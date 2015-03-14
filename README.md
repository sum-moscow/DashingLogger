# DashingLogger
This module can send service status and information message to dashboard Dashing.

I use this to control scripts execution from [Dashing](https://github.com/Shopify/dashing/).

Also I make the module "public" (all PS scripts can import it).
For this:

1. clone the module to folder `C:\Program Files\Common Files\Modules\`
(file `DashingLogger.psm1` is located on `C:\Program Files\Common Files\Modules\DashingLogger\DashingLogger.psm1` )
2. run the command:
`[Environment]::SetEnvironmentVariable("PSModulePath", $CurrentValue + ";C:\Program Files\Common Files\Modules\", "Machine")`


# Usage
## Only Dashing
```PowerShell
# Import module
Import-Module DashingLogger
# Init (in asynchron mode)
Set-Dashing -Service SomeSerive -Url SomeUrl -Token SomeToken -Asynchron
# Send status
Write-Dashing -Status ok -Message "All is ok"
# or
Write-DashingOk "All is ok"
```
## As logger
```PowerShell
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
```
