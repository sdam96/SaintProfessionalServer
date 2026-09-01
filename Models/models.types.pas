unit models.types;

interface

type
  // decimal(17,2) allows up to 999,999,999,999,999.99
  // Currency     allows up to 922,337,203,685,477.58
  TAmount      = Currency;
  TQuantity    = Currency;   // decimal(17,3)
  TRate        = Currency;   // decimal(7,2) / decimal(5,2) / decimal(13,2)
  TClarionDate = Integer;    // int used as a Clarion date. Epoch: 1800-12-28.
  TFlag        = ShortInt;   // MySQL tinyint is SIGNED
  TClarionTime = Integer;    // hundredths of a second since midnight

const
  MAX_AMOUNT: TAmount = 922337203685477.58;

  CLARION_EPOCH_YEAR  = 1800;
  CLARION_EPOCH_MONTH = 12;
  CLARION_EPOCH_DAY   = 28;

function IsAmountInRange(const AValue: Double): Boolean;
function ClarionToDate(ADate: TClarionDate): TDate;
function DateToClarion(const ADate: TDate): TClarionDate;
function ClarionToStr(ADate: TClarionDate): string;
function CurrentClarionTime: TClarionTime;

implementation

uses
  System.SysUtils, System.DateUtils;

var
  GEpoch: TDate;

function IsAmountInRange(const AValue: Double): Boolean;
begin
  Result := Abs(AValue) <= MAX_AMOUNT;
end;

function ClarionToDate(ADate: TClarionDate): TDate;
begin
  Result := GEpoch + ADate;
end;

function DateToClarion(const ADate: TDate): TClarionDate;
begin
  Result := Trunc(ADate) - Trunc(GEpoch);
end;

function ClarionToStr(ADate: TClarionDate): string;
begin
  if ADate = 0 then
    Exit('');
  Result := FormatDateTime('yyyymmdd', ClarionToDate(ADate));
end;

function CurrentClarionTime: TClarionTime;
var
  H, M, S, MS: Word;
begin
  DecodeTime(Now, H, M, S, MS);
  Result := (H * 360000) + (M * 6000) + (S * 100) + (MS div 10);
end;

initialization
  GEpoch := EncodeDate(CLARION_EPOCH_YEAR, CLARION_EPOCH_MONTH, CLARION_EPOCH_DAY);

end.
