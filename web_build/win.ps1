param([string]$mode="list",[int]$hwnd=0,[int]$x=0,[int]$y=0,[int]$w=0,[int]$h=0)
$src=@"
using System;
using System.Text;
using System.Runtime.InteropServices;
using System.Collections.Generic;
public class W {
  public delegate bool EnumProc(IntPtr h,IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb,IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetWindowTextW(IntPtr h,[MarshalAs(UnmanagedType.LPWStr)]StringBuilder s,int n);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int cmd);
  [DllImport("user32.dll")] public static extern void keybd_event(byte k,byte s,uint f,UIntPtr e);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h,IntPtr a,int x,int y,int w,int hh,uint f);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L,T,R,B; }
  public static List<string> Found = new List<string>();
  public static bool Cb(IntPtr h,IntPtr l){
    if(!IsWindowVisible(h)) return true;
    uint pid; GetWindowThreadProcessId(h,out pid);
    var sb=new StringBuilder(512); GetWindowTextW(h,sb,512);
    var t=sb.ToString();
    if(t.Length==0) return true;
    RECT r; GetWindowRect(h,out r);
    Found.Add(h.ToInt64()+"|"+pid+"|"+t+"|"+r.L+","+r.T+","+r.R+","+r.B);
    return true;
  }
}
"@
Add-Type -TypeDefinition $src
if($mode -eq "list"){
  $script:found=@()
  $cb=[W+EnumProc]{
    param($h,$l)
    if([W]::IsWindowVisible($h)){
      $sb=New-Object System.Text.StringBuilder 512
      [W]::GetWindowTextW($h,$sb,512)|Out-Null
      $t=$sb.ToString()
      if($t.Length -gt 0){
        $pid2=0; [W+RECT]$r=New-Object W+RECT
        [W]::GetWindowThreadProcessId($h,[ref]$pid2)|Out-Null
        [W]::GetWindowRect($h,[ref]$r)|Out-Null
        $script:found += ("{0}|{1}|{2}|{3},{4},{5},{6}" -f $h.ToInt64(),$pid2,$t,$r.L,$r.T,$r.R,$r.B)
      }
    }
    return $true
  }
  [W]::EnumWindows($cb,[IntPtr]::Zero)|Out-Null
  foreach($f in $script:found){
    $p=$f.Split('|')[1]
    $pn=(Get-Process -Id $p -ErrorAction SilentlyContinue).ProcessName
    if($pn -match "msedge|chrome"){ Write-Output ($f + "|" + $pn) }
  }
} elseif($mode -eq "move"){
  $wh=[IntPtr]$hwnd
  [W]::SetWindowPos($wh,[IntPtr]::Zero,$x,$y,$w,$h,0x0004)|Out-Null
  Start-Sleep -Milliseconds 250
  Write-Output ("MOVED " + $hwnd + " to " + $x + "," + $y + " " + $w + "x" + $h)
} elseif($mode -eq "close"){
  $h=[IntPtr]$hwnd
  [W]::PostMessage($h,0x0010,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null
  Start-Sleep -Milliseconds 400
  Write-Output ("CLOSED " + $hwnd)
} elseif($mode -eq "activate"){
  $h=[IntPtr]$hwnd
  [W]::keybd_event(0x12,0,0,[UIntPtr]::Zero); [W]::keybd_event(0x12,0,2,[UIntPtr]::Zero)
  [W]::ShowWindow($h,9)|Out-Null
  Start-Sleep -Milliseconds 150
  [W]::SetForegroundWindow($h)|Out-Null
  Start-Sleep -Milliseconds 400
  Write-Output ("ACTIVATED " + $hwnd)
}
