Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Gameloop FPS Optimizer" Height="450" Width="600" ResizeMode="NoResize" WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Gameloop FPS Optimizer" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,10"/>

        <TextBox Name="LogBox" Grid.Row="1" VerticalScrollBarVisibility="Auto" AcceptsReturn="True" IsReadOnly="True"/>

        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10,0,0" >
            <Button Name="OptimizeBtn" Width="150" Height="40" Margin="5">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE7EF;" Margin="0,0,5,0"/>
                    <TextBlock Text="Optimize FPS"/>
                </StackPanel>
            </Button>
            <Button Name="ResetBtn" Width="150" Height="40" Margin="5">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE72C;" Margin="0,0,5,0"/>
                    <TextBlock Text="Reset Ayarlar"/>
                </StackPanel>
            </Button>
            <Button Name="ExitBtn" Width="100" Height="40" Margin="5">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE8BB;" Margin="0,0,5,0"/>
                    <TextBlock Text="Çıkış"/>
                </StackPanel>
            </Button>
        </StackPanel>
    </Grid>
</Window>
"@

# XAML yükleme
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Log yazma fonksiyonu
function Write-Log($text) {
    $Window.FindName("LogBox").AppendText("$text`r`n")
    $Window.FindName("LogBox").ScrollToEnd()
}

# FPS Optimize Fonksiyonu
function Optimize-FPS {
    Write-Log "Başlıyor: HAGS kapatılıyor..."
    try {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 0 /f | Out-Null
        Write-Log "✅ HAGS kapatıldı"
    } catch { Write-Log "❌ HAGS hatası: $_" }

    Write-Log "GameDVR kapatılıyor..."
    try {
        reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\Software\Microsoft\GameBar" /v ShowStartupPanel /t REG_DWORD /d 0 /f | Out-Null
        Write-Log "✅ GameDVR kapatıldı"
    } catch { Write-Log "❌ GameDVR hatası: $_" }

    Write-Log "NVIDIA DX/GL cache temizleniyor..."
    try {
        $dxCache = "$env:LOCALAPPDATA\NVIDIA\DXCache"
        $glCache = "$env:LOCALAPPDATA\NVIDIA\GLCache"
        if (Test-Path $dxCache) { Remove-Item -Path $dxCache -Recurse -Force }
        if (Test-Path $glCache) { Remove-Item -Path $glCache -Recurse -Force }
        Write-Log "✅ DX/GL cache temizlendi"
    } catch { Write-Log "❌ Cache temizleme hatası: $_" }

    Write-Log "Güç planı yüksek performans olarak ayarlanıyor..."
    try { powercfg /s SCHEME_MIN | Out-Null; Write-Log "✅ Güç planı ayarlandı" } catch { Write-Log "❌ Güç planı hatası: $_" }

    Write-Log "Gereksiz servisler durduruluyor..."
    try { Stop-Service -Name "SysMain","DiagTrack","WSearch" -Force; Write-Log "✅ Servisler durduruldu" } catch { Write-Log "❌ Servis hatası: $_" }

    Write-Log "🎉 FPS Optimizer tamamlandı! Lütfen PC'yi yeniden başlatın."
}

# Reset Fonksiyonu
function Reset-Settings {
    Write-Log "Ayarlar fabrika değerlerine sıfırlanıyor..."
    try { reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f | Out-Null } catch {}
    try { reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f | Out-Null } catch {}
    try { reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 1 /f | Out-Null } catch {}
    Write-Log "✅ Ayarlar sıfırlandı. Lütfen PC'yi yeniden başlatın."
}

# Buton eventleri
$Window.FindName("OptimizeBtn").Add_Click({ Optimize-FPS })
$Window.FindName("ResetBtn").Add_Click({ Reset-Settings })
$Window.FindName("ExitBtn").Add_Click({ $Window.Close() })

# Pencereyi aç
$Window.ShowDialog() | Out-Null
