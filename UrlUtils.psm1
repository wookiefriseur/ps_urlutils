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
