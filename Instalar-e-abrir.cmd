@echo off
setlocal
set "DREADS_PROJECT=%~dp0"
echo Preparando Godot 4.7.2 para Windows x64 nesta pasta...
powershell.exe -NoProfile -Command "$ErrorActionPreference='Stop'; try { $root=$env:DREADS_PROJECT; $tools=Join-Path $root '.tools'; $exe=Join-Path $tools 'Godot_v4.7.2-stable_win64.exe'; if (-not (Test-Path -LiteralPath $exe)) { New-Item -ItemType Directory -Force -Path $tools | Out-Null; $archive=Join-Path $tools 'godot.zip'; Invoke-WebRequest -UseBasicParsing -Uri 'https://downloads.godotengine.org/?flavor=stable&platform=windows.64&slug=win64.exe.zip&version=4.7.2' -OutFile $archive; Expand-Archive -LiteralPath $archive -DestinationPath $tools -Force; Remove-Item -LiteralPath $archive }; if (-not (Test-Path -LiteralPath $exe)) { throw 'Executavel do Godot nao encontrado apos extrair.' }; Start-Process -FilePath $exe -WorkingDirectory $root -ArgumentList '--editor','--path','.' } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
 echo Nao foi possivel abrir. Download manual: https://godotengine.org/download/windows/
 pause
 exit /b 1
)
endlocal
