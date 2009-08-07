
select year(c10_fecing) as anho, month(c10_fecing) as mes, 
       c10_cod_depto as cod_depto, 
       (select g34_nombre[1, 15] from gent034 
         where g34_cod_depto = c10_cod_depto)
       as departamento, c10_codprov as codprov, 
       (select p01_nomprov[1, 30] from cxpt001 where p01_codprov = c10_codprov)
       as proveedor, 
       c13_factura as factura, p28_tipo_ret || ' ' || round(p28_porcentaje, 0)
       || '%' as retencion, p28_valor_base as base, p28_valor_ret as retenido
  from ordt010, ordt013, cxpt027, cxpt028 
 where c13_compania  = c10_compania
   and c13_localidad = c10_localidad
   and c13_numero_oc = c10_numero_oc
   and p27_compania  = c13_compania
   and p27_localidad = c13_localidad
   and p27_num_ret   = c13_num_ret
   and p27_estado    = 'A'
   and p28_compania  = p27_compania
   and p28_localidad = p27_localidad
   and p28_num_ret   = p27_num_ret;

