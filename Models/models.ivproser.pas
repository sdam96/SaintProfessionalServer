unit models.ivproser;

interface

uses
  attributes, models.types;

type
  // Products AND services, discriminated by TIPINV / TIPPRO.
  // EXISTENCIA..EXISTENCIA5 is POSITIONAL per warehouse (01..05).
  // CANVEN holds the quantity of the LAST sale, not a running total.
  TProduct = class
  public
    [PrimaryKey][NotNull][Size(15)] CODPRO: string;
    [Indexed][Size(15)] CODIGO: string;          // level-1 category
    [Size(60)] DESCRIP1: string;
    [Size(60)] DESCRIP2: string;
    [Size(60)] DESCRIP3: string;
    [Size(10)] UNIDAD: string;

    [Decimal(17, 2)] COSTOACT: TAmount;
    [Decimal(17, 2)] COSTOPRO: TAmount;
    [Decimal(17, 2)] PRECIO1: TAmount;
    [Decimal(7, 2)]  UTILPRECIO1: TRate;
    [Decimal(17, 2)] PRECIO2: TAmount;
    [Decimal(7, 2)]  UTILPRECIO2: TRate;
    [Decimal(17, 2)] PRECIO3: TAmount;
    [Decimal(7, 2)]  UTILPRECIO3: TRate;

    [Decimal(17, 3)] EXISTENCIA: TQuantity;      // warehouse 01
    [Decimal(17, 3)] EXISTENCIAANT: TQuantity;
    EXENTO: TFlag;
    [Decimal(7, 2)] IMPPOR: TRate;
    MOVMES: TFlag;
    TIPINV: TFlag;
    TIPPRO: TFlag;
    [Decimal(17, 2)] COSTOANT: TAmount;
    [Decimal(17, 3)] EXIMINIMA: TQuantity;
    [Decimal(17, 3)] EXIMAXIMA: TQuantity;
    [Decimal(17, 2)] COSTOEXT: TAmount;
    [Decimal(17, 2)] CAMBIOEXT: TAmount;
    [Indexed][Size(15)] CODREF: string;
    [Decimal(17, 2)] COSTOPOR: TAmount;
    [Size(25)] CODPROV: string;
    MARCA: TFlag;

    [Decimal(17, 3)] EXISTENCIA2: TQuantity;     // warehouse 02
    [Decimal(17, 3)] EXISTENCIA3: TQuantity;
    [Decimal(17, 3)] EXISTENCIA4: TQuantity;
    [Decimal(17, 3)] EXISTENCIA5: TQuantity;

    USASERIAL: TFlag;
    [Decimal(17, 3)] CANPEDIDA: TQuantity;
    [Decimal(17, 3)] CANODC: TQuantity;
    [Decimal(17, 3)] CANRESERVADA: TQuantity;
    PROCOMPUESTO: TFlag;
    [Size(100)] FOTO: string;

    USASERVIDOR: TFlag;
    [Decimal(5, 2)]  PORCOMISION: TRate;
    [Decimal(17, 2)] MONTOCOMISION: TAmount;

    [Size(15)] CODCAT2: string;
    [Size(15)] CODCAT3: string;
    [Size(15)] CODCAT4: string;
    [Size(15)] CODCAT5: string;

    FECCOM: TClarionDate;
    [Decimal(17, 3)] CANCOM: TQuantity;
    FECVEN: TClarionDate;
    [Decimal(17, 3)] CANVEN: TQuantity;

    [Decimal(17, 3)] CONTEO1: TQuantity;
    [Decimal(17, 3)] CONTEO2: TQuantity;
    [Decimal(17, 3)] CONTEO3: TQuantity;
    [Decimal(17, 3)] CONTEO4: TQuantity;
    [Decimal(17, 3)] CONTEO5: TQuantity;

    [Size(20)] UBICACION1: string;
    [Size(20)] UBICACION2: string;
    [Size(20)] UBICACION3: string;
    [Size(20)] UBICACION4: string;
    [Size(20)] UBICACION5: string;

    [Decimal(7, 2)] IMPPOR2: TRate;
    [Decimal(7, 2)] IMPPOR3: TRate;
    [Decimal(7, 2)] IMPPOR4: TRate;

    [Size(20)] CUENTAVENTACON: string;
    [Size(20)] CUENTAVENTACRE: string;
    [Size(20)] CUENTACOMPRACON: string;
    [Size(20)] CUENTACOMPRACRE: string;
    [Size(20)] CCVENTA: string;
    [Size(20)] CCCOMPRA: string;

    [Decimal(17, 3)] CANTEMPAQUE: TQuantity;
    [Size(19)] GRUPOINV: string;

    [Decimal(17, 2)] MONTOCOM1: TAmount;
    [Decimal(17, 2)] MONTOCOM2: TAmount;
    [Decimal(17, 2)] MONTOCOM3: TAmount;
    ACTIVARCOMXMONTO: TFlag;
    [Decimal(17, 2)] COSTOPROANT: TAmount;

    [Size(25)] CODIGOPROV: string;
    GARANTIA: Integer;
    [Size(19)] LINEAINV: string;
    [Size(19)] CODFABRICANTE: string;

    PVPPORESCALA: TFlag;
    [Decimal(17, 3)] DESCALA1: TQuantity;
    [Decimal(17, 3)] HESCALA1: TQuantity;
    [Decimal(17, 3)] DESCALA2: TQuantity;
    [Decimal(17, 3)] HESCALA2: TQuantity;
    [Decimal(17, 3)] DESCALA3: TQuantity;
    [Decimal(17, 3)] HESCALA3: TQuantity;

    [Size(25)] CODIGOCLIEN: string;
    [Size(30)] NUMULTIMCOMPRA: string;
    [Size(30)] NUMULTIMVENTA: string;
    ESCOMISPORCENT: TFlag;
    ACTIVO: TFlag;
    LEER_CAN_PRE: TFlag;
    [Size(20)] TIPOMEDIDA: string;               // 'Cantidad'
    CAN_DECIMALES_MEDIDA: TFlag;
    INTEGRADO: TFlag;

    // ---- CR localisation patches ----
    [Size(20)] CABYS: string;
    [Size(20)] Partida_arancelaria: string;
    Es_otro_cargo: TFlag;
    [Size(10)] Tipo_otro_cargo: string;
    [Size(25)] Cedula_tercero: string;
    [Size(100)] Nombre_tercero: string;
    [Size(10)] Unidad_medidaCR: string;

    [Size(2)] CODIMPUESTO1: string;
    [Size(2)] CODIMPUESTO2: string;
    [Size(2)] CODIMPUESTO3: string;
  end;

implementation

end.
