create view repv021(
       r21_compania, 
    r21_localidad ,
    r21_numprof ,
    r21_grupo_linea, 
    r21_modelo ,
    r21_forma_pago, 
    r21_referencia ,
    r21_atencion ,
    r21_codcli ,
    r21_nomcli ,
    r21_dircli ,
    r21_telcli ,
    r21_cedruc ,
    r21_vendedor, 
    r21_descuento, 
    r21_porc_impto, 
    r21_bodega ,
    r21_moneda ,
    r21_tot_costo, 
    r21_tot_bruto ,
    r21_tot_dscto ,
    r21_tot_neto ,
    r21_precision ,
    r21_dias_prof ,
    r21_factor_fob ,
    r21_factor_prec ,
    r21_usuario ,
    r21_fecing ,
    r21_fec_aprob
) as
select r21_compania, 
    r21_localidad ,
    r21_numprof ,
    r21_grupo_linea, 
    r21_modelo ,
    r21_forma_pago, 
    r21_referencia ,
    r21_atencion ,
    r21_codcli ,
    r21_nomcli ,
    r21_dircli ,
    r21_telcli ,
    r21_cedruc ,
    r21_vendedor, 
    r21_descuento, 
    r21_porc_impto, 
    r21_bodega ,
    r21_moneda ,
    r21_tot_costo, 
    r21_tot_bruto ,
    r21_tot_dscto ,
    r21_tot_neto ,
    r21_precision ,
    r21_dias_prof ,
    r21_factor_fob ,
    r21_factor_prec ,
    r21_usuario ,
    r21_fecing ,
    (select max(r23_fecing) from rept023, rept102
            where r102_compania  = r21_compania
              and r102_localidad = r21_localidad
              and r102_numprof   = r21_numprof
              and r23_compania   = r102_compania
              and r23_localidad  = r102_localidad
              and r23_numprev    = r102_numprev
              and r23_estado     in ('P', 'F')) as r21_fec_aprob
  from rept021


