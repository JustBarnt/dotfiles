@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'GitHubReleases.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = '7f3a8c2d-5e1b-4a9c-8d6f-2b4e7c9a1f3d'

    # Author of this module
    Author = 'Brent'

    # Company or vendor of this module
    CompanyName = 'Unknown'

    # Copyright statement for this module
    Copyright = '(c) 2024. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell module for downloading GitHub release assets with support for filtering, authentication, and private repositories.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @('Get-GitHubRelease', 'Test-GitHubToken')

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('GitHub', 'Release', 'Download', 'Asset', 'CI', 'CD', 'Automation')

            # ReleaseNotes of this module
            ReleaseNotes = @'
# Version 1.0.0
- Initial release
- Download latest or specific tagged releases from GitHub
- Filter assets by name pattern (wildcards supported)
- Support for authentication via personal access tokens
- Works with both public and private repositories
- Automatic file size verification
- Skip already downloaded files
- Token validation helper function
'@

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
