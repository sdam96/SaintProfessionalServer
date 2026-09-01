unit dto.invoice;

interface

uses
  System.Generics.Collections, models.types;

type
  TPaymentTerms = (ptCash, ptCredit);

  TInvoiceLineRequest = class
  public
    ProductCode: string;         // ivproser.CODPRO
    Quantity: TQuantity;
    UnitPrice: TAmount;          // net of tax; 0 = take from the price list
    DiscountRate: TRate;
    ServerCode: string;          // cfservid.CODSER; optional
    WarehouseCode: string;       // defaults to '01'
  end;

  TInvoiceRequest = class
  private
    FLines: TObjectList<TInvoiceLineRequest>;
  public
    CustomerCode: string;        // cfprocli.CODIGO where TIPREG = 1
    SalespersonCode: string;
    PaymentTerms: TPaymentTerms;
    CreditDays: Integer;
    UserCode: string;
    CashRegisterCode: string;
    PaidInForeignCurrency: Boolean;   // triggers IGTF calculation
    constructor Create;
    destructor Destroy; override;
    function AddLine: TInvoiceLineRequest;
    property Lines: TObjectList<TInvoiceLineRequest> read FLines;
  end;

  TInvoiceResult = record
    InvoiceControl: string;
    PaymentControl: string;
    CashControl: string;
    InvoiceNumber: string;
    GrossAmount: TAmount;
    TaxAmount: TAmount;
    IGTFAmount: TAmount;
    TotalAmount: TAmount;
    IssueDate: TClarionDate;
  end;

implementation

constructor TInvoiceRequest.Create;
begin
  inherited;
  FLines := TObjectList<TInvoiceLineRequest>.Create(True);
  SalespersonCode := '01';
  UserCode := 'DEMO';
  CashRegisterCode := 'DEMO';
  PaymentTerms := ptCash;
end;

destructor TInvoiceRequest.Destroy;
begin
  FLines.Free;
  inherited;
end;

function TInvoiceRequest.AddLine: TInvoiceLineRequest;
begin
  Result := TInvoiceLineRequest.Create;
  Result.WarehouseCode := '01';
  FLines.Add(Result);
end;

end.
