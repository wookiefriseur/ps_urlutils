# Tests for ConvertTo-Base64, ConvertFrom-Base64

Describe 'Base64 conversion tests' {
  BeforeAll {
    # Import WIP modules to be tested
    foreach ($module in $(Get-ChildItem -Path (Join-Path $PSScriptRoot "..") -Filter *.psm1)) {
      Write-Output "Importing $module"
      Import-Module -Name $module.FullName -Prefix 'WIP' -Force
    }
  }

  Context 'Simple string checks' {
    It 'should return the same string after conversion to Base64 and back' {
      $originalString = 'Test String'
      $base64String = ConvertTo-WIPBase64 $originalString -Encoding UTF-8
      $convertedString = ConvertFrom-WIPBase64 $base64String -Encoding UTF-8
      $convertedString | Should -Be $originalString
    }

    It 'should throw an error when an invalid base64 string is input' {
      { ConvertFrom-WIPBase64 'invalid_base64_string' -Encoding UTF-8 } | Should -Throw
    }

    It 'should throw an error when an empty string is sent to ConvertTo-Base64' {
      { ConvertTo-WIPBase64 '' -Encoding UTF-8 } | Should -Throw
    }
  }

  Context 'Multi step conversion tests' {
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
