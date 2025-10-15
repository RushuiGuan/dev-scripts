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

function Use-Filter(
	[parameter(Mandatory = $false)]
	[string[]]
	$items,
	[parameter(Mandatory = $false)]
	[string[]]
	$patterns = @()
) {
	if($null -eq $items) {
		return @();
	}
	if ($patterns.Count -eq 0) {
		return $items;
	}
	$result = @();
	foreach ($item in $items) {
		foreach ($pattern in $patterns) {
			if ($item -like $pattern) {
				$result += $item;
				break;
			}
		}
	}
	return $result;
}