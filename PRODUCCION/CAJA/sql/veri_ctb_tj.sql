set isolation to dirty read;
select j10_compania cia, j11_localidad loc, j10_tipo_destino tp,
        lpad(j10_num_destino, 5, 0) num, date(j10_fecing) fecha,
        z02_aux_clte_mb aux_tj, b13_cuenta aux_ctb, j11_valor, b13_valor_base
        from cajt010, cajt011, gent010, cxct001, cxct002, rept040, ctbt012,
        ctbt013
        where j10_compania      = 1
          and j10_localidad     = 1
          and j10_tipo_fuente  in ('PR', 'OT')
          and year(j10_fecing)  = 2010
          and j11_compania      = j10_compania
          and j11_localidad     = j10_localidad
          and j11_tipo_fuente   = j10_tipo_fuente
          and j11_num_fuente    = j10_num_fuente
          and j11_codigo_pago   = 'TJ'
          and g10_compania      = j11_compania
          and g10_tarjeta       = j11_cod_bco_tarj
          and g10_cod_tarj      = j11_codigo_pago
          and g10_cont_cred     = 'C'
          and z01_codcli        = g10_codcobr
          and z02_compania      = g10_compania
          and z02_localidad     = j11_localidad
          and z02_codcli        = z01_codcli
          and r40_compania      = j10_compania
          and r40_localidad     = j10_localidad
          and r40_cod_tran      = j10_tipo_destino
          and r40_num_tran      = j10_num_destino
          and b12_compania      = r40_compania
          and b12_tipo_comp     = r40_tipo_comp
          and b12_num_comp      = r40_num_comp
          and b12_subtipo       = 8
          and b13_compania      = b12_compania
          and b13_tipo_comp     = b12_tipo_comp
          and b13_num_comp      = b12_num_comp
          and b13_cuenta       <> z02_aux_clte_mb
          and b13_valor_base    = j11_valor
        order by 5, 3, 4;
