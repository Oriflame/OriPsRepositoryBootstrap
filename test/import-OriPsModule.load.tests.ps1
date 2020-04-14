Get-Module -Name OriPsRepositoryBootstrap | Remove-Module;
Import-Module -Name "$PSScriptRoot\..\src\OriPsRepositoryBootstrap.psd1";

Describe 'Testing Import-OriPsModule' {
    InModuleScope OriPsRepositoryBootstrap {
        $numCalls = @{ [Version]"0.9.0" = 0; [Version]"1.0.0" = 0; [Version]"1.1.0" = 0 };
        $numCallsUntilTrue = @{ [Version]"0.9.0" = 0; [Version]"1.0.0" = 1; [Version]"1.1.0" = 2 };

        Mock Test-GetModule { 
            if ($numCallsUntilTrue[$RequiredVersion] -ne $numCalls[$RequiredVersion]) {
                $numCalls[$RequiredVersion] = $numCalls[$RequiredVersion] + 1;
                return $false;
            }

            return $true;
        };
        Mock Import-Module { };
        Mock Install-Module { };
        Mock Invoke-RegisterOriflameFeeds { };
        Mock Test-OriPsRepositoryBootstrapModuleInstalled { };

        It "Module is already imported" {
            Import-OriPsModule -Name "someModule" -RequiredVersion "0.9.0";
            Assert-MockCalled -CommandName Test-GetModule -Times 1 -Exactly -Scope It;
            Assert-MockCalled -CommandName Import-Module -Times 0 -Exactly -Scope It;
            Assert-MockCalled -CommandName Install-Module -Times 0 -Exactly -Scope It;
            Assert-MockCalled -CommandName Invoke-RegisterOriflameFeeds -Times 0 -Exactly -Scope It;
        } 

        It "Module needs to be imported" {
            Import-OriPsModule -Name "someModule" -RequiredVersion "1.0.0";
            Assert-MockCalled -CommandName Test-GetModule -Times 2 -Exactly -Scope It;
            Assert-MockCalled -CommandName Import-Module -Times 1 -Exactly -Scope It;
            Assert-MockCalled -CommandName Install-Module -Times 0 -Exactly -Scope It;
            Assert-MockCalled -CommandName Invoke-RegisterOriflameFeeds -Times 0 -Exactly -Scope It;
        }

        It "Module needs to be installed" {
            Import-OriPsModule -Name "someModule" -RequiredVersion "1.1.0";
            Assert-MockCalled -CommandName Test-GetModule -Times 2 -Exactly -Scope It;
            Assert-MockCalled -CommandName Import-Module -Times 2 -Exactly -Scope It;
            Assert-MockCalled -CommandName Install-Module -Times 1 -Exactly -Scope It;
            Assert-MockCalled -CommandName Invoke-RegisterOriflameFeeds -Times 2 -Exactly -Scope It;
        }
    }
}

Describe 'Testing Test-GetModule' {
    InModuleScope OriPsRepositoryBootstrap {
        Mock Get-Module { return @{ Version = [Version]"1.0.0" }; } -ParameterFilter { $Name -and $Name -eq "ImportedModule" };
        Mock Get-Module { return @{ Version = [Version]"0.9.0" }; } -ParameterFilter { $Name -and $Name -eq "NotImportedModule" };

        It "Module is already imported" {
            Test-GetModule -Name "ImportedModule" -RequiredVersion "0.9.0" | Should -Be $true;
        }

        It "Module is not yet imported" {
            Test-GetModule -Name "NotImportedModule" -RequiredVersion "1.0.0" | Should -Be $false;
        }
    }
}

Describe 'Testing Invoke-RegisterOriflameFeeds' {
    InModuleScope OriPsRepositoryBootstrap {
        Context "No registered package feeds" {
            It "PowerShellGet is not installed" {
                Mock Test-GetModule { return $false; };
                Mock Install-Module;
                Mock Get-PSRepository { return @(); };
                Mock Register-PSRepository

                Invoke-RegisterOriflameFeeds -Feeds @();
                Assert-MockCalled -CommandName Test-GetModule -Times 1 -Exactly;
                Assert-MockCalled -CommandName Install-Module -Times 1 -Exactly;
                Assert-MockCalled -CommandName Get-PSRepository -Times 1 -Exactly;
                Assert-MockCalled -CommandName Register-PSRepository -Times 0 -Exactly;
            }
        }

        Context "Required to register new feed - the required feed is not installed" {
            It "Should register requested feed" {
                Mock Test-GetModule { return $true; };
                Mock Install-Module
                Mock Get-PSRepository { return @([PSCustomObject]@{ SourceLocation = "https://pkgs.dev.azure.com/oriflame/_packaging/PackageManagementFeed/nuget/v2" }) };
                Mock Register-PSRepository { };

                Invoke-RegisterOriflameFeeds -Feeds @( "GlobalDev" );
                Assert-MockCalled -CommandName Test-GetModule -Times 1 -Exactly;
                Assert-MockCalled -CommandName Install-Module -Times 0 -Exactly;
                Assert-MockCalled -CommandName Get-PSRepository -Times 1 -Exactly;
                Assert-MockCalled -CommandName Register-PSRepository -Times 1 -Exactly;
            }
        }

        Context "Required to register new feed - the required feed is already installed" {
            It "Should skip register requested feed" {
                Mock Test-GetModule { return $true; };
                Mock Install-Module
                Mock Get-PSRepository { return @([PSCustomObject]@{ SourceLocation = "https://pkgs.dev.azure.com/oriflame/_packaging/PackageManagementFeed/nuget/v2" }) };
                Mock Register-PSRepository { };

                Invoke-RegisterOriflameFeeds -Feeds @( "PackageManagementFeed" );
                Assert-MockCalled -CommandName Test-GetModule -Times 1 -Exactly;
                Assert-MockCalled -CommandName Install-Module -Times 0 -Exactly;
                Assert-MockCalled -CommandName Get-PSRepository -Times 1 -Exactly;
                Assert-MockCalled -CommandName Register-PSRepository -Times 0 -Exactly;
            }
        }
    }
}