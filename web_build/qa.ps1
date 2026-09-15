param(
  [string]$mode,
  [int]$x=0,[int]$y=0,[int]$w=0,[int]$h=0,[double]$scale=2.0,
  [string]$path="D:\works\realestate\web_build\qa_shots\shot.png",
  [int]$delayMs=180
)
$src = @"
using System;
using System.Runtime.InteropServices;
public class QA {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int X,int Y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint dx,uint dy,uint dw,UIntPtr e);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern int GetSystemMetrics(int n);
}
"@
Add-Type -TypeDefinition $src
[QA]::SetProcessDPIAware() | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
switch($mode){
 "info" {
   Write-Output ("SM0=" + [QA]::GetSystemMetrics(0) + " SM1=" + [QA]::GetSystemMetrics(1))
   $b=[System.Windows.Forms.SystemInformation]::VirtualScreen
   Write-Output ("VIRTUAL " + $b.X + "," + $b.Y + " " + $b.Width + "x" + $b.Height)
 }
 "green" {
   $bmp=[System.Drawing.Bitmap]::FromFile($path)
   $sum=0.0;$n=0
   for($yy=$y;$yy -lt ($y+$h);$yy+=3){
     for($xx=$x;$xx -lt ($x+$w);$xx+=3){
       if($xx -lt $bmp.Width -and $yy -lt $bmp.Height){
         $c=$bmp.GetPixel($xx,$yy)
         $sum += ($c.G - [Math]::Max($c.R,$c.B)); $n++
       }
     }
   }
   $bmp.Dispose()
   Write-Output ("GREEN avg=" + [math]::Round($sum/$n,1) + " n=" + $n)
 }
 "stats" {
   $bmp=[System.Drawing.Bitmap]::FromFile($path)
   $set=New-Object System.Collections.Generic.HashSet[int]
   $sumR=0.0;$sumG=0.0;$sumB=0.0;$n=0
   for($yy=$y;$yy -lt ($y+$h);$yy+=7){
     for($xx=$x;$xx -lt ($x+$w);$xx+=7){
       if($xx -lt $bmp.Width -and $yy -lt $bmp.Height){
         $c=$bmp.GetPixel($xx,$yy)
         $sumR+=$c.R;$sumG+=$c.G;$sumB+=$c.B;$n++
         [void]$set.Add((($c.R/32)*100+(($c.G)/32)*10+[int]($c.B/32)))
       }
     }
   }
   $bmp.Dispose()
   Write-Output ("STATS avgRGB=" + [int]($sumR/$n) + "," + [int]($sumG/$n) + "," + [int]($sumB/$n) + " distinct32=" + $set.Count + " samples=" + $n)
 }
 "shot" {
   $w0=[QA]::GetSystemMetrics(0); $h0=[QA]::GetSystemMetrics(1)
   $bmp=New-Object System.Drawing.Bitmap($w0,$h0)
   $g=[System.Drawing.Graphics]::FromImage($bmp)
   $g.CopyFromScreen(0,0,0,0,$bmp.Size)
   $dir=Split-Path $path; if(!(Test-Path $dir)){New-Item -ItemType Directory -Force -Path $dir|Out-Null}
   $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
   Write-Output "SAVED $path"
 }
 "zoom" {
   $bmp0=New-Object System.Drawing.Bitmap($w,$h)
   $g0=[System.Drawing.Graphics]::FromImage($bmp0)
   $g0.CopyFromScreen($x,$y,0,0,(New-Object System.Drawing.Size($w,$h)))
   $bw=[int]($w*$scale); $bh=[int]($h*$scale)
   $bmp=New-Object System.Drawing.Bitmap($bw,$bh)
   $g=[System.Drawing.Graphics]::FromImage($bmp)
   $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
   $g.DrawImage($bmp0,0,0,$bw,$bh)
   $dir=Split-Path $path; if(!(Test-Path $dir)){New-Item -ItemType Directory -Force -Path $dir|Out-Null}
   $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
   $g0.Dispose();$bmp0.Dispose();$g.Dispose();$bmp.Dispose()
   Write-Output "SAVED $path"
 }
 "move" {
   [QA]::SetCursorPos($x,$y)|Out-Null; Start-Sleep -Milliseconds $delayMs
   [QA]::SetCursorPos(($x+3),$y)|Out-Null; Start-Sleep -Milliseconds 90
   [QA]::SetCursorPos($x,$y)|Out-Null
   Write-Output "MOVED $x,$y"
 }
 "click" {
   [QA]::SetCursorPos($x,$y)|Out-Null; Start-Sleep -Milliseconds $delayMs
   [QA]::mouse_event(2,0,0,0,[UIntPtr]::Zero); Start-Sleep -Milliseconds 80
   [QA]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
   Write-Output "CLICKED $x,$y"
 }
}
