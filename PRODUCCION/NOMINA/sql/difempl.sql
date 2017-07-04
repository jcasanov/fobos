select distinct

a.n30_compania, b.n30_compania,

a.n30_cod_trab, b.n30_cod_trab,

a.n30_estado, b.n30_estado,

a.n30_nombres, b.n30_nombres,

a.n30_fecha_ing, b.n30_fecha_ing,

a.n30_fecha_reing, b.n30_fecha_reing,

a.n30_fecha_sal, b.n30_fecha_sal,

a.n30_mon_sueldo, b.n30_mon_sueldo,

a.n30_sueldo_mes, b.n30_sueldo_mes,

a.n30_factor_hora, b.n30_factor_hora,

a.n30_tipo_trab, b.n30_tipo_trab,

a.n30_tipo_contr, b.n30_tipo_contr,

a.n30_tipo_rol, b.n30_tipo_rol,

a.n30_cod_cargo, b.n30_cod_cargo,

a.n30_cod_depto, b.n30_cod_depto,

a.n30_pais_nac, b.n30_pais_nac,

a.n30_ciudad_nac, b.n30_ciudad_nac,

a.n30_fecha_nacim, b.n30_fecha_nacim,

a.n30_sexo, b.n30_sexo,

a.n30_est_civil, b.n30_est_civil,

a.n30_telef_fami, b.n30_telef_fami,

a.n30_refer_fami, b.n30_refer_fami,

a.n30_tipo_doc_id, b.n30_tipo_doc_id,

a.n30_num_doc_id, b.n30_num_doc_id,

--a.n30_carnet_seg, b.n30_carnet_seg,

a.n30_sub_activ, b.n30_sub_activ,

a.n30_tipo_pago, b.n30_tipo_pago,

a.n30_bco_empresa, b.n30_bco_empresa,

a.n30_cta_empresa, b.n30_cta_empresa,

a.n30_tipo_cta_tra, b.n30_tipo_cta_tra,

a.n30_cta_trabaj, b.n30_cta_trabaj,

a.n30_desc_seguro, b.n30_desc_seguro,

a.n30_desc_impto, b.n30_desc_impto,

a.n30_cod_seguro, b.n30_cod_seguro,

a.n30_sectorial, b.n30_sectorial,

a.n30_lib_militar, b.n30_lib_militar,

a.n30_fec_jub, b.n30_fec_jub,

a.n30_val_jub_pat, b.n30_val_jub_pat,

a.n30_usuario, b.n30_usuario,

a.n30_fecing, b.n30_fecing

  from rolt030 a, aceros:rolt030 b  where b.n30_compania = 1    and
             b.n30_estado   = "A"    and a.n30_compania = b.n30_compania    and
             a.n30_cod_trab = b.n30_cod_trab  order by b.n30_nombres
