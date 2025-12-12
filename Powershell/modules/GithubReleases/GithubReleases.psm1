function Get-GitHubRelease {
    <#
    .SYNOPSIS
        Downloads GitHub release assets to a specified folder.

    .DESCRIPTION
        This function downloads release assets from a GitHub repository. It can download
        the latest release or a specific release by tag name. Supports filtering assets
        by pattern and handles authentication for private repositories.

    .PARAMETER Owner
        The GitHub repository owner/organization name.

    .PARAMETER Repo
        The GitHub repository name.

    .PARAMETER Destination
        The folder path where assets will be downloaded. Created if it doesn't exist.

    .PARAMETER Tag
        Optional. Specific release tag to download. If not specified, downloads latest release.

    .PARAMETER AssetPattern
        Optional. Filter assets by name pattern (supports wildcards). Downloads all assets if not specified.

    .PARAMETER Token
        Optional. GitHub personal access token for private repos or to avoid rate limits.
        Defaults to $env:GITHUB_TOKEN if not specified.

    .EXAMPLE
        Get-GitHubRelease -Owner "microsoft" -Repo "terminal" -Destination "C:\Downloads\Terminal"

    .EXAMPLE
        Get-GitHubRelease -Owner "neovim" -Repo "neovim" -Destination ".\nvim" -Tag "v0.9.5" -AssetPattern "*win64.zip"

    .EXAMPLE
        Get-GitHubRelease -Owner "private-org" -Repo "private-repo" -Destination ".\output" -Token $env:GITHUB_TOKEN

    .NOTES
        Author: Brent
        Requires PowerShell 5.1 or higher
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Repo,
        
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Destination,
        
        [Parameter(Mandatory = $false)]
        [string]$Tag,
        
        [Parameter(Mandatory = $false)]
        [string]$AssetPattern,
        
        [Parameter(Mandatory = $false)]
        [string]$Token = $env:GITHUB_TOKEN
    )

    # Set TLS to 1.2 for GitHub API compatibility
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Internal helper function for colored output
    function Write-ColorOutput {
        param(
            [string]$Message,
            [string]$Color = "White"
        )
        Write-Host $Message -ForegroundColor $Color
    }

    # Internal helper function to fetch release data
    function Get-ReleaseData {
        param(
            [string]$Owner,
            [string]$Repo,
            [string]$Tag,
            [string]$Token
        )
        
        if ($Tag) {
            $apiUrl = "https://api.github.com/repos/$Owner/$Repo/releases/tags/$Tag"
            Write-ColorOutput "Fetching release with tag: $Tag" "Cyan"
        } else {
            $apiUrl = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
            Write-ColorOutput "Fetching latest release..." "Cyan"
        }
        
        $headers = @{
            "User-Agent" = "PowerShell-GitHub-Release-Downloader"
        }
        
        if ($Token) {
            $headers["Authorization"] = "token $Token"
        }
        
        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
            return $release
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 404) {
                Write-ColorOutput "Error: Release not found. Check owner/repo/tag names." "Red"
            }
            elseif ($_.Exception.Response.StatusCode -eq 401) {
                Write-ColorOutput "Error: Unauthorized. Check your GitHub token." "Red"
            }
            else {
                Write-ColorOutput "Error fetching release: $($_.Exception.Message)" "Red"
            }
            throw
        }
    }

    # Internal helper function to download a single asset
    function Download-Asset {
        param(
            [object]$Asset,
            [string]$DestinationPath,
            [hashtable]$Headers
        )
        
        $filePath = Join-Path $DestinationPath $Asset.name
        
        # Check if file already exists
        if (Test-Path $filePath) {
            $existingFile = Get-Item $filePath
            if ($existingFile.Length -eq $Asset.size) {
                Write-ColorOutput "  ✓ Already downloaded: $($Asset.name) (skipping)" "Green"
                return $true
            }
            else {
                Write-ColorOutput "  ⚠ File exists but size mismatch, re-downloading: $($Asset.name)" "Yellow"
            }
        }
        
        try {
            Write-ColorOutput "  ⬇ Downloading: $($Asset.name) ($([math]::Round($Asset.size / 1MB, 2)) MB)" "Cyan"
            
            # Use browser_download_url for direct download
            Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $filePath -Headers $Headers -ErrorAction Stop
            
            # Verify download
            $downloadedFile = Get-Item $filePath
            if ($downloadedFile.Length -eq $Asset.size) {
                Write-ColorOutput "  ✓ Downloaded successfully: $($Asset.name)" "Green"
                return $true
            }
            else {
                Write-ColorOutput "  ✗ Size mismatch for: $($Asset.name)" "Red"
                return $false
            }
        }
        catch {
            Write-ColorOutput "  ✗ Failed to download $($Asset.name): $($_.Exception.Message)" "Red"
            return $false
        }
    }

    # Main script execution
    Write-ColorOutput "`n=== GitHub Release Downloader ===" "Yellow"
    Write-ColorOutput "Repository: $Owner/$Repo`n" "Yellow"

    # Create destination directory if it doesn't exist
    if (-not (Test-Path $Destination)) {
        Write-ColorOutput "Creating destination folder: $Destination" "Cyan"
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    # Get release information
    try {
        $release = Get-ReleaseData -Owner $Owner -Repo $Repo -Tag $Tag -Token $Token
    }
    catch {
        return
    }

    Write-ColorOutput "`nRelease: $($release.name)" "Green"
    Write-ColorOutput "Tag: $($release.tag_name)" "Green"
    Write-ColorOutput "Published: $($release.published_at)" "Green"
    Write-ColorOutput "Assets: $($release.assets.Count)`n" "Green"

    # Filter assets if pattern is specified
    $assetsToDownload = $release.assets
    if ($AssetPattern) {
        $assetsToDownload = $release.assets | Where-Object { $_.name -like $AssetPattern }
        Write-ColorOutput "Filtered to $($assetsToDownload.Count) assets matching pattern: $AssetPattern`n" "Cyan"
    }

    if ($assetsToDownload.Count -eq 0) {
        Write-ColorOutput "No assets to download!" "Yellow"
        return
    }

    # Prepare headers for downloads
    $downloadHeaders = @{
        "User-Agent" = "PowerShell-GitHub-Release-Downloader"
    }
    if ($Token) {
        $downloadHeaders["Authorization"] = "token $Token"
    }

    # Download assets
    $successCount = 0
    $failCount = 0

    foreach ($asset in $assetsToDownload) {
        $result = Download-Asset -Asset $asset -DestinationPath $Destination -Headers $downloadHeaders
        if ($result) {
            $successCount++
        }
        else {
            $failCount++
        }
    }

    # Summary
    Write-ColorOutput "`n=== Download Summary ===" "Yellow"
    Write-ColorOutput "Successfully downloaded: $successCount" "Green"
    if ($failCount -gt 0) {
        Write-ColorOutput "Failed: $failCount" "Red"
    }
    Write-ColorOutput "Destination: $Destination" "Cyan"
    Write-ColorOutput ""
}

function Test-GitHubToken {
    <#
    .SYNOPSIS
        Validates a GitHub personal access token.

    .DESCRIPTION
        Tests whether a GitHub token is valid and displays information about
        the authenticated user and remaining rate limit.

    .PARAMETER Token
        The GitHub personal access token to validate.
        Defaults to $env:GITHUB_TOKEN if not specified.

    .EXAMPLE
        Test-GitHubToken -Token "ghp_xxxxxxxxxxxx"

    .EXAMPLE
        Test-GitHubToken

    .NOTES
        Useful for troubleshooting authentication issues before downloading releases.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Token = $env:GITHUB_TOKEN
    )

    if (-not $Token) {
        Write-Host "No token provided and GITHUB_TOKEN environment variable not set." -ForegroundColor Yellow
        Write-Host "Set token with: `$env:GITHUB_TOKEN = 'your_token_here'" -ForegroundColor Cyan
        return $false
    }

    try {
        $headers = @{
            "Authorization" = "token $Token"
            "User-Agent" = "PowerShell-Token-Validator"
        }
        
        Write-Host "`nValidating GitHub token..." -ForegroundColor Cyan
        
        $user = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
        Write-Host "✓ Token valid - authenticated as: $($user.login)" -ForegroundColor Green
        Write-Host "  Name: $($user.name)" -ForegroundColor Gray
        Write-Host "  Account type: $($user.type)" -ForegroundColor Gray
        
        # Check rate limit
        $rateLimit = Invoke-RestMethod -Uri "https://api.github.com/rate_limit" -Headers $headers
        Write-Host "`nRate Limits:" -ForegroundColor Cyan
        Write-Host "  Core API: $($rateLimit.rate.remaining)/$($rateLimit.rate.limit) remaining" -ForegroundColor Gray
        Write-Host "  Resets at: $(([DateTimeOffset]::FromUnixTimeSeconds($rateLimit.rate.reset).LocalDateTime))" -ForegroundColor Gray
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host "✗ Token validation failed: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response.StatusCode -eq 401) {
            Write-Host "`nPossible issues:" -ForegroundColor Yellow
            Write-Host "  - Token is invalid or expired" -ForegroundColor Gray
            Write-Host "  - Token was revoked" -ForegroundColor Gray
            Write-Host "  - Token format is incorrect" -ForegroundColor Gray
        }
        
        Write-Host ""
        return $false
    }
}

# Export module members
Export-ModuleMember -Function Get-GitHubRelease, Test-GitHubToken
