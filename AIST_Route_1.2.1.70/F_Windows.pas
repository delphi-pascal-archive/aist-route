unit F_Windows;

interface

uses
  Windows;

type
  _STARTUPINFOW = record
    cb             : DWORD;
    lpReserved     : LPWSTR;
    lpDesktop      : LPWSTR;
    lpTitle        : LPWSTR;
    dwX            : DWORD;
    dwY            : DWORD;
    dwXSize        : DWORD;
    dwYSize        : DWORD;
    dwXCountChars  : DWORD;
    dwYCountChars  : DWORD;
    dwFillAttribute: DWORD;
    dwFlags        : DWORD;
    wShowWindow    : Word;
    cbReserved2    : Word;
    lpReserved2    : PByte;
    hStdInput      : THandle;
    hStdOutput     : THandle;
    hStdError      : THandle;
  end;
  TStartupInfoW = _STARTUPINFOW;

const
  HEAP_ZERO_MEMORY = $00000008;

  ECM_FIRST        = $1500;         // Edit control messages
  EM_SETCUEBANNER  = ECM_FIRST + 1; // Set the cue banner with the lParm = LPCWSTR

function GetVersionExW(var lpVersionInformation: TOSVersionInfoW): BOOL; stdcall;
function LoadMenuW(hInstance: HINST; lpMenuName: LPWSTR): HMENU; stdcall;
function CreateProcessW(lpApplicationName: LPWSTR; lpCommandLine: LPWSTR; lpProcessAttributes, lpThreadAttributes: PSecurityAttributes; bInheritHandles: BOOL; dwCreationFlags: DWORD; lpEnvironment: Pointer; lpCurrentDirectory: LPWSTR; const lpStartupInfo: TStartupInfoW; var lpProcessInformation: TProcessInformation): BOOL; stdcall;

implementation

function GetVersionExW; external kernel32 name 'GetVersionExW';
function LoadMenuW; external user32 name 'LoadMenuW';
function CreateProcessW; external kernel32 name 'CreateProcessW';

end.