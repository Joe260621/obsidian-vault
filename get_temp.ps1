# Use OpenHardwareMonitor or WMI to get temps
# Try via WMI first, then via OpenHardwareMonitor if available

function Get-Temp {
    # Method 1: Win32_PerfFormattedData for thermal zone
    try {
        $thermal = Get-WmiObject -Class Win32_PerfFormattedData_Counters_ThermalZoneInformation -ErrorAction Stop
        foreach ($t in $thermal) {
            [PSCustomObject]@{Source="ThermalZone"; Name=$t.Name; Temp_C=($t.Temperature - 2732)/10.0}
        }
    } catch {}

    # Method 2: Check if HWMonitor is running and try to get its data
    try {
        $searcher = New-Object System.Management.ManagementObjectSearcher("root\WMI", "SELECT * FROM MSAcpi_ThermalZoneTemperature")
        $items = $searcher.Get()
        foreach ($item in $items) {
            [PSCustomObject]@{Source="ACPI"; Name=$item.InstanceName; Temp_K=$item.CurrentTemperature}
        }
    } catch {}
}

Get-Temp
