# Tests for ConvertTo-EscapedURL, ConvertFrom-EscapedURL

Describe 'URL Escaping tests' {
  BeforeAll {
    # Import WIP modules to be tested
    foreach ($module in $(Get-ChildItem -Path (Join-Path $PSScriptRoot "..") -Filter *.psm1)) {
      Write-Output "Importing $module"
      Import-Module -Name $module.FullName -Prefix 'WIP' -Force
    }
  }

  Context 'Simple one-way conversions' {
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
  }

  Context 'Two-way conversions' {
    It "Preserves original URL when converting to and from escaped URL" {
      $originalUrl = 'https://www.example.com/?q=hello world'
      $escapedAndUnescapedUrl = $originalUrl | ConvertTo-WIPEscapedURL | ConvertFrom-WIPEscapedURL
      $escapedAndUnescapedUrl | Should -Be $originalUrl
    }
  }

}
