$InformationPreference = "Continue";
$ErrorActionPreference = "Stop";
Set-StrictMode -Version Latest;

. $PSScriptRoot\shared.ps1;

function Release(
	[parameter(Mandatory = $true)]
	[System.IO.DirectoryInfo]
	$directory,
	[switch]$commit
) {
	$root = Resolve-Path -Path $directory;

	if (-not [System.IO.Directory]::Exists($root)) {
		throw "Directory $root does not exist"
	}

	$version = Invoke-Strict devtools project property --property Version -f (Join $directory, "Directory.Build.props");
	$newVersion = Invoke-Strict devtools version build --version $version -clear-meta -pa
	$msg = "Update project version from $version to $newVersion";
	Write-Output $msg;
	Invoke-Strict devtools project set-version --directory $directory --version $newVersion --verbosity Information;
	if ($commit) {
		$current = Get-Location
		try {
			Set-Location $directory;
			Invoke-Strict git add (Join $directory, "Directory.Build.props");
			Invoke-Strict git commit -m "'$msg'";
		} finally {
			Set-Location $current;
		}
	}
}

