$InformationPreference = "Continue";
$ErrorActionPreference = "Stop";
Set-StrictMode -Version Latest;

. $PSScriptRoot\shared.ps1;
. $PSScriptRoot\process.ps1;

function Build(
	[parameter(Mandatory = $true)]
	[System.IO.DirectoryInfo]
	$directory
) {
	$root = Resolve-Path -Path $directory;

	if (-not [System.IO.Directory]::Exists($root)) {
		Write-Error "Directory $root does not exist"
	}

	if (-not [System.IO.File]::Exists((Join $root, .projects))) {
		Write-Error ".projects file not found"
	}

	$apps = devtools project list -f (Join $root, .projects) -h apps
	Write-Information "apps: $($apps -join ', ')"

	foreach ($app in $apps) {
		$csproj = Get-ProjectRoot -root $root -project $app;
		Write-Information "Building $app at $csproj";
		Invoke-Strict dotnet publish $csproj -c Release --output (Join $env:DevDirectory, $app)
	}
}

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