@{

    RootModule        = 'UrlUtils.psm1'
    ModuleVersion     = '0.0.1'
    Description       = 'URL Utilities like Base64 conversion, URL encoding and working with Data URLs'

    GUID              = '6121cfce-e5e1-4a1e-900b-22b8edc96fc5'

    Author            = 'Matthäus Falkowski'
    Copyright         = 'Copyright (c) 2020 Matthäus Falkowski. MIT License.'

    # Exports
    FunctionsToExport = @(
        "ConvertFrom-EscapedURL",
        "ConvertTo-EscapedURL"
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData       = @{

        PSData = @{

            Tags       = @("url", "dataurl")
            LicenseUri = "https://github.com/wookiefriseur/valor-modulis/blob/master/LICENSE.md"
        }

    }

}
