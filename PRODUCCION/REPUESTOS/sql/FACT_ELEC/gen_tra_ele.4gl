DATABASE aceros


DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)
DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran
DEFINE vm_num_tran	VARCHAR(15)
DEFINE vm_codcli	LIKE cxct001.z01_codcli
DEFINE vm_tip_doc	CHAR(3)



MAIN

	IF num_args() <> 7 AND num_args() <> 8 THEN
		DISPLAY 'Parametros Incorrectos. SON: BASE SERVIDOR COMPANIA',
			' LOCALIDAD COD_TRAN NUM_TRAN TIP_DOC o CODCLI.'
		EXIT PROGRAM
	END IF
	LET base_ori    = arg_val(1)
	LET serv_ori    = arg_val(2)
	LET vg_codcia   = arg_val(3)
	LET vg_codloc   = arg_val(4)
	LET vm_cod_tran = arg_val(5)
	LET vm_num_tran = arg_val(6)
	LET vm_tip_doc  = arg_val(7)
	IF num_args() = 8 THEN
		LET vm_codcli = arg_val(8)
	END IF
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
DEFINE query		CHAR(1500)

CALL activar_base(base_ori, serv_ori)
SET ISOLATION TO DIRTY READ
LET query = preparar_query()
PREPARE exec_t1 FROM query
EXECUTE exec_t1
CASE vm_tip_doc
	WHEN "FAI" CALL gen_xml_elect("fact_elec_inv")
	WHEN "FAT" CALL gen_xml_elect("fact_elec_tal")
	WHEN "NCI" CALL gen_xml_elect("nc_elec_inv")
	WHEN "NCT" CALL gen_xml_elect("nc_elec_tal")
	--WHEN "RTC" CALL gen_xml_elect("rt_elec_cli")
	WHEN "RTP" CALL gen_xml_elect("rt_elec_prov")
	WHEN "GRI" CALL gen_xml_elect("guia_elec_inv")
	WHEN "NDC" CALL gen_xml_elect("nd_elec_cli")
	WHEN "NCC" CALL gen_xml_elect("nc_elec_cli")
END CASE
DROP TABLE t1

END FUNCTION



FUNCTION preparar_query()
DEFINE query		CHAR(1500)

CASE vm_tip_doc
	WHEN "FAI" LET query = 'SELECT "FT" AS cod, ',
				'g02_numruc AS ruc, ',
				'LPAD(g02_serie_cia, 3, 0) AS estab, ',
				'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
				{--
				'LPAD(NVL((SELECT TRIM(r38_num_sri[9, 21]) ',
					'FROM rept038 ',
					'WHERE r38_compania   = r19_compania ',
					'  AND r38_localidad  = r19_localidad ',
					'  AND r38_tipo_doc   = "',vm_cod_tran,
								 '" ',
					'  AND r38_tipo_fuente= "PR" ',
					'  AND r38_cod_tran  = r19_cod_tran ',
					'  AND r38_num_tran  = r19_num_tran), ',
					'0), 9, 0) AS secuencial, ',
				--}
				'LPAD(r19_num_tran, 9, 0) AS secuencial, ',
				'EXTEND(r19_fecing, DAY TO DAY) AS dia, ',
				'EXTEND(r19_fecing, MONTH TO MONTH) AS mes, ',
				'EXTEND(r19_fecing, YEAR TO YEAR) AS anio, ',
				'EXTEND(r19_fecing, HOUR TO HOUR) AS hora, ',
				'EXTEND(r19_fecing,MINUTE TO MINUTE) AS minu, ',
				'EXTEND(r19_fecing, SECOND TO SECOND) AS segu ',
				'FROM rept019, gent002 ',
				'WHERE r19_compania  = ', vg_codcia,
				'  AND r19_localidad = ', vg_codloc,
				'  AND r19_cod_tran  = "', vm_cod_tran, '" ',
				'  AND r19_num_tran  = ', vm_num_tran,
				'  AND g02_compania  = r19_compania ',
				'  AND g02_localidad = r19_localidad ',
				'INTO TEMP t1'
	WHEN "FAT" LET query = 'SELECT "FT" AS cod, ',
				'g02_numruc AS ruc, ',
				'LPAD(g02_serie_cia, 3, 0) AS estab, ',
				'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
				{--
				'LPAD(NVL((SELECT TRIM(r38_num_sri[9, 21]) ',
					'FROM rept038 ',
					'WHERE r38_compania    = t23_compania ',
					'  AND r38_localidad   = t23_localidad',
					'  AND r38_tipo_doc    = "FA" ',
					'  AND r38_tipo_fuente = "OT" ',
					'  AND r38_cod_tran    = "FA" ',
					'  AND r38_num_tran    = t23_num_factura), ',
					'0), 9, 0) AS secuencial, ',
				--}
				'LPAD(t23_num_factura, 9, 0) AS secuencial, ',
				'EXTEND(t23_fec_factura, DAY TO DAY) AS dia, ',
				'EXTEND(t23_fec_factura, MONTH TO MONTH) AS mes, ',
				'EXTEND(t23_fec_factura, YEAR TO YEAR) AS anio, ',
				'EXTEND(t23_fec_factura, HOUR TO HOUR) AS hora, ',
				'EXTEND(t23_fec_factura,MINUTE TO MINUTE) AS minu, ',
				'EXTEND(t23_fec_factura, SECOND TO SECOND) AS segu ',
				'FROM talt023, gent002 ',
				'WHERE t23_compania    = ', vg_codcia,
				'  AND t23_localidad   = ', vg_codloc,
				'  AND t23_estado      = "', vm_cod_tran, '" ',
				'  AND t23_num_factura = ', vm_num_tran,
				'  AND g02_compania    = t23_compania ',
				'  AND g02_localidad   = t23_localidad ',
				'INTO TEMP t1'
	WHEN "NCI" LET query = 'SELECT "NC" AS cod, ',
				'g02_numruc AS ruc, ',
				'LPAD(g02_serie_cia, 3, 0) AS estab, ',
				'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
				'LPAD(NVL((SELECT z21_num_doc ',
					'FROM cxct021 ',
					'WHERE z21_compania  = r19_compania ',
					'  AND z21_localidad = r19_localidad ',
					'  AND z21_codcli    = r19_codcli ',
					'  AND z21_tipo_doc  = "NC" ',
					'  AND z21_cod_tran  = r19_cod_tran ',
					'  AND z21_num_tran  = r19_num_tran), ',
					'0), 9, 0) AS secuencial, ',
				'EXTEND(r19_fecing, DAY TO DAY) AS dia, ',
				'EXTEND(r19_fecing, MONTH TO MONTH) AS mes, ',
				'EXTEND(r19_fecing, YEAR TO YEAR) AS anio, ',
				'EXTEND(r19_fecing, HOUR TO HOUR) AS hora, ',
				'EXTEND(r19_fecing,MINUTE TO MINUTE) AS minu, ',
				'EXTEND(r19_fecing, SECOND TO SECOND) AS segu ',
				'FROM rept019, gent002 ',
				'WHERE r19_compania  = ', vg_codcia,
				'  AND r19_localidad = ', vg_codloc,
				'  AND r19_cod_tran  = "', vm_cod_tran, '" ',
				'  AND r19_num_tran  = ', vm_num_tran,
				'  AND g02_compania  = r19_compania ',
				'  AND g02_localidad = r19_localidad ',
				'INTO TEMP t1'
	WHEN "NCT" LET query = 'SELECT "NC" AS cod, ',
				'g02_numruc AS ruc, ',
				'LPAD(g02_serie_cia, 3, 0) AS estab, ',
				'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
				'LPAD(NVL((SELECT z21_num_doc ',
					'FROM cxct021 ',
					'WHERE z21_compania  = t23_compania ',
					'  AND z21_localidad = t23_localidad ',
					'  AND z21_codcli    = t23_cod_cliente ',
					'  AND z21_tipo_doc  = "NC" ',
					'  AND z21_cod_tran  = "FA" ',
					'  AND z21_num_tran  = t23_num_factura), ',
					'0), 9, 0) AS secuencial, ',
				'EXTEND(t28_fec_anula, DAY TO DAY) AS dia, ',
				'EXTEND(t28_fec_anula, MONTH TO MONTH) AS mes, ',
				'EXTEND(t28_fec_anula, YEAR TO YEAR) AS anio, ',
				'EXTEND(t28_fec_anula, HOUR TO HOUR) AS hora, ',
				'EXTEND(t28_fec_anula,MINUTE TO MINUTE) AS minu, ',
				'EXTEND(t28_fec_anula, SECOND TO SECOND) AS segu ',
				'FROM talt028, talt023, gent002 ',
				'WHERE t28_compania    = ', vg_codcia,
				'  AND t28_localidad   = ', vg_codloc,
				'  AND t28_num_dev     = ', vm_num_tran,
				'  AND t23_compania    = t28_compania ',
				'  AND t23_localidad   = t28_localidad ',
				'  AND t23_orden       = t28_ot_ant ',
				'  AND t23_num_factura = t28_factura ',
				'  AND t23_estado      = "', vm_cod_tran, '" ',
				'  AND g02_compania    = t23_compania ',
				'  AND g02_localidad   = t23_localidad ',
				'INTO TEMP t1'
	WHEN "RTC" LET query = 'SELECT "CR" AS cod, ',
				'g02_numruc AS ruc, ',
				'LPAD(g02_serie_cia, 3, 0) AS estab, ',
				'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
				{--
				'LPAD(NVL(TRIM(j14_num_ret_sri[9, 21]), ',
					'0), 9, 0) AS secuencial, ',
				--}
				'LPAD(j14_num_fuente, 9, 0) AS secuencial, ',
				'EXTEND(j14_fecha_emi, DAY TO DAY) AS dia, ',
				'EXTEND(j14_fecha_emi, MONTH TO MONTH) AS mes,',
				'EXTEND(j14_fecha_emi, YEAR TO YEAR) AS anio, ',
				'EXTEND(j14_fecha_emi, HOUR TO HOUR) AS hora, ',
				'EXTEND(j14_fecha_emi,MINUTE TO MINUTE) AS minu, ',
				'EXTEND(j14_fecha_emi, SECOND TO SECOND) AS segu ',
				'FROM cajt014, gent002 ',
				'WHERE j14_compania    = ', vg_codcia,
				'  AND j14_localidad   = ', vg_codloc,
				'  AND j14_tipo_fuente = "', vm_cod_tran, '" ',
				'  AND j14_num_fuente  = ', vm_num_tran,
				'  AND g02_compania    = j14_compania ',
				'  AND g02_localidad   = j14_localidad ',
				'GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ',
				'INTO TEMP t1'
	WHEN "RTP" LET query = 'SELECT "CR" AS cod, ',
				'g02_numruc AS ruc, ',
				'LPAD(g02_serie_cia, 3, 0) AS estab, ',
				'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
				{--
				'LPAD(NVL(TRIM(p29_num_sri[9, 21]), ',
					'0), 9, 0) AS secuencial, ',
				--}
				'LPAD(p27_num_ret, 9, 0) AS secuencial, ',
				'EXTEND(p27_fecing, DAY TO DAY) AS dia, ',
				'EXTEND(p27_fecing, MONTH TO MONTH) AS mes,',
				'EXTEND(p27_fecing, YEAR TO YEAR) AS anio, ',
				'EXTEND(p27_fecing, HOUR TO HOUR) AS hora, ',
				'EXTEND(p27_fecing,MINUTE TO MINUTE) AS minu, ',
				'EXTEND(p27_fecing, SECOND TO SECOND) AS segu ',
				'FROM cxpt027, cxpt029, gent002 ',
				'WHERE p27_compania  = ', vg_codcia,
				'  AND p27_localidad = ', vg_codloc,
				'  AND p27_num_ret   = ', vm_num_tran,
				'  AND p27_estado    = "A" ',
				'  AND p29_compania  = p27_compania ',
				'  AND p29_localidad = p27_localidad ',
				'  AND p29_num_ret   = p27_num_ret ',
				'  AND g02_compania  = p29_compania ',
				'  AND g02_localidad = p29_localidad ',
				'INTO TEMP t1'
	WHEN "GRI" LET query = 'SELECT "GR" AS cod, ',
				'g02_numruc AS ruc, ',
				'LPAD(g02_serie_cia, 3, 0) AS estab, ',
				'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
				{--
				'LPAD(NVL(TRIM(r95_num_sri[9, 21]), ',
					'0), 9, 0) AS secuencial, ',
				--}
				'LPAD(r95_guia_remision, 9, 0) AS secuencial, ',
				'EXTEND(r95_fecing, DAY TO DAY) AS dia, ',
				'EXTEND(r95_fecing, MONTH TO MONTH) AS mes,',
				'EXTEND(r95_fecing, YEAR TO YEAR) AS anio, ',
				'EXTEND(r95_fecing, HOUR TO HOUR) AS hora, ',
				'EXTEND(r95_fecing,MINUTE TO MINUTE) AS minu, ',
				'EXTEND(r95_fecing, SECOND TO SECOND) AS segu ',
				'FROM rept095, gent002 ',
				'WHERE r95_compania      = ', vg_codcia,
				'  AND r95_localidad     = ', vg_codloc,
				'  AND r95_guia_remision = ', vm_num_tran,
				'  AND r95_estado        = "C" ',
				'  AND g02_compania      = r95_compania ',
				'  AND g02_localidad     = r95_localidad ',
				'INTO TEMP t1'
	WHEN "NDC" LET query = 'SELECT "ND" AS cod, ',
				'g02_numruc AS ruc, ',
				'LPAD(g02_serie_cia, 3, 0) AS estab, ',
				'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
				{--
				'LPAD(NVL(TRIM(z20_num_sri[9, 21]), ',
					'0), 9, 0) AS secuencial, ',
				--}
				'LPAD(CAST(z20_num_doc AS INTEGER), 9, 0) AS secuencial, ',
				'EXTEND(z20_fecha_emi, DAY TO DAY) AS dia, ',
				'EXTEND(z20_fecha_emi, MONTH TO MONTH) AS mes,',
				'EXTEND(z20_fecha_emi, YEAR TO YEAR) AS anio, ',
				'EXTEND(z20_fecha_emi, HOUR TO HOUR) AS hora, ',
				'EXTEND(z20_fecha_emi,MINUTE TO MINUTE) AS minu, ',
				'EXTEND(z20_fecha_emi, SECOND TO SECOND) AS segu ',
				'FROM cxct020, gent002 ',
				'WHERE z20_compania  = ', vg_codcia,
				'  AND z20_localidad = ', vg_codloc,
				'  AND z20_codcli    = ', vm_codcli,
				'  AND z20_tipo_doc  = "', vm_cod_tran, '" ',
				'  AND z20_num_doc   = "', vm_num_tran, '" ',
				'  AND z20_dividendo = 1 ',
				'  AND g02_compania  = z20_compania ',
				'  AND g02_localidad = z20_localidad ',
				'INTO TEMP t1'
	WHEN "NCC" LET query = 'SELECT "NC" AS cod, ',
				'g02_numruc AS ruc, ',
				'LPAD(g02_serie_cia, 3, 0) AS estab, ',
				'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
				{--
				'LPAD(NVL(TRIM(z21_num_sri[9, 21]), ',
					'0), 9, 0) AS secuencial, ',
				--}
				'LPAD(z21_num_doc, 9, 0) AS secuencial, ',
				'EXTEND(z21_fecha_emi, DAY TO DAY) AS dia, ',
				'EXTEND(z21_fecha_emi, MONTH TO MONTH) AS mes,',
				'EXTEND(z21_fecha_emi, YEAR TO YEAR) AS anio, ',
				'EXTEND(z21_fecha_emi, HOUR TO HOUR) AS hora, ',
				'EXTEND(z21_fecha_emi,MINUTE TO MINUTE) AS minu, ',
				'EXTEND(z21_fecha_emi, SECOND TO SECOND) AS segu ',
				'FROM cxct021, gent002 ',
				'WHERE z21_compania  = ', vg_codcia,
				'  AND z21_localidad = ', vg_codloc,
				'  AND z21_codcli    = ', vm_codcli,
				'  AND z21_tipo_doc  = "', vm_cod_tran, '" ',
				'  AND z21_num_doc   = ', vm_num_tran,
				'  AND z21_origen    = "M" ',
				'  AND g02_compania  = z21_compania ',
				'  AND g02_localidad = z21_localidad ',
				'INTO TEMP t1'
END CASE
RETURN query CLIPPED

END FUNCTION



FUNCTION gen_xml_elect(prog)
DEFINE prog		VARCHAR(15)
DEFINE r_reg		RECORD
				codtran		VARCHAR(2),
				rucemp		VARCHAR(13),
				establ		VARCHAR(3),
				ptoemi		VARCHAR(3),
				secuen		VARCHAR(9),
				dia		VARCHAR(2),
				mes		VARCHAR(2),
				anio		VARCHAR(4),
				hora		VARCHAR(2),
				minuto		VARCHAR(2),
				segundo		VARCHAR(2)
			END RECORD
DEFINE comando		CHAR(600)
DEFINE carpeta		VARCHAR(10)

INITIALIZE r_reg.* TO NULL
SELECT * INTO r_reg.* FROM t1
IF r_reg.codtran IS NULL THEN
	RETURN
END IF
LET comando = 'umask 0002; fglgo ', prog CLIPPED, ' ', base_ori CLIPPED, ' ',
		serv_ori CLIPPED, ' ', vg_codcia, ' ', vg_codloc, ' "',
		vm_cod_tran, '" ', vm_num_tran
IF vm_tip_doc = "NDC" OR vm_tip_doc = "NCC" THEN
	LET comando = comando CLIPPED, ' ', vm_codcli
END IF
CASE vm_tip_doc
	WHEN "FAI" LET carpeta = "FA_ELEC"
	WHEN "FAT" LET carpeta = "FA_ELEC"
	WHEN "NCI" LET carpeta = "NC_ELEC"
	WHEN "NCT" LET carpeta = "NC_ELEC"
	WHEN "RTC" LET carpeta = "RT_ELEC"
	WHEN "RTP" LET carpeta = "RT_ELEC"
	WHEN "GRI" LET carpeta = "GR_ELEC"
	WHEN "NDC" LET carpeta = "ND_ELEC"
	WHEN "NCC" LET carpeta = "NC_ELEC"
END CASE
LET comando = comando CLIPPED, ' > /u/acero/fobos/tmp/',
		carpeta CLIPPED, '/', r_reg.*, '.xml'
RUN comando CLIPPED
LET comando = 'cp -rf /u/acero/fobos/tmp/', carpeta CLIPPED,'/', r_reg.*,
		'.xml ', '/u/acero/fobos/tmp/DOCUMENTOSELECTRONICOS/'
RUN comando CLIPPED

END FUNCTION
