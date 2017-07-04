DATABASE aceros


DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)
DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE fecha		DATE
DEFINE hor_ini, hor_fin	DATETIME HOUR TO MINUTE
DEFINE vm_tot_reg	INTEGER



MAIN

	IF num_args() <> 5 AND num_args() <> 6 AND num_args() <> 7 THEN
		DISPLAY 'Parametros Incorrectos. SON: BASE SERVIDOR COMPANIA',
			' LOCALIDAD FECHA = (mm/dd/aaaa) HOR_INI HOR_FIN ',
			'(hh:mm).'
		EXIT PROGRAM
	END IF
	LET base_ori  = arg_val(1)
	LET serv_ori  = arg_val(2)
	LET vg_codcia = arg_val(3)
	LET vg_codloc = arg_val(4)
	LET fecha     = arg_val(5)
	INITIALIZE hor_ini, hor_fin TO NULL
	LET hor_ini   = arg_val(6)
	LET hor_fin   = arg_val(7)
	CALL ejecuta_proceso()

END MAIN



FUNCTION activar_base(b, s)
DEFINE b, s		CHAR(20)
DEFINE base, base1	CHAR(20)
DEFINE r_g51		RECORD LIKE gent051.*

LET base  = b
LET base1 = base CLIPPED, '@', s
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base1
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base1
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecuta_proceso()

CALL activar_base(base_ori, serv_ori)
SET ISOLATION TO DIRTY READ
DISPLAY 'Generando FA ELEC. de Inventario ... (', base_ori CLIPPED, '@',
	serv_ori CLIPPED, ')'
LET vm_tot_reg = 0
CALL gen_xml_elect("FAI")
DISPLAY ' '
DISPLAY 'Generando NC ELEC. de Inventario ... (', base_ori CLIPPED, '@',
	serv_ori CLIPPED, ')'
CALL gen_xml_elect("NCI")
DISPLAY ' '
DISPLAY 'Generando NC ELEC. Manuales ... (', base_ori CLIPPED, '@',
	serv_ori CLIPPED, ')'
CALL gen_xml_elect("NCC")
DISPLAY ' '
DISPLAY 'Generando GR ELEC. de Inventario ... (', base_ori CLIPPED, '@',
	serv_ori CLIPPED, ')'
CALL gen_xml_elect("GRI")
IF vg_codloc <> 4 THEN
	DISPLAY ' '
	DISPLAY 'Generando RT ELEC. de Proveedores ... (',base_ori CLIPPED, '@',
		serv_ori CLIPPED, ')'
	CALL gen_xml_elect("RTP")
	DISPLAY ' '
	DISPLAY 'Generando FA ELEC. de Taller ... (', base_ori CLIPPED, '@',
		serv_ori CLIPPED, ')'
	CALL gen_xml_elect("FAT")
	DISPLAY ' '
	DISPLAY 'Generando NC ELEC. de Taller ... (', base_ori CLIPPED, '@',
		serv_ori CLIPPED, ')'
	CALL gen_xml_elect("NCT")
	DISPLAY ' '
	DISPLAY 'Generando ND ELEC. de Clientes ... (', base_ori CLIPPED, '@',
		serv_ori CLIPPED, ')'
	CALL gen_xml_elect("NDC")
END IF
{--
DISPLAY ' '
DISPLAY 'Generando RT ELEC. de Clientes ... (', base_ori CLIPPED, '@',
	serv_ori CLIPPED, ')'
CALL gen_xml_elect("RTC")
--}
DISPLAY ' '
DISPLAY ' '
DISPLAY 'Total de ', vm_tot_reg USING "<<<<<&", ' Archivos Generados  OK.  ',
	'en (', base_ori CLIPPED, '@', serv_ori CLIPPED, ')'

END FUNCTION



FUNCTION gen_xml_elect(tip_doc)
DEFINE tip_doc		CHAR(3)
DEFINE r_reg		RECORD
				cod_tran	LIKE rept019.r19_cod_tran,
				num_tran	VARCHAR(15),
				codcli		LIKE cxct001.z01_codcli
			END RECORD
DEFINE query		CHAR(1800)
DEFINE comando		CHAR(400)
DEFINE cont		INTEGER
DEFINE nom_doc		VARCHAR(30)

LET query = preparar_query(tip_doc)
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DECLARE q_t1 CURSOR FOR
	SELECT * FROM t1
LET cont = 0
FOREACH q_t1 INTO r_reg.*
	LET comando = 'umask 0002; fglgo gen_tra_ele ', base_ori CLIPPED, ' ',
			serv_ori CLIPPED, ' ', vg_codcia, ' ', vg_codloc, ' "',
			r_reg.cod_tran, '" ', r_reg.num_tran, ' ', tip_doc
	IF tip_doc = "NDC" OR tip_doc = "NCC" THEN
		LET comando = comando CLIPPED, ' ', r_reg.codcli
	END IF
	RUN comando CLIPPED
	LET cont = cont + 1
END FOREACH
DROP TABLE t1
CASE tip_doc
	WHEN "FAI" LET nom_doc = "Facturas Inventario"
	WHEN "FAT" LET nom_doc = "Facturas Taller"
	WHEN "NCI" LET nom_doc = "Notas Credito Inventario"
	WHEN "NCT" LET nom_doc = "Notas Credito Taller"
	--WHEN "RTC" LET nom_doc = "Retenciones Clientes"
	WHEN "RTP" LET nom_doc = "Retenciones Proveedores"
	WHEN "GRI" LET nom_doc = "Guias de Remision"
	WHEN "NDC" LET nom_doc = "Notas Debito"
	WHEN "NCC" LET nom_doc = "Notas Credito Clientes"
END CASE
DISPLAY " "
IF cont > 0 THEN
	DISPLAY "  Generado un total de ", cont USING "<<<<&&", " ",
		nom_doc CLIPPED, "."
ELSE
	DISPLAY "  No se generaron ", nom_doc CLIPPED, "."
END IF
LET vm_tot_reg = vm_tot_reg + cont

END FUNCTION



FUNCTION preparar_query(tip_doc)
DEFINE tip_doc		CHAR(3)
DEFINE query		CHAR(1800)

CASE tip_doc
	WHEN "FAI"
		LET query = 'SELECT r19_cod_tran AS cod_tran, ',
					'r19_num_tran AS num_tran, ',
					'r19_codcli AS codcli ',
				'FROM rept019 ',
				'WHERE r19_compania     = ', vg_codcia,
				'  AND r19_localidad    = ', vg_codloc,
				'  AND r19_cod_tran     = "FA" ',
				'  AND DATE(r19_fecing) = DATE("', fecha, '") ',
				expr_sql("r19_fecing") CLIPPED, ' ',
				'INTO TEMP t1'
	WHEN "FAT"
		LET query = 'SELECT "F" AS cod_tran, ',
					't23_num_factura AS num_tran, ',
					't23_cod_cliente AS codcli ',
				'FROM talt023 ',
				'WHERE t23_compania          = ', vg_codcia,
				'  AND t23_localidad         = ', vg_codloc,
				'  AND t23_estado            = "F" ',
				'  AND DATE(t23_fec_factura) = DATE("', fecha,
								'") ',
				expr_sql("t23_fec_factura") CLIPPED, ' ',
				'INTO TEMP t1'
	WHEN "NCI"
		LET query = 'SELECT r19_cod_tran AS cod_tran, ',
					'r19_num_tran AS num_tran, ',
					'r19_codcli AS codcli ',
				'FROM rept019 ',
				'WHERE r19_compania     = ', vg_codcia,
				'  AND r19_localidad    = ', vg_codloc,
				'  AND r19_cod_tran     = "DF" ',
				'  AND DATE(r19_fecing) = DATE("', fecha, '") ',
				expr_sql("r19_fecing") CLIPPED, ' ',
				'INTO TEMP t1'
	WHEN "NCT"
		LET query = 'SELECT "D" AS cod_tran, ',
					't28_num_dev AS num_tran, ',
					't23_cod_cliente AS codcli ',
				'FROM talt023, talt028 ',
				'WHERE t23_compania        = ', vg_codcia,
				'  AND t23_localidad       = ', vg_codloc,
				'  AND t23_estado          = "D" ',
				'  AND t28_compania        = t23_compania ',
				'  AND t28_localidad       = t23_localidad ',
				'  AND t28_factura         = t23_num_factura ',
				'  AND t28_ot_ant          = t23_orden ',
				'  AND DATE(t28_fec_anula) = DATE("', fecha,
								'") ',
				expr_sql("t28_fec_anula") CLIPPED, ' ',
				'INTO TEMP t1'
	WHEN "RTC"
		LET query = 'SELECT j14_tipo_fuente AS cod_tran, ',
					'j14_num_fuente AS num_tran, ',
					'0 AS codcli ',
				'FROM cajt014 ',
				'WHERE j14_compania     = ', vg_codcia,
				'  AND j14_localidad    = ', vg_codloc,
				'  AND DATE(j14_fecing) = DATE("', fecha, '") ',
				expr_sql("j14_fecing") CLIPPED, ' ',
				'GROUP BY 1, 2, 3 ',
				'INTO TEMP t1'
	WHEN "RTP"
		LET query = 'SELECT "CR" AS cod_tran, ',
					'p27_num_ret AS num_tran, ',
					'0 AS codcli ',
				'FROM cxpt027 ',
				'WHERE p27_compania     = ', vg_codcia,
				'  AND p27_localidad    = ', vg_codloc,
				'  AND p27_estado       = "A" ',
				'  AND DATE(p27_fecing) = DATE("', fecha, '") ',
				expr_sql("p27_fecing") CLIPPED, ' ',
				'INTO TEMP t1'
	WHEN "GRI"
		LET query = 'SELECT "GR" AS cod_tran, ',
					'r95_guia_remision AS num_tran, ',
					'0 AS codcli ',
				'FROM rept095 ',
				'WHERE r95_compania     = ', vg_codcia,
				'  AND r95_localidad    = ', vg_codloc,
				'  AND r95_estado       = "C" ',
				'  AND DATE(r95_fecing) = DATE("', fecha, '") ',
				expr_sql("r95_fecing") CLIPPED, ' ',
				'INTO TEMP t1'
	WHEN "NDC"
		LET query = 'SELECT z20_tipo_doc AS cod_tran, ',
					'z20_num_doc AS num_tran, ',
					'z20_codcli AS codcli ',
				'FROM cxct020 ',
				'WHERE z20_compania  = ', vg_codcia,
				'  AND z20_localidad = ', vg_codloc,
				'  AND z20_tipo_doc  = "ND" ',
				'  AND z20_dividendo = 1 ',
				'  AND z20_fecha_emi = DATE("', fecha, '") ',
				expr_sql("z20_fecing") CLIPPED, ' ',
				'INTO TEMP t1'
	WHEN "NCC"
		LET query = 'SELECT z21_tipo_doc AS cod_tran, ',
					'z21_num_doc AS num_tran, ',
					'z21_codcli AS codcli ',
				'FROM cxct021 ',
				'WHERE z21_compania  = ', vg_codcia,
				'  AND z21_localidad = ', vg_codloc,
				'  AND z21_tipo_doc  = "NC" ',
				'  AND z21_fecha_emi = DATE("', fecha, '") ',
				'  AND z21_origen    = "M" ',
				expr_sql("z21_fecing") CLIPPED, ' ',
				'INTO TEMP t1'
END CASE
RETURN query CLIPPED

END FUNCTION



FUNCTION expr_sql(campo)
DEFINE campo		VARCHAR(20)
DEFINE expr		VARCHAR(250)

LET expr = NULL
IF num_args() > 5 THEN
	LET expr = '  AND EXTEND(', campo CLIPPED, ', HOUR TO MINUTE) ',
			'BETWEEN "', hor_ini, '" AND "', hor_fin, '" '
	IF hor_fin IS NULL THEN
		LET expr = '  AND EXTEND(', campo CLIPPED,
				', HOUR TO MINUTE) >= "', hor_ini, '" '
	END IF
END IF
RETURN expr CLIPPED

END FUNCTION
