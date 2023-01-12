# Enable natural scrolling for all configured USB mice on the system - pulling
# down the mouse wheel pulls the screen area down, showing the text above.
#
# Use the "reverse" argument to enable unnatural a.k.a. Microsoft default
# scrolling - pulling down the mouse wheel shows the text below.
#
# Run this script in PowerShell as administrator.
#
# The mouse behavior changes only after rebooting the system.

# Check if we have admin rights
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        
if (!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
     Write-Host -ForegroundColor Red "Need admin privilege to modify the registry"
     exit 1
}

$scrollingBehaviors = @("DEFAULT", "NATURAL")

$switchValue = $args[0];

if ($switchValue -eq "disable" || $switchValue -eq "reverse") {
    $targetSettingValue = 0
} else {
    $targetSettingValue = 1;
}

$mice = (Get-PnpDevice -Class Mouse).where{($_.Status -eq "OK") -and ($_.InstanceID -like "HID\VID*")}

if ($mice.Count -eq 0) {
    Write-Host -ForegroundColor Red "Could not find any USB mouse. Exiting."
    exit 1
}

$settingUpdated = $false

# set up every mouse
foreach ($mouse in $mice) {
    $deviceName = $mouse.FriendlyName
    $deviceInstanceId = $mouse.InstanceID

    Write-Host -ForegroundColor White -BackgroundColor DarkGreen "Found a mouse device $deviceName ($deviceInstanceId)"

    Write-Host -ForegroundColor Cyan "Modifying scrolling behaviors"

    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceInstanceId\Device Parameters"

    $currentVerticalScrollingValue = (Get-ItemProperty -Path $registryPath -Name FlipFlopWheel).FlipFlopWheel

    if ($currentVerticalScrollingValue -ne $targetSettingValue) {
        Set-ItemProperty -Path $registryPath -Name FlipFlopWheel -Value $targetSettingValue
        Write-Host -ForegroundColor Green "Vertical scrolling behavior has been set to " $scrollingBehaviors[$targetSettingValue]
        $settingUpdated = $true
    } else {
        Write-Host -ForegroundColor Green "Keeping the current vertical scrolling behavior: " $scrollingBehaviors[$targetSettingValue]
    }

    $currentHorizontalScrollingValue = (Get-ItemProperty -Path $registryPath -Name FlipFlopHScroll).FlipFlopHScroll

    if ($currentVerticalScrollingValue -ne $targetSettingValue) {
        Set-ItemProperty -Path $registryPath -Name FlipFlopHScroll -Value $targetSettingValue
        Write-Host -ForegroundColor Green "Horizontal scrolling behavior has been set to " $scrollingBehaviors[$targetSettingValue]
        $settingUpdated = $true
    } else {
        Write-Host -ForegroundColor Green "Keeping the current horizontal scrolling behavior: " $scrollingBehaviors[$targetSettingValue]
    }
}

if ($settingUpdated) {
    Write-Host -ForegroundColor Red "Done. You must reboot your computer for the changes to take effect."
} else {
    Write-Host -ForegroundColor Red "Done. No changes have been made."
}
