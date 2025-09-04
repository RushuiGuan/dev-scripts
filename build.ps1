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
	else {
		Write-Information "Project directory: $root"
	}

	if (-not [System.IO.File]::Exists((Join $root, .projects))) {
		Write-Error ".projects file not found"
	}

	$testProjects = devtools project list -f (Join $root, .projects) -h tests
	Write-Information "Test projects: $($testProjects -join ', ')"

	$projects = devtools project list -f (Join $root, .projects) -h packages
	Write-Information "packages: $($projects -join ', ')"

	$projects = devtools project list -f (Join $root, .projects) -h projects
	Write-Information "projects: $($projects -join ', ')"

	$services = devtools project list -f (Join $root, .projects) -h services
	Write-Information "Services: $($services -join ', ')"

	if ($projects.Length -eq 0) {
		Write-Information "Nothing to do";
		return;	
	}
}