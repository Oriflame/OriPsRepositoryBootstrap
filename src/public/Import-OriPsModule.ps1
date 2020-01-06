<#
.DESCRIPTION
    It does the following:
    1. Checks if required module is already loaded with a required (or higher) version
    2. ... if not, tryes to import required version from installed modules
    3. If the loaded module version is still lower or missing (it is not installed) it tries to install it:
    4. Checks for prerequisities like PS version, packagteManager version etc (check is done only once in a session lifetime once satisfied)
    5. Installs necessary tools if needed (PowershellGet etc)
    6. Registers repository if not yet
    7. Installs the module
    8. Loads required version of the module

.PAREMETER Name
    Specifies the exact names of modules to install from the online gallery. The module name must match the module name in the repository.
    {TBD:A comma-separated list of module names is accepted. }
	
.PAREMETER RequiredVersion
	Specifies the exact version of a single module to install. If there is no match in the repository for the specified version, an error is displayed. If you want to install multiple modules, you cannot use RequiredVersion. 

#>
function Import-OriPsModule
{
    [CmdLetBinding()]
    param
    (
        [parameter(Mandatory=$true,
            HelpMessage="Specify the exact name of module to install from the online gallery")]  #{TBD: A comma-separated list of module names is accepted}
	    [string]
        $Name,
    
        [parameter(Mandatory=$true,
            HelpMessage="Specifiy the exact version of a single module to install")]
        [string]
        $RequiredVersion
    )

    $ErrorActionPreference='Stop';
    $PsRepositoryName = 'DevOpsPackageSrc';

    Write-Verbose "Trying to load module [$Name] with version [$RequiredVersion]."

    ################### 1. Checks if required module is already loaded with a required (or higher) version
    $currentlyLoadedModule = Get-Module -Name $Name -ea SilentlyContinue;
    if ($currentlyLoadedModule -eq $null -or $currentlyLoadedModule.version -lt [Version]$RequiredVersion)
    {
        ################### 2. ... if not, tryes to import required version from installed modules
        Write-Debug "Module version currently loaded: [$($currentlyLoadedModule.version)]"
        Import-Module -Name $Name -RequiredVersion $RequiredVersion -ea SilentlyContinue;
        $currentlyLoadedModule = Get-Module -Name $Name -ea SilentlyContinue;
    }
    if ($currentlyLoadedModule -eq $null -or $currentlyLoadedModule.version -lt $RequiredVersion)
    {
        ################### 3. If the loaded module version is still lower or missing (it is not installed) it tries to install it:
        Write-Verbose "Module not found or version is lesser then required [$($currentlyLoadedModule.version)] so we need to install it. Now checking pre-requisites..."

        ################### 4. Checks for prerequisities like PS version, packageManager version etc (check is done only once in a session lifetime once satisfied)
        $currentPowershellGetProviderVersion = (Get-PackageProvider -Name PowerShellGet -ea SilentlyContinue).Version;
        if ($currentPowershellGetProviderVersion -eq $null -or $currentPowershellGetProviderVersion -lt [version]'2.2.3.0')
        {
            ################### 5. Installs necessary tools if needed (PowershellGet etc)
            Install-PackageProvider -Name PowerShellGet -MinimumVersion 2.2.3.0;
        }

        ################### 6. Registers repository if not yet
        $currentDevOpsRepo = Get-PackageSource -Name $PsRepositoryName -ProviderName PowerShellGet -ea SilentlyContinue;
        if ($currentDevOpsRepo -eq $null)
        {
            Register-PackageSource -Name $PsRepositoryName -Location https://pkgs.dev.azure.com/oriflame/_packaging/GlobalDev/nuget/v3/index.json -Trusted -ProviderName PowerShellGet
        }

        ################### 7. Installs the module
        Install-Module -Name $Name -RequiredVersion $RequiredVersion -Repository $PsRepositoryName;

        ################### 8. Loads required version of the module
        Import-Module -Name $Name -RequiredVersion $RequiredVersion;
    }

    ########## self-installation of PsRepositoryBootstrap module ##########
    #Import-Module -Name PsRepositoryBootstrap -ea SilentlyContinue;
    #if (!(Get-Module -Name PsRepositoryBootstrap))
    #{
    #    #PsRepositoryBootstrap not installed!
    #}
}
