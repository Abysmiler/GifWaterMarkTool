Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$exe = 'D:\Dev\PersonalProjects\QT\GifWaterMarkTool\deploy_p3\GifWaterMarkTool.exe'
$out = 'D:\test\layout_now.png'
$p = Start-Process -FilePath $exe -PassThru
Start-Sleep -Seconds 3
$b = [System.Windows.Forms.SystemInformation]::VirtualScreen
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.X, $b.Y, 0, 0, $b.Size)
$bmp.Save($out)
$g.Dispose(); $bmp.Dispose()
Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
Write-Host "saved $out"
