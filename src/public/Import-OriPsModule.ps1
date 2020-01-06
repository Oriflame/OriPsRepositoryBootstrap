
<#
.DESCRIPTION
    It does the following:
    1. Checks if required module is already loaded with a required (or higher) version
    2. ... if not, tryes to import required version from installed modules
    3. {TBD} If the loaded module version is still lower or missing (it is not installed) it tries to install it:
    4. {TBD} Checks for prerequisities like PS version, packagteManager version etc (check is done only once in a session lifetime once satisfied)
    5. {TBD} Installs necessary tools if needed (PowershellGet etc)
    6. {TBD} Registers repository if not yet
    7. {TBD} Installs the module
    8. {TBD} Loads required version of the module

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


    ################### 1. Checks if required module is already loaded with a required (or higher) version
    $currentlyLoadedModule = Get-Module -Name $Name -ea SilentlyContinue;
    if ($currentlyLoadedModule -eq $null -or $currentlyLoadedModule.version -le $RequiredVersion)
    {
        ################### 2. ... if not, tryes to import required version from installed modules
        Import-Module -Name $Name -RequiredVersion $RequiredVersion -ea SilentlyContinue;
        $currentlyLoadedModule = Get-Module -Name $Name -ea SilentlyContinue;
    }
    if ($currentlyLoadedModule -eq $null -or $currentlyLoadedModule.version -le $RequiredVersion)
    {
        ################### 3. {TBD} If the loaded module version is still lower or missing (it is not installed) it tries to install it:
        
        ################### 4. {TBD} Checks for prerequisities like PS version, packagteManager version etc (check is done only once in a session lifetime once satisfied)
        ################### 5. {TBD} Installs necessary tools if needed (PowershellGet etc)
        ################### 6. {TBD} Registers repository if not yet
        ################### 7. {TBD} Installs the module
        ################### 8. {TBD} Loads required version of the module
    }

    ########## self-installation of PsRepositoryBootstrap module ##########
    Import-Module -Name PsRepositoryBootstrap -ea SilentlyContinue;
    if (!(Get-Module -Name PsRepositoryBootstrap))
    {
        #PsRepositoryBootstrap not installed!
    }
}
