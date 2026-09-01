unit models.dcdetall;

interface

uses
  attributes, models.types;

type
  // Logical key: CONTROL + FECHORA (KeyDet01).
  // WARNING: KeyDet05 is UNIQUE (FECHORA, CODPRO) across the WHOLE table,
  // not per document. That is the constraint that fails under concurrency.
  TDCDetail = class
  public
    [PrimaryKey][NotNull][Size(19)] CONTROL: string;

    // ---- Product and quantities ----
    [Indexed][Size(15)] CODPRO: string;
    [Decimal(17, 3)] CANTIDAD: TQuantity;
    [Decimal(17, 2)] PRECOSUNI: TAmount;
    [Decimal(17, 2)] COSTOACT: TAmount;
    [Decimal(17, 2)] COSTOPRO: TAmount;
    [Decimal(7, 2)]  IMPPOR: TRate;
    [Decimal(17, 2)] MONTOIMP: TAmount;
    [Decimal(17, 2)] TOTAL: TAmount;
    [Size(60)] DESCRIP1: string;

    // ---- Document ----
    [Indexed][Size(10)] TIPTRAN: string;
    [Indexed] FECEMIS: TClarionDate;
    [Size(10)] FECEMISS: string;

    // ---- Sale prices and margins ----
    [Decimal(17, 2)] PRECIO1: TAmount;
    [Decimal(7, 2)]  UTILPRECIO1: TRate;
    [Decimal(17, 2)] PRECIO2: TAmount;
    [Decimal(7, 2)]  UTILPRECIO2: TRate;
    [Decimal(17, 2)] PRECIO3: TAmount;
    [Decimal(7, 2)]  UTILPRECIO3: TRate;
    [Decimal(17, 2)] MONTOCOS: TAmount;
    TIPINV: TFlag;

    // ---- Import cost structure (set 1) ----
    [Decimal(7, 2)]  FACCAM1: TRate;
    [Decimal(17, 2)] VALFOB1: TAmount;
    [Decimal(17, 2)] COSTOFLE1: TAmount;
    [Decimal(17, 2)] COSTOSEG1: TAmount;
    [Decimal(17, 2)] VALORCIF1: TAmount;
    [Decimal(17, 2)] COSTOARA1: TAmount;
    [Decimal(17, 2)] COSTONAC1: TAmount;
    [Decimal(17, 2)] COSTOADU1: TAmount;
    [Decimal(17, 2)] PAGOCOM1: TAmount;
    [Decimal(17, 2)] GASTOADU1: TAmount;
    [Decimal(17, 2)] OTROGAS1: TAmount;
    [Decimal(17, 2)] COSTOFIN1: TAmount;
    [Size(30)] NUMPLANILLA: string;

    // ---- Import cost structure (set 2) ----
    [Decimal(7, 2)]  FACCAM2: TRate;
    [Decimal(17, 2)] VALFOB2: TAmount;
    [Decimal(17, 2)] COSTOFLE2: TAmount;
    [Decimal(17, 2)] COSTOSEG2: TAmount;
    [Decimal(17, 2)] VALORCIF2: TAmount;
    [Decimal(17, 2)] COSTOARA2: TAmount;
    [Decimal(17, 2)] COSTONAC2: TAmount;
    [Decimal(17, 2)] COSTOADU2: TAmount;
    [Decimal(17, 2)] PAGOCOM2: TAmount;
    [Decimal(17, 2)] GASTOADU2: TAmount;
    [Decimal(17, 2)] OTROGAS2: TAmount;
    [Decimal(17, 2)] COSTOFIN2: TAmount;

    // ---- Special prices ----
    [Decimal(17, 2)] PRECIOE1: TAmount;
    [Decimal(17, 2)] PRECIOE2: TAmount;
    [Decimal(17, 2)] PRECIOE3: TAmount;

    // ---- Line classification ----
    TIPODET: TFlag;
    TIPPRO: TFlag;
    TIPREG: TFlag;
    [Size(25)] CODIGO: string;

    // ---- Commissions ----
    [Decimal(17, 2)] COMISVEN: TAmount;
    [Decimal(17, 2)] COMISCOB: TAmount;
    COMISTIP: TFlag;

    // ---- Warehouses ----
    [Size(3)] CODALREC: string;
    [Size(3)] CODALENT: string;

    // ---- PHYSICAL position of FECHORA (column 59) ----
    // char(20) in the schema, but Saint always writes 19 characters.
    // Write exactly 19, no padding.
    [PrimaryKey][NotNull][FixedLength][Size(20)] FECHORA: string;

    // ---- Line-level discounts ----
    [Decimal(7, 2)]  PORDES: TRate;
    [Decimal(17, 2)] MONTODESCUENTO: TAmount;

    [Size(19)] FHIMPORTAR: string;
    COMPONENTE: TFlag;
    [Size(19)] FHPRODBASE: string;

    // ---- Server (waiter, technician), not a service code ----
    [Indexed][Size(15)] CODSER: string;
    [Decimal(5, 2)]  PORCOMISION: TRate;
    [Decimal(17, 2)] MONTOCOMISION: TAmount;

    // ---- Return ----
    DEVUELTA: TFlag;
    [Decimal(17, 3)] CANTIDADDEV: TQuantity;

    ORIGEN: TFlag;
    PRECIO: TFlag;                    // tinyint: price list applied
    [Decimal(7, 2)] FACTORCAMBIO: TRate;
    [Size(15)] SIGNOMONEDA: string;

    // ---- Additional taxes ----
    [Decimal(7, 2)]  IMPPOR2: TRate;
    [Decimal(17, 2)] MONTOIMP2: TAmount;
    [Decimal(7, 2)]  IMPPOR3: TRate;
    [Decimal(17, 2)] MONTOIMP3: TAmount;

    PROCESADO: TFlag;
    [Size(15)] CODIGODEP: string;
    [Size(19)] GRUPOINV: string;
    CONLINEA: TFlag;

    // ---- Telephony / contract ----
    [Size(20)] NUMCONTRATO: string;
    [Size(20)] NUMTELEFONO: string;
    [Size(15)] CODVEN: string;

    // ---- Card withholding ----
    [Decimal(7, 2)]  PORRETTAR: TRate;
    [Decimal(17, 2)] MONTORETTAR: TAmount;

    MESVENC: Integer;
    FECHAVENCE: TClarionDate;

    [Size(19)] LINEAOINV: string;
    [Size(19)] CODFABRICANTE: string;
    [Indexed][Size(60)] CENTROCOSTO: string;
    [Size(20)] NROSNEDET: string;
    [Size(40)] NOMBRE: string;

    // ---- Detail-level commission ----
    [Decimal(13, 2)] PORCOMISDETAIL: TRate;
    [Decimal(13, 2)] MTOCOMISDETAIL: TAmount;

    // ---- Prorated global discount and surcharge ----
    [Decimal(7, 2)]  PORDESGLO: TRate;
    [Decimal(17, 2)] MONTODESCUENTOGLO: TAmount;
    [Decimal(17, 3)] CANTIDADFAC: TQuantity;
    [Decimal(7, 2)]  PORREC: TRate;
    [Decimal(17, 2)] MONTORECARGA: TAmount;
    [Decimal(7, 2)]  PORRECARGOGLO: TRate;
    [Decimal(17, 2)] MONTORECARGOGLO: TAmount;

    // ---- Tax codes ----
    [Size(2)] CODIMPUESTO1: string;
    [Size(2)] CODIMPUESTO2: string;
    [Size(2)] CODIMPUESTO3: string;
    [DefaultValue('0')] IMPUESTOVALORAGREGADO: TFlag;
  end;

implementation

end.
