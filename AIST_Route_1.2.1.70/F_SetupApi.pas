unit F_SetupApi;

interface

function IsUserAdmin: LongBool; stdcall;

implementation

const
  setupapi = 'setupapi.dll';

function IsUserAdmin; external setupapi name 'IsUserAdmin';

end.