unit tools.livetest;

interface

uses
  System.SysUtils, models.types, dto.invoice;

type
  // Parameters for the first live invoice against a real Saint database.
  // Defaults replicate invoice 000011 from snapshot 02 as closely as the
  // test database allows: one line, quantity 1, paid in foreign currency.
  // Replicating that document exactly is what makes the resulting dump diff
  // comparable against Saint's own.
  TLiveTestSettings = record
    CustomerCode: string;
    ProductCode: string;
    Quantity: TQuantity;
    PaidInForeignCurrency: Boolean;
    class function Default: TLiveTestSettings; static;
  end;

// Reads Professional.ini, opens the connection and loads the company row.
// Writes nothing. Returns a human-readable report.
function RunConnectionCheck: string;

// Issues one cash invoice and returns a human-readable report.
// On failure the exception message is returned instead; the invoice
// transaction has already been rolled back by then, but the invoice number
// and the control counters stay consumed.
function RunLiveInvoiceTest(const ASettings: TLiveTestSettings): string;

implementation

uses
  FireDAC.Comp.Client,
  data.connection, data.mapper, models.cfparame,
  services.connection, services.invoice;

class function TLiveTestSettings.Default: TLiveTestSettings;
begin
  Result.CustomerCode := '';
  Result.ProductCode := '';
  Result.Quantity := 1;
  Result.PaidInForeignCurrency := True;
end;

function YesNo(AValue: Boolean): string;
begin
  if AValue then
    Result := 'sí'
  else
    Result := 'no';
end;

function RunConnectionCheck: string;
var
  Settings: TSaintSettings;
  Connection: TFDConnection;
  Session: ISaintSession;
  Params: TParameters;
begin
  try
    Settings := TSaintSettings.Load;

    Result :=
      'Configuración leída de Professional.ini' + sLineBreak +
      '  Servidor ........ ' + Settings.Host + ':' + IntToStr(Settings.Port) + sLineBreak +
      '  Base de datos ... ' + Settings.Database + sLineBreak +
      '  Usuario ......... ' + Settings.UserName + sLineBreak +
      '  Estación ........ ' + Settings.Station + sLineBreak +
      '  Usa caja ........ ' + YesNo(Settings.UsesCashRegister) + sLineBreak +
      '  Usa IGTF ........ ' + YesNo(Settings.UsesIGTF) +
        ' (' + FormatFloat('0.##', Settings.IGTFRate) + '%)' + sLineBreak;

    Connection := TSaintConnectionFactory.Build(Settings);
    // The session takes ownership of the connection.
    Session := TSaintSession.Create(Connection, True);

    Params := TParameters.Create;
    try
      if not TEntityMapper.SelectOne(Session, Params, 'cfparame',
           'CONTROL = 1', []) then
        Exit(Result + sLineBreak +
          'Conectado, pero no se encontró la configuración de la empresa.');

      Result := Result + sLineBreak +
        'Conexión establecida' + sLineBreak +
        '  Empresa ......... ' + Params.NOMBRE + sLineBreak +
        '  RIF ............. ' + Params.NUMFISCAL + sLineBreak +
        '  IVA general ..... ' + FormatFloat('0.00', Params.IMPPOR) + '%' + sLineBreak +
        '  Tasa de cambio .. ' + FormatFloat('#,##0.0000', Params.TASACAMBIO1) + sLineBreak +
        '  Próxima factura . ' + IntToStr(Params.NROINIFAC) + sLineBreak +
        '  CONTADORCONTROL . ' + IntToStr(Params.CONTADORCONTROL);
    finally
      Params.Free;
    end;
  except
    on E: Exception do
      Result := 'Falló la verificación: ' + E.Message;
  end;
end;

function BuildReport(const AResult: TInvoiceResult): string;
begin
  Result :=
    'Factura emitida' + sLineBreak +
    '  Número .......... ' + AResult.InvoiceNumber + sLineBreak +
    '  CONTROL factura . ' + AResult.InvoiceControl + sLineBreak +
    '  CONTROL pago .... ' + AResult.PaymentControl + sLineBreak;

  if AResult.CashControl <> '' then
    Result := Result +
      '  CONTROL caja .... ' + AResult.CashControl + sLineBreak
  else
    Result := Result +
      '  CONTROL caja .... (módulo de caja desactivado)' + sLineBreak;

  Result := Result +
    '  Fecha Clarion ... ' + IntToStr(AResult.IssueDate) +
      ' (' + ClarionToStr(AResult.IssueDate) + ')' + sLineBreak +
    '  Base ............ ' + FormatFloat('#,##0.00', AResult.GrossAmount) + sLineBreak +
    '  IVA ............. ' + FormatFloat('#,##0.00', AResult.TaxAmount) + sLineBreak +
    '  IGTF ............ ' + FormatFloat('#,##0.00', AResult.IGTFAmount) + sLineBreak +
    '  Total ........... ' + FormatFloat('#,##0.00', AResult.TotalAmount);
end;

function RunLiveInvoiceTest(const ASettings: TLiveTestSettings): string;
var
  Settings: TSaintSettings;
  Connection: TFDConnection;
  Session: ISaintSession;
  Service: TInvoiceService;
  Request: TInvoiceRequest;
  Line: TInvoiceLineRequest;
begin
  if Trim(ASettings.CustomerCode) = '' then
    Exit('Falta indicar el código del cliente de prueba.');
  if Trim(ASettings.ProductCode) = '' then
    Exit('Falta indicar el código del producto de prueba.');

  try
    Settings := TSaintSettings.Load;
    Connection := TSaintConnectionFactory.Build(Settings);

    // The session takes ownership of the connection.
    Session := TSaintSession.Create(Connection, True);

    Service := TInvoiceService.Create(Session, Settings);
    try
      Request := TInvoiceRequest.Create;
      try
        Request.CustomerCode := ASettings.CustomerCode;
        Request.PaidInForeignCurrency := ASettings.PaidInForeignCurrency;

        Line := Request.AddLine;
        Line.ProductCode := ASettings.ProductCode;
        Line.Quantity := ASettings.Quantity;
        // UnitPrice left at 0 so the price comes from ivproser, the same way
        // Saint resolves it.

        Result := BuildReport(Service.Issue(Request));
      finally
        Request.Free;
      end;
    finally
      Service.Free;
    end;
  except
    on E: Exception do
      Result := 'Falló la emisión: ' + E.Message;
  end;
end;

end.
