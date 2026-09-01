================================================================
DOCUMENTACIÓN BASE DE DATOS - SAINT (CLARION 6 / MySQL)
Objetivo: desarrollo de API de VENTAS
Fecha de levantamiento: 2026-08-28
Estado: preliminar - verificar puntos marcados [PENDIENTE]
================================================================


1. ENTORNO
----------------------------------------------------------------
Aplicación origen : Saint (desarrollada en Clarion 6)
Motor             : MySQL 8.x
Conexión de la app: ODBC (MySQL ODBC 5.3 ANSI Driver)
Servidor          : localhost

1.1 COLACIONES - IMPORTANTE
Las tablas heredadas usan utf8mb4_unicode_ci.
El servidor MySQL 8 usa por defecto utf8mb4_0900_ai_ci.
Al comparar columnas de texto contra parámetros o variables se
produce:
    Error 1267. Illegal mix of collations

SOLUCIÓN: fijar la colación al abrir cada conexión del API:
    SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

Alternativa puntual en una consulta:
    SET @c = _utf8mb4'...' COLLATE utf8mb4_unicode_ci;

[PENDIENTE] Confirmar colación y ENGINE de todas las tablas dc*:
    SELECT TABLE_NAME, TABLE_COLLATION, ENGINE
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME LIKE 'dc%';

1.2 MOTOR DE ALMACENAMIENTO
InnoDB


2. EL CAMPO "CONTROL" - IDENTIFICADOR INTERNO DE DOCUMENTO
----------------------------------------------------------------
Cadena numérica de 19 caracteres. No es autoincremental de MySQL:
lo genera la aplicación combinando fecha, hora y un consecutivo.

2.1 ESTRUCTURA
  Posición  Largo  Contenido
  --------  -----  ---------------------------------------------
  1  - 5      5    Fecha estándar Clarion (días desde 1800-12-28)
  6  - 12     7    Hora estándar Clarion (centésimas de segundo
                   desde medianoche, base 1 -- no base 0)
  13 - 17     5    Consecutivo global (CONTADORCONTROL)
  18 - 19     2    Constante observada: '01'
                   [PENDIENTE] Confirmar si es terminal, estación
                   o sucursal. Revisar registros creados desde
                   otro equipo. Ver también NROESTABLECIMIENTO
                   en cfparame.

Origen en Clarion 6: funciones TODAY() y CLOCK().

2.2 DECODIFICACIÓN (SQL)
    SELECT
      CONTROL,
      DATE_ADD('1800-12-28',
        INTERVAL CAST(SUBSTRING(CONTROL,1,5) AS UNSIGNED) DAY)   AS fecha,
      SEC_TO_TIME((CAST(SUBSTRING(CONTROL,6,7) AS UNSIGNED)-1)/100) AS hora,
      CAST(SUBSTRING(CONTROL,13,5) AS UNSIGNED)                  AS consecutivo,
      SUBSTRING(CONTROL,18,2)                                    AS terminal
    FROM dcheader
    ORDER BY CONTROL;

2.3 GENERACIÓN (SQL)
    SELECT CONCAT(
      LPAD(DATEDIFF(NOW(), '1800-12-28'), 5, '0'),
      LPAD(FLOOR(TIME_TO_SEC(CURTIME()) * 100) + 1, 7, '0'),
      LPAD(:consecutivo, 5, '0'),
      '01'
    );

2.4 MUESTRA VERIFICADA (21 cabeceras)
  CONTROL              Fecha       Hora        Consec.  Detalle
  -------------------  ----------  ----------  -------  -------
  8236433263670001401  30/06/2026  09:14:23.66     14   SI
  8236433292900002001  30/06/2026  09:14:52.89     20   no
  8236433706880002601  30/06/2026  09:21:46.87     26   SI
  8236433737030003201  30/06/2026  09:22:17.02     32   no
  8238450581600003801  20/07/2026  14:03:01.59     38   SI
  8238450615240004401  20/07/2026  14:03:35.23     44   no
  8238637116890005001  22/07/2026  10:18:36.88     50   SI
  8238637157770005601  22/07/2026  10:19:17.76     56   no
  8242335972240006001  28/08/2026  09:59:32.23     60   SI
  8242336001070006701  28/08/2026  10:00:01.06     67   SI
  8242336095320007301  28/08/2026  10:01:35.31     73   no
  8242336898740008201  28/08/2026  10:14:58.73     82   SI
  8242336926350008801  28/08/2026  10:15:26.34     88   no
  8242336927780009101  28/08/2026  10:15:27.77     91   SI
  8242337213750009701  28/08/2026  10:20:13.74     97   no
  8242337215820010001  28/08/2026  10:20:15.81    100   SI
  8242337523450010601  28/08/2026  10:25:23.44    106   no
  8242337525440010901  28/08/2026  10:25:25.43    109   SI
  8242337756260011601  28/08/2026  10:29:16.25    116   no
  8242338450700012101  28/08/2026  10:30:45.06    121   SI
  8242338484120012801  28/08/2026  10:30:48.40    128   no

[PENDIENTE] Validar la época contra una factura de fecha/hora
conocida. Si aparece desplazada 1 o 4 días, ajustar la fecha base
(algunas implementaciones usan 1801-01-01).

2.5 LÍMITE DEL CONSECUTIVO
El consecutivo tiene 5 dígitos: tope 99999.
Al ritmo observado (~6 por operación de venta) se agota alrededor
de 16.000 documentos.
[PENDIENTE] Averiguar qué hace Saint al llegar al tope. Si
reinicia, CONTROL no es único a perpetuidad y no sirve como
clave primaria eterna.


3. EL CONTADOR: cfparame.CONTADORCONTROL
----------------------------------------------------------------
Tabla cfparame = parámetros de la empresa, registro único.
Campo CONTADORCONTROL = consecutivo global.
Valor observado al momento del levantamiento: 130
(coherente: el último CONTROL de la muestra tenía consecutivo 128)

Mecanismo: al guardar un documento la aplicación lee el contador,
lo incrementa y compone el CONTROL.

3.1 POR QUÉ SALTA DE 6 EN 6
El contador lo consumen TODAS las escrituras de la aplicación, no
solo las facturas. Saltos observados: +3, +4, +5, +6, +7, +9.
Los saltos menores corresponden a operaciones más juntas en el
tiempo (menos escrituras intermedias).

HIPÓTESIS DESCARTADA: no corresponde a las 6 tablas dc*.
Verificado sobre CONTROL 8242336898740008201:
    dcheader  1
    dcdetall  1
    dcauxili  0
    dcamplia  0
    dcobserv  0
    dcserial  0
    TOTAL     2   (el salto fue de 6)

[PENDIENTE] Identificar las escrituras restantes. Candidatas:
inventario, cuentas por cobrar, caja, auditoría.
Método recomendado: traza ODBC acotada a UN solo guardado
(ver sección 8).

3.2 OTROS CONTADORES EN cfparame
    CONTADORCAJA
    CONTADORSER
    CONTCIERREDIA
    CONTROL          <- la tabla cfparame tiene su propia col. CONTROL
[PENDIENTE] Determinar el uso de cada uno.

3.3 CONCURRENCIA - ADVERTENCIA
Saint es una aplicación de escritorio Clarion que no espera
competencia por este registro. Si el API y un usuario guardan a la
vez, ambos leen el mismo valor y se generan CONTROL duplicados.

Si se decide compartir el contador (requiere InnoDB):
    START TRANSACTION;
    SELECT CONTADORCONTROL FROM cfparame FOR UPDATE;
    UPDATE cfparame SET CONTADORCONTROL = CONTADORCONTROL + 1;
    -- componer CONTROL e insertar
    COMMIT;

RECOMENDACIÓN ALTERNATIVA (más segura):
No tocar CONTADORCONTROL. Asignar al API un código propio en las
posiciones 18-19 (ej. '90') y llevar contador independiente. Así
nunca hay colisión con los CONTROL generados por Saint.
Requisito previo: confirmar que las posiciones 18-19 son
efectivamente terminal/estación (ver 2.1).


4. FAMILIA DE TABLAS "dc*" (DOCUMENTOS)
----------------------------------------------------------------
  dcheader   Cabecera de documento
  dcdetall   Renglones / detalle
  dcauxili   [PENDIENTE] propósito
  dcamplia   [PENDIENTE] propósito
  dcobserv   [PENDIENTE] propósito - probable observaciones
  dcserial   [PENDIENTE] propósito - probable seriales

Todas se relacionan por la columna CONTROL.
dcdetall.CONTROL es clave foránea hacia dcheader.CONTROL
(no genera CONTROL propio: verificado, los 11 CONTROL de dcdetall
existen todos en dcheader).

[PENDIENTE] Confirmar nombres exactos con:  SHOW TABLES LIKE 'dc%';


5. dcheader - TABLA POLIMÓRFICA
----------------------------------------------------------------
dcheader NO guarda solo facturas. Guarda todos los tipos de
documento mezclados. El discriminador es TIPTRAN.

IMPORTANTE: el campo TIPODOC NO se usa como discriminador.
Verificado: TIPODOC = 0 en los 21 registros.

5.1 COLUMNAS IDENTIFICADAS
  CONTROL      Identificador único del documento (ver sección 2)
  CONTROLDOC   Enlace al documento PADRE. En la factura apunta a
               sí misma; en los documentos derivados (pago,
               devolución) apunta al CONTROL de la factura.
               ES LA CLAVE PARA RECONSTRUIR LA OPERACIÓN COMPLETA.
  TIPTRAN      Tipo de transacción (ver 5.3)
  TIPREG       Tipo de registro. Valor observado: 1
  CODIGO       Código de cliente. Ej: V24403273 (cédula/RIF)
  NOMBRE       Nombre del cliente
  NUMREF       Número de referencia. En FAC lleva el nro. de doc.
  NUMDOC       Número de documento. En FAC va vacío; en PAGxFAC
               lleva el nro. con sufijo 'R' (recibo)
  DESCRIP1     Descripción. Ej: "Factura 000006"
  DESCRIP2     Descripción secundaria. Ej: "Por 2,485.72"
  MONTOPAGF    Monto. En FAC = total; en PAGxFAC = 0.00
               [PENDIENTE] Confirmar semántica exacta con una
               factura a crédito o con pago parcial.

[PENDIENTE] Volcar estructura completa:  DESCRIBE dcheader;

5.2 EJEMPLO REAL - PAR FACTURA/PAGO
control,tipreg,codigo,tiptran,numref,numdoc,descrip1,descrip2,nombre,controldoc,montopagf
8242336898740008201,1,V24403273,FAC,000006,,"Factura 000006",,"SAMUEL ACOSTA",8242336898740008201,2485.72
8242336926350008801,1,V24403273,PAGxFAC,000006,000006R,"Pago factura 000006","Por 2,485.72","SAMUEL ACOSTA",8242336898740008201,0.00

5.3 VALORES DE TIPTRAN
  CAR       Cargo de inventario
  DES       Descargo de inventario
  FAC       Factura
  PAGxFAC   Pago de factura
  DEVxFAC   Devolución de factura
  PRE       Cotización / Presupuesto
  PEDxCLI   Pedido de cliente
  N/E       Nota de entrega
  DEVxNE    Devolución nota de entrega (SOLO EN dcdetall)

5.4 AGRUPACIÓN POR COMPORTAMIENTO
  Grupo          Tipos              Inventario   CxC
  -------------  -----------------  -----------  ---------
  Ajuste         CAR, DES           Si           No
  Venta          FAC, N/E           Si           Si
  Reversa        DEVxFAC, DEVxNE    Si (entra)   Si (resta)
  Cobro          PAGxFAC            No           Si
  No vinculante  PRE, PEDxCLI       No           No

Nota: N/E mueve mercancía pero es previa a la factura. Si el
negocio la usa, hay documentos que descargan stock sin facturar.

[PENDIENTE] Inventario real de tipos en uso:
    SELECT TIPTRAN, COUNT(*) FROM dcheader
    GROUP BY TIPTRAN ORDER BY 2 DESC;


6. dcdetall - TAMBIÉN POLIMÓRFICA
----------------------------------------------------------------
dcdetall tiene su propio campo TIPTRAN y NO siempre coincide con
el de la cabecera (evidencia: DEVxNE existe solo en dcdetall).

REGLA: filtrar siempre por el TIPTRAN del detalle, nunca asumir
que hereda el de dcheader.

    SELECT * FROM dcdetall WHERE CONTROL = ? AND TIPTRAN = 'FAC';

[PENDIENTE] Mapear el cruce real:
    SELECT h.TIPTRAN AS cabecera, d.TIPTRAN AS detalle, COUNT(*)
    FROM dcheader h JOIN dcdetall d ON d.CONTROL = h.CONTROL
    GROUP BY 1, 2;

[PENDIENTE] Volcar estructura completa:  DESCRIBE dcdetall;


7. NUMERACIÓN FISCAL (cfparame)
----------------------------------------------------------------
Contador DISTINTO e independiente del CONTROL interno. Es el
número visible/impreso de la factura y el que se reporta al
organismo fiscal.

7.1 NÚMEROS SIGUIENTES POR TIPO DE DOCUMENTO
  NROINIFAC, NROINIFAC2   Factura
  NROININC                Nota de crédito
  NROININD                Nota de débito
  NROINIDEV               Devolución
  NROINIREC               Recibo
  NROINIPRE               Presupuesto
  NROINISOL               Solicitud
  NROINIODC               Orden de compra
  NROINITRA, NROINITRAS   Traslado
  NROINICAR               Cargo
  NROINIDES               Descargo
  NROINIAJU               Ajuste
  NROINIATRIBUTOS
  NROINIBANCHE / BANDEP / BANNC / BANND   Movimientos bancarios

7.2 SEGMENTACIÓN POR TIPO DE CONTRIBUYENTE
Cada tipo tiene número actual y rango desde (_D) / hasta (_H):
  NROFAC_CONTRI  / _D / _H    Contribuyente ordinario
  NROFAC_GUBER   / _D / _H    Gubernamental
  NROFAC_REGESP  / _D / _H    Régimen especial
  NROFAC_CONFIN  / _D / _H    Consumidor final
  NRONC_*        idem para notas de crédito
  PREFAC_* / PRENC_*          Prefijos por tipo

CRÍTICO PARA EL API: al emitir una factura hay que usar el rango
que corresponde al tipo de contribuyente del cliente, o se rompe
el control fiscal.

[PENDIENTE] Determinar de qué campo del cliente se deriva el tipo
de contribuyente.

7.3 OTROS CAMPOS RELEVANTES DE cfparame
  NROESTABLECIMIENTO   Posible relación con posiciones 18-19 del
                       CONTROL
  IDFISCAL, IDFISCAL2, NUMFISCAL, NUMFISCAL2
  IDIMPUESTO, IDIMPUESTO2, IDIMPUESTO3, IDIMPUESTOL, IDIMPUESTOR
  IMPPOR, IMPPOR2, IMPPOR3        Porcentajes de impuesto
  CODIMPUESTOIVA, CODIMPUESTOL, CODIMPUESTOR
  ACTIVARIVAREDUCIDO
  MONTOMAXDCTOIVA, MONTOMAXDCTOIVA2
  PORRETIMP, PORRETIMPCLI         Retenciones
  NRORETIMP, NRORETIMPISLR
  TASACAMBIO1, MONEDA, NOMBREMONEDA, RECONVERSION
  REDONDEO, PRECIOVENTAD, PVPMENOR
  TITPRECIO1/2/3, FPRECIO1/2/3, ACTPRECIO1/2/3   Listas de precio
  USAINVPER, USACAJA, USACXCGEN, USACXPGEN, USACONTABILIDAD
  USAOPERACIONES, USANE, USACAMPOSADD

[PENDIENTE] Verificar cuáles flags USA* están activos: definen
qué módulos debe alimentar el API.


8. SECUENCIA DE ESCRITURA DE UNA VENTA
----------------------------------------------------------------
Una venta de contado NO es un registro. Confirmado por evidencia:

  1. dcheader  TIPTRAN='FAC'
               CONTROLDOC = su propio CONTROL
  2. dcdetall  una fila por renglón, con el CONTROL de la factura
  3. dcheader  TIPTRAN='PAGxFAC'
               CONTROL nuevo (siguiente consecutivo)
               CONTROLDOC = CONTROL de la factura
               NUMDOC = nro. con sufijo 'R'

Si se omite el paso 3, Saint mostrará la factura como pendiente de
cobro y se descuadra cuentas por cobrar.

[PENDIENTE] Confirmar si además se genera un DES (descargo de
inventario) asociado:
    SELECT CONTROL, TIPTRAN, NUMREF, NUMDOC
    FROM dcheader
    WHERE CONTROLDOC = '8242336898740008201'
    ORDER BY CONTROL;

[PENDIENTE] Mapear las escrituras fuera de dc* (ver 3.1).
Método: activar traza ODBC de 32 bits
(C:\Windows\SysWOW64\odbcad32.exe -> pestaña Rastreo),
guardar UNA sola factura, detener la traza inmediatamente.
Buscar SQLExecDirect / SQLPrepare en el log.

VENTAS A CRÉDITO: la muestra levantada es toda de contado. Si el
negocio maneja plazos, esas facturas no tendrán PAGxFAC asociado.
    SELECT h.NUMREF, h.MONTOPAGF
    FROM dcheader h
    WHERE h.TIPTRAN = 'FAC'
      AND NOT EXISTS (SELECT 1 FROM dcheader p
                      WHERE p.CONTROLDOC = h.CONTROL
                        AND p.TIPTRAN = 'PAGxFAC');


9. CONSULTAS DE LECTURA ÚTILES
----------------------------------------------------------------
-- Factura con sus renglones
SELECT h.*, d.*
FROM dcheader h
JOIN dcdetall d ON d.CONTROL = h.CONTROL
WHERE h.TIPTRAN = 'FAC' AND h.NUMREF = '000006';

-- Operación completa (factura + pago + devoluciones + descargo)
SELECT * FROM dcheader
WHERE CONTROLDOC = '8242336898740008201'
ORDER BY CONTROL;

-- Facturas de un período, decodificando la fecha del CONTROL
SELECT NUMREF, NOMBRE, MONTOPAGF,
       DATE_ADD('1800-12-28',
         INTERVAL CAST(SUBSTRING(CONTROL,1,5) AS UNSIGNED) DAY) AS fecha
FROM dcheader
WHERE TIPTRAN = 'FAC'
HAVING fecha BETWEEN '2026-08-01' AND '2026-08-31';


10. OTRAS TABLAS DETECTADAS (contexto)
----------------------------------------------------------------
Módulo documentos : dcheader, dcdetall, dcauxili, dcamplia,
                    dcobserv, dcserial
Configuración     : cfparame, cfusuari, cftreten, cffecorrel
Fact. electrónica : fecorrelenc, fecorrellin, cffecorrel
Bancos            : bancos, bacompro, bamovimi
Caja              : cjdetall, movimientoscaja, movimientoscajatemp,
                    aperturacierrecaja, aperturacierrecajadenominacion
POS               : apolloposrecords, apolloposserialdevices
Auditoría         : auditoriafacturacioncomandas,
                    auditoriaitemsfacturacioncomandas
Módulo CR         : clientescr, productoscr, servicioscr,
                    impuestoscr, instrumentoscr, configuracioncr
IGTF              : igtfconfig, igtfrecords
Vehículos         : vehodch, vehodcd

Nota: el prefijo 'fe' corresponde a facturación electrónica; no
confundir esos correlativos con el CONTROL interno.

[PENDIENTE] Identificar la tabla de clientes y la de productos:
son necesarias para el API de ventas y aún no se han mapeado.


11. RIESGOS Y DECISIONES ABIERTAS
----------------------------------------------------------------
[ ] ENGINE de las tablas (InnoDB vs MyISAM) -> define si se puede
    usar transacción + FOR UPDATE
[ ] Estrategia del contador: compartir CONTADORCONTROL vs código
    de terminal propio en posiciones 18-19
[ ] Semántica exacta de las posiciones 18-19
[ ] Escrituras fuera de dc* que consume una venta
[ ] Rangos fiscales por tipo de contribuyente
[ ] Manejo de ventas a crédito
[ ] Comportamiento al agotar el consecutivo de 5 dígitos
[ ] Tablas de clientes y productos

RECOMENDACIÓN DE IMPLANTACIÓN:
Empezar las pruebas de escritura con documentos NO vinculantes
(PRE, PEDxCLI): no descargan inventario ni generan deuda, así que
un error no descuadra nada. Pasar a FAC solo después.

================================================================
FIN DEL DOCUMENTO
================================================================