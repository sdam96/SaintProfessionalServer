unit models.ivserial;

interface

uses
  attributes, models.types;

type
  // Available serial numbers. Selling a product with USASERIAL = 1 DELETES
  // the row for the serial handed out, and Saint writes nothing to dcserial,
  // so there is no record of which serial left on which document.
  TSerial = class
  public
    [PrimaryKey][NotNull][Size(15)] CODIGO: string;    // warehouse
    [PrimaryKey][NotNull][Size(15)] CODPRO: string;
    [PrimaryKey][NotNull][Size(30)] SERIAL: string;
    MARCA: TFlag;
  end;

implementation

end.
