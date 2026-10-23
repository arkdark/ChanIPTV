#requires -Version 5.1
<#
    Gera todos os PNGs usados pelo ChanIPTV (ícones da loja, splash e
    elementos da interface). Requer Windows PowerShell + System.Drawing.
    Uso: powershell -ExecutionPolicy Bypass -File tools\GenerateAssets.ps1
#>

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$imagesDir = Join-Path $root 'images'
New-Item -ItemType Directory -Force -Path $imagesDir | Out-Null

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Color([string]$hex, [int]$alpha = 255) {
    $hex = $hex.TrimStart('#')
    $r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
    $g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
    $b = [Convert]::ToInt32($hex.Substring(4, 2), 16)
    return [System.Drawing.Color]::FromArgb($alpha, $r, $g, $b)
}

function New-Surface([int]$width, [int]$height) {
    $bitmap = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear([System.Drawing.Color]::Transparent)
    return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function New-RoundedPath([single]$x, [single]$y, [single]$width, [single]$height, [single]$radius) {
    $radius = [Math]::Min($radius, [Math]::Min($width, $height) / 2)
    $diameter = $radius * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($x, $y, $diameter, $diameter, 180, 90)
    $path.AddArc($x + $width - $diameter, $y, $diameter, $diameter, 270, 90)
    $path.AddArc($x + $width - $diameter, $y + $height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($x, $y + $height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-Font([single]$size, [string]$family = 'Segoe UI', [string]$style = 'Regular') {
    $fontStyle = [System.Drawing.FontStyle]::$style
    return New-Object System.Drawing.Font($family, $size, $fontStyle, [System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-Text($graphics, [string]$text, $font, $brush,
                   [single]$x, [single]$y, [single]$width, [single]$height,
                   [string]$align = 'Center', [string]$valign = 'Center') {
    $format = New-Object System.Drawing.StringFormat
    switch ($align) {
        'Left'   { $format.Alignment = [System.Drawing.StringAlignment]::Near }
        'Right'  { $format.Alignment = [System.Drawing.StringAlignment]::Far }
        default  { $format.Alignment = [System.Drawing.StringAlignment]::Center }
    }
    switch ($valign) {
        'Top'    { $format.LineAlignment = [System.Drawing.StringAlignment]::Near }
        'Bottom' { $format.LineAlignment = [System.Drawing.StringAlignment]::Far }
        default  { $format.LineAlignment = [System.Drawing.StringAlignment]::Center }
    }
    $rect = [System.Drawing.RectangleF]::new($x, $y, $width, $height)
    $graphics.DrawString($text, $font, $brush, $rect, $format)
    $format.Dispose()
}

function Save-Png($surface, [string]$fileName) {
    $path = Join-Path $imagesDir $fileName
    $surface.Graphics.Flush()
    $surface.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $surface.Graphics.Dispose()
    $surface.Bitmap.Dispose()
    Write-Host "  $fileName"
}

function Draw-Background($graphics, [int]$width, [int]$height) {
    $rect = [System.Drawing.Rectangle]::new(0, 0, $width, $height)
    $background = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        (Color '060A12'),
        (Color '0C1626'),
        [single]90)
    $graphics.FillRectangle($background, $rect)
    $background.Dispose()

    # Brilho suave no canto superior direito.
    $glow = New-Object System.Drawing.Drawing2D.GraphicsPath
    $glow.AddEllipse([single]($width * 0.55), [single](-$height * 0.45), [single]($width * 0.85), [single]($height * 1.05))
    $glowBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($glow)
    $glowBrush.CenterColor = Color '0F8E86' 34
    $glowBrush.SurroundColors = [System.Drawing.Color[]]@((Color '0F8E86' 0))
    $graphics.FillPath($glowBrush, $glow)
    $glowBrush.Dispose()
    $glow.Dispose()

    # Brilho frio no canto inferior esquerdo.
    $glow2 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $glow2.AddEllipse([single](-$width * 0.35), [single]($height * 0.45), [single]($width * 0.8), [single]($height * 0.9))
    $glowBrush2 = New-Object System.Drawing.Drawing2D.PathGradientBrush($glow2)
    $glowBrush2.CenterColor = Color '1C4FA8' 26
    $glowBrush2.SurroundColors = [System.Drawing.Color[]]@((Color '1C4FA8' 0))
    $graphics.FillPath($glowBrush2, $glow2)
    $glowBrush2.Dispose()
    $glow2.Dispose()

    # Textura de linhas bem discreta.
    $linePen = New-Object System.Drawing.Pen((Color 'FFFFFF' 5), [single]1)
    for ($y = 0; $y -lt $height; $y += 6) {
        $graphics.DrawLine($linePen, 0, $y, $width, $y)
    }
    $linePen.Dispose()
}

function Draw-Mark($graphics, [single]$x, [single]$y, [single]$size) {
    $radius = $size * 0.25
    $path = New-RoundedPath $x $y $size $size $radius
    $gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        [System.Drawing.RectangleF]::new($x, $y, $size, $size),
        (Color '00D6B0'),
        (Color '2E7BFF'),
        [single]45)
    $graphics.FillPath($gradient, $path)
    $gradient.Dispose()

    $innerBorder = New-Object System.Drawing.Pen((Color 'FFFFFF' 46), [single][Math]::Max(1, $size * 0.012))
    $graphics.DrawPath($innerBorder, $path)
    $innerBorder.Dispose()

    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, [single][Math]::Max(1.5, $size * 0.034))
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    $tvWidth = $size * 0.60
    $tvHeight = $size * 0.40
    $tvX = $x + ($size - $tvWidth) / 2
    $tvY = $y + $size * 0.36
    $tv = New-RoundedPath $tvX $tvY $tvWidth $tvHeight ($size * 0.07)
    $graphics.DrawPath($pen, $tv)
    $tv.Dispose()

    $graphics.DrawLine($pen, $x + $size * 0.50, $tvY, $x + $size * 0.37, $y + $size * 0.16)
    $graphics.DrawLine($pen, $x + $size * 0.50, $tvY, $x + $size * 0.63, $y + $size * 0.16)

    $triangle = New-Object System.Drawing.Drawing2D.GraphicsPath
    $triangle.AddPolygon([System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($x + $size * 0.45, $y + $size * 0.44),
        [System.Drawing.PointF]::new($x + $size * 0.45, $y + $size * 0.68),
        [System.Drawing.PointF]::new($x + $size * 0.64, $y + $size * 0.56)
    ))
    $graphics.FillPath($white, $triangle)
    $triangle.Dispose()

    $white.Dispose()
    $pen.Dispose()
    $path.Dispose()
}

function New-Card([string]$fileName, [int]$width, [int]$height, [int]$radius,
                  [string]$fill, [string]$border, [int]$borderWidth) {
    $surface = New-Surface $width $height
    $graphics = $surface.Graphics
    $path = New-RoundedPath 1 1 ($width - 2) ($height - 2) $radius

    $brush = New-Object System.Drawing.SolidBrush((Color $fill))
    $graphics.FillPath($brush, $path)
    $brush.Dispose()

    $pen = New-Object System.Drawing.Pen((Color $border), [single]$borderWidth)
    $graphics.DrawPath($pen, $path)
    $pen.Dispose()
    $path.Dispose()

    Save-Png $surface $fileName
}

function New-Star([string]$fileName, [int]$size) {
    $surface = New-Surface $size $size
    $graphics = $surface.Graphics
    $center = $size / 2

    $badge = New-Object System.Drawing.SolidBrush((Color '0A111D' 215))
    $graphics.FillEllipse($badge, 1, 1, $size - 2, $size - 2)
    $badge.Dispose()

    $points = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    $outer = $size * 0.34
    $inner = $outer * 0.45
    for ($i = 0; $i -lt 10; $i++) {
        $angle = [Math]::PI / 2 + $i * [Math]::PI / 5
        $r = if (($i % 2) -eq 0) { $outer } else { $inner }
        $points.Add([System.Drawing.PointF]::new(
            [single]($center + [Math]::Cos($angle) * $r),
            [single]($center - [Math]::Sin($angle) * $r)))
    }
    $star = New-Object System.Drawing.Drawing2D.GraphicsPath
    $star.AddPolygon($points.ToArray())
    $gold = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        [System.Drawing.RectangleF]::new(0, 0, $size, $size),
        (Color 'FFD36A'),
        (Color 'FFAE33'),
        [single]90)
    $graphics.FillPath($gold, $star)
    $gold.Dispose()
    $star.Dispose()

    Save-Png $surface $fileName
}

function New-Check([string]$fileName, [int]$size) {
    $surface = New-Surface $size $size
    $graphics = $surface.Graphics
    $circle = New-Object System.Drawing.SolidBrush((Color '00C2A8'))
    $graphics.FillEllipse($circle, 1, 1, $size - 2, $size - 2)
    $circle.Dispose()

    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, [single]($size * 0.105))
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $graphics.DrawLines($pen, [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($size * 0.26, $size * 0.52),
        [System.Drawing.PointF]::new($size * 0.43, $size * 0.69),
        [System.Drawing.PointF]::new($size * 0.75, $size * 0.33)
    ))
    $pen.Dispose()
    Save-Png $surface $fileName
}

Write-Host 'Gerando imagens do ChanIPTV...'

# ---------------------------------------------------------------------------
# Imagem de fundo (1920x1080, usada em todas as resoluções)
# ---------------------------------------------------------------------------
$surface = New-Surface 1920 1080
Draw-Background $surface.Graphics 1920 1080
Save-Png $surface 'bg.png'

# ---------------------------------------------------------------------------
# Marca (PNG transparente para o cabeçalho)
# ---------------------------------------------------------------------------
$surface = New-Surface 384 384
Draw-Mark $surface.Graphics 0 0 384
Save-Png $surface 'logo.png'

# ---------------------------------------------------------------------------
# Cards da interface (gerados em 1.5x para telas 1080p)
# ---------------------------------------------------------------------------
New-Card 'card.png'           270 294 18 '121A2B' '1F2C45' 2
New-Card 'card_focus.png'     270 294 18 '15263E' '00C2A8' 4
New-Card 'logo_box.png'       231 126 12 '0A101C' '182338' 2
New-Card 'category_card.png'  405 150 18 '121A2B' '1F2C45' 2
New-Card 'category_focus.png' 405 150 18 '15263E' '00C2A8' 4
New-Card 'setting_card.png'  1728 108 15 '121A2B' '1F2C45' 2
New-Card 'setting_focus.png' 1728 108 15 '15263E' '00C2A8' 4

# Botões do cabeçalho (tamanho exato para o indicador de foco do Roku)
New-Card 'btn_normal.png' 150 44 22 '16213A' '2B3A5C' 1
New-Card 'btn_focus.png'  150 44 22 '00C2A8' '00C2A8' 1

New-Star 'star.png' 96
New-Check 'check.png' 96

# ---------------------------------------------------------------------------
# Ícones da loja Roku
# ---------------------------------------------------------------------------
function New-FocusIcon([string]$fileName, [int]$width, [int]$height,
                       [single]$markSize, [single]$titleSize, [single]$tagSize) {
    $surface = New-Surface $width $height
    $graphics = $surface.Graphics
    $graphics.Clear((Color '070B14'))

    $markY = $height * 0.12
    Draw-Mark $graphics (($width - $markSize) / 2) $markY $markSize

    $titleFont = New-Font $titleSize 'Segoe UI' 'Bold'
    $tagFont = New-Font $tagSize 'Segoe UI' 'Regular'
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $teal = New-Object System.Drawing.SolidBrush((Color '57E6C8'))

    Draw-Text $graphics 'ChanIPTV' $titleFont $white 0 ($height * 0.56) $width ($height * 0.18)
    Draw-Text $graphics 'IPTV para todos' $tagFont $teal 0 ($height * 0.75) $width ($height * 0.10)

    $white.Dispose()
    $teal.Dispose()
    $titleFont.Dispose()
    $tagFont.Dispose()
    Save-Png $surface $fileName
}

New-FocusIcon 'icon_focus_fhd.png' 540 405 132 54 22
New-FocusIcon 'icon_focus_hd.png'  290 218 72  30 12
New-FocusIcon 'icon_focus_sd.png'  214 144 50  22 9

function New-SideIcon([string]$fileName, [int]$width, [int]$height,
                      [single]$markSize, [single]$titleSize, [single]$tagSize) {
    $surface = New-Surface $width $height
    $graphics = $surface.Graphics
    $graphics.Clear((Color '070B14'))

    $markX = $width * 0.07
    $markY = ($height - $markSize) / 2
    Draw-Mark $graphics $markX $markY $markSize

    $titleFont = New-Font $titleSize 'Segoe UI' 'Bold'
    $tagFont = New-Font $tagSize 'Segoe UI' 'Regular'
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $teal = New-Object System.Drawing.SolidBrush((Color '57E6C8'))

    $textX = $markX + $markSize + ($width * 0.045)
    $textW = $width - $textX - ($width * 0.05)
    Draw-Text $graphics 'ChanIPTV' $titleFont $white $textX ($height * 0.27) $textW ($height * 0.30) 'Left' 'Center'
    Draw-Text $graphics 'IPTV aberto para todos' $tagFont $teal $textX ($height * 0.55) $textW ($height * 0.17) 'Left' 'Center'

    $white.Dispose()
    $teal.Dispose()
    $titleFont.Dispose()
    $tagFont.Dispose()
    Save-Png $surface $fileName
}

New-SideIcon 'icon_side_fhd.png' 1080 405 170 76 30
New-SideIcon 'icon_side_hd.png'  580 218  92  42 16
New-SideIcon 'icon_side_sd.png'  428 144  68  30 12

# ---------------------------------------------------------------------------
# Splash screens
# ---------------------------------------------------------------------------
function New-Splash([string]$fileName, [int]$width, [int]$height,
                    [single]$markSize, [single]$titleSize, [single]$tagSize, [single]$footSize) {
    $surface = New-Surface $width $height
    $graphics = $surface.Graphics
    Draw-Background $graphics $width $height

    $markX = ($width - $markSize) / 2
    $markY = $height * 0.28
    Draw-Mark $graphics $markX $markY $markSize

    $titleFont = New-Font $titleSize 'Segoe UI' 'Bold'
    $tagFont = New-Font $tagSize 'Segoe UI' 'Regular'
    $footFont = New-Font $footSize 'Segoe UI' 'Regular'
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $teal = New-Object System.Drawing.SolidBrush((Color '57E6C8'))
    $muted = New-Object System.Drawing.SolidBrush((Color '7F8DA8'))

    Draw-Text $graphics 'ChanIPTV' $titleFont $white 0 ($height * 0.53) $width ($height * 0.12)
    Draw-Text $graphics 'IPTV aberto para todos' $tagFont $teal 0 ($height * 0.66) $width ($height * 0.06)
    Draw-Text $graphics 'Feito para Roku' $footFont $muted 0 ($height * 0.84) $width ($height * 0.05)

    $white.Dispose()
    $teal.Dispose()
    $muted.Dispose()
    $titleFont.Dispose()
    $tagFont.Dispose()
    $footFont.Dispose()
    Save-Png $surface $fileName
}

New-Splash 'splash_fhd.png' 1920 1080 224 96 34 24
New-Splash 'splash_hd.png'  1280 720  150 64 23 17
New-Splash 'splash_sd.png'  720 480   104 44 16 12

Write-Host 'Assets gerados em:' $imagesDir
