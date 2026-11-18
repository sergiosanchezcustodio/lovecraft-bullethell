# Memoria de la build (hito 22.8): lanza el .exe en el escritorio aparte (sin quitar el foco) y apunta
# la RAM y la memoria de vídeo máximas del proceso. Desde PowerShell, en la raíz:
#   ./tools/medir_memoria.ps1 -Args2 "level=p4_n5 bots=3 bot=smart god=true mute=true cfg_quality=3" -Secs 110
param([string]$Args2, [int]$Secs = 100, [string]$Exe = (Join-Path $PSScriptRoot "..\builds\windows\LovecraftLibrary.exe"))
$py = Join-Path $PSScriptRoot "escritorio_aparte.py"
$argList = @($py, $Exe, "--resolution", "1920x1080", "--") + ($Args2 -split ' ')
$launcher = Start-Process python -ArgumentList $argList -PassThru -WindowStyle Hidden
$p = $null
for ($i = 0; $i -lt 60 -and -not $p; $i++) { Start-Sleep -Milliseconds 500; $p = Get-Process LovecraftLibrary -ErrorAction SilentlyContinue | Select-Object -First 1 }
if (-not $p) { "no arrancó"; exit 1 }
$maxWs = 0; $maxGpu = 0; $maxShared = 0
$t0 = Get-Date
while (((Get-Date) - $t0).TotalSeconds -lt $Secs -and -not $p.HasExited) {
	$p.Refresh()
	if ($p.WorkingSet64 -gt $maxWs) { $maxWs = $p.WorkingSet64 }
	try {
		$c = Get-Counter "\GPU Process Memory(pid_$($p.Id)_*)\Dedicated Usage", "\GPU Process Memory(pid_$($p.Id)_*)\Shared Usage" -ErrorAction Stop
		$ded = ($c.CounterSamples | Where-Object { $_.Path -like '*dedicated*' } | Measure-Object CookedValue -Sum).Sum
		$sh = ($c.CounterSamples | Where-Object { $_.Path -like '*shared*' } | Measure-Object CookedValue -Sum).Sum
		if ($ded -gt $maxGpu) { $maxGpu = $ded }
		if ($sh -gt $maxShared) { $maxShared = $sh }
	} catch {}
	Start-Sleep -Milliseconds 1000
}
$p.Refresh()
$peak = $p.PeakWorkingSet64
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
"RAM máx: {0} MB (pico del proceso {1} MB) · VRAM dedicada máx: {2} MB · compartida: {3} MB" -f [int]($maxWs/1MB), [int]($peak/1MB), [int]($maxGpu/1MB), [int]($maxShared/1MB)
