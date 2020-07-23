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
#>
function ConvertTo-Base64 {
    [CmdletBinding()]
    param (
        # Text to be converted to Base64
        [Parameter(Mandatory, Position = 1, ValueFromPipeline = $true)]
        [System.String]
        $Text
    )

    begin {
        function ToBase64 {
            return [System.Convert]::ToBase64String($Text.ToCharArray())
        }
    }

    process {
        ToBase64
    }

    end {
    }
}

<#
.SYNOPSIS
    Base64 string to plain text

.DESCRIPTION
    Converts a Base64 encoded string (for instance from a data url) back to plain text.

.EXAMPLE
    ConvertFrom-Base64 'TW9pbg=='

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
            return [System.Convert]::FromBase64String($Text)
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
