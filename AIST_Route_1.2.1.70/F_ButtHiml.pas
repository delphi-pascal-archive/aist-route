unit F_ButtHiml;

interface

uses
  Windows, CommCtrl;

const
  BCM_FIRST = $1600;

const
  BUTTON_IMAGELIST_ALIGN_LEFT   = 0; // Align the image with the left margin.
  BUTTON_IMAGELIST_ALIGN_RIGHT  = 1; // Align the image with the right margin.
  BUTTON_IMAGELIST_ALIGN_TOP    = 2; // Align the image with the top margin.
  BUTTON_IMAGELIST_ALIGN_BOTTOM = 3; // Align the image with the bottom margin.
  BUTTON_IMAGELIST_ALIGN_CENTER = 4; // Center the image.

type
  PBUTTON_IMAGELIST = ^BUTTON_IMAGELIST;
  BUTTON_IMAGELIST = packed record
    himl  : HIMAGELIST; // Images: Normal, Hot, Pushed, Disabled. If count is less than 4, we use index 1.
    margin: TRect;      // Margin around icon.
    uAlign: UINT;
  end;

const
  BCM_GETIDEALSIZE  = BCM_FIRST + $0001;
  BCM_SETIMAGELIST  = BCM_FIRST + $0002;
  BCM_GETIMAGELIST  = BCM_FIRST + $0003;
  BCM_SETTEXTMARGIN = BCM_FIRST + $0004;
  BCM_GETTEXTMARGIN = BCM_FIRST + $0005;

implementation

end.