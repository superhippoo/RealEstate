param([string]$path="D:\works\realestate\web_build\qa_shots\shot.png")
$ErrorActionPreference="Continue"
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null=[Windows.Media.Ocr.OcrEngine,Windows.Media.Ocr,ContentType=WindowsRuntime]
$null=[Windows.Graphics.Imaging.BitmapDecoder,Windows.Graphics.Imaging,ContentType=WindowsRuntime]
$null=[Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime]
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($WinRtTask,$ResultType){ $asTask=$asTaskGeneric.MakeGenericMethod($ResultType); $netTask=$asTask.Invoke($null,@($WinRtTask)); $netTask.Wait(-1)|Out-Null; $netTask.Result }
try { $file=Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($path)) ([Windows.Storage.StorageFile]) } catch { Write-Output "NOFILE"; exit }
$stream=Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
$decoder=Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
$bmp=Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
$lang=[Windows.Globalization.Language,Windows.Globalization,ContentType=WindowsRuntime]::new("ko-KR")
if([Windows.Media.Ocr.OcrEngine]::IsLanguageSupported($lang)){ $eng=[Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($lang); Write-Output "ENGINE=ko-KR" }
else { $eng=[Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages(); Write-Output ("ENGINE=fallback:" + $eng.RecognizerLanguage.LanguageTag) }
$result=Await ($eng.RecognizeAsync($bmp)) ([Windows.Media.Ocr.OcrResult])
$ci=[System.Globalization.CultureInfo]::InvariantCulture
foreach($line in $result.Lines){
  $x1=99999; $y1=99999; $x2=0; $y2=0; $ok=$false
  foreach($wr in $line.Words){
    try{
      $s=[string]$wr.BoundingRect
      $p=$s.Split(',')
      if($p.Count -ge 4){
        $wx=[double]::Parse($p[0],$ci); $wy=[double]::Parse($p[1],$ci); $ww=[double]::Parse($p[2],$ci); $wh=[double]::Parse($p[3],$ci)
        if($wx -lt $x1){$x1=$wx}; if($wy -lt $y1){$y1=$wy}; if(($wx+$ww) -gt $x2){$x2=$wx+$ww}; if(($wy+$wh) -gt $y2){$y2=$wy+$wh}; $ok=$true
      }
    }catch{}
  }
  if($ok){
    $cx=[int](($x1+$x2)/2); $cy=[int](($y1+$y2)/2)
    Write-Output ("TEXT[int$x1,int$y1,int$x2,int$y2,c=$cx,$cy] " + $line.Text)
  } else {
    Write-Output ("TEXT[norect] " + $line.Text)
  }
}
