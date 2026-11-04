# Full-screen capture of the primary screen (read only). Saved under shots\ unless -Out is absolute.
param([Parameter(Mandatory)][string]$Out, [string]$Crop)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
# Without DPI awareness the capture covers only the top-left logical-size rectangle of the screen.
Add-Type -Namespace W -Name D -MemberDefinition '[System.Runtime.InteropServices.DllImport("user32.dll")] public static extern bool SetProcessDPIAware();'
[void][W.D]::SetProcessDPIAware()
$shots = Join-Path $PSScriptRoot '..\shots'
New-Item -ItemType Directory -Force $shots | Out-Null
$path = if ([IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path (Resolve-Path $shots).Path $Out }
$b = [Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object Drawing.Bitmap $b.Width, $b.Height
$g = [Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.Location, [Drawing.Point]::Empty, $b.Size)
$g.Dispose()
if ($Crop) {
  $c = $Crop -split ',' | ForEach-Object { [int]$_ }
  $rect = New-Object Drawing.Rectangle $c[0], $c[1], $c[2], $c[3]
  $cropped = $bmp.Clone($rect, $bmp.PixelFormat); $bmp.Dispose(); $bmp = $cropped
}
$bmp.Save($path, [Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "shot: $path"
