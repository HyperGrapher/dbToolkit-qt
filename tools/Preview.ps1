param(
    [switch]$PrepareOnly
)

$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$qmlDirectory = Join-Path $projectDirectory 'src/qml'
$previewDirectory = Join-Path $projectDirectory 'build/ui-preview'
$moduleDirectory = Join-Path $previewDirectory 'DbToolKit'
$qmlCommand = Get-Command qml.exe -ErrorAction Stop

New-Item -ItemType Directory -Path $moduleDirectory -Force | Out-Null
$moduleLines = @('module DbToolKit')
foreach ($sourceFile in Get-ChildItem -LiteralPath $qmlDirectory -Filter '*.qml') {
    Copy-Item -LiteralPath $sourceFile.FullName -Destination $moduleDirectory -Force
    $isSingleton = Select-String -LiteralPath $sourceFile.FullName -Pattern '^pragma Singleton' -Quiet
    $prefix = if ($isSingleton) { 'singleton ' } else { '' }
    $moduleLines += "$prefix$($sourceFile.BaseName) 1.0 $($sourceFile.Name)"
}
$moduleLines | Set-Content -LiteralPath (Join-Path $moduleDirectory 'qmldir') -Encoding utf8
@'
import QtQuick
import DbToolKit

Main {}
'@ | Set-Content -LiteralPath (Join-Path $previewDirectory 'Launch.qml') -Encoding utf8

if ($PrepareOnly) {
    Write-Output "Prepared QML preview at $previewDirectory. No configure or build was run."
    return
}

# Only the child QML process inherits this style; no machine settings are changed.
$previousStyle = $env:QT_QUICK_CONTROLS_STYLE
try {
    $env:QT_QUICK_CONTROLS_STYLE = 'Basic'
    # This is the visible, interactive preview requested by the user.
    $previewProcess = Start-Process -FilePath $qmlCommand.Source -WorkingDirectory $previewDirectory `
        -ArgumentList @('-apptype', 'gui', '-I', '.', 'Launch.qml') -PassThru
    Write-Output "Opened dbToolKit UI preview (PID $($previewProcess.Id)). No dependencies were built."
} finally {
    $env:QT_QUICK_CONTROLS_STYLE = $previousStyle
}
