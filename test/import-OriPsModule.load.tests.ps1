
Get-Module -Name PsRepositoryBootstrap | Remove-Module

Import-Module -Name "$PSScriptRoot\..\src\PsRepositoryBootstrap.psd1"

Describe 'Simple-Imports' {

    InModuleScope PsRepositoryBootstrap {

        Mock Get-Module { return @{Version=[Version]'0.9.0'}}
        Mock Import-Module {} -Verifiable -ParameterFilter {$name -eq "someModule"}
        Mock Get-PackageProvider { return @{Version=[Version]'2.2.3.0'}}
        Mock Install-PackageProvider {} -Verifiable
        Mock Get-PackageSource {}
        Mock Register-PackageSource {}
        Mock Install-Module {}

        It "without mandatory parameter Name exception expected" {
            #this should throw an error
            { Import-OriPsModule } | Should Throw
        } 


        It "without mandatory parameter RequiredVersion exception expected" {
            #this should throw an error
            {Import-OriPsModule -Name "someModule"} | Should Throw
        } 


        It "with all mandatory parameters should be OK" {
            Import-OriPsModule -Name "someModule" -RequiredVersion 0.9.0 -Verbose
            Assert-MockCalled -CommandName Import-Module -Times 0 -Exactly
        } 


        It "must replace lower version" {
            Import-OriPsModule -Name "someModule" -RequiredVersion 1.0.0 -Verbose
            Assert-MockCalled -CommandName Import-Module -Times 2 -Exactly  #one for first import which returns nothing, second for import after install
            Assert-MockCalled -CommandName Get-PackageProvider -Times 1 -Exactly
            Assert-MockCalled -CommandName Install-PackageProvider -Times 0 -Exactly
            Assert-MockCalled -CommandName Install-Module -Times 1 -Exactly
        }
    }
}

Describe 'RepositoryInstall-checks' {

    InModuleScope PsRepositoryBootstrap {

        Mock Get-Module { return @{Version=[Version]'0.9.0'}}
        Mock Import-Module {}
        Mock Get-PackageProvider { return @{Version=[Version]'2.2.2.9'}}
        Mock Install-PackageProvider {} -Verifiable -ParameterFilter {$Name -eq "PowerShellGet"}
        Mock Get-PackageSource {}
        Mock Register-PackageSource {} -Verifiable
        Mock Install-Module {} -Verifiable

        It "Check installation of PowerShellGet provider" {
            Import-OriPsModule -Name "someModule" -RequiredVersion 1.0.0 -Verbose
            Assert-MockCalled -CommandName Install-PackageProvider -Times 1 -Exactly
            Assert-MockCalled -CommandName Register-PackageSource -Times 1 -Exactly
            Assert-MockCalled -CommandName Install-Module -Times 1 -Exactly
        }
    }
}