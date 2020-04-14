function Import-OriPsModule {
    <#
    .SYNOPSIS
        Install PowerShell module from online gallery.

    .DESCRIPTION
        This cmdlet will try to install PowerShell module from online gallery.

        It does the following:
        1. Checks if required module is already loaded with a required (or higher) version.
        2. If not, tryes to import required version from installed modules.
        3. If the loaded module version is still lower or missing (it is not installed) it tries to install it
        4. Checks for prerequisities like PS version, PackageManager version etc
        5. Installs necessary tools if needed
        6. Registers repository if not yet
        7. Installs the module
        8. Loads required version of the module

    .PARAMETER Name
        Specifies the exact names of modules to install from the online gallery. The module name must match the module name in the repository.
        
    .PARAMETER RequiredVersion
        Specifies the exact version of a single module to install.
    #>
    [CmdLetBinding()]
    param (
        [parameter(Mandatory = $true, HelpMessage = "Exact name of the mmodule")]
        [string] $Name,

        [parameter(Mandatory = $true, HelpMessage = "Minimum required module version")]
        [Version] $RequiredVersion
    )

    Test-OriPsRepositoryBootstrapModuleInstalled;

    # Required module is already imported
    if (Test-GetModule -Name $Name -RequiredVersion $RequiredVersion) {
        Write-Verbose "Module $Name is already imported.";
        return;
    }

    # Required module is installed, but not imported
    Import-Module -Name $Name -RequiredVersion $RequiredVersion -ea SilentlyContinue;

    if (Test-GetModule -Name $Name -RequiredVersion $RequiredVersion) { 
        Write-Verbose "Module $Name was imported from installed modules.";
        return;
    }

    # Required module needs to be installed and impoted
    "GlobalDev", "PackageManagementFeed" | Invoke-RegisterOriflameFeeds
    Install-Module -Name $Name -RequiredVersion $RequiredVersion -Force;
    Import-Module -Name $Name -RequiredVersion $RequiredVersion;
}

function Test-OriPsRepositoryBootstrapModuleInstalled {
    <#
    .SYNOPSIS
        Checks, whether OriPsRepositoryBootstrap is installed and if not, installs it.
    #>
    [CmdLetBinding()]
    param()
    $oriPsModuleName = 'OriPsRepositoryBootstrap';
    $RequiredVersion = '1.0';
    $LastCheckRegName = 'last-version-check';
    
    $LastCheckValue = Get-RegistrySetting -Name $LastCheckRegName;

    [datetime]$lastCheck = [datetime]::UtcNow;
    $shouldWeForceInstallAnyway = $false;
    if ($null -ne $LastCheckValue -and [DateTime]::TryParseExact($LastCheckValue, 'o', [CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$lastCheck)) {
        $shouldWeForceInstallAnyway = $lastCheck -le [datetime]::UtcNow.AddDays(-1);
    }

    if (!(Test-GetModule -Name $oriPsModuleName -RequiredVersion $RequiredVersion) -or $shouldWeForceInstallAnyway) {
        # following will ensure installation to C:\Program Files\WindowsPowerShell\Modules and thus availability in all future sessions
        Install-Module -Name $oriPsModuleName -MinimumVersion $RequiredVersion -Force -Scope AllUsers -AcceptLicense -Repository PSGallery;
    }

    Set-RegistrySetting -Name $LastCheckRegName -Value ([datetime]::UtcNow.ToString('o', [CultureInfo]::InvariantCulture))
}

function Get-RegistrySetting {
    <#
    .SYNOPSIS
        returns registry setting for OriPsRepositoryBootstrap
    #>
    [CmdLetBinding()]
    param (
        [parameter(Mandatory = $true, HelpMessage = "Name of the setting")]
        [string] $Name
    )

    if (-not (Test-Path -LiteralPath $Script:RegistrySettingPath)) {
        New-Item -Path $Script:RegistrySettingPath -Force | Out-Null
    }

    try {
        Get-ItemProperty $Script:RegistrySettingPath -Name $Name -ErrorAction Stop |
        Select-Object -Expand $Name
    }
    catch {
        $null;
    }
}

function Set-RegistrySetting {
    <#
    .SYNOPSIS
        Sets registry setting for OriPsRepositoryBootstrap
    #>
    [CmdLetBinding()]
    param (
        [parameter(Mandatory = $true, HelpMessage = "Name of the setting")]
        [string] $Name,

        [parameter(Mandatory = $true, HelpMessage = "Value of the setting")]
        $Value
    )

    if (-not (Test-Path -LiteralPath $Script:RegistrySettingPath)) {
        New-Item -Path $Script:RegistrySettingPath -Force | Out-Null
    }

    Set-ItemProperty $Script:RegistrySettingPath -Name $Name -Value $Value
}

function Test-GetModule {
    <#
    .SYNOPSIS
        Checks, whether specified module is installed.
    #>
    [CmdLetBinding()]
    [OutputType([bool])]
    param (
        [parameter(Mandatory = $true, HelpMessage = "Exact name of the mmodule")]
        [string] $Name,

        [parameter(Mandatory = $true, HelpMessage = "Minimum required module version")]
        [Version] $RequiredVersion
    )

    $module = Get-Module -Name $Name -ea SilentlyContinue;

    $null -ne $module -and $module.version -ge $RequiredVersion;
}

function Invoke-RegisterOriflameFeeds {
    <#
    .SYNOPSIS
        Register required NuGet feeds from Oriflame artifact sources.
    .NOTES
        This cmdlet also install PowerShellGet module, if required.
    #>
    [CmdLetBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, HelpMessage = "List of Oriaflame NuGet feeds to register (eg. GlobalDev, PackageManagementFeed).")]
        [string[]] $feeds
    )
    begin {
        if (!(Test-GetModule -Name PowerShellGet -RequiredVersion 2.2.3)) {
            Write-Verbose "Updating PowerShellGet module to the latest version.";
            Install-Module -Name PowerShellGet -Force;
        }

        $registeredFeeds = Get-PSRepository | Select-Object -Expand SourceLocation;
    }
    process {
        foreach ($feed in $feeds) {
            if ($registeredFeeds -like "*/$feed/*") {
                continue;
            }
    
            Write-Verbose "Register $feed NuGet feed.";
            Register-PSRepository -Name $feed -SourceLocation https://pkgs.dev.azure.com/oriflame/_packaging/$feed/nuget/v2 -InstallationPolicy Trusted
        }
    }
}

$Script:RegistrySettingPath = 'HKLM:\Software\Oriflame\PsModules\OriPsRepositoryBootstrap';