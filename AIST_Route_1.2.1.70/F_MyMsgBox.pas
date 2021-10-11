unit F_MyMsgBox;

{******************************************************************************}
{                                                                              }
{ ������             : Message Box Icon Caption                                }
{ ��������� ���������: 10.07.2010                                              }
{ ��������� �����    : � ��������� ������ ����������, 2010                     }
{ ����������� �����  : maks1509@inbox.ru                                       }
{                                                                              }
{******************************************************************************}
{                                                                              }
{ ��� ��������� �������� ��������� ����������� ������������. �� ������         }
{ �������������� �/��� �������������� � �������� �������� �����������         }
{ ������������ �������� GNU, �������������� ������ ���������� ������������     }
{ �����������, ������ 3 ���, �� ������ �������, ����� ����� ������� ������.    }
{                                                                              }
{ ��� ��������� ���������������� � �������, ��� ��� ����� ��������, �� ���     }
{ ������ ��������, � ��� ����� ��������������� �������� ��������� ���������    }
{ ��� ������� � �������� ��� ������˨����� ����������. �������� �����������    }
{ ������������ �������� GNU ��� ��������� �������������� ����������.           }
{                                                                              }
{ �� ������ ���� �������� ����� ����������� ������������ �������� GNU          }
{ ������ � ����������. � ������ � ����������, ����������                      }
{ http://www.gnu.org/copyleft/gpl.html                                         }
{                                                                              }
{******************************************************************************}

interface

uses
  Windows, Messages;

function MyMessageBoxW(hWnd: HWND; pszText, pszCaption: LPWSTR; dwFlags: DWORD): Integer;

implementation

var
  hook: HHOOK = 0;

//

function THookProcW(nCode: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  himi: HICON;
  hWnd: THandle;
begin

  case nCode of

    //

    HCBT_ACTIVATE:
    begin

      hWnd := GetParent(THandle(wParam));

      himi := GetClassLongW(hWnd, GCL_HICON);
      if (himi = 0) then
        himi := SendMessageW(hWnd, WM_GETICON, ICON_SMALL, 0);
      if (himi <> 0) then
        SendMessageW(wParam, WM_SETICON, ICON_SMALL, himi);

      Result := 0;

      if (hook <> 0) then
      begin
        UnhookWindowsHookEx(hook);
        hook := 0;
      end;

    end;
    
  else
    Result := CallNextHookEx(hook, nCode, wParam, lParam);
  end;

end;

//

function MyMessageBoxW(hWnd: HWND; pszText, pszCaption: LPWSTR; dwFlags: DWORD): Integer;
var
  dwRet: Integer;
begin

  if (hook = 0) then
    hook := SetWindowsHookExW(WH_CBT, @THookProcW, HInstance, 0);

  dwRet := MessageBoxW(hWnd, pszText, pszCaption, dwFlags);

  if (hook <> 0) then
  begin
    UnhookWindowsHookEx(hook);
    hook := 0;
  end;

  Result := dwRet;

end;

end.