--------------------------------------------------------------------------------
-- Titulo           : repp326.4gl - Facturas para comisión
-- Elaboracion      : 07-Jul-2011
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp326 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par		RECORD
				anio		SMALLINT,
				mes		SMALLINT,
				tit_mes		VARCHAR(11)
			END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp326.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp326'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu   = 0
LET row_ini    = 3
LET num_rows   = 06
LET num_cols   = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp326 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf326 FROM "../forms/repf326_1"
ELSE
	OPEN FORM f_repf326 FROM "../forms/repf326_1c"
END IF
DISPLAY FORM f_repf326
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()

CALL borrar_cabecera()
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_proceso()
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repp326
EXIT PROGRAM

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR anio, mes, tit_mes
INITIALIZE rm_par.* TO NULL

END FUNCTION



FUNCTION lee_parametros()
DEFINE mes_a		SMALLINT

LET rm_par.anio = YEAR(TODAY)
LET rm_par.mes  = MONTH(TODAY)
IF rm_par.mes = 1 THEN
	LET rm_par.mes  = 12
	LET rm_par.anio = rm_par.anio - 1
ELSE
	LET rm_par.mes  = rm_par.mes - 1
END IF
CALL fl_retorna_nombre_mes(rm_par.mes) RETURNING rm_par.tit_mes
LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(mes) THEN
			CALL fl_ayuda_mostrar_meses()
				RETURNING rm_par.mes, rm_par.tit_mes
			IF rm_par.mes IS NOT NULL THEN
				DISPLAY BY NAME rm_par.mes, rm_par.tit_mes
			END IF
                END IF
	AFTER FIELD mes
		IF rm_par.mes IS NULL THEN
			LET rm_par.mes = mes_a
			DISPLAY BY NAME rm_par.mes
		END IF
		CALL fl_retorna_nombre_mes(rm_par.mes) RETURNING rm_par.tit_mes
		DISPLAY BY NAME rm_par.tit_mes
END INPUT

END FUNCTION



FUNCTION control_proceso()
DEFINE mensaje		VARCHAR(250)
DEFINE query		CHAR(6000)
DEFINE cuantos		INTEGER
DEFINE fecha		DATETIME YEAR TO MONTH

LET fecha = EXTEND(MDY(rm_par.mes, 01, rm_par.anio), YEAR TO MONTH)
ERROR 'Procesando Facturas a crédito ... '
SELECT z20_compania cia_d, z20_localidad loc_d, z20_codcli cli_d,
		z20_tipo_doc tipo_d, z20_num_doc num_d, z20_cod_tran cod_d,
		z20_num_tran num_t,
		NVL(SUM((z20_saldo_cap + z20_saldo_int)), 0) saldo_doc
	FROM cxct020
	WHERE z20_compania                          = vg_codcia
	  AND z20_localidad                         = vg_codloc
	  AND z20_tipo_doc                          = 'FA'
	  AND z20_areaneg                           = 1
	  AND EXTEND(z20_fecha_emi, YEAR TO MONTH) <= fecha
	GROUP BY 1, 2, 3, 4, 5, 6, 7
	HAVING SUM((z20_saldo_cap + z20_saldo_int)) = 0
	INTO TEMP tmp_z20
SELECT COUNT(*) INTO cuantos FROM tmp_z20
IF cuantos = 0 THEN
	ERROR '                                  '
	DROP TABLE tmp_z20
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
ERROR 'Procesando Movimientos Facturas a crédito ... '
SELECT cia_d, loc_d, cod_d, num_t,
		(SELECT g10_codcobr
			FROM gent010
			WHERE g10_compania  = cia_d
			  AND g10_codcobr   = cli_d
			  AND g10_cont_cred = "R") cli_tar,
		MAX(DATE(z22_fecing)) fec_pago
	FROM tmp_z20, cxct022, cxct023
	WHERE z23_compania  = cia_d
	  AND z23_localidad = loc_d
	  AND z23_codcli    = cli_d
	  AND z23_tipo_doc  = tipo_d
	  AND z23_num_doc   = num_d
	  AND (z23_valor_cap + z23_valor_int + z23_saldo_cap
		+ z23_saldo_int) = 0
	  AND z22_compania  = z23_compania
	  AND z22_localidad = z23_localidad
	  AND z22_codcli    = z23_codcli
	  AND z22_tipo_trn  = z23_tipo_trn
	  AND z22_num_trn   = z23_num_trn
	  AND z22_fecing    =
			(SELECT MAX(z22_fecing)
				FROM cxct023, cxct022
				WHERE z23_compania   = cia_d
				  AND z23_localidad  = loc_d
				  AND z23_codcli     = cli_d
				  AND z23_tipo_doc   = tipo_d
				  AND z23_num_doc    = num_d
				  AND z22_compania   = z23_compania
				  AND z22_localidad  = z23_localidad
				  AND z22_codcli     = z23_codcli
				  AND z22_tipo_trn   = z23_tipo_trn
				  AND z22_num_trn    = z23_num_trn
		  		  AND EXTEND(z22_fecing, YEAR TO MONTH) = fecha)
	GROUP BY 1, 2, 3, 4, 5
	INTO TEMP tmp_pag
DROP TABLE tmp_z20
SELECT COUNT(*) INTO cuantos FROM tmp_pag
IF cuantos = 0 THEN
	ERROR '                        '
	DROP TABLE tmp_pag
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
ERROR 'Procesando Facturas Inventario ... '
LET query = 'SELECT rept019.*, r01_iniciales ',
		'FROM rept019, rept001 ',
		'WHERE r19_compania       = ', vg_codcia,
		'  AND r19_localidad      = ', vg_codloc,
		'  AND (r19_cod_tran      = "DF" ',
		'   OR (r19_cod_tran      = "FA" ',
		'  AND (r19_tipo_dev     IS NULL ',
		'   OR  r19_tipo_dev      = "DF"))) ',
		'  AND r19_codcli        <> 101 ',
		'  AND r19_cont_cred      = "C" ',
		'  AND EXTEND(r19_fecing, YEAR TO MONTH) = "',
			rm_par.anio USING "&&&&",'-', rm_par.mes USING "&&",'"',
		'  AND r01_compania       = r19_compania ',
		'  AND r01_codigo         = r19_vendedor ',
		'  AND NOT EXISTS ',
			'(SELECT 1 FROM tmp_pag ',
				'WHERE cia_d = r19_compania ',
				'  AND loc_d = r19_localidad ',
				'  AND cod_d = r19_cod_tran ',
				'  AND num_t = r19_num_tran) ',
		' UNION ',
		'SELECT rept019.*, r01_iniciales ',
		'FROM rept019, rept001 ',
		'WHERE r19_compania       = ', vg_codcia,
		'  AND r19_localidad      = ', vg_codloc,
		'  AND (r19_cod_tran      = "DF" ',
		'   OR (r19_cod_tran      = "FA" ',
		'  AND (r19_tipo_dev     IS NULL ',
		'   OR  r19_tipo_dev      = "DF"))) ',
		'  AND r19_codcli        <> 101 ',
		'  AND r19_cont_cred      = "C" ',
		'  AND YEAR(r19_fecing)  >= YEAR(TODAY) - 1 ',
		'  AND r01_compania       = r19_compania ',
		'  AND r01_codigo         = r19_vendedor ',
		'  AND EXISTS ',
			'(SELECT 1 FROM tmp_pag ',
				'WHERE cia_d   = r19_compania ',
				'  AND loc_d   = r19_localidad ',
				'  AND cod_d   = r19_cod_tran ',
				'  AND num_t   = r19_num_tran ',
				'  AND cli_tar IS NOT NULL) ',
		' UNION ',
		'SELECT rept019.*, r01_iniciales ',
		'FROM rept019, rept001 ',
		'WHERE r19_compania       = ', vg_codcia,
		'  AND r19_localidad      = ', vg_codloc,
		'  AND (r19_cod_tran      = "DF" ',
		'   OR (r19_cod_tran      = "FA" ',
		'  AND (r19_tipo_dev     IS NULL ',
		'   OR  r19_tipo_dev      = "DF"))) ',
		'  AND r19_codcli        <> 101 ',
		'  AND r19_cont_cred      = "R" ',
		'  AND r01_compania       = r19_compania ',
		'  AND r01_codigo         = r19_vendedor ',
		'  AND EXISTS ',
			'(SELECT 1 FROM tmp_pag ',
				'WHERE cia_d = r19_compania ',
				'  AND loc_d = r19_localidad ',
				'  AND cod_d = r19_cod_tran ',
				'  AND num_t = r19_num_tran) ',
		'INTO TEMP t1 '
PREPARE exec_r19_1 FROM query
EXECUTE exec_r19_1
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos = 0 THEN
	ERROR '                        '
	DROP TABLE t1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
ERROR 'Eliminando Facturas totalmente devueltas ... '
SELECT * FROM t1 a
	WHERE NOT EXISTS
		(SELECT 1 FROM rept019 b
			WHERE b.r19_compania  = a.r19_compania
			  AND b.r19_localidad = a.r19_localidad
			  AND b.r19_tipo_dev  = a.r19_cod_tran
			  AND b.r19_num_dev   = a.r19_num_tran
			  AND b.r19_tot_bruto = a.r19_tot_bruto)
	INTO TEMP tmp_r19
DROP TABLE t1
ERROR 'Procesando Facturas detalle ... '
LET query = 'SELECT * FROM rept020 ',
		'WHERE r20_compania      = ', vg_codcia,
		'  AND r20_localidad     = ', vg_codloc,
		'  AND r20_cod_tran     IN ("FA", "DF", "AF") ',
		'  AND EXISTS ',
			'(SELECT 1 FROM tmp_r19 ',
				'WHERE r19_compania  = r20_compania ',
				'  AND r19_localidad = r20_localidad ',
				'  AND r19_cod_tran  = r20_cod_tran ',
				'  AND r19_num_tran  = r20_num_tran) ',
		'INTO TEMP tmp_r20 '
PREPARE exec_r20 FROM query
EXECUTE exec_r20
LET query = 'SELECT r19_compania cia, r19_localidad loc, r01_iniciales agt, ',
			'r19_cod_tran codtran, r19_num_tran numtran, ',
			'NVL(r19_codcli, 99) codcli, r19_nomcli nombre, ',
			'DATE(r20_fecing) fecha_fact, ',
			'CASE WHEN r19_cont_cred = "C" THEN "CONTADO" ',
			     'WHEN r19_cont_cred = "R" THEN "CREDITO" ',
			     'ELSE "" ',
			'END formapago, ',
			'CASE WHEN r19_cont_cred = "R" ',
				'THEN (SELECT MAX(z20_fecha_vcto) ',
					'FROM cxct020 ',
					'WHERE z20_compania  = r19_compania ',
					'  AND z20_localidad = r19_localidad ',
					'  AND z20_codcli    = r19_codcli ',
					'  AND z20_cod_tran  = r19_cod_tran ',
					'  AND z20_num_tran  = r19_num_tran ',
					'  AND z20_areaneg   = 1) ',
				'ELSE DATE(r20_fecing) ',
			'END fecha_vcto, ',
			'r20_item coditem, ',
			'CASE WHEN r19_cod_tran = "FA" ',
				'THEN NVL(r20_cant_ven, 0) ',
				'ELSE NVL(r20_cant_ven, 0) * (-1) ',
			'END can_vta, ',
			'r20_precio pvp, r20_descuento por_dscto, ',
			'r20_val_descto val_dscto, ',
			'CASE WHEN r19_cod_tran = "FA" THEN ',
				'NVL(((r20_cant_ven * r20_precio) - ',
					'r20_val_descto), 0) ',
				'ELSE NVL(((r20_cant_ven * r20_precio) - ',
					'r20_val_descto), 0) * (-1) ',
			'END val_vta, ',
			'NVL((SELECT r88_num_fact ',
				'FROM rept088 ',
				'WHERE r88_compania     = r19_compania ',
				'  AND r88_localidad    = r19_localidad ',
				'  AND r88_cod_fact_nue = r19_cod_tran ',
				'  AND r88_num_fact_nue = r19_num_tran), ',
			'"") fac_ant, ',
			'NVL(DATE((SELECT r19_fecing ',
				'FROM rept088, rept019 repm ',
				'WHERE repm.r19_compania  = r88_compania ',
				'  AND repm.r19_localidad = r88_localidad ',
				'  AND repm.r19_cod_tran  = r88_cod_fact ',
				'  AND repm.r19_num_tran  = r88_num_fact ',
				'  AND r88_compania       = r19m.r19_compania ',
				'  AND r88_localidad      = r19m.r19_localidad',
				'  AND r88_cod_fact_nue   = r19m.r19_cod_tran ',
				'  AND r88_num_fact_nue   = r19m.r19_num_tran',
			')), "") fech_ant, ',
			'r19_tipo_dev tipodev, r19_num_dev numdev ',
		'FROM tmp_r19 r19m, tmp_r20 ',
		'WHERE r20_compania  = r19_compania ',
		'  AND r20_localidad = r19_localidad ',
		'  AND r20_cod_tran  = r19_cod_tran ',
		'  AND r20_num_tran  = r19_num_tran ',
		'INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DROP TABLE tmp_r19
DROP TABLE tmp_r20
ERROR 'Generando Archivo de las Facturas ... '
LET query = 'SELECT a.loc, ',
			'(SELECT r73_desc_marca ',
				'FROM rept073 ',
				'WHERE r73_compania = r10_compania ',
				'  AND r73_marca    = r10_marca) marca, ',
			'r10_filtro filtro, a.agt, ',
			'a.codtran, a.numtran, a.codcli, a.nombre, ',
			'TO_CHAR(a.fecha_fact, "%d/%m/%Y") fecha_fact, ',
			'a.formapago, ',
			'TO_CHAR(a.fecha_vcto, "%d/%m/%Y") fecha_vcto, ',
			'r72_cod_clase clase, r72_desc_clase nombre_clase, ',
			'a.coditem, r10_nombre nombre_item, a.can_vta, a.pvp, ',
			'por_dscto, ', --r77_multiplic multip, ',
			'TO_CHAR(NVL((SELECT MAX(fec_pago) ',
				'FROM tmp_pag ',
				'WHERE cia_d = a.cia ',
				'  AND loc_d = a.loc ',
				'  AND cod_d = a.codtran ',
				 ' AND num_t = a.numtran), ',
				'a.fecha_fact), "%d/%m/%Y") fec_pago, ',
			'a.val_dscto, a.val_vta, a.fac_ant, ',
			'CASE WHEN a.fech_ant IS NOT NULL ',
				'THEN TO_CHAR(DATE(a.fech_ant), "%d/%m/%Y") ',
			'END fech_ant, ',
			'CASE WHEN (SELECT UNIQUE b.tipodev ',
					'FROM t1 b ',
					'WHERE b.cia     = a.cia ',
					'  AND b.loc     = a.loc ',
					'  AND b.codtran = a.tipodev ',
					'  AND b.numtran = a.numdev ',
					'  AND b.coditem = a.coditem) ',
							'IN ("DF", "FA") ',
				'THEN tipodev ',
				'ELSE "" ',
			'END tipodev, ',
			'CASE WHEN (SELECT UNIQUE b.tipodev ',
					'FROM t1 b ',
					'WHERE b.cia     = a.cia ',
					'  AND b.loc     = a.loc ',
					'  AND b.codtran = a.tipodev ',
					'  AND b.numtran = a.numdev ',
					'  AND b.coditem = a.coditem) ',
							'IN ("DF", "FA") ',
				'THEN numdev ',
			'END numdev ',
		'FROM t1 a, rept010, rept072 ',--, rept077 ',
		'WHERE r10_compania    = a.cia ',
		'  AND r10_codigo      = a.coditem ',
		'  AND r72_compania    = r10_compania ',
		'  AND r72_linea       = r10_linea ',
		'  AND r72_sub_linea   = r10_sub_linea ',
		'  AND r72_cod_grupo   = r10_cod_grupo ',
		'  AND r72_cod_clase   = r10_cod_clase ',
		{--
		'  AND r77_compania    = r10_compania ',
		'  AND r77_codigo_util = r10_cod_util ',
		--}
		'INTO TEMP t2 '
PREPARE exec_t2 FROM query
EXECUTE exec_t2
DROP TABLE t1
DROP TABLE tmp_pag
UNLOAD TO "../../../tmp/arch326.unl" DELIMITER "	"
	SELECT * FROM t2
		ORDER BY 4 ASC, 3 ASC, 7 ASC, 5 ASC
DROP TABLE t2
RUN 'echo "LOC	MARCA	FILTRO	AGT	CODTRAN	NUMTRAN	CODCLI	NOMBRE	FECHA_FACT	FORMAPAGO	FECHA_VCTO	CLASE	NOMBRE_CLASE	CODITEM	NOMBRE_ITEM	CAN_VTA	PVP	POR_DSCTO	FEC_PAGO	VAL_DSCTO	VAL_VTA	FAC_ANT	FECH_ANT	TIPODEV	NUMDEV	" > ../../../tmp/cab326.unl'
RUN "cat ../../../tmp/cab326.unl ../../../tmp/arch326.unl > ../../../tmp/repp326.unl"
RUN "rm ../../../tmp/cab326.unl ../../../tmp/arch326.unl"
RUN "mv ../../../tmp/repp326.unl $HOME/tmp/"
RUN "unix2dos $HOME/tmp/repp326.unl"
LET mensaje = FGL_GETENV("HOME"), '/tmp/repp326.unl'
CALL fl_mostrar_mensaje('Archivo Generado en: ' || mensaje, 'info')
ERROR ' '

END FUNCTION
