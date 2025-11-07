$InformationPreference = "Continue";
$ErrorActionPreference = "Stop";
Set-StrictMode -Version Latest;

. $PSScriptRoot\shared.ps1;
. $PSScriptRoot\process.ps1;

function Get-ProjectRoot(
	[string]$root,
	[string]$project
) {
	$array = @(
		(join $root, $project, "$project.csproj"),
		(join $root, "src", $project, "$project.csproj")
	);
	foreach ($path in $array) {
		if (Test-Path $path) {
			return $path;
		}
	}
	throw "Project $project not found in $root"
}

function Build(
	[parameter(Mandatory = $true)]
	[System.IO.DirectoryInfo]
	$directory,
	[parameter(Mandatory = $false)]
	[string[]]
	$patterns = @(),
	[switch]$run
) {
	$root = Resolve-Path -Path $directory;

	if (-not [System.IO.Directory]::Exists($root)) {
		throw "Directory $root does not exist"
	}

	if (-not [System.IO.File]::Exists((Join $root, .projects))) {
		throw ".projects file not found"
	}

	# Write-Information "patterns: $patterns";

	$apps = devtools project list -f (Join $root, .projects) -h apps
	$apps = Use-Filter -items $apps -patterns $patterns
	# Write-Information "Found apps: $apps";

	$services = devtools project list -f (Join $root, .projects) -h services
	$services = Use-Filter -items $services -patterns $patterns
	# Write-Information "Found services: $services";

	foreach ($app in $apps) {
		$csproj = Get-ProjectRoot -root $root -project $app;
		Write-Information "Publishing $app at $csproj";
		Invoke-Strict dotnet publish $csproj -c Release --output (Join $env:InstallDirectory, $app)
	}

	foreach ($service in $services) {
		KillProcess -name $service
		$csproj = Get-ProjectRoot -root $root -project $service;
		Write-Information "Publishing $service at $csproj";
		Invoke-Strict dotnet publish $csproj -c Release --output (Join $env:InstallDirectory, $service)
	}
	if ($run) {
		RunProcess $services;
	}
}

