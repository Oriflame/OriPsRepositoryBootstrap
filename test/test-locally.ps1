get-module -Name PsRepositoryBootstrap | remove-module 

Import-Module -Name Pester -ea SilentlyContinue;

if (!(Get-Module -Name Pester)) {Install-Module -Name Pester -Force}

PowerShell.exe -noninteractive {Import-Module -Name Pester;Invoke-Pester}
