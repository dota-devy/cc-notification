# Focus handler for claude-notify:// protocol
# Invoked by Windows when a toast notification is clicked
# Usage: focus-handler.ps1 "claude-notify://focus?pid=12345"

param([string]$Uri)

# Debug log (same location as toast-notification.ps1 debug log)
$LogPath = Join-Path $env:TEMP "cc-notification-focus.log"
function Write-Log { param([string]$Msg); "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - $Msg" | Out-File -FilePath $LogPath -Append -Encoding UTF8 }

Write-Log "=== Focus handler invoked ==="
Write-Log "URI: $Uri"

# Parse the URI to extract the PID
$TargetPid = $null
if ($Uri -match '[?&]pid=(\d+)') {
    $TargetPid = [int]$Matches[1]
}

if (-not $TargetPid) {
    Write-Log "No PID found in URI"
    exit 1
}

# Load Win32 interop for window management
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WindowFocusHelper {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();

    public const int SW_RESTORE = 9;

    public static bool ForceForeground(IntPtr targetHwnd) {
        IntPtr foregroundHwnd = GetForegroundWindow();
        if (foregroundHwnd == targetHwnd) return true;

        uint foregroundPid;
        uint foregroundThreadId = GetWindowThreadProcessId(foregroundHwnd, out foregroundPid);
        uint currentThreadId = GetCurrentThreadId();

        if (foregroundThreadId != currentThreadId) {
            AttachThreadInput(currentThreadId, foregroundThreadId, true);
        }

        if (IsIconic(targetHwnd)) {
            ShowWindow(targetHwnd, SW_RESTORE);
        }

        bool result = SetForegroundWindow(targetHwnd);

        if (foregroundThreadId != currentThreadId) {
            AttachThreadInput(currentThreadId, foregroundThreadId, false);
        }

        return result;
    }
}
"@

# Find the process and focus its window
$proc = Get-Process -Id $TargetPid -ErrorAction SilentlyContinue
if (-not $proc) {
    Write-Log "Process $TargetPid not found"
    exit 1
}

Write-Log "Process found: $($proc.ProcessName), MainWindowHandle: $($proc.MainWindowHandle), Title: '$($proc.MainWindowTitle)'"

if ($proc.MainWindowHandle -eq [IntPtr]::Zero) {
    Write-Log "Process has no main window handle"
    exit 1
}

$result = [WindowFocusHelper]::ForceForeground($proc.MainWindowHandle)
Write-Log "ForceForeground result: $result"
exit 0
