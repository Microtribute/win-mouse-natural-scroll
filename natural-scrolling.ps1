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
function UpdateRegistryParameter {
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


# Check if we have admin rights
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        
if (!$CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
     Write-Host -ForegroundColor Red "Admin privilege required to modify the registry as necessary"
     exit 1
}

$ScrollingBehaviors = @("DEFAULT", "NATURAL")

$SwitchValue = $args[0];

if (($SwitchValue -eq "disable") -or ($SwitchValue -eq "reverse")) {
    $TargetSettingValue = 0
} else {
    $TargetSettingValue = 1;
}

# $Mice = (Get-PnpDevice -Class Mouse).where{($_.Status -eq "OK") -and ($_.InstanceID -like "HID\VID*")}
# The InstanceID of a bluetooth mouth starts with "HID\{_uuid_}" e.g.
# HID\{00001812-0000-1000-8000-00805F9B34FB}_DEV_VID&021235_PID&AA22_REV&0001_231CC511CE68\9&2358A2F3&0&0000
$Mice = (Get-PnpDevice -Class Mouse).where{($_.Status -eq "OK") -and (($_.InstanceID -like "HID\VID*") -or ($_.InstanceID -like "HID\*"))}

if ($Mice.Count -eq 0) {
    Write-Host -ForegroundColor Red "Could not find any USB Mouse. Exiting."
    exit 1
}

$SettingUpdated = $false

foreach ($Mouse in $Mice) {
    $DeviceName = $Mouse.FriendlyName
    $DeviceInstanceId = $Mouse.InstanceID

    Write-Host -ForegroundColor DarkMagenta "Found a mouse device: $DeviceName ($DeviceInstanceId)"

    $VerticalScrollingBehaviorUpdated = UpdateRegistryParameter -InstanceId $DeviceInstanceId -ParameterName FlipFlopWheel -TargetValue $TargetSettingValue

    if ($VerticalScrollingBehaviorUpdated) {
        Write-Host -ForegroundColor Green "> Vertical scrolling behavior has been updated:" $ScrollingBehaviors[$TargetSettingValue]
    } else {
        Write-Host -ForegroundColor Green "> Keeping the current vertical scrolling behavior:" $ScrollingBehaviors[$TargetSettingValue]
    }

    $HorizontalScrollingBehaviorUpdated = UpdateRegistryParameter -InstanceId $DeviceInstanceId -ParameterName FlipFlopHScroll -TargetValue $TargetSettingValue

    if ($HorizontalScrollingBehaviorUpdated) {
        Write-Host -ForegroundColor Green "> Horizontal scrolling behavior has been updated to:" $ScrollingBehaviors[$TargetSettingValue]
    } else {
        Write-Host -ForegroundColor Green "> Keeping the current horizontal scrolling behavior:" $ScrollingBehaviors[$TargetSettingValue]
    }

    $SettingUpdated = $SettingUpdated -or $VerticalScrollingBehaviorUpdated -or $HorizontalScrollingBehaviorUpdated
}

if ($SettingUpdated) {
    Write-Host -ForegroundColor Red "Done. You must reboot your computer for the changes to take effect."
} else {
    Write-Host -ForegroundColor Red "Done. No changes have been made."
}
