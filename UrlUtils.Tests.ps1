# Check if Pester is available (if run as a script, otherwise use Invoke-Pester)
if (-not(Get-Module -ListAvailable -Name Pester)) {
  # If not, try to install it
  Write-Output "Pester module not found. Attempting to install..."
  try {
    Install-Module -Name Pester -Force
  }
  catch {
    Write-Error "Failed to install Pester. Please install it manually."
    return
  }
}

Describe 'UrlUtils tests' {
  BeforeAll {
    # Import WIP modules to be tested
    foreach ($module in $(Get-ChildItem -Path $PSScriptRoot -Filter *.psm1)) {
      Write-Output "Importing $module"
      Import-Module -Name $module.FullName -Prefix 'WIP' -Force
    }
  }

  Describe "URL Escaping Tests" {
    It "Converts plain text to escaped URL" {
      $plainText = 'https://www.example.com/?q=hello world'
      $escapedText = ConvertTo-WIPEscapedURL $plainText
      $escapedText | Should -Be 'https%3a%2f%2fwww.example.com%2f%3fq%3dhello+world'
    }

    It "Converts escaped URL to plain text" {
      $escapedText = 'https%3a%2f%2fwww.example.com%2f%3fq%3dhello+world'
      $plainText = ConvertFrom-WIPEscapedURL $escapedText
      $plainText | Should -Be 'https://www.example.com/?q=hello world'
    }

    It "Converts irregular escaped URL to plain text (%20 instead of + in query)" {
      $escapedText = 'https%3a%2f%2fwww.example.com%2f%3fq%3dhello%20world'
      $plainText = ConvertFrom-WIPEscapedURL $escapedText
      $plainText | Should -Be 'https://www.example.com/?q=hello world'
    }

    It "Preserves original URL when converting to and from escaped URL" {
      $originalUrl = 'https://www.example.com/?q=hello world'
      $escapedAndUnescapedUrl = $originalUrl | ConvertTo-WIPEscapedURL | ConvertFrom-WIPEscapedURL
      $escapedAndUnescapedUrl | Should -Be $originalUrl
    }
  }

  Describe 'URI extraction and manipulation tests' {
    Describe 'Get-URIParts' {
      BeforeAll {
        function Compare-URIParts {
          param ([hashtable]$Expected, [hashtable]$Actual)

          $diff = Compare-Object -ReferenceObject $Expected -DifferenceObject $Actual -Property scheme, user, password, host, port, path, fragment
          $queryDiff = Compare-Object -ReferenceObject $Expected.query -DifferenceObject $Actual.query

          $diffMsg = if ($diff -or $queryDiff) {
            "Differences:`n" + ($diff + $queryDiff | Out-String)
          }
          else {
            "No differences"
          }

          ($diff + $queryDiff) | Should -BeNullOrEmpty -Because $diffMsg
        }
      }

      It 'should return correct parts for a given URI containing credentials and IPv6' {
        $uri = 'https://user:password@[::1]:8080/index.php?q1=a&q2=123#anchor'
        $expected = @{
          Scheme   = 'https'
          User     = 'user'
          Password = 'password'
          Host     = '[::1]'
          Port     = 8080
          Path     = '/index.php'
          Query    = @{
            q1 = 'a'
            q2 = '123'
          }
          Fragment = 'anchor'
        }

        $actual = Get-WIPURIParts -URI $uri
        Compare-URIParts -Expected $expected -Actual $actual
      }

      It 'should return correct parts for a regular web URI' {
        $uri = 'http://www.example.com'
        $expected = @{
          Scheme   = 'http'
          User     = ''
          Password = ''
          Host     = 'www.example.com'
          Port     = 80
          Path     = '/'
          Query    = @{}
          Fragment = ''
        }

        $actual = Get-WIPURIParts -URI $uri
        Compare-URIParts -Expected $expected -Actual $actual
      }

      It 'should return correct parts for a URI containing an emoji' {
        $uri = 'https://🍕.ws'
        $expected = @{
          Scheme   = 'https'
          User     = ''
          Password = ''
          Host     = '🍕.ws'
          Port     = 443
          Path     = '/'
          Query    = @{}
          Fragment = ''
        }

        $actual = Get-WIPURIParts -URI $uri
        Compare-URIParts -Expected $expected -Actual $actual
      }

      It 'should return correct parts for a URI pointing to an IPv4' {
        $uri = 'http://127.0.0.1'
        $expected = @{
          Scheme   = 'http'
          User     = ''
          Password = ''
          Host     = '127.0.0.1'
          Port     = 80
          Path     = '/'
          Query    = @{}
          Fragment = ''
        }

        $actual = Get-WIPURIParts -URI $uri
        Compare-URIParts -Expected $expected -Actual $actual
      }

      It 'should throw an error for an invalid URI' {
        $uri = 'not a valid URI'
        { Get-WIPURIParts -URI $uri } | Should -Throw
      }

    }

  }

  Describe 'Base64 conversion tests' {
    Context 'Simple string check' {
      It 'should return the same string after conversion to Base64 and back' {
        $originalString = 'Test String'
        $base64String = ConvertTo-WIPBase64 $originalString -Encoding UTF-8
        $convertedString = ConvertFrom-WIPBase64 $base64String -Encoding UTF-8
        $convertedString | Should -Be $originalString
      }
    }

    Context 'Invalid base64 string' {
      It 'should throw an error when an invalid base64 string is input' {
        { ConvertFrom-WIPBase64 'invalid_base64_string' -Encoding UTF-8 } | Should -Throw
      }
    }

    Context 'Empty string input' {
      It 'should throw an error when an empty string is sent to ConvertTo-Base64' {
        { ConvertTo-WIPBase64 '' -Encoding UTF-8 } | Should -Throw
      }
    }

    Context 'File conversion test' {
      It 'should have identical content for the original and processed txt files' {
        $originalFileContent = "Test file content äöü Unicode ⚠️`nLinebreak`n"
        $originalFile = New-TemporaryFile
        Set-Content -Path $originalFile.FullName -Value $originalFileContent -NoNewline

        # Create a zip file from the txt file
        $zipFile = New-TemporaryFile
        Compress-Archive -Path $originalFile.FullName -DestinationPath $zipFile.FullName -Force

        # Convert the raw zip file content to base64
        # ❗ `Get-Content -AsByteStream` actually outputs a ByteArray, not a Stream ❗
        $base64String = Get-Content -Path $zipFile.FullName -Raw -AsByteStream | ConvertTo-WIPBase64

        # Convert the Base64 string back to a zip file
        $convertedBytes = ConvertFrom-WIPBase64 $base64String -AsByteArray
        $convertedZipFile = New-TemporaryFile
        Remove-Item $convertedZipFile.FullName -Force
        [System.IO.File]::WriteAllBytes($convertedZipFile.FullName, $convertedBytes)

        # Extract the zip file to a txt file
        $convertedFile = New-TemporaryFile
        Remove-Item $convertedFile.FullName -Force
        Expand-Archive -Path $convertedZipFile.FullName -DestinationPath $convertedFile.FullName -Force

        $extractedFilePath = Join-Path -Path $convertedFile.FullName -ChildPath $originalFile.Name
        $convertedFileContent = Get-Content -Path $extractedFilePath -Raw

        Remove-Item $originalFile.FullName -Force
        Remove-Item $zipFile.FullName -Force
        Remove-Item $convertedZipFile.FullName -Force
        Remove-Item $convertedFile.FullName -Force -Recurse

        $convertedFileContent | Should -Be $originalFileContent
      }
    }
  }
}
