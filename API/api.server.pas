unit api.server;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  Horse,
  models.types, models.cfprocli, models.ivproser,
  models.dcheader, models.dcdetall,
  dto.invoice, data.connection, services.connection, services.queries,
  services.documents, services.invoice, api.json, api.fields, api.filters;

const
  DEFAULT_PORT = 9000;
  API_PREFIX = '/api/v1';

// Registers the routes and blocks listening on APort.
procedure StartServer(APort: Integer = DEFAULT_PORT);

implementation

uses
  FireDAC.Comp.Client, data.mapper;

var
  GSettings: TSaintSettings;

// Serialises and sends AJson, then frees it. Doing this by hand keeps the
// project free of the Jhonson middleware, which only added body parsing and
// this same serialisation step.
procedure SendJson(Res: THorseResponse; AJson: TJSONObject;
  AStatus: Integer = 200);
begin
  try
    Res.ContentType('application/json; charset=utf-8')
       .Status(AStatus)
       .Send(AJson.ToJSON);
  finally
    AJson.Free;
  end;
end;

procedure SendError(Res: THorseResponse; const AMessage: string;
  AStatus: Integer);
begin
  SendJson(Res, TJsonMapper.ErrorToJson(AMessage), AStatus);
end;

// Horse serves each request on its own thread, and a FireDAC connection
// cannot be shared across threads. Every request therefore opens its own
// connection and closes it on the way out. If throughput ever demands it,
// this is the single place to swap in a TFDManager pool; the services take
// the session as a parameter and do not care where it came from.
function NewSession: ISaintSession;
begin
  Result := TSaintSession.Create(TSaintConnectionFactory.Build(GSettings), True);
end;

function ReadInt(const AText: string; ADefault: Integer): Integer;
begin
  if not TryStrToInt(AText, Result) then
    Result := ADefault;
end;

// Resolves ?fields= and the column filters in one step, since both fail the
// same way and both must run before any database work.
function ParseRequest(AClass: TClass; Req: THorseRequest; Res: THorseResponse;
  out AColumns: TArray<string>; out AWhere: string;
  out AParams: TArray<Variant>): Boolean;
begin
  Result := False;
  try
    AColumns := TFieldSelection.Parse(AClass, Req.Query.Field('fields').AsString);
    TFilterParser.Parse(AClass, Req.Query, AWhere, AParams);
    Result := True;
  except
    on E: EInvalidFieldsError do
      SendError(Res, E.Message, 400);
    on E: EInvalidFilterError do
      SendError(Res, E.Message, 400);
  end;
end;

procedure GetCustomers(Req: THorseRequest; Res: THorseResponse);
var
  Session: ISaintSession;
  Service: TQueryService;
  Columns: TArray<string>;
  Where: string;
  Params: TArray<Variant>;
  PageSize, Offset: Integer;
  List: TObjectList<TParty>;
begin
  if not ParseRequest(TParty, Req, Res, Columns, Where, Params) then
    Exit;

  PageSize := ReadInt(Req.Query.Field('limit').AsString, DEFAULT_PAGE_SIZE);
  Offset := ReadInt(Req.Query.Field('offset').AsString, 0);

  Session := NewSession;
  Service := TQueryService.Create(Session);
  try
    List := Service.FindCustomers(Where, Params, PageSize, Offset, Columns);
    try
      SendJson(Res, TJsonMapper.EntityListToJson<TParty>(
        List, Service.CountCustomers(Where, Params), Offset, Columns));
    finally
      List.Free;
    end;
  finally
    Service.Free;
  end;
end;

procedure GetCustomer(Req: THorseRequest; Res: THorseResponse);
var
  Session: ISaintSession;
  Service: TQueryService;
  Columns: TArray<string>;
  Customer: TParty;
begin
  try
    Columns := TFieldSelection.Parse(TParty, Req.Query.Field('fields').AsString);
  except
    on E: EInvalidFieldsError do
    begin
      SendError(Res, E.Message, 400);
      Exit;
    end;
  end;

  Session := NewSession;
  Service := TQueryService.Create(Session);
  try
    Customer := Service.GetCustomer(Req.Params['codigo'], Columns);
    if Customer = nil then
    begin
      SendError(Res, 'No existe el cliente indicado.', 404);
      Exit;
    end;
    try
      SendJson(Res, TJsonMapper.EntityToJson(Customer, Columns));
    finally
      Customer.Free;
    end;
  finally
    Service.Free;
  end;
end;

procedure GetProducts(Req: THorseRequest; Res: THorseResponse);
var
  Session: ISaintSession;
  Service: TQueryService;
  Columns: TArray<string>;
  Where: string;
  Params: TArray<Variant>;
  PageSize, Offset: Integer;
  List: TObjectList<TProduct>;
begin
  if not ParseRequest(TProduct, Req, Res, Columns, Where, Params) then
    Exit;

  PageSize := ReadInt(Req.Query.Field('limit').AsString, DEFAULT_PAGE_SIZE);
  Offset := ReadInt(Req.Query.Field('offset').AsString, 0);

  Session := NewSession;
  Service := TQueryService.Create(Session);
  try
    List := Service.FindProducts(Where, Params, PageSize, Offset, Columns);
    try
      SendJson(Res, TJsonMapper.EntityListToJson<TProduct>(
        List, Service.CountProducts(Where, Params), Offset, Columns));
    finally
      List.Free;
    end;
  finally
    Service.Free;
  end;
end;

procedure GetProduct(Req: THorseRequest; Res: THorseResponse);
var
  Session: ISaintSession;
  Service: TQueryService;
  Columns: TArray<string>;
  Product: TProduct;
begin
  try
    Columns := TFieldSelection.Parse(TProduct, Req.Query.Field('fields').AsString);
  except
    on E: EInvalidFieldsError do
    begin
      SendError(Res, E.Message, 400);
      Exit;
    end;
  end;

  Session := NewSession;
  Service := TQueryService.Create(Session);
  try
    Product := Service.GetProduct(Req.Params['codigo'], Columns);
    if Product = nil then
    begin
      SendError(Res, 'No existe el producto indicado.', 404);
      Exit;
    end;
    try
      SendJson(Res, TJsonMapper.EntityToJson(Product, Columns));
    finally
      Product.Free;
    end;
  finally
    Service.Free;
  end;
end;

procedure GetDocuments(Req: THorseRequest; Res: THorseResponse);
var
  Session: ISaintSession;
  Service: TDocumentService;
  Columns: TArray<string>;
  Where: string;
  Params: TArray<Variant>;
  PageSize, Offset: Integer;
  List: TObjectList<TDCHeader>;
begin
  if not ParseRequest(TDCHeader, Req, Res, Columns, Where, Params) then
    Exit;

  PageSize := ReadInt(Req.Query.Field('limit').AsString,
    DEFAULT_DOCUMENT_PAGE_SIZE);
  Offset := ReadInt(Req.Query.Field('offset').AsString, 0);

  Session := NewSession;
  Service := TDocumentService.Create(Session);
  try
    List := Service.FindDocuments(Where, Params, PageSize, Offset, Columns);
    try
      SendJson(Res, TJsonMapper.EntityListToJson<TDCHeader>(
        List, Service.CountDocuments(Where, Params), Offset, Columns));
    finally
      List.Free;
    end;
  finally
    Service.Free;
  end;
end;

procedure GetDocument(Req: THorseRequest; Res: THorseResponse);
var
  Session: ISaintSession;
  Service: TDocumentService;
  Columns: TArray<string>;
  Header: TDCHeader;
begin
  try
    Columns := TFieldSelection.Parse(TDCHeader, Req.Query.Field('fields').AsString);
  except
    on E: EInvalidFieldsError do
    begin
      SendError(Res, E.Message, 400);
      Exit;
    end;
  end;

  Session := NewSession;
  Service := TDocumentService.Create(Session);
  try
    // Documents are addressed by CONTROL, the only truly unique key in
    // dcheader. NUMREF repeats across TIPREG and is not safe as an id.
    Header := Service.GetByControl(Req.Params['control'], Columns);
    if Header = nil then
    begin
      SendError(Res, 'No existe el documento indicado.', 404);
      Exit;
    end;
    try
      SendJson(Res, TJsonMapper.EntityToJson(Header, Columns));
    finally
      Header.Free;
    end;
  finally
    Service.Free;
  end;
end;

procedure GetDocumentLines(Req: THorseRequest; Res: THorseResponse);
var
  Session: ISaintSession;
  Service: TDocumentService;
  Columns: TArray<string>;
  Lines: TObjectList<TDCDetail>;
begin
  try
    Columns := TFieldSelection.Parse(TDCDetail, Req.Query.Field('fields').AsString);
  except
    on E: EInvalidFieldsError do
    begin
      SendError(Res, E.Message, 400);
      Exit;
    end;
  end;

  Session := NewSession;
  Service := TDocumentService.Create(Session);
  try
    Lines := Service.GetLines(Req.Params['control'], Columns);
    try
      SendJson(Res, TJsonMapper.EntityListToJson<TDCDetail>(
        Lines, Lines.Count, 0, Columns));
    finally
      Lines.Free;
    end;
  finally
    Service.Free;
  end;
end;

procedure PostInvoice(Req: THorseRequest; Res: THorseResponse);
var
  Session: ISaintSession;
  Service: TInvoiceService;
  Body: TJSONValue;
  Request: TInvoiceRequest;
begin
  // Without Jhonson the body arrives as raw text and is parsed here.
  Body := TJSONObject.ParseJSONValue(Req.Body);
  if not (Body is TJSONObject) then
  begin
    Body.Free;
    SendError(Res, 'El cuerpo de la solicitud no es un objeto JSON válido.', 400);
    Exit;
  end;

  try
    try
      Request := TJsonMapper.JsonToInvoiceRequest(TJSONObject(Body));
    except
      on E: EInvoiceRequestError do
      begin
        SendError(Res, E.Message, 400);
        Exit;
      end;
    end;

    try
      try
        Session := NewSession;
        Service := TInvoiceService.Create(Session, GSettings);
        try
          SendJson(Res,
            TJsonMapper.InvoiceResultToJson(Service.Issue(Request)), 201);
        finally
          Service.Free;
        end;
      except
        on E: EInvoiceError do
          // The transaction is already rolled back by the service. The
          // invoice number and control counters stay consumed either way.
          SendError(Res, E.Message, 422);
        on E: Exception do
          SendError(Res, E.Message, 500);
      end;
    finally
      Request.Free;
    end;
  finally
    Body.Free;
  end;
end;

procedure GetStatus(Req: THorseRequest; Res: THorseResponse);
var
  Status: TJSONObject;
begin
  Status := TJSONObject.Create;
  Status.AddPair('servidor', 'ProfessionalServer');
  Status.AddPair('baseDatos', GSettings.Database);
  Status.AddPair('estacion', GSettings.Station);
  Status.AddPair('usaCaja', TJSONBool.Create(GSettings.UsesCashRegister));
  Status.AddPair('usaIGTF', TJSONBool.Create(GSettings.UsesIGTF));
  SendJson(Res, Status);
end;

// Lists the columns each resource exposes, so a client can discover what to
// ask for in ?fields= and what it can filter by.
function SchemaJson(AClass: TClass): TJSONObject;
var
  Columns: TJSONArray;
  Column: string;
begin
  Columns := TJSONArray.Create;
  for Column in TEntityMapper.ColumnNames(AClass) do
    Columns.Add(Column);
  Result := TJSONObject.Create;
  Result.AddPair('fields', Columns);
end;

procedure GetCustomerSchema(Req: THorseRequest; Res: THorseResponse);
begin
  SendJson(Res, SchemaJson(TParty));
end;

procedure GetProductSchema(Req: THorseRequest; Res: THorseResponse);
begin
  SendJson(Res, SchemaJson(TProduct));
end;

procedure GetDocumentSchema(Req: THorseRequest; Res: THorseResponse);
var
  Body: TJSONObject;
  HeaderFields, LineFields: TJSONArray;
  Column: string;
begin
  HeaderFields := TJSONArray.Create;
  for Column in TEntityMapper.ColumnNames(TDCHeader) do
    HeaderFields.Add(Column);

  LineFields := TJSONArray.Create;
  for Column in TEntityMapper.ColumnNames(TDCDetail) do
    LineFields.Add(Column);

  Body := TJSONObject.Create;
  Body.AddPair('fields', HeaderFields);
  Body.AddPair('lineFields', LineFields);
  SendJson(Res, Body);
end;

procedure StartServer(APort: Integer);
begin
  // Read once at startup: Professional.ini does not change while running.
  GSettings := TSaintSettings.Load;

  // Horse resolves routes in registration order, so every literal segment
  // must be registered before the parameterised route it would collide with.
  THorse.Get(API_PREFIX + '/status', GetStatus);
  THorse.Get(API_PREFIX + '/customers', GetCustomers);
  THorse.Get(API_PREFIX + '/customers/schema', GetCustomerSchema);
  THorse.Get(API_PREFIX + '/customers/:codigo', GetCustomer);
  THorse.Get(API_PREFIX + '/products', GetProducts);
  THorse.Get(API_PREFIX + '/products/schema', GetProductSchema);
  THorse.Get(API_PREFIX + '/products/:codigo', GetProduct);
  THorse.Get(API_PREFIX + '/documents', GetDocuments);
  THorse.Get(API_PREFIX + '/documents/schema', GetDocumentSchema);
  THorse.Get(API_PREFIX + '/documents/:control', GetDocument);
  THorse.Get(API_PREFIX + '/documents/:control/lines', GetDocumentLines);
  THorse.Post(API_PREFIX + '/invoices', PostInvoice);

  Writeln(Format('Escuchando en http://localhost:%d%s', [APort, API_PREFIX]));
  Writeln('Ctrl+C para detener.');
  THorse.Listen(APort);
end;

end.
