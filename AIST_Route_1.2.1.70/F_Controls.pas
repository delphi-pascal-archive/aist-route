unit F_Controls;

interface

uses
  Messages, Windows, CommCtrl, F_SysUtils;

function Edit_GetTextW(hWnd: HWND): WideString;
function ListBox_GetItemW(hWnd: HWND; nItem: Integer): WideString;
function ComboBox_GetItemW(hWnd: HWND; nItem: Integer): WideString;
function SysIPAddress32_GetTextW(hWnd: HWND): WideString;
procedure SysIPAddress32_SetTextW(hWnd: HWND; pszText: WideString);
function SysIPAddress32_IsBlankW(hWnd: HWND): Boolean;

implementation

//

function Edit_GetTextW(hWnd: HWND): WideString;
var
  L: Integer;
begin
  L := SendMessageW(hWnd, WM_GETTEXTLENGTH, 0, 0);
  if (L > 0) then
  begin
    SetLength(Result, L + 1);
    SendMessageW(hWnd, WM_GETTEXT, L + 1, Integer(LPWSTR(Result)));
  end
  else
    Result := '';
end;

//

function ListBox_GetItemW(hWnd: HWND; nItem: Integer): WideString;
var
  L: Integer;
begin
  L := SendMessageW(hWnd, LB_GETTEXTLEN, nItem, 0);
  if (L > 0) then
  begin
    SetLength(Result, L);
    SendMessageW(hWnd, LB_GETTEXT, nItem, Integer(LPWSTR(Result)));
  end
  else
    Result := '';
end;

//

function ComboBox_GetItemW(hWnd: HWND; nItem: Integer): WideString;
var
  L: Integer;
begin
  L := SendMessageW(hWnd, CB_GETLBTEXTLEN, nItem, 0);
  if (L > 0) then
  begin
    SetLength(Result, L);
    SendMessageW(hWnd, CB_GETLBTEXT, nItem, Integer(LPWSTR(Result)));
  end
  else
    Result := '';
end;

//

function SysIPAddress32_GetTextW(hWnd: HWND): WideString;
const
  fmtAddr: WideString = '%d.%d.%d.%d';
var
  pdwAddr : DWORD;
  ipFirst : DWORD;
  ipSecond: DWORD;
  ipThird : DWORD;
  ipFourth: DWORD;
begin
  SendMessageW(hWnd, IPM_GETADDRESS, 0, Integer(@pdwAddr));
  ipFirst  := (pdwAddr shr 24) and $FF;
  ipSecond := (pdwAddr shr 16) and $FF;
  ipThird  := (pdwAddr shr 8) and $FF;
  ipFourth := pdwAddr and $FF;
  Result := FormatW(fmtAddr, [ipFirst, ipSecond, ipThird, ipFourth]);
end;

//

procedure SysIPAddress32_SetTextW(hWnd: HWND; pszText: WideString);
var
  i      : Integer;
  dot    : Integer;
  pdwAddr: DWORD;
  number : DWORD;
begin
  pdwAddr := 0;
  number := 0;
  i := 0;
  repeat
    dot := Pos('.', pszText);
    if (dot <= 1) then
      if (i < 3) then
        Break
      else
        number := StrToIntW(pszText)
    else
      number := StrToIntW(Copy(pszText, 1, dot - 1));
    if (number > 255) then
      Break;
    Delete(pszText, 1, dot);
    pdwAddr := (pdwAddr shl 8) or number;
    Inc(i);
  until
    i > 3;
  SendMessageW(hWnd, IPM_SETADDRESS, 0, pdwAddr);
end;

//

function SysIPAddress32_IsBlankW(hWnd: HWND): Boolean;
var
  i   : Integer;
  edit: Array [1..4] of THandle;
  len : Integer;
begin
  Result := FALSE;
  edit[4] := GetWindow(hWnd, GW_CHILD);
  edit[3] := GetWindow(edit[4], GW_HWNDNEXT);
  edit[2] := GetWindow(edit[3], GW_HWNDNEXT);
  edit[1] := GetWindow(edit[2], GW_HWNDNEXT);
  for i := 1 to 4 do
  begin
    len := SendMessageW(edit[i], WM_GETTEXTLENGTH, 0, 0);
    if (len = 0) then
    begin
      Result := TRUE;
      Break;
    end;
  end;
end;

end.