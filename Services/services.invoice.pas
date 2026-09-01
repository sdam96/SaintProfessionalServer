unit services.invoice;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  models.types, models.dcheader, models.dcdetall, models.cjdetall,
  models.igtfrecords, models.movprod, models.hiproduc, models.hiprocli,
  models.hiresume, models.ivproser, models.cfprocli, models.cfparame,
  dto.invoice, services.connection, services.counters, services.control;

type
  EInvoiceError = class(Exception);

  TDocumentTotals = record
    Gross: TAmount;       // sum of line TOTAL, net of tax
    Discount: TAmount;
    Subtotal: TAmount;
    Tax: TAmount;
    IGTF: TAmount;
    Total: TAmount;       // MONTOTOT: includes tax and IGTF
    Cost: TAmount;        // sum of line MONTOCOS
  end;

  TInvoiceService = class
  private
    FSession: ISaintSession;
    FAllocator: ICounterAllocator;
    FParams: TParameters;

    function LoadCustomer(const ACode: string): TParty;
    function LoadProduct(const ACode: string): TProduct;
    function FormatDocumentNumber(ANumber: Integer): string;
    function FormatPaymentCaption(const AAmount: TAmount): string;

    procedure ValidateRequest(ARequest: TInvoiceRequest);
    procedure UpdateStock(AProduct: TProduct; const AQty: TQuantity;
      ADate: TClarionDate);
    procedure UpsertProductMovement(const AProductCode: string;
      ADate: TClarionDate; const ADocNumber: string; const AQty: TQuantity;
      ACustomer: TParty; const ASalespersonName: string);
    procedure AccumulateProductHistory(const AProductCode: string;
      AYear, AMonth: Integer; const AQty: TQuantity; const AAmount: TAmount);
    procedure AccumulateSalesHistory(const ACustomerCode: string;
      AYear, AMonth: Integer; const ANetAmount: TAmount);
    procedure UpdateCustomerBalance(ACustomer: TParty; ADate: TClarionDate;
      const ATotal: TAmount);
  public
    constructor Create(const ASession: ISaintSession);
    destructor Destroy; override;
    function Issue(ARequest: TInvoiceRequest): TInvoiceResult;
  end;

implementation

uses
  System.DateUtils;

const
  TIPREG_SALES = 1;
  IGTF_RATE: TRate = 3.00;
  // Literal values Saint expects to find in these columns; they are data,
  // not user-facing text.
  SALES_MODULE = 'Ventas';
  DIRECT_SALES = 'Ventas Directas';

// Formula verified against invoice 000011 (snapshot 02):
//   Gross 2142.86 + Tax 342.86 = 2485.72 ; x 1.03 = 2560.29 = MONTOTOT
//
// Invoice 000012 (snapshot 03) does NOT match:
//   Gross 4285.72 + Tax 685.72 = 4971.44 ; observed MONTOTOT = 10071.45
//   Delta 5100.01 ~ 6 x 850 (FACTORCAMBIO), and its igtfrecords row is
//   all zeros. UNRESOLVED.
function Round2(const AValue: TAmount): TAmount;
begin
  Result := RoundTo(AValue, -2);
end;

constructor TInvoiceService.Create(const ASession: ISaintSession);
begin
  inherited Create;
  FSession := ASession;
  FAllocator := TCounterAllocator.Create(ASession);
  FParams := nil;
end;

destructor TInvoiceService.Destroy;
begin
  FParams.Free;
  inherited;
end;

function TInvoiceService.FormatDocumentNumber(ANumber: Integer): string;
begin
  Result := Format('%.6d', [ANumber]);
end;

function TInvoiceService.FormatPaymentCaption(const AAmount: TAmount): string;
begin
  // dcheader.DESCRIP2 on a PAGxFAC: 'Por' plus the amount right-aligned in
  // 13 characters. Observed: 'Por     2,560.29' and 'Por    10,071.45'.
  Result := 'Por' + Format('%13s', [FormatFloat('#,##0.00', AAmount)]);
end;

procedure TInvoiceService.ValidateRequest(ARequest: TInvoiceRequest);
var
  Line: TInvoiceLineRequest;
begin
  if ARequest.Lines.Count = 0 then
    raise EInvoiceError.Create('La factura no tiene renglones.');
  if Trim(ARequest.CustomerCode) = '' then
    raise EInvoiceError.Create('Falta el código del cliente.');

  for Line in ARequest.Lines do
  begin
    if Trim(Line.ProductCode) = '' then
      raise EInvoiceError.Create('Hay un renglón sin código de producto.');
    if Line.Quantity <= 0 then
      raise EInvoiceError.CreateFmt(
        'Cantidad inválida en el renglón %s.', [Line.ProductCode]);
  end;
end;

function TInvoiceService.Issue(ARequest: TInvoiceRequest): TInvoiceResult;
var
  Customer: TParty;
  Block: TControlBlock;
  Generator: TControlGenerator;
  IssueDate: TClarionDate;
  IssueTime: TClarionTime;
  DateText: string;
  InvoiceNo: Integer;
  DocNumber: string;
  Header, Payment: TDCHeader;
  Line: TDCDetail;
  Cash: TCashDetail;
  Igtf: TIGTFRecord;
  Product: TProduct;
  Req: TInvoiceLineRequest;
  Totals: TDocumentTotals;
  UnitPrice, LineBase, LineTax: TAmount;
  Year, Month, Day: Word;
begin
  ValidateRequest(ARequest);

  if ARequest.PaymentTerms = ptCredit then
    raise EInvoiceError.Create(
      'La facturación a crédito aún no está disponible.');

  IssueDate := DateToClarion(Date);
  IssueTime := CurrentClarionTime;
  DateText := ClarionToStr(IssueDate);
  DecodeDate(Date, Year, Month, Day);

  Customer := LoadCustomer(ARequest.CustomerCode);
  try
    // Reserve: 1 header + N lines + 1 cash row + 1 payment.
    // Short transaction, already committed when this returns.
    InvoiceNo := FAllocator.AllocateInvoiceNumber;
    Block := FAllocator.AllocateControlBlock(ARequest.Lines.Count + 3);
    DocNumber := FormatDocumentNumber(InvoiceNo);

    Generator := TControlGenerator.Create(IssueDate, IssueTime);
    try
      FSession.BeginTx;
      try
        Header := TDCHeader.Create;
        Header.CONTROL := Generator.NewControl(Block);
        Header.TIPREG := TIPREG_SALES;
        Header.CODIGO := Customer.CODIGO;
        Header.TIPTRAN := 'FAC';
        Header.NUMREF := DocNumber;
        Header.NUMDOC := '';
        Header.DESCRIP1 := 'Factura ' + DocNumber;
        Header.FECEMIS := IssueDate;
        Header.FECEMISS := DateText;
        Header.DIASVEN := 0;
        Header.FECVENC := IssueDate;
        Header.FECVENCS := DateText;
        Header.NOMBRE := Customer.NOMBRE;
        Header.RIF := Customer.RIF;
        Header.NIT := Customer.NIT;
        Header.DIRECCION := Customer.DIRECC1;
        Header.DIRECCION2 := Customer.DIRECC2;
        Header.TELEFCLIEV := Customer.NUMTEL;
        Header.CODVEN := ARequest.SalespersonCode;
        Header.CODUSER := ARequest.UserCode;
        Header.CODALENT := '01';
        Header.CODALREC := '';
        Header.HORA := IssueTime;
        Header.PORIMP := FParams.IMPPOR;
        Header.FACTORCAMBIO := FParams.TASACAMBIO1;
        Header.SIGNOMONEDA := FParams.MONEDA;
        Header.DESDEMODULO := SALES_MODULE;
        Header.TIPOFACTURA := 'CONTADO';
        Header.FECULTIMOPAGO := IssueDate;
        Header.CONTADOR := 1;
        Header.TOTCONTADOR := 2;              // FAC + PAGxFAC
        Header.CONTROLDOC := Header.CONTROL;
        Header.COMISV := 1;
        Header.COMISC := 0;
        Header.TIPOCLI := Customer.TIPOCLI;
        Header.TIPOPRO := '';

        FillChar(Totals, SizeOf(Totals), 0);

        for Req in ARequest.Lines do
        begin
          Product := LoadProduct(Req.ProductCode);
          try
            if Req.UnitPrice > 0 then
              UnitPrice := Req.UnitPrice
            else
              case Customer.PRECIO of
                2: UnitPrice := Product.PRECIO2;
                3: UnitPrice := Product.PRECIO3;
              else
                UnitPrice := Product.PRECIO1;
              end;

            LineBase := Round2(UnitPrice * Req.Quantity);
            if Product.EXENTO <> 0 then
              LineTax := 0
            else
              LineTax := Round2(LineBase * Product.IMPPOR / 100);

            Line := TDCDetail.Create;
            Line.CONTROL := Header.CONTROL;
            Line.FECHORA := Generator.NewControl(Block);
            Line.FHPRODBASE := Line.FECHORA;   // observed: always identical
            Line.CODPRO := Product.CODPRO;
            Line.DESCRIP1 := Product.DESCRIP1;
            Line.CANTIDAD := Req.Quantity;
            Line.PRECOSUNI := UnitPrice;
            Line.COSTOACT := Product.COSTOACT;
            Line.COSTOPRO := Product.COSTOPRO;
            if Product.EXENTO <> 0 then
              Line.IMPPOR := 0
            else
              Line.IMPPOR := Product.IMPPOR;
            Line.MONTOIMP := LineTax;
            Line.TOTAL := LineBase;
            Line.MONTOCOS := Round2(Product.COSTOACT * Req.Quantity);
            Line.TIPTRAN := 'FAC';
            Line.FECEMIS := IssueDate;
            Line.FECEMISS := DateText;
            Line.TIPREG := TIPREG_SALES;
            Line.TIPODET := 0;
            Line.TIPPRO := Product.TIPPRO;
            Line.TIPINV := Product.TIPINV;
            Line.CODIGO := Customer.CODIGO;
            Line.COMISTIP := 4;                // observed on cash sales
            Line.CODALENT := '01';
            Line.CODALREC := '';
            Line.CODIGODEP := Req.WarehouseCode;
            Line.GRUPOINV := Product.GRUPOINV;
            Line.LINEAOINV := Product.LINEAINV;
            Line.CODSER := Req.ServerCode;
            Line.CODVEN := ARequest.SalespersonCode;
            Line.NOMBRE := DIRECT_SALES;
            if Customer.PRECIO = 0 then
              Line.PRECIO := 1
            else
              Line.PRECIO := Customer.PRECIO;
            Line.FACTORCAMBIO := FParams.TASACAMBIO1;
            Line.SIGNOMONEDA := FParams.MONEDA;
            Line.PROCESADO := 0;
            Line.ORIGEN := 0;
            Line.CODIMPUESTO1 := Product.CODIMPUESTO1;

            // TODO: persist Line through the ORM

            Totals.Gross := Totals.Gross + LineBase;
            Totals.Tax := Totals.Tax + LineTax;
            Totals.Cost := Totals.Cost + Line.MONTOCOS;

            UpdateStock(Product, Req.Quantity, IssueDate);
            UpsertProductMovement(Product.CODPRO, IssueDate, DocNumber,
              Req.Quantity, Customer, DIRECT_SALES);
            AccumulateProductHistory(Product.CODPRO, Year, Month,
              Req.Quantity, LineBase);
          finally
            Product.Free;
          end;
        end;

        Totals.Subtotal := Totals.Gross - Totals.Discount;
        if ARequest.PaidInForeignCurrency then
          Totals.IGTF := Round2((Totals.Subtotal + Totals.Tax) * IGTF_RATE / 100)
        else
          Totals.IGTF := 0;
        Totals.Total := Round2(Totals.Subtotal + Totals.Tax + Totals.IGTF);

        if not IsAmountInRange(Totals.Total) then
          raise EInvoiceError.Create(
            'El monto total excede el límite permitido por el sistema.');

        Header.MONTOBRU := Totals.Gross;
        Header.MONTODES := Totals.Discount;
        Header.MONTOSUB := Totals.Subtotal;
        Header.MONTOIMP := Totals.Tax;
        Header.MONTOTOT := Totals.Total;
        Header.MONTOEFE := Totals.Total;
        Header.MONTOPAGF := Totals.Total;
        Header.MONTOSAL := 0;
        Header.MONTOPAG := 0;
        Header.MONTOCOS := Totals.Cost;
        Header.BASEIMPONIBLEIVA := 0;          // observed 0 on cash sales
        // TODO: persist Header through the ORM

        Cash := TCashDetail.Create;
        Cash.CONTROL := Generator.NewControl(Block);
        Cash.CODCAJA := ARequest.CashRegisterCode;
        Cash.NUMREF := DocNumber + 'R';
        Cash.NUMDOC := DocNumber;
        Cash.FECEMIS := IssueDate;
        Cash.FECEMISS := '';                   // Saint leaves this empty here
        Cash.MONTOCOBRADO := Totals.Total;
        Cash.TIPOCOBRO := 0;                   // cash
        Cash.HORA := IssueTime;
        Cash.TIPTRAN := 'FAC';
        Cash.CODIGO := Customer.CODIGO;
        Cash.DESCRIP1 := 'Factura ' + DocNumber;
        Cash.ESTADOCAJA := 0;
        // TODO: persist Cash through the ORM

        Payment := TDCHeader.Create;
        Payment.CONTROL := Generator.NewControl(Block);
        Payment.TIPREG := TIPREG_SALES;
        Payment.CODIGO := Customer.CODIGO;
        Payment.TIPTRAN := 'PAGxFAC';
        Payment.NUMREF := DocNumber;
        Payment.NUMDOC := DocNumber + 'R';
        Payment.DESCRIP1 := 'Pago factura ' + DocNumber;
        Payment.DESCRIP2 := FormatPaymentCaption(Totals.Total);
        Payment.FECEMIS := IssueDate;
        Payment.FECEMISS := DateText;
        Payment.FECVENC := IssueDate;
        Payment.FECVENCS := DateText;
        Payment.MONTOBRU := Totals.Total;
        Payment.MONTOSUB := Totals.Total;
        Payment.MONTOIMP := Totals.Tax;
        Payment.PORIMP := FParams.IMPPOR;
        Payment.MONTOTOT := Totals.Total;
        Payment.MONTOSAL := 0;
        Payment.MONTOPAGF := 0;
        Payment.MONTOCOS := 0;
        Payment.NOMBRE := Customer.NOMBRE;
        Payment.RIF := Customer.RIF;
        Payment.DIRECCION := Customer.DIRECC1;
        Payment.DIRECCION2 := Customer.DIRECC2;
        Payment.TELEFCLIEV := Customer.NUMTEL;
        Payment.CONTADOR := 2;
        Payment.TOTCONTADOR := 0;
        Payment.CONTROLDOC := Header.CONTROL;  // links back to the invoice
        Payment.CODVEN := ARequest.SalespersonCode;
        Payment.CODUSER := ARequest.UserCode;
        Payment.CODALENT := '01';
        Payment.HORA := IssueTime;
        Payment.FACTORCAMBIO := FParams.TASACAMBIO1;
        Payment.SIGNOMONEDA := FParams.MONEDA;
        Payment.DESDEMODULO := SALES_MODULE;
        Payment.TIPOFACTURA := '';
        Payment.FECULTIMOPAGO := IssueDate;
        Payment.COMISV := 0;
        // TODO: persist Payment through the ORM

        Igtf := TIGTFRecord.Create;
        Igtf.dcheaderCONTROL := Header.CONTROL;
        Igtf.baseImponibleGeneral := Totals.Gross;
        Igtf.porcentajeImpuestoIGTF := '3';    // TEXT, not numeric
        Igtf.DESCRIPCION := 'Dolar';
        // On invoice 000011, IGTFEFECTIVOMONEDALOCAL = 2558.50 while
        // MONTOTOT = 2560.29. The 1.79 gap is unexplained. We write the
        // total and compare during the live test.
        if ARequest.PaidInForeignCurrency then
          Igtf.IGTFEFECTIVOMONEDALOCAL := Totals.Total
        else
          Igtf.IGTFEFECTIVOMONEDALOCAL := 0;
        // TODO: persist Igtf through the ORM

        AccumulateSalesHistory(Customer.CODIGO, Year, Month,
          Totals.Total - Totals.Tax);
        UpdateCustomerBalance(Customer, IssueDate, Totals.Total);

        FSession.CommitTx;

        Result.InvoiceControl := Header.CONTROL;
        Result.PaymentControl := Payment.CONTROL;
        Result.CashControl := Cash.CONTROL;
        Result.InvoiceNumber := DocNumber;
        Result.GrossAmount := Totals.Gross;
        Result.TaxAmount := Totals.Tax;
        Result.IGTFAmount := Totals.IGTF;
        Result.TotalAmount := Totals.Total;
        Result.IssueDate := IssueDate;
      except
        FSession.RollbackTx;
        raise;
      end;
    finally
      Generator.Free;
    end;
  finally
    Customer.Free;
  end;
end;

procedure TInvoiceService.UpdateStock(AProduct: TProduct;
  const AQty: TQuantity; ADate: TClarionDate);
begin
  // CANVEN holds the quantity of THIS sale, not a running total.
  // Stock may go negative; Saint allows it (-12 was observed).
  FSession.Execute(
    'UPDATE ivproser SET EXISTENCIA = EXISTENCIA - :qty, FECVEN = :dt, ' +
    'CANVEN = :qty2, MOVMES = 1 WHERE CODPRO = :code',
    [AQty, ADate, AQty, AProduct.CODPRO]);
end;

procedure TInvoiceService.UpsertProductMovement(const AProductCode: string;
  ADate: TClarionDate; const ADocNumber: string; const AQty: TQuantity;
  ACustomer: TParty; const ASalespersonName: string);
begin
  // The row may not exist yet (product never moved). Safe because CODPRO
  // carries a unique index.
  FSession.Execute(
    'INSERT INTO movprod (CODPRO, TIPINV, FECULTCOMP, NUMULTCOMPRA, ' +
    '  CANTULTCOMP, IDPROVEE, NOMPROVEE, NOMRESPONS, FECULTVENT, ' +
    '  NUMULTVENT, CANTULTVENT, IDCLIEN, NOMCLIENTE, NOMVENDEDOR) ' +
    'VALUES (:code, 0, 0, '''', 0, '''', '''', '''', :dt, :num, :qty, ' +
    '        :cust, :custname, :seller) ' +
    'ON DUPLICATE KEY UPDATE FECULTVENT = :dt2, NUMULTVENT = :num2, ' +
    '  CANTULTVENT = :qty2, IDCLIEN = :cust2, NOMCLIENTE = :custname2, ' +
    '  NOMVENDEDOR = :seller2',
    [AProductCode, ADate, ADocNumber, AQty, ACustomer.CODIGO,
     ACustomer.NOMBRE, ASalespersonName,
     ADate, ADocNumber, AQty, ACustomer.CODIGO,
     ACustomer.NOMBRE, ASalespersonName]);
end;

procedure TInvoiceService.AccumulateProductHistory(const AProductCode: string;
  AYear, AMonth: Integer; const AQty: TQuantity; const AAmount: TAmount);
begin
  FSession.Execute(
    'INSERT INTO hiproduc (ANIOH, MESH, CODPRO, CANVENTA, MONTOVENTA) ' +
    'VALUES (:y, :m, :code, :qty, :amt) ' +
    'ON DUPLICATE KEY UPDATE CANVENTA = CANVENTA + :qty2, ' +
    '  MONTOVENTA = MONTOVENTA + :amt2',
    [AYear, AMonth, AProductCode, AQty, AAmount, AQty, AAmount]);
end;

procedure TInvoiceService.AccumulateSalesHistory(const ACustomerCode: string;
  AYear, AMonth: Integer; const ANetAmount: TAmount);
begin
  // Rule verified on 000011 and 000012:
  //   CONTADO += MONTOTOT - MONTOIMP   (total with IGTF, minus tax)
  //   COBPAG  += same value
  // IMPUESTO does NOT accumulate on cash sales (only on credit).
  // Odd, but consistent across snapshots; replicated as observed.
  FSession.Execute(
    'INSERT INTO hiprocli (ANIOH, MESH, TIPREG, CODIGO, CONTADO, COBPAG) ' +
    'VALUES (:y, :m, 1, :code, :amt, :amt) ' +
    'ON DUPLICATE KEY UPDATE CONTADO = CONTADO + :amt2, ' +
    '  COBPAG = COBPAG + :amt3',
    [AYear, AMonth, ACustomerCode, ANetAmount, ANetAmount, ANetAmount]);

  FSession.Execute(
    'INSERT INTO hiresume (ANIOH, MESH, TIPREG, CONTADO, COBPAG) ' +
    'VALUES (:y, :m, 1, :amt, :amt) ' +
    'ON DUPLICATE KEY UPDATE CONTADO = CONTADO + :amt2, ' +
    '  COBPAG = COBPAG + :amt3',
    [AYear, AMonth, ANetAmount, ANetAmount, ANetAmount]);
end;

procedure TInvoiceService.UpdateCustomerBalance(ACustomer: TParty;
  ADate: TClarionDate; const ATotal: TAmount);
var
  DateText: string;
begin
  DateText := ClarionToStr(ADate);
  // On cash sales both MONTODEB and MONTOCRE increase by the total.
  FSession.Execute(
    'UPDATE cfprocli SET FECHA1 = :d1, FECHA2 = :d2, FECHA1S = :s1, ' +
    '  FECHA2S = :s2, MONTODEB = MONTODEB + :amt, ' +
    '  MONTOCRE = MONTOCRE + :amt2 ' +
    'WHERE TIPREG = 1 AND CODIGO = :code',
    [ADate, ADate, DateText, DateText, ATotal, ATotal, ACustomer.CODIGO]);
end;

function TInvoiceService.LoadCustomer(const ACode: string): TParty;
begin
  // TODO: load through the ORM, ALWAYS filtering TIPREG = 1. Without that
  // filter an invoice could be issued against a supplier sharing the code.
  raise ENotImplemented.Create('LoadCustomer: ORM binding pending.');
end;

function TInvoiceService.LoadProduct(const ACode: string): TProduct;
begin
  // TODO: load through the ORM. Check ACTIVO and, if USASERIAL = 1, require
  // serial numbers.
  raise ENotImplemented.Create('LoadProduct: ORM binding pending.');
end;

end.
