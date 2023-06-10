# Tests for Get-URIParts

Describe 'URI extraction and manipulation tests' {
  BeforeAll {
    # Import WIP modules to be tested
    foreach ($module in $(Get-ChildItem -Path (Join-Path $PSScriptRoot "..") -Filter *.psm1)) {
      Write-Output "Importing $module"
      Import-Module -Name $module.FullName -Prefix 'WIP' -Force
    }

    # Helper function for hashtable comparison
    function Compare-URIParts {
      param ([hashtable]$Expected, [hashtable]$Actual, [string]$ContextMessage = '')

      foreach ($key in $Expected.Keys) {
        $expectedValue = $Expected[$key]
        $actualValue = $Actual[$key]

        if ($null -eq $actualValue) {
          $actualValue | Should -Be $expectedValue -Because "$ContextMessage`n$($key): expected '$expectedValue', got '$actualValue'"
        }

        if (($expectedValue -is [hashtable]) -or ($expectedValue -is [array])) {
          $diff = Compare-Object -ReferenceObject $expectedValue -DifferenceObject $actualValue
          if ($diff) {
            $diffMsg = "Differences in $($key):`n" + ($diff | Out-String)
            $diff | Should -BeNullOrEmpty -Because "$ContextMessage`n$diffMsg"
          }
        }
        else {
          $actualValue | Should -Be $expectedValue -Because "$ContextMessage`n$($key): expected '$expectedValue', got '$actualValue'"
        }
      }
    }
  }

  Describe 'HTTP URI scheme tests' {

    Context 'Single tests for HTTP URIs' {
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

      It 'should return correct parts for a URI with a multi-segment path' {
        $uri = 'http://www.example.com/segment1/segment2/segment3'
        $expected = @{
          Scheme   = 'http'
          User     = ''
          Password = ''
          Host     = 'www.example.com'
          Port     = 80
          Path     = '/segment1/segment2/segment3'
          Query    = @{}
          Fragment = ''
        }

        $actual = Get-WIPURIParts -URI $uri
        Compare-URIParts -Expected $expected -Actual $actual
      }

      It 'should recognise a HTTP URL with the missing scheme prefix' {
        $uri = 'www.example.com'
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

      It 'should recognise a HTTPS URL with missing scheme prefix, ending with a port number' {
        $uri = 'www.example.com:443'
        $expected = @{
          Scheme   = 'https'
          User     = ''
          Password = ''
          Host     = 'www.example.com'
          Port     = 443
          Path     = '/'
          Query    = @{}
          Fragment = ''
        }

        $actual = Get-WIPURIParts -URI $uri
        Compare-URIParts -Expected $expected -Actual $actual
      }

      It 'should throw an error for an invalid URI' {
        $uri = 'not a valid URI'
        { Get-WIPURIParts -URI $uri } | Should -Throw -Because "🔥 URI was: $uri"
      }

      It 'should throw an error for a URI with an unsupported scheme' {
        $uri = 'unsupported://www.example.com'
        { Get-WIPURIParts -URI $uri } | Should -Throw -Because "🔥 URI was: $uri"
      }

    }

    Context 'Test lists of HTTP URIs' {
      It 'should correctly parse all kinds of valid HTTP URIs' {
        $validUris = @(
          @{ Uri     = 'https://user:password@[::1]:8080/index.php?q1=a&q2=123#anchor'
            Expected = @{
              User = 'user'; Password = 'password'; Host = '[::1]'; Fragment = 'anchor'
              Port = 8080; Path = '/index.php'; Query = @{ 'q1' = 'a'; 'q2' = '123' };
            }
          },
          @{ Uri     = 'http://www.example.com'
            Expected = @{ Host = 'www.example.com'; Port = 80; Path = '/' }
          },
          @{ Uri = 'https://example.com' ; Expected = @{ Port = 443; } },
          @{ Uri = 'http://example.com:8080' ; Expected = @{ Port = 8080 } },
          @{ Uri = 'https://example.com/path/to/page' ; Expected = @{ Path = '/path/to/page' } },
          @{ Uri     = 'http://example.com/path/to/page?query=param'
            Expected = @{
              Scheme = 'http'; Host = 'example.com'; Port = 80;
              Path = '/path/to/page'; Query = @{ 'query' = 'param' }
            }
          },
          @{ Uri     = 'https://example.com/path/to/page?query=param&another=param'
            Expected = @{ Scheme = 'https'; Host = 'example.com'; Port = 443; Path = '/path/to/page'; Query = @{ 'query' = 'param'; 'another' = 'param' } }
          },
          @{ Uri     = 'http://user:password@example.com'
            Expected = @{ Scheme = 'http'; User = 'user'; Password = 'password'; Host = 'example.com'; Port = 80; Path = '/' }
          },
          @{ Uri     = 'https://user:password@example.com/path/to/page'
            Expected = @{ Scheme = 'https'; User = 'user'; Password = 'password'; Host = 'example.com'; Port = 443; Path = '/path/to/page' }
          },
          @{ Uri     = 'http://user:password@example.com:8080/path/to/page'
            Expected = @{ Scheme = 'http'; User = 'user'; Password = 'password'; Host = 'example.com'; Port = 8080; Path = '/path/to/page' }
          },
          @{ Uri     = 'https://user:password@example.com:8080/path/to/page?query=param'
            Expected = @{
              Scheme = 'https'; User = 'user'; Password = 'password'; Host = 'example.com';
              Port = 8080; Path = '/path/to/page'; Query = @{ 'query' = 'param' }
            }
          },
          @{ Uri = 'http://127.0.0.1/' ; Expected = @{ Scheme = 'http'; Host = '127.0.0.1'; Port = 80; Path = '/' } },
          @{ Uri = 'http://localhost/' ; Expected = @{ Scheme = 'http'; Host = 'localhost'; Port = 80; Path = '/' } },
          @{ Uri = 'http://[2001:db8::1]' ; Expected = @{ Scheme = 'http' ; Host = '[2001:db8::1]' ; Path = '/' } },
          @{ Uri = 'http://[2001:db8::1]:8080' ; Expected = @{ Host = '[2001:db8::1]' ; Port = 8080 } }
        )

        foreach ($test in $validUris) {
          $actual = Get-WIPURIParts -URI $test.Uri
          Compare-URIParts -Expected $test.Expected -Actual $actual -ContextMessage $test.Uri
        }
      }

      It 'should throw an error for a correctly prefixed invalid URI' {
        $invalidUris = @(
          'http://',
          'http://.',
          'http://..',
          'http://../',
          'http://?',
          'http://?#',
          'http://#?',
          'http://user:password@',
          'http://user:password@:8080',
          'http://:8080',
          'http://user:password@/path',
          'http://user:password@?query=param',
          'http://user:password@#fragment',
          'http://[2001:db8::1]:-1',
          'http://[2001:db8::1]:70000',
          'http://unsupported://www.example.com'
        )

        foreach ($uri in $invalidUris) {
          { Get-WIPURIParts -URI $uri } | Should -Throw -Because "🔥 URI was: $uri"
        }
      }
    }
  }

  Describe 'DATA URI scheme tests' {

    Context 'Single tests for DATA URIs' {
      It 'should return correct parts for a valid data URI' {
        $uri = 'data:application/json;charset=UTF-8,{"message": "moin"}'
        $expected = @{
          Scheme     = 'data'
          MimeType   = 'application/json'
          Parameters = @{ charset = 'UTF-8' }
          Base64     = $false
          Data       = '{"message": "moin"}'
        }

        $actual = Get-WIPURIParts -URI $uri -Scheme DATA
        Compare-URIParts -Expected $expected -Actual $actual
      }

      It 'should parse a valid data URI with no data' {
        $uri = 'data:,'
        $expected = @{
          Scheme     = 'data'
          MimeType   = 'text/plain'
          Parameters = @{ charset = 'US-ASCII' }
          Base64     = $false
          Data       = ''
        }

        $actual = Get-WIPURIParts -URI $uri -Scheme DATA
        Compare-URIParts -Expected $expected -Actual $actual
      }

      It 'should throw an error for an empty data URI' {
        $uri = ''
        { Get-WIPURIParts -URI $uri -Scheme DATA } | Should -Throw -Because "🔥 URI was: $uri"
      }
    }

    Context 'Test lists of DATA URIs' {
      It 'should correctly parse all kinds of valid data URIs' {
        $validUris = @(
          @{ Uri     = 'data:text/plain;charset=US-ASCII,hello%20world'
            Expected = @{ MimeType = 'text/plain'; Parameters = @{ charset = 'US-ASCII' }; Data = 'hello%20world' }
          },
          @{ Uri = 'data:,hello world'; Expected = @{ Data = 'hello world' } },
          @{
            Uri      = 'data:text/html,<html><body>Hello World</body></html>'
            Expected = @{ MimeType = 'text/html'; Data = '<html><body>Hello World</body></html>' }
          },
          @{ Uri     = 'data:isolated=param;base64,YQ=='
            Expected = @{
              MimeType   = 'text/plain'
              Parameters = @{ isolated = 'param'; charset = 'US-ASCII' }
              Base64     = $true
              Data       = 'YQ=='
            }
          },
          @{ Uri     = 'data:charset=UTF-8,e'
            Expected = @{ MimeType = 'text/plain'; Parameters = @{ charset = 'UTF-8' }; Data = 'e' }
          },
          @{ Uri     = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=='
            Expected = @{ MimeType = 'image/png'; Base64 = $true; Data = 'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==' }
          }
        )

        foreach ($test in $validUris) {
          $actual = Get-WIPURIParts -URI $test.Uri -Scheme DATA
          Compare-URIParts -Expected $test.Expected -Actual $actual -ContextMessage $test.Uri
        }
      }

      It 'should throw an error for an invalid data URI' {
        $invalidUris = @(
          'data:',
          'data:;;,',
          'data:wrongmimetype,somedata',
          'data:my/type;wrong-param,somedata',
          'data:my/type;charset;someflag;toolong,somedata',
          'data:invalid'
        )

        foreach ($uri in $invalidUris) {
          { Get-WIPURIParts -URI $uri -Scheme DATA } | Should -Throw -Because "🔥 URI was: $uri"
        }
      }
    }
  }
}


