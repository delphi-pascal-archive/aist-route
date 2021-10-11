unit F_SysUtils;

interface

uses
  Windows, Messages, ShellApi, F_Windows;

function CharReplaceW(pszText: WideString; oldChar, newChar: WideChar): WideString;
function LoadStrW(I: Integer): WideString;
function IntToStrW(I: Integer): WideString;
function StrToIntW(pszText: WideString): Integer;
function FormatW(pszText: WideString; const Params: Array of const): WideString;
function FileExistsW(pszText: WideString): Boolean;
function IsManifestAvailableW(pszText: WideString): Boolean;
function TrimW(pszText: WideString): WideString;
function WideStringToAnsi(pszText: WideString; CodePage: WORD): AnsiString;
function AnsiStringToWide(pszText: AnsiString; CodePage: WORD): WideString;
function SetCenterDialogPos(hDialog, hParent: HWND; IsParent: Boolean): Boolean;
function ExtractFilePathW(pszText: WideString): WideString;
function ExtractFileExtW(pszText: WideString): WideString;
function SysErrorMessageW(ErrorCode: Integer): WideString;
function ShellExecuteAndWaitW(CmdStr: WideString; CmdShow: Integer): Boolean;
procedure SetTextToClipboard(hWnd: HWND; pszText: Pointer; SetUnicode: Boolean);
function SetEnableWindowW(hWnd: HWND; fEnable: Boolean): Boolean;
function GetWindowFontSizeW(hWnd: HWND; pSize: Integer): Integer;
function GetPixelFromDialogUnitX(x: Integer): Integer;
function GetPixelFromDialogUnitY(y: Integer): Integer;

implementation

//

function CharReplaceW(pszText: WideString; oldChar, newChar: WideChar): WideString;
var
  I: Integer;
begin
  Result := pszText;
  for I := 1 to Length(Result) do
    if Result[I] = oldChar then
      Result[I] := newChar
end;

//

function LoadStrW(I: Integer): WideString;
var
  lpBuffer: Array [0..MAX_PATH-1] of WideChar;
begin
  LoadStringW(HInstance, I, lpBuffer, Length(lpBuffer));
  Result := lpBuffer;
end;

//

function IntToStrW(I: Integer): WideString;
begin
  Str(I, Result);
end;

//

function StrToIntW(pszText: WideString): Integer;
var
  I: Integer;
begin
  Val(pszText, Result, I);
end;

//

function FormatW(pszText: WideString; const Params: Array of const): WideString;
var
  lpChar: Array [0..1023] of WideChar;
  lpWord: Array [0..15] of LongWord;
  nIndex: Integer;
begin
  for nIndex := High(Params) downto 0 do
    lpWord[nIndex] := Params[nIndex].VInteger;
  wvsprintfW(@lpChar, LPWSTR(pszText), @lpWord);
  Result := lpChar;
end;

//

function FileExistsW(pszText: WideString): Boolean;
var
  att: DWORD;
begin
  att := GetFileAttributesW(LPWSTR(pszText));
  Result := (att <> $FFFFFFFF) and (att and FILE_ATTRIBUTE_DIRECTORY = 0);
end;

//

function IsManifestAvailableW(pszText: WideString): Boolean;
  function EnumResTypeProc(hModule: HMODULE; lpszType: LPWSTR; lParam: LPARAM): BOOL; stdcall;
    begin
      Result := lpszType <> MAKEINTRESOURCEW(24);
    end;
const
  fmtMan: WideString = '%s.manifest';
var
  hmod: HMODULE;
  osvi: TOSVersionInfoW;
begin
  Result := FALSE;
  ZeroMemory(@osvi, SizeOf(TOSVersionInfoW));
  osvi.dwOSVersionInfoSize := SizeOf(TOSVersionInfoW);
  if not F_Windows.GetVersionExW(osvi) then
    Exit;
  if not ((osvi.dwMajorVersion > 5) or ((osvi.dwMajorVersion = 5) and
    (osvi.dwMinorVersion >= 1))) then
    Exit;
  Result := FileExistsW(FormatW(fmtMan, [pszText]));
  if not Result then
    begin
      hmod := LoadLibraryW(LPWSTR(pszText));
      if (hmod <> 0) then
        Result := not EnumResourceTypesW(hmod, @EnumResTypeProc, 0);
      if (hmod <> 0) then
        FreeLibrary(hmod);
    end;
end;

//

function TrimW(pszText: WideString): WideString;
var
  I: Integer;
  L: Integer;
begin
  L := Length(pszText);
  I := 1;
  while (I <= L) and (pszText[I] <= ' ') do
    Inc(I);
  if (I > L) then
    Result := ''
  else
  begin
    while (pszText[L] <= ' ') do
      Dec(L);
    Result := Copy(pszText, I, L - I + 1);
  end;
end;

//

function WideStringToAnsi(pszText: WideString; CodePage: WORD): AnsiString;
var
  dwBytes: Integer;
  dwFlags: DWORD;
begin
  if (pszText <> '') then
  begin
    dwFlags := WC_COMPOSITECHECK or WC_DISCARDNS or WC_SEPCHARS or WC_DEFAULTCHAR;
    dwBytes := WideCharToMultiByte(CodePage, dwFlags, LPWSTR(pszText), -1, nil,
      0, nil, nil);
    SetLength(Result, dwBytes - 1);
    if (dwBytes > 1) then
      WideCharToMultiByte(CodePage, dwFlags, LPWSTR(pszText), -1, LPTSTR(Result),
        dwBytes - 1, nil, nil);
  end
  else
    Result := '';
end;

//

function AnsiStringToWide(pszText: AnsiString; CodePage: WORD): WideString;
var
  dwBytes: Integer;
begin
  if (pszText <> '') then
  begin
    dwBytes := MultiByteToWideChar(CodePage, MB_PRECOMPOSED, LPTSTR(pszText), -1,
      nil, 0);
    SetLength(Result, dwBytes - 1);
    if (dwBytes > 1) then
      MultiByteToWideChar(CodePage, MB_PRECOMPOSED, LPTSTR(pszText), -1,
        LPWSTR(Result), dwBytes - 1);
  end
  else
    Result := '';
end;

//

function SetCenterDialogPos(hDialog, hParent: HWND; IsParent: Boolean): Boolean;
var
  wRect  : TRect;
  pRect  : TRect;
  wArea  : TRect;
  xLeft  : Integer;
  yTop   : Integer;
  iWidth : Integer;
  iHeight: Integer;
  dwFlags: DWORD;
begin
  if IsParent then
  begin
    GetWindowRect(hDialog, wRect);
    GetWindowRect(hParent, pRect);
    iWidth  := wRect.Right - wRect.Left;
    iHeight := wRect.Bottom - wRect.Top;
    SystemParametersInfoW(SPI_GETWORKAREA, 0, @wArea, 0);
    xLeft := pRect.Left + ((pRect.Right - pRect.Left - iWidth) div 2);
    if (xLeft < 0) then
      xLeft := 0
    else
    if ((xLeft + iWidth) > (wArea.Right - wArea.Left)) then
      xLeft := wArea.Right - wArea.Left - iWidth;
    yTop := pRect.Top + ((pRect.Bottom - pRect.Top - iHeight) div 2);
    if (yTop < 0) then
      yTop := 0
    else
    if ((yTop + iHeight) > (wArea.Bottom - wArea.Top)) then
      yTop := wArea.Bottom - wArea.Top - iHeight;
  end
  else
  begin
    GetWindowRect(hDialog, wRect);
    iWidth  := wRect.Right - wRect.Left;
    iHeight := wRect.Bottom - wRect.Top;
    xLeft := (GetSystemMetrics(SM_CXSCREEN) - iWidth) div 2;
    yTop  := (GetSystemMetrics(SM_CYSCREEN) - iHeight) div 2;
  end;
  dwFlags := SWP_NOACTIVATE or SWP_NOSIZE or SWP_NOZORDER;
  Result := SetWindowPos(hDialog, 0, xLeft, yTop, 0, 0, dwFlags);
end;

//

function ExtractFilePathW(pszText: WideString): WideString;
var
  L: Integer;
begin
  Result := '';
  L := Length(pszText);
  while (L > 0) do
  begin
    if (pszText[L] = ':') or (pszText[L] = '\') then
    begin
      Result := Copy(pszText, 1, L);
      Break;
    end;
    Dec(L);
  end;
end;

//

function ExtractFileExtW(pszText: WideString): WideString;
var
  L: Integer;
begin
  L := Length(pszText);
  while (L > 0) do
  begin
    if (pszText[L] = '.') then
      Break;
    Dec(L);
  end;
  if (L = 0) then
    Result := pszText
  else
    Result := Copy(pszText, 1, L - 1);
end;

//

function SysErrorMessageW(ErrorCode: Integer): WideString;
begin
  SetLength(Result, MAX_PATH);
  FormatMessageW(
    FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ARGUMENT_ARRAY,
    nil,
    ErrorCode,
    0,
    LPWSTR(Result),
    MAX_PATH,
    nil
  );
end;

//

function ShellExecuteAndWaitW(CmdStr: WideString; CmdShow: Integer): Boolean;
var
  se     : TShellExecuteInfoW;
  dwRet  : DWORD;
  bResult: Boolean;
begin
  ZeroMemory(@se, SizeOf(TShellExecuteInfoW));
  with se do
  begin
    cbSize := SizeOf(TShellExecuteInfoW);
    fMask  := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_DDEWAIT;
    lpFile := LPWSTR(CmdStr);
    nShow  := CmdShow;
  end;
  bResult := ShellExecuteExW(@se);
  if (bResult and (se.hProcess <> 0)) then
  begin
    dwRet := WaitForSingleObject(se.hProcess, 2000);
    bResult := dwRet <> WAIT_ABANDONED;
    CloseHandle(se.hProcess);
  end;
  Result := bResult;
end;

//

procedure SetTextToClipboard(hWnd: HWND; pszText: Pointer; SetUnicode: Boolean);
const
  uFormats: Array [Boolean] of Byte = (CF_TEXT, CF_UNICODETEXT);
var
  hGlobal: THandle;
  dCopy  : Pointer;
  dwBytes: Integer;
begin
  OpenClipboard(hWnd);
  try
    EmptyClipboard;
    if SetUnicode then
      dwBytes := lstrlenW(LPWSTR(pszText)) * 2 + 1
    else
      dwBytes := lstrlen(LPTSTR(pszText)) + 1;
    hGlobal := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, dwBytes);
    try
      dCopy := GlobalLock(hGlobal);
      try
        if SetUnicode then
          CopyMemory(dCopy, LPWSTR(pszText), dwBytes)
        else
          CopyMemory(dCopy, LPTSTR(pszText), dwBytes);
        SetClipboardData(uFormats[SetUnicode], hGlobal);
      finally
        GlobalUnlock(hGlobal);
      end;
    except
      GlobalFree(hGlobal);
    end;
  finally
    CloseClipboard;
  end;
end;

//

function SetEnableWindowW(hWnd: HWND; fEnable: Boolean): Boolean;
var
  hParent: THandle;
  hFocus : THandle;
begin
  hParent := GetParent(hWnd);
  hFocus := GetFocus;
  if (hFocus = hWnd) then
    SendMessageW(hParent, WM_NEXTDLGCTL, 0, 0);
  Result := EnableWindow(hWnd, fEnable);
end;

//

function GetWindowFontSizeW(hWnd: HWND; pSize: Integer): Integer;
var
  dc: HDC;
begin
  dc := GetDC(hWnd);
  Result := -MulDiv(pSize, GetDeviceCaps(dc, LOGPIXELSY), 72);
  ReleaseDC(hWnd, dc);
end;

//

function GetPixelFromDialogUnitX(x: Integer): Integer;
begin
  Result := (x * LoWord(GetDialogBaseUnits)) div 4;
end;

//

function GetPixelFromDialogUnitY(y: Integer): Integer;
begin
  Result := (y * HiWord(GetDialogBaseUnits)) div 8;
end;

end.