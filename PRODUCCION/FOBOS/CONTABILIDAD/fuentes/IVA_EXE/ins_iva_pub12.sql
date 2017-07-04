begin work;

update cxct001
	set z01_tipo_clte = 4,
	    z01_paga_impto = 'S'
	where z01_tipo_clte = 9
	  and z01_estado    = 'A';

{--
--------------------------------------------------------------------------------
-- PARA CONTABILIZACION INVENTARIO: VENTAS IVA 12% (OTROS)
insert into ctbt044
	(b44_compania, b44_localidad, b44_modulo, b44_bodega, b44_grupo_linea,
	 b44_porc_impto, b44_tipo_cli, b44_venta, b44_descuento, b44_dev_venta,
	 b44_costo_venta, b44_dev_costo, b44_inventario, b44_transito,
	 b44_ajustes, b44_flete, b44_usuario, b44_fecing)
	select b40_compania, b40_localidad, b40_modulo, b40_bodega,
		b40_grupo_linea, b40_porc_impto, 4, '41020201001',
		'41020201003', '41020201002', b40_costo_venta, b40_dev_costo,
		b40_inventario, b40_transito, b40_ajustes, b40_flete,
		'FOBOS', current
		from ctbt040
		where b40_porc_impto = 12.00;
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- PARA CONTABILIZACION TALLER: VENTAS IVA 0% (OTROS)
insert into ctbt045
	(b45_compania, b45_localidad, b45_grupo_linea, b45_porc_impto,
	 b45_tipo_cli, b45_vta_mo_tal, b45_vta_mo_ext, b45_vta_mo_cti,
	 b45_vta_rp_tal, b45_vta_rp_ext, b45_vta_rp_cti, b45_vta_rp_alm,
	 b45_vta_otros1, b45_vta_otros2, b45_dvt_mo_tal, b45_dvt_mo_ext,
	 b45_dvt_mo_cti, b45_dvt_rp_tal, b45_dvt_rp_ext, b45_dvt_rp_cti,
	 b45_dvt_rp_alm, b45_dvt_otros1, b45_dvt_otros2, b45_cos_mo_tal,
	 b45_cos_mo_ext, b45_cos_mo_cti, b45_cos_rp_tal, b45_cos_rp_ext,
	 b45_cos_rp_cti, b45_cos_rp_alm, b45_cos_otros1, b45_cos_otros2,
	 b45_pro_mo_tal, b45_pro_mo_ext, b45_pro_mo_cti, b45_pro_rp_tal,
	 b45_pro_rp_ext, b45_pro_rp_cti, b45_pro_rp_alm, b45_pro_otros1,
	 b45_pro_otros2, b45_des_mo_tal, b45_des_rp_tal, b45_des_rp_alm,
	 b45_usuario, b45_fecing) 
	select b43_compania, b43_localidad, b43_grupo_linea, b43_porc_impto,
		4, '41020202001', '41020202002', '41020202001',
		'41020202003', '41020202003', b43_vta_rp_cti, b43_vta_rp_alm,
		b43_vta_otros1, b43_vta_otros2, '41020202004', '41020202005',
		'41020202004', '41020202006', '41020202006', '41020202006',
		b43_dvt_rp_alm, b43_dvt_otros1, b43_dvt_otros2, b43_cos_mo_tal,
		b43_cos_mo_ext, b43_cos_mo_cti, b43_cos_rp_tal, b43_cos_rp_ext,
		b43_cos_rp_cti, b43_cos_rp_alm, b43_cos_otros1, b43_cos_otros2,
		b43_pro_mo_tal, b43_pro_mo_ext, b43_pro_mo_cti, b43_pro_rp_tal,
		b43_pro_rp_ext, b43_pro_rp_cti, b43_pro_rp_alm, b43_pro_otros1,
		b43_pro_otros2, b43_des_mo_tal, b43_des_rp_tal, b43_des_rp_alm,
	 	'FOBOS', current 
		from ctbt043
		where b43_porc_impto = 12.00;
--
--------------------------------------------------------------------------------
--}


commit work;
