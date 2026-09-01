unit services.totals;

interface

uses
  System.Math, models.types;

type
  TDocumentTotals = record
    Gross: TAmount;       // sum of line TOTAL, net of tax
    Discount: TAmount;
    Subtotal: TAmount;
    Tax: TAmount;
    IGTF: TAmount;
    Total: TAmount;       // MONTOTOT: includes tax and IGTF
    Cost: TAmount;        // sum of line MONTOCOS
  end;

  // Formula verified against invoice 000011 (snapshot 02):
  //   Gross 2142.86 + Tax 342.86 = 2485.72 ; x 1.03 = 2560.29 = MONTOTOT
  //
  // Invoice 000012 (snapshot 03) does NOT match:
  //   Gross 4285.72 + Tax 685.72 = 4971.44 ; observed MONTOTOT = 10071.45
  //   Delta 5100.01 ~ 6 x 850 (FACTORCAMBIO), and its igtfrecords row is
  //   all zeros. UNRESOLVED.
  TTotalsCalculator = class
  public
    class function Round2(const AValue: TAmount): TAmount; static; inline;
    class function CalculateIGTF(const ATaxedBase: TAmount;
      ARate: TRate; AApplies: Boolean): TAmount; static;
  end;

const
  DEFAULT_IGTF_RATE: TRate = 3.00;

implementation

class function TTotalsCalculator.Round2(const AValue: TAmount): TAmount;
begin
  Result := RoundTo(AValue, -2);
end;

class function TTotalsCalculator.CalculateIGTF(const ATaxedBase: TAmount;
  ARate: TRate; AApplies: Boolean): TAmount;
begin
  if not AApplies then
    Exit(0);
  Result := Round2(ATaxedBase * ARate / 100);
end;

end.
