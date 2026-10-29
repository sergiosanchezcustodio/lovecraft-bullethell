"""Lanza un programa en un escritorio de Windows aparte (29-10-2026).

Las pruebas de Godot lanzadas desde Claude Code abren una ventana y, aunque se pida sin foco
(no_focus), Windows se lo da un instante al crearla: medido, unos 90 ms. Basta para que el juego
al que esté jugando el autor en este PC pierda el foco y deje de hacer caso al mando. Una ventana
de otro escritorio (como el de la pantalla de bloqueo, no un escritorio virtual de Windows 11) no
puede quitar el foco al escritorio en uso, haga lo que haga.

Uso: python tools/escritorio_aparte.py programa [argumentos...]
La salida y el código de salida son los del programa. El escritorio («LovecraftPruebas») se crea
la primera vez y Windows lo quita al cerrarse el último programa que lo usa. El programa va en un
«job» que se cierra con este script: si la prueba se corta (timeout, Ctrl+C), Godot no se queda
abierto en un escritorio que no se ve.
"""
import ctypes
import subprocess
import sys
from ctypes import wintypes

DESKTOP = "LovecraftPruebas"
GENERIC_ALL = 0x10000000
HANDLE_FLAG_INHERIT = 1
STARTF_USESTDHANDLES = 0x100
INFINITE = 0xFFFFFFFF
CREATE_SUSPENDED = 0x4
JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x2000
JobObjectExtendedLimitInformation = 9

k32 = ctypes.WinDLL("kernel32", use_last_error=True)
u32 = ctypes.WinDLL("user32", use_last_error=True)


class STARTUPINFOW(ctypes.Structure):
    _fields_ = [("cb", wintypes.DWORD), ("lpReserved", wintypes.LPWSTR), ("lpDesktop", wintypes.LPWSTR),
                ("lpTitle", wintypes.LPWSTR), ("dwX", wintypes.DWORD), ("dwY", wintypes.DWORD),
                ("dwXSize", wintypes.DWORD), ("dwYSize", wintypes.DWORD), ("dwXCountChars", wintypes.DWORD),
                ("dwYCountChars", wintypes.DWORD), ("dwFillAttribute", wintypes.DWORD), ("dwFlags", wintypes.DWORD),
                ("wShowWindow", wintypes.WORD), ("cbReserved2", wintypes.WORD), ("lpReserved2", ctypes.c_void_p),
                ("hStdInput", wintypes.HANDLE), ("hStdOutput", wintypes.HANDLE), ("hStdError", wintypes.HANDLE)]


class PROCESS_INFORMATION(ctypes.Structure):
    _fields_ = [("hProcess", wintypes.HANDLE), ("hThread", wintypes.HANDLE),
                ("dwProcessId", wintypes.DWORD), ("dwThreadId", wintypes.DWORD)]


class JOBOBJECT_BASIC_LIMIT_INFORMATION(ctypes.Structure):
    _fields_ = [("PerProcessUserTimeLimit", ctypes.c_int64), ("PerJobUserTimeLimit", ctypes.c_int64),
                ("LimitFlags", wintypes.DWORD), ("MinimumWorkingSetSize", ctypes.c_size_t),
                ("MaximumWorkingSetSize", ctypes.c_size_t), ("ActiveProcessLimit", wintypes.DWORD),
                ("Affinity", ctypes.c_size_t), ("PriorityClass", wintypes.DWORD), ("SchedulingClass", wintypes.DWORD)]


class IO_COUNTERS(ctypes.Structure):
    _fields_ = [(n, ctypes.c_uint64) for n in ("ReadOperationCount", "WriteOperationCount", "OtherOperationCount",
                                               "ReadTransferCount", "WriteTransferCount", "OtherTransferCount")]


class JOBOBJECT_EXTENDED_LIMIT_INFORMATION(ctypes.Structure):
    _fields_ = [("BasicLimitInformation", JOBOBJECT_BASIC_LIMIT_INFORMATION), ("IoInfo", IO_COUNTERS),
                ("ProcessMemoryLimit", ctypes.c_size_t), ("JobMemoryLimit", ctypes.c_size_t),
                ("PeakProcessMemoryUsed", ctypes.c_size_t), ("PeakJobMemoryUsed", ctypes.c_size_t)]


k32.CreateJobObjectW.restype = wintypes.HANDLE
k32.CreateJobObjectW.argtypes = [ctypes.c_void_p, wintypes.LPCWSTR]
k32.SetInformationJobObject.argtypes = [wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD]
k32.AssignProcessToJobObject.argtypes = [wintypes.HANDLE, wintypes.HANDLE]
k32.ResumeThread.argtypes = [wintypes.HANDLE]
u32.CreateDesktopW.restype = wintypes.HANDLE
u32.CreateDesktopW.argtypes = [wintypes.LPCWSTR, wintypes.LPCWSTR, ctypes.c_void_p, wintypes.DWORD,
                               wintypes.DWORD, ctypes.c_void_p]
k32.GetStdHandle.restype = wintypes.HANDLE
k32.CreateProcessW.argtypes = [wintypes.LPCWSTR, wintypes.LPWSTR, ctypes.c_void_p, ctypes.c_void_p, wintypes.BOOL,
                               wintypes.DWORD, ctypes.c_void_p, wintypes.LPCWSTR, ctypes.POINTER(STARTUPINFOW),
                               ctypes.POINTER(PROCESS_INFORMATION)]


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    desk = u32.CreateDesktopW(DESKTOP, None, None, 0, GENERIC_ALL, None)   # o abre el que ya hay
    if not desk:
        print("escritorio_aparte: no se pudo crear el escritorio (%d); lanzo en el normal" % ctypes.get_last_error(),
              file=sys.stderr)
        return subprocess.call(sys.argv[1:])
    si = STARTUPINFOW()
    si.cb = ctypes.sizeof(si)
    si.lpDesktop = "WinSta0\\" + DESKTOP
    si.dwFlags = STARTF_USESTDHANDLES
    handles = []
    for n in (-10, -11, -12):                      # entrada, salida y errores: los de quien lanza (las tuberías de bash)
        h = k32.GetStdHandle(n)
        if h and h != wintypes.HANDLE(-1).value:
            k32.SetHandleInformation(wintypes.HANDLE(h), HANDLE_FLAG_INHERIT, HANDLE_FLAG_INHERIT)
        handles.append(h)
    si.hStdInput, si.hStdOutput, si.hStdError = handles
    job = k32.CreateJobObjectW(None, None)          # al cerrarse (al acabar este script, como sea), cierra el programa
    info = JOBOBJECT_EXTENDED_LIMIT_INFORMATION()
    info.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
    k32.SetInformationJobObject(job, JobObjectExtendedLimitInformation, ctypes.byref(info), ctypes.sizeof(info))
    pi = PROCESS_INFORMATION()
    cmd = subprocess.list2cmdline(sys.argv[1:])
    if not k32.CreateProcessW(None, cmd, None, None, True, CREATE_SUSPENDED, None, None, ctypes.byref(si),
                              ctypes.byref(pi)):
        print("escritorio_aparte: no se pudo lanzar (%d)" % ctypes.get_last_error(), file=sys.stderr)
        return 1
    k32.AssignProcessToJobObject(job, pi.hProcess)  # antes de que arranque: sus hijos (Godot de verdad) también
    k32.ResumeThread(pi.hThread)
    try:
        k32.WaitForSingleObject(pi.hProcess, INFINITE)
    except KeyboardInterrupt:                      # Ctrl+C o timeout: que no quede Godot suelto en el escritorio invisible
        k32.TerminateProcess(pi.hProcess, 1)
    code = wintypes.DWORD()
    k32.GetExitCodeProcess(pi.hProcess, ctypes.byref(code))
    k32.CloseHandle(pi.hThread)
    k32.CloseHandle(pi.hProcess)
    u32.CloseDesktop(desk)
    return code.value


if __name__ == "__main__":
    sys.exit(main())
