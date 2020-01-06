
Get-Module -Name PsRepositoryBootstrap | Remove-Module

Import-Module -Name "$PSScriptRoot\..\src\PsRepositoryBootstrap.psd1"

Describe 'Simple-Imports' {

    InModuleScope PsRepositoryBootstrap {

        Mock Get-Module { return @{Version=[Version]'0.9.0'}}
        Mock Import-Module {} -Verifiable -ParameterFilter {$name -eq "someModule"}

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
            Assert-MockCalled -CommandName Import-Module -Times 1 -Exactly
        }
    }
}