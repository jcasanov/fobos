unload to "/FOBOS/PRODUCCION/REPUESTOS/sql/prof_vendedor"
select r01_nombres   VENDEDOR,  r21_nomcli    CLIENTE,
       r21_tot_bruto BRUTO   , r21_tot_dscto DESCUENTO,
       r21_tot_bruto - r21_tot_dscto SUBTOTAL,
       date(r21_fecing) FECHA
from rept021, rept001
where r21_compania = 1
  and r21_localidad = 1
   and r21_compania =  r01_compania
-- and r21_vendedor = 3
   and r21_vendedor = r01_codigo
   and date(r21_fecing) > '04-30-2002'
   and r01_estado = 'A'
