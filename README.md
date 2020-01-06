# PsRepositoryBootstrap

Powershell repository bootstrap (Import-OriPsModule) to hide logic behind integration PowerShell Repository with DevOps nuget source

## Motivation

We need to have a source for our PowerShell modules authenticated via Azure Active Directory or some other seemless way from local machines. On servers we want to use manage identity to access the modules.

We want to use built-in commandlets like [Install-Module](https://docs.microsoft.com/en-us/powershell/module/powershellget/install-module) ( [Register-PsRepository](https://docs.microsoft.com/en-us/powershell/module/powershellget/register-psrepository),...)

We want to make consumption of our PowerShell modules easy and straitghforward on "client" side, e.g. custom scripts used during build or client-side tools.

## About 

This bootstrap provides a simple way how to install a module from our custom repository and use it on a machine under a user with Azure Active Directory access.

Use it like:

    if (!(Get-Command -name Import-OriPsModule)){iwr -useBasicParsing -url {TBD}|iex}
    Import-OriPsModule -name MyCustomModule -requiredVersion 1.2

The above command will take care of every necessary steps like:

1. Checks if required module is already loaded with a required (or higher) version
2. ... if not, tryes to import required version from installed modules
3. If the loaded module version is still lower or missing (it is not installed) it tries to install it:
4. Checks for prerequisities like PS version, packagteManager version etc (check is done only once in a session lifetime once satisfied)
5. Installs necessary tools if needed (PowershellGet etc)
6. Registers repository if not yet
7. Installs the module
8. Loads required version of the module

TODO: it also installs latest version of PsRepositoryBootstrap if not installed
TODO: once a while (daily?) it checks for higher version of the PsRepositoryBootstrap module and installs it if available

## How to test

So far only local testing is supported. Navigate to /test folder and run .\test-locally.ps1 to download and execute Pester