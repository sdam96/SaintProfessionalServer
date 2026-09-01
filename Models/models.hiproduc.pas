unit models.hiproduc;

interface

uses
  attributes, models.types;

type
  // Monthly product history. Cumulative: values are ADDED, not replaced.
  // Logical key: ANIOH + MESH + CODPRO.
  TProductHistory = class
  public
    [PrimaryKey][NotNull] ANIOH: Integer;
    [PrimaryKey][NotNull] MESH: Integer;
    [PrimaryKey][NotNull][Size(15)] CODPRO: string;

    [Decimal(17, 3)] CANINVINICIAL: TQuantity;
    [Decimal(17, 2)] MONTOINVINICIAL: TAmount;
    [Decimal(17, 3)] CANCOMPRA: TQuantity;
    [Decimal(17, 2)] MONTOCOMPRA: TAmount;
    [Decimal(17, 3)] CANVENTA: TQuantity;
    [Decimal(17, 2)] MONTOVENTA: TAmount;
    [Decimal(17, 3)] CANDEVCOMPRA: TQuantity;
    [Decimal(17, 2)] MONTODEVCOMPRA: TAmount;
    [Decimal(17, 3)] CANDEVVENTA: TQuantity;
    [Decimal(17, 2)] MONTODEVVENTA: TAmount;
    [Decimal(17, 3)] CANCARGOS: TQuantity;
    [Decimal(17, 2)] MONTOCARGOS: TAmount;
    [Decimal(17, 3)] CANDESCARGOS: TQuantity;
    [Decimal(17, 2)] MONTODESCARGOS: TAmount;
    [Decimal(17, 3)] CANAJUSTESP: TQuantity;
    [Decimal(17, 2)] MONTOAJUSTESP: TAmount;
    [Decimal(17, 3)] CANAJUSTESN: TQuantity;
    [Decimal(17, 2)] MONTOAJUSTESN: TAmount;

    // ---- Delivery-note counterparts ----
    [Decimal(17, 3)] CANNECOMPRA: TQuantity;
    [Decimal(17, 2)] MONTONECOMPRA: TAmount;
    [Decimal(17, 3)] CANNEDEVCOMPRA: TQuantity;
    [Decimal(17, 2)] MONTONEDEVCOMPRA: TAmount;
    [Decimal(17, 3)] CANNEVENTA: TQuantity;
    [Decimal(17, 2)] MONTONEVENTA: TAmount;
    [Decimal(17, 3)] CANNEDEVVENTA: TQuantity;
    [Decimal(17, 2)] MONTONEDEVVENTA: TAmount;
  end;

implementation

end.
