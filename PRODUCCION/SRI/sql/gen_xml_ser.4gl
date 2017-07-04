DATABASE sermaco


DEFINE anio, mes	INTEGER



MAIN

	LET anio = arg_val(1)
	LET mes  = arg_val(2)
	CALL generar_archivo_venta_xml()

END MAIN



FUNCTION generar_archivo_venta_xml()
DEFINE r_s21		RECORD
				s21_compania	LIKE srit021.s21_compania,
				s21_anio	LIKE srit021.s21_anio,
				s21_mes		LIKE srit021.s21_mes,
				s21_ident_cli	LIKE srit021.s21_ident_cli,
				s21_num_doc_id	LIKE srit021.s21_num_doc_id,
				s21_tipo_comp	LIKE srit021.s21_tipo_comp,
				s21_fecha_reg_cont LIKE srit021.s21_fecha_reg_cont,
				s21_num_comp_emi LIKE srit021.s21_num_comp_emi,
				s21_fecha_emi_vta LIKE srit021.s21_fecha_emi_vta,
				s21_base_imp_tar_0 LIKE srit021.s21_base_imp_tar_0,
				s21_iva_presuntivo LIKE srit021.s21_iva_presuntivo,
				s21_bas_imp_gr_iva LIKE srit021.s21_bas_imp_gr_iva,
				s21_cod_porc_iva   LIKE srit021.s21_cod_porc_iva,
				s21_monto_iva	LIKE srit021.s21_monto_iva,
				s21_base_imp_ice LIKE srit021.s21_base_imp_ice,
				s21_cod_porc_ice LIKE srit021.s21_cod_porc_ice,
				s21_monto_ice	 LIKE srit021.s21_monto_ice,
				s21_monto_iva_bie LIKE srit021.s21_monto_iva_bie,
				s21_cod_ret_ivabie LIKE srit021.s21_cod_ret_ivabie,
				s21_mon_ret_ivabie LIKE srit021.s21_mon_ret_ivabie,
				s21_monto_iva_ser  LIKE srit021.s21_monto_iva_ser,
				s21_cod_ret_ivaser LIKE srit021.s21_cod_ret_ivaser,
				s21_mon_ret_ivaser LIKE srit021.s21_mon_ret_ivaser,
				s21_ret_presuntivo LIKE srit021.s21_ret_presuntivo,
				s21_concepto_ret   LIKE srit021.s21_concepto_ret,
				s21_base_imp_renta LIKE srit021.s21_base_imp_renta,
				s21_porc_ret_renta LIKE srit021.s21_porc_ret_renta,
				s21_monto_ret_rent LIKE srit021.s21_monto_ret_rent
			END RECORD
DEFINE query		CHAR(6000)
DEFINE registro		CHAR(4000)

SELECT * FROM sermaco_gm@segye01:srit021
	WHERE s21_compania  = 2
	  AND s21_localidad = 6
	  AND s21_anio      = anio
	  AND s21_mes       = mes
UNION
	SELECT * FROM sermaco_qm@seuio01:srit021
		WHERE s21_compania  = 2
		  AND s21_localidad = 7
		  AND s21_anio      = anio
		  AND s21_mes       = mes
INTO TEMP t1
LET query = 'SELECT s21_compania, s21_anio, s21_mes,',
		' s21_ident_cli, s21_num_doc_id, s21_tipo_comp,',
		' MDY(s21_mes, 01, s21_anio) + 1 UNITS MONTH - 1 UNITS DAY',
		' s21_fecha_reg_cont, NVL(SUM(s21_num_comp_emi), 0)',
		' s21_num_comp_emi,',
		' MDY(s21_mes, 01, s21_anio) + 1 UNITS MONTH - 1 UNITS DAY',
		' s21_fecha_emi_vta,',
		' NVL(SUM(s21_base_imp_tar_0), 0) s21_base_imp_tar_0,',
		' s21_iva_presuntivo,',
		' NVL(SUM(s21_bas_imp_gr_iva), 0) s21_bas_imp_gr_iva,',
		' s21_cod_porc_iva, NVL(SUM(s21_monto_iva), 0) s21_monto_iva,',
		' NVL(SUM(s21_base_imp_ice), 0) s21_base_imp_ice,',
		' s21_cod_porc_ice, NVL(SUM(s21_monto_ice), 0) s21_monto_ice,',
		' NVL(SUM(s21_monto_iva_bie), 0) s21_monto_iva_bie,',
		' s21_cod_ret_ivabie,',
		' NVL(SUM(s21_mon_ret_ivabie), 0) s21_mon_ret_ivabie, ',
		' NVL(SUM(s21_monto_iva_ser), 0) s21_monto_iva_ser,',
		' s21_cod_ret_ivaser,',
		' NVL(SUM(s21_mon_ret_ivaser), 0) s21_mon_ret_ivaser,',
		' s21_ret_presuntivo, s21_concepto_ret,',
		' NVL(SUM(s21_base_imp_renta), 0) s21_base_imp_renta,',
		' s21_porc_ret_renta,',
		' NVL(SUM(s21_monto_ret_rent), 0) s21_monto_ret_rent ',
		' FROM t1 ',
		' GROUP BY 1,2,3,4,5,6,7,9,11,13,16,19,22,24,25,27 ',
		' INTO TEMP tmp_s21 '
PREPARE exec_t1_final FROM query
EXECUTE exec_t1_final
DROP TABLE t1
DECLARE q_s21 CURSOR FOR SELECT * FROM tmp_s21
DISPLAY '<?xml version="1.0" encoding="UTF-8"?>'
DISPLAY '<iva xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
DISPLAY '<numeroRuc>1790008959001</numeroRuc>'
DISPLAY '<razonSocial>ACERO COMERCIAL ECUATORIANO S.A.</razonSocial>'
DISPLAY '<direccionMatriz>AV. LA PRENSA</direccionMatriz>'
DISPLAY '<telefono>022454333</telefono>'
DISPLAY '<email>infouio@acerocomercial.com</email>'
DISPLAY '<tpIdRepre>C</tpIdRepre>'
DISPLAY '<idRepre>0915392880</idRepre>'
DISPLAY '<rucContador>0915392880001</rucContador>'
DISPLAY '<anio>', anio, '</anio>'
DISPLAY '<mes>', mes USING "&&", '</mes>'
DISPLAY '<compras>'
DISPLAY '</compras>'
LET registro = '<ventas>'
FOREACH q_s21 INTO r_s21.*
	LET registro = registro CLIPPED, '<detalleVentas>',
			'<tpIdCliente>', r_s21.s21_ident_cli, '</tpIdCliente>',
			'<idCliente>', r_s21.s21_num_doc_id, '</idCliente>',
		'<tipoComprobante>', r_s21.s21_tipo_comp, '</tipoComprobante>',
		'<fechaRegistro>', r_s21.s21_fecha_reg_cont USING "dd/mm/yyyy", '</fechaRegistro>',
		'<numeroComprobantes>', r_s21.s21_num_comp_emi, '</numeroComprobantes> ',
		'<fechaEmision>', r_s21.s21_fecha_emi_vta USING "dd/mm/yyyy", '</fechaEmision> ',
		'<baseImponible>', r_s21.s21_base_imp_tar_0, '</baseImponible> ',
		'<ivaPresuntivo>', r_s21.s21_iva_presuntivo, '</ivaPresuntivo> ',
		'<baseImpGrav>', r_s21.s21_bas_imp_gr_iva, '</baseImpGrav> ',
		'<porcentajeIva>', r_s21.s21_cod_porc_iva, '</porcentajeIva> ',
		'<montoIva>', r_s21.s21_monto_iva, '</montoIva> ',
		'<baseImpIce>', r_s21.s21_base_imp_ice, '</baseImpIce> ',
		'<porcentajeIce>', r_s21.s21_cod_porc_ice, '</porcentajeIce> ',
		'<montoIce>', r_s21.s21_monto_ice, '</montoIce> ',
		'<montoIvaBienes>', r_s21.s21_monto_iva_bie, '</montoIvaBienes> ',
		'<porRetBienes>', r_s21.s21_cod_ret_ivabie, '</porRetBienes> ',
		'<valorRetBienes>', r_s21.s21_mon_ret_ivabie, '</valorRetBienes> ',
		'<montoIvaServicios>', r_s21.s21_monto_iva_ser, '</montoIvaServicios> ',
		'<porRetServicios>', r_s21.s21_cod_ret_ivaser, '</porRetServicios> ',
		'<valorRetServicios>', r_s21.s21_mon_ret_ivaser, '</valorRetServicios> ',
		'<retPresuntiva>', r_s21.s21_ret_presuntivo, '</retPresuntiva>'
	IF r_s21.s21_concepto_ret <> '000' THEN
		LET registro = registro CLIPPED, '<air>','<detalleAir>',
			'<codRetAir>', r_s21.s21_concepto_ret, '</codRetAir>',
			'<baseImpAir>',r_s21.s21_base_imp_renta,'</baseImpAir>',
			'<porcentajeAir>', r_s21.s21_porc_ret_renta,'</porcentajeAir>',
			'<valRetAir>', r_s21.s21_monto_ret_rent,'</valRetAir>',
			'</detalleAir>','</air>'
	ELSE
		LET registro = registro CLIPPED, '<air/>'
	END IF
	LET registro = registro CLIPPED, '</detalleVentas>'
	DISPLAY registro CLIPPED
	LET registro = ' '
END FOREACH
DISPLAY '</ventas>'
DISPLAY '<importaciones>'
DISPLAY '</importaciones>'
DISPLAY '<exportaciones>'
DISPLAY '</exportaciones>'
DISPLAY '<recap>'
DISPLAY '</recap>'
DISPLAY '<fideicomisos>'
DISPLAY '</fideicomisos>'
DISPLAY '<anulados>'
DISPLAY '</anulados>'
DISPLAY '<rendFinancieros>'
DISPLAY '</rendFinancieros>'
DISPLAY '</iva>'
DROP TABLE tmp_s21
--CALL fl_mostrar_mensaje('Archivo XML de ventas generado OK.', 'info')

END FUNCTION
