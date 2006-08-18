{******************************************************************************}
{                                                                              }
{ Project JEDI Code Library (JCL)                                              }
{                                                                              }
{ The contents of this file are subject to the Mozilla Public License Version  }
{ 1.1 (the "License"); you may not use this file except in compliance with the }
{ License. You may obtain a copy of the License at http://www.mozilla.org/MPL/ }
{                                                                              }
{ Software distributed under the License is distributed on an "AS IS" basis,   }
{ WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for }
{ the specific language governing rights and limitations under the License.    }
{                                                                              }
{ The Original Code is JclMapi.pas.                                            }
{                                                                              }
{ The Initial Developer of the Original Code is documented in the accompanying }
{ help file JCL.chm. Portions created by these individuals are Copyright (C)   }
{ of these individuals.                                                        }
{                                                                              }
{******************************************************************************}
{                                                                              }
{ Various classes and support routines for sending e-mail through Simple MAPI  }
{                                                                              }
{ Unit owner: Petr Vones                                                       }
{ Last modified: June 5, 2001                                                  }
{                                                                              }
{******************************************************************************}

unit JclMapi;

{$I JCL.INC}

interface

uses
  Windows, Classes, Mapi, SysUtils,
  {$IFDEF DELPHI5_UP}
  Contnrs,
  {$ENDIF DELPHI5_UP}
  JclBase;

type
  EJclMapiError = class (EJclError)
  private
    FErrorCode: DWORD;
  public
    property ErrorCode: DWORD read FErrorCode;
  end;

//------------------------------------------------------------------------------
// Simple MAPI interface
//------------------------------------------------------------------------------

  TJclMapiClient = record
    ClientName: string;
    ClientPath: string;
    RegKeyName: string;
    Valid: Boolean;
  end;

  TJclMapiClientConnect = (ctAutomatic, ctMapi, ctDirect);

  TJclSimpleMapi = class (TObject)
  private
    FAnyClientInstalled: Boolean;
    FBeforeUnloadClient: TNotifyEvent;
    FClients: array of TJclMapiClient;
    FClientConnectKind: TJclMapiClientConnect;
    FClientLibHandle: THandle;
    FDefaultClientIndex: Integer;
    FFunctions: array of ^Pointer;
    FMapiInstalled: Boolean;
    FMapiVersion: string;
    FSelectedClientIndex: Integer;
    FSimpleMapiInstalled: Boolean;
    FMapiAddress: TFNMapiAddress;
    FMapiDeleteMail: TFNMapiDeleteMail;
    FMapiDetails: TFNMapiDetails;
    FMapiFindNext: TFNMapiFindNext;
    FMapiFreeBuffer: TFNMapiFreeBuffer;
    FMapiLogOff: TFNMapiLogOff;
    FMapiLogOn: TFNMapiLogOn;
    FMapiReadMail: TFNMapiReadMail;
    FMapiResolveName: TFNMapiResolveName;
    FMapiSaveMail: TFNMapiSaveMail;
    FMapiSendDocuments: TFNMapiSendDocuments;
    FMapiSendMail: TFNMapiSendMail;
    function GetClientCount: Integer;
    function GetClients(Index: Integer): TJclMapiClient;
    function GetCurrentClientName: string;
    procedure SetSelectedClientIndex(const Value: Integer);
    procedure SetClientConnectKind(const Value: TJclMapiClientConnect);
    function UseMapi: Boolean;
  protected
    procedure BeforeUnloadClientLib; dynamic;
    procedure CheckListIndex(I: Integer);
    function GetClientLibName: string;
    procedure ReadMapiSettings;
  public
    constructor Create;
    destructor Destroy; override;
    function ClientLibLoaded: Boolean;
    procedure LoadClientLib;
    procedure UnloadClientLib;
    property AnyClientInstalled: Boolean read FAnyClientInstalled;
    property ClientConnectKind: TJclMapiClientConnect read FClientConnectKind write SetClientConnectKind;
    property ClientCount: Integer read GetClientCount;
    property Clients[Index: Integer]: TJclMapiClient read GetClients; default;
    property CurrentClientName: string read GetCurrentClientName;
    property DefaultClientIndex: Integer read FDefaultClientIndex;
    property MapiInstalled: Boolean read FMapiInstalled;
    property MapiVersion: string read FMapiVersion;
    property SelectedClientIndex: Integer read FSelectedClientIndex write SetSelectedClientIndex;
    property SimpleMapiInstalled: Boolean read FSimpleMapiInstalled;
    property BeforeUnloadClient: TNotifyEvent read FBeforeUnloadClient write FBeforeUnloadClient;
    // Simple MAPI functions
    property MapiAddress: TFNMapiAddress read FMapiAddress;
    property MapiDeleteMail: TFNMapiDeleteMail read FMapiDeleteMail;
    property MapiDetails: TFNMapiDetails read FMapiDetails;
    property MapiFindNext: TFNMapiFindNext read FMapiFindNext;
    property MapiFreeBuffer: TFNMapiFreeBuffer read FMapiFreeBuffer;
    property MapiLogOff: TFNMapiLogOff read FMapiLogOff;
    property MapiLogOn: TFNMapiLogOn read FMapiLogOn;
    property MapiReadMail: TFNMapiReadMail read FMapiReadMail;
    property MapiResolveName: TFNMapiResolveName read FMapiResolveName;
    property MapiSaveMail: TFNMapiSaveMail read FMapiSaveMail;
    property MapiSendDocuments: TFNMapiSendDocuments read FMapiSendDocuments;
    property MapiSendMail: TFNMapiSendMail read FMapiSendMail;
  end;

//------------------------------------------------------------------------------
// Simple email classes
//------------------------------------------------------------------------------

  TJclEmailRecipKind = (rkOriginator, rkTO, rkCC, rkBCC);

  TJclEmailRecip = class (TObject)
  private
    FAddress: string;
    FAddressType: string;
    FKind: TJclEmailRecipKind;
    FName: string;
  protected
    function SortingName: string;
  public
    function AddressAndName: string;
    property AddressType: string read FAddressType write FAddressType;
    property Address: string read FAddress write FAddress;
    property Kind: TJclEmailRecipKind read FKind write FKind;
    property Name: string read FName write FName;
  end;

  TJclEmailRecips = class (TObjectList)
  private
    FAddressesType: string;
    function GetItems(Index: Integer): TJclEmailRecip;
    function GetOriginator: TJclEmailRecip;
  public
    function Add(const Address: string;
      const Name: string {$IFDEF SUPPORTS_DEFAULTPARAMS} = '' {$ENDIF};
      const Kind: TJclEmailRecipKind {$IFDEF SUPPORTS_DEFAULTPARAMS} = rkTO {$ENDIF};
      const AddressType: string {$IFDEF SUPPORTS_DEFAULTPARAMS} = '' {$ENDIF}): Integer;
    procedure SortRecips;
    property AddressesType: string read FAddressesType write FAddressesType;
    property Items[Index: Integer]: TJclEmailRecip read GetItems; default;
    property Originator: TJclEmailRecip read GetOriginator;
  end;

  TJclEmailFindOptions = set of (foFifo, foUnreadOnly);
  TJclEmailLogonOptions = set of (loLogonUI, loNewSession, loForceDownload);
  TJclEmailReadOptions = set of (roAttachments, roHeaderOnly, roMarkAsRead);

  TJclEmailReadMsg = record
    ConversationID: string;
    DateReceived: TDateTime;
    MessageType: string;
    Flags: FLAGS;
  end;

  TJclEmail = class (TJclSimpleMapi)
  private
    FAttachments: TStrings;
    FBody: string;
    FFindOptions: TJclEmailFindOptions;
    FLogonOptions: TJclEmailLogonOptions;
    FParentWnd: HWND;
    FReadMsg: TJclEmailReadMsg;
    FRecipients: TJclEmailRecips;
    FSeedMessageID: string;
    FSessionHandle: THandle;
    FSubject: string;
    function GetUserLogged: Boolean;
    procedure SetBody(const Value: string);
    function GetParentWnd: HWND;
  protected
    procedure BeforeUnloadClientLib; override;
    procedure DecodeRecips(RecipDesc: PMapiRecipDesc; Count: Integer);
    function InternalSendOrSave(Save: Boolean; ShowDialog: Boolean): Boolean;
    function LogonOptionsToFlags(ShowDialog: Boolean): DWORD;
  public
    constructor Create;
    destructor Destroy; override;
    function Address(const Caption: string {$IFDEF SUPPORTS_DEFAULTPARAMS} = '' {$ENDIF};
      EditFields: Integer {$IFDEF SUPPORTS_DEFAULTPARAMS} = 3 {$ENDIF}): Boolean;
    procedure Clear;
    function Delete(const MessageID: string): Boolean;
    function FindFirstMessage: Boolean;
    function FindNextMessage: Boolean;
    procedure LogOff;
    procedure LogOn(const ProfileName: string {$IFDEF SUPPORTS_DEFAULTPARAMS} = '' {$ENDIF};
      const Password: string {$IFDEF SUPPORTS_DEFAULTPARAMS} = '' {$ENDIF});
    function MessageReport(Strings: TStrings;
      MaxWidth: Integer {$IFDEF SUPPORTS_DEFAULTPARAMS} = 80 {$ENDIF};
      IncludeAddresses: Boolean {$IFDEF SUPPORTS_DEFAULTPARAMS} = False {$ENDIF}): Integer;
    function Read(const Options: TJclEmailReadOptions {$IFDEF SUPPORTS_DEFAULTPARAMS} = [] {$ENDIF}): Boolean;
    function ResolveName(var Name, Address: string;
      ShowDialog: Boolean {$IFDEF SUPPORTS_DEFAULTPARAMS} = False {$ENDIF}): Boolean;
    function Save: Boolean;
    function Send(ShowDialog: Boolean {$IFDEF SUPPORTS_DEFAULTPARAMS} = True {$ENDIF}): Boolean;
    procedure SortAttachments;
    property Attachments: TStrings read FAttachments;
    property Body: string read FBody write SetBody;
    property FindOptions: TJclEmailFindOptions read FFindOptions write FFindOptions;
    property LogonOptions: TJclEmailLogonOptions read FLogonOptions write FLogonOptions;
    property ParentWnd: HWND read GetParentWnd write FParentWnd;
    property ReadMsg: TJclEmailReadMsg read FReadMsg;
    property Recipients: TJclEmailRecips read FRecipients;
    property SeedMessageID: string read FSeedMessageID write FSeedMessageID;
    property SessionHandle: THandle read FSessionHandle;
    property Subject: string read FSubject write FSubject;
    property UserLogged: Boolean read GetUserLogged;
  end;

//------------------------------------------------------------------------------
// Simple email send function
//------------------------------------------------------------------------------

function JclSimpleSendMail(const ARecipient, AName, ASubject, ABody: string;
  const AAttachment: TFileName {$IFDEF SUPPORTS_DEFAULTPARAMS} = '' {$ENDIF};
  ShowDialog: Boolean {$IFDEF SUPPORTS_DEFAULTPARAMS} = True {$ENDIF};
  AParentWND: HWND {$IFDEF SUPPORTS_DEFAULTPARAMS} = 0 {$ENDIF}): Boolean;

function JclSimpleBringUpSendMailDialog(const ASubject, ABody: string;
  const AAttachment: TFileName {$IFDEF SUPPORTS_DEFAULTPARAMS} = '' {$ENDIF};
  AParentWND: HWND {$IFDEF SUPPORTS_DEFAULTPARAMS} = 0 {$ENDIF}): Boolean;

//------------------------------------------------------------------------------
// MAPI Errors
//------------------------------------------------------------------------------

function MapiCheck(const Res: DWORD; IgnoreUserAbort: Boolean {$IFDEF SUPPORTS_DEFAULTPARAMS} = True {$ENDIF}): DWORD;

function MapiErrorMessage(const ErrorCode: DWORD): string;

implementation

uses
  Registry,
  JclLogic, JclResources, JclStrings, JclSysInfo, JclSysUtils;

const
  mapidll = 'mapi32.dll';
  MapiExportNames: array [0..11] of PChar =
    ('MAPIAddress',
     'MAPIDeleteMail',
     'MAPIDetails',
     'MAPIFindNext',
     'MAPIFreeBuffer',
     'MAPILogoff',
     'MAPILogon',
     'MAPIReadMail',
     'MAPIResolveName',
     'MAPISaveMail',
     'MAPISendDocuments',
     'MAPISendMail'
     );

//------------------------------------------------------------------------------
// MAPI Errors check
//------------------------------------------------------------------------------

function MapiCheck(const Res: DWORD; IgnoreUserAbort: Boolean): DWORD;
var
  Error: EJclMapiError;
begin
  if (Res = SUCCESS_SUCCESS) or (IgnoreUserAbort and (Res = MAPI_E_USER_ABORT)) then
    Result := Res
  else
  begin
    Error := EJclMapiError.CreateResRecFmt(@RsMapiError, [Res, MapiErrorMessage(Res)]);
    Error.FErrorCode := Res;
    raise Error;
  end;
end;

//------------------------------------------------------------------------------

function MapiErrorMessage(const ErrorCode: DWORD): string;
begin
  case ErrorCode of
    MAPI_E_USER_ABORT:
      Result := RsMapiErrUSER_ABORT;
    MAPI_E_FAILURE:
      Result := RsMapiErrFAILURE;
    MAPI_E_LOGIN_FAILURE:
      Result := RsMapiErrLOGIN_FAILURE;
    MAPI_E_DISK_FULL:
      Result := RsMapiErrDISK_FULL;
    MAPI_E_INSUFFICIENT_MEMORY:
      Result := RsMapiErrINSUFFICIENT_MEMORY;
    MAPI_E_ACCESS_DENIED:
      Result := RsMapiErrACCESS_DENIED;
    MAPI_E_TOO_MANY_SESSIONS:
      Result := RsMapiErrTOO_MANY_SESSIONS;
    MAPI_E_TOO_MANY_FILES:
      Result := RsMapiErrTOO_MANY_FILES;
    MAPI_E_TOO_MANY_RECIPIENTS:
      Result := RsMapiErrTOO_MANY_RECIPIENTS;
    MAPI_E_ATTACHMENT_NOT_FOUND:
      Result := RsMapiErrATTACHMENT_NOT_FOUND;
    MAPI_E_ATTACHMENT_OPEN_FAILURE:
      Result := RsMapiErrATTACHMENT_OPEN_FAILURE;
    MAPI_E_ATTACHMENT_WRITE_FAILURE:
      Result := RsMapiErrATTACHMENT_WRITE_FAILURE;
    MAPI_E_UNKNOWN_RECIPIENT:
      Result := RsMapiErrUNKNOWN_RECIPIENT;
    MAPI_E_BAD_RECIPTYPE:
      Result := RsMapiErrBAD_RECIPTYPE;
    MAPI_E_NO_MESSAGES:
      Result := RsMapiErrNO_MESSAGES;
    MAPI_E_INVALID_MESSAGE:
      Result := RsMapiErrINVALID_MESSAGE;
    MAPI_E_TEXT_TOO_LARGE:
      Result := RsMapiErrTEXT_TOO_LARGE;
    MAPI_E_INVALID_SESSION:
      Result := RsMapiErrINVALID_SESSION;
    MAPI_E_TYPE_NOT_SUPPORTED:
      Result := RsMapiErrTYPE_NOT_SUPPORTED;
    MAPI_E_AMBIGUOUS_RECIPIENT:
      Result := RsMapiErrAMBIGUOUS_RECIPIENT;
    MAPI_E_MESSAGE_IN_USE:
      Result := RsMapiErrMESSAGE_IN_USE;
    MAPI_E_NETWORK_FAILURE:
      Result := RsMapiErrNETWORK_FAILURE;
    MAPI_E_INVALID_EDITFIELDS:
      Result := RsMapiErrINVALID_EDITFIELDS;
    MAPI_E_INVALID_RECIPS:
      Result := RsMapiErrINVALID_RECIPS;
    MAPI_E_NOT_SUPPORTED:
      Result := RsMapiErrNOT_SUPPORTED;
  else
    Result := '';
  end;
end;

//==============================================================================
// TJclSimpleMapi
//==============================================================================

procedure TJclSimpleMapi.BeforeUnloadClientLib;
begin
  if Assigned(FBeforeUnloadClient) then
    FBeforeUnloadClient(Self);
end;

//------------------------------------------------------------------------------

procedure TJclSimpleMapi.CheckListIndex(I: Integer);
begin
  if (I < 0) or (I >= ClientCount) then
    raise EJclMapiError.CreateResRecFmt(@RsMapiInvalidIndex, [I]);
end;

//------------------------------------------------------------------------------

function TJclSimpleMapi.ClientLibLoaded: Boolean;
begin
  Result := FClientLibHandle <> 0;
end;

//------------------------------------------------------------------------------

constructor TJclSimpleMapi.Create;
begin
  SetLength(FFunctions, Length(MapiExportNames));
  FFunctions[0] := @@FMapiAddress;
  FFunctions[1] := @@FMapiDeleteMail;
  FFunctions[2] := @@FMapiDetails;
  FFunctions[3] := @@FMapiFindNext;
  FFunctions[4] := @@FMapiFreeBuffer;
  FFunctions[5] := @@FMapiLogOff;
  FFunctions[6] := @@FMapiLogOn;
  FFunctions[7] := @@FMapiReadMail;
  FFunctions[8] := @@FMapiResolveName;
  FFunctions[9] := @@FMapiSaveMail;
  FFunctions[10] := @@FMapiSendDocuments;
  FFunctions[11] := @@FMapiSendMail;
  FDefaultClientIndex := -1;
  FClientConnectKind := ctAutomatic;
  FSelectedClientIndex := -1;
  ReadMapiSettings;
end;

//------------------------------------------------------------------------------

destructor TJclSimpleMapi.Destroy;
begin
  UnloadClientLib;
  inherited;
end;

//------------------------------------------------------------------------------

function TJclSimpleMapi.GetClientCount: Integer;
begin
  Result := Length(FClients);
end;

//------------------------------------------------------------------------------

function TJclSimpleMapi.GetClientLibName: string;
begin
  if UseMapi then
    Result := mapidll
  else
    Result := FClients[FSelectedClientIndex].ClientPath;
end;

//------------------------------------------------------------------------------

function TJclSimpleMapi.GetClients(Index: Integer): TJclMapiClient;
begin
  CheckListIndex(Index);
  Result := FClients[Index];
end;

//------------------------------------------------------------------------------

function TJclSimpleMapi.GetCurrentClientName: string;
begin
  if UseMapi then
    Result := 'MAPI'
  else
  if ClientCount > 0 then
    Result := Clients[SelectedClientIndex].ClientName
  else
    Result := '';
end;

//------------------------------------------------------------------------------

procedure TJclSimpleMapi.LoadClientLib;
var
  I: Integer;
  P: Pointer;
begin
  if ClientLibLoaded then
    Exit;
  FClientLibHandle := LoadLibrary(PChar(GetClientLibName));
  if FClientLibHandle = 0 then
    RaiseLastOSError;
  for I := 0 to Length(FFunctions) - 1 do
  begin
    P := GetProcAddress(FClientLibHandle, PChar(MapiExportNames[I]));
    if P = nil then
    begin
      UnloadClientLib;
      raise EJclMapiError.CreateResRecFmt(@RsMapiMissingExport, [MapiExportNames[I]]);
    end
    else
      FFunctions[I]^ := P;
  end;
end;

//------------------------------------------------------------------------------

procedure TJclSimpleMapi.ReadMapiSettings;
const
  MessageSubsytemKey = 'SOFTWARE\Microsoft\Windows Messaging Subsystem';
  MailClientsKey = 'SOFTWARE\Clients\Mail';
var
  DefaultClient: string;
  SL: TStringList;
  I: Integer;

  function CheckValid(var Client: TJclMapiClient): Boolean;
  var
    I: Integer;
    LibHandle: THandle;
  begin
    LibHandle := LoadLibraryEx(PChar(Client.ClientPath), 0, DONT_RESOLVE_DLL_REFERENCES);
    Result := (LibHandle <> 0);
    if Result then
    begin
      for I := Low(MapiExportNames) to High(MapiExportNames) do
        if GetProcAddress(LibHandle, PChar(MapiExportNames[I])) = nil then
        begin
          Result := False;
          Break;
        end;
      FreeLibrary(LibHandle);
    end;
    Client.Valid := Result;
  end;

begin
  FClients := nil;
  FDefaultClientIndex := -1;
  SL := TStringList.Create;
  with TRegistry.Create do
  try
    RootKey := HKEY_LOCAL_MACHINE;
    if OpenKeyReadOnly(MessageSubsytemKey) then
    begin
      FMapiInstalled := ReadString('MAPIX') = '1';
      FSimpleMapiInstalled := ReadString('MAPI') = '1';
      FMapiVersion := ReadString('MAPIXVER');
      CloseKey;
    end;
    FAnyClientInstalled := FMapiInstalled;
    if OpenKeyReadOnly(MailClientsKey) then
    begin
      DefaultClient := ReadString('');
      GetKeyNames(SL);
      CloseKey;
      SetLength(FClients, SL.Count);
      for I := 0 to SL.Count - 1 do
      begin
        FClients[I].RegKeyName := SL[I];
        FClients[I].Valid := False;
        if OpenKeyReadOnly(MailClientsKey + '\' + SL[I]) then
        begin
          FClients[I].ClientName := ReadString('');
          FClients[I].ClientPath := ReadString('DLLPath');
          ExpandEnvironmentVar(FClients[I].ClientPath);
          if CheckValid(FClients[I]) then
            FAnyClientInstalled := True;
          CloseKey;
        end;
      end;
      FDefaultClientIndex := SL.IndexOf(DefaultClient);
      FSelectedClientIndex := FDefaultClientIndex;
    end;
  finally
    Free;
    SL.Free;
  end;
end;

//------------------------------------------------------------------------------

procedure TJclSimpleMapi.SetClientConnectKind(const Value: TJclMapiClientConnect);
begin
  if FClientConnectKind <> Value then
  begin
    FClientConnectKind := Value;
    UnloadClientLib;
  end;
end;

//------------------------------------------------------------------------------

procedure TJclSimpleMapi.SetSelectedClientIndex(const Value: Integer);
begin
  CheckListIndex(Value);
  if FSelectedClientIndex <> Value then
  begin
    FSelectedClientIndex := Value;
    UnloadClientLib;
  end;
end;

//------------------------------------------------------------------------------

procedure TJclSimpleMapi.UnloadClientLib;
var
  I: Integer;
begin
  if ClientLibLoaded then
  begin
    BeforeUnloadClientLib;
    FreeLibrary(FClientLibHandle);
    FClientLibHandle := 0;
    for I := 0 to Length(FFunctions) - 1 do
      FFunctions[I]^ := nil;
  end;
end;

//------------------------------------------------------------------------------

function TJclSimpleMapi.UseMapi: Boolean;
begin
  case FClientConnectKind of
    ctAutomatic:
      UseMapi := FSimpleMapiInstalled;
    ctMapi:
      UseMapi := True;
    ctDirect:
      UseMapi := False;
  else
    UseMapi := True;
  end;
end;

//==============================================================================
// TJclEmailRecip
//==============================================================================

function TJclEmailRecip.AddressAndName: string;
var
  N: string;
begin
  if Name = '' then
    N := Address
  else
    N := Name;
  Result := Format('"%s" <%s>', [N, Address]);
end;

//------------------------------------------------------------------------------

function TJclEmailRecip.SortingName: string;
begin
  if FName = '' then
    Result := FAddress
  else
    Result := FName;
end;

//==============================================================================
// TJclEmailRecips
//==============================================================================

function TJclEmailRecips.Add(const Address, Name: string;
  const Kind: TJclEmailRecipKind; const AddressType: string): Integer;
var
  Item: TJclEmailRecip;
begin
  Item := TJclEmailRecip.Create;
  try
    Item.Address := Trim(Address);
    Item.AddressType := AddressType;
    Item.Name := Name;
    Item.Kind := Kind;
    Result := inherited Add(Item);
  except
    Item.Free;
    raise;
  end;
end;

//------------------------------------------------------------------------------

function TJclEmailRecips.GetItems(Index: Integer): TJclEmailRecip;
begin
  Result := TJclEmailRecip(inherited Items[Index]);
end;

//------------------------------------------------------------------------------

function TJclEmailRecips.GetOriginator: TJclEmailRecip;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if Items[I].Kind = rkOriginator then
    begin
      Result := Items[I];
      Break;
    end;
end;

//------------------------------------------------------------------------------

function EmailRecipsCompare(Item1, Item2: Pointer): Integer;
var
  R1, R2: TJclEmailRecip;
begin
  R1 := TJclEmailRecip(Item1);
  R2 := TJclEmailRecip(Item2);
  Result := Integer(R1.Kind) - Integer(R2.Kind);
  if Result = 0 then
    Result := AnsiCompareStr(R1.SortingName, R2.SortingName);
end;

procedure TJclEmailRecips.SortRecips;
begin
  Sort(EmailRecipsCompare);
end;

//==============================================================================
// TJclEmail
//==============================================================================

function TJclEmail.Address(const Caption: string; EditFields: Integer): Boolean;
var
  NewRecipCount: ULONG;
  NewRecips: PMapiRecipDesc;
  Recips: TMapiRecipDesc;
  Res: DWORD;
begin
  LoadClientLib;
  NewRecips := nil;
  NewRecipCount := 0;
  Res := MapiAddress(FSessionHandle, ParentWnd, PChar(Caption), EditFields, nil,
    0, Recips, LogonOptionsToFlags(False), 0, @NewRecipCount, NewRecips);
  Result := (MapiCheck(Res, True) = SUCCESS_SUCCESS);
  if Result then
  begin
    DecodeRecips(NewRecips, NewRecipCount);
    MapiFreeBuffer(NewRecips);
  end;
end;

//------------------------------------------------------------------------------

procedure TJclEmail.BeforeUnloadClientLib;
begin
  LogOff;
  inherited;
end;

//------------------------------------------------------------------------------

procedure TJclEmail.Clear;
begin
  FAttachments.Clear;
  FBody := '';
  FSubject := '';
  FRecipients.Clear;
  FReadMsg.MessageType := '';
  FReadMsg.DateReceived := 0;
  FReadMsg.ConversationID := '';
  FReadMsg.Flags := 0;
end;

//------------------------------------------------------------------------------

constructor TJclEmail.Create;
begin
  inherited;
  FAttachments := TStringList.Create;
  FLogonOptions := [loLogonUI];
  FFindOptions := [foFifo];
  FRecipients := TJclEmailRecips.Create(True);
  FRecipients.AddressesType := 'SMTP';
end;

//------------------------------------------------------------------------------

procedure TJclEmail.DecodeRecips(RecipDesc: PMapiRecipDesc; Count: Integer);
var
  S: string;
  N, I: Integer;
  Kind: TJclEmailRecipKind;
begin
  for I := 0 to Count - 1 do
  begin
    if RecipDesc = nil then
      Break;
    Kind := rkOriginator;
    with RecipDesc^ do
    begin
      S := lpszAddress;
      N := Pos(':', S);
      if N = 0 then
        N := Length(S) + 1;
      if ulRecipClass in [MAPI_ORIG..MAPI_BCC] then
        Kind := TJclEmailRecipKind(ulRecipClass)
      else
        MapiCheck(MAPI_E_INVALID_MESSAGE, True);
      Recipients.Add(Copy(S, 1, N - 1), lpszName, Kind, Copy(S, N + 1, Length(S)));
    end;
    Inc(RecipDesc);
  end;  
end;

//------------------------------------------------------------------------------

function TJclEmail.Delete(const MessageID: string): Boolean;
begin
  LoadClientLib;
  Result := MapiCheck(MapiDeleteMail(FSessionHandle, 0, PChar(MessageID), 0, 0),
    False) = SUCCESS_SUCCESS;
end;

//------------------------------------------------------------------------------

destructor TJclEmail.Destroy;
begin
  FreeAndNil(FAttachments);
  FreeAndNil(FRecipients);
  inherited;
end;

//------------------------------------------------------------------------------

function TJclEmail.FindFirstMessage: Boolean;
begin
  FSeedMessageID := '';
  Result := FindNextMessage;
end;

//------------------------------------------------------------------------------

function TJclEmail.FindNextMessage: Boolean;
var
  MsgID: array [0..512] of AnsiChar;
  Flags, Res: ULONG;
begin
  Result := False;
  if not UserLogged then
    Exit;
  Flags := MAPI_LONG_MSGID;
  if foFifo in FFindOptions then
    Inc(Flags, MAPI_GUARANTEE_FIFO);
  if foUnreadOnly in FFindOptions then
    Inc(Flags, MAPI_UNREAD_ONLY);
  Res := MapiFindNext(FSessionHandle, 0, nil, PChar(FSeedMessageID), Flags, 0, MsgId);
  Result := (Res = SUCCESS_SUCCESS);
  if Result then
    FSeedMessageID := MsgID
  else
  begin
    FSeedMessageID := '';
    if Res <> MAPI_E_NO_MESSAGES then
      MapiCheck(Res, True);
  end;
end;

//------------------------------------------------------------------------------

function TJclEmail.GetParentWnd: HWND;
var
  FoundWnd: HWND;

  function EnumThreadWndProc(Wnd: HWND; Param: LPARAM): Boolean; stdcall;
  begin
    if IsWindowVisible(Wnd) and (GetWindowLong(Wnd, GWL_STYLE) and WS_POPUP <> 0) then
    begin
      PDWORD(Param)^ := Wnd;
      Result := False;
    end
    else
      Result := True;
  end;

begin
  if IsWindow(FParentWnd) then
    Result := FParentWnd
  else
  begin
    FoundWnd := 0;
    EnumThreadWindows(MainThreadID, @EnumThreadWndProc, Integer(@FoundWnd));
    Result := FoundWnd;
  end;
end;

//------------------------------------------------------------------------------

function TJclEmail.GetUserLogged: Boolean;
begin
  Result := (FSessionHandle <> 0);
end;

//------------------------------------------------------------------------------

function TJclEmail.InternalSendOrSave(Save, ShowDialog: Boolean): Boolean;
const
  RecipClasses: array [TJclEmailRecipKind] of DWORD =
    (MAPI_ORIG, MAPI_TO, MAPI_CC, MAPI_BCC);
var
  AttachArray: array of TMapiFileDesc;
  RecipArray: array of TMapiRecipDesc;
  RealAdresses: array of string;
  MapiMessage: TMapiMessage;
  Flags, Res: DWORD;
  I: Integer;
  MsgID: array [0..512] of AnsiChar;
begin
  if not AnyClientInstalled then
    raise EJclMapiError.CreateResRec(@RsMapiMailNoClient);

  if FAttachments.Count > 0 then
  begin
    SetLength(AttachArray, FAttachments.Count);
    for I := 0 to FAttachments.Count - 1 do
    begin
      if not FileExists(FAttachments[I]) then
        MapiCheck(MAPI_E_ATTACHMENT_NOT_FOUND, False);
      FAttachments[I] := ExpandFileName(FAttachments[I]);
      FillChar(AttachArray[I], SizeOf(TMapiFileDesc), #0);
      AttachArray[I].nPosition := DWORD(-1);
      AttachArray[I].lpszFileName := nil;
      AttachArray[I].lpszPathName := PChar(FAttachments[I]);
    end;
  end
  else
    AttachArray := nil;

  if Recipients.Count > 0 then
  begin
    SetLength(RecipArray, Recipients.Count);
    SetLength(RealAdresses, Recipients.Count);
    for I := 0 to Recipients.Count - 1 do
    begin
      FillChar(RecipArray[I], SizeOf(TMapiRecipDesc), #0);
      with RecipArray[I], Recipients[I] do
      begin
        ulRecipClass := RecipClasses[Kind];
        if Name = '' then // some clients requires Name item always filled
        begin
          if FAddress = '' then
            MapiCheck(MAPI_E_INVALID_RECIPS, False);
          lpszName := PChar(FAddress);
        end
        else
          lpszName := PChar(FName);
        if FAddressType <> '' then
          RealAdresses[I] := FAddressType + ':' + FAddress
        else
        if Recipients.AddressesType <> '' then
          RealAdresses[I] := Recipients.AddressesType + ':' + FAddress
        else
          RealAdresses[I] := FAddress;
        lpszAddress := PCharOrNil(RealAdresses[I]);
      end;
    end;
  end
  else
  begin
    if ShowDialog then
      RecipArray := nil
    else
      MapiCheck(MAPI_E_INVALID_RECIPS, False);
  end;

  LoadClientLib;

  FillChar(MapiMessage, SizeOf(MapiMessage), #0);
  MapiMessage.lpszSubject := PChar(FSubject);
  MapiMessage.lpszNoteText := PChar(FBody);
  MapiMessage.lpRecips := PMapiRecipDesc(RecipArray);
  MapiMessage.nRecipCount := Length(RecipArray);
  MapiMessage.lpFiles := PMapiFileDesc(AttachArray);
  MapiMessage.nFileCount := Length(AttachArray);
  Flags := LogonOptionsToFlags(ShowDialog);
  if Save then
  begin
    StrPCopy(MsgID, FSeedMessageID);
    Res := MapiSaveMail(FSessionHandle, ParentWND, MapiMessage, Flags, 0, MsgID);
    if Res = SUCCESS_SUCCESS then
      FSeedMessageID := MsgID;
  end
  else
    Res := MapiSendMail(FSessionHandle, ParentWND, MapiMessage, Flags, 0);
  Result := (MapiCheck(Res, True) = SUCCESS_SUCCESS);
end;

//------------------------------------------------------------------------------

procedure TJclEmail.LogOff;
begin
  if UserLogged then
  begin
    MapiCheck(MapiLogOff(FSessionHandle, ParentWND, 0, 0), True);
    FSessionHandle := 0;
  end;
end;

//------------------------------------------------------------------------------

procedure TJclEmail.LogOn(const ProfileName, Password: string);
begin
  if not UserLogged then
  begin
    LoadClientLib;
    MapiCheck(MapiLogOn(ParentWND, PChar(ProfileName), PChar(Password),
      LogonOptionsToFlags(False), 0, @FSessionHandle), True);
  end; 
end;

//------------------------------------------------------------------------------

function TJclEmail.LogonOptionsToFlags(ShowDialog: Boolean): DWORD;
begin
  Result := 0;
  if FSessionHandle = 0 then
  begin
    if loLogonUI in FLogonOptions then
      Inc(Result, MAPI_LOGON_UI);
    if loNewSession in FLogonOptions then
      Inc(Result, MAPI_NEW_SESSION);
    if loForceDownload in FLogonOptions then
      Inc(Result, MAPI_FORCE_DOWNLOAD);
  end;
  if ShowDialog then
    Inc(Result, MAPI_DIALOG);
end;

//------------------------------------------------------------------------------

function TJclEmail.MessageReport(Strings: TStrings; MaxWidth: Integer;
  IncludeAddresses: Boolean): Integer;
const
  NameDelimiter = ', ';
  KindNames: array [TJclEmailRecipKind] of string =
    (RsMapiMailORIG, RsMapiMailTO, RsMapiMailCC, RsMapiMailBCC);
var
  LabelsWidth: Integer;
  NamesList: array [TJclEmailRecipKind] of string;
  ReportKind: TJclEmailRecipKind;
  I, Cnt: Integer;
  BreakStr, S: string;
begin
  Cnt := Strings.Count;
  LabelsWidth := Length(RsMapiMailSubject);
  for ReportKind := Low(ReportKind) to High(ReportKind) do
  begin
    NamesList[ReportKind] := '';
    LabelsWidth := Max(LabelsWidth, Length(KindNames[ReportKind]));
  end;
  BreakStr := AnsiCrLf + StringOfChar(' ', LabelsWidth + 2);
  for I := 0 to FRecipients.Count - 1 do
    with FRecipients[I] do
    begin
      if IncludeAddresses then
        S := AddressAndName
      else
        S := Name;
      NamesList[Kind] := NamesList[Kind] + S + NameDelimiter;
    end;  
  for ReportKind := Low(ReportKind) to High(ReportKind) do
    if NamesList[ReportKind] <> '' then
    begin
      S := StrPadRight(KindNames[ReportKind], LabelsWidth, AnsiSpace) + ': ' +
        Copy(NamesList[ReportKind], 1, Length(NamesList[ReportKind]) - Length(NameDelimiter));
      Strings.Add(WrapText(S, BreakStr, [AnsiTab, AnsiSpace], MaxWidth));
    end;
  S := RsMapiMailSubject + ': ' + Subject;
  Strings.Add(WrapText(S, BreakStr, [AnsiTab, AnsiSpace], MaxWidth));
  Result := Strings.Count - Cnt;
  Strings.Add('');
  Strings.Add(WrapText(Body, AnsiCrLf, [AnsiTab, AnsiSpace, '-'], MaxWidth));
end;

//------------------------------------------------------------------------------

function TJclEmail.Read(const Options: TJclEmailReadOptions): Boolean;
var
  Flags: ULONG;
  Msg: PMapiMessage;
  I: Integer;
  Files: PMapiFileDesc;

  function CopyAndStrToInt(const S: string; Index, Count: Integer): Integer;
  begin
    Result := StrToIntDef(Copy(S, Index, Count), 0);
  end;

  function MessageDateToDate(const S: string): TDateTime;
  var
    T: TSystemTime;
  begin
    FillChar(T, SizeOf(T), #0);
    with T do
    begin
      wYear := CopyAndStrToInt(S, 1, 4);
      wMonth := CopyAndStrToInt(S, 6, 2);
      wDay := CopyAndStrToInt(S, 9, 2);
      wHour := CopyAndStrToInt(S, 12, 2);
      wMinute := CopyAndStrToInt(S, 15,2);
      Result := EncodeDate(wYear, wMonth, wDay) +
        EncodeTime(wHour, wMinute, wSecond, wMilliseconds);
    end;
  end;

begin
  Result := False;
  if not UserLogged then
    Exit;
  Clear;
  Flags := 0;
  if roHeaderOnly in Options then
    Inc(Flags, MAPI_ENVELOPE_ONLY);
  if not (roMarkAsRead in Options) then
    Inc(Flags, MAPI_PEEK);
  if not (roAttachments in Options) then
    Inc(Flags, MAPI_SUPPRESS_ATTACH);
  MapiCheck(MapiReadMail(SessionHandle, 0, PChar(FSeedMessageID), Flags, 0, Msg), True);
  if Msg <> nil then
  try
    DecodeRecips(Msg^.lpOriginator, 1);
    DecodeRecips(Msg^.lpRecips, Msg^.nRecipCount);
    FSubject := Msg^.lpszSubject;
    FBody := AdjustLineBreaks(Msg^.lpszNoteText);
    Files := Msg^.lpFiles;
    if Files <> nil then
      for I := 0 to Msg^.nFileCount - 1 do
      begin
        if Files^.lpszPathName <> nil then
          Attachments.Add(Files^.lpszPathName)
        else
          Attachments.Add(Files^.lpszFileName);
        Inc(Files);
      end;
    FReadMsg.MessageType := Msg^.lpszMessageType;
    if Msg^.lpszDateReceived <> nil then
      FReadMsg.DateReceived := MessageDateToDate(Msg^.lpszDateReceived);
    FReadMsg.ConversationID := Msg^.lpszConversationID;
    FReadMsg.Flags := Msg^.flFlags;
    Result := True;
  finally
    MapiFreeBuffer(Msg);
  end;
end;

//------------------------------------------------------------------------------

function TJclEmail.ResolveName(var Name, Address: string; ShowDialog: Boolean): Boolean;
var
  Recip: PMapiRecipDesc;
  Res, Flags: DWORD;
begin
  LoadClientLib;
  Flags := LogonOptionsToFlags(ShowDialog) or MAPI_AB_NOMODIFY;
  Recip := nil;
  Res := MapiResolveName(FSessionHandle, ParentWnd, PChar(Name), Flags, 0, Recip);
  Result := (MapiCheck(Res, True) = SUCCESS_SUCCESS) and (Recip <> nil);
  if Result then
  begin
    Address := Recip^.lpszAddress;
    Name := Recip^.lpszName;
    MapiFreeBuffer(Recip);
  end;
end;

//------------------------------------------------------------------------------

function TJclEmail.Save: Boolean;
begin
  Result := InternalSendOrSave(True, False);
end;

//------------------------------------------------------------------------------

function TJclEmail.Send(ShowDialog: Boolean): Boolean;
begin
  Result := InternalSendOrSave(False, ShowDialog);
end;

//------------------------------------------------------------------------------

procedure TJclEmail.SetBody(const Value: string);
begin
  FBody := StrEnsureSuffix(AnsiCrLf, Value);
end;

//------------------------------------------------------------------------------

procedure TJclEmail.SortAttachments;
begin
  TStringList(FAttachments).Sort;
end;

//==============================================================================
// Simple email send function
//==============================================================================

function JclSimpleSendMail(const ARecipient, AName, ASubject, ABody: string;
  const AAttachment: TFileName; ShowDialog: Boolean; AParentWND: HWND): Boolean;
begin
  with TJclEmail.Create do
  try
    ParentWnd := AParentWND;
    Recipients.Add(ARecipient, AName, rkTO, '');
    Subject := ASubject;
    Body := ABody;
    if AAttachment <> '' then
      Attachments.Add(AAttachment);
    Result := Send(ShowDialog);
  finally
    Free;
  end;
end;

//------------------------------------------------------------------------------

function JclSimpleBringUpSendMailDialog(const ASubject, ABody: string;
  const AAttachment: TFileName; AParentWND: HWND): Boolean;
begin
  with TJclEmail.Create do
  try
    ParentWnd := AParentWND;
    Subject := ASubject;
    Body := ABody;
    if AAttachment <> '' then
      Attachments.Add(AAttachment);
    Result := Send(True);
  finally
    Free;
  end;
end;

end.