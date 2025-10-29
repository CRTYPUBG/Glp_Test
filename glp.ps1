# Gerekli .NET sınıflarını yükle
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# XAML tanımı - Daha temiz ve okunabilir UI
[xml]$xaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="FPS Optimizer - Daha Hızlı Oyunlar" 
    Height="550" 
    Width="700" 
    ResizeMode="NoResize" 
    WindowStartupLocation="CenterScreen"
    Background="#f0f0f0">
    <Border Margin="15" Background="White" CornerRadius="10" BorderBrush="#cccccc" BorderThickness="1">
        <Grid Margin="15">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- Başlık -->
            <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,15">
                <TextBlock Text="🎮" FontSize="24" VerticalAlignment="Center" Margin="0,0,10,0"/>
                <TextBlock Name="TitleText" Text="FPS Optimizer" FontSize="26" FontWeight="SemiBold" Foreground="#333333" VerticalAlignment="Center"/>
            </StackPanel>

            <!-- Log Kutusu -->
            <Border Grid.Row="1" BorderBrush="#dddddd" BorderThickness="1" CornerRadius="5" Padding="5">
                <ScrollViewer>
                    <TextBox Name="LogBox" 
                             VerticalScrollBarVisibility="Auto" 
                             HorizontalScrollBarVisibility="Auto" 
                             AcceptsReturn="True" 
                             IsReadOnly="True" 
                             TextWrapping="Wrap" 
                             Background="#fafafa" 
                             FontFamily="Consolas" 
                             FontSize="12"
                             Padding="10"/>
                </ScrollViewer>
            </Border>

            <!-- Buton Paneli -->
            <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,20,0,0">
                <Button Name="OptimizeBtn" 
                        Width="160" 
                        Height="45" 
                        Margin="0,0,15,0" 
                        Background="#4CAF50" 
                        Foreground="White" 
                        BorderBrush="#45a049"
                        FontWeight="Medium">
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                        <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE7EF;" Margin="0,0,8,0" VerticalAlignment="Center"/>
                        <TextBlock Text="FPS'i Optimize Et" VerticalAlignment="Center"/>
                    </StackPanel>
                </Button>
                <Button Name="ResetBtn" 
                        Width="160" 
                        Height="45" 
                        Margin="0,0,15,0" 
                        Background="#FF9800" 
                        Foreground="White" 
                        BorderBrush="#e68900"
                        FontWeight="Medium">
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                        <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE72C;" Margin="0,0,8,0" VerticalAlignment="Center"/>
                        <TextBlock Text="Ayarları Sıfırla" VerticalAlignment="Center"/>
                    </StackPanel>
                </Button>
                <Button Name="ExitBtn" 
                        Width="100" 
                        Height="45" 
                        Background="#f44336" 
                        Foreground="White" 
                        BorderBrush="#d32f2f"
                        FontWeight="Medium">
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                        <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE8BB;" Margin="0,0,8,0" VerticalAlignment="Center"/>
                        <TextBlock Text="Çıkış" VerticalAlignment="Center"/>
                    </StackPanel>
                </Button>
            </StackPanel>

            <!-- Uyarı Metni -->
            <TextBlock Grid.Row="2" 
                       Text="⚠️ Dikkat: Bu script sistem ayarlarını değiştirir. Kullanmadan önce bilgi sahibi olun veya bir uzmana danışın. Lütfen programı yönetici olarak çalıştırın." 
                       TextWrapping="Wrap" 
                       FontSize="10" 
                       Foreground="#555555" 
                       HorizontalAlignment="Center" 
                       VerticalAlignment="Bottom" 
                       Margin="0,10,0,0" 
                       MaxWidth="600" />

        </Grid>
    </Border>
</Window>
"@

# XAML Reader ve pencere yükleme
try {
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $Window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Host "XAML Hatası: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Log yazma fonksiyonu
function Write-Log($text) {
    $logBox = $Window.FindName("LogBox")
    $logBox.AppendText("$text`r`n")
    $logBox.ScrollToEnd()
}

# Orijinal fonksiyonlar - Karakter hatalarını düzelttim
function Optimize-FPS {
    Write-Log "=== FPS Optimizasyonu Başlatılıyor ==="
    Write-Log "Gerekli izinlerin (yönetici) olduğundan emin olun."

    Write-Log "1/6: HAGS (Donanım Hızlandırmalı GPU Zamanlayıcısı) kapatılıyor..."
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        $regName = "HwSchMode"
        $regValue = 0
        Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -Type DWord -Force
        Write-Log "   ✅ HAGS başarıyla kapatıldı. (HwSchMode = $regValue)"
    } catch {
        Write-Log "   ❌ HAGS kapatma hatası: $($_.Exception.Message)"
    }

    Write-Log "2/6: GameDVR ve Xbox Game Bar özellikleri kapatılıyor..."
    try {
        $gameConfigPath = "HKCU:\System\GameConfigStore"
        $gameDVRName = "GameDVR_Enabled"
        $gameDVRValue = 0
        Set-ItemProperty -Path $gameConfigPath -Name $gameDVRName -Value $gameDVRValue -Type DWord -Force

        $gameDVRPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
        $allowGameDVRName = "AllowGameDVR"
        $allowGameDVRValue = 0
        if (!(Test-Path $gameDVRPolicyPath)) {
            New-Item -Path $gameDVRPolicyPath -Force | Out-Null
        }
        Set-ItemProperty -Path $gameDVRPolicyPath -Name $allowGameDVRName -Value $allowGameDVRValue -Type DWord -Force

        $gameBarPath = "HKCU:\Software\Microsoft\GameBar"
        $showStartupPanelName = "ShowStartupPanel"
        $showStartupPanelValue = 0
        if (!(Test-Path $gameBarPath)) {
            New-Item -Path $gameBarPath -Force | Out-Null
        }
        Set-ItemProperty -Path $gameBarPath -Name $showStartupPanelName -Value $showStartupPanelValue -Type DWord -Force

        Write-Log "   ✅ GameDVR ve GameBar başarıyla kapatıldı."
    } catch {
        Write-Log "   ❌ GameDVR/GameBar kapatma hatası: $($_.Exception.Message)"
    }

    Write-Log "3/6: NVIDIA DX/GL önbellekleri temizleniyor..."
    try {
        $dxCache = "$env:LOCALAPPDATA\NVIDIA\DXCache"
        $glCache = "$env:LOCALAPPDATA\NVIDIA\GLCache"

        if (Test-Path $dxCache) {
            Remove-Item -Path $dxCache -Recurse -Force -ErrorAction Stop
            Write-Log "   ✅ DXCache temizlendi."
        } else {
            Write-Log "   ℹ️ DXCache bulunamadı, atlanıyor."
        }

        if (Test-Path $glCache) {
            Remove-Item -Path $glCache -Recurse -Force -ErrorAction Stop
            Write-Log "   ✅ GLCache temizlendi."
        } else {
            Write-Log "   ℹ️ GLCache bulunamadı, atlanıyor."
        }
    } catch {
        Write-Log "   ❌ NVIDIA cache temizleme hatası: $($_.Exception.Message)"
    }

    Write-Log "4/6: Güç planı 'Yüksek Performans' olarak ayarlanıyor..."
    try {
        $highPerfGuid = (Get-WmiObject -Class win32_powerplan -Namespace root\cimv2\power -Filter "ElementName='High performance'").InstanceID.Split('\\')[-1]
        if ($highPerfGuid) {
            powercfg /setactive $highPerfGuid
            Write-Log "   ✅ Güç planı 'Yüksek Performans' olarak ayarlandı. (GUID: $highPerfGuid)"
        } else {
            Write-Log "   ⚠️ 'Yüksek Performans' güç planı bulunamadı."
        }
    } catch {
        Write-Log "   ❌ Güç planı ayarlama hatası: $($_.Exception.Message)"
    }

    Write-Log "5/6: Gereksiz hizmetler durduruluyor..."
    $servicesToStop = @("SysMain", "DiagTrack", "WSearch")
    foreach ($serviceName in $servicesToStop) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction Stop
            if ($service.Status -eq 'Running') {
                Stop-Service -Name $serviceName -Force -ErrorAction Stop
                Write-Log "   ✅ '$serviceName' hizmeti durduruldu."
            } else {
                Write-Log "   ℹ️ '$serviceName' zaten durmuş durumda."
            }
        } catch {
            Write-Log "   ❌ '$serviceName' hizmeti durdurulamadı: $($_.Exception.Message)"
        }
    }

    Write-Log "6/6: Disk temizliği çalıştırılıyor..."
    try {
        sfc /scannow | Write-Log
        Write-Log "   ℹ️ SFC taraması başlatıldı (loglara yazılacak)."
    } catch {
        Write-Log "   ❌ Disk temizliği hatası (sfc): $($_.Exception.Message)"
    }

    Write-Log "🎉 FPS Optimizasyonu tamamlandı!"
    Write-Log "Lütfen sistemi yeniden başlatarak değişikliklerin etkili olması için gereken adımı yapın."
}

function Reset-Settings {
    Write-Log "=== Ayarlar Sıfırlanıyor (Fabrika Ayarları) ==="

    Write-Log "1/3: HAGS (Donanım Hızlandırmalı GPU Zamanlayıcısı) etkinleştiriliyor..."
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        $regName = "HwSchMode"
        $regValue = 2
        Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -Type DWord -Force
        Write-Log "   ✅ HAGS etkinleştirildi. (HwSchMode = $regValue)"
    } catch {
        Write-Log "   ❌ HAGS sıfırlama hatası: $($_.Exception.Message)"
    }

    Write-Log "2/3: GameDVR ayarları etkinleştiriliyor..."
    try {
        $gameConfigPath = "HKCU:\System\GameConfigStore"
        $gameDVRName = "GameDVR_Enabled"
        $gameDVRValue = 1
        Set-ItemProperty -Path $gameConfigPath -Name $gameDVRName -Value $gameDVRValue -Type DWord -Force

        $gameDVRPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
        $allowGameDVRName = "AllowGameDVR"
        $allowGameDVRValue = 1
        if (Test-Path $gameDVRPolicyPath) {
            Set-ItemProperty -Path $gameDVRPolicyPath -Name $allowGameDVRName -Value $allowGameDVRValue -Type DWord -Force
        } else {
            Write-Warning "Sıfırlama: $gameDVRPolicyPath yolu mevcut değil, oluşturulmadı."
        }

        $gameBarPath = "HKCU:\Software\Microsoft\GameBar"
        $showStartupPanelName = "ShowStartupPanel"
        $showStartupPanelValue = 1
        if (Test-Path $gameBarPath) {
            Set-ItemProperty -Path $gameBarPath -Name $showStartupPanelName -Value $showStartupPanelValue -Type DWord -Force
        } else {
             Write-Log "   ℹ️ GameBar ayarları zaten sıfırlanmış olabilir."
        }

        Write-Log "   ✅ GameDVR/GameBar ayarları sıfırlandı."
    } catch {
        Write-Log "   ❌ GameDVR/GameBar sıfırlama hatası: $($_.Exception.Message)"
    }

    Write-Log "3/3: Servisler başlatılamaz (otomatik/elle başlayabilirler)."
    Write-Log "   ℹ️ 'SysMain', 'DiagTrack', 'WSearch' gibi servisler için Windows varsayılan ayarları kullanılacaktır. Gerekirse Hizmetler (services.msc) üzerinden manuel olarak kontrol edin."

    Write-Log "✅ Ayarlar sıfırlandı."
    Write-Log "Lütfen sistemi yeniden başlatarak değişikliklerin etkili olması için gereken adımı yapın."
}

# Buton event'lerini bağlama
$Window.FindName("OptimizeBtn").Add_Click({ Optimize-FPS })
$Window.FindName("ResetBtn").Add_Click({ Reset-Settings })
$Window.FindName("ExitBtn").Add_Click({ $Window.Close() })

# Pencereyi göster
try {
    $Window.ShowDialog() | Out-Null
} catch {
    Write-Host "UI Hatası: $($_.Exception.Message)" -ForegroundColor Red
}
