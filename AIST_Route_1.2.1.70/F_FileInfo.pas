unit F_FileInfo;

{******************************************************************************}
{                                                                              }
{ ������             : Binary File Info                                        }
{ ��������� ���������: 01.07.2010                                              }
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
  Windows, F_SysUtils, F_Windows;

type
  PStringFileInfoW = ^TStringFileInfoW;
  TStringFileInfoW = packed record
    pszCompanyName     : WideString;
    pszFileDescription : WideString;
    pszFileVersion     : WideString;
    pszInternalName    : WideString;
    pszLegalCopyright  : WideString;
    pszLegalTrademarks : WideString;
    pszOriginalFilename: WideString;
    pszProductName     : WideString;
    pszProductVersion  : WideString;
    pszComments        : WideString;
    pszPrivateBuild    : WideString;
    pszSpecialBuild    : WideString;
    pszLanguageName    : WideString;
    pszLanguageID      : WideString;
  end;

procedure GetFileInfoW(pszPath: WideString; var sfi: TStringFileInfoW);

implementation

procedure GetFileInfoW(pszPath: WideString; var sfi: TStringFileInfoW);

const

  fmtVarFile : LPWSTR = '\VarFileInfo\Translation';
  fmtValTran : LPWSTR = '%.4x%.4x';
  fmtStrValue: Array [1..14] of LPWSTR = (
    'CompanyName',
    'FileDescription',
    'FileVersion',
    'InternalName',
    'LegalCopyright',
    'LegalTrademarks',
    'OriginalFileName',
    'ProductName',
    'ProductVersion',
    'Comments',
    'PrivateBuild',
    'SpecialBuild',
    'LanguageName',
    'LanguageID'
  );

type

  TChrSet = Array [0..1] of Word;
  PChrset = ^TChrSet;

var

  pcValue : PChrSet;
  iAppSize: DWORD;
  pcBuf   : Pointer;
  puLen   : DWORD;
  pszLng  : WideString;

  function GetFileInfoProcW(pszValue: LPWSTR): LPWSTR;
  const
    fmtFileInfo: LPWSTR = '\StringFileInfo\%s\%s';
  var
    pszBlock: WideString;
    pInfo   : Pointer;
  begin
    pszBlock := FormatW(fmtFileInfo, [pszLng, pszValue]);
    if VerQueryValueW(pcBuf, LPWSTR(pszBlock), pInfo, puLen) then
      Result := LPWSTR(pInfo)
    else
      Result := '';
  end;

begin

  iAppSize := GetFileVersionInfoSizeW(LPWSTR(pszPath), iAppSize);
  if (iAppSize > 0) then
  try

    pcBuf := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, iAppSize);
    GetFileVersionInfoW(LPWSTR(pszPath), 0, iAppSize, pcBuf);
    VerQueryValueW(pcBuf, fmtVarFile, Pointer(pcValue), puLen);
    if (puLen > 0) then
    try

      pszLng := FormatW(fmtValTran, [pcValue[0], pcValue[1]]);

      with sfi do
      begin

        pszCompanyName      := GetFileInfoProcW(fmtStrValue[1]);
        pszFileDescription  := GetFileInfoProcW(fmtStrValue[2]);
        pszFileVersion      := GetFileInfoProcW(fmtStrValue[3]);
        pszInternalName     := GetFileInfoProcW(fmtStrValue[4]);
        pszLegalCopyright   := GetFileInfoProcW(fmtStrValue[5]);
        pszLegalTrademarks  := GetFileInfoProcW(fmtStrValue[6]);
        pszOriginalFilename := GetFileInfoProcW(fmtStrValue[7]);
        pszProductName      := GetFileInfoProcW(fmtStrValue[8]);
        pszProductVersion   := GetFileInfoProcW(fmtStrValue[9]);
        pszComments         := GetFileInfoProcW(fmtStrValue[10]);
        pszPrivateBuild     := GetFileInfoProcW(fmtStrValue[11]);
        pszSpecialBuild     := GetFileInfoProcW(fmtStrValue[12]);
        pszLanguageName     := GetFileInfoProcW(fmtStrValue[13]);
        pszLanguageID       := GetFileInfoProcW(fmtStrValue[14]);

      end;

    finally

    end;

  finally

    HeapFree(GetProcessHeap, 0, pcBuf);

  end;

end;

end.