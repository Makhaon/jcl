
const
   UTMPX_FILE = _PATH_UTMPX;
   UTMPX_FILENAME = _PATH_UTMPX;
   WTMPX_FILE = _PATH_WTMPX;
   WTMPX_FILENAME = _PATH_WTMPX;

procedure setutxent;cdecl;external clib name 'setutxent';
procedure endutxent;cdecl;external clib name 'endutxent';
function getutxent:Putmpx;cdecl;external clib name 'getutxent';
function getutxid(__id:Putmpx):Putmpx;cdecl;external clib name 'getutxid'; overload;
function getutxline(__line:Putmpx):Putmpx;cdecl;external clib name 'getutxline'; overload;
function pututxline(__utmpx:Putmpx):Putmpx;cdecl;external clib name 'pututxline'; overload;
function utmpxname(__file:Pchar):longint;cdecl;external clib name 'utmpxname';
procedure updwtmpx(__wtmpx_file:Pchar; __utmpx:Putmpx);cdecl;external clib name 'updwtmpx'; overload;
procedure getutmp(__utmpx:Putmpx; __utmp:Putmp);cdecl;external clib name 'getutmp'; overload;
procedure getutmpx(__utmp:Putmp; __utmpx:Putmpx);cdecl;external clib name 'getutmpx'; overload;

{ ---------------------------------------------------------------------
    Borland compatibility types
  ---------------------------------------------------------------------}

// Type
function getutxid(const __id:utmpx):Putmpx;cdecl;external clib name 'getutxid'; overload;
function getutxline(const __line:utmpx):Putmpx;cdecl;external clib name 'getutxline'; overload;
function pututxline(const __utmpx:utmpx):Putmpx;cdecl;external clib name 'pututxline'; overload;
procedure updwtmpx(__wtmpx_file:Pchar;const __utmpx:utmpx);cdecl;external clib name 'updwtmpx'; overload;
procedure getutmp(const __utmpx:utmpx; var __utmp:utmp);cdecl;external clib name 'getutmp'; overload;
procedure getutmpx(var __utmp:utmp; var __utmpx:utmpx);cdecl;external clib name 'getutmpx'; overload;
