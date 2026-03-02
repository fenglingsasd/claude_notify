# Claude Code Windows 通知安装脚本
# 用法: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = 'Stop'

# 1. 确定安装目录（脚本所在目录）
$installDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$snore      = Join-Path $installDir 'snoretoast.exe'
$icon       = Join-Path $installDir 'claude-icon.png'
$settingsDir = Join-Path $env:USERPROFILE '.claude'
$settingsFile = Join-Path $settingsDir 'settings.json'

Write-Host "Install dir : $installDir"
Write-Host "Settings    : $settingsFile"

# 2. 检查必要文件
if (-not (Test-Path $snore)) { throw "snoretoast.exe not found in $installDir" }
if (-not (Test-Path $icon))  { throw "claude-icon.png not found in $installDir" }

# 3. 注册 AppID（幂等）
& $snore -install 'Claude Code' $snore 'Claude.Code' | Out-Null
Write-Host "AppID registered: Claude.Code"

# 4. 生成 EncodedCommand（动态路径）
function New-ToastCmd {
    param([string]$CharCodes)
    $ps = @"
& '$snore' -install 'Claude Code' '$snore' 'Claude.Code' | Out-Null
`$ts  = (Get-Date -Format 'HH:mm:ss')
`$msg = [System.String]::new([char[]]@($CharCodes))
& '$snore' -t 'Claude Code' -m "`$msg  `$ts" -p '$icon' -appID 'Claude.Code'
"@
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($ps)
    $enc   = [Convert]::ToBase64String($bytes)
    return "powershell -NoProfile -NonInteractive -EncodedCommand $enc"
}

$stopCmd     = New-ToastCmd '0x4EFB,0x52A1,0x5DF2,0x5B8C,0x6210,0xFF0C,0x8BF7,0x67E5,0x770B,0x7ED3,0x679C'
$questionCmd = New-ToastCmd '0x6709,0x65B9,0x6848,0x9700,0x8981,0x4F60,0x9009,0x62E9,0xFF0C,0x8BF7,0x56DE,0x5230,0x7EC8,0x7AEF'

# 5. 读取或创建 settings.json
if (Test-Path $settingsFile) {
    $cfg = Get-Content $settingsFile -Raw | ConvertFrom-Json
} else {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    $cfg = [PSCustomObject]@{ hooks = [PSCustomObject]@{} }
}

# 6. 写入 Stop hook
$stopHook = [PSCustomObject]@{
    hooks = @(
        [PSCustomObject]@{
            type    = 'command'
            command = $stopCmd
            timeout = 10
        }
    )
}

# 7. 写入 PreToolUse hook
$questionHook = [PSCustomObject]@{
    matcher = 'AskUserQuestion'
    hooks = @(
        [PSCustomObject]@{
            type    = 'command'
            command = $questionCmd
            timeout = 10
        }
    )
}

# 8. 合并到 settings.json
if (-not $cfg.hooks) { $cfg | Add-Member -NotePropertyName hooks -NotePropertyValue ([PSCustomObject]@{}) }
$cfg.hooks | Add-Member -NotePropertyName Stop     -NotePropertyValue @($stopHook)     -Force
$cfg.hooks | Add-Member -NotePropertyName PreToolUse -NotePropertyValue @($questionHook) -Force

$cfg | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8

Write-Host ""
Write-Host "Done! settings.json updated at: $settingsFile"
Write-Host "Restart Claude Code (VSCode) to apply."
