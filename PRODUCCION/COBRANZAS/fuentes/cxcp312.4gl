--------------------------------------------------------------------------------
-- Titulo           : cxcp312.4gl - Consulta Saldos de Cartera por Fecha
-- Elaboracion      : 11-Oct-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp312 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par		RECORD
				moneda		LIKE gent013.g13_moneda,
				tit_mon		VARCHAR(30),
				localidad	LIKE gent002.g02_localidad,
				tit_local	VARCHAR(30),
				tipo_detalle	CHAR(1),
				fecha_cart	DATE,
				ind_venc	CHAR(1),
				rango1_i 	SMALLINT,
				rango1_f  	SMALLINT,
				rango2_i  	SMALLINT,
				rango2_f  	SMALLINT,
				rango3_i  	SMALLINT,
				rango3_f  	SMALLINT,
				rango4_i  	SMALLINT,
				rango4_f  	SMALLINT,
				rango5_i  	SMALLINT
			END RECORD
DEFINE rm_det1		ARRAY[32766] OF RECORD
				cod_des		INTEGER,
				descripcion	VARCHAR(100),
				cod_loc		SMALLINT,
				val_col1	DECIMAL(12,2),
				val_col2	DECIMAL(12,2),
				val_col3	DECIMAL(12,2),
				val_col4	DECIMAL(12,2),
				val_col5	DECIMAL(12,2),
				val_col6	DECIMAL(12,2)
			END RECORD
DEFINE rm_descrip	ARRAY[32766] OF VARCHAR(100)
DEFINE rm_det2		ARRAY[32766] OF RECORD
				cod_des		INTEGER,
				cod_loc		SMALLINT,
				val_col1	DECIMAL(12,2),
				val_col2	DECIMAL(12,2),
				val_col3	DECIMAL(12,2),
				val_col4	DECIMAL(12,2),
				val_col5	DECIMAL(12,2),
				val_col6	DECIMAL(12,2)
			END RECORD
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE rm_color		ARRAY[10] OF VARCHAR(10)
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE rm_z60		RECORD LIKE cxct060.*
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_divisor	SMALLINT
DEFINE tot_col1		DECIMAL(14,2)
DEFINE tot_col2		DECIMAL(12,2)
DEFINE tot_col3		DECIMAL(12,2)
DEFINE tot_col4		DECIMAL(12,2)
DEFINE tot_col5		DECIMAL(12,2)
DEFINE tot_col6		DECIMAL(12,2)
DEFINE vm_max_rows	INTEGER
DEFINE vm_num_rows	INTEGER
DEFINE vm_num_doc	INTEGER
DEFINE vm_num_res	INTEGER
DEFINE tit_precision	VARCHAR(30)
DEFINE tit_edad		VARCHAR(54)
DEFINE vm_fecha_ini	DATE
DEFINE vm_decimales	CHAR(1)
DEFINE vm_pan, vm_arr	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp312.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parametros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp312'
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
CREATE TEMP TABLE tempo_doc 
	(localidad	SMALLINT,
	 areaneg	SMALLINT,
	 cartera	SMALLINT,
	 tipo_cli	SMALLINT,
	 cladoc		CHAR(2),
	 numdoc		CHAR(13),
	 dividendo	SMALLINT,
	 codcli		INTEGER,
	 fecha		DATE,
	 valor 		DECIMAL(12,2))
CREATE TEMP TABLE tempo_acum
	(cod_loc	SMALLINT,
	 codigo		INTEGER,
	 descripcion	VARCHAR(100),
	 val_col1	DECIMAL(12,2),
 	 val_col2	DECIMAL(12,2),
	 val_col3	DECIMAL(12,2),
	 val_col4	DECIMAL(12,2),
	 val_col5	DECIMAL(12,2),
	 val_col6	DECIMAL(12,2))
INITIALIZE rm_par.*, vm_fecha_ini TO NULL
LET vm_max_rows         = 32766
LET rm_par.moneda       = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon      = rm_mon.g13_nombre
LET rm_par.fecha_cart   = TODAY
LET vm_fecha_ini        = rm_z60.z60_fecha_carga
LET rm_par.tipo_detalle = 'P'
LET rm_par.ind_venc     = 'V'
LET vm_divisor          = 1
LET rm_par.rango1_i     = 1
LET rm_par.rango1_f     = 30
LET rm_par.rango2_i     = 31
LET rm_par.rango2_f     = 60
LET rm_par.rango3_i     = 61
LET rm_par.rango3_f     = 90
LET rm_par.rango4_i     = 91
LET rm_par.rango4_f     = 180
LET rm_par.rango5_i     = 181
CALL pantalla_principal()
LET vm_num_res = 0
CALL carga_colores()
MENU "OPCIONES"
	BEFORE MENU
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Precisión'
		HIDE OPTION 'Rangos'
		HIDE OPTION 'Grafico'
		HIDE OPTION 'Decimales'
		HIDE OPTION 'Imprimir'
		CALL control_consulta()
		IF vm_num_doc > 0 AND NOT int_flag THEN
			CALL control_detalle()
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Precisión'
			SHOW OPTION 'Rangos'
			SHOW OPTION 'Grafico'
			SHOW OPTION 'Decimales'
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY("C") "Consultar"
		CALL control_consulta()
		IF vm_num_doc = 0 AND int_flag THEN
			HIDE OPTION 'Detalle'
			HIDE OPTION 'Precisión'
			HIDE OPTION 'Rangos'
			HIDE OPTION 'Grafico'
			HIDE OPTION 'Decimales'
			HIDE OPTION 'Imprimir'
		ELSE
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Precisión'
			SHOW OPTION 'Rangos'
			SHOW OPTION 'Grafico'
			SHOW OPTION 'Decimales'
			SHOW OPTION 'Imprimir'
		END IF
		IF vm_num_doc > 0 AND NOT int_flag THEN
			CALL control_detalle()
		END IF
	COMMAND KEY("R") "Rangos"
		CALL control_rangos()
	COMMAND KEY("P") "Precisión"
		CALL control_precision()
	COMMAND KEY('F') 'Decimales'
		CALL pantalla_principal()
		CALL carga_arreglo_trabajo()
		CALL control_detalle()
	COMMAND KEY("D") "Detalle"
		CALL control_detalle()
	COMMAND KEY('G') 'Grafico'
		CALL muestra_grafico_barras()
	COMMAND KEY('K') 'Imprimir'
		CALL control_imprimir()
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION pantalla_principal()
DEFINE resp		CHAR(6)

CALL fl_hacer_pregunta('Desea ver valores con decimales?', 'No') RETURNING resp
LET vm_decimales = 'N'
IF resp = 'Yes' THEN
	LET vm_decimales = 'S'
END IF
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vm_decimales = 'N' THEN
	OPEN FORM f_cons FROM '../forms/cxcf312_1'
ELSE
	OPEN FORM f_cons FROM '../forms/cxcf312_2'
END IF
DISPLAY FORM f_cons
DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon,rm_par.localidad,rm_par.tit_local,
		rm_par.tipo_detalle, rm_par.fecha_cart
CALL muestra_titulos()

END FUNCTION



FUNCTION control_consulta()
DEFINE i		SMALLINT

CALL lee_parametros()
IF int_flag THEN
	RETURN
END IF
LET vm_pan = 1
LET vm_arr = 1
FOR i = 1 TO 10
	LET rm_orden[i] = ''
END FOR
CASE vm_decimales
	WHEN 'N'
		LET vm_columna_1 = 2
		LET vm_columna_2 = 4
		LET rm_orden[2]  = 'ASC'
		LET rm_orden[4]  = 'DESC'
	WHEN 'S'
		LET vm_columna_1 = 4
		LET vm_columna_2 = 1
		LET rm_orden[4]  = 'DESC'
		LET rm_orden[1]  = 'ASC'
END CASE
CALL control_tablas_temporales()

END FUNCTION



FUNCTION control_tablas_temporales()

CALL genera_tabla_trabajo_detalle()
IF vm_num_doc = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
CALL genera_tabla_trabajo_resumen()
IF vm_num_res > 0 THEN
	CALL carga_arreglo_trabajo()
END IF

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_loc		RECORD LIKE gent002.*
DEFINE loc_aux		LIKE gent002.g02_localidad
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE resp		CHAR(3)
DEFINE fec		DATE
DEFINE num_dec		SMALLINT

LET int_flag = 0
DISPLAY BY NAME rm_par.tit_mon
INPUT BY NAME rm_par.moneda, rm_par.localidad, rm_par.fecha_cart,
	rm_par.tipo_detalle
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.localidad, rm_par.moneda,
				     rm_par.fecha_cart, rm_par.tipo_detalle)
		THEN
			RETURN
		END IF
		LET int_flag = 0
		CALL FGL_WINQUESTION(vg_producto, 
                                     'Desea salir de la consulta',
                                     'No', 'Yes|No|Cancel',
                                     'question', 1) RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING loc_aux, rm_par.tit_local
			IF loc_aux IS NOT NULL THEN
				LET rm_par.localidad = loc_aux
				DISPLAY BY NAME rm_par.localidad,
						rm_par.tit_local
			END IF
		END IF
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mon_aux,rm_par.tit_mon, num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda = mon_aux
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
	BEFORE FIELD fecha_cart
		LET fec = rm_par.fecha_cart
	AFTER FIELD localidad
		IF rm_par.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.localidad) 
				RETURNING r_loc.*
			IF r_loc.g02_localidad IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Localidad no existe', 'exclamation')
				NEXT FIELD localidad
			END IF
			LET rm_par.tit_local = r_loc.g02_nombre
			DISPLAY BY NAME rm_par.tit_local
		ELSE
			LET rm_par.tit_local = NULL
			CLEAR tit_local
		END IF
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
			IF rm_mon.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Moneda no existe', 'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = rm_mon.g13_nombre
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			CLEAR tit_mon
		END IF
	AFTER FIELD fecha_cart
		IF rm_par.fecha_cart IS NULL THEN
			LET rm_par.fecha_cart = fec
			DISPLAY BY NAME rm_par.fecha_cart
		END IF
END INPUT

END FUNCTION



FUNCTION control_rangos()

CALL lee_rangos_vencimientos()
IF int_flag THEN
	RETURN
END IF
CALL muestra_titulos()
CALL genera_tabla_trabajo_resumen()
IF vm_num_res > 0 THEN
	CALL carga_arreglo_trabajo()
	CALL control_detalle()
END IF

END FUNCTION



FUNCTION control_precision()

IF vm_divisor = 1 THEN
	LET vm_divisor = 10
ELSE
	IF vm_divisor = 10 THEN
		LET vm_divisor = 100
	ELSE
		IF vm_divisor = 100 THEN
			LET vm_divisor = 1000
		ELSE
			IF vm_divisor = 1000 THEN
				LET vm_divisor = 1
			END IF
		END IF
	END IF
END IF
CALL muestra_titulos()
CALL carga_arreglo_trabajo()

END FUNCTION



FUNCTION lee_rangos_vencimientos()

OPEN WINDOW w_ran AT 7, 27 WITH FORM "../forms/cxcf312_3" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET int_flag = 0
INPUT BY NAME rm_par.rango1_i THRU rm_par.rango5_i WITHOUT DEFAULTS
CLOSE WINDOW w_ran

END FUNCTION



FUNCTION muestra_titulos()
DEFINE label		CHAR(7)

IF vm_divisor = 1 THEN
	LET tit_precision = "Valores expresados en unidades"
END IF 
IF vm_divisor = 10 THEN
	LET tit_precision = "Valores expresados en decenas"
END IF 
IF vm_divisor = 100 THEN
	LET tit_precision = "Valores expresados en centenas"
END IF 
IF vm_divisor = 1000 THEN
	LET tit_precision = "Valores expresados en miles"
END IF 
CASE vm_decimales
	WHEN 'N'
		LET tit_edad = "      -- Rango de días vencidos --      "
		DISPLAY 'Descripción' TO tit_col2
		DISPLAY 'Tot.Ven.'    TO tit_col4
	WHEN 'S'
		LET tit_edad = "             -- Rango de días vencidos --             "
		DISPLAY 'Total Venc.' TO tit_col4
END CASE
DISPLAY 'Código' TO tit_col1
DISPLAY 'LC'     TO tit_col3
LET label = rm_par.rango1_i USING "<<&", "-", rm_par.rango1_f USING "<<&"
DISPLAY label    TO tit_col5
LET label = rm_par.rango2_i USING "<<&", "-", rm_par.rango2_f USING "<<&"
DISPLAY label    TO tit_col6
LET label = rm_par.rango3_i USING "<<&", "-", rm_par.rango3_f USING "<<&"
DISPLAY label    TO tit_col7
LET label = rm_par.rango4_i USING "<<&", "-", rm_par.rango4_f USING "<<&"
DISPLAY label    TO tit_col8
LET label = '>= ', rm_par.rango5_i USING "<<&"
DISPLAY label    TO tit_col9
DISPLAY BY NAME tit_precision, tit_edad

END FUNCTION



FUNCTION genera_tabla_trabajo_detalle()
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(4000)
DEFINE subquery1	CHAR(1500)
DEFINE subquery2	CHAR(500)
DEFINE expr_loc		VARCHAR(100)

ERROR "Procesando documentos deudores con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
DELETE FROM tempo_doc
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr_loc = NULL
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loc = '   AND z20_localidad   = ', rm_par.localidad
END IF
LET subquery1 = '(SELECT z23_valor_cap + z23_valor_int + z23_saldo_cap + ',
			'z23_saldo_int ',
		' FROM cxct023, cxct022 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo ',
		'   AND z22_compania  = z23_compania ',
		'   AND z22_localidad = z23_localidad ',
		'   AND z22_codcli    = z23_codcli ',
		'   AND z22_tipo_trn  = z23_tipo_trn ',
		'   AND z22_num_trn   = z23_num_trn ',
		'   AND z22_fecing    = (SELECT MAX(z22_fecing) ',
					' FROM cxct023, cxct022 ',
					' WHERE z23_compania  = z20_compania ',
					'   AND z23_localidad = z20_localidad ',
					'   AND z23_codcli    = z20_codcli ',
					'   AND z23_tipo_doc  = z20_tipo_doc ',
					'   AND z23_num_doc   = z20_num_doc ',
					'   AND z23_div_doc   = z20_dividendo ',
					'   AND z22_compania  = z23_compania ',
					'   AND z22_localidad = z23_localidad ',
					'   AND z22_codcli    = z23_codcli ',
					'   AND z22_tipo_trn  = z23_tipo_trn ',
					'   AND z22_num_trn   = z23_num_trn ',
					'   AND z22_fecing   <= "', fecha, '"))'
LET subquery2 = ' (SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM cxct023 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo) '
LET query = 'INSERT INTO tempo_doc ',
		' SELECT z20_localidad, z20_areaneg, z20_cartera, ',
			'z01_tipo_clte, z20_tipo_doc, z20_num_doc, ',
			'z20_dividendo, z20_codcli, z20_fecha_vcto, ',
			' NVL(', subquery1 CLIPPED, ', ',
			' CASE WHEN z20_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN z20_saldo_cap + z20_saldo_int - ',
					subquery2 CLIPPED,
				' ELSE z20_valor_cap + z20_valor_int',
			' END) - ',
			' CASE WHEN z20_tipo_doc = "FA" THEN ',
			' CASE WHEN z20_areaneg = 1 THEN ',
			' (SELECT NVL(SUM(z21_valor), 0) ',
				' FROM rept019, cxct021 ',
				' WHERE r19_compania   = z20_compania ',
				'   AND r19_localidad  = z20_localidad ',
				'   AND r19_tipo_dev   = z20_cod_tran ',
				'   AND r19_num_dev    = z20_num_tran ',
				'   AND z21_compania   = r19_compania ',
				'   AND z21_localidad  = r19_localidad ',
				'   AND z21_codcli     = z20_codcli ',
				'   AND z21_tipo_doc   = "NC" ',
				'   AND z21_fecha_emi <= z20_fecha_emi ',
				'   AND z21_cod_tran   = r19_cod_tran ',
				'   AND z21_num_tran   = r19_num_tran) ',
			' WHEN z20_areaneg = 2 THEN ',
			' (SELECT NVL(SUM(z21_valor), 0) ',
				' FROM cxct021 ',
				' WHERE z21_compania   = z20_compania ',
				'   AND z21_localidad  = z20_localidad ',
				'   AND z21_codcli     = z20_codcli ',
				'   AND z21_tipo_doc   = "NC" ',
				'   AND z21_fecha_emi <= z20_fecha_emi ',
				'   AND z21_areaneg    = z20_areaneg ',
				'   AND z21_cod_tran   = z20_cod_tran ',
				'   AND z21_num_tran   = z20_num_tran) ',
			' END ',
			' ELSE 0 ',
			' END ',
		' FROM cxct020, cxct001 ',
		' WHERE z20_compania    = ', vg_codcia,
			expr_loc CLIPPED,
		'   AND z20_moneda      = "', rm_par.moneda, '"',
		'   AND z20_fecha_emi  <= "', rm_par.fecha_cart, '"',
		'   AND z20_fecha_vcto  < "', rm_par.fecha_cart, '"',
		'   AND z01_codcli      = z20_codcli '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
DELETE FROM tempo_doc WHERE valor <= 0
SELECT COUNT(*) INTO vm_num_doc FROM tempo_doc 
ERROR ' '

END FUNCTION



FUNCTION genera_tabla_trabajo_resumen()
DEFINE query		CHAR(6000)
DEFINE tipo		VARCHAR(20)
DEFINE tabla		VARCHAR(20)
DEFINE campo		VARCHAR(20)
DEFINE camp1, camp2	VARCHAR(20)
DEFINE expr_whe		VARCHAR(200)
DEFINE expr_sql		VARCHAR(200)

ERROR "Generando resumen . . . espere por favor." ATTRIBUTE(NORMAL)
DELETE FROM tempo_acum
CASE rm_par.tipo_detalle 
	WHEN 'A'
		LET campo    = 'areaneg '
		LET camp1    = ' g03_areaneg '
		LET camp2    = ' g03_nombre '
		LET tabla    = ' gent003 '
		LET expr_whe = ' WHERE g03_compania = ', vg_codcia
		LET expr_sql = ' WHERE g03_areaneg  = ', campo CLIPPED
	WHEN "C"
		LET campo    = 'tipo_cli '
		LET tipo     = 'CL'
	WHEN "R"
		LET campo    = 'cartera '
		LET tipo     = 'CR'
	WHEN "P"
		LET campo    = 'codcli '
		LET camp1    = ' z01_codcli '
		LET camp2    = ' z01_nomcli '
		LET tabla    = ' cxct001 '
		LET expr_whe = NULL
		LET expr_sql = ' WHERE z01_codcli = ', campo CLIPPED
END CASE
IF rm_par.tipo_detalle = "C" OR rm_par.tipo_detalle = "R" THEN
	LET camp1    = ' g12_subtipo '
	LET camp2    = ' g12_nombre '
	LET tabla    = ' gent012 '
	LET expr_whe = ' WHERE g12_tiporeg = "', tipo CLIPPED, '"'
	LET expr_sql = ' WHERE g12_subtipo = ', campo CLIPPED
END IF
LET query = 'SELECT ', camp1 CLIPPED, ', ', camp2 CLIPPED, ' descri ',
		' FROM ', tabla CLIPPED,
		expr_whe CLIPPED,
		' INTO TEMP tmp_des '
PREPARE cons_des FROM query
EXECUTE cons_des
CALL subquery_pven_venc('1', campo, rm_par.rango1_i, rm_par.rango1_f)
CALL subquery_pven_venc('2', campo, rm_par.rango2_i, rm_par.rango2_f)
CALL subquery_pven_venc('3', campo, rm_par.rango3_i, rm_par.rango3_f)
CALL subquery_pven_venc('4', campo, rm_par.rango4_i, rm_par.rango4_f)
CALL subquery_pven_venc('5', campo, rm_par.rango5_i, 0)
LET query = 'INSERT INTO tempo_acum ',
		 'SELECT localidad, ', campo CLIPPED, ', descri, 0, ',
			'(SELECT NVL(SUM(val1), 0) ',
				' FROM t1 ',
				' WHERE cod1 = ', campo CLIPPED,
				'   AND loc1 = localidad), ',
			'(SELECT NVL(SUM(val2), 0) ',
				' FROM t2 ',
				' WHERE cod2 = ', campo CLIPPED,
				'   AND loc2 = localidad), ',
			'(SELECT NVL(SUM(val3), 0) ',
				' FROM t3 ',
				' WHERE cod3 = ', campo CLIPPED,
				'   AND loc3 = localidad), ',
			'(SELECT NVL(SUM(val4), 0) ',
				' FROM t4 ',
				' WHERE cod4 = ', campo CLIPPED,
				'   AND loc4 = localidad), ',
			'(SELECT NVL(SUM(val5), 0) ',
				' FROM t5 ',
				' WHERE cod5 = ', campo CLIPPED,
				'   AND loc5 = localidad) ',
			' FROM tempo_doc, tmp_des ',
				expr_sql CLIPPED,
			' GROUP BY 1, 2, 3, 4'
PREPARE tmp_acum FROM query
EXECUTE tmp_acum
DROP TABLE tmp_des
DROP TABLE t1
DROP TABLE t2
DROP TABLE t3
DROP TABLE t4
DROP TABLE t5
UPDATE tempo_acum
	SET val_col1 = val_col2 + val_col3 + val_col4 + val_col5 + val_col6
SELECT COUNT(*) INTO vm_num_res FROM tempo_acum
ERROR " "
IF vm_num_res = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF

END FUNCTION



FUNCTION subquery_pven_venc(indicador, campo, rango_i, rango_f)
DEFINE indicador	CHAR(1)
DEFINE campo		VARCHAR(20)
DEFINE rango_i, rango_f	SMALLINT
DEFINE subquery		CHAR(800)
DEFINE expr_fec		VARCHAR(100)
DEFINE expr_sql		VARCHAR(200)

LET expr_sql = NULL
LET expr_fec = '" - fecha BETWEEN ', rango_i, ' AND ', rango_f
IF rango_f = 0 THEN
	LET expr_fec = '" - fecha >= ', rango_i
END IF
LET expr_sql = '   AND "', rm_par.fecha_cart, expr_fec CLIPPED
LET subquery = 'SELECT localidad loc', indicador, ', ', campo CLIPPED,
			' cod', indicador, ', NVL(SUM(valor), 0) val',indicador,
		' FROM tempo_doc ',
		' WHERE fecha < "', rm_par.fecha_cart, '"',
			expr_sql CLIPPED,
		' GROUP BY 1, 2 ',
		' HAVING SUM(valor) > 0 ',
		' INTO TEMP t', indicador
PREPARE exec_tmp FROM subquery
EXECUTE exec_tmp

END FUNCTION



FUNCTION carga_arreglo_trabajo()
DEFINE query		VARCHAR(400)
DEFINE i		INTEGER

SELECT * FROM tempo_acum INTO TEMP tempo_acum1
UPDATE tempo_acum1 SET val_col1 = val_col1 / vm_divisor,
 	               val_col2 = val_col2 / vm_divisor,
	               val_col3 = val_col3 / vm_divisor,
	               val_col4 = val_col4 / vm_divisor,
	               val_col5 = val_col5 / vm_divisor,
	               val_col6 = val_col6 / vm_divisor
LET query = 'SELECT codigo, descripcion, cod_loc, val_col1, val_col2, ',
		'val_col3, val_col4, val_col5, val_col6 ',
		' FROM tempo_acum1 ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ',',
			      vm_columna_2, ' ', rm_orden[vm_columna_2] 
PREPARE tmp_a1 FROM query
DECLARE q_tmp_a1 CURSOR FOR tmp_a1
LET tot_col1 = 0
LET tot_col2 = 0
LET tot_col3 = 0
LET tot_col4 = 0
LET tot_col5 = 0
LET tot_col6 = 0
LET i        = 1
CASE vm_decimales
	WHEN 'N'
		FOREACH q_tmp_a1 INTO rm_det1[i].*
			LET tot_col1 = tot_col1 + rm_det1[i].val_col1 
			LET tot_col2 = tot_col2 + rm_det1[i].val_col2 
			LET tot_col3 = tot_col3 + rm_det1[i].val_col3 
			LET tot_col4 = tot_col4 + rm_det1[i].val_col4 
			LET tot_col5 = tot_col5 + rm_det1[i].val_col5 
			LET tot_col6 = tot_col6 + rm_det1[i].val_col6 
			LET i        = i + 1
			IF i > vm_max_rows THEN
				EXIT FOREACH
			END IF
		END FOREACH
	WHEN 'S'
		FOREACH q_tmp_a1 INTO rm_det2[i].cod_des, rm_descrip[i],
				rm_det2[i].cod_loc, rm_det2[i].val_col1,
				rm_det2[i].val_col2, rm_det2[i].val_col3,
				rm_det2[i].val_col4, rm_det2[i].val_col5,
				rm_det2[i].val_col6
			LET tot_col1 = tot_col1 + rm_det2[i].val_col1 
			LET tot_col2 = tot_col2 + rm_det2[i].val_col2 
			LET tot_col3 = tot_col3 + rm_det2[i].val_col3 
			LET tot_col4 = tot_col4 + rm_det2[i].val_col4 
			LET tot_col5 = tot_col5 + rm_det2[i].val_col5 
			LET tot_col6 = tot_col6 + rm_det2[i].val_col6 
			LET i        = i + 1
			IF i > vm_max_rows THEN
				EXIT FOREACH
			END IF
		END FOREACH
END CASE
LET vm_num_rows = i - 1
CALL muestrar_contadores_det(0, vm_num_rows)
DISPLAY BY NAME tot_col1, tot_col2, tot_col3, tot_col4, tot_col5, tot_col6
CASE vm_decimales
	WHEN 'N'
		FOR i = 1 TO fgl_scr_size ('rm_det1')
			CLEAR rm_det1[i].*
			IF i <= vm_num_rows THEN
				DISPLAY rm_det1[i].* TO rm_det1[i].*
			END IF
		END FOR
	WHEN 'S'
		CLEAR descripcion
		FOR i = 1 TO fgl_scr_size ('rm_det2')
			CLEAR rm_det2[i].*
			IF i <= vm_num_rows THEN
				DISPLAY rm_det2[i].* TO rm_det2[i].*
			END IF
		END FOR
		DISPLAY rm_descrip[1] TO descripcion
END CASE
DROP TABLE tempo_acum1

END FUNCTION



FUNCTION control_detalle()

CASE vm_decimales
	WHEN 'N'
		CALL muestra_detalle01()
	WHEN 'S'
		CALL muestra_detalle02()
END CASE

END FUNCTION



FUNCTION muestra_detalle01()
DEFINE i, col		INTEGER
DEFINE cod_aux		INTEGER
DEFINE loc_aux		SMALLINT
DEFINE pos_pan, pos_arr	INTEGER
DEFINE flag_p, flag_d	SMALLINT
DEFINE col1, col2	SMALLINT
DEFINE pos1, pos2	CHAR(4)

LET pos_pan = vm_pan
LET pos_arr = vm_arr
LET col     = vm_columna_1
LET col1    = vm_columna_1
LET col2    = vm_columna_2
LET pos1    = rm_orden[col1]
LET pos2    = rm_orden[col2]
LET flag_p  = 0
LET flag_d  = 0
CALL muestrar_contadores_det(0, vm_num_rows)
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
			CALL muestra_documentos(rm_det1[i].cod_des,
						rm_par.ind_venc,
						rm_det1[i].cod_loc)
			LET int_flag = 0
		ON KEY(F6)
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
		ON KEY(F7)
			CALL muestra_grafico_barras()
		ON KEY(F8)
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
		BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			CALL dialog.setcurrline(pos_pan, pos_arr)
			CALL muestrar_contadores_det(pos_arr, vm_num_rows)
		BEFORE ROW
			LET i = arr_curr()
			CALL muestrar_contadores_det(i, vm_num_rows)
			IF flag_d THEN
				CALL dialog.setcurrline(pos_pan, pos_arr)
				CALL muestrar_contadores_det(pos_arr,
								vm_num_rows)
				LET flag_d = 0
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
		LET cod_aux = rm_det1[pos_arr].cod_des
		LET loc_aux = rm_det1[pos_arr].cod_loc
	END IF
	CALL carga_arreglo_trabajo()
	IF flag_d THEN
		FOR i = 1 TO vm_num_rows
			IF cod_aux = rm_det1[i].cod_des AND
			   loc_aux = rm_det1[i].cod_loc
			THEN
				LET pos_arr = i
				IF vm_num_rows <= fgl_scr_size('rm_det1') THEN
					LET pos_pan = i
				END IF
				EXIT FOR
			END IF
		END FOR
	END IF
END WHILE
CALL muestrar_contadores_det(0, vm_num_rows)

END FUNCTION



FUNCTION muestra_detalle02()
DEFINE i, col		INTEGER
DEFINE cod_aux		INTEGER
DEFINE loc_aux		SMALLINT
DEFINE pos_pan, pos_arr	INTEGER
DEFINE flag_p, flag_d	SMALLINT
DEFINE col1, col2	SMALLINT
DEFINE pos1, pos2	CHAR(4)

LET pos_pan = vm_pan
LET pos_arr = vm_arr
LET col     = vm_columna_1
LET col1    = vm_columna_1
LET col2    = vm_columna_2
LET pos1    = rm_orden[col1]
LET pos2    = rm_orden[col2]
LET flag_p  = 0
LET flag_d  = 0
CALL muestrar_contadores_det(0, vm_num_rows)
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
			CALL muestra_documentos(rm_det2[i].cod_des,
						rm_par.ind_venc,
						rm_det2[i].cod_loc)
			LET int_flag = 0
		ON KEY(F6)
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
		ON KEY(F7)
			CALL muestra_grafico_barras()
		ON KEY(F8)
			CALL control_imprimir()
		ON KEY(F15)
			LET col      = 1
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
		BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			CALL dialog.setcurrline(pos_pan, pos_arr)
			CALL muestrar_contadores_det(pos_arr, vm_num_rows)
			DISPLAY rm_descrip[pos_arr] TO descripcion
		BEFORE ROW
			LET i = arr_curr()
			CALL muestrar_contadores_det(i, vm_num_rows)
			DISPLAY rm_descrip[i] TO descripcion
			IF flag_d THEN
				CALL dialog.setcurrline(pos_pan, pos_arr)
				CALL muestrar_contadores_det(pos_arr,
								vm_num_rows)
				DISPLAY rm_descrip[pos_arr] TO descripcion
				LET flag_d = 0
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
		LET cod_aux = rm_det2[pos_arr].cod_des
		LET loc_aux = rm_det2[pos_arr].cod_loc
	END IF
	CALL carga_arreglo_trabajo()
	IF flag_d THEN
		FOR i = 1 TO vm_num_rows
			IF cod_aux = rm_det2[i].cod_des AND
			   loc_aux = rm_det2[i].cod_loc
			THEN
				LET pos_arr = i
				IF vm_num_rows <= fgl_scr_size('rm_det2') THEN
					LET pos_pan = i
				END IF
				EXIT FOR
			END IF
		END FOR
	END IF
END WHILE
CLEAR descripcion
CALL muestrar_contadores_det(0, vm_num_rows)

END FUNCTION



FUNCTION muestrar_contadores_det(num_row, max_row)
DEFINE num_row, max_row	INTEGER

DISPLAY BY NAME num_row, max_row

END FUNCTION



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
DEFINE descri		VARCHAR(35)
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
DEFINE campo		CHAR(13)
DEFINE ind_venc		CHAR(1)
DEFINE comando		VARCHAR(100)
DEFINE r_obj		ARRAY[8] OF RECORD
				localidad	SMALLINT,
				codigo		INTEGER,
				descripcion	CHAR(20),
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
LET query = 'SELECT cod_loc te_loc, codigo te_codigo, ',
			'descripcion te_descripcion, ',
			'val_col1 te_vencido, ',
			'(val_col1 + val_col2 + val_col3 + val_col4 + ',
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
			LET campo = 'te_venc_fav'
		OTHERWISE
			LET label = 'TOTAL'
			LET campo = 'te_total'
	END CASE
	LET titulo = 'CARTERA ', label CLIPPED, ' POR '
	CASE rm_par.tipo_detalle
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
	OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/cxcf312_4"
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
				LET i    = FGL_LASTKEY() - key_f30
				CALL muestra_documentos(r_obj[i].codigo,
						ind_venc, r_obj[i].localidad)
				RUN comando
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



FUNCTION muestra_documentos(cod_des, ind_venc, locali)
DEFINE cod_des		INTEGER
DEFINE ind_venc		CHAR(1)
DEFINE locali		LIKE gent002.g02_localidad
DEFINE area		LIKE gent003.g03_areaneg
DEFINE tipcli, tipcar	LIKE gent012.g12_subtipo
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE comando          VARCHAR(150)

LET area   = 0
LET tipcli = 0
LET tipcar = 0
LET codcli = 0
CASE rm_par.tipo_detalle
	WHEN 'A'
		LET area   = cod_des
	WHEN "C"
		LET tipcli = cod_des
	WHEN "R"
		LET tipcar = cod_des
	WHEN "P"
		LET codcli = cod_des
END CASE
LET comando = 'fglrun cxcp315 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', rm_par.moneda, ' ', ind_venc, ' "D" "S" "N" ',
		rm_par.fecha_cart, ' ', area, ' ', tipcli, ' ',	tipcar, ' ',
		locali, ' ', codcli
RUN comando

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		INTEGER

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_list_cartera TO PIPE comando
FOR i = 1 TO vm_num_rows
	OUTPUT TO REPORT report_list_cartera(i)
END FOR
FINISH REPORT report_list_cartera

END FUNCTION



REPORT report_list_cartera(i)
DEFINE i		INTEGER
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE label		VARCHAR(11)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
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
  	      COLUMN 070, "PAGINA: ", PAGENO USING '&&&'
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 026, "ACUMULADOS CARTERA DE CLIENTES",
	      COLUMN 074, UPSHIFT(vg_proceso) 
	SKIP 1 LINES
	PRINT COLUMN 015, "** MONEDA         : ", rm_par.moneda,
		" ", rm_par.tit_mon
	IF rm_par.localidad IS NOT NULL THEN
		CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
			RETURNING r_g02.*
		PRINT COLUMN 015, "** LOCALIDAD      : ",
			rm_par.localidad USING '&&', " ", r_g02.g02_nombre
	END IF
	PRINT COLUMN 015, "** TIPO DE DETALLE: ", rm_par.tipo_detalle, " ",
		retorna_tipo_detalle(rm_par.tipo_detalle)
	PRINT COLUMN 015, "** CARTERA A FECHA: ",
		rm_par.fecha_cart USING 'dd-mm-yyyy',
	      COLUMN 052, "SE RESTARON NC POR DEVOLUCION"
	PRINT COLUMN 051, UPSHIFT(tit_precision)
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	IF vm_decimales = 'N' THEN
	PRINT COLUMN 037, UPSHIFT(tit_edad)
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 008, "DESCRIPCION",
	      COLUMN 025, "LC",
	      COLUMN 028, "TOT.VEN.";
	LET label = rm_par.rango1_i USING "<<&","-", rm_par.rango1_f USING "<<&"
	CALL fl_justifica_titulo('D', label, 8) RETURNING label
	PRINT COLUMN 037, label;
	LET label = rm_par.rango2_i USING "<<&","-", rm_par.rango2_f USING "<<&"
	CALL fl_justifica_titulo('D', label, 8) RETURNING label
	PRINT COLUMN 046, label;
	LET label = rm_par.rango3_i USING "<<&","-", rm_par.rango3_f USING "<<&"
	CALL fl_justifica_titulo('D', label, 8) RETURNING label
	PRINT COLUMN 055, label;
	LET label = rm_par.rango4_i USING "<<&","-", rm_par.rango4_f USING "<<&"
	CALL fl_justifica_titulo('D', label, 8) RETURNING label
	PRINT COLUMN 064, label;
	LET label = '>= ', rm_par.rango5_i USING "<<&"
	CALL fl_justifica_titulo('D', label, 8) RETURNING label
	PRINT COLUMN 073, label
	END IF
	IF vm_decimales = 'S' THEN
	PRINT COLUMN 023, UPSHIFT(tit_edad)
	PRINT COLUMN 001, "CODIG",
	      COLUMN 007, "LC",
	      COLUMN 010, "TOTAL VENC.";
	LET label = rm_par.rango1_i USING "<<&","-", rm_par.rango1_f USING "<<&"
	CALL fl_justifica_titulo('D', label, 11) RETURNING label
	PRINT COLUMN 022, label;
	LET label = rm_par.rango2_i USING "<<&","-", rm_par.rango2_f USING "<<&"
	CALL fl_justifica_titulo('D', label, 11) RETURNING label
	PRINT COLUMN 034, label;
	LET label = rm_par.rango3_i USING "<<&","-", rm_par.rango3_f USING "<<&"
	CALL fl_justifica_titulo('D', label, 11) RETURNING label
	PRINT COLUMN 046, label;
	LET label = rm_par.rango4_i USING "<<&","-", rm_par.rango4_f USING "<<&"
	CALL fl_justifica_titulo('D', label, 11) RETURNING label
	PRINT COLUMN 058, label;
	LET label = '>= ', rm_par.rango5_i USING "<<&"
	CALL fl_justifica_titulo('D', label, 11) RETURNING label
	PRINT COLUMN 070, label
	END IF
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	CASE vm_decimales
		WHEN 'N'
	PRINT COLUMN 001, rm_det1[i].cod_des		USING "####&&",
	      COLUMN 008, rm_det1[i].descripcion[1, 16] CLIPPED,
	      COLUMN 025, rm_det1[i].cod_loc		USING "&&",
	      COLUMN 028, rm_det1[i].val_col1		USING "----,--&",
	      COLUMN 037, rm_det1[i].val_col2		USING "----,--&",
	      COLUMN 046, rm_det1[i].val_col3		USING "----,--&",
	      COLUMN 055, rm_det1[i].val_col4		USING "----,--&",
	      COLUMN 064, rm_det1[i].val_col5		USING "----,--&",
	      COLUMN 073, rm_det1[i].val_col6		USING "----,--&"
		WHEN 'S'
	PRINT COLUMN 001, rm_det2[i].cod_des		USING "###&&",
	      COLUMN 007, rm_det2[i].cod_loc		USING "&&",
	      COLUMN 010, rm_det2[i].val_col1		USING "----,--&.##",
	      COLUMN 022, rm_det2[i].val_col2		USING "----,--&.##",
	      COLUMN 034, rm_det2[i].val_col3		USING "----,--&.##",
	      COLUMN 046, rm_det2[i].val_col4		USING "----,--&.##",
	      COLUMN 058, rm_det2[i].val_col5		USING "----,--&.##",
	      COLUMN 070, rm_det2[i].val_col6		USING "----,--&.##"
	END CASE
	
ON LAST ROW
	NEED 2 LINES
	CASE vm_decimales
		WHEN 'N'
	PRINT COLUMN 028, "--------",
	      COLUMN 037, "--------",
	      COLUMN 046, "--------",
	      COLUMN 055, "--------",
	      COLUMN 064, "--------",
	      COLUMN 073, "--------"
	PRINT COLUMN 015, "TOTALES ==>  ", tot_col1	USING "----,--&",
	      COLUMN 037, tot_col2			USING "----,--&",
	      COLUMN 046, tot_col3			USING "----,--&",
	      COLUMN 055, tot_col4			USING "----,--&",
	      COLUMN 064, tot_col5			USING "----,--&",
	      COLUMN 073, tot_col6			USING "----,--&"
		WHEN 'S'
	PRINT COLUMN 010, "-----------",
	      COLUMN 022, "-----------",
	      COLUMN 034, "-----------",
	      COLUMN 046, "-----------",
	      COLUMN 058, "-----------",
	      COLUMN 070, "-----------"
	PRINT COLUMN 002, "TOTALES",
	      COLUMN 010, tot_col1			USING "----,--&.##",
	      COLUMN 022, tot_col2			USING "----,--&.##",
	      COLUMN 034, tot_col3			USING "----,--&.##",
	      COLUMN 046, tot_col4			USING "----,--&.##",
	      COLUMN 058, tot_col5			USING "----,--&.##",
	      COLUMN 070, tot_col6			USING "----,--&.##"
	END CASE

END REPORT



FUNCTION retorna_tipo_detalle(tipo)
DEFINE tipo		CHAR(1)
DEFINE tipo_nom		VARCHAR(20)

CASE tipo
	WHEN 'A'
		LET tipo_nom = 'POR AREA DE NEGOCIO'
	WHEN 'P'
		LET tipo_nom = 'POR CLIENTE'
	WHEN 'C'
		LET tipo_nom = 'TIPO DE CLIENTE'
	WHEN 'R'
		LET tipo_nom = 'TIPO DE CARTERA'
END CASE
RETURN tipo_nom CLIPPED

END FUNCTION
