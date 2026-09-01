#!/bin/bash
orden=(
  01_snap_original
  02_snap_fac_contado_1renglon
  03_snap_fac_contado_2renglones
  04_snap_fac_cred_1renglon
  05_snap_cob_fac_cred_1renglon
  06_snap_nuevo_cliente
  07_snap_cotizacion
  08_snap_devolucion
  09_snap_producto_seriales
  10_snap_compra_producto_seriales
  11_snap_venta_2productos_seriales
  12_snap_abrir_cerrar_modulo
)

for ((i=1; i<${#orden[@]}; i++)); do
  a=${orden[i-1]}; b=${orden[i]}
  n=$(printf "%02d" $i)
  out="diff_${n}_${b#snap_}.txt"
  diff -U0 -I '^-- Dump completed' "$a.sql" "$b.sql" > "$out"
  printf "%-45s %6s lineas\n" "$out" "$(wc -l < "$out")"
done