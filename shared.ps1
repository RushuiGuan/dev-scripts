$InformationPreference = "Continue";
$ErrorActionPreference = "Stop";
Set-StrictMode -Version Latest;

function Invoke-Strict (
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$args
) {
	$cmd = [string]::Join(' ', $args);
	Invoke-Expression $cmd;
	if ($LASTEXITCODE -ne 0) {
		Write-Error "Command ""$args"" failed with exit code $LASTEXITCODE"
	}
}

function Join(
	[string[]]$array
) {
	return [System.IO.Path]::Join($array);
}