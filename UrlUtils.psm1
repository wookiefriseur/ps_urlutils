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
    Plain text to Base64 string

.DESCRIPTION
    Converts plain text to a Base64 encoded string that can be used in data urls.

.EXAMPLE
    ConvertTo-Base64 'Moin'

.EXAMPLE
    ConvertTo-Base64 'Moin' -Encoding UTF8
#>
function ConvertTo-Base64 {
    [CmdletBinding()]
    param (
        # Text to be converted to Base64
        [Parameter(Mandatory, Position = 1, ValueFromPipeline = $true)]
        [System.String]
        $Text,
        # Text encoding (ASCII, UTF-8, ...)
        [ValidateSet("ASCII", "Unicode", "UTF7", "UTF8", "UTF32")]
        [System.String]
        $Encoding = "UTF8"
    )

    begin {
        function ToBase64 {
            param (
                [Parameter(Mandatory)]
                [byte[]]
                $bytes
            )

            return [System.Convert]::ToBase64String($bytes)
        }

        function GetBytesASCII {
            return [System.Text.Encoding]::ASCII.GetBytes($Text)
        }

        function GetBytesUnicode {
            return [System.Text.Encoding]::Unicode.GetBytes($Text)
        }

        function GetBytesUTF7 {
            return [System.Text.Encoding]::UTF7.GetBytes($Text)
        }

        function GetBytesUTF8 {
            return [System.Text.Encoding]::UTF8.GetBytes($Text)
        }

        function GetBytesUTF32 {
            return [System.Text.Encoding]::UTF32.GetBytes($Text)
        }
    }

    process {
        switch ($Encoding) {
            { $_ -eq "ASCII" } { return ToBase64( (GetBytesASCII) ) }
            { $_ -eq "Unicode" } { return ToBase64( (GetBytesUnicode) ) }
            { $_ -eq "UTF7" } { return ToBase64( (GetBytesUTF7) ) }
            { $_ -eq "UTF8" } { return ToBase64( (GetBytesUTF8) ) }
            { $_ -eq "UTF32" } { return ToBase64( (GetBytesUTF32) ) }
            Default { throw New-Object System.NotImplementedException }
        }
    }

    end {
    }
}

<#
.SYNOPSIS
    Base64 string to plain text

.DESCRIPTION
    Converts a Base64 encoded string (for instance from a data url) back to plain text. Tolerates missing padding.

.EXAMPLE
    ConvertFrom-Base64 'TW9pbg=='
    ConvertFrom-Base64 'TW9pbg='
    ConvertFrom-Base64 'TW9pbg'

.EXAMPLE
    ConvertFrom-Base64 'TW9pbg==' -Encoding UTF32
#>
function ConvertFrom-Base64 {
    [CmdletBinding()]
    param (
        # Text to be converted to plain text
        [Parameter(Mandatory, Position = 1, ValueFromPipeline = $true)]
        [System.String]
        $Text,
        # Text encoding (ASCII, UTF-8, ...)
        [ValidateSet("ASCII", "Unicode", "UTF7", "UTF8", "UTF32")]
        [System.String]
        $Encoding = "UTF8"
    )

    begin {
        function FromBase64ToByteArray {
            $inputLen = $Text.Length
            $currentException = ''
            for ($i = 0; $i -lt 3; $i++) {
                try {
                    return [System.Convert]::FromBase64String($Text.PadRight($inputLen + $i, '='))
                }
                catch [System.FormatException] {
                    $currentException = $_.Exception.Message
                }
            }
            Write-Error -Message "Invalid base64 string!`n$currentException" -ErrorAction Stop
        }

        function ByteArrayToStringASCII {
            return [System.Text.Encoding]::ASCII.GetString( (FromBase64ToByteArray) )
        }
        function ByteArrayToStringUnicode {
            return [System.Text.Encoding]::Unicode.GetString( (FromBase64ToByteArray) )
        }
        function ByteArrayToStringUTF7 {
            return [System.Text.Encoding]::UTF7.GetString( (FromBase64ToByteArray) )
        }
        function ByteArrayToStringUTF8 {
            return [System.Text.Encoding]::UTF8.GetString( (FromBase64ToByteArray) )
        }
        function ByteArrayToStringUTF32 {
            return [System.Text.Encoding]::UTF32.GetString( (FromBase64ToByteArray) )
        }
    }

    process {
        switch ($Encoding) {
            { $_ -eq "ASCII" } { return ByteArrayToStringASCII }
            { $_ -eq "Unicode" } { return ByteArrayToStringUnicode }
            { $_ -eq "UTF7" } { return ByteArrayToStringUTF7 }
            { $_ -eq "UTF8" } { return ByteArrayToStringUTF8 }
            { $_ -eq "UTF32" } { return ByteArrayToStringUTF32 }
            Default { throw New-Object System.NotImplementedException }
        }
    }

    end {
    }
}
