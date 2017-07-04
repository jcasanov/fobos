SELECT r21_numprof AS numprof,
	(SELECT r23_numprev
		FROM rept023
		WHERE r23_compania  = r21_compania
		  AND r23_localidad = r21_localidad
		  AND r23_numprof   = r21_numprof) AS numprev,
	r21_cod_tran AS codtran,
	r21_num_tran AS numtran,
	r21_moneda AS moneda,
	(SELECT g13_nombre
		FROM gent013
		WHERE g13_moneda = r21_moneda) AS nommon,
	r21_fecing AS fecprof,
	r21_dias_prof AS dias_val,
	r21_porc_impto AS porc_impto,
	g02_nombre AS almacen,
	g02_numruc AS ruccia,
	g02_direccion AS dircia,
	g02_telefono1 AS telcia,
	g02_fax1 AS faxcia,
	r21_codcli AS codcli,
	r21_nomcli AS nomcli,
	r21_dircli AS dircli,
	r21_telcli AS telcli,
	r21_cedruc AS cedruc,
	(SELECT z01_fax1
		FROM cxct001
		WHERE z01_codcli = r21_codcli) AS faxcli,
	r21_atencion AS observacion,
	r21_referencia AS entregar_en,
	r21_forma_pago AS forpago,
	r21_vendedor AS codven,
	r01_nombres AS vendedor,
	r22_orden AS secuencia,
	r22_item AS item,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r10_uni_med AS uni_med,
	r10_marca AS marca,
	r22_cantidad AS cantidad,
	r22_precio AS precio_uni,
	r22_porc_descto AS porc_desc,
	((r22_cantidad * r22_precio) - r22_val_descto) AS precio_tot,
	r21_tot_bruto AS tot_bru,
	r21_tot_dscto AS val_des,
	(r21_tot_bruto - r21_tot_dscto) AS subtot,
	(r21_tot_neto - r21_flete - (r21_tot_bruto - r21_tot_dscto)) AS impto,
	r21_flete AS flete,
	r21_tot_neto AS tot_neto
	FROM rept021, rept022, rept010, rept072, rept001, gent002
	WHERE r21_compania  = 1
	  AND r21_localidad = 1
	  AND r21_numprof   = 134812
	  AND r22_compania  = r21_compania
	  AND r22_localidad = r21_localidad
	  AND r22_numprof   = r21_numprof
	  AND r10_compania  = r22_compania
	  AND r10_codigo    = r22_item
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	  AND r01_compania  = r21_compania
	  AND r01_codigo    = r21_vendedor
	  AND g02_compania  = r22_compania
	  AND g02_localidad = r22_localidad
	ORDER BY r22_orden ASC;
