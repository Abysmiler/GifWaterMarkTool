<#
.SYNOPSIS
  GIF 水印工具 - 压缩滤镜链验证脚本

.DESCRIPTION
  精确复刻 core/ffmpegrunner.cpp buildFilterComplex() 各预设拼出的 filter_complex 字符串，
  喂给 tools/ffmpeg.exe 跑通，验证：
    1) 滤镜语法被 ffmpeg 接受（无报错、产出可播 GIF）
    2) 各压缩杠杆实际生效（输出分辨率/体积下降）
  覆盖：原图高质量 / 平衡 / 极限 / 手动降帧率 / 文字水印 / 窄图不放大(边缘) 共 6 个场景。

  滤镜串通过 -filter_complex_script 从临时文件读取，规避 PowerShell 给原生 exe
  传 [0:v] / 'min(iw,720)' 等特殊字符的 argv 解析陷阱（与 C++ QProcess 直传 argv 等价）。

.PARAMETER InputGif
  可选。指定输入 GIF 路径；不指定则用 test/ 下第一个 .gif。

.EXAMPLE
  pwsh test/test_filters.ps1
  pwsh test/test_filters.ps1 -InputGif test\莉莉_摇头_xxx.gif
#>

param(
    [string]$InputGif = ""
)

# ---- 路径定位 ----
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path   # test/
$root      = Split-Path -Parent $scriptDir                      # 项目根
$ff        = Join-Path $root 'tools\ffmpeg.exe'
if (-not (Test-Path -LiteralPath $ff)) {
    Write-Host "找不到 ffmpeg.exe：$ff" -ForegroundColor Red; exit 1
}

# 选输入 GIF
if ($InputGif -ne "") {
    $inGif = Get-Item -LiteralPath $InputGif
} else {
    $inGif = Get-ChildItem -Path $scriptDir -Filter *.gif | Select-Object -First 1
}
if (-not $inGif) { Write-Host "test/ 下没有 .gif 文件" -ForegroundColor Red; exit 1 }

$outDir   = Join-Path $scriptDir 'out_filters'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# 生成测试水印 PNG（白色块，无字体依赖；C++ 水印链会 format=rgba 处理 alpha）
$waterPng = Join-Path $outDir '_wm.png'
& $ff -y -f lavfi -i 'color=c=white:s=120x40:r=1' -frames:v 1 $waterPng *> $null
if (-not (Test-Path -LiteralPath $waterPng)) {
    Write-Host "生成测试水印失败" -ForegroundColor Red; exit 1
}

$inSizeKB = [math]::Round($inGif.Length / 1KB, 1)
Write-Host "ffmpeg : $ff"
Write-Host "输入   : $($inGif.Name)  ($inSizeKB KB)"
Write-Host "输出目录: $outDir`n"

# ---- 工具：抓 GIF 分辨率 ----
function Get-GifDims([string]$path) {
    $info = (& $ff -hide_banner -i $path 2>&1 | Out-String)
    if ($info -match 'Video:\s*gif.*?(\d{2,5})x(\d{2,5})') { return "$($Matches[1])x$($Matches[2])" }
    return "?"
}
$inDims = Get-GifDims $inGif.FullName

# ---- 6 个场景：精确复刻 buildFilterComplex 输出（wmScale=1/rotate=0/opacity=1/中心100,100）----
$wmChain = '[1:v]scale=iw*1.0000:ih*1.0000,rotate=0.0000*PI/180:ow=rotw(0.0000*PI/180):oh=roth(0.0000*PI/180):fillcolor=0x00000000,format=rgba,colorchannelmixer=aa=1.0000[wm]'

$cases = @(
    @{ Name = '1.原图高质量(256色/bayer/diff)';
       Inputs = 2; NeedWater = $true;
       Filter = "$wmChain;[0:v][wm]overlay=x=100.00-w/2:y=100.00-h/2[comp];[comp]split=2[a][b];[a]palettegen=stats_mode=diff:max_colors=256[pal];[b][pal]paletteuse=new=1:dither=bayer:bayer_scale=3[out]" }
    @{ Name = '2.平衡 720宽/128色/bayer';
       Inputs = 2; NeedWater = $true;
       Filter = "$wmChain;[0:v][wm]overlay=x=100.00-w/2:y=100.00-h/2,scale='min(iw,720)':-2:flags=lanczos[comp];[comp]split=2[a][b];[a]palettegen=stats_mode=diff:max_colors=128[pal];[b][pal]paletteuse=new=1:dither=bayer:bayer_scale=3[out]" }
    @{ Name = '3.极限 480宽/64色/none';
       Inputs = 2; NeedWater = $true;
       Filter = "$wmChain;[0:v][wm]overlay=x=100.00-w/2:y=100.00-h/2,scale='min(iw,480)':-2:flags=lanczos[comp];[comp]split=2[a][b];[a]palettegen=stats_mode=diff:max_colors=64[pal];[b][pal]paletteuse=new=1:dither=none[out]" }
    @{ Name = '4.手动降帧率 fps=15';
       Inputs = 2; NeedWater = $true;
       Filter = "[0:v]fps=15[v0];$wmChain;[v0][wm]overlay=x=100.00-w/2:y=100.00-h/2,scale='min(iw,720)':-2:flags=lanczos[comp];[comp]split=2[a][b];[a]palettegen=stats_mode=diff:max_colors=128[pal];[b][pal]paletteuse=new=1:dither=bayer:bayer_scale=3[out]" }
    @{ Name = '5.文字水印分支';
       Inputs = 1; NeedWater = $false;
       Filter = "[0:v]drawtext=text='WATERMARK':fontsize=24:fontcolor=white@1.00:x=100.00-tw/2:y=100.00-th/2,scale='min(iw,720)':-2:flags=lanczos,split=2[a][b];[a]palettegen=stats_mode=diff:max_colors=128[pal];[b][pal]paletteuse=new=1:dither=bayer:bayer_scale=3[out]" }
    @{ Name = '6.窄图不放大(min(iw,1920))';
       Inputs = 2; NeedWater = $true;
       Filter = "$wmChain;[0:v][wm]overlay=x=100.00-w/2:y=100.00-h/2,scale='min(iw,1920)':-2:flags=lanczos[comp];[comp]split=2[a][b];[a]palettegen=stats_mode=diff:max_colors=256[pal];[b][pal]paletteuse=new=1:dither=bayer:bayer_scale=3[out]" }
)

# ---- 跑每个 case ----
$results = @()
$i = 0
foreach ($case in $cases) {
    $i++
    $out = Join-Path $outDir ("case{0}.gif" -f $i)
    $fc  = Join-Path $outDir ("case{0}.fc"  -f $i)
    $log = Join-Path $outDir ("case{0}.log" -f $i)

    # 滤镜串写文件（UTF-8 无 BOM），用 -filter_complex_script 规避 argv 特殊字符问题
    [IO.File]::WriteAllText($fc, $case.Filter)

    Write-Host ("{0,-32} " -f $case.Name) -NoNewline

    $inputArgs = @('-y', '-i', $inGif.FullName)
    if ($case.NeedWater) { $inputArgs += @('-i', $waterPng) }

    & $ff @inputArgs -filter_complex_script $fc -map '[out]' $out *> $log
    $ok = (Test-Path -LiteralPath $out) -and ((Get-Item -LiteralPath $out).Length -gt 0)

    if ($ok) {
        $outKB  = [math]::Round((Get-Item -LiteralPath $out).Length / 1KB, 1)
        $pct    = if ($inSizeKB -gt 0) { [math]::Round($outKB / $inSizeKB * 100, 0) } else { 0 }
        $dims   = Get-GifDims $out
        $color  = if ($pct -le 60) { 'Green' } elseif ($pct -le 90) { 'Yellow' } else { 'White' }
        Write-Host ("OK  {0,8} KB  {1,4}%  {2}" -f $outKB, $pct, $dims) -ForegroundColor $color
        $results += [pscustomobject]@{ 场景=$case.Name; 状态='OK'; 输出KB=$outKB; 占输入=$pct; 输出尺寸=$dims }
    } else {
        Write-Host "FAIL  详见 .log" -ForegroundColor Red
        $results += [pscustomobject]@{ 场景=$case.Name; 状态='FAIL'; 输出KB=0; 占输入=0; 输出尺寸='-' }
    }
}

# ---- 汇总 ----
Write-Host ("`n输入 {0} KB  {1}" -f $inSizeKB, $inDims) -ForegroundColor Cyan
Write-Host "==== 汇总 ====" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$fails = ($results | Where-Object { $_.状态 -eq 'FAIL' }).Count
if ($fails -gt 0) {
    Write-Host "`n有 $fails 个场景失败，请查看对应的 case*.log（通常是字体/滤镜语法问题）。" -ForegroundColor Yellow
} else {
    Write-Host "`n全部 6 个场景通过：压缩滤镜链语法正确、产出可播。" -ForegroundColor Green
}
