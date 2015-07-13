$module = (Split-Path -Leaf $PSCommandPath).Replace(".Tests.ps1", ".psm1")
$code = Get-Content $module | Out-String
# You have to comment out the Export-ModuleMember line or you will get an 
# error.
$code = $code -replace "Export-ModuleMember", "# Export-ModuleMember"

# Load the contents of the module into memory so we can test the code.
Invoke-Expression $code

Describe "Test Directory" {
    # Mock methods that are already tested
    Mock GetFiles { @{FullName="z:\web.config"} }
    Mock ProcessFile { }
    Context "finds single file but no token file" {
        Mock TestSingleFile { $false }
        It "should return false" {
            $tokens = @{place="World"}
            TestDirectory -path "z:\" -filter "*.config" -tokens $tokens -useTokenFiles $true | Should Be $false
            Assert-MockCalled TestSingleFile -Exactly 1
        }
    }
}

Describe "Test Single File" {
    Mock Get-Content { "Hello __place__" } -ParameterFilter { $Path -eq "z:\web.config.token" }
    Mock Get-Item { @{Attributes=[System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Archive; FullName="z:\web.config"} }
    Mock Set-Content { $args.GetValue(1) | Should Be "Hello World" }
    Mock Test-Path { $true } -ParameterFilter { $Path -eq "z:\web.config.token" }

    $tokens = @{place="World"}
    
    Context "is passed path to a file not processed" {
        Mock Get-Content { "Hello PowerShell" } -ParameterFilter { $Path -eq "z:\web.config" }
        It "should return false" {
            TestSingleFile -path "z:\web.config.token" -tokens $tokens -useTokenFiles $true | Should Be $false
        }
    }

    Context "is passed path to a processed file" {
        Mock Get-Content { "Hello World" } -ParameterFilter { $Path -eq "z:\web.config" }
        It "should return true" {
            TestSingleFile -path "z:\web.config" -tokens $tokens -useTokenFiles $true | Should Be $true
        }
    }

    Context "is passed path to a processed file but token file is missing" {
        Mock Get-Content { "Hello World" } -ParameterFilter { $Path -eq "z:\web.config" }
        It "should return true" {
            Mock Test-Path { $false } -ParameterFilter { $Path -eq "z:\web.config.token" }
            TestSingleFile -path "z:\web.config" -tokens $tokens -useTokenFiles $true | Should Be $true
        }
    }

    Context "is passed path to a processed file not using token files" {
        Mock Get-Content { "Hello World" } -ParameterFilter { $Path -eq "z:\web.config" }
        Mock Test-Path { $true } -ParameterFilter { $Path -eq "z:\web.config" }
        It "should return true" {
            TestSingleFile -path "z:\web.config" -tokens $tokens | Should Be $true
            Assert-MockCalled Test-Path -Exactly 1
        }
    }

    Context "is passed path to an unprocessed file not using token files" {
        Mock Test-Path { $true } -ParameterFilter { $Path -eq "z:\web.config" }
        Mock Get-Content { "Hello __place__" } -ParameterFilter { $Path -eq "z:\web.config" }
        It "should return false" {
            TestSingleFile -path "z:\web.config" -tokens $tokens | Should Be $false
            Assert-MockCalled Test-Path -Exactly 1
        }
    }
}

Describe "Process Directory" {
    # Mock methods that are already tested
    Mock GetFiles { @{FullName="z:\web.config"} }
    Mock ProcessFile { }
    
    Context "is passed path, filter, tokens and useTokenFiles switch" {
        It "process 1 file" {
            $tokens = @{place="World"}
            ProcessDirectory -path "z:\" -filter "*.config" -tokens $tokens -useTokenFiles $true
            Assert-MockCalled GetFiles -Exactly 1
            Assert-MockCalled ProcessFile -Exactly 1
        }
    }
}

Describe "Process Single File" {
    Mock Get-Content { "Hello __place__" }
    Mock Get-Item { @{Attributes=[System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Archive; FullName="z:\web.config"} }
    Mock Set-Content { $args.GetValue(1) | Should Be "Hello World" }
    
    Context "is passed file, tokens and useTokenFiles switch" {
        Mock Test-Path { $true } -ParameterFilter { $Path -eq "z:\web.config.token" }
        It "saves file" {
            $tokens = @{place="World"}
            ProcessSingleFile -path "z:\web.config" -tokens $tokens -useTokenFiles $true
            Assert-MockCalled Get-Item -Exactly 2
            Assert-MockCalled Get-Content -Exactly 1
            Assert-MockCalled Set-Content -Exactly 1
        }
    }    

    Context "is passed file, tokens and useTokenFiles switch but token file does not exist" {
        # Token file should not be found so return false
        Mock Test-Path { $false }
        It "should write error" {
            $tokens = @{place="World"}
            ProcessSingleFile -path "z:\web.config" -tokens $tokens -useTokenFiles $true
            Assert-MockCalled Get-Item -Exactly 1
            Assert-MockCalled Get-Content -Exactly 0
            Assert-MockCalled Set-Content -Exactly 0
        }
    }
}

Describe "Process File" {
    Mock Get-Content { "Hello __place__" }
    Mock Get-Item { @{Attributes=[System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Archive} }
    Mock Set-Content { $args.GetValue(1) | Should Be "Hello World" }

    Context "is passed file and tokens" {
        It "saves file" {
            $tokens = @{place="World"}
            ProcessFile -path "web.config.token" -tokens $tokens
            Assert-MockCalled Get-Item -Exactly 1
            Assert-MockCalled Get-Content -Exactly 1
            Assert-MockCalled Set-Content -Exactly 1
        }
    }
}

Describe "Get Files" {
    # When Test-Path is called to see if there is a .token return false
    Mock Test-Path { $false }

    Context "is passed UseTokenFiles on empty folder" {
        It "returns nothing" {
            Mock Get-ChildItem { }
            GetFiles -useTokenFiles $true | Should Be $null
            Assert-MockCalled Test-Path -Exactly 0
        }
    }

    Context "is passed UseTokenFiles on a folder without token file" {
        It "returns no file" {
            # Arrange
            # Return web.config for the initial call to Get-ChildItem
            Mock Get-ChildItem { }
            
            # Act                     # Assert
            GetFiles -useTokenFiles $true | Should Be $null
            Assert-MockCalled Test-Path -Exactly 0
        }
    }

    Context "is passed UseTokenFiles on a folder with token file" {
        It "returns one file" {
            # Return web.config for the initial call to Get-ChildItem
            Mock Get-ChildItem { @{FullName="z:\web.config.token"} }
            
            (GetFiles -useTokenFiles $true).Count | Should Be 1
        }
    }

    Context "is not passed UseTokenFiles on a folder without token file" {
        It "returns one file" {
            # Return web.config for the initial call to Get-ChildItem
            Mock Get-ChildItem { @{FullName="z:\web.config"} }

            (GetFiles).Count | Should Be 1
            Assert-MockCalled Test-Path -Exactly 0
        }
    }

    Context "is not passed UseTokenFiles on a folder with token file" {
        It "returns one file" {
            # Return web.config for the initial call to Get-ChildItem
            Mock Get-ChildItem { @{FullName="z:\web.config"} }

            # When Test-Path is called to see if there is a .token return true
            Mock Test-Path { $true } -ParameterFilter { $Path -eq "z:\web.config.token" }
            (GetFiles).Count | Should Be 1
            Assert-MockCalled Test-Path -Exactly 0
        }
    }
}

Describe "Replace Tokens" {
    Context "gets an empty string" {
        It "returns an empty string" {
            $contents = ""
            $tokens = @{}
            $expected = ""
            ReplaceTokens $contents $tokens | Should Be $expected
        }
    }
    Context "gets null tokens parameter" {
        It "returns the original string" {
            $contents = "Hello __place__"
            $tokens = $null
            $expected = "Hello __place__"
            ReplaceTokens $contents $tokens | Should Be $expected
        }
    }
    Context "gets an empty tokens parameter" {
        It "returns the original string" {
            $contents = "Hello __place__"
            $tokens = @{}
            $expected = "Hello __place__"
            ReplaceTokens $contents $tokens | Should Be $expected
        }
    }
    Context "has tokens to replace" {
        It "returns a transformed string" {
            $contents = "Hello __place__"
            $tokens = @{place = "World"}
            $expected = "Hello World"
            ReplaceTokens $contents $tokens | Should Be $expected
        }
    }
}

Describe "Remove Read Only Attribute" {
    Context "is passed ReadOnly | Archive and ReadOnly" {
        It "returns Archive" {
            $attributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Archive
             $expected = [System.IO.FileAttributes]::Archive
            RemoveReadyOnlyAttribute $attributes | Should Be $expected
        }
    }
    Context "is passed ReadOnly | Archive | System and ReadOnly" {
        It "returns Archive | System" {
            $attributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Archive -bor [System.IO.FileAttributes]::System
            $expected = [System.IO.FileAttributes]::Archive -bor [System.IO.FileAttributes]::System
            RemoveReadyOnlyAttribute $attributes | Should Be $expected
        }
    }
}
