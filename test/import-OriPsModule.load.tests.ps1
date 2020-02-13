Get-Module -Name PsRepositoryBootstrap | Remove-Module;
Import-Module -Name "$PSScriptRoot\..\src\PsRepositoryBootstrap.psd1";

Describe 'Testing Import-OriPsModule' {
    InModuleScope PsRepositoryBootstrap {
        $numCalls          = @{ "0.9.0" = 0; "1.0.0" = 0; "1.1.0" = 0 };
        $numCallsUntilTrue = @{ "0.9.0" = 0; "1.0.0" = 1; "1.1.0" = 2 };

        Mock Test-GetModule { 
            if($numCallsUntilTrue[$RequiredVersion] -ne $numCalls[$RequiredVersion]) {
                $numCalls[$RequiredVersion] = $numCalls[$RequiredVersion] + 1;
                return $false;
            }

            return $true;
        }
        Mock Import-Module {}
        Mock Install-Module {}
        Mock Invoke-RegisterOriflameFeeds {}

        It "Parameter validation: Missing [Name] and [RequiredVersion]" {
            Import-OriPsModule | Should Throw;
        }

        It "Parameter validation: Missing [RequiredVersion]" {
            Import-OriPsModule -Name "someModule" | Should Throw;
        }

        It "Module is already imported" {
            Import-OriPsModule -Name "someModule" -RequiredVersion 0.9.0 -Verbose;
            Assert-MockCalled -CommandName Test-GetModule -Times 1 -Exactly;
            Assert-MockCalled -CommandName Import-Module -Times 0 -Exactly;
            Assert-MockCalled -CommandName Install-Module -Times 0 -Exactly;
            Assert-MockCalled -CommandName Invoke-RegisterOriflameFeeds -Times 0 -Exactly;
        } 

        It "Module needs to be imported" {
            Import-OriPsModule -Name "someModule" -RequiredVersion 1.0.0 -Verbose;
            Assert-MockCalled -CommandName Test-GetModule -Times 1 -Exactly;
            Assert-MockCalled -CommandName Import-Module -Times 1 -Exactly;
            Assert-MockCalled -CommandName Install-Module -Times 0 -Exactly;
            Assert-MockCalled -CommandName Invoke-RegisterOriflameFeeds -Times 0 -Exactly;
        }

        It "Module needs to be installed" {
            Import-OriPsModule -Name "someModule" -RequiredVersion 1.1.0 -Verbose;
            Assert-MockCalled -CommandName Test-GetModule -Times 2 -Exactly;
            Assert-MockCalled -CommandName Import-Module -Times 1 -Exactly;
            Assert-MockCalled -CommandName Install-Module -Times 1 -Exactly;
            Assert-MockCalled -CommandName Invoke-RegisterOriflameFeeds -Times 1 -Exactly;
        }
    }
}

Describe 'Testing Test-GetModule' {
    InModuleScope PsRepositoryBootstrap {
        Mock Get-Module { return $true; } -ParameterFilter { $RequiredVersion -and $RequiredVersion -eq "0.9.0" };
        Mock Get-Module { return $false; } -ParameterFilter { $RequiredVersion -and $RequiredVersion -eq "1.0.0" };

        It "Module is already imported" {
            Test-GetModule -Name "someModule" -RequiredVersion 0.9.0 -Verbose | Should -Be $true;
        }

        It "Module is not yet imported" {
            Test-GetModule -Name "someModule" -RequiredVersion 1.0.0 -Verbose | Should -Be $false;
        }
    }
}