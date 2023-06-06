<#
.SYNOPSIS
    URL escaped string to plain text

.DESCRIPTION
    Converts an URL escaped string to human readable plain text.

.EXAMPLE
    ConvertFrom-EscapedURL "https%3a%2f%2fwww.example.com%3fq%3dhello"
#>
function ConvertFrom-EscapedURL {
  [CmdletBinding()]
  param (
    # Escaped text to be converted
    [Parameter(Mandatory, Position = 1, ValueFromPipeline = $true)]
    [System.String]
    $Text
  )

  begin {
    function UnescapeURL {
      return [System.Web.HttpUtility]::UrlDecode($Text)
    }
  }

  process {
    UnescapeURL
  }

  end {
  }
}

<#
.SYNOPSIS
    URL escape plain text

.DESCRIPTION
    Converts plain text to an URL escaped string.

.EXAMPLE
    ConvertTo-EscapedURL 'https://www.example.com/?q=hello'
#>
function ConvertTo-EscapedURL {
  [CmdletBinding()]
  param (
    # Text to be escaped
    [Parameter(Mandatory, Position = 1, ValueFromPipeline = $true)]
    [System.String]
    $Text
  )

  begin {
    function EscapeURL {
      return [System.Web.HttpUtility]::UrlEncodeUnicode($Text)
    }
  }

  process {
    EscapeURL
  }

  end {
  }
}

<#
.SYNOPSIS
    Extract parts of a URI string.

.DESCRIPTION
    Extracts parts from a URI and makes them acessible from a table.
    Supports http(s) URIs.

.EXAMPLE
    Get-URIParts 'https://www.example.com/?q=hello'
    # Returns a table like @{Scheme: https ; Query: @{q: hello}, ...}
#>
function Get-URIParts {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, Position = 1)]
    [System.String]
    $URI,
    [ValidateSet("HTTP")]
    [System.String]
    $Scheme = "HTTP"
  )

  begin {
    $schemeHttp = "^(?i)https?://"
    $schemePort443 = ":443(?![a-zA-Z@])(/.+)*"
    $schemeRFC3986 = "[a-z][a-z\.\-\+]*"
  }

  process {
    switch ($Scheme) {
      { $_ -eq "HTTP" } {
        if (-not($URI -match $schemeHttp)) {
          # Check if prepending schema fixes it
          $prefix = if ($URI -match $schemePort443 ) { 'https://' }
          else { 'http://' }
          $prefixed = "$($prefix)$($URI)"
          $tmpObject = $null
          $isValid = [Uri]::IsWellFormedUriString($prefixed, [UriKind]::Absolute)
          $isValid = $isValid -and ([Uri]::TryCreate($prefixed, [UriKind]::Absolute, [ref]$tmpObject))
          $isValid = $isValid -and ($tmpObject.Scheme -match "https?")

          if (-not($isValid)) { throw  "Invalid Scheme in URI: $URI" }

          $URI = $prefixed
        }

        $uriObject = New-Object System.Uri($URI, [System.UriKind]::Absolute)

        # Catch malformed schemes
        if (-not($uriObject.Scheme -match $schemeRFC3986)) {
          throw "Invalid scheme: $($uriObject.Scheme)"
        }

        # Catch malformed paths
        if ($uriObject.AbsolutePath.StartsWith('//')) {
          throw "Invalid path segment: $($uriObject.AbsolutePath)"
        }

        $queryParts = [System.Web.HttpUtility]::ParseQueryString($uriObject.Query)

        $result = @{
          Scheme   = $uriObject.Scheme ?? ''
          User     = $uriObject.UserInfo.Split(':')[0] ?? ''
          Password = $uriObject.UserInfo.Split(':')[1] ?? ''
          Host     = $uriObject.Host ?? ''
          Port     = $uriObject.Port ?? ''
          Path     = $uriObject.AbsolutePath ?? ''
          Query    = @{}
          Fragment = $uriObject.Fragment.TrimStart('#') ?? ''
        }

        if ($result.Port -lt 0 -or $result.Port -gt (65536)) {
          throw "Invalid port or malformed URI"
        }
        if (-not($URI -match $schemeHttp)) { throw "Unsupported Scheme" }

        foreach ($key in $queryParts.Keys) {
          $result.Query[$key] = $queryParts[$key]
        }
        return $result

      }
      Default { throw "Unsupported Scheme: $($Scheme)" }
    }
    throw "Unsupported scheme ..."

  }
}


<#
.SYNOPSIS
    Converts plain text or byte array to a Base64 string.

.DESCRIPTION
    This commandlet converts plain text or a byte array to a Base64 encoded string.
    The resulting Base64 string can be used in data URLs or emails.

.EXAMPLE
    ConvertTo-Base64 'Moin'
    # Returns 'TW9pbg=='

.EXAMPLE
    ConvertTo-Base64 -Text 'Moin' -Encoding UTF32
    # Returns 'TQAAAG8AAABpAAAAbgAAAA=='

.EXAMPLE
    Get-Content -Raw some.zip -AsByteStream | ConvertTo-Base64 -ByteArray | Set-Content -Path some.zip.txt -NoNewline
    # Reads a zip file as a byte array, converts it to Base64, and saves the Base64 string to a text file
#>
function ConvertTo-Base64 {
  [CmdletBinding()]
  param (
    # Text to be converted to Base64
    [Parameter(Mandatory, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'Text')]
    [System.String]
    $Text,
    # ByteArray to be converted to Base64
    [Parameter(Mandatory, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'ByteArray')]
    [System.Byte[]]
    $ByteArray,
    # Encoding for byte conversion
    [ValidateSet("ASCII", "UTF-16", "UTF-7", "UTF-8", "UTF-32", "ISO-8859-1", "WINDOWS-1252")]
    [System.String]
    $Encoding = "UTF-8"
  )

  begin {
    function textToByteArray {
      param ([string] $String, [string] $Encoding)
      $bytes = [System.Text.Encoding]::GetEncoding($Encoding).GetBytes($String)
      return $bytes
    }

    function byteArrayToBase64String {
      param ([Parameter(Mandatory)][byte[]] $bytes)

      return [System.Convert]::ToBase64String($bytes)
    }
  }

  process {
    if ($PSCmdlet.ParameterSetName -eq 'ByteArray') {
      $bytes = $ByteArray
    }
    else {
      $bytes = textToByteArray -String $Text -Encoding $Encoding
    }
    return byteArrayToBase64String $bytes
  }

  end {}
}

<#
.SYNOPSIS
    Converts a Base64 string to plain text or a byte array.

.DESCRIPTION
    This commandlet converts a Base64 encoded string back to plain text or a byte array.
    Specify an encoding if the original was not utf-8.
    It also tolerates missing padding in the Base64 string.

.EXAMPLE
    ConvertFrom-Base64 'TW9pbg=='
    ConvertFrom-Base64 'TW9pbg='
    ConvertFrom-Base64 'TW9pbg'
    # Returns 'Moin', missing padding is OK

.EXAMPLE
    ConvertFrom-Base64 'TQAAAG8AAABpAAAAbgAAAA==' -Encoding UTF-32
    # Returns 'Moin', with explicit utf-32 encoding

.EXAMPLE
    Get-Content -Raw -AsByteStream b64.txt | ConvertFrom-Base64 -ByteArray -AsByteArray | Set-Content -Path file.zip -AsByteStream
    # Reads a Base64 string from a text file, converts it to a byte array, and saves the byte array to a binary file
#>
function ConvertFrom-Base64 {
  [CmdletBinding()]
  param (
    # Input as text
    [Parameter(Mandatory, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'Text')]
    [System.String]
    $Text,
    # Input as a ByteArray
    [Parameter(Mandatory, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'ByteArray')]
    [System.Byte[]]
    $ByteArray,
    [ValidateSet("ASCII", "ISO-8859-1", "UTF-7", "UTF-8", "UTF-16", "UTF-32", "WINDOWS-1252")]
    [System.String]
    $Encoding = "UTF-8",
    # Output as a ByteArray
    [Parameter()]
    [Switch]
    $AsByteArray = $false
  )

  begin {
    function fromBase64ToByteArray {
      param ([System.String] $Base64String)

      $inputLen = $Base64String.Length
      $currentException = ''
      for ($i = 0; $i -lt 3; $i++) {
        try {
          return [System.Convert]::FromBase64String($Base64String.PadRight($inputLen + $i, '='))
        }
        catch [System.FormatException] {
          $currentException = $_.Exception.Message
        }
      }
      Write-Error -Message "Invalid base64 string!`n$currentException" -ErrorAction Stop
    }

    if ($PSCmdlet.ParameterSetName -eq 'ByteArray') {
      $Text = ([System.Text.Encoding]::GetEncoding($Encoding)).GetString($ByteArray)
    }

    $bytes = fromBase64ToByteArray -Base64String $Text
  }

  process {
    if ($AsByteArray) {
      return $bytes
    }
    else {
      return ([System.Text.Encoding]::GetEncoding($Encoding)).GetString($bytes)
    }
  }

  end {}

}
