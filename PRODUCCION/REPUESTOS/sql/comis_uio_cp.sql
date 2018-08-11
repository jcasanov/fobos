
select
        r20_localidad
       ,r20_item
       ,r20_cod_tran
       ,r20_num_tran
       ,r19_cont_cred
       ,r01_nombres
       ,r19_vendedor
       ,r19_codcli
       ,z01_nomcli
       ,z01_ciudad
       ,round(r20_precio*r20_cant_ven,2)-r20_val_descto
       ,0
       ,0
       ,0
       ,0
       ,0
       ,0
       ,date(r19_fecing)
       ,r10_marca
       ,r10_cod_clase
       ,z20_fecha_vcto
    ,date(z24_fecing)
       ,z20_valor_cap
       ,r10_filtro
       ,r20_bodega
       ,'F'
FROM
acero_qm:rept019,
acero_qm:cxct001,
acero_qm:rept001,
acero_qm:rept020,
acero_qm:rept010,
acero_qm:cxct020,
acero_qm:cxct025,
acero_qm:cxct024

WHERE r19_compania   = 1
  and r19_localidad in (3, 5)
  and r19_cod_tran   = 'FA'
  and z01_codcli     = r19_codcli
  and r01_compania   = r19_compania
  and r01_codigo     = r19_vendedor
  and r01_estado     = 'A'        -- Vendedores activos
  and r01_tipo       = 'E'                -- Vendedores externos
  and r20_compania   = r19_compania
  and r20_localidad  = r19_localidad
  and r20_cod_tran   = r19_cod_tran
  and r20_num_tran   = r19_num_tran
  and r10_compania   = r20_compania
  and r10_codigo     = r20_item
  and z20_compania   = r20_compania
  and z20_localidad  = r20_localidad
  and z20_codcli     = r19_codcli
  and z20_tipo_doc   = 'FA'
  and z20_cod_tran   = r20_cod_tran
  and z20_num_tran   = r20_num_tran
  and z20_areaneg    = 1
  and z20_saldo_cap + z20_saldo_int = 0
  and z25_compania   = z20_compania
  and z25_localidad  = z20_localidad
  and z25_codcli     = z20_codcli
  and z25_tipo_doc   = z20_tipo_doc
  and z25_num_doc    = z20_num_doc
  and z24_compania   = z25_compania
  and z24_localidad  = z25_localidad
  and z24_numero_sol = z25_numero_sol
  and z24_estado     = 'P'
  and extend(z24_fecing, year to month) = '2013-03';
