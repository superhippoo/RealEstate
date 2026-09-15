param([string]$a,[string]$b,[int]$x=0,[int]$y=0,[int]$w=1920,[int]$h=1080)
Add-Type -AssemblyName System.Drawing
$ba=[System.Drawing.Bitmap]::FromFile($a)
$bb=[System.Drawing.Bitmap]::FromFile($b)
$cnt=0;$minx=99999;$miny=99999;$maxx=-1;$maxy=-1
for($yy=$y;$yy -lt ($y+$h);$yy+=2){
  for($xx=$x;$xx -lt ($x+$w);$xx+=2){
    if($xx -lt $ba.Width -and $yy -lt $ba.Height){
      $ca=$ba.GetPixel($xx,$yy); $cb=$bb.GetPixel($xx,$yy)
      $d=[Math]::Abs($ca.R-$cb.R)+[Math]::Abs($ca.G-$cb.G)+[Math]::Abs($ca.B-$cb.B)
      if($d -gt 60){ $cnt++
        if($xx -lt $minx){$minx=$xx}; if($yy -lt $miny){$miny=$yy}
        if($xx -gt $maxx){$maxx=$xx}; if($yy -gt $maxy){$maxy=$yy}
      }
    }
  }
}
$ba.Dispose();$bb.Dispose()
if($cnt -eq 0){ Write-Output "DIFF none" } else {
  $cx=[int](($minx+$maxx)/2); $cy=[int](($miny+$maxy)/2)
  Write-Output ("DIFF count=" + $cnt + " bbox=" + $minx + "," + $miny + " - " + $maxx + "," + $maxy + " center=" + $cx + "," + $cy)
}
