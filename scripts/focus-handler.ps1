# Focus handler for claude-notify:// protocol
# Invoked by Windows when a toast notification is clicked
# Usage: focus-handler.ps1 "claude-notify://focus?pid=12345"

param([string]$Uri)

# Parse the URI to extract the PID
$TargetPid = $null
if ($Uri -match '[?&]pid=(\d+)') {
    $TargetPid = [int]$Matches[1]
}

if (-not $TargetPid) {
    Write-Host "focus-handler: no PID found in URI: $Uri"
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
if (-not $proc -or $proc.MainWindowHandle -eq [IntPtr]::Zero) {
    Write-Host "focus-handler: process $TargetPid not found or has no window"
    exit 1
}

[WindowFocusHelper]::ForceForeground($proc.MainWindowHandle) | Out-Null
exit 0
