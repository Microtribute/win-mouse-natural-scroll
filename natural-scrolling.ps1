# Enable natural scrolling for all configured USB Mice on the system - pulling
# down the Mouse wheel pulls the screen area down, showing the text above.
#
# Use the "reverse" argument to enable unnatural a.k.a. Microsoft default
# scrolling - pulling down the Mouse wheel shows the text below.
#
# Run this script in PowerShell as administrator.
#
# The Mouse behavior changes only after rebooting the system.


# Function to modify registry values
function Set-ScrollingBehavior {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InstanceId,

        [Parameter(Mandatory = $true)]
        [string]$ParameterName,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 1)]
        [int]$TargetValue
    )

    $RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$InstanceId\Device Parameters"

    $CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $ParameterName).$ParameterName

    $ValueUpdated = $false;

    if ($CurrentValue -ne $TargetValue) {
        Set-ItemProperty -Path $RegistryPath -Name $ParameterName -Value $TargetValue
        $ValueUpdated = $true;
    }

    return $ValueUpdated
}

# Finds devices that are recognized as a mouse
function Get-Mouse {    
    # $Mice = (Get-PnpDevice -Class Mouse).where{($_.Status -eq "OK") -and ($_.InstanceID -like "HID\VID*")}
    # The InstanceID of a bluetooth mouse starts with "HID\{_uuid_}" e.g.
    # HID\{00001812-0000-1000-8000-00805F9B34FB}_DEV_VID&021235_PID&AA22_REV&0001_231CC511CE68\9&2358A2F3&0&0000
    return (Get-PnpDevice -Class Mouse).where{ ($_.Status -eq "OK") -and (($_.InstanceID -like "HID\VID*") -or ($_.InstanceID -like "HID\*")) }
}

# The `Write-Host` command does a bad job at coloring.
function Write-Message {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$BackgroundColor,

        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$ForegroundColor,

        [Parameter(Mandatory = $false)]
        [bool]$NewLine = $true,

        [Parameter(Mandatory = $true)]
        [Object]$Object
    )

    $Arguments = @{
        Separator       = " "
        NoNewLine       = $true
        Object          = $Object
        ForegroundColor = ($ForegroundColor ?? ([System.Console]::ForegroundColor))
        BackgroundColor = ($BackgroundColor ?? ([System.Console]::BackgroundColor))
    }

    Write-Host @Arguments

    if ($NewLine) {
        Write-Host ([char]0xA0)
    }
}

# Check if we have admin rights
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

if (!$CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Message -ForegroundColor Red -Object "Admin privilege required to modify the registry as necessary."
    exit 1
}

$ScrollingBehaviors = @("DEFAULT", "NATURAL")

$SwitchValue = $args[0];

if ($SwitchValue -eq "disable") {
    $TargetSettingValue = 0
}
else {
    $TargetSettingValue = 1;
}

$Mice = Get-Mouse

if ($Mice.Count -eq 0) {
    Write-Message -BackgroundColor Red -ForegroundColor White -Object "No mice found. Exiting."
    exit 1
}

Write-Message -ForegroundColor White -BackgroundColor DarkGreen -Object "$($Mice.Count) mouse device(s) found."

$SettingUpdated = $false

foreach ($Mouse in $Mice) {
    $DeviceName = $Mouse.FriendlyName
    $DeviceInstanceId = $Mouse.InstanceID

    Write-Message -ForegroundColor DarkMagenta -Object "Device: $DeviceName ($DeviceInstanceId)"

    $VerticalScrollingBehaviorUpdated = Set-ScrollingBehavior -InstanceId $DeviceInstanceId -ParameterName FlipFlopWheel -TargetValue $TargetSettingValue

    if ($VerticalScrollingBehaviorUpdated) {
        Write-Message -ForegroundColor Green -Object "> Vertical scrolling behavior has been set to: $($ScrollingBehaviors[$TargetSettingValue])"
    }
    else {
        Write-Message -ForegroundColor Green -Object "> Keeping the current vertical scrolling behavior: $($ScrollingBehaviors[$TargetSettingValue])"
    }

    $HorizontalScrollingBehaviorUpdated = Set-ScrollingBehavior -InstanceId $DeviceInstanceId -ParameterName FlipFlopHScroll -TargetValue $TargetSettingValue

    if ($HorizontalScrollingBehaviorUpdated) {
        Write-Message -ForegroundColor Green -Object "> Horizontal scrolling behavior has been set to: $($ScrollingBehaviors[$TargetSettingValue])"
    }
    else {
        Write-Message -ForegroundColor Green -Object "> Keeping the current horizontal scrolling behavior: $($ScrollingBehaviors[$TargetSettingValue])"
    }

    $SettingUpdated = $SettingUpdated -or $VerticalScrollingBehaviorUpdated -or $HorizontalScrollingBehaviorUpdated
}

if ($SettingUpdated) {
    Write-Message -ForegroundColor Red -BackgroundColor White -Object "Done. You must reboot your computer or re-plug the devices for the changes to take effect."
}
else {
    Write-Message -ForegroundColor White -BackgroundColor DarkGray -Object "Done. No changes have been made."
}
