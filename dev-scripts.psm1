$InformationPreference = "Continue";
$ErrorActionPreference = "Stop";
Set-StrictMode -Version Latest;

. $PSScriptRoot/shared.ps1;
. $PSScriptRoot/process.ps1;
. $PSScriptRoot/pack.ps1;
. $PSScriptRoot/build.ps1;
. $PSScriptRoot/release.ps1;
