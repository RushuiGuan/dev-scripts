$InformationPreference = "Continue";
$ErrorActionPreference = "Stop";
Set-StrictMode -Version Latest;

function Invoke-Strict (
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$args
) {
	if(-not $args -or $args.Length -eq 0){
		Write-Error "No command has been provided";
	}
	$cmd = $args[0];
	$resolved = Get-Command -Name $cmd -ErrorAction SilentlyContinue;
	if($resolved -and $resolved.CommandType -eq 'Alias'){
		$cmd = $resolved.Definition;
	}
	if($args.Length -gt 1){
		$params = $args[1..($args.Length -1)];
	}else {
		$params = @();
	}
	
	& $cmd @params;
	
	if ($LASTEXITCODE -ne 0) {
		$text = $args -join ' ';
		Write-Error "Command ""$text"" failed with exit code $LASTEXITCODE"
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

function Confirm-NonProdDotNetEnvironment{
	if ($env:ASPNETCORE_ENVIRONMENT -eq "production" `
			-or $env:ASPNETCORE_ENVIRONMENT -eq "prod")	{
		# Write-Error "!!!FULL STOP!!! Current ASPNETCORE_ENVIRONMENT is PRODUCTION";
	}

	if ($env:DOTNET_ENVIRONMENT -eq "production" `
			-or $env:DOTNET_ENVIRONMENT -eq "prod")	{
		Write-Error "!!!FULL STOP!!! Current DOTNET_ENVIRONMENT is PRODUCTION";
	}
}