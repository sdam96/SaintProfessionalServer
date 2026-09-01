unit models.igtfrecords;

interface

uses
  attributes, models.types;

type
  // Patch table (camelCase, unlike the rest of the schema).
  // porcentajeImpuestoIGTF is TEXT, not numeric. Observed value: '3'.
  TIGTFRecord = class
  public
    [PrimaryKey][NotNull][Size(19)] dcheaderCONTROL: string;
    [Decimal(17, 2)] baseImponibleGeneral: TAmount;
    [Size(10)] porcentajeImpuestoIGTF: string;
    [Size(30)] DESCRIPCION: string;                 // 'Dolar'
    [Decimal(17, 2)] IGTFEFECTIVOMONEDALOCAL: TAmount;
    [Decimal(17, 2)] IGTFCHEQUEMONEDALOCAL: TAmount;
    [Decimal(17, 2)] IGTFTARJETAMONEDALOCAL: TAmount;
    [Decimal(17, 2)] IGTFOTROMETODOMONEDALOCAL: TAmount;
  end;

implementation

end.
