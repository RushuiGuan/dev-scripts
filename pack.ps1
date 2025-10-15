$InformationPreference = "Continue";
$ErrorActionPreference = "Stop";
Set-StrictMode -Version Latest;

. $PSScriptRoot\shared.ps1;

function Pack(
		[parameter(Mandatory = $true)]
		[System.IO.DirectoryInfo]
		$directory,
		[switch]
		[bool]$skipTest,
		[switch]
		[bool]$prod,
		[switch]
		[bool]$tag
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
	Write-Information "Projects: $($projects -join ', ')"

	if (-not $skipTest) {
		# run the test projects
		foreach ($item in $testProjects) {
			$csproj = Get-ProjectRoot -root $root -project $item;
			"Testing $item at $csproj";
			Invoke-Strict dotnet test $csproj -c release
		}
	}

	if ($projects.Length -eq 0) {
		Write-Information "Nothing to do";
		return;	
	}

	$isDirty = $false;
	devtools git is-dirty -d $root
	if ($LASTEXITCODE -ne 0) {
		$isDirty = $true;
	}

	# if $prod is true or $tag is true, do not proceed if the directory is dirty
	if (($tag -or $prod) -and $isDirty) {
		Write-Error "Directory has uncomitted changes. Please commit or stash changes before proceeding with a prod build"
	}
	$oldVersion = Invoke-Strict devtools project property --project-file (Join $root, Directory.Build.props) --property Version
	$version = Invoke-Strict devtools project version --directory-build-props --directory $root --prod="$prod"
	try {
		# first clean up the artifacts folder
		Write-Information "Cleaning up artifacts folder: $(Join $root, artifacts)";
		if (-not [System.IO.Directory]::Exists((Join $root, artifacts))) {
			New-Item -ItemType Directory -Path (Join $root, artifacts)
		}
		else {
			Get-ChildItem (Join $root, artifacts, *.nupkg) | Remove-Item -Force
		}
		Write-Information "Version: $version";
		Invoke-Strict devtools project set-version --directory $root --version $version
	
		$repositoryProjectRoot = Invoke-Strict devtools project property --project-file (Join $root, Directory.Build.props) --property RepositoryUrl
		$repositoryProjectRoot = $repositoryProjectRoot + "/tree/main/README.md";

		foreach ($project in $projects) {
			# first fix the README.md file
			$readme = (Join $root, $project, README.md);
			$tmp = [System.IO.Path]::GetTempFileName()
			Copy-Item $readme $tmp -Force
			try {
				if ([System.IO.File]::Exists($readme)) {
					Invoke-Strict devtools project fix-markdown-relative-urls --markdown-file $readme --root-folder $root --root-url $repositoryProjectRoot
				}
				"Building $project";
				Invoke-Strict dotnet pack (Join $root, $project, "$project.csproj") --configuration release --output (Join $root, artifacts)
			}
			finally {
				Copy-Item $tmp $readme -Force
				Remove-Item $tmp -Force
			}
		}
		Invoke-Strict devtools project set-version --directory $root --version $oldVersion
		if ($tag -and $projects.Length -ne 0) {
			$directoryName = Split-Path $root -Leaf
			$version = Invoke-Strict devtools version build --version $version --clear-metadata
			$tagText = "$directoryName-$version";
			Write-Information "Tagging $tagText";
			Invoke-Strict git tag $tagText;
			if ($prod) {
				#if it is a prod build and tagged, bump the version to the next patch
				$version = Invoke-Strict devtools version build --version $version --next-patch -clear-pre -clear-meta
				Invoke-Strict devtools project set-version --directory $root --version $version
				Invoke-Strict devtools xml format --xml-file (Join $root, Directory.Build.props)
				Invoke-Strict git commit -m "'Bump version of $directoryName to $version'" (Join $root, Directory.Build.props);
			}
		}
	}
	finally {
		Invoke-Strict devtools xml format --xml-file (Join $root, Directory.Build.props)
		Get-ChildItem (Join $root, *.csproj) -recurse | ForEach-Object { 
			Invoke-Strict devtools xml format --xml-file $_.FullName
		}
	}
}