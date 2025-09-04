$InformationPreference = "Continue";
$ErrorActionPreference = "Stop";
Set-StrictMode -Version Latest;

. $PSScriptRoot\shared.ps1;

function FindAndKillTerminalTab([System.Diagnostics.Process]$process) {
	$diff = [datetime]::MaxValue.Ticks;
	[System.Diagnostics.Process]$openConsoleProcess;
	Get-Process "OpenConsole" | ForEach-Object {
		$gap = $process.StartTime.Ticks - $_.StartTime.Ticks;
		if ($gap -ge 0 -and $diff -gt $gap -and $gap -lt 1000000) {
			$diff = $gap;
			$openConsoleProcess = $_;
		}
	}
	if ($openConsoleProcess) {
		Write-Information "Killing the terminal window tab $($openConsoleProcess.ProcessName) $($openConsoleProcess.Id)";
		Stop-Process -Id $openConsoleProcess.Id -Force;
		Start-Sleep -Seconds 0.1;
	}
	Write-Information "Stopping process $($process.ProcessName)";
	Stop-Process -Id $process.Id -Force;
	Start-Sleep -Seconds 0.1;
}

function KillProcess([System.Diagnostics.Process]$process) {
	[System.Diagnostics.Process]$parentProcess = $process.Parent;
	if ($parentProcess -and $parentProcess.ProcessName -eq "WindowsTerminal") {
		FindAndKillTerminalTab $process;
	}
	else {
		Write-Information "Stopping process $($process.ProcessName)";
		Stop-Process -Id $process.Id -Force;
		Start-Sleep -Seconds 0.1;
		Write-Output $process.ProcessName;
	}
}
