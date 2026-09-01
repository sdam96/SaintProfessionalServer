unit models.movprod;

interface

uses
  attributes, models.types;

type
  // Last movement per product. One row per CODPRO, updated in place.
  // If the row does not exist it must be inserted (see product 010002,
  // snapshot 10).
  TProductMovement = class
  public
    [PrimaryKey][NotNull][Size(15)] CODPRO: string;
    TIPINV: TFlag;

    // ---- Last purchase ----
    FECULTCOMP: TClarionDate;
    [Size(30)] NUMULTCOMPRA: string;
    [Decimal(17, 3)] CANTULTCOMP: TQuantity;
    [Size(25)] IDPROVEE: string;
    [Size(100)] NOMPROVEE: string;
    [Size(40)] NOMRESPONS: string;

    // ---- Last sale ----
    FECULTVENT: TClarionDate;
    [Size(30)] NUMULTVENT: string;
    [Decimal(17, 3)] CANTULTVENT: TQuantity;
    [Size(25)] IDCLIEN: string;
    [Size(100)] NOMCLIENTE: string;
    [Size(40)] NOMVENDEDOR: string;    // 'Ventas Directas' when CODVEN = '01'
  end;

implementation

end.
