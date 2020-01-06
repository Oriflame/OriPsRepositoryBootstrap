
Import-Module -Name "$PSScriptRoot\..\src\PsRepositoryBootstrap.psd1"

It "without mandatory parameter Name exception expected" {
    #this should throw an error
    { Import-OriPsModule } | Should Throw
} 


It "without mandatory parameter RequiredVersion exception expected" {
    #this should throw an error
    {Import-OriPsModule -Name "someModule"} | Should Throw
} 


It "with all mandatory parameters should be OK" {
    Import-OriPsModule -Name "PsRepositoryBootstrap" -RequiredVersion 1.0.0
} 


It "must replace lower version" {
    Mock -CommandName Get-Module -MockWith { @{Version=[Version]'0.9.0'}}
    Import-OriPsModule -Name "PsRepositoryBootstrap" -RequiredVersion 1.0.0
}