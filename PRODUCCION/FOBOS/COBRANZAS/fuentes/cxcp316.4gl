--------------------------------------------------------------------------------
-- Titulo           : cxcp316.4gl - Analisis de Venta vs. Cobranza
-- Elaboracion      : 18-Sep-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp316 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo		CHAR(1)
DEFINE rm_par		RECORD
				fecha_ini	DATE,
				fecha_fin	DATE,
				area_n          LIKE gent003.g03_areaneg,
				tit_area        LIKE gent003.g03_nombre,
				localidad	LIKE gent002.g02_localidad,
				tit_localidad	LIKE gent002.g02_nombre,
				vendedor	LIKE rept019.r19_vendedor,
				tit_vendedor	LIKE rept001.r01_nombres,
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli
			END RECORD
DEFINE rm_par2		RECORD
				fecha_ini	DATETIME YEAR TO MONTH,
				fecha_fin	DATETIME YEAR TO MONTH,
				area_n          LIKE gent003.g03_areaneg,
				tit_area        LIKE gent003.g03_nombre,
				localidad	LIKE gent002.g02_localidad,
				tit_localidad	LIKE gent002.g02_nombre,
				vendedor	LIKE rept019.r19_vendedor,
				tit_vendedor	LIKE rept001.r01_nombres,
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli
			END RECORD
DEFINE rm_det1		ARRAY[15000] OF RECORD
				cod_cli		LIKE cxct001.z01_codcli,
				nom_cli		LIKE cxct001.z01_nomcli,
				valor_vta	DECIMAL(12,2),
				valor_apr	DECIMAL(12,2),
				valor_cob	DECIMAL(12,2),
				valor_dif	DECIMAL(12,2)
			END RECORD
DEFINE rm_det2		ARRAY[300] OF RECORD
				periodo		DATETIME YEAR TO MONTH,
				valor_vta	DECIMAL(12,2),
				valor_apr	DECIMAL(12,2),
				valor_cob	DECIMAL(12,2),
				valor_dif	DECIMAL(12,2),
				margen		DECIMAL(8,2)
			END RECORD
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE rm_color		ARRAY[10] OF VARCHAR(10)
DEFINE rm_z60		RECORD LIKE cxct060.*
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_divisor	SMALLINT
DEFINE tot_col1		DECIMAL(14,2)
DEFINE tot_col2		DECIMAL(12,2)
DEFINE tot_col3		DECIMAL(12,2)
DEFINE tot_col4		DECIMAL(12,2)
DEFINE tot_col5		DECIMAL(8,2)
DEFINE vm_max_rows	INTEGER
DEFINE vm_num_rows	INTEGER
DEFINE vm_num_res	INTEGER
DEFINE tit_precision	VARCHAR(30)
DEFINE tit_edad		VARCHAR(54)
DEFINE vm_fecha_ini	DATE
DEFINE vm_pan, vm_arr	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp316.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp316'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING rm_z60.*
IF rm_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
CREATE TEMP TABLE tmp_cobven1
	(
		codcli		INTEGER,
		nomcli		VARCHAR(100),
		val_vta		DECIMAL(12,2),
		val_apr		DECIMAL(12,2),
		val_cob		DECIMAL(12,2),
		val_dif		DECIMAL(12,2)
	)
CREATE TEMP TABLE tmp_cobven2
	(
		period		DATE,
		val_vta		DECIMAL(12,2),
		val_apr		DECIMAL(12,2),
		val_cob		DECIMAL(12,2),
		val_dif		DECIMAL(12,2),
		marg		DECIMAL(8,2)
	)
CREATE TEMP TABLE tmp_doc_vta
	(
		localidad	SMALLINT,
		areaneg		SMALLINT,
		cod_tran	CHAR(2),
		num_tran	DECIMAL(15,0),
		fecha		DATE,
		valor_neto	DECIMAL(12,2),
		valor_apro	DECIMAL(12,2),
		valor_cobr	DECIMAL(12,2),
		usuario_apr	VARCHAR(10),
		cli		INTEGER,
		nom		VARCHAR(100),
		vend		SMALLINT,
		period		DATETIME YEAR TO MONTH
	)
CREATE TEMP TABLE tmp_doc_cob
	(
		localid		SMALLINT,
		area_neg	SMALLINT,
		tipo_trn	CHAR(2),
		num_trn		DECIMAL(15,0),
		fecha		DATE,
		tipo_doc	CHAR(2),
		num_doc		VARCHAR(15),
		divid		SMALLINT,
		referencia	VARCHAR(40),
		valor_cobr	DECIMAL(12,2),
		cli_cr		INTEGER,
		nom_cr		VARCHAR(100),
		vend		SMALLINT,
		period		DATETIME YEAR TO MONTH,
		c_tran		CHAR(2),
		n_tran		DECIMAL(15,0)
	)
INITIALIZE rm_par.*, vm_fecha_ini TO NULL
LET vm_max_rows       = 15000
LET vm_fecha_ini      = rm_z60.z60_fecha_carga
LET rm_par.fecha_ini  = MDY(MONTH(TODAY), 01, YEAR(TODAY))
IF vm_fecha_ini > rm_par.fecha_ini THEN
	LET rm_par.fecha_ini = vm_fecha_ini + 1 UNITS DAY
END IF
LET rm_par.fecha_fin  = TODAY
LET vm_divisor        = 1
LET vm_tipo           = NULL
CALL mover_parametros(1)
CALL pantalla_principal()
IF int_flag THEN
	RETURN
END IF
IF vm_tipo = 'P' THEN
	LET rm_par2.fecha_ini = MDY(01, 01, YEAR(TODAY))
	IF vm_fecha_ini > rm_par2.fecha_ini THEN
		LET rm_par2.fecha_ini = vm_fecha_ini + 1 UNITS DAY
	END IF
END IF
LET vm_num_res = 0
CALL carga_colores()
MENU "OPCIONES"
	BEFORE MENU
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Precisión'
		--HIDE OPTION 'Grafico'
		HIDE OPTION 'Tipo Consulta'
		HIDE OPTION 'Imprimir'
		CALL control_consulta()
		IF vm_num_res > 0 THEN
			CALL control_detalle()
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Precisión'
			--SHOW OPTION 'Grafico'
			SHOW OPTION 'Tipo Consulta'
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY("C") "Consultar"
		CALL control_consulta()
		IF vm_num_res = 0 THEN
			HIDE OPTION 'Detalle'
			HIDE OPTION 'Precisión'
			--HIDE OPTION 'Grafico'
			HIDE OPTION 'Tipo Consulta'
			HIDE OPTION 'Imprimir'
		ELSE
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Precisión'
			--SHOW OPTION 'Grafico'
			SHOW OPTION 'Tipo Consulta'
			SHOW OPTION 'Imprimir'
		END IF
		IF vm_num_res > 0 THEN
			CALL control_detalle()
		END IF
	COMMAND KEY("P") "Precisión"
		CALL control_precision()
	COMMAND KEY('T') 'Tipo Consulta'
		CALL pantalla_principal()
		IF NOT int_flag THEN
			CALL control_tablas_temporales()
			CALL control_detalle()
		END IF
		LET int_flag = 0
	COMMAND KEY("D") "Detalle"
		CALL control_detalle()
	{--
	COMMAND KEY('G') 'Grafico'
		CALL muestra_grafico_barras()
	--}
	COMMAND KEY('K') 'Imprimir'
		CALL control_imprimir()
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION pantalla_principal()

OPEN WINDOW w_cxcp316_1 AT 08, 31 WITH 07 ROWS, 18 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
OPEN FORM f_cons_1 FROM '../forms/cxcf316_1'
DISPLAY FORM f_cons_1
IF vm_tipo IS NULL THEN
	LET vm_tipo = 'C'
END IF
LET int_flag = 0
INPUT BY NAME vm_tipo
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
END INPUT
CLOSE WINDOW w_cxcp316_1
IF int_flag THEN
	RETURN
END IF
CASE vm_tipo
	WHEN 'C' LET vm_max_rows = 15000
	WHEN 'P' LET vm_max_rows = 300
END CASE
LET int_flag = 0
OPEN WINDOW w_cxcp316_2 AT 03, 02 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vm_tipo = 'C' THEN
	OPEN FORM f_cons_2 FROM '../forms/cxcf316_2'
ELSE
	OPEN FORM f_cons_2 FROM '../forms/cxcf316_3'
END IF
DISPLAY FORM f_cons_2
DISPLAY BY NAME rm_par.*
CALL muestra_titulos()

END FUNCTION



FUNCTION control_consulta()

CASE vm_tipo
	WHEN 'C' CALL lee_parametros1()
		 CALL mover_parametros(1)
	WHEN 'P' CALL lee_parametros2()
		 CALL mover_parametros(2)
END CASE
IF int_flag THEN
	RETURN
END IF
CALL posicion_inicial_arreglo()
DELETE FROM tmp_cobven1
DELETE FROM tmp_cobven2
CALL control_tablas_temporales()

END FUNCTION



FUNCTION control_tablas_temporales()
DEFINE query		VARCHAR(600)
DEFINE ctos1, ctos2	INTEGER

CALL posicion_inicial_arreglo()
SELECT COUNT(*) INTO ctos1 FROM tmp_cobven1
SELECT COUNT(*) INTO ctos2 FROM tmp_cobven2
IF ctos1 = 0 AND ctos2 = 0 THEN
	CALL genera_tabla_trabajo_detalle()
	IF vm_num_res = 0 THEN
		RETURN
	END IF
ELSE
	DELETE FROM tmp_cobven1
	DELETE FROM tmp_cobven2
	SELECT cli codcli, nom nomcli, period peri,
		NVL(SUM(valor_neto), 0) val_n, NVL(SUM(valor_apro), 0) val_a,
		NVL(SUM(valor_cobr), 0) val_c, NVL(SUM(valor_neto), 0) val_d
		FROM tmp_doc_vta
		GROUP BY 1, 2, 3
		INTO TEMP t1
	UPDATE t1 SET val_c = 0 WHERE 1 = 1
	INSERT INTO t1
		SELECT cli_cr ccli, nom_cr ncli, period perid, 0.00, 0.00,
			NVL(SUM(valor_cobr), 0) val_c,
			NVL(SUM(valor_cobr), 0) * (-1) val_d
			FROM tmp_doc_cob
			GROUP BY 1, 2, 3, 4, 5
	SELECT codcli, nomcli, peri, NVL(SUM(val_n), 0) val_n,
		NVL(SUM(val_a), 0) val_a, NVL(SUM(val_c), 0) val_c,
		NVL(SUM(val_d), 0) val_d
		FROM t1
		GROUP BY 1, 2, 3
		INTO TEMP t2
	DROP TABLE t1
	DELETE FROM t2 WHERE val_n = 0 AND val_a = 0 AND val_c = 0
	CASE vm_tipo
		WHEN 'C'
			INSERT INTO tmp_cobven1
				SELECT codcli, nomcli, NVL(SUM(val_n), 0) val_n,
					NVL(SUM(val_a), 0) val_a,
					NVL(SUM(val_c), 0) val_c,
					NVL(SUM(val_d), 0) val_d
					FROM t2
					GROUP BY 1, 2
			SELECT COUNT(*) INTO vm_num_res FROM tmp_cobven1
		WHEN 'P'
			SELECT peri, NVL(SUM(val_n), 0) val_n,
				NVL(SUM(val_a), 0) val_a,
				NVL(SUM(val_c), 0) val_c,
				NVL(SUM(val_d), 0) val_d
				FROM t2
				GROUP BY 1
				INTO TEMP t3
			LET query = 'INSERT INTO tmp_cobven2 ',
					' SELECT peri, val_n, val_a, val_c, ',
						' val_d, ',
						' CASE WHEN val_n <> 0 THEN ',
							'NVL(val_c * 100 ',
								'/ val_n, 0)',
						' ELSE 0 ',
						' END ',
						' FROM t3 '
			PREPARE exec_cobven1 FROM query
			EXECUTE exec_cobven1
			SELECT COUNT(*) INTO vm_num_res FROM tmp_cobven2
			DROP TABLE t3
	END CASE
	DROP TABLE t2
END IF
CALL carga_arreglo_trabajo()

END FUNCTION



FUNCTION posicion_inicial_arreglo()
DEFINE i		SMALLINT

LET vm_pan = 1
LET vm_arr = 1
FOR i = 1 TO 10
	LET rm_orden[i] = ''
END FOR
CASE vm_tipo
	WHEN 'C'
		LET vm_columna_1 = 3
		LET vm_columna_2 = 5
		LET rm_orden[3]  = 'DESC'
		LET rm_orden[5]  = 'ASC'
	WHEN 'P'
		LET vm_columna_1 = 1
		LET vm_columna_2 = 4
		LET rm_orden[1]  = 'ASC'
		LET rm_orden[4]  = 'DESC'
END CASE

END FUNCTION



FUNCTION lee_parametros1()
DEFINE resp		CHAR(6)
DEFINE fec_ini, fec_fin	DATE
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE area_aux		LIKE gent003.g03_areaneg
DEFINE tit_area		LIKE gent003.g03_nombre

IF rm_par.codcli IS NULL THEN
	CLEAR codcli, nomcli
END IF
LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.*) THEN
			RETURN
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(area_n) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING area_aux, tit_area
			IF area_aux IS NOT NULL THEN
				LET rm_par.area_n   = area_aux
				LET rm_par.tit_area = tit_area
 				DISPLAY BY NAME rm_par.area_n, rm_par.tit_area
			END IF
		END IF
		IF INFIELD(localidad) THEN
			IF vg_codcia > 1 THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.localidad     = r_g02.g02_localidad
				LET rm_par.tit_localidad = r_g02.g02_nombre
				DISPLAY BY NAME rm_par.localidad,
						rm_par.tit_localidad
			END IF
		END IF
		IF INFIELD(vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'T', 'F')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_par.vendedor     = r_r01.r01_codigo
				LET rm_par.tit_vendedor = r_r01.r01_nombres
				DISPLAY BY NAME rm_par.vendedor,
						rm_par.tit_vendedor
			END IF
		END IF
		IF INFIELD(codcli) THEN
			LET codloc = vg_codloc
			IF rm_par.localidad IS NOT NULL THEN
				LET codloc = rm_par.localidad
			END IF
			CALL fl_ayuda_cliente_localidad(vg_codcia, codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par.codcli = r_z01.z01_codcli
				LET rm_par.nomcli = r_z01.z01_nomcli
				DISPLAY BY NAME rm_par.codcli, rm_par.nomcli
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		IF vg_codcia > 1 THEN
			CALL fl_lee_localidad(vg_codcia, vg_codloc)
				RETURNING r_g02.*
			LET rm_par.localidad     = r_g02.g02_localidad
			LET rm_par.tit_localidad = r_g02.g02_nombre
			DISPLAY BY NAME rm_par.localidad, rm_par.tit_localidad
		END IF
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD fecha_ini 
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_ini
			END IF
			IF rm_par.fecha_ini <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La fecha inicial no puede ser menor a la Fecha de Inicio de las COBRANZAS en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_ini
			END IF
		ELSE
			LET rm_par.fecha_ini = fec_ini     
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
	AFTER FIELD fecha_fin 
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha final no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_fin
			END IF
			IF rm_par.fecha_fin <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La fecha final no puede ser menor a la Fecha de Inicio de las COBRANZAS en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_ini
			END IF
		ELSE
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
	AFTER FIELD area_n
		IF rm_par.area_n IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area_n)
				RETURNING r_an.*
			IF r_an.g03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe area de negocio', 'exclamation')
				NEXT FIELD area_n
			END IF
			LET rm_par.tit_area = r_an.g03_nombre
			DISPLAY BY NAME rm_par.tit_area
		ELSE
			LET rm_par.tit_area = NULL
			DISPLAY BY NAME rm_par.tit_area
		END IF
	AFTER FIELD localidad
		IF vg_codcia > 1 THEN
			CALL fl_lee_localidad(vg_codcia, vg_codloc)
				RETURNING r_g02.*
			LET rm_par.localidad     = r_g02.g02_localidad
			LET rm_par.tit_localidad = r_g02.g02_nombre
			DISPLAY BY NAME rm_par.localidad, rm_par.tit_localidad
			CONTINUE INPUT
		END IF
		IF rm_par.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD localidad
			END IF
			LET rm_par.tit_localidad = r_g02.g02_nombre
			DISPLAY BY NAME rm_par.tit_localidad
		ELSE
			LET rm_par.tit_localidad = NULL
			CLEAR tit_localidad
		END IF
	AFTER FIELD vendedor
		IF rm_par.vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_par.vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('No existe vendedor.','exclamation')
				NEXT FIELD vendedor
			END IF
			LET rm_par.tit_vendedor = r_r01.r01_nombres
			DISPLAY BY NAME rm_par.tit_vendedor
		ELSE
			LET rm_par.tit_vendedor = NULL
			CLEAR tit_vendedor
		END IF
	AFTER FIELD codcli
		IF rm_par.codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD codcli
			END IF
			LET rm_par.nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_par.nomcli
		ELSE
			LET rm_par.nomcli = NULL
			DISPLAY BY NAME rm_par.nomcli
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()
DEFINE resp		CHAR(6)
DEFINE fec_ini, fec_fin	DATE
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE area_aux		LIKE gent003.g03_areaneg
DEFINE tit_area		LIKE gent003.g03_nombre

IF rm_par2.codcli IS NULL THEN
	CLEAR codcli, nomcli
END IF
LET int_flag = 0
INPUT BY NAME rm_par2.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par2.*) THEN
			RETURN
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(area_n) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING area_aux, tit_area
			IF area_aux IS NOT NULL THEN
				LET rm_par2.area_n   = area_aux
				LET rm_par2.tit_area = tit_area
 				DISPLAY BY NAME rm_par2.area_n, rm_par2.tit_area
			END IF
		END IF
		IF INFIELD(vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'T', 'F')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_par2.vendedor     = r_r01.r01_codigo
				LET rm_par2.tit_vendedor = r_r01.r01_nombres
				DISPLAY BY NAME rm_par2.vendedor,
						rm_par2.tit_vendedor
			END IF
		END IF
		IF INFIELD(localidad) THEN
			IF vg_codcia > 1 THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par2.localidad     = r_g02.g02_localidad
				LET rm_par2.tit_localidad = r_g02.g02_nombre
				DISPLAY BY NAME rm_par2.localidad,
						rm_par2.tit_localidad
			END IF
		END IF
		IF INFIELD(codcli) THEN
			LET codloc = vg_codloc
			IF rm_par2.localidad IS NOT NULL THEN
				LET codloc = rm_par2.localidad
			END IF
			CALL fl_ayuda_cliente_localidad(vg_codcia, codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par2.codcli = r_z01.z01_codcli
				LET rm_par2.nomcli = r_z01.z01_nomcli
				DISPLAY BY NAME rm_par2.codcli, rm_par2.nomcli
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		IF vg_codcia > 1 THEN
			CALL fl_lee_localidad(vg_codcia, vg_codloc)
				RETURNING r_g02.*
			LET rm_par2.localidad     = r_g02.g02_localidad
			LET rm_par2.tit_localidad = r_g02.g02_nombre
			DISPLAY BY NAME rm_par2.localidad, rm_par2.tit_localidad
		END IF
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par2.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par2.fecha_fin
	AFTER FIELD fecha_ini 
		IF rm_par2.fecha_ini IS NOT NULL THEN
			IF rm_par2.fecha_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_ini
			END IF
			IF rm_par2.fecha_ini <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La fecha inicial no puede ser menor a la Fecha de Inicio de las COBRANZAS en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_ini
			END IF
		ELSE
			LET rm_par2.fecha_ini = fec_ini     
			DISPLAY BY NAME rm_par2.fecha_ini
		END IF
	AFTER FIELD fecha_fin 
		IF rm_par2.fecha_fin IS NOT NULL THEN
			IF rm_par2.fecha_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha final no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_fin
			END IF
			IF rm_par2.fecha_fin <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La fecha final no puede ser menor a la Fecha de Inicio de las COBRANZAS en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_ini
			END IF
		ELSE
			LET rm_par2.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par2.fecha_fin
		END IF
	AFTER FIELD area_n
		IF rm_par2.area_n IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par2.area_n)
				RETURNING r_an.*
			IF r_an.g03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe area de negocio', 'exclamation')
				NEXT FIELD area_n
			END IF
			LET rm_par2.tit_area = r_an.g03_nombre
			DISPLAY BY NAME rm_par2.tit_area
		ELSE
			LET rm_par2.tit_area = NULL
			DISPLAY BY NAME rm_par2.tit_area
		END IF
	AFTER FIELD localidad
		IF vg_codcia > 1 THEN
			CALL fl_lee_localidad(vg_codcia, vg_codloc)
				RETURNING r_g02.*
			LET rm_par2.localidad     = r_g02.g02_localidad
			LET rm_par2.tit_localidad = r_g02.g02_nombre
			DISPLAY BY NAME rm_par2.localidad, rm_par2.tit_localidad
			CONTINUE INPUT
		END IF
		IF rm_par2.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par2.localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD localidad
			END IF
			LET rm_par2.tit_localidad = r_g02.g02_nombre
			DISPLAY BY NAME rm_par2.tit_localidad
		ELSE
			LET rm_par2.tit_localidad = NULL
			CLEAR tit_localidad
		END IF
	AFTER FIELD vendedor
		IF rm_par2.vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_par2.vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('No existe vendedor.','exclamation')
				NEXT FIELD vendedor
			END IF
			LET rm_par2.tit_vendedor = r_r01.r01_nombres
			DISPLAY BY NAME rm_par2.tit_vendedor
		ELSE
			LET rm_par2.tit_vendedor = NULL
			CLEAR tit_vendedor
		END IF
	AFTER FIELD codcli
		IF rm_par2.codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par2.codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD codcli
			END IF
			LET rm_par2.nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_par2.nomcli
		ELSE
			LET rm_par2.nomcli = NULL
			DISPLAY BY NAME rm_par2.nomcli
		END IF
	AFTER INPUT
		IF rm_par2.fecha_ini > rm_par2.fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION mover_parametros(flag)
DEFINE flag		SMALLINT

CASE flag
	WHEN 1
		LET rm_par2.fecha_ini     = rm_par.fecha_ini
		LET rm_par2.fecha_fin     = rm_par.fecha_fin
		LET rm_par2.area_n        = rm_par.area_n
		LET rm_par2.tit_area      = rm_par.tit_area
		LET rm_par2.localidad     = rm_par.localidad
		LET rm_par2.tit_localidad = rm_par.tit_localidad
		LET rm_par2.vendedor      = rm_par.vendedor
		LET rm_par2.tit_vendedor  = rm_par.tit_vendedor
		LET rm_par2.codcli        = rm_par.codcli
		LET rm_par2.nomcli        = rm_par.nomcli
	WHEN 2
		LET rm_par.fecha_ini      = rm_par2.fecha_ini
		LET rm_par.fecha_fin      = DATE(rm_par2.fecha_fin)
						+ 1 UNITS MONTH - 1 UNITS DAY
		IF rm_par.fecha_fin > TODAY THEN
			LET rm_par.fecha_fin = TODAY
		END IF
		LET rm_par.area_n         = rm_par2.area_n
		LET rm_par.tit_area       = rm_par2.tit_area
		LET rm_par.localidad      = rm_par2.localidad
		LET rm_par.tit_localidad  = rm_par2.tit_localidad
		LET rm_par.vendedor       = rm_par2.vendedor
		LET rm_par.tit_vendedor   = rm_par2.tit_vendedor
		LET rm_par.codcli         = rm_par2.codcli
		LET rm_par.nomcli         = rm_par2.nomcli
END CASE

END FUNCTION



FUNCTION control_precision()

CASE vm_divisor
	WHEN 1    LET vm_divisor = 10
	WHEN 10   LET vm_divisor = 100
	WHEN 100  LET vm_divisor = 1000
	WHEN 1000 LET vm_divisor = 1
END CASE
CALL muestra_titulos()
CALL carga_arreglo_trabajo()

END FUNCTION



FUNCTION muestra_titulos()
DEFINE label		CHAR(7)

CASE vm_divisor
	WHEN 1    LET tit_precision = "Valores expresados en unidades"
	WHEN 10   LET tit_precision = "Valores expresados en decenas"
	WHEN 100  LET tit_precision = "Valores expresados en centenas"
	WHEN 1000 LET tit_precision = "Valores expresados en miles"
END CASE
CASE vm_tipo
	WHEN 'C'
		DISPLAY 'Código'         TO tit_col1
		DISPLAY 'Cliente'        TO tit_col2
		DISPLAY 'Valor Venta'    TO tit_col3
		DISPLAY 'Valor Aprobado' TO tit_col4
		DISPLAY 'Valor Cobrado'  TO tit_col5
		DISPLAY 'Diferencia'     TO tit_col6
	WHEN 'P'
		DISPLAY 'Período'        TO tit_col1
		DISPLAY 'Valor Venta'    TO tit_col2
		DISPLAY 'Valor Aprobado' TO tit_col3
		DISPLAY 'Valor Cobrado'  TO tit_col4
		DISPLAY 'Diferencia'     TO tit_col5
		DISPLAY 'Margen'         TO tit_col6
END CASE
DISPLAY BY NAME tit_precision

END FUNCTION



FUNCTION genera_tabla_trabajo_detalle()
DEFINE fecha_ini	LIKE cxct022.z22_fecing
DEFINE fecha_fin	LIKE cxct022.z22_fecing
DEFINE cuantos		INTEGER
DEFINE query		VARCHAR(600)

DELETE FROM tmp_doc_vta
DELETE FROM tmp_doc_cob
ERROR "Procesando clientes con ventas . . . espere por favor." ATTRIBUTE(NORMAL)
LET vm_num_res = 0
LET fecha_fin  = rm_par.fecha_fin
IF vm_tipo = 'P' THEN
	LET fecha_fin = MDY(MONTH(rm_par.fecha_fin), 01, YEAR(rm_par.fecha_fin))
			+ 1 UNITS MONTH - 1 UNITS DAY
END IF
LET fecha_ini = EXTEND(rm_par.fecha_ini, YEAR TO SECOND)
LET fecha_fin = EXTEND(fecha_fin, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
CALL generar_tabla_temporal_clientes(fecha_ini, fecha_fin)
SELECT COUNT(*) INTO cuantos FROM tmp_cli
IF cuantos = 0 THEN
	CALL fl_mostrar_mensaje('No hay clientes para el analisis en este período.', 'exclamation')
	DROP TABLE tmp_cli
	RETURN
END IF
CALL obtener_resumen_ventas(fecha_ini, fecha_fin)
CALL obtener_resumen_aprobados(fecha_ini, fecha_fin)
CALL obtener_resumen_cobranza(fecha_ini, fecha_fin)
INSERT INTO tmp_doc_vta
	SELECT t2.locali, t2.areaneg, t2.cod_tran, t2.num_tran, t2.fecha,
		t2.val_vta, t4.val_apr, NVL(SUM(a.valor_cobr), 0) valor_cobrad,
		t2.j10_usuario, t2.cli_t, t2.nom_t, t2.vend, t2.v_per
		FROM t2, OUTER tmp_doc_cob a, t4
		WHERE t2.locali   = a.localid
		  AND t2.areaneg  = a.area_neg
		  AND t2.cod_tran = a.c_tran
		  AND t2.num_tran = a.n_tran
		  AND t2.cli_t    = a.cli_cr
		  AND t4.locali   = t2.locali
		  AND t4.areaneg  = t2.areaneg
		  AND t4.cod_tran = t2.cod_tran
		  AND t4.num_tran = t2.num_tran
		  AND t4.cli_t    = t2.cli_t
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13
CASE vm_tipo
	WHEN 'C'
		SELECT loc, codcli, nomcli,
			NVL((SELECT SUM(val_vta) FROM tmp_vta
				WHERE local = loc
				  AND cli   = codcli), 0) val_vta,
			NVL((SELECT SUM(val_apr) FROM tmp_apr
				WHERE local = loc
				  AND cli   = codcli), 0) val_apr,
			NVL((SELECT SUM(val_cob) FROM tmp_cob
				WHERE local = loc
				  AND cli   = codcli), 0) val_cob
			FROM tmp_cli
			GROUP BY 1, 2, 3
			INTO TEMP t1
	WHEN 'P'
		SELECT periodo,
			NVL((SELECT SUM(val_vta) FROM tmp_vta
				WHERE period = periodo), 0) val_vta,
			NVL((SELECT SUM(val_apr) FROM tmp_apr
				WHERE period = periodo), 0) val_apr,
			NVL((SELECT SUM(val_cob) FROM tmp_cob
				WHERE period = periodo), 0) val_cob
			FROM tmp_cli
			GROUP BY 1, 2, 3, 4
			INTO TEMP t1
END CASE
DROP TABLE t2
DROP TABLE t4
DROP TABLE tmp_vta
DROP TABLE tmp_apr
DROP TABLE tmp_cob
DROP TABLE tmp_cli
DELETE FROM t1 WHERE val_vta = 0 AND val_apr = 0 AND val_cob = 0
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE t1
	RETURN
END IF
CASE vm_tipo
	WHEN 'C'
		INSERT INTO tmp_cobven1
			SELECT codcli, nomcli, NVL(SUM(val_vta), 0) val_vta,
				NVL(SUM(val_apr), 0) val_apr,
				NVL(SUM(val_cob), 0) val_cob,
				NVL(SUM(val_vta - val_cob), 0) val_dif
				FROM t1
				GROUP BY 1, 2
		SELECT COUNT(*) INTO vm_num_res FROM tmp_cobven1
	WHEN 'P'
		SELECT periodo, NVL(SUM(val_vta), 0) val_vta,
			NVL(SUM(val_apr), 0) val_apr,
			NVL(SUM(val_cob), 0) val_cob,
			NVL(SUM(ABS(val_vta) - ABS(val_cob)), 0) val_dif
			FROM t1
			GROUP BY 1
			INTO TEMP t2
		LET query = 'INSERT INTO tmp_cobven2 ',
				' SELECT periodo, val_vta, val_apr, val_cob, ',
					' val_dif, ',
					' CASE WHEN val_vta <> 0 THEN ',
					' NVL(val_cob * 100 / val_vta, 0) ',
					' ELSE 0 ',
					' END margen ',
					' FROM t2 '
		PREPARE exec_cobven2 FROM query
		EXECUTE exec_cobven2
		SELECT COUNT(*) INTO vm_num_res FROM tmp_cobven2
		DROP TABLE t2
END CASE
DROP TABLE t1
ERROR ' '

END FUNCTION



FUNCTION generar_tabla_temporal_clientes(fecha_ini, fecha_fin)
DEFINE fecha_ini	LIKE cxct022.z22_fecing
DEFINE fecha_fin	LIKE cxct022.z22_fecing
DEFINE query		CHAR(6000)
DEFINE expr_are		VARCHAR(100)
DEFINE expr_clt		VARCHAR(100)
DEFINE expr_clz		VARCHAR(100)
DEFINE expr_lot		VARCHAR(100)
DEFINE expr_loz		VARCHAR(100)

LET expr_are  = NULL
IF rm_par.area_n IS NOT NULL THEN
	LET expr_are = '   AND z22_areaneg    = ', rm_par.area_n
END IF
LET expr_lot = '   AND t23_localidad    = ', vg_codloc
LET expr_loz = NULL
IF rm_par.localidad IS NOT NULL THEN
	LET expr_lot = '   AND t23_localidad    = ', rm_par.localidad
	LET expr_loz = '   AND z22_localidad    = ', rm_par.localidad
END IF
LET expr_clt = NULL
LET expr_clz = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr_clt = '   AND t23_cod_cliente = ', rm_par.codcli
	LET expr_clz = '   AND z22_codcli      = ', rm_par.codcli
END IF
LET query = query_clientes_ventas(fecha_ini, fecha_fin, 1)
IF vg_codcia = 1 THEN
	LET query = query CLIPPED,
			' UNION ',
			query_clientes_ventas(fecha_ini, fecha_fin, 2)
END IF
LET query = query CLIPPED,
		' UNION ',
		' SELECT UNIQUE t23_compania cia, t23_localidad loc,',
			' t23_cod_cliente codcli, z01_nomcli nomcli, ',
			' EXTEND(t23_fec_factura, YEAR TO MONTH) periodo ',
			' FROM talt023, cxct001 ',
			' WHERE t23_compania     = ', vg_codcia,
			expr_lot CLIPPED,
			'   AND t23_estado       = "F"',
			'   AND t23_cont_cred    = "R" ',
			expr_clt CLIPPED,
			'   AND t23_num_factura  IS NOT NULL ',
			'   AND t23_fec_factura  BETWEEN "', fecha_ini,
						  '" AND "', fecha_fin, '"',
			'   AND z01_codcli       = t23_cod_cliente ',
		' UNION ',
		' SELECT UNIQUE t23_compania cia, t23_localidad loc,',
			' t23_cod_cliente codcli, z01_nomcli nomcli, ',
			' EXTEND(t28_fec_anula, YEAR TO MONTH) periodo ',
			' FROM talt023, talt028, cxct001 ',
			' WHERE t23_compania     = ', vg_codcia,
			expr_lot CLIPPED,
			'   AND t23_estado       = "D"',
			'   AND t23_cont_cred    = "R" ',
			expr_clt CLIPPED,
			'   AND t23_num_factura  IS NOT NULL ',
			'   AND t28_compania     = t23_compania ',
			'   AND t28_localidad    = t23_localidad ',
			'   AND t28_factura      = t23_num_factura ',
			'   AND t28_fec_anula    BETWEEN "', fecha_ini,
						  '" AND "',fecha_fin,'"',
			'   AND z01_codcli       = t23_cod_cliente ',
		' UNION ',
		' SELECT UNIQUE z22_compania cia, z22_localidad loc,',
			' z22_codcli codcli, z01_nomcli nomcli, ',
			' EXTEND(z22_fecing, YEAR TO MONTH) periodo ',
			' FROM cxct022, cxct001 ',
			' WHERE z22_compania     = ', vg_codcia,
			expr_loz CLIPPED,
			expr_clz CLIPPED,
			expr_are CLIPPED,
			'   AND z22_fecing       BETWEEN "', fecha_ini,
					  	  '" AND "', fecha_fin, '"',
			'   AND z01_codcli       = z22_codcli ',
		' INTO TEMP tmp_cli '
PREPARE exec_cli FROM query
EXECUTE exec_cli

END FUNCTION



FUNCTION obtener_resumen_ventas(fecha_ini, fecha_fin)
DEFINE fecha_ini	LIKE cxct022.z22_fecing
DEFINE fecha_fin	LIKE cxct022.z22_fecing
DEFINE query		CHAR(6000)

CALL generar_tabla_temporal_facturas_caja(fecha_ini, fecha_fin)
CALL retorna_query_vta_apr(fecha_ini, fecha_fin, 0) RETURNING query
PREPARE exec_vta FROM query
EXECUTE exec_vta
DELETE FROM t1 WHERE val_vta = 0
SELECT locali, areaneg, cod_tran, num_tran, fecha, val_vta, j10_usuario, cli_t,
	nom_t, vend, EXTEND(fecha, YEAR TO MONTH) v_per
	FROM t1, OUTER tmp_j10
	 WHERE cod_tran         IN ("FA", "NV")
	   AND j10_localidad    = locali
	   AND j10_areaneg      = areaneg
	   AND j10_tipo_destino = cod_tran
	   AND j10_num_destino  = num_tran
	UNION
	SELECT locali, areaneg, cod_tran, num_tran, fecha, val_vta, j10_usuario,
		cli_t, nom_t, vend, EXTEND(fecha, YEAR TO MONTH) v_per
		FROM t1, OUTER tmp_j10
		 WHERE cod_tran         IN ("DF", "AF")
		   AND j10_localidad    = locali
		   AND j10_areaneg      = areaneg
		   AND j10_tipo_destino = tipo_dev
		   AND j10_num_destino  = num_dev
	INTO TEMP t2
DROP TABLE tmp_j10
CASE vm_tipo
	WHEN 'C'
		SELECT local, cli, NVL(SUM(val_vta), 0) val_vta
			FROM t1
			GROUP BY 1, 2
			INTO TEMP tmp_vta
	WHEN 'P'
		SELECT period, NVL(SUM(val_vta), 0) val_vta
			FROM t1
			GROUP BY 1
			INTO TEMP tmp_vta
END CASE
DROP TABLE t1

END FUNCTION



FUNCTION obtener_resumen_aprobados(fecha_ini, fecha_fin)
DEFINE fecha_ini	LIKE cxct022.z22_fecing
DEFINE fecha_fin	LIKE cxct022.z22_fecing
DEFINE query		CHAR(6000)

CALL retorna_query_vta_apr(fecha_ini, fecha_fin, 1) RETURNING query
PREPARE exec_apr FROM query
EXECUTE exec_apr
DELETE FROM t1 WHERE val_apr = 0
SELECT locali, areaneg, cod_tran, num_tran, fecha, val_apr, cli_t, vend,
	EXTEND(fecha, YEAR TO MONTH) v_per
	FROM t1
	INTO TEMP t4
CASE vm_tipo
	WHEN 'C'
		SELECT local, cli, NVL(SUM(val_apr), 0) val_apr
			FROM t1
			GROUP BY 1, 2
			INTO TEMP tmp_apr
	WHEN 'P'
		SELECT period, NVL(SUM(val_apr), 0) val_apr
			FROM t1
			GROUP BY 1
			INTO TEMP tmp_apr
END CASE
DROP TABLE t1

END FUNCTION



FUNCTION obtener_resumen_cobranza(fecha_ini, fecha_fin)
DEFINE fecha_ini	LIKE cxct022.z22_fecing
DEFINE fecha_fin	LIKE cxct022.z22_fecing
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE subquery		CHAR(1200)
DEFINE query		CHAR(6000)
DEFINE expr_are		VARCHAR(100)
DEFINE expr_loz		VARCHAR(100)
DEFINE expr_clz		VARCHAR(100)
DEFINE expr_gru		VARCHAR(100)
DEFINE col_sum		VARCHAR(100)
DEFINE base_vta		VARCHAR(10)

CASE vm_tipo
	WHEN 'C'
		LET col_sum  = 'z22_localidad local, z22_codcli cli'
		LET expr_gru = ' GROUP BY 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, ',
					'13, 14, 15, 16, 17 '
	WHEN 'P'
		LET col_sum  = 'EXTEND(z22_fecing, YEAR TO MONTH) period'
		LET expr_gru = ' GROUP BY 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, ',
					'13, 14, 15, 16 '
END CASE
LET expr_are = NULL
IF rm_par.area_n IS NOT NULL THEN
	LET expr_are = '   AND z22_areaneg     = ', rm_par.area_n
END IF
LET expr_clz = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr_clz = '   AND z22_codcli      = ', rm_par.codcli
END IF
LET expr_loz = NULL
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loz = '   AND z22_localidad    = ', rm_par.localidad
END IF
LET query = 'SELECT ', col_sum CLIPPED, ', z22_tipo_trn tip_trn,',
		' CASE WHEN z22_tipo_trn = "PG" ',
			' THEN NVL(SUM(z23_valor_cap + z23_valor_int),0) *(-1)',
			' ELSE NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' END val_cob, z23_tipo_doc tipo_doc, z23_num_doc num_doc,',
		' z23_div_doc divid, z23_localidad localid,',
		' z22_areaneg area_neg, z23_num_trn num_trn,',
		' DATE(z22_fecing) fecha, z22_referencia referencia,',
		' z22_codcli cli_c, z01_nomcli nom_c, 0 vend, z23_tipo_favor,',
		' z23_doc_favor ',
		' FROM cxct022, cxct023, cxct001 ',
		' WHERE z22_compania   = ', vg_codcia,
		expr_loz CLIPPED,
		expr_clz CLIPPED,
		expr_are CLIPPED,
		'   AND z22_fecing     BETWEEN "', fecha_ini,
					'" AND "', fecha_fin, '"',
		'   AND z01_codcli     = z22_codcli ',
		'   AND z23_compania   = z22_compania ',
		'   AND z23_localidad  = z22_localidad ',
		'   AND z23_codcli     = z22_codcli ',
		'   AND z23_tipo_trn   = z22_tipo_trn ',
		'   AND z23_num_trn    = z22_num_trn ',
		expr_gru CLIPPED,
		' INTO TEMP t3 '
PREPARE exec_t3 FROM query
EXECUTE exec_t3
CASE vm_tipo
	WHEN 'C'
		LET col_sum  = 'local, cli'
	WHEN 'P'
		LET col_sum  = 'period'
END CASE
LET query = 'SELECT ', col_sum CLIPPED, ', tip_trn, ',
		' CASE WHEN tip_trn = "AJ" AND val_cob > 0 ',
			' THEN val_cob * (-1) ',
			' ELSE val_cob ',
		' END val_cob, ',
		' tipo_doc, num_doc, divid, localid, area_neg, num_trn, fecha,',
		' referencia, cli_c, nom_c, vend, z20_cod_tran c_tran,',
		' z20_num_tran n_tran ',
		' FROM t3, OUTER cxct020 ',
		' WHERE z23_tipo_favor IS NULL ',
		'   AND z20_compania   = ', vg_codcia,
		'   AND z20_localidad  = localid ',
		'   AND z20_codcli     = cli_c ',
		'   AND z20_tipo_doc   = tipo_doc ',
		'   AND z20_num_doc    = num_doc ',
		'   AND z20_dividendo  = divid ',
		' UNION ',
		' SELECT ', col_sum CLIPPED, ', tip_trn, val_cob, tipo_doc,',
		' num_doc, divid, localid, area_neg, num_trn, fecha,',
		' referencia, cli_c, nom_c, vend, z21_cod_tran c_tran,',
		' z21_num_tran n_tran ',
		' FROM t3, OUTER cxct021 ',
		' WHERE z23_tipo_favor IS NOT NULL ',
		'   AND z21_compania   = ', vg_codcia,
		'   AND z21_localidad  = localid ',
		'   AND z21_codcli     = cli_c ',
		'   AND z21_tipo_doc   = z23_tipo_favor ',
		'   AND z21_num_doc    = z23_doc_favor ',
		' INTO TEMP tmp_z23 '
PREPARE exec_z23 FROM query
EXECUTE exec_z23
DROP TABLE t3
IF rm_par.vendedor IS NOT NULL THEN
	CASE vm_tipo
		WHEN 'C'
			LET col_sum  = 'local, cli'
			LET expr_gru = ' GROUP BY 1, 2, 4, 5, 6, 7, 8, 9, 10,',
					' 11, 12, 13, 14, 15, 16, 17 '
		WHEN 'P'
			LET col_sum  = 'period'
			LET expr_gru = ' GROUP BY 1, 3, 4, 5, 6, 7, 8, 9,',
					' 10, 11, 12, 13, 14, 15, 16 '
	END CASE
	CASE vg_codloc
		WHEN 1
			LET base_vta = 'acero_gc:'
			LET codloc   = 2
		WHEN 3
			LET base_vta = 'acero_qs:'
			LET codloc   = 4
	END CASE
	LET subquery = NULL
	IF vg_codcia = 1 THEN
		LET subquery = ' UNION ALL ',
			' SELECT ', col_sum CLIPPED,
				', NVL(SUM(val_cob),0) val_cob,',
			' tipo_doc, num_doc, divid, localid, area_neg,tip_trn,',
			' num_trn, fecha, referencia, cli_c, nom_c,',
			' r19_vendedor vend, c_tran, n_tran ',
			' FROM tmp_z23, ', base_vta CLIPPED, 'rept019 ',
			' WHERE area_neg         = 1 ',
			'   AND r19_compania     = ', vg_codcia,
			'   AND r19_localidad    = ', codloc,
			'   AND r19_cod_tran     = c_tran ',
			'   AND r19_num_tran     = n_tran ',
			'   AND r19_vendedor     = ', rm_par.vendedor,
			expr_gru CLIPPED
	END IF
	LET query = 'SELECT ', col_sum CLIPPED,', NVL(SUM(val_cob),0) val_cob,',
			' tipo_doc, num_doc, divid, localid, area_neg,tip_trn,',
			' num_trn, fecha, referencia, cli_c, nom_c,',
			' r19_vendedor vend, c_tran, n_tran ',
			' FROM tmp_z23, rept019 ',
			' WHERE area_neg         = 1 ',
			'   AND r19_compania     = ', vg_codcia,
			'   AND r19_localidad    = ', vg_codloc,
			'   AND r19_cod_tran     = c_tran ',
			'   AND r19_num_tran     = n_tran ',
			'   AND r19_vendedor     = ', rm_par.vendedor,
			expr_gru CLIPPED,
			subquery CLIPPED,
			' UNION ALL ',
			' SELECT ', col_sum CLIPPED,
				', NVL(SUM(val_cob), 0) val_cob, ',
			' tipo_doc, num_doc, divid, localid, area_neg,tip_trn,',
			' num_trn, fecha, referencia, cli_c, nom_c,',
			' t61_cod_vendedor vend, c_tran, n_tran ',
			' FROM tmp_z23, talt023, talt061 ',
			' WHERE area_neg         = 2 ',
			'   AND t23_compania     = ', vg_codcia,
			'   AND t23_localidad    = localid ',
			'   AND t23_num_factura  = n_tran ',
			'   AND t61_compania     = t23_compania ',
			'   AND t61_cod_asesor   = t23_cod_asesor ',
			'   AND t61_cod_vendedor = ', rm_par.vendedor,
			expr_gru CLIPPED,
			' INTO TEMP t1 '
	PREPARE exec_cob FROM query
	EXECUTE exec_cob
	DELETE FROM t1 WHERE val_cob = 0
	INSERT INTO tmp_doc_cob
		SELECT localid, area_neg, tip_trn, num_trn, fecha, tipo_doc,
			num_doc, divid, referencia, val_cob, cli_c, nom_c, vend,
			EXTEND(fecha, YEAR TO MONTH), c_tran, n_tran
			FROM t1
ELSE
	DELETE FROM tmp_z23 WHERE val_cob = 0
	INSERT INTO tmp_doc_cob
		SELECT localid, area_neg, tip_trn, num_trn, fecha, tipo_doc,
			num_doc, divid, referencia, val_cob, cli_c, nom_c, vend,
			EXTEND(fecha, YEAR TO MONTH), c_tran, n_tran
			FROM tmp_z23
	CASE vm_tipo
		WHEN 'C'
			SELECT local, cli, tip_trn, NVL(SUM(val_cob), 0) val_cob
				FROM tmp_z23
				GROUP BY 1, 2, 3
				INTO TEMP t1
		WHEN 'P'
			SELECT period, tip_trn, NVL(SUM(val_cob), 0) val_cob
				FROM tmp_z23
				GROUP BY 1, 2
				INTO TEMP t1
	END CASE
END IF
DROP TABLE tmp_z23
CASE vm_tipo
	WHEN 'C'
		SELECT local, cli, NVL(SUM(val_cob), 0) val_cob
			FROM t1
			GROUP BY 1, 2
			INTO TEMP tmp_cob
	WHEN 'P'
		SELECT period, NVL(SUM(val_cob), 0) val_cob
			FROM t1
			GROUP BY 1
			INTO TEMP tmp_cob
END CASE
DROP TABLE t1

END FUNCTION



FUNCTION generar_tabla_temporal_facturas_caja(fecha_ini, fecha_fin)
DEFINE fecha_ini	LIKE cxct022.z22_fecing
DEFINE fecha_fin	LIKE cxct022.z22_fecing
DEFINE query		CHAR(1600)

LET query = query_facturas_caja(fecha_ini, fecha_fin, 1)
IF vg_codcia = 1 THEN
	LET query = query CLIPPED,
		' UNION ALL ',
		query_facturas_caja(fecha_ini, fecha_fin, 2)
END IF
IF rm_par.localidad IS NOT NULL AND rm_par.localidad <> vg_codloc THEN
	LET query = query_facturas_caja(fecha_ini, fecha_fin, 2)
END IF
LET query = query CLIPPED, ' INTO TEMP tmp_j10 '
PREPARE exec_j10 FROM query
EXECUTE exec_j10

END FUNCTION



FUNCTION query_clientes_ventas(fecha_ini, fecha_fin, flag)
DEFINE fecha_ini	LIKE cxct022.z22_fecing
DEFINE fecha_fin	LIKE cxct022.z22_fecing
DEFINE flag		SMALLINT
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE query		CHAR(800)
DEFINE expr_cli		VARCHAR(100)
DEFINE expr_ven		VARCHAR(100)
DEFINE base_vta		VARCHAR(10)

LET expr_ven = NULL
IF rm_par.vendedor IS NOT NULL THEN
	LET expr_ven = '   AND r19_vendedor   = ', rm_par.vendedor
END IF
LET expr_cli = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr_cli = '   AND r19_codcli      = ', rm_par.codcli
END IF
CASE flag
	WHEN 1
		LET base_vta = NULL
		LET codloc   = vg_codloc
	WHEN 2
		CASE vg_codloc
			WHEN 1
				LET base_vta = 'acero_gc:'
				LET codloc   = 2
			WHEN 3
				LET base_vta = 'acero_qs:'
				LET codloc   = 4
		END CASE
END CASE
LET query = 'SELECT UNIQUE r19_compania cia, r19_localidad loc,',
		' r19_codcli codcli, z01_nomcli nomcli, ',
		' EXTEND(r19_fecing, YEAR TO MONTH) periodo ',
		' FROM ', base_vta CLIPPED, 'rept019, cxct001 ',
		' WHERE r19_compania    = ', vg_codcia,
		'   AND r19_localidad   = ', codloc,
		'   AND r19_cod_tran    IN ("FA", "NV", "DF", "AF") ',
		'   AND r19_cont_cred   = "R" ',
		expr_ven CLIPPED,
		expr_cli CLIPPED,
		'   AND r19_fecing      BETWEEN "', fecha_ini,
					 '" AND "', fecha_fin, '"',
		'   AND z01_codcli      = r19_codcli '
RETURN query CLIPPED

END FUNCTION



FUNCTION query_facturas_caja(fecha_ini, fecha_fin, flag)
DEFINE fecha_ini	LIKE cxct022.z22_fecing
DEFINE fecha_fin	LIKE cxct022.z22_fecing
DEFINE flag		SMALLINT
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE query		CHAR(800)
DEFINE expr_are		VARCHAR(100)
DEFINE expr_cli		VARCHAR(100)
DEFINE base_vta		VARCHAR(10)

LET expr_are = NULL
IF rm_par.area_n IS NOT NULL THEN
	LET expr_are = '   AND j10_areaneg     = ', rm_par.area_n
END IF
LET expr_cli = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr_cli = '   AND j10_codcli      = ', rm_par.codcli
END IF
CASE flag
	WHEN 1
		LET base_vta = NULL
		LET codloc   = vg_codloc
	WHEN 2
		CASE vg_codloc
			WHEN 1
				LET base_vta = 'acero_gc:'
				LET codloc   = 2
			WHEN 3
				LET base_vta = 'acero_qs:'
				LET codloc   = 4
		END CASE
END CASE
LET query = 'SELECT j10_usuario, j10_localidad, j10_areaneg, ',
		' j10_tipo_destino, j10_num_destino ',
		' FROM ', base_vta CLIPPED, 'cajt010 ',
		' WHERE j10_compania    = ', vg_codcia,
		'   AND j10_localidad   = ', codloc,
		expr_cli CLIPPED,
		expr_are CLIPPED,
		'   AND j10_tipo_fuente IN ("PR", "OT") ',
		'   AND j10_estado      IN ("P", "E") ',
		'   AND j10_valor       = 0 ',
		'   AND j10_fecha_pro   BETWEEN "', fecha_ini,
					 '" AND "', fecha_fin, '"'
RETURN query CLIPPED

END FUNCTION



FUNCTION retorna_query_vta_apr(fecha_ini, fecha_fin, tipo)
DEFINE fecha_ini	LIKE cxct022.z22_fecing
DEFINE fecha_fin	LIKE cxct022.z22_fecing
DEFINE tipo		SMALLINT
DEFINE query		CHAR(6000)

LET query = query_venta_aprob(fecha_ini, fecha_fin, 1, tipo) CLIPPED,
		' UNION ALL ',
		query_venta_aprob(fecha_ini, fecha_fin, 2, tipo) CLIPPED,
		' UNION ALL ',
		query_venta_aprob_tal(fecha_ini, fecha_fin, tipo) CLIPPED
IF vg_codcia > 1 OR rm_par.localidad = vg_codloc THEN
	LET query = query_venta_aprob(fecha_ini, fecha_fin, 1, tipo) CLIPPED,
			' UNION ALL ',
			query_venta_aprob_tal(fecha_ini,fecha_fin,tipo) CLIPPED
END IF
IF vg_codcia = 1 AND rm_par.localidad <> vg_codloc THEN
	LET query = query_venta_aprob(fecha_ini, fecha_fin, 2, tipo) CLIPPED
END IF
CASE rm_par.area_n
	WHEN 1
		LET query = query_venta_aprob(fecha_ini, fecha_fin, 1, tipo)
				CLIPPED, ' UNION ALL ',
				query_venta_aprob(fecha_ini, fecha_fin, 2, tipo)
		IF rm_par.localidad = vg_codloc THEN
			LET query = query_venta_aprob(fecha_ini, fecha_fin, 1,
							tipo)
		END IF
		IF rm_par.localidad IS NOT NULL AND
		   rm_par.localidad <> vg_codloc
		THEN
			LET query = query_venta_aprob(fecha_ini, fecha_fin, 2,
							tipo)
		END IF
	WHEN 2
		LET query = query_venta_aprob(fecha_ini, fecha_fin, 1, tipo)
				CLIPPED, ' UNION ALL ',
				query_venta_aprob_tal(fecha_ini, fecha_fin,tipo)
END CASE
LET query = query CLIPPED, ' INTO TEMP t1 '
RETURN query CLIPPED

END FUNCTION



FUNCTION query_venta_aprob(fecha_ini, fecha_fin, flag, flag_join)
DEFINE fecha_ini	LIKE cxct022.z22_fecing
DEFINE fecha_fin	LIKE cxct022.z22_fecing
DEFINE flag, flag_join	SMALLINT
DEFINE query		VARCHAR(2000)
DEFINE base_vta		VARCHAR(10)
DEFINE col_loc		VARCHAR(15)
DEFINE col_sum		VARCHAR(100)
DEFINE col_val 		VARCHAR(200)
DEFINE nom_col		VARCHAR(10)
DEFINE multip		VARCHAR(10)
DEFINE tabla		VARCHAR(25)
DEFINE colad		VARCHAR(250)
DEFINE expr_join	VARCHAR(200)
DEFINE expr_gru		VARCHAR(50)
DEFINE expr_are		VARCHAR(100)
DEFINE expr_ven		VARCHAR(100)
DEFINE expr_cli		VARCHAR(100)
DEFINE codloc		LIKE rept019.r19_localidad

CASE flag
	WHEN 1
		LET base_vta = NULL
		LET codloc   = vg_codloc
		IF rm_par.area_n = 2 AND rm_par.localidad IS NOT NULL THEN
			LET codloc = rm_par.localidad
		END IF
	WHEN 2
		CASE vg_codloc
			WHEN 1
				LET base_vta = 'acero_gc:'
				LET codloc   = 2
			WHEN 3
				LET base_vta = 'acero_qs:'
				LET codloc   = 4
		END CASE
END CASE
LET col_loc   = 'r19_localidad'
LET col_val   = ' CASE WHEN r19_cod_tran = "FA" OR r19_cod_tran = "NV" ',
			' THEN NVL(SUM(r19_tot_neto), 0) ',
			' ELSE NVL(SUM(r19_tot_neto), 0) * (-1) ',
		' END val_vta'
LET multip    = NULL
LET nom_col   = NULL
LET tabla     = NULL
LET expr_join = NULL
IF flag_join THEN
	LET col_loc   = 'r25_localidad'
	LET col_val   =	'NVL(SUM(r25_valor_cred), 0) '
	LET multip    = ' * (-1) '
	LET nom_col   = 'val_apr'
	LET tabla     = ', ', base_vta CLIPPED, 'rept025 '
	LET expr_join = '   AND r25_compania   = r19_compania ',
			'   AND r25_localidad  = r19_localidad ',
			'   AND r25_cod_tran   = r19_cod_tran ',
			'   AND r25_num_tran   = r19_num_tran '
END IF
LET expr_are  = NULL
IF rm_par.area_n = 2 THEN
	LET expr_are = '   AND r19_ord_trabajo IS NOT NULL'
END IF
LET expr_ven  = NULL
IF rm_par.vendedor IS NOT NULL THEN
	LET expr_ven = '   AND r19_vendedor   = ', rm_par.vendedor
END IF
LET expr_cli  = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr_cli = '   AND r19_codcli     = ', rm_par.codcli
END IF
LET col_sum  = col_loc CLIPPED, ' local, r19_codcli cli '
LET expr_gru = ' GROUP BY 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13 '
IF vm_tipo = 'P' THEN
	LET col_sum  = ' EXTEND(r19_fecing, YEAR TO MONTH) period '
	LET expr_gru = ' GROUP BY 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12 '
END IF
LET colad = ', 1 areaneg, r19_num_tran num_tran, DATE(r19_fecing) fecha, ',
		' r19_vendedor vend, r19_localidad locali, r19_codcli cli_t, ',
		' z01_nomcli nom_t, r19_tipo_dev tipo_dev, r19_num_dev num_dev '
LET query = 'SELECT ', col_sum CLIPPED, ', r19_cod_tran cod_tran,',
		col_val CLIPPED, colad CLIPPED,
		' FROM ', base_vta CLIPPED, 'rept019, cxct001 ', tabla CLIPPED,
		' WHERE r19_compania   = ', vg_codcia,
		'   AND r19_localidad  = ', codloc,
		'   AND r19_cod_tran   IN ("FA", "NV", "DF", "AF") ',
		'   AND r19_cont_cred  = "R" ',
		expr_cli CLIPPED,
		expr_are CLIPPED,
		expr_ven CLIPPED,
		'   AND r19_fecing     BETWEEN "', fecha_ini,
					'" AND "', fecha_fin, '"',
		'   AND z01_codcli     = r19_codcli ',
		expr_join CLIPPED,
		expr_gru CLIPPED
IF flag_join THEN
	LET query = 'SELECT ', col_sum CLIPPED, ', r19_cod_tran cod_tran, ',
			col_val CLIPPED, ' ', nom_col CLIPPED, colad CLIPPED,
			' FROM ', base_vta CLIPPED, 'rept019, cxct001 ',
				tabla CLIPPED,
			' WHERE r19_compania   = ', vg_codcia,
			'   AND r19_localidad  = ', codloc,
			'   AND r19_cod_tran   IN ("FA", "NV") ',
			'   AND r19_cont_cred  = "R" ',
			expr_cli CLIPPED,
			expr_are CLIPPED,
			expr_ven CLIPPED,
			'   AND r19_fecing     BETWEEN "', fecha_ini,
						'" AND "', fecha_fin, '"',
			'   AND z01_codcli     = r19_codcli ',
			expr_join CLIPPED,
			expr_gru CLIPPED,
			' UNION ALL ',
			'SELECT ', col_sum CLIPPED, ', r19_cod_tran, ',
				col_val CLIPPED, ' ', multip CLIPPED, ' ',
				nom_col CLIPPED, colad CLIPPED,
			' FROM ', base_vta CLIPPED, 'rept019, cxct001 ',
				tabla CLIPPED,
			' WHERE r19_compania   = ', vg_codcia,
			'   AND r19_localidad  = ', codloc,
			'   AND r19_cod_tran   IN ("DF", "AF") ',
			'   AND r19_cont_cred  = "R" ',
			expr_cli CLIPPED,
			expr_are CLIPPED,
			expr_ven CLIPPED,
			'   AND r19_fecing     BETWEEN "', fecha_ini,
						'" AND "', fecha_fin, '"',
			'   AND z01_codcli     = r19_codcli ',
			'   AND r25_compania   = r19_compania ',
			'   AND r25_localidad  = r19_localidad ',
			'   AND r25_cod_tran   = r19_tipo_dev ',
			'   AND r25_num_tran   = r19_num_dev ',
			expr_gru CLIPPED
END IF
RETURN query CLIPPED

END FUNCTION



FUNCTION query_venta_aprob_tal(fecha_ini, fecha_fin, flag_join)
DEFINE fecha_ini	LIKE cxct022.z22_fecing
DEFINE fecha_fin	LIKE cxct022.z22_fecing
DEFINE flag_join	SMALLINT
DEFINE query		VARCHAR(2500)
DEFINE col_loc		VARCHAR(15)
DEFINE col_val		VARCHAR(200)
DEFINE col_comp1	VARCHAR(250)
DEFINE col_comp2	VARCHAR(250)
DEFINE tabla		VARCHAR(10)
DEFINE tabla_v		VARCHAR(10)
DEFINE expr_join	VARCHAR(200)
DEFINE expr_loc		VARCHAR(100)
DEFINE expr_cli		VARCHAR(100)
DEFINE expr_ven		VARCHAR(150)
DEFINE expr_gru		VARCHAR(50)
DEFINE col_sum		VARCHAR(100)
DEFINE col_sum2		VARCHAR(100)
DEFINE multip		VARCHAR(10)
DEFINE nom_col		VARCHAR(10)

LET col_loc   = 't23_localidad'
LET col_val   =	' NVL(SUM(t23_tot_neto), 0) '
LET multip    = ' * (-1) '
LET nom_col   = ' val_vta'
LET tabla     = NULL
LET expr_join = NULL
IF flag_join THEN
	LET col_loc   = 't25_localidad'
	LET col_val   = ' NVL(SUM(t25_valor_cred), 0) '
	LET nom_col   = ' val_apr'
	LET tabla     = ', talt025 '
	LET expr_join = '   AND t25_compania    = t23_compania ',
			'   AND t25_localidad   = t23_localidad ',
			'   AND t25_orden       = t23_orden '
END IF
LET tabla_v   = NULL
LET expr_ven  = NULL
IF rm_par.vendedor IS NOT NULL THEN
	LET tabla_v   = ', talt061'
	LET expr_ven  = '   AND t61_compania    = t23_compania ',
			'   AND t61_cod_asesor  = t23_cod_asesor ',
			'   AND t61_cod_vendedor= ', rm_par.vendedor
END IF
LET expr_cli  = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr_cli  = '   AND t23_cod_cliente = ', rm_par.codcli
END IF
LET expr_loc  = NULL
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loc = '   AND t23_localidad   = ', rm_par.localidad
END IF
LET col_sum  = col_loc CLIPPED, ' local, t23_cod_cliente cli '
LET col_sum2 = col_sum CLIPPED
LET expr_gru = ' GROUP BY 1, 2, 3 '
IF vm_tipo = 'P' THEN
	LET col_sum  = ' EXTEND(t23_fec_factura, YEAR TO MONTH) period '
	LET col_sum2 = ' EXTEND(t28_fec_anula, YEAR TO MONTH) period '
	LET expr_gru = ' GROUP BY 1, 2 '
END IF
LET col_comp1 = ', 2 areaneg, t23_num_factura num_tran,',
		' DATE(t23_fec_factura) fecha, 0 vend, t23_localidad',
		' locali, t23_cod_cliente cli_t, z01_nomcli nom_t, "FA"',
		' tipo_dev, t23_num_factura num_dev '
LET col_comp2 = ', 2 areaneg, t28_num_dev num_tran, ',
		'DATE(t28_fec_anula) fecha, 0 vend, t23_localidad',
		' locali, t23_cod_cliente cli_t, z01_nomcli nom_t, "FA"',
		' tipo_dev, t23_num_factura num_dev '
LET expr_gru = ' GROUP BY 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13 '
IF vm_tipo = 'P' THEN
	LET expr_gru = ' GROUP BY 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12 '
END IF
LET query = 'SELECT ', col_sum CLIPPED, ', "FA" cod_tran, ',
		col_val CLIPPED, ' ', nom_col CLIPPED, col_comp1 CLIPPED,
		' FROM talt023, cxct001 ', tabla CLIPPED, tabla_v CLIPPED,
		' WHERE t23_compania    = ', vg_codcia,
		expr_loc CLIPPED,
		'   AND t23_estado      IN ("F", "D") ',
		'   AND t23_cont_cred   = "R" ',
		expr_cli CLIPPED,
		'   AND t23_num_factura IS NOT NULL ',
		'   AND t23_fec_factura BETWEEN "', fecha_ini,
					 '" AND "', fecha_fin, '"',
		'   AND z01_codcli      = t23_cod_cliente ',
		expr_ven CLIPPED,
		expr_join CLIPPED,
		expr_gru CLIPPED,
		' UNION ALL ',
		' SELECT ', col_sum2 CLIPPED, ', "DF" cod_tran, ',
			col_val CLIPPED, ' ', multip CLIPPED, ' ',
			nom_col CLIPPED, col_comp2 CLIPPED,
		' FROM talt023, cxct001, talt028 ', tabla CLIPPED,
			tabla_v CLIPPED,
		' WHERE t23_compania    = ', vg_codcia,
		expr_loc CLIPPED,
		'   AND t23_estado      = "D" ',
		'   AND t23_cont_cred   = "R" ',
		expr_cli CLIPPED,
		'   AND t23_num_factura IS NOT NULL ',
		'   AND z01_codcli      = t23_cod_cliente ',
		'   AND t28_compania    = t23_compania ',
		'   AND t28_localidad   = t23_localidad ',
		'   AND t28_factura     = t23_num_factura ',
		'   AND t28_fec_anula   BETWEEN "', fecha_ini,
					 '" AND "', fecha_fin, '"',
		expr_ven CLIPPED,
		expr_join CLIPPED,
		expr_gru CLIPPED
RETURN query CLIPPED

END FUNCTION



FUNCTION carga_arreglo_trabajo()
DEFINE query		VARCHAR(400)
DEFINE i		INTEGER

CASE vm_tipo
	WHEN 'C' SELECT * FROM tmp_cobven1 INTO TEMP tmp_cobven_g
	WHEN 'P' SELECT * FROM tmp_cobven2 INTO TEMP tmp_cobven_g
END CASE
UPDATE tmp_cobven_g
	SET val_vta = val_vta / vm_divisor,
 	    val_apr = val_apr / vm_divisor,
	    val_cob = val_cob / vm_divisor,
	    val_dif = val_dif / vm_divisor
LET query = 'SELECT * FROM tmp_cobven_g ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ',',
			      vm_columna_2, ' ', rm_orden[vm_columna_2] 
PREPARE fin FROM query
DECLARE q_fin CURSOR FOR fin
LET tot_col1 = 0
LET tot_col2 = 0
LET tot_col3 = 0
LET tot_col4 = 0
LET tot_col5 = 0
LET i        = 1
CASE vm_tipo
	WHEN 'C'
		FOREACH q_fin INTO rm_det1[i].*
			LET tot_col1 = tot_col1 + rm_det1[i].valor_vta 
			LET tot_col2 = tot_col2 + rm_det1[i].valor_apr 
			LET tot_col3 = tot_col3 + rm_det1[i].valor_cob 
			LET tot_col4 = tot_col4 + rm_det1[i].valor_dif 
			LET i        = i + 1
			IF i > vm_max_rows THEN
				EXIT FOREACH
			END IF
		END FOREACH
	WHEN 'P'
		FOREACH q_fin INTO rm_det2[i].*
			LET tot_col1 = tot_col1 + rm_det2[i].valor_vta 
			LET tot_col2 = tot_col2 + rm_det2[i].valor_apr 
			LET tot_col3 = tot_col3 + rm_det2[i].valor_cob 
			LET tot_col4 = tot_col4 + rm_det2[i].valor_dif 
			LET i        = i + 1
			IF i > vm_max_rows THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET tot_col5 = 0
		IF tot_col1 <> 0 THEN
			LET tot_col5 = tot_col3 * 100 / tot_col1
		END IF
		DISPLAY BY NAME tot_col5
END CASE
LET vm_num_rows = i - 1
CALL muestra_contadores_det(0, vm_num_rows)
DISPLAY BY NAME tot_col1, tot_col2, tot_col3, tot_col4
CASE vm_tipo
	WHEN 'C'
		FOR i = 1 TO fgl_scr_size ('rm_det1')
			CLEAR rm_det1[i].*
			IF i <= vm_num_rows THEN
				DISPLAY rm_det1[i].* TO rm_det1[i].*
			END IF
		END FOR
	WHEN 'P'
		FOR i = 1 TO fgl_scr_size ('rm_det2')
			CLEAR rm_det2[i].*
			IF i <= vm_num_rows THEN
				DISPLAY rm_det2[i].* TO rm_det2[i].*
			END IF
		END FOR
END CASE
DROP TABLE tmp_cobven_g

END FUNCTION



FUNCTION control_detalle()

CASE vm_tipo
	WHEN 'C'
		CALL muestra_detalle01()
	WHEN 'P'
		CALL muestra_detalle02()
END CASE

END FUNCTION



FUNCTION muestra_detalle01()
DEFINE i, col		INTEGER
DEFINE cod_aux		INTEGER
DEFINE pos_pan, pos_arr	INTEGER
DEFINE flag_p, flag_d	SMALLINT
DEFINE col1, col2	SMALLINT
DEFINE pos1, pos2	CHAR(4)
DEFINE expr_par2	VARCHAR(300)

LET pos_pan = vm_pan
LET pos_arr = vm_arr
LET col     = vm_columna_1
LET col1    = vm_columna_1
LET col2    = vm_columna_2
LET pos1    = rm_orden[col1]
LET pos2    = rm_orden[col2]
LET flag_p  = 0
LET flag_d  = 0
CALL muestra_contadores_det(0, vm_num_rows)
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_rows)
	DISPLAY ARRAY rm_det1 TO rm_det1.*
		ON KEY(INTERRUPT)
			LET vm_pan   = scr_line()
			LET vm_arr   = arr_curr()
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL muestra_detalle_venta(rm_det1[i].cod_cli)
			LET int_flag = 0
		ON KEY(F6)
			LET i         = arr_curr()
			LET expr_par2 = NULL
			CALL muestra_detalle_cobranza(rm_det1[i].cod_cli,
							expr_par2)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL muestra_estado_cuenta(rm_det1[i].cod_cli)
			LET int_flag = 0
		ON KEY(F8)
			CALL control_precision()
			LET pos_pan        = scr_line()
			LET pos_arr        = arr_curr()
			LET col            = col1
			LET vm_columna_1   = col1
			LET vm_columna_2   = col2
			LET rm_orden[col1] = pos1
			LET rm_orden[col2] = pos2
			LET flag_p         = 1
			EXIT DISPLAY
		ON KEY(F9)
			LET i = arr_curr()
			IF rm_par.area_n = 2 THEN
				CONTINUE DISPLAY
			END IF
			IF rm_par.localidad <> vg_codloc THEN
				CONTINUE DISPLAY
			END IF
			CALL muestra_detalle_inventario(rm_det1[i].cod_cli, 1)
			LET int_flag = 0
		ON KEY(F10)
			LET i = arr_curr()
			IF rm_par.area_n = 1 THEN
				CONTINUE DISPLAY
			END IF
			IF rm_par.localidad <> vg_codloc THEN
				CONTINUE DISPLAY
			END IF
			CALL muestra_detalle_taller(rm_det1[i].cod_cli)
			LET int_flag = 0
		ON KEY(F11)
			LET i = arr_curr()
			IF rm_par.localidad = vg_codloc THEN
				CONTINUE DISPLAY
			END IF
			CALL muestra_detalle_inventario(rm_det1[i].cod_cli, 2)
			LET int_flag = 0
		{--
		ON KEY(CONTROL-W)
			CALL muestra_grafico_barras()
		--}
		ON KEY(CONTROL-X)
			CALL control_imprimir()
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("CONTROL-W","Grafico")
			--#CALL dialog.keysetlabel("CONTROL-X","Imprimir Listado")
			CALL dialog.setcurrline(pos_pan, pos_arr)
			CALL muestra_contadores_det(pos_arr, vm_num_rows)
		BEFORE ROW
			LET i = arr_curr()
			CALL muestra_contadores_det(i, vm_num_rows)
			DISPLAY rm_det1[i].cod_cli TO codcli
			DISPLAY rm_det1[i].nom_cli TO nomcli
			IF flag_d THEN
				CALL dialog.setcurrline(pos_pan, pos_arr)
				CALL muestra_contadores_det(pos_arr,
								vm_num_rows)
				DISPLAY rm_det1[pos_arr].cod_cli TO codcli
				DISPLAY rm_det1[pos_arr].nom_cli TO nomcli
				LET flag_d = 0
			END IF
			IF rm_par.localidad <> vg_codloc THEN
				--#CALL dialog.keysetlabel("F9","")
				--#CALL dialog.keysetlabel("F10","")
			ELSE
				--#CALL dialog.keysetlabel("F9","Detalle Inventario")
				--#CALL dialog.keysetlabel("F10","Detalle Taller")
			END IF
			IF rm_par.area_n = 2 THEN
				--#CALL dialog.keysetlabel("F9","")
			ELSE
				--#CALL dialog.keysetlabel("F9","Detalle Inventario")
			END IF
			IF rm_par.area_n = 1 THEN
				--#CALL dialog.keysetlabel("F10","")
			ELSE
				--#CALL dialog.keysetlabel("F10","Detalle Taller")
			END IF
			IF rm_par.localidad = vg_codloc THEN
				--#CALL dialog.keysetlabel("F11","")
			ELSE
				--#CALL dialog.keysetlabel("F11","Detalle Sucursal")
			END IF
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
	CASE flag_p
		WHEN 1
			LET col            = col1
			LET vm_columna_1   = col1
			LET vm_columna_2   = col2
			LET rm_orden[col1] = pos1
			LET rm_orden[col2] = pos2
			LET flag_p         = 0
		WHEN 0
			LET col1   = vm_columna_1
			LET col2   = vm_columna_2
			LET pos1   = rm_orden[col1]
			LET pos2   = rm_orden[col2]
			LET flag_d = 1
	END CASE
	IF flag_d THEN
		LET pos_pan = scr_line()
		LET pos_arr = arr_curr()
		LET cod_aux = rm_det1[pos_arr].cod_cli
	END IF
	CALL carga_arreglo_trabajo()
	IF flag_d THEN
		FOR i = 1 TO vm_num_rows
			IF cod_aux = rm_det1[i].cod_cli THEN
				LET pos_arr = i
				IF vm_num_rows <= fgl_scr_size('rm_det1') THEN
					LET pos_pan = i
				END IF
				EXIT FOR
			END IF
		END FOR
	END IF
END WHILE
CALL muestra_contadores_det(0, vm_num_rows)

END FUNCTION



FUNCTION muestra_detalle02()
DEFINE i, col		INTEGER
DEFINE cod_aux		DATETIME YEAR TO MONTH
DEFINE pos_pan, pos_arr	INTEGER
DEFINE flag_p, flag_d	SMALLINT
DEFINE col1, col2	SMALLINT
DEFINE pos1, pos2	CHAR(4)
DEFINE expr_par2	VARCHAR(300)

LET pos_pan = vm_pan
LET pos_arr = vm_arr
LET col     = vm_columna_1
LET col1    = vm_columna_1
LET col2    = vm_columna_2
LET pos1    = rm_orden[col1]
LET pos2    = rm_orden[col2]
LET flag_p  = 0
LET flag_d  = 0
CALL muestra_contadores_det(0, vm_num_rows)
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_rows)
	DISPLAY ARRAY rm_det2 TO rm_det2.*
		ON KEY(INTERRUPT)
			LET vm_pan   = scr_line()
			LET vm_arr   = arr_curr()
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL muestra_detalle_venta(rm_det2[i].periodo)
			LET int_flag = 0
		ON KEY(F6)
			LET i         = arr_curr()
			LET expr_par2 = NULL
			CALL muestra_detalle_cobranza(rm_det2[i].periodo,
							expr_par2)
			LET int_flag = 0
		ON KEY(F7)
			CALL control_precision()
			LET pos_pan        = scr_line()
			LET pos_arr        = arr_curr()
			LET col            = col1
			LET vm_columna_1   = col1
			LET vm_columna_2   = col2
			LET rm_orden[col1] = pos1
			LET rm_orden[col2] = pos2
			LET flag_p         = 1
			EXIT DISPLAY
		ON KEY(F8)
			LET i = arr_curr()
			IF rm_par2.area_n = 2 THEN
				CONTINUE DISPLAY
			END IF
			IF rm_par2.localidad <> vg_codloc THEN
				CONTINUE DISPLAY
			END IF
			CALL muestra_detalle_inventario(rm_det2[i].periodo, 1)
			LET int_flag = 0
		ON KEY(F9)
			LET i = arr_curr()
			IF rm_par2.area_n = 1 THEN
				CONTINUE DISPLAY
			END IF
			IF rm_par2.localidad <> vg_codloc THEN
				CONTINUE DISPLAY
			END IF
			CALL muestra_detalle_taller(rm_det2[i].periodo)
			LET int_flag = 0
		ON KEY(F10)
			LET i = arr_curr()
			IF rm_par2.localidad = vg_codloc THEN
				CONTINUE DISPLAY
			END IF
			CALL muestra_detalle_inventario(rm_det2[i].periodo, 2)
			LET int_flag = 0
		{--
		ON KEY(F11)
			CALL muestra_grafico_barras()
		--}
		ON KEY(CONTROL-W)
			CALL control_imprimir()
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("CONTROL-W","Imprimir Listado")
			CALL dialog.setcurrline(pos_pan, pos_arr)
			IF pos_arr > vm_num_rows THEN
				LET pos_arr = 1
			END IF
			CALL muestra_contadores_det(pos_arr, vm_num_rows)
		BEFORE ROW
			LET i = arr_curr()
			CALL muestra_contadores_det(i, vm_num_rows)
			IF flag_d THEN
				CALL dialog.setcurrline(pos_pan, pos_arr)
				CALL muestra_contadores_det(pos_arr,
								vm_num_rows)
				LET flag_d = 0
			END IF
			IF rm_par.localidad <> vg_codloc THEN
				--#CALL dialog.keysetlabel("F8","")
				--#CALL dialog.keysetlabel("F9","")
			ELSE
				--#CALL dialog.keysetlabel("F8","Cliente Inventario")
				--#CALL dialog.keysetlabel("F9","Clientes Taller")
			END IF
			IF rm_par2.area_n = 2 THEN
				--#CALL dialog.keysetlabel("F8","")
			ELSE
				--#CALL dialog.keysetlabel("F8","Cliente Inventario")
			END IF
			IF rm_par2.area_n = 1 THEN
				--#CALL dialog.keysetlabel("F9","")
			ELSE
				--#CALL dialog.keysetlabel("F9","Clientes Taller")
			END IF
			IF rm_par2.localidad = vg_codloc THEN
				--#CALL dialog.keysetlabel("F10","")
			ELSE
				--#CALL dialog.keysetlabel("F10","Clientes Sucursal")
			END IF
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
	CASE flag_p
		WHEN 1
			LET col            = col1
			LET vm_columna_1   = col1
			LET vm_columna_2   = col2
			LET rm_orden[col1] = pos1
			LET rm_orden[col2] = pos2
			LET flag_p         = 0
		WHEN 0
			LET col1   = vm_columna_1
			LET col2   = vm_columna_2
			LET pos1   = rm_orden[col1]
			LET pos2   = rm_orden[col2]
			LET flag_d = 1
	END CASE
	IF flag_d THEN
		LET pos_pan = scr_line()
		LET pos_arr = arr_curr()
		LET cod_aux = rm_det2[pos_arr].periodo
	END IF
	CALL carga_arreglo_trabajo()
	IF flag_d THEN
		FOR i = 1 TO vm_num_rows
			IF cod_aux = rm_det2[i].periodo THEN
				LET pos_arr = i
				IF vm_num_rows <= fgl_scr_size('rm_det2') THEN
					LET pos_pan = i
				END IF
				EXIT FOR
			END IF
		END FOR
	END IF
END WHILE
CALL muestra_contadores_det(0, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	INTEGER

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_detalle_venta(parametro)
DEFINE parametro	VARCHAR(10)
DEFINE r_orden		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE max_rows, i, col	SMALLINT
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE tot_neto_inv	DECIMAL(14,2)
DEFINE tot_cobr_inv	DECIMAL(14,2)
DEFINE tot_neto_tal	DECIMAL(14,2)
DEFINE tot_cobr_tal	DECIMAL(14,2)
DEFINE tot_neto		DECIMAL(14,2)
DEFINE tot_cobr		DECIMAL(14,2)
DEFINE tot_saldo	DECIMAL(14,2)
DEFINE expr_par2	VARCHAR(300)
DEFINE param2		VARCHAR(10)
DEFINE expr_par		VARCHAR(100)
DEFINE query		VARCHAR(1200)
DEFINE r_aux		ARRAY[18000] OF RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				vend		LIKE rept001.r01_codigo,
				period		DATETIME YEAR TO MONTH
			END RECORD
DEFINE r_fact		ARRAY[18000] OF RECORD
				localidad	LIKE rept019.r19_localidad,
				areaneg		LIKE gent003.g03_areaneg,
				cod_tran	LIKE rept019.r19_cod_tran,
				num_tran	LIKE rept019.r19_num_tran,
				fecha		DATE,
				valor_neto	LIKE rept019.r19_tot_neto,
				valor_cobr	LIKE cxct022.z22_total_cap,
				saldo		DECIMAL(14,2),
				usuario_apr	LIKE cxct022.z22_usuario
			END RECORD
DEFINE r_r01		RECORD LIKE rept001.*

LET max_rows  = 18000
LET num_rows2 = 19
LET num_cols  = 79
IF vg_gui = 0 THEN
	LET num_rows2 = 16
	LET num_cols  = 78
END IF
OPEN WINDOW w_cxcf316_4 AT 03, 02 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf316_4 FROM "../forms/cxcf316_4"
ELSE
	OPEN FORM f_cxcf316_4 FROM "../forms/cxcf316_4c"
END IF
DISPLAY FORM f_cxcf316_4
--#DISPLAY 'LC'			TO tit_col1 
--#DISPLAY 'AN'			TO tit_col2 
--#DISPLAY 'TP'			TO tit_col3 
--#DISPLAY 'Número'		TO tit_col4 
--#DISPLAY 'Fecha'		TO tit_col5
--#DISPLAY 'Valor Neto'		TO tit_col6 
--#DISPLAY 'Valor Cobrado'	TO tit_col7 
--#DISPLAY 'S a l d o'		TO tit_col8
--#DISPLAY 'User Apr.'		TO tit_col9
CASE vm_tipo
	WHEN 'C'
		LET fecha_ini = rm_par.fecha_ini
		LET fecha_fin = rm_par.fecha_fin
	WHEN 'P'
		LET fecha_ini = MDY(parametro[6, 7], 01, parametro[1, 4])
		LET fecha_fin = fecha_ini
		LET fecha_fin = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
				+ 1 UNITS MONTH - 1 UNITS DAY
END CASE
DISPLAY BY NAME fecha_ini, fecha_fin, rm_par.vendedor, rm_par.tit_vendedor,
		rm_par.codcli, rm_par.nomcli
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[5] = 'ASC'
LET r_orden[6] = 'DESC'
LET columna_1  = 6
LET columna_2  = 5
CASE vm_tipo
	WHEN 'C'  LET expr_par = ' WHERE cli = ', parametro
	WHEN 'P'  LET expr_par = ' WHERE period = "', parametro, '"'
	OTHERWISE LET expr_par = NULL
END CASE
WHILE TRUE
	LET query = 'SELECT localidad, areaneg, cod_tran, num_tran, fecha, ',
			'valor_neto, valor_cobr, ',
			'(ABS(valor_neto) - ABS(valor_cobr)) saldo, ',
			'usuario_apr, cli, nom, vend, period',
			' FROM tmp_doc_vta ',
			expr_par CLIPPED,
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE cons_fac FROM query
	DECLARE q_cons_fac CURSOR FOR cons_fac
	LET tot_neto_inv = 0
	LET tot_cobr_inv = 0
	LET tot_neto_tal = 0
	LET tot_cobr_tal = 0
	LET tot_neto     = 0
	LET tot_cobr     = 0
	LET tot_saldo    = 0
	LET num_rows     = 1
	FOREACH q_cons_fac INTO r_fact[num_rows].*, r_aux[num_rows].*
		LET tot_neto  = tot_neto  + r_fact[num_rows].valor_neto
		LET tot_cobr  = tot_cobr  + r_fact[num_rows].valor_cobr
		LET tot_saldo = tot_saldo + r_fact[num_rows].saldo
		CASE r_fact[num_rows].areaneg
			WHEN 1 LET tot_neto_inv = tot_neto_inv +
						r_fact[num_rows].valor_neto
			       LET tot_cobr_inv = tot_cobr_inv +
						r_fact[num_rows].valor_cobr
			WHEN 2 LET tot_neto_tal = tot_neto_tal +
						r_fact[num_rows].valor_neto
			       LET tot_cobr_tal = tot_cobr_tal +
						r_fact[num_rows].valor_cobr
		END CASE
		LET num_rows  = num_rows  + 1
		IF num_rows > max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_rows = num_rows - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Cliente no tiene facturas.', 'exclamation')
		CLOSE WINDOW w_cxcf316_4
		RETURN
	END IF
	DISPLAY BY NAME tot_neto, tot_cobr, tot_saldo, tot_neto_inv,
			tot_cobr_inv, tot_neto_tal, tot_cobr_tal
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY ARRAY r_fact TO r_fact.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_factura_devolucion(r_fact[i].areaneg,
							r_fact[i].localidad,
							r_fact[i].cod_tran,
							r_fact[i].num_tran)
			LET int_flag = 0
		ON KEY(F6)
			LET i         = arr_curr()
			IF r_fact[i].valor_cobr = 0 THEN
				CONTINUE DISPLAY
			END IF
			LET expr_par2 = '   AND localid  = ',
							r_fact[i].localidad,
					'   AND area_neg = ', r_fact[i].areaneg,
					'   AND c_tran   = "',
							r_fact[i].cod_tran, '"',
					'   AND n_tran   = ', r_fact[i].num_tran
			CASE vm_tipo
				WHEN 'C' LET param2 = r_aux[i].codcli
				WHEN 'P' LET param2 = r_aux[i].period
			END CASE
			CALL muestra_detalle_cobranza(param2, expr_par2)
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F22)
			LET col      = 8
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F23)
			LET col      = 9
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_det(i, num_rows)
			--#IF r_aux[i].vend = 0 AND r_fact[i].areaneg = 2 AND
			--#   r_fact[i].cod_tran = 'FA'
			--#THEN
				--#SELECT t61_cod_vendedor INTO r_aux[i].vend
					--#FROM talt023, talt061
					--#WHERE t23_compania   = vg_codcia
					--#  AND t23_localidad  = vg_codloc
					--#  AND t23_num_factura=r_fact[i].num_tran
					--#  AND t61_compania   = t23_compania
					--#  AND t61_cod_asesor = t23_cod_asesor
			--#END IF
			--#CALL fl_lee_vendedor_rep(vg_codcia, r_aux[i].vend)
				--#RETURNING r_r01.*
			--#DISPLAY r_aux[i].codcli   TO codcli
			--#DISPLAY r_aux[i].nomcli   TO nomcli
			--#DISPLAY r_r01.r01_codigo  TO vendedor
			--#DISPLAY r_r01.r01_nombres TO tit_vendedor
			--#CASE r_fact[i].cod_tran
				--#WHEN "FA" CALL dialog.keysetlabel("F5","Factura")
				--#WHEN "NV" CALL dialog.keysetlabel("F5","Nota de Venta")
				--#WHEN "DF" CALL dialog.keysetlabel("F5","Devolución Factura")
				--#WHEN "AF" CALL dialog.keysetlabel("F5","Anulación Factura")
			--#END CASE
			--#IF r_fact[i].valor_cobr = 0 THEN
				--#CALL dialog.keysetlabel("F6","")
			--#ELSE
				--#CALL dialog.keysetlabel("F6","Movimiento")
			--#END IF
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("RETURN","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> columna_1 THEN
		LET columna_2          = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1          = col 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_cxcf316_4
RETURN

END FUNCTION



FUNCTION muestra_detalle_cobranza(parametro, expr_par2)
DEFINE parametro	VARCHAR(10)
DEFINE expr_par2	VARCHAR(300)
DEFINE r_orden		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE max_rows, i, col	SMALLINT
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE tot_cobr_inv	DECIMAL(14,2)
DEFINE tot_cobr_tal	DECIMAL(14,2)
DEFINE tot_cobr		DECIMAL(14,2)
DEFINE expr_par		VARCHAR(100)
DEFINE query		VARCHAR(1200)
DEFINE r_aux		ARRAY[14000] OF RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				vend		LIKE rept001.r01_codigo,
				cod_tran	LIKE rept019.r19_cod_tran,
				num_tran	LIKE rept019.r19_num_tran
			END RECORD
DEFINE r_cob		ARRAY[14000] OF RECORD
				localidad	LIKE rept019.r19_localidad,
				areaneg		LIKE gent003.g03_areaneg,
				tipo_trn	LIKE cxct022.z22_tipo_trn,
				num_trn		LIKE cxct022.z22_num_trn,
				fecha		DATE,
				tipo_doc	LIKE cxct020.z20_tipo_doc,
				num_doc		VARCHAR(18),
				referencia	LIKE cxct022.z22_referencia,
				valor_cobr	LIKE cxct022.z22_total_cap
			END RECORD
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r19		RECORD LIKE rept019.*

LET max_rows  = 14000
LET num_rows2 = 19
LET num_cols  = 79
IF vg_gui = 0 THEN
	LET num_rows2 = 16
	LET num_cols  = 78
END IF
OPEN WINDOW w_cxcf316_5 AT 03, 02 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf316_5 FROM "../forms/cxcf316_5"
ELSE
	OPEN FORM f_cxcf316_5 FROM "../forms/cxcf316_5c"
END IF
DISPLAY FORM f_cxcf316_5
--#DISPLAY 'LC'			TO tit_col1 
--#DISPLAY 'AN'			TO tit_col2 
--#DISPLAY 'TP'			TO tit_col3 
--#DISPLAY 'Número'		TO tit_col4 
--#DISPLAY 'Fecha'		TO tit_col5
--#DISPLAY 'TD'			TO tit_col6
--#DISPLAY 'Documento'		TO tit_col7
--#DISPLAY 'Referencia'		TO tit_col8 
--#DISPLAY 'Valor Cobrado'	TO tit_col9 
CASE vm_tipo
	WHEN 'C'
		LET fecha_ini = rm_par.fecha_ini
		LET fecha_fin = rm_par.fecha_fin
	WHEN 'P'
		LET fecha_ini = MDY(parametro[6, 7], 01, parametro[1, 4])
		LET fecha_fin = fecha_ini
		LET fecha_fin = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
				+ 1 UNITS MONTH - 1 UNITS DAY
END CASE
DISPLAY BY NAME fecha_ini, fecha_fin, rm_par.vendedor, rm_par.tit_vendedor,
		rm_par.codcli, rm_par.nomcli
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[5] = 'ASC'
LET r_orden[6] = 'ASC'
LET columna_1  = 6
LET columna_2  = 5
CASE vm_tipo
	WHEN 'C'  LET expr_par = ' WHERE cli_cr = ', parametro
	WHEN 'P'  LET expr_par = ' WHERE period = "', parametro, '"'
	OTHERWISE LET expr_par = NULL
END CASE
WHILE TRUE
	LET query = 'SELECT localid, area_neg, tipo_trn, num_trn, fecha, ',
			' tipo_doc, TRIM(num_doc) || "-" || LPAD(divid, 3, 0),',
			' referencia, valor_cobr, cli_cr, nom_cr, vend,',
			' c_tran, n_tran',
			' FROM tmp_doc_cob ',
			expr_par CLIPPED,
			expr_par2 CLIPPED,
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE cons_cob FROM query
	DECLARE q_cons_cob CURSOR FOR cons_cob
	LET tot_cobr_inv = 0
	LET tot_cobr_tal = 0
	LET tot_cobr     = 0
	LET num_rows     = 1
	FOREACH q_cons_cob INTO r_cob[num_rows].*, r_aux[num_rows].*
		LET tot_cobr = tot_cobr + r_cob[num_rows].valor_cobr
		CASE r_cob[num_rows].areaneg
			WHEN 1 LET tot_cobr_inv = tot_cobr_inv +
						r_cob[num_rows].valor_cobr
			WHEN 2 LET tot_cobr_tal = tot_cobr_tal +
						r_cob[num_rows].valor_cobr
		END CASE
		LET num_rows = num_rows + 1
		IF num_rows > max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_rows = num_rows - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Cliente no tiene movimientos.', 'exclamation')
		CLOSE WINDOW w_cxcf316_5
		RETURN
	END IF
	DISPLAY BY NAME tot_cobr, tot_cobr_inv, tot_cobr_tal
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY ARRAY r_cob TO r_cob.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			IF r_cob[i].tipo_trn <> 'PG' THEN
				CONTINUE DISPLAY
			END IF
			CALL fl_muestra_forma_pago_caja(vg_codcia,
					r_cob[i].localidad, r_cob[i].areaneg,
					r_aux[i].codcli, r_cob[i].tipo_trn,
					r_cob[i].num_trn)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento_tran(vg_codcia, r_cob[i].localidad,
					r_aux[i].codcli, r_cob[i].tipo_trn,
					r_cob[i].num_trn)
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F22)
			LET col      = 8
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F23)
			LET col      = 9
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_det(i, num_rows)
			--#IF r_aux[i].vend = 0 THEN
			--#CASE r_cob[i].areaneg
				--#WHEN 1 CALL fl_lee_cabecera_transaccion_rep(
						--#vg_codcia,r_cob[i].localidad,
						--#r_aux[i].cod_tran,
						--#r_aux[i].num_tran)
					--#RETURNING r_r19.*
				--#LET r_aux[i].vend = r_r19.r19_vendedor
				--#WHEN 2
				--#SELECT t61_cod_vendedor INTO r_aux[i].vend
					--#FROM talt023, talt061
					--#WHERE t23_compania   = vg_codcia
					--#  AND t23_localidad  = vg_codloc
					--#  AND t23_num_factura=r_aux[i].num_tran
					--#  AND t61_compania   = t23_compania
					--#  AND t61_cod_asesor = t23_cod_asesor
			--#END CASE
			--#END IF
			--#CALL fl_lee_vendedor_rep(vg_codcia, r_aux[i].vend)
				--#RETURNING r_r01.*
			--#DISPLAY r_aux[i].codcli   TO codcli
			--#DISPLAY r_aux[i].nomcli   TO nomcli
			--#DISPLAY r_r01.r01_codigo  TO vendedor
			--#DISPLAY r_r01.r01_nombres TO tit_vendedor
			--#IF r_cob[i].tipo_trn <> 'PG' THEN
				--#CALL dialog.keysetlabel("F5","")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Pago Caja")
			--#END IF
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("RETURN","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> columna_1 THEN
		LET columna_2          = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1          = col 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_cxcf316_5
RETURN

END FUNCTION



FUNCTION muestra_detalle_inventario(parametro, flag)
DEFINE parametro	VARCHAR(10)
DEFINE flag		SMALLINT
DEFINE base		CHAR(20)
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE vendedor		LIKE rept019.r19_vendedor

CASE flag
	WHEN 1
		LET base   = vg_base
		LET codloc = vg_codloc
	WHEN 2
		CASE vg_codloc
			WHEN 1
				LET base   = 'acero_gc'
				LET codloc = 2
			WHEN 3
				LET base   = 'acero_qs'
				LET codloc = 4
		END CASE
END CASE
LET vendedor = 0
IF rm_par.vendedor IS NOT NULL THEN
	LET vendedor = rm_par.vendedor
END IF
CASE vm_tipo
	WHEN 'C'
		LET fecha_ini = rm_par.fecha_ini
		LET fecha_fin = rm_par.fecha_fin
		LET prog      = 'repp309'
		LET param     = ' "C" ', parametro, ' "',rg_gen.g00_moneda_base,
				'" ', vendedor, ' "R"'
	WHEN 'P'
		LET fecha_ini = MDY(parametro[6, 7], 01, parametro[1, 4])
		LET fecha_fin = fecha_ini
		LET fecha_fin = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
				+ 1 UNITS MONTH - 1 UNITS DAY
		LET prog      = 'repp312'
		LET param     = ' "', rg_gen.g00_moneda_base, '" "R" 0 ',
				vendedor, ' "C"'
END CASE
LET comando = 'cd ..', vg_separador, '..', vg_separador, '..', vg_separador,
		'PRODUCCION', vg_separador, 'REPUESTOS', vg_separador,
		'fuentes; ', 'fglrun ', prog CLIPPED, ' ', base CLIPPED,
		' "RE" ', vg_codcia, ' ', codloc, ' "', fecha_ini, '" "',
		fecha_fin, '" ', param CLIPPED
RUN comando

END FUNCTION



FUNCTION muestra_detalle_taller(parametro)
DEFINE parametro	VARCHAR(10)
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE vendedor		LIKE rept019.r19_vendedor

LET vendedor = NULL
IF rm_par.vendedor IS NOT NULL THEN
	LET vendedor = rm_par.vendedor
END IF
CASE vm_tipo
	WHEN 'C'
		LET fecha_ini = rm_par.fecha_ini
		LET fecha_fin = rm_par.fecha_fin
		LET prog      = 'talp309'
		LET param     = ' "T" "R" "', fecha_ini, '" "', fecha_fin, '" ',
				parametro, ' "N"'
	WHEN 'P'
		LET fecha_ini = MDY(parametro[6, 7], 01, parametro[1, 4])
		LET fecha_fin = fecha_ini
		LET fecha_fin = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
				+ 1 UNITS MONTH - 1 UNITS DAY
		LET prog      = 'talp313'
		LET param     = ' "', fecha_ini, '" "', fecha_fin, '" "R" "N"',
				vendedor
END CASE
LET comando = 'cd ..', vg_separador, '..', vg_separador, '..', vg_separador,
		'PRODUCCION', vg_separador, 'TALLER', vg_separador,
		'fuentes; ', 'fglrun ', prog CLIPPED, ' ', vg_base CLIPPED,
		' "TA" ', vg_codcia, ' ', vg_codloc, param CLIPPED
RUN comando

END FUNCTION



FUNCTION ver_factura_devolucion(area_n, local, cod_tran, num_tran)
DEFINE area_n		LIKE cxct020.z20_areaneg
DEFINE local		LIKE cxct020.z20_localidad
DEFINE cod_tran		LIKE cxct020.z20_cod_tran
DEFINE num_tran		LIKE cxct020.z20_num_tran
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE i		SMALLINT
DEFINE prog		VARCHAR(10)
DEFINE comando          VARCHAR(200)

CALL fl_lee_area_negocio(vg_codcia, area_n) RETURNING r_g03.*
CASE r_g03.g03_modulo
	WHEN 'RE'
		CALL fl_ver_transaccion_rep(vg_codcia, local, cod_tran,num_tran)
	WHEN 'TA'
		LET prog = 'talp308 '
		IF cod_tran = 'DF' THEN
			LET prog = 'talp211 '
		END IF
		LET comando = 'cd ..', vg_separador, '..', vg_separador, '..',
				vg_separador, 'PRODUCCION', vg_separador,
				'TALLER', vg_separador, 'fuentes; ', 'fglrun ',
				prog CLIPPED, ' ', vg_base, ' TA ', vg_codcia,
				' ', local, ' ', num_tran
		RUN comando
END CASE

END FUNCTION



FUNCTION ver_documento_tran(codcia, loc, codcli, tipo_trn, num_trn)
DEFINE codcia		LIKE cxct022.z22_compania
DEFINE loc		LIKE cxct022.z22_localidad
DEFINE codcli		LIKE cxct022.z22_codcli
DEFINE tipo_trn		LIKE cxct022.z22_tipo_trn
DEFINE num_trn		LIKE cxct022.z22_num_trn
DEFINE tipo		LIKE cxct023.z23_tipo_favor
DEFINE comando		VARCHAR(200)
DEFINE run_prog		CHAR(10)
DEFINE prog		CHAR(10)

{- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE -}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
LET prog = 'cxcp202 '
INITIALIZE tipo TO NULL
DECLARE q_favor CURSOR FOR
	SELECT UNIQUE z23_tipo_favor FROM cxct023
		WHERE z23_compania  = codcia
		  AND z23_localidad = loc
		  AND z23_codcli    = codcli
		  AND z23_tipo_trn  = tipo_trn
		  AND z23_num_trn   = num_trn
		ORDER BY 1
OPEN q_favor
FETCH q_favor INTO tipo
CLOSE q_favor
FREE q_favor
IF tipo IS NOT NULL THEN
	LET prog = 'cxcp203 '
END IF
LET comando = run_prog, prog, vg_base, ' ', vg_modulo, ' ', codcia, ' ', loc,
		' ', codcli, ' ', tipo_trn, ' ', num_trn
RUN comando

END FUNCTION



{--
FUNCTION muestra_grafico_barras()
DEFINE inicio_x		SMALLINT
DEFINE inicio_y		SMALLINT
DEFINE maximo_x		SMALLINT
DEFINE maximo_y		SMALLINT
DEFINE factor_y		DECIMAL(16,6)
DEFINE max_barras	SMALLINT
DEFINE ancho_barra	SMALLINT
DEFINE num_barras	SMALLINT
DEFINE inicio2_x	SMALLINT
DEFINE inicio2_y	SMALLINT
DEFINE max_elementos	SMALLINT
DEFINE max_valor	DECIMAL(14,2)
DEFINE filas_procesadas	SMALLINT
DEFINE codigo		SMALLINT
DEFINE descri		VARCHAR(30)
DEFINE valor		DECIMAL(14,2)
DEFINE key_n		SMALLINT
DEFINE key_c		CHAR(3)
DEFINE key_f30		SMALLINT
DEFINE cant_val		CHAR(1)
DEFINE query		VARCHAR(600)
DEFINE i, indice	INTEGER
DEFINE tecla		CHAR(1)
DEFINE titulo, tit_pos	CHAR(75)
DEFINE label          	CHAR(10)
DEFINE tit_val		CHAR(16)
DEFINE campos		VARCHAR(100)
DEFINE campo		CHAR(13)
DEFINE ind_venc		CHAR(1)
DEFINE comando		VARCHAR(100)
DEFINE r_obj		ARRAY[8] OF RECORD
				localidad	SMALLINT,
				codigo		INTEGER,
				descripcion	VARCHAR(20),
				valor		DECIMAL(12,2),
				id_obj_rec1	SMALLINT,
				id_obj_rec2	SMALLINT
			END RECORD
DEFINE loc		LIKE gent002.g02_localidad

CALL carga_colores()
LET max_barras = 8
LET inicio_x   = 50
LET inicio_y   = 80
LET maximo_x   = 500
LET maximo_y   = 750
LET inicio2_x  = 910
IF rm_par.ind_venc = 'V' THEN
	LET campos = 'val_col1 te_por_vencer, (val_col2 + val_col3 + ',
			'val_col4 + val_col5 + val_col6) te_vencido, '
ELSE
	LET campos = 'val_col1 te_vencido, (val_col2 + val_col3 + ',
			'val_col4 + val_col5 + val_col6) te_por_vencer, '
END IF
LET query = 'SELECT cod_loc te_loc, codigo te_codigo, ',
			'descripcion te_descripcion, ', campos CLIPPED,
			' (val_col1 + val_col2 + val_col3 + val_col4 + ',
			'val_col5 + val_col6) te_total ',
		' FROM tempo_acum ',
		' INTO TEMP temp_barra'
PREPARE in_bar FROM query
EXECUTE in_bar
LET ind_venc = rm_par.ind_venc
WHILE TRUE
	CASE ind_venc
		WHEN 'V'
			LET label = 'VENCIDA'
			LET campo = 'te_vencido'
		WHEN 'P'
			LET label = 'POR VENCER'
			LET campo = 'te_por_vencer'
		OTHERWISE
			LET label = 'TOTAL'
			LET campo = 'te_total'
	END CASE
	LET titulo = 'CARTERA ', label CLIPPED, ' POR '
	CASE rm_par.tipo_venta
		WHEN 'P'
			LET titulo = titulo CLIPPED, ' CLIENTE'
		WHEN 'C'
			LET titulo = titulo CLIPPED, ' TIPO DE CLIENTE'
		WHEN 'R'
			LET titulo = titulo CLIPPED, ' TIPO DE CARTERA'
		WHEN 'A'
			LET titulo = titulo CLIPPED, ' AREA DE NEGOCIO'
	END CASE
	LET query = 'SELECT COUNT(*), MAX(', campo CLIPPED, ')',
			' FROM temp_barra '
	PREPARE maxi FROM query
	DECLARE q_maxi CURSOR FOR maxi
	OPEN q_maxi
	FETCH q_maxi INTO max_elementos, max_valor	
	CLOSE q_maxi
	FREE q_maxi
	IF max_elementos IS NULL THEN
		DROP TABLE temp_barra
		RETURN
	END IF
	LET query = 'SELECT te_loc, te_codigo, te_descripcion, ', campo CLIPPED,
			' FROM temp_barra ',
			' ORDER BY 4 DESC'
	PREPARE bar FROM query
	DECLARE q_bar SCROLL CURSOR FOR bar
	CALL drawinit()
	OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/cxcf316_4"
		ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
	CALL drawselect('c001')
	CALL drawanchor('w')
	CALL DrawFillColor("blue")
	LET i = drawline(inicio_y, inicio_x, 0, maximo_x)
	LET i = drawline(inicio_y, inicio_x, maximo_y, 0)
	LET factor_y         = maximo_y / max_valor 
	LET filas_procesadas = 0
	OPEN q_bar
	WHILE TRUE
		LET i = drawtext(960,10,titulo CLIPPED)
		LET num_barras = max_elementos - filas_procesadas
		IF num_barras >= max_barras THEN
			LET num_barras = max_barras
		END IF
		LET ancho_barra = maximo_x / num_barras 
		LET indice = 0
		LET inicio2_y  = maximo_y + 70 
		WHILE indice < num_barras 
			FETCH q_bar INTO loc, codigo, descri, valor
			IF status = NOTFOUND THEN
				EXIT WHILE
			END IF
			LET r_obj[indice + 1].localidad   = loc
			LET r_obj[indice + 1].codigo      = codigo
			LET r_obj[indice + 1].descripcion = descri
			LET r_obj[indice + 1].valor       = valor
        		CALL DrawFillColor(rm_color[indice+1])
			LET r_obj[indice + 1].id_obj_rec1 =
				drawrectangle(inicio_y, inicio_x +
						(ancho_barra * indice),
						factor_y * valor, ancho_barra)
			LET r_obj[indice + 1].id_obj_rec2 =
				drawrectangle(inicio2_y, inicio2_x, 25, 75)
			LET descri = fl_justifica_titulo('D', descri[1,30], 30)
			LET i = drawtext(inicio2_y + 53, inicio2_x - 315,descri)
			LET tit_val = valor USING "#,###,###,##&.##"
			LET i = drawtext(inicio2_y + 15,inicio2_x - 215,tit_val)
			LET indice = indice + 1
			LET filas_procesadas = filas_procesadas + 1
			LET inicio2_y = inicio2_y - 110
		END WHILE
		LET tit_pos = '   ', filas_procesadas USING "<<<<<&", ' de ',
				max_elementos USING "<<<<<&"
		LET i = drawtext(900,05, tit_pos)
		LET i = drawtext(30,10,'Haga click sobre un item para ver detalles')
		FOR i = 1 TO indice
			LET key_n = i + 30
			LET key_c = 'F', key_n
			CALL drawbuttonleft(r_obj[i].id_obj_rec1, key_c)
			CALL drawbuttonleft(r_obj[i].id_obj_rec2, key_c)
		END FOR
		LET key_f30 = FGL_KEYVAL("F30")
		LET int_flag = 0
		IF filas_procesadas >= max_elementos THEN
			--#CALL fgl_keysetlabel("F3","")
		ELSE
			--#CALL fgl_keysetlabel("F3","Avanzar")
		END IF
		IF filas_procesadas <= max_barras THEN
			--#CALL fgl_keysetlabel("F4","")
		ELSE
			--#CALL fgl_keysetlabel("F4","Retroceder")
		END IF
		INPUT BY NAME tecla
			BEFORE INPUT
				IF filas_procesadas <= max_barras THEN
					--#CALL dialog.keysetlabel("F5","Vencimientos")
				ELSE
					--#CALL dialog.keysetlabel("F5","")
				END IF
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F31","")
				--#CALL dialog.keysetlabel("F32","")
				--#CALL dialog.keysetlabel("F33","")
				--#CALL dialog.keysetlabel("F34","")
				--#CALL dialog.keysetlabel("F35","")
				--#CALL dialog.keysetlabel("F36","")
				--#CALL dialog.keysetlabel("F37","")
				--#CALL dialog.keysetlabel("F38","")
			ON KEY(F5)
				IF filas_procesadas <= max_barras THEN
					IF ind_venc = 'P' THEN
						LET ind_venc = 'V'
					ELSE
						IF ind_venc = 'V' THEN
							LET ind_venc = 'T'
						ELSE
							LET ind_venc = 'P'
						END IF
					END IF
					LET int_flag = 2
					EXIT INPUT
				END IF
			ON KEY(F3)
				IF filas_procesadas < max_elementos THEN
					CALL drawclear()
					EXIT INPUT
				END IF
			ON KEY(F4)
				IF filas_procesadas > max_barras THEN
					LET filas_procesadas = filas_procesadas
						- (indice + max_barras)
					IF filas_procesadas = 0 THEN
						CLOSE q_bar
						OPEN q_bar
					ELSE
						FOR i = 1 TO indice + max_barras 
							FETCH PREVIOUS q_bar 
						END FOR
					END IF
					CALL drawclear()
					EXIT INPUT
				END IF
			ON KEY(F31,F32,F33,F34,F35,F36,F37,F38)
				LET i = FGL_LASTKEY() - key_f30
				CALL muestra_documentos(r_obj[i].codigo,
						ind_venc, r_obj[i].localidad)
			AFTER FIELD tecla
				NEXT FIELD tecla	
		END INPUT
		IF int_flag THEN
			CLOSE q_bar
			EXIT WHILE
		END IF
	END WHILE
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
FREE q_bar
CLOSE WINDOW w_gr1
DROP TABLE temp_barra
	
END FUNCTION
--}



FUNCTION carga_colores()

LET rm_color[01] = 'cyan'
LET rm_color[02] = 'yellow'
LET rm_color[03] = 'green'
LET rm_color[04] = 'red'
LET rm_color[05] = 'snow'
LET rm_color[06] = 'magenta'
LET rm_color[07] = 'pink'
LET rm_color[08] = 'chocolate'
LET rm_color[09] = 'tomato'
LET rm_color[10] = 'blue'

END FUNCTION



FUNCTION muestra_estado_cuenta(codcli)
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE comando          VARCHAR(100)

LET comando = 'fglrun cxcp314 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', ' ', rg_gen.g00_moneda_base, ' ',
		rm_par.fecha_fin, ' "T" ', 0.01, ' "N" ', vg_codloc, ' ', codcli
RUN comando

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		INTEGER

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CASE vm_tipo
	WHEN 'C' START REPORT report_list_cobven01 TO PIPE comando
	WHEN 'P' START REPORT report_list_cobven02 TO PIPE comando
END CASE
FOR i = 1 TO vm_num_rows
	CASE vm_tipo
		WHEN 'C' OUTPUT TO REPORT report_list_cobven01(i)
		WHEN 'P' OUTPUT TO REPORT report_list_cobven02(i)
	END CASE
END FOR
CASE vm_tipo
	WHEN 'C' FINISH REPORT report_list_cobven01
	WHEN 'P' FINISH REPORT report_list_cobven02
END CASE

END FUNCTION



REPORT report_list_cobven01(i)
DEFINE i		INTEGER
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE label		VARCHAR(11)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo  = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	PRINT COLUMN 001, r_g01.g01_razonsocial,
  	      COLUMN 070, 'PAGINA: ', PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 021, 'LISTADO VENTAS VS. COBRANZAS POR CLIENTE',
	      COLUMN 074, UPSHIFT(vg_proceso) 
	SKIP 1 LINES
	PRINT COLUMN 015, '** RANGO DE FECHAS: ',
			rm_par.fecha_ini USING "dd-mm-yyyy", '   -   ',
			rm_par.fecha_fin USING "dd-mm-yyyy"
	IF rm_par.localidad IS NOT NULL THEN
		PRINT COLUMN 015, '** LOCALIDAD      : ',
			rm_par.localidad USING "&&", ' ',
			rm_par.tit_localidad CLIPPED
	END IF
	IF rm_par.area_n IS NOT NULL THEN
		PRINT COLUMN 015, '** AREA DE NEGOCIO: ',
			rm_par.area_n USING "&&", ' ', rm_par.tit_area CLIPPED
	END IF
	IF rm_par.vendedor IS NOT NULL THEN
		PRINT COLUMN 015, '** VENDEDOR       : ',
			rm_par.vendedor USING "<<&", ' ',
			rm_par.tit_vendedor CLIPPED
	END IF
	IF rm_par.codcli IS NOT NULL THEN
		PRINT COLUMN 015, '** CLIENTE        : ',
			rm_par.codcli USING "<<<<&", ' ',
			rm_par.nomcli[1, 40] CLIPPED
	END IF
	PRINT COLUMN 051, UPSHIFT(tit_precision)
	SKIP 1 LINES
	PRINT COLUMN 001, 'FECHA IMPRESION: ', TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, 'CODIGO',
	      COLUMN 013, 'CLIENTES',
	      COLUMN 027, '  VALOR VENTA',
	      COLUMN 041, ' VALOR APROB.',
	      COLUMN 055, 'VALOR COBRADO',
	      COLUMN 069, '  DIFERENCIA'
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_det1[i].cod_cli		USING "####&&",
	      COLUMN 008, rm_det1[i].nom_cli[1, 18]	CLIPPED,
	      COLUMN 027, rm_det1[i].valor_vta		USING "--,---,--&.##",
	      COLUMN 041, rm_det1[i].valor_apr		USING "--,---,--&.##",
	      COLUMN 055, rm_det1[i].valor_cob		USING "--,---,--&.##",
	      COLUMN 069, rm_det1[i].valor_dif		USING "-,---,--&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 027, '-------------',
	      COLUMN 041, '-------------',
	      COLUMN 055, '-------------',
	      COLUMN 069, '------------'
	PRINT COLUMN 014, 'TOTALES ==>  ', tot_col1	USING "--,---,--&.##",
	      COLUMN 041, tot_col2			USING "--,---,--&.##",
	      COLUMN 055, tot_col3			USING "--,---,--&.##",
	      COLUMN 069, tot_col4			USING "-,---,--&.##"

END REPORT



REPORT report_list_cobven02(i)
DEFINE i		INTEGER
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE label		VARCHAR(11)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo  = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	PRINT COLUMN 001, r_g01.g01_razonsocial,
  	      COLUMN 070, 'PAGINA: ', PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 021, 'LISTADO VENTAS VS. COBRANZAS POR PERIODO',
	      COLUMN 074, UPSHIFT(vg_proceso) 
	SKIP 1 LINES
	PRINT COLUMN 015, '** RANGO DE FECHAS: ',
			DATE(rm_par2.fecha_ini) USING "yyyy-mm", '   -   ',
			DATE(rm_par2.fecha_fin) USING "yyyy-mm"
	IF rm_par2.localidad IS NOT NULL THEN
		PRINT COLUMN 015, '** LOCALIDAD      : ',
			rm_par2.localidad USING "&&", ' ',
			rm_par2.tit_localidad CLIPPED
	END IF
	IF rm_par2.area_n IS NOT NULL THEN
		PRINT COLUMN 015, '** AREA DE NEGOCIO: ',
			rm_par2.area_n USING "&&", ' ', rm_par2.tit_area CLIPPED
	END IF
	IF rm_par2.vendedor IS NOT NULL THEN
		PRINT COLUMN 015, '** VENDEDOR       : ',
			rm_par2.vendedor USING "<<&", ' ',
			rm_par2.tit_vendedor CLIPPED
	END IF
	IF rm_par2.codcli IS NOT NULL THEN
		PRINT COLUMN 015, '** CLIENTE        : ',
			rm_par2.codcli USING "<<<<&", ' ',
			rm_par2.nomcli[1, 40] CLIPPED
	END IF
	PRINT COLUMN 051, UPSHIFT(tit_precision)
	SKIP 1 LINES
	PRINT COLUMN 001, 'FECHA IMPRESION: ', TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, 'PERIODO',
	      COLUMN 011, '  VALOR VENTA',
	      COLUMN 027, ' VALOR APROB.',
	      COLUMN 043, 'VALOR COBRADO',
	      COLUMN 058, '  DIFERENCIA',
	      COLUMN 072, '   MARGEN'
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, DATE(rm_det2[i].periodo)	USING "yyyy-mm",
	      COLUMN 011, rm_det2[i].valor_vta		USING "--,---,--&.##",
	      COLUMN 027, rm_det2[i].valor_apr		USING "--,---,--&.##",
	      COLUMN 043, rm_det2[i].valor_cob		USING "--,---,--&.##",
	      COLUMN 058, rm_det2[i].valor_dif		USING "-,---,--&.##",
	      COLUMN 072, rm_det2[i].margen		USING "----&.##%"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 011, '-------------',
	      COLUMN 027, '-------------',
	      COLUMN 043, '-------------',
	      COLUMN 058, '------------',
	      COLUMN 072, '---------'
	PRINT COLUMN 002, 'TOTALES: ', tot_col1		USING "--,---,--&.##",
	      COLUMN 027, tot_col2			USING "--,---,--&.##",
	      COLUMN 043, tot_col3			USING "--,---,--&.##",
	      COLUMN 058, tot_col4			USING "-,---,--&.##",
	      COLUMN 072, tot_col5			USING "----&.##%"

END REPORT
