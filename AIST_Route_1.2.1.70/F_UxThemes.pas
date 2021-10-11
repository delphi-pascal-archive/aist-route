unit F_UxThemes;

interface

uses
  Windows;

procedure FreeThemeLibrary;
function InitThemeLibrary: Boolean;
function IsUseThemes: Boolean;

type

  HTHEME = THandle;

var

  OpenThemeData           : function(hWnd: HWND; pszClassList: LPCWSTR): HTHEME; stdcall;
  CloseThemeData          : function(hTheme: HTHEME): HRESULT; stdcall;
  DrawThemeBackground     : function(hTheme: HTHEME; hdc: HDC; iPartId, iStateId: Integer; const pRect: TRect; pClipRect: pRect): HRESULT; stdcall;
  IsThemeActive           : function: BOOL; stdcall;
  IsAppThemed             : function: BOOL; stdcall;
  GetWindowTheme          : function(hWnd: HWND): HTHEME; stdcall;
  EnableThemeDialogTexture: function(hWnd: HWND; dwFlags: DWORD): HRESULT; stdcall;
  SetWindowTheme          : function(hwnd: HWND; pszSubAppName: LPCWSTR; pszSubIdList: LPCWSTR): HRESULT; stdcall;

const

  CBS_UNCHECKEDNORMAL = 1;
  CBS_UNCHECKEDHOT    = 2;
  CBS_CHECKEDNORMAL   = 5;
  CBS_CHECKEDHOT      = 6;

  BP_CHECKBOX         = 3;
  BP_PUSHBUTTON       = 1;

  PBS_NORMAL          = 1;
  PBS_HOT             = 2;
  PBS_PRESSED         = 3;
  PBS_DISABLED        = 4;
  PBS_DEFAULTED       = 5;

  SP_GRIPPER          = 3;

implementation

const

  themelib: WideString = 'uxtheme.dll';

var

  cs     : TRTLCriticalSection;
  UxTheme: HMODULE;
  ref    : Integer;

//

procedure FreeThemeLibrary;
begin
  EnterCriticalSection(cs);
  try
    if (ref > 0) then
      Dec(ref);
    if (UxTheme <> 0) and (ref = 0) then
    begin
      FreeLibrary(UxTheme);
      UxTheme                  := 0;
      OpenThemeData            := nil;
      CloseThemeData           := nil;
      DrawThemeBackground      := nil;
      IsThemeActive            := nil;
      IsAppThemed              := nil;
      GetWindowTheme           := nil;
      EnableThemeDialogTexture := nil;
      SetWindowTheme           := nil;
    end;
  finally
    LeaveCriticalSection(cs);
  end;
end;

//

function InitThemeLibrary: Boolean;
begin
  EnterCriticalSection(cs);
  try
    Inc(ref);
    if (UxTheme = 0) then
    begin
      UxTheme := LoadLibraryW(LPWSTR(themelib));
      if (UxTheme <> 0) then
      begin
        OpenThemeData            := GetProcAddress(UxTheme, LPTSTR('OpenThemeData'));
        CloseThemeData           := GetProcAddress(UxTheme, LPTSTR('CloseThemeData'));
        DrawThemeBackground      := GetProcAddress(UxTheme, LPTSTR('DrawThemeBackground'));
        IsThemeActive            := GetProcAddress(UxTheme, LPTSTR('IsThemeActive'));
        IsAppThemed              := GetProcAddress(UxTheme, LPTSTR('IsAppThemed'));
        GetWindowTheme           := GetProcAddress(UxTheme, LPTSTR('GetWindowTheme'));
        EnableThemeDialogTexture := GetProcAddress(UxTheme, LPTSTR('EnableThemeDialogTexture'));
        SetWindowTheme           := GetProcAddress(UxTheme, LPTSTR('SetWindowTheme'));
      end;
    end;
    Result := (UxTheme <> 0) and
      (@OpenThemeData <> nil) and
      (@CloseThemeData <> nil) and
      (@DrawThemeBackground <> nil) and
      (@IsThemeActive <> nil) and
      (@IsAppThemed <> nil) and
      (@GetWindowTheme <> nil) and
      (@EnableThemeDialogTexture <> nil) and
      (@SetWindowTheme <> nil);
  finally
    LeaveCriticalSection(cs);
  end;
end;

//

function IsUseThemes: Boolean;
begin
  Result := (IsAppThemed and IsThemeActive) and (UxTheme <> 0);
end;

initialization

  InitializeCriticalSection(cs);

finalization

  while (ref > 0) do
    FreeThemeLibrary;
  DeleteCriticalSection(cs);
  
end.