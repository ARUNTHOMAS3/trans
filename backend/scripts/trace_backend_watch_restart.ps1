param(
  [int]$DurationMinutes = 60,
  [switch]$TakeOverPort = $true
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Split-Path -Parent $scriptDir
$srcDir = Join-Path $backendDir "src"
$logsDir = Join-Path $backendDir "logs"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$traceLog = Join-Path $logsDir "backend-watch-trace-$stamp.log"
$stdoutLog = Join-Path $logsDir "backend-watch-stdout-$stamp.log"
$stderrLog = Join-Path $logsDir "backend-watch-stderr-$stamp.log"

function Write-TraceLog {
  param([string]$Message)
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"), $Message
  Add-Content -Path $traceLog -Value $line
}

function Get-WatchProcesses {
  Get-CimInstance Win32_Process |
    Where-Object {
      ($_.CommandLine -like "*node --watch*src/main.ts*") -or
      ($_.CommandLine -like "*ts-node/register/transpile-only*src/main.ts*")
    } |
    Select-Object ProcessId, ParentProcessId, Name, CommandLine
}

function Get-ListenerSnapshot {
  Get-NetTCPConnection -LocalPort 3001 -ErrorAction SilentlyContinue |
    Select-Object LocalAddress, LocalPort, State, OwningProcess
}

Write-TraceLog "Trace session started. DurationMinutes=$DurationMinutes TakeOverPort=$TakeOverPort"

if ($TakeOverPort) {
  $existing = Get-WatchProcesses
  if ($existing) {
    $ids = $existing.ProcessId | Sort-Object -Unique
    Write-TraceLog ("Stopping existing watched backend processes: " + ($ids -join ", "))
    foreach ($id in ($ids | Sort-Object -Descending)) {
      Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
  }
}

$watchProc = Start-Process `
  -FilePath "cmd.exe" `
  -ArgumentList "/d", "/s", "/c", "node --watch -r ts-node/register/transpile-only -r tsconfig-paths/register src/main.ts" `
  -WorkingDirectory $backendDir `
  -RedirectStandardOutput $stdoutLog `
  -RedirectStandardError $stderrLog `
  -PassThru

Write-TraceLog "Launched traced watched backend. Wrapper PID=$($watchProc.Id)"

$events = New-Object System.Collections.ArrayList
$fsw = New-Object System.IO.FileSystemWatcher $srcDir, "*"
$fsw.IncludeSubdirectories = $true
$fsw.EnableRaisingEvents = $true

$action = {
  $line = "[{0}] FILE {1} {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"), $Event.SourceEventArgs.ChangeType, $Event.SourceEventArgs.FullPath
  Add-Content -Path $using:traceLog -Value $line
}

$rChanged = Register-ObjectEvent $fsw Changed -Action $action
$rCreated = Register-ObjectEvent $fsw Created -Action $action
$rRenamed = Register-ObjectEvent $fsw Renamed -Action $action
$rDeleted = Register-ObjectEvent $fsw Deleted -Action $action

$deadline = (Get-Date).AddMinutes($DurationMinutes)
$lastProcessSignature = ""
$lastListenerSignature = ""

try {
  while ((Get-Date) -lt $deadline) {
    $procs = Get-WatchProcesses | Sort-Object ProcessId
    $procSignature = ($procs | ForEach-Object { "{0}:{1}" -f $_.ProcessId, $_.ParentProcessId }) -join "|"
    if ($procSignature -ne $lastProcessSignature) {
      $lastProcessSignature = $procSignature
      if ([string]::IsNullOrWhiteSpace($procSignature)) {
        Write-TraceLog "PROCESS No watched backend processes found."
      } else {
        Write-TraceLog ("PROCESS " + (($procs | ForEach-Object {
              "PID={0} PPID={1} NAME={2} CMD={3}" -f $_.ProcessId, $_.ParentProcessId, $_.Name, $_.CommandLine
            }) -join " || "))
      }
    }

    $listeners = Get-ListenerSnapshot | Sort-Object OwningProcess
    $listenerSignature = ($listeners | ForEach-Object { "{0}:{1}" -f $_.State, $_.OwningProcess }) -join "|"
    if ($listenerSignature -ne $lastListenerSignature) {
      $lastListenerSignature = $listenerSignature
      if ([string]::IsNullOrWhiteSpace($listenerSignature)) {
        Write-TraceLog "PORT No listener on 3001."
      } else {
        Write-TraceLog ("PORT " + (($listeners | ForEach-Object {
              "STATE={0} PID={1} ADDR={2}:{3}" -f $_.State, $_.OwningProcess, $_.LocalAddress, $_.LocalPort
            }) -join " || "))
      }
    }

    Start-Sleep -Seconds 1
  }
}
finally {
  Unregister-Event -SourceIdentifier $rChanged.Name -ErrorAction SilentlyContinue
  Unregister-Event -SourceIdentifier $rCreated.Name -ErrorAction SilentlyContinue
  Unregister-Event -SourceIdentifier $rRenamed.Name -ErrorAction SilentlyContinue
  Unregister-Event -SourceIdentifier $rDeleted.Name -ErrorAction SilentlyContinue
  $fsw.Dispose()
  Write-TraceLog "Trace session finished."
  Write-TraceLog "Stdout log: $stdoutLog"
  Write-TraceLog "Stderr log: $stderrLog"
}
