# Gerekli modülleri yükle (WPF için gerekli olabilir, sadece konsol için gerekli değil)
# Add-Type -AssemblyName PresentationFramework

# Fonksiyon: Registry değerini kontrol et
function Test-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )
    $exists = $false
    $value = $null
    try {
        if (Test-Path $Path) {
            $item = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
            $value = $item.$Name
            $exists = $true
        }
    } catch [System.Management.Automation.ItemNotFoundException] {
        # Yol mevcut değil
    } catch [System.Management.Automation.ParameterBindingException] {
        # Özellik adı mevcut değil
        $exists = $true # Yol var ama özellik yok
    }
    return @{
        Exists = $exists
        Value  = $value
    }
}

# Fonksiyon: Ayar durumunu yazdır
function Write-Status {
    param(
        [string]$SettingName,
        [bool]$IsActive
    )
    if ($IsActive) {
        Write-Host "✅ $SettingName: Etkin" -ForegroundColor Green
    } else {
        Write-Host "❌ $SettingName: Devre Dışı" -ForegroundColor Red
    }
}

# Fonksiyon: Ayar durumunu detaylı yazdır
function Write-Detail {
    param(
        [string]$SettingName,
        [bool]$IsActive,
        [object]$Value,
        [string]$ExpectedValue
    )
    $status = if ($IsActive) { "Etkin" } else { "Devre Dışı" }
    $color = if ($IsActive) { "Green" } else { "Red" }
    Write-Host "✅ $SettingName: $status" -ForegroundColor $color
    if ($Value -ne $null) {
        Write-Host "   Değer: $Value (Beklenen: $ExpectedValue)" -ForegroundColor $color
    }
}

Write-Host "=== FPS Optimizasyon Ayarları Kontrolü ===" -ForegroundColor Cyan
Write-Host ""

# 1. HAGS (Donanım Hızlandırmalı GPU Zamanlayıcısı)
Write-Host "--- HAGS (Hardware-Accelerated GPU Scheduling) ---"
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
$regName = "HwSchMode"
$result = Test-RegistryValue -Path $regPath -Name $regName
$isActive = ($result.Exists -and $result.Value -eq 0)
Write-Detail -SettingName "HAGS" -IsActive $isActive -Value $result.Value -ExpectedValue "0 (Devre Dışı)"

Write-Host ""

# 2. GameDVR
Write-Host "--- GameDVR ve Xbox Game Bar Ayarları ---"
$gameConfigPath = "HKCU:\System\GameConfigStore"
$gameDVRName = "GameDVR_Enabled"
$gameDVRResult = Test-RegistryValue -Path $gameConfigPath -Name $gameDVRName
$gameDVRActive = ($gameDVRResult.Exists -and $gameDVRResult.Value -eq 0)

$gameDVRPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
$allowGameDVRName = "AllowGameDVR"
$allowGameDVRResult = Test-RegistryValue -Path $gameDVRPolicyPath -Name $allowGameDVRName
$allowGameDVREnabled = ($allowGameDVRResult.Exists -and $allowGameDVRResult.Value -eq 0) # 0 = Engelle

$gameBarPath = "HKCU:\Software\Microsoft\GameBar"
$showStartupPanelName = "ShowStartupPanel"
$showStartupPanelResult = Test-RegistryValue -Path $gameBarPath -Name $showStartupPanelName
$showStartupPanelDisabled = ($showStartupPanelResult.Exists -and $showStartupPanelResult.Value -eq 0)

$gameDVROverallActive = ($gameDVRActive -and $allowGameDVREnabled -and $showStartupPanelDisabled)

Write-Detail -SettingName "GameDVR (HKCU)" -IsActive $gameDVRActive -Value $gameDVRResult.Value -ExpectedValue "0 (Devre Dışı)"
Write-Detail -SettingName "GameDVR (HKLM Policy)" -IsActive $allowGameDVREnabled -Value $allowGameDVRResult.Value -ExpectedValue "0 (Engelli)"
Write-Detail -SettingName "GameBar Başlangıç Paneli" -IsActive $showStartupPanelDisabled -Value $showStartupPanelResult.Value -ExpectedValue "0 (Gizli)"
Write-Host ""
if ($gameDVROverallActive) {
    Write-Host "✅ Genel GameDVR Ayarları: Etkin" -ForegroundColor Green
} else {
    Write-Host "❌ Genel GameDVR Ayarları: Devre Dışı" -ForegroundColor Red
}

Write-Host ""

# 3. NVIDIA Cache (Klasör mevcudiyetiyle kontrol edilir, registry değil)
Write-Host "--- NVIDIA DX/GL Önbelleği ---"
$dxCachePath = "$env:LOCALAPPDATA\NVIDIA\DXCache"
$glCachePath = "$env:LOCALAPPDATA\NVIDIA\GLCache"
$dxCacheExists = Test-Path $dxCachePath
$glCacheExists = Test-Path $glCachePath

if ($dxCacheExists) {
    Write-Host "❌ DXCache Klasörü Mevcut: $dxCachePath (Temizlenmemiş)" -ForegroundColor Red
} else {
    Write-Host "✅ DXCache Klasörü Yok: Temizlenmiş (muhtemelen)" -ForegroundColor Green
}
if ($glCacheExists) {
    Write-Host "❌ GLCache Klasörü Mevcut: $glCachePath (Temizlenmemiş)" -ForegroundColor Red
} else {
    Write-Host "✅ GLCache Klasörü Yok: Temizlenmiş (muhtemelen)" -ForegroundColor Green
}

Write-Host ""

# 4. Güç Planı
Write-Host "--- Güç Planı ---"
$currentPlan = powercfg /getactivescheme
# Örnek çıktı: "Power Scheme GUID: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  (High performance)"
$highPerfGuid = (Get-WmiObject -Class win32_powerplan -Namespace root\cimv2\power -Filter "ElementName='High performance'").InstanceID.Split('\\')[-1]
$isActive = $currentPlan -match $highPerfGuid

if ($isActive) {
    Write-Host "✅ Güç Planı: Yüksek Performans (Etkin)" -ForegroundColor Green
    Write-Host "   GUID: $highPerfGuid" -ForegroundColor Green
} else {
    Write-Host "❌ Güç Planı: Yüksek Performans DEĞİL" -ForegroundColor Red
    Write-Host "   Mevcut Plan: $currentPlan" -ForegroundColor Red
}

Write-Host ""

# 5. Servisler
Write-Host "--- Servisler ---"
$services = @(
    @{ Name = "SysMain"; ExpectedStatus = "Stopped" },
    @{ Name = "DiagTrack"; ExpectedStatus = "Stopped" },
    @{ Name = "WSearch"; ExpectedStatus = "Stopped" }
)

foreach ($service in $services) {
    try {
        $svc = Get-Service -Name $service.Name -ErrorAction Stop
        $isActive = ($svc.Status -eq $service.ExpectedStatus)
        Write-Detail -SettingName $service.Name -IsActive $isActive -Value $svc.Status -ExpectedValue $service.ExpectedStatus
    } catch {
        Write-Host "❌ Servis '$($service.Name)' bulunamadı." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Kontrol Tamamlandı ===" -ForegroundColor Cyan
