------------------------------------------------------------------------------
-- Titulo           : repp304.4gl - Consulta Ventas Vendedores
-- Elaboración      : 04-Sep-2001
-- Autor            : YEC
-- Formato Ejecución: fglrun repp304.4gl base_datos modulo compañía
-- Ultima Corrección: 24-Sep-2001 
-- Motivo Corrección: Habilitación de graficas. 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE tit_mes1		VARCHAR(11)
DEFINE tit_mes2		VARCHAR(11)
DEFINE tit_mes3		VARCHAR(11)
DEFINE tit_subt		VARCHAR(10)
DEFINE vm_campo_orden	SMALLINT
DEFINE vm_tipo_orden	CHAR(4)
DEFINE rm_par RECORD
	ano		SMALLINT,
	moneda		LIKE gent013.g13_moneda,
	tit_mon		VARCHAR(30),
	bodega		LIKE rept002.r02_codigo,
	tit_bod		VARCHAR(30),
	linea		LIKE rept003.r03_codigo,
	tit_lin		VARCHAR(30),
	indrot		LIKE rept004.r04_rotacion,
	tit_indrot	VARCHAR(30),
	mes1		CHAR(1),
	mes2		CHAR(1),
	mes3		CHAR(1),
	mes4		CHAR(1),
	mes5		CHAR(1),
	mes6		CHAR(1),
	mes7		CHAR(1),
	mes8		CHAR(1),
	mes9		CHAR(1),
	mes10		CHAR(1),
	mes11		CHAR(1),
	mes12		CHAR(1)
	END RECORD
DEFINE rm_cons ARRAY[200] OF RECORD
	name_vend	LIKE rept001.r01_nombres,
	valor_1		DECIMAL(14,2),
	valor_2		DECIMAL(14,2),
	valor_3		DECIMAL(14,2),
	tot_val		DECIMAL(14,2)
	END RECORD
DEFINE rm_vend ARRAY[200] OF INTEGER
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE vm_num_meses	SMALLINT
DEFINE vm_num_vend	SMALLINT
DEFINE vm_pantallas	SMALLINT
DEFINE vm_pant_cor	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_divisor	SMALLINT
DEFINE vm_ind_ini	SMALLINT
DEFINE vm_ind_fin	SMALLINT
DEFINE rm_meses  ARRAY[12] OF SMALLINT
DEFINE t_valor_1	DECIMAL(14,2)
DEFINE t_valor_2	DECIMAL(14,2)
DEFINE t_valor_3	DECIMAL(14,2)
DEFINE t_tot_val	DECIMAL(14,2)
DEFINE rm_color ARRAY[10] OF VARCHAR(10)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp304.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp304'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*

INITIALIZE rm_par.* TO NULL
CALL fl_lee_configuracion_facturacion() RETURNING r.*
LET rm_par.moneda = r.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon = rm_mon.g13_nombre
LET rm_par.ano     = YEAR(vg_fecha)
LET vm_campo_orden= 6
LET vm_tipo_orden = 'DESC'
LET rm_par.mes1   = 'S'
LET rm_par.mes2   = 'S'
LET rm_par.mes3   = 'S'
LET rm_par.mes4   = 'S'
LET rm_par.mes5   = 'S'
LET rm_par.mes6   = 'S'
LET rm_par.mes7   = 'S'
LET rm_par.mes8   = 'S'
LET rm_par.mes9   = 'S'
LET rm_par.mes10  = 'S'
LET rm_par.mes11  = 'S'
LET rm_par.mes12  = 'S'
OPEN WINDOW w_repf304_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_cons FROM '../forms/repf304_1'
DISPLAY FORM f_cons
DISPLAY 'V e n d e d o r'  TO tit_mod
LET vm_max_rows = 200
CALL carga_colores()
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	LET vm_pant_cor   = 1
	CALL obtiene_numero_meses()
	CALL genera_tabla_temporal()
	IF int_flag THEN
		DROP TABLE temp_acum
		CONTINUE WHILE
	END IF
	CALL carga_arreglo_consulta()
	CALL muestra_consulta()
	DROP TABLE temp_acum
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repf304_1
EXIT PROGRAM

END FUNCTION



FUNCTION lee_parametros()
DEFINE resp		CHAR(3)
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE bod_aux		LIKE rept002.r02_codigo
DEFINE lin_aux		LIKE rept003.r03_codigo
DEFINE ind_aux		LIKE rept004.r04_rotacion
DEFINE num_dec		SMALLINT
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_tip		RECORD LIKE rept006.*
DEFINE r_ind		RECORD LIKE rept004.*

DISPLAY 'Enero'    TO tit_mes1
DISPLAY 'Febrero'  TO tit_mes2
DISPLAY 'Marzo'    TO tit_mes3 
DISPLAY 'Subtotal' TO tit_subt
DISPLAY BY NAME rm_par.tit_mon
LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.ano, rm_par.moneda, rm_par.bodega,
				     rm_par.linea, rm_par.indrot) THEN
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_hacer_pregunta('Desea salir de la consulta','No')
			RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux,rm_par.tit_mon,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda = mon_aux
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF INFIELD(bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T', '2', 'A', 'S', 'V')
				RETURNING bod_aux,rm_par.tit_bod
			IF bod_aux IS NOT NULL THEN
				LET rm_par.bodega = bod_aux
				DISPLAY BY NAME rm_par.bodega, rm_par.tit_bod
			END IF
		END IF
		IF INFIELD(linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia) RETURNING lin_aux,rm_par.tit_lin
			IF lin_aux IS NOT NULL THEN
				LET rm_par.linea = lin_aux
				DISPLAY BY NAME rm_par.linea, rm_par.tit_lin
			END IF
		END IF
		IF INFIELD(indrot) THEN
			CALL fl_ayuda_clases(vg_codcia) RETURNING ind_aux,rm_par.tit_indrot
			IF ind_aux IS NOT NULL THEN
				LET rm_par.indrot = ind_aux
				DISPLAY BY NAME rm_par.indrot, rm_par.tit_indrot
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD ano
		IF rm_par.ano > YEAR(vg_fecha) THEN
			CALL fl_mostrar_mensaje('Año incorrecto.','exclamation')
			NEXT FIELD ano
		END IF
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
			IF rm_mon.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = rm_mon.g13_nombre
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			CLEAR tit_mon
		END IF
	AFTER FIELD bodega
		IF rm_par.bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_par.bodega) RETURNING r_bod.*
			IF r_bod.r02_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				NEXT FIELD bodega
			END IF
			LET rm_par.tit_bod = r_bod.r02_nombre
			DISPLAY BY NAME rm_par.tit_bod
		ELSE
			LET rm_par.tit_bod = NULL
			CLEAR tit_bod
		END IF
	AFTER FIELD linea
		IF rm_par.linea IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_par.linea) RETURNING r_lin.*
			IF r_lin.r03_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Línea no existe.','exclamation')
				NEXT FIELD linea
			END IF
			LET rm_par.tit_lin = r_lin.r03_nombre
			DISPLAY BY NAME rm_par.tit_lin
		ELSE
			LET rm_par.tit_lin = NULL
			CLEAR tit_lin
		END IF
	AFTER FIELD indrot
		IF rm_par.indrot IS NOT NULL THEN
			CALL fl_lee_indice_rotacion(vg_codcia, rm_par.indrot) RETURNING r_ind.*
			IF r_ind.r04_rotacion IS NULL THEN
				CALL fl_mostrar_mensaje('Indice de rotación no existe.','exclamation')
				NEXT FIELD indrot
			END IF
			LET rm_par.tit_indrot = r_ind.r04_nombre
			DISPLAY BY NAME rm_par.tit_indrot
		ELSE
			LET rm_par.tit_indrot = NULL
			CLEAR tit_indrot
		END IF
	AFTER INPUT 
		IF rm_par.mes1  = 'N' AND rm_par.mes2  = 'N' AND
		   rm_par.mes3  = 'N' AND rm_par.mes4  = 'N' AND
		   rm_par.mes5  = 'N' AND rm_par.mes6  = 'N' AND
		   rm_par.mes7  = 'N' AND rm_par.mes8  = 'N' AND
		   rm_par.mes9  = 'N' AND rm_par.mes10 = 'N' AND
		   rm_par.mes11 = 'N' AND rm_par.mes12 = 'N' THEN
			CALL fl_mostrar_mensaje('Seleccion un mes por lo menos.','exclamation')
			NEXT FIELD mes1
		END IF
END INPUT

END FUNCTION



FUNCTION genera_tabla_temporal()
DEFINE cod_vend		LIKE rept001.r01_codigo
DEFINE mes, i		SMALLINT
DEFINE valor, val	DECIMAL(14,2)
DEFINE r		RECORD LIKE rept001.*
DEFINE campo		VARCHAR(15)
DEFINE expr1, expr2	VARCHAR(80)
DEFINE expr3       	VARCHAR(80)
DEFINE query		VARCHAR(800)
DEFINE expr_ins		VARCHAR(200)
DEFINE mes_c		CHAR(10)

ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
CREATE TEMP TABLE temp_acum
       (te_vendedor	SMALLINT,
	te_nombres	VARCHAR(40),
	te_mes1		DECIMAL(14,2),
	te_mes2		DECIMAL(14,2),
	te_mes3		DECIMAL(14,2),
	te_mes4		DECIMAL(14,2),
	te_mes5		DECIMAL(14,2),
	te_mes6		DECIMAL(14,2),
	te_mes7		DECIMAL(14,2),
	te_mes8		DECIMAL(14,2),
	te_mes9 	DECIMAL(14,2),
	te_mes10	DECIMAL(14,2),
	te_mes11	DECIMAL(14,2),
	te_mes12	DECIMAL(14,2))
LET expr1 = ' 1 = 1 '
LET expr2 = ' 1 = 1 '
LET expr3 = ' 1 = 1 '
IF rm_par.bodega IS NOT NULL THEN
	LET expr1 = " r60_bodega = '", rm_par.bodega CLIPPED, "' "
END IF
IF rm_par.linea IS NOT NULL THEN
	LET expr2 = " r60_linea = '", rm_par.linea CLIPPED, "' "
END IF
IF rm_par.indrot IS NOT NULL THEN
	LET expr3 = " r60_rotacion = '", rm_par.indrot CLIPPED, "' "
END IF
LET query = 'SELECT r60_vendedor, MONTH(r60_fecha), SUM(r60_precio) ',
		' FROM rept060, rept002 ',
		' WHERE r60_compania = ', vg_codcia, 
		' AND YEAR(r60_fecha) = ? ',
		' AND r60_moneda = ? AND ',
		  expr1, ' AND ',
		  expr2, ' AND ',
		  expr3,
		' AND r02_compania  = r60_compania ',
		' AND r02_codigo    = r60_bodega ',
		' AND r02_localidad = ', vg_codloc,
		' GROUP BY 1, 2 '
PREPARE men FROM query
DECLARE q_men CURSOR FOR men
OPEN q_men USING rm_par.ano, rm_par.moneda
LET vm_num_vend = 0
WHILE TRUE
	FETCH q_men INTO cod_vend, mes, valor
	IF STATUS = NOTFOUND THEN
		EXIT WHILE
	END IF
	LET  i = 1
	WHILE i <= vm_num_meses
		IF rm_meses[i] = mes THEN
			EXIT WHILE
		END IF
		LET i = i + 1
	END WHILE
	IF i > vm_num_meses THEN
		CONTINUE WHILE
	END IF
	LET mes_c = mes
	LET campo = 'te_mes', mes_c
	LET expr_ins = NULL
	FOR i = 1 TO 12
		IF mes = i THEN
			LET val = valor
		ELSE
			LET val = 0
		END IF
		LET expr_ins = expr_ins CLIPPED, ',', val 
	END FOR
	SELECT * FROM temp_acum WHERE te_vendedor = cod_vend
	IF STATUS = NOTFOUND THEN
		IF vm_num_vend = vm_max_rows THEN
			CONTINUE WHILE
		END IF
		LET vm_num_vend = vm_num_vend + 1
		CALL fl_lee_vendedor_rep(vg_codcia, cod_vend) RETURNING r.*
		LET query = "INSERT INTO temp_acum VALUES(", cod_vend, ", '",
			     r.r01_nombres CLIPPED, "'", expr_ins CLIPPED, ')'
		PREPARE in_temp FROM query
		EXECUTE in_temp 
	ELSE
		LET query = 'UPDATE temp_acum SET ', campo, '= ', campo, ' + ?',
				' WHERE te_vendedor = ?'
		PREPARE up_temp FROM query
		EXECUTE up_temp USING valor, cod_vend 
	END IF
END WHILE
CLOSE q_men
FREE q_men
LET int_flag = 0
IF vm_num_vend = 0 THEN
	LET int_flag = 1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
SELECT SUM(te_mes1+te_mes2+te_mes3+te_mes4+te_mes5+te_mes6+
           te_mes7+te_mes8+te_mes9+te_mes10+te_mes11+te_mes12)
	INTO valor
	FROM temp_acum
LET vm_divisor = 1
IF valor > 999999 THEN
	LET vm_divisor = 1000
END IF

END FUNCTION



FUNCTION carga_arreglo_consulta()
DEFINE i		SMALLINT
DEFINE expr_meses	VARCHAR(300)
DEFINE expr_suma	VARCHAR(300)
DEFINE expr_ceros	VARCHAR(10)
DEFINE mes_c		CHAR(10)
DEFINE query		VARCHAR(600)

SELECT * FROM temp_acum INTO TEMP temp_acum1
UPDATE temp_acum1 SET te_mes1 = te_mes1 / vm_divisor,
                      te_mes2 = te_mes2 / vm_divisor,
                      te_mes3 = te_mes3 / vm_divisor,
                      te_mes4 = te_mes4 / vm_divisor,
                      te_mes5 = te_mes5 / vm_divisor,
                      te_mes6 = te_mes6 / vm_divisor,
                      te_mes7 = te_mes7 / vm_divisor,
                      te_mes8 = te_mes8 / vm_divisor,
                      te_mes9 = te_mes9 / vm_divisor,
                      te_mes10= te_mes10/ vm_divisor,
                      te_mes11= te_mes11/ vm_divisor,
                      te_mes12= te_mes12/ vm_divisor
CASE vm_pant_cor 
	WHEN 1
		LET vm_ind_ini = 1
		LET vm_ind_fin = 3
	WHEN 2
		LET vm_ind_ini = 4
		LET vm_ind_fin = 6
	WHEN 3
		LET vm_ind_ini = 7
		LET vm_ind_fin = 9
	WHEN 4
		LET vm_ind_ini = 10
		LET vm_ind_fin = 12
END CASE
LET expr_ceros = ''
IF vm_num_meses < vm_ind_fin THEN
	FOR i = vm_num_meses + 1 TO vm_ind_fin
		LET expr_ceros = expr_ceros CLIPPED, ',0 '
	END FOR
	LET vm_ind_fin = vm_num_meses
END IF
LET expr_meses = NULL
FOR i = vm_ind_ini TO vm_ind_fin 
	LET mes_c = rm_meses[i]
	LET expr_meses = expr_meses CLIPPED, ', te_mes', mes_c
END FOR
LET expr_suma  = ',0'
FOR i = 1 TO vm_num_meses
	LET mes_c = rm_meses[i]
	LET expr_suma  = expr_suma  CLIPPED, '+ te_mes', mes_c
END FOR
LET query = 'SELECT te_nombres ', 
		expr_meses CLIPPED,
		expr_ceros CLIPPED,
		expr_suma CLIPPED, ', te_vendedor',
		' FROM temp_acum1 ',
		' ORDER BY ', vm_campo_orden, ' ', vm_tipo_orden
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET t_valor_1 = 0
LET t_valor_2 = 0
LET t_valor_3 = 0
LET t_tot_val = 0
LET i = 1
FOREACH q_cons INTO rm_cons[i].*, rm_vend[i]
	LET t_valor_1 = t_valor_1 + rm_cons[i].valor_1
	LET t_valor_2 = t_valor_2 + rm_cons[i].valor_2
	LET t_valor_3 = t_valor_3 + rm_cons[i].valor_3
	LET t_tot_val = t_tot_val + rm_cons[i].tot_val
	LET i = i + 1
END FOREACH
DROP TABLE temp_acum1

END FUNCTION



FUNCTION muestra_consulta()
DEFINE i, j		SMALLINT
DEFINE nuevo_DISPLAY	SMALLINT
DEFINE pos_pantalla	SMALLINT
DEFINE pos_arreglo	SMALLINT
DEFINE vend_aux		LIKE veht001.v01_nombres
DEFINE resp		CHAR(3)

ERROR " " ATTRIBUTE(NORMAL) 
LET nuevo_DISPLAY = 0
CALL set_count(vm_num_vend)
WHILE TRUE
	CALL muestra_nombre_meses()
	CALL muestra_precision()
	LET int_flag = 0
	--#CALL fgl_keysetlabel('F7','Precisión')
	--#CALL fgl_keysetlabel('F9','Grafico')
	--#CALL fgl_keysetlabel('F10','PDF')
	IF vm_pantallas > 1 THEN
		--#CALL fgl_keysetlabel('F6','Mas Meses')
	ELSE
		--#CALL fgl_keysetlabel('F6','')
	END IF
	DISPLAY BY NAME t_valor_1, t_valor_2, t_valor_3, t_tot_val
	DISPLAY ARRAY rm_cons TO rm_cons.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL muestra_movimientos_vendedor(rm_vend[i], rm_meses[vm_ind_ini], rm_meses[vm_ind_ini], null, null, null, null, null, null, null)
			LET int_flag = 0
		ON KEY(F6)
			IF vm_pantallas > 1 THEN
				IF vm_pant_cor = 4 OR vm_pant_cor = vm_pantallas THEN
					LET vm_pant_cor = 1
				ELSE
					LET vm_pant_cor = vm_pant_cor + 1
				END IF
				LET nuevo_DISPLAY = 1
				LET pos_pantalla = scr_line()
				LET pos_arreglo  = arr_curr()
				CALL carga_arreglo_consulta()
				EXIT DISPLAY
			END IF
		ON KEY(F7)
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
			LET nuevo_DISPLAY = 1
			LET pos_pantalla = scr_line()
			LET pos_arreglo  = arr_curr()
			CALL carga_arreglo_consulta()
			EXIT DISPLAY
		ON KEY(F9)
			--CALL FGL_WINQUESTION(vg_producto,'Desea grafico de barras','Yes','Yes|No|Cancel','question',1)
			CALL fl_hacer_pregunta('Desea grafico de barras','Yes')
				RETURNING resp
			IF resp = 'Yes' THEN
				CALL muestra_grafico_barras()
			END IF
			IF resp = 'No' THEN
				CALL muestra_grafico_pastel()
			END IF
			LET int_flag = 0
		ON KEY(F10)
			CALL generar_pdf()
		ON KEY(F15)
			LET vm_campo_orden = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET vm_campo_orden = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET vm_campo_orden = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET vm_campo_orden = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET vm_campo_orden = 5
			LET int_flag = 2
			EXIT DISPLAY
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("RETURN","")
			--#CALL dialog.keysetlabel("ACCEPT","")
		BEFORE ROW
			IF nuevo_DISPLAY THEN
				CALL dialog.setcurrline(pos_pantalla,pos_arreglo)
				LET nuevo_DISPLAY = 0
			END IF
			LET i = arr_curr()
			MESSAGE i, ' de ', vm_num_vend
		AFTER DISPLAY 
			CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF int_flag = 2 THEN
		CALL asigna_orden()
		LET nuevo_DISPLAY = 1
		LET pos_pantalla  = scr_line()
		LET pos_arreglo   = arr_curr()
		LET vend_aux      = rm_cons[pos_arreglo].name_vend
		CALL carga_arreglo_consulta()
		IF vm_num_vend > fgl_scr_size('rm_cons') THEN
			FOR i = 1 TO vm_num_vend
				IF rm_cons[i].name_vend = vend_aux THEN
					LET pos_arreglo = i
					EXIT FOR
				END IF
			END FOR
		END IF
	END IF
END WHILE

END FUNCTION



FUNCTION asigna_orden()

IF vm_tipo_orden = 'ASC' THEN	
	LET vm_tipo_orden = 'DESC'
ELSE
	LET vm_tipo_orden = 'ASC'
END IF

END FUNCTION



FUNCTION muestra_movimientos_vendedor(cod_vend, mes_ini, mes_fin, out1, out2, 
			 out3, out4, out5, out6, out7)
DEFINE cod_vend		LIKE rept001.r01_codigo
DEFINE mes_ini, mes_fin	SMALLINT
DEFINE out1, out2, out3	LIKE rept001.r01_codigo
DEFINE out4, out5, out6	LIKE rept001.r01_codigo
DEFINE out7		LIKE rept001.r01_codigo
DEFINE fec_ini, fec_fin	DATE
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_vend		RECORD LIKE rept001.*
DEFINE r_cab		RECORD LIKE rept019.*
DEFINE r_det		RECORD LIKE rept020.*
DEFINE num_rows, i	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE tot_uni		DECIMAL(8,2)
DEFINE tot_val, valor	DECIMAL(14,2)
DEFINE comando		VARCHAR(160)
DEFINE descri_cli	CHAR(28)
DEFINE descri_item	CHAR(28)
DEFINE columna_act	SMALLINT
DEFINE columna_ant	SMALLINT
DEFINE orden_act	CHAR(4)
DEFINE orden_ant	CHAR(4)
DEFINE orden		VARCHAR(100)
DEFINE prog		VARCHAR(10)
DEFINE query		VARCHAR(300)
DEFINE expr_vend	VARCHAR(120)
DEFINE rt		RECORD LIKE gent021.*
DEFINE r_mov ARRAY[4000] OF RECORD
	fecha		DATE,
	cod_bod		LIKE rept002.r02_codigo,
	tipo		LIKE rept019.r19_cod_tran,
	numero		LIKE rept019.r19_num_tran,
	item		LIKE rept010.r10_codigo,
	unidades	DECIMAL(8,2),
	valor		DECIMAL(14,2)
	END RECORD

CREATE TEMP TABLE temp_mov
	(te_fecha	DATETIME YEAR TO SECOND,
	 te_bodega	CHAR(2),
	 te_tipo	CHAR(2),
	 te_numero	INTEGER,
	 te_item	CHAR(15),
	 te_unidades	DECIMAL(8,2),
	 te_valor	DECIMAL(14,2))
LET max_rows = 4000
OPEN WINDOW w_mov AT 4,5 WITH FORM "../forms/repf304_2"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
DISPLAY 'Fecha'       TO tit_col1
DISPLAY 'Bd'          TO tit_col2
DISPLAY 'Tp'          TO tit_col3
DISPLAY '# Documento' TO tit_col4
DISPLAY 'Item'        TO tit_col5
DISPLAY 'Uni.'        TO tit_col6
DISPLAY 'V a l o r'   TO tit_col7
LET fec_ini = MDY(mes_ini, 01, rm_par.ano)
LET fec_fin = MDY(mes_fin, 01, rm_par.ano) + 1 UNITS MONTH - 1 UNITS DAY
DISPLAY BY NAME fec_ini, fec_fin, rm_par.moneda,
	rm_par.tit_mon, rm_par.bodega, rm_par.tit_bod, rm_par.linea,
	rm_par.tit_lin, rm_par.indrot, rm_par.tit_indrot
IF cod_vend <> 0 THEN
	DISPLAY BY NAME cod_vend
	CALL fl_lee_vendedor_rep(vg_codcia, cod_vend) RETURNING r_vend.*
	DISPLAY r_vend.r01_nombres TO name_vend
	LET expr_vend = ' r19_vendedor = ', cod_vend
ELSE
	DISPLAY 'OTROS' TO name_vend
	LET expr_vend = ' r19_vendedor NOT IN (', 
				out1, ',', out2, ',', 
				out3, ',', out4, ',', 
				out5, ',', out6, ',', 
				out7, ')'
END IF	
LET int_flag = 0
INPUT BY NAME fec_ini, fec_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	AFTER INPUT
		IF fec_ini > fec_fin THEN
			CALL fl_mostrar_mensaje('Rango de fechas incorrecto.','exclamation')
			NEXT FIELD fec_ini
		END IF
END INPUT			
IF int_flag THEN
	LET int_flag = 0
	CLOSE WINDOW w_mov
	DROP TABLE temp_mov
	RETURN
END IF
ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT * FROM rept019 ',
		' WHERE r19_compania = ? AND ',
		expr_vend, ' AND ',
	        ' r19_fecing BETWEEN EXTEND(?', ',YEAR TO SECOND) AND ',
	        ' EXTEND(?', ', YEAR TO SECOND) + 23 UNITS HOUR +  ',
		' 59 UNITS MINUTE '
PREPARE cab FROM query
DECLARE q_cab CURSOR FOR cab
LET num_rows = 0
LET tot_uni = 0
LET tot_val = 0
OPEN q_cab USING vg_codcia, fec_ini, fec_fin 
WHILE TRUE
	FETCH q_cab INTO r_cab.*
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	IF r_cab.r19_localidad <> vg_codloc THEN
		CONTINUE WHILE
	END IF
	{
	IF rm_par.bodega IS NOT NULL AND 
		r_cab.r19_bodega_ori <> rm_par.bodega THEN
		CONTINUE WHILE
	END IF
	}
	IF rm_par.moneda <> r_cab.r19_moneda THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_cod_transaccion(r_cab.r19_cod_tran) RETURNING rt.*
	IF rt.g21_act_estad <> 'S' THEN
		CONTINUE WHILE
	END IF
	IF num_rows >= max_rows THEN
		EXIT WHILE
	END IF
	DECLARE q_det CURSOR FOR 
		SELECT * FROM rept020
			WHERE r20_compania = vg_codcia AND 
			      r20_localidad = vg_codloc AND
		              r20_cod_tran = r_cab.r19_cod_tran AND
		              r20_num_tran = r_cab.r19_num_tran
			ORDER BY r20_orden
	FOREACH q_det INTO r_det.*
		IF rm_par.linea IS NOT NULL AND 
			r_det.r20_linea <> rm_par.linea THEN
			CONTINUE FOREACH
		END IF
		IF rm_par.indrot IS NOT NULL AND 
			r_det.r20_rotacion <> rm_par.indrot THEN
			CONTINUE FOREACH
		END IF
		IF rm_par.bodega IS NOT NULL AND 
			r_det.r20_bodega <> rm_par.bodega THEN
			CONTINUE FOREACH
		END IF
		LET valor = (r_det.r20_precio * r_det.r20_cant_ven) - 
			     r_det.r20_val_descto
		IF r_cab.r19_cod_tran = 'DF' OR r_cab.r19_cod_tran = 'AF' THEN
			LET r_det.r20_cant_ven = r_det.r20_cant_ven * (-1) 
			LET valor = valor * -1
		END IF
		INSERT INTO temp_mov VALUES (r_cab.r19_fecing, 	
			r_cab.r19_bodega_ori, r_det.r20_cod_tran,
			r_det.r20_num_tran,   r_det.r20_item, 
			r_det.r20_cant_ven,   valor)
		LET tot_uni = tot_uni + r_det.r20_cant_ven
		LET tot_val = tot_val + valor
		LET num_rows = num_rows + 1
		IF num_rows = max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
END WHILE
IF num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_mov
	DROP TABLE temp_mov
	RETURN
END IF
LET orden_act = 'DESC'
LET orden_ant = 'ASC'
LET columna_act = 1
LET columna_ant = 4
DISPLAY BY NAME tot_uni, tot_val
ERROR ' '
WHILE TRUE
	IF orden_act = 'ASC' THEN
		LET orden_act = 'DESC'
	ELSE
		LET orden_act = 'ASC'
	END IF
	LET orden = columna_act, ' ', orden_act, ', ', columna_ant, ' ',
		    orden_ant 
	LET query = 'SELECT * FROM temp_mov ORDER BY ', orden CLIPPED
	PREPARE mt FROM query
	DECLARE q_mt CURSOR FOR mt
	LET  i = 1
	FOREACH q_mt INTO r_mov[i].*
		LET i = i + 1
	END FOREACH 
	CALL set_count(num_rows)
	DISPLAY ARRAY r_mov TO r_mov.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			LET prog = ' repp217 '
			IF r_mov[i].tipo = 'FA' THEN
				LET prog = ' repp308 '
			END IF
			LET comando = 'fglrun', prog CLIPPED, ' ', vg_base, ' ',
				vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
				r_mov[i].tipo, ' ', r_mov[i].numero
			RUN comando
		ON KEY(F15)
			LET columna_ant = columna_act
			LET columna_act = 1 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET columna_ant = columna_act
			LET columna_act = 2 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET columna_ant = columna_act
			LET columna_act = 3 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET columna_ant = columna_act
			LET columna_act = 4 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET columna_ant = columna_act
			LET columna_act = 5 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET columna_ant = columna_act
			LET columna_act = 6 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET columna_ant = columna_act
			LET columna_act = 7 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("RETURN","")
			--#CALL dialog.keysetlabel("ACCEPT","")
		BEFORE ROW
			LET i = arr_curr()
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, 
				r_mov[i].tipo, r_mov[i].numero)
				RETURNING r_cab.*
			CALL fl_lee_item(vg_codcia, r_mov[i].item) RETURNING r_item.* 
			LET descri_cli  = r_cab.r19_nomcli
			LET descri_item = r_item.r10_nombre
			MESSAGE i, ' de ', num_rows, ' ** ', descri_cli, ' ** ', 
				descri_item
		AFTER DISPLAY 
			CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_mov
DROP TABLE temp_mov
RETURN

END FUNCTION



FUNCTION muestra_nombre_meses()
DEFINE tit_mes1		VARCHAR(11)
DEFINE tit_mes2		VARCHAR(11)
DEFINE tit_mes3		VARCHAR(11)
DEFINE i		SMALLINT

LET tit_mes2 = ''
LET tit_mes3 = ''
LET i = vm_ind_ini 
LET tit_mes1 = fl_retorna_nombre_mes(rm_meses[i])
LET i = i + 1
IF i <= vm_num_meses THEN
	LET tit_mes2 = fl_retorna_nombre_mes(rm_meses[i])
	LET i = i + 1
	IF i <= vm_num_meses THEN
		LET tit_mes3 = fl_retorna_nombre_mes(rm_meses[i])
	END IF
END IF
DISPLAY BY NAME tit_mes1, tit_mes2, tit_mes3	

END FUNCTION



FUNCTION muestra_precision()

CASE vm_divisor
	WHEN 1
		DISPLAY 'Valores Expresados en Unidades' TO tit_precision
	WHEN 10
		DISPLAY 'Valores Expresados en Decenas' TO tit_precision
	WHEN 100
		DISPLAY 'Valores Expresados en Centenas' TO tit_precision
	WHEN 1000
		DISPLAY 'Valores Expresados en Miles' TO tit_precision
END CASE

END FUNCTION



FUNCTION obtiene_numero_meses() 
DEFINE i		SMALLINT

FOR i = 1 TO 12
	LET rm_meses[i] = 0
END FOR
LET i = 0
IF rm_par.mes1 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 1
END IF
IF rm_par.mes2 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 2
END IF
IF rm_par.mes3 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 3
END IF
IF rm_par.mes4 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 4
END IF
IF rm_par.mes5 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 5
END IF
IF rm_par.mes6 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 6
END IF
IF rm_par.mes7 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 7
END IF
IF rm_par.mes8 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 8
END IF
IF rm_par.mes9 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 9
END IF
IF rm_par.mes10 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 10
END IF
IF rm_par.mes11 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 11
END IF
IF rm_par.mes12 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 12
END IF
LET vm_num_meses = i
LET vm_pantallas = vm_num_meses / 3
IF vm_num_meses MOD 3 > 0 THEN
	LET vm_pantallas = vm_pantallas + 1
END IF

END FUNCTION



FUNCTION muestra_grafico_pastel()
DEFINE query		VARCHAR(400)
DEFINE expr_suma	VARCHAR(200)
DEFINE mes_c		CHAR(10)
DEFINE i, indice	SMALLINT
DEFINE limite		SMALLINT
DEFINE tot_valor	DECIMAL(14,2)
DEFINE residuo		DECIMAL(14,2)
DEFINE factor		DECIMAL(20,12)
DEFINE grados_ini	DECIMAL(10,0)
DEFINE grados_fin	DECIMAL(10,0)
DEFINE vendedor		LIKE rept001.r01_codigo
DEFINE nombres		LIKE rept001.r01_nombres
DEFINE valor		DECIMAL(14,2)
DEFINE max_elementos	SMALLINT
DEFINE pos_ini		SMALLINT
DEFINE tecla		CHAR(1)
DEFINE titulo		CHAR(75)
DEFINE key_n		SMALLINT
DEFINE key_c		CHAR(3)
DEFINE key_f30		SMALLINT
DEFINE val_aux		CHAR(16)
DEFINE r_obj ARRAY[8] OF RECORD
	vendedor	LIKE rept001.r01_codigo,
	etiqueta	LIKE rept001.r01_nombres,
	valor		DECIMAL(14,2),
	id_obj_arc	SMALLINT,
	id_obj_rec	SMALLINT
	END RECORD

LET mes_c = rm_par.ano
LET titulo = 'VALORES VENDIDOS POR VENDEDOR DURANTE MESES SELECCIONADOS DEL ANO: ' || mes_c
--
-- Solo 8 elementos se mostraran. Desde el 8vo. hasta el final se acumularan
-- como uno solo, bajo el título 'OTROS'.
--
LET limite = 8		
				
LET max_elementos = vm_num_vend 
IF vm_num_vend > limite THEN
	LET max_elementos = limite
END IF 
LET expr_suma  = '0'
FOR i = 1 TO 12
	LET mes_c = i
	LET expr_suma  = expr_suma  CLIPPED, '+ te_mes', mes_c CLIPPED
END FOR
LET query = 'SELECT SUM(', expr_suma CLIPPED, ') ',
		' FROM temp_acum'
PREPARE ct FROM query
DECLARE q_ct CURSOR FOR ct
OPEN q_ct 
FETCH q_ct INTO tot_valor
CLOSE q_ct
IF tot_valor IS NULL THEN
	RETURN
END IF
LET query = 'SELECT te_vendedor, te_nombres, ', expr_suma CLIPPED,
		' FROM temp_acum ',
		' ORDER BY 3 DESC'
PREPARE gr1 FROM query
DECLARE q_gr1 CURSOR FOR gr1
CALL drawinit()
OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/repf304_3"
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
CALL drawselect('c001')
CALL drawanchor('w')
LET i = drawtext(960,10,titulo CLIPPED)
LET titulo = 'Total: ', tot_valor USING "#,###,###,##&.##"
CALL drawfillcolor('blue')
LET i = drawtext(910,10, titulo)
LET i = drawtext(030,10,'Haga click sobre un vendedor para ver detalles')
LET factor = 360 / tot_valor  -- Factor para obtener los grados de c/elemento.
LET indice = 1
LET grados_ini = 0 
LET residuo = tot_valor
LET pos_ini = 810
FOR i = 1 TO limite
	LET r_obj[i].etiqueta = NULL
END FOR
FOREACH q_gr1 INTO vendedor, nombres, valor
	LET r_obj[indice].valor    = valor
	LET r_obj[indice].vendedor = vendedor
	IF indice = max_elementos THEN
		LET grados_fin = 360 - grados_ini
		IF indice = limite THEN
			LET r_obj[indice].etiqueta = 'OTROS'
			LET r_obj[indice].valor    = residuo
		ELSE
			LET r_obj[indice].etiqueta = nombres
		END IF
	ELSE
		LET grados_fin = valor * factor
		LET r_obj[indice].etiqueta = nombres
	END IF
	LET residuo = residuo - valor
	CALL drawfillcolor(rm_color[indice])
	LET r_obj[indice].id_obj_arc = drawarc(750,100,400, grados_ini, grados_fin)
	LET r_obj[indice].id_obj_rec = drawrectangle(pos_ini,750,25,75)
	LET val_aux = r_obj[indice].valor USING "#,###,###,##&.##"
	LET i = drawtext(pos_ini + 45,750, r_obj[indice].etiqueta)
	LET i = drawtext(pos_ini + 12,520, val_aux)
	LET pos_ini = pos_ini - 100
	LET grados_ini = grados_ini + grados_fin
	IF indice = max_elementos THEN
		EXIT FOREACH
	END IF
	LET indice = indice + 1
END FOREACH
FOR i = 1 TO max_elementos
	LET key_n = i + 30
	LET key_c = 'F', key_n
	CALL drawbuttonleft(r_obj[i].id_obj_arc, key_c)
	CALL drawbuttonleft(r_obj[i].id_obj_rec, key_c)
END FOR
LET key_f30  = FGL_KEYVAL("F30")
LET int_flag = 0
INPUT BY NAME tecla
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F31,F32,F33,F34,F35,F36,F37,F38)
		LET i = FGL_LASTKEY() - key_f30
		IF i = 8 THEN
			CALL muestra_movimientos_vendedor(0,
				    rm_meses[1], rm_meses[vm_num_meses],
		                    r_obj[1].vendedor, r_obj[2].vendedor, 
				    r_obj[3].vendedor, r_obj[4].vendedor, 
				    r_obj[5].vendedor, r_obj[6].vendedor,
		     		    r_obj[7].vendedor)
		ELSE
			CALL muestra_movimientos_vendedor(r_obj[i].vendedor,
				    rm_meses[1], rm_meses[vm_num_meses],
				    null, null, null, null, null, null, null)
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F31","")
		--#CALL dialog.keysetlabel("F32","")
		--#CALL dialog.keysetlabel("F33","")
		--#CALL dialog.keysetlabel("F34","")
		--#CALL dialog.keysetlabel("F35","")
		--#CALL dialog.keysetlabel("F36","")
		--#CALL dialog.keysetlabel("F37","")
		--#CALL dialog.keysetlabel("F38","")
	AFTER FIELD tecla
		NEXT FIELD tecla
END INPUT
LET int_flag = 0
CLOSE WINDOW w_gr1
RETURN

END FUNCTION



FUNCTION muestra_grafico_barras()
DEFINE query		VARCHAR(400)
DEFINE expr_suma	VARCHAR(200)
DEFINE mes_c		CHAR(10)
DEFINE i, indice	SMALLINT
DEFINE limite		SMALLINT
DEFINE valor_max	DECIMAL(14,2)
DEFINE residuo		DECIMAL(14,2)
DEFINE factor		DECIMAL(20,12)
DEFINE grados_ini	DECIMAL(10,0)
DEFINE grados_fin	DECIMAL(10,0)
DEFINE vendedor		LIKE rept001.r01_codigo
DEFINE nombres		LIKE rept001.r01_nombres
DEFINE valor, val_x	DECIMAL(14,2)
DEFINE tot_valor   	DECIMAL(14,2)
DEFINE max_elementos	SMALLINT
DEFINE pos_ini		SMALLINT
DEFINE tecla		CHAR(1)
DEFINE titulo		CHAR(75)
DEFINE key_n		SMALLINT
DEFINE key_c		CHAR(3)
DEFINE key_f30		SMALLINT
DEFINE val_aux		CHAR(16)
DEFINE start_x          SMALLINT
DEFINE start_y          SMALLINT
DEFINE max_x            SMALLINT
DEFINE max_y            SMALLINT
DEFINE segments         SMALLINT
DEFINE startkey_x       SMALLINT
DEFINE startkey_y       SMALLINT
DEFINE key_interval     SMALLINT
DEFINE key_width        SMALLINT
DEFINE key_length       SMALLINT
DEFINE key_y            SMALLINT
DEFINE start_key_text   SMALLINT
DEFINE start_bar        SMALLINT
DEFINE scale            DECIMAL
DEFINE num_bars         INTEGER
DEFINE max_bar          INTEGER
DEFINE bar_width        INTEGER
DEFINE r_obj ARRAY[8] OF RECORD
	vendedor	LIKE rept001.r01_codigo,
	etiqueta	LIKE rept001.r01_nombres,
	valor		DECIMAL(14,2),
	id_obj_rec1	SMALLINT,
	id_obj_rec2	SMALLINT
	END RECORD

LET mes_c = rm_par.ano
LET titulo = 'VALORES VENDIDOS POR VENDEDOR DURANTE MESES SELECCIONADOS DEL ANO: ' || mes_c
LET limite = 8
LET expr_suma  = '0'
FOR i = 1 TO 12
	LET mes_c = i
	LET expr_suma  = expr_suma  CLIPPED, '+ te_mes', mes_c CLIPPED
END FOR
LET query = 'SELECT te_vendedor, te_nombres, ', expr_suma CLIPPED,
		' FROM temp_acum ',
		' ORDER BY 3 DESC'
PREPARE gr2 FROM query
DECLARE q_gr2 CURSOR FOR gr2
CREATE TEMP TABLE temp_bar
	(te_vendedor	SMALLINT,
	 te_nombres	VARCHAR(20),
	 te_valor	DECIMAL(14,2),
         te_indice	SMALLINT)
LET i = 1
LET val_x = 0
LET tot_valor = 0
FOREACH q_gr2 INTO vendedor, nombres, valor
	LET tot_valor = tot_valor + valor
	IF i <= limite - 1 THEN
		INSERT INTO temp_bar VALUES (vendedor, nombres, valor, i)
		LET i = i + 1
	ELSE
		LET val_x = val_x + valor
	END IF	
END FOREACH
IF i = 1 THEN
	RETURN
END IF
IF val_x > 0 THEN
	INSERT INTO temp_bar VALUES (0, 'OTROS', val_x, i)
END IF
SELECT MAX(te_valor) INTO valor_max FROM temp_bar 
---------
LET segments = 1
LET start_x = 050
LET start_y = 080
LET max_x = 500
LET max_y = 750
LET startkey_x = 800
LET startkey_y = 800
LET key_interval = 90
LET key_width = 25
LET key_length = 75
#LET start_key_text = startkey_x + key_length + 25
LET start_key_text = startkey_x
---------

CALL drawinit()
OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/repf304_3"
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
CALL drawselect('c001')
CALL drawanchor('w')

-------------
CALL DrawFillColor("black")
LET i = drawline(start_y, start_x, 0, max_x)
LET i = drawline(start_y, start_x, max_y, 0)
-------------

LET i = drawtext(960,10,titulo CLIPPED)
LET titulo = 'Total: ', tot_valor USING "#,###,###,##&.##"
LET i = drawtext(910,10, titulo)
LET i = drawtext(030,10,'Haga click sobre un vendedor para ver detalles')

LET max_elementos = vm_num_vend
IF max_elementos > limite THEN
	LET max_elementos = limite
END IF
--------------
LET scale = max_y / valor_max
LET bar_width = max_x / max_elementos / segments
#LET start_bar = start_x + bar_width
LET start_bar = start_x
--------------
FOR i = 1 TO limite
	LET r_obj[i].etiqueta = NULL
END FOR
LET key_y = startkey_y
LET indice = 0
DECLARE q_bar CURSOR FOR SELECT * FROM temp_bar
	ORDER BY 4
FOREACH q_bar INTO vendedor, nombres, valor
        CALL DrawFillColor(rm_color[indice+1])
	LET r_obj[indice + 1].vendedor = vendedor
	LET r_obj[indice + 1].valor = valor
	LET r_obj[indice + 1].etiqueta = nombres
        LET r_obj[indice + 1].id_obj_rec1 = DrawRectangle (start_y,
                         start_bar + bar_width * segments * indice,
                         scale * valor, bar_width)
        LET r_obj[indice + 1].id_obj_rec2 = DrawRectangle (key_y, startkey_x, key_width,  key_length)
        LET i = DrawText(key_y + 40, start_key_text, nombres)
	LET val_aux = r_obj[indice + 1].valor USING "#,###,###,##&.##"
	LET i = drawtext(key_y + 10,start_key_text - 220, val_aux)
        LET indice = indice + 1
        LET key_y = key_y - key_interval
END FOREACH
DROP TABLE temp_bar
FOR i = 1 TO max_elementos
	LET key_n = i + 30
	LET key_c = 'F', key_n
	CALL drawbuttonleft(r_obj[i].id_obj_rec1, key_c)
	CALL drawbuttonleft(r_obj[i].id_obj_rec2, key_c)
END FOR
LET key_f30  = FGL_KEYVAL("F30")
LET int_flag = 0
INPUT BY NAME tecla
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F31,F32,F33,F34,F35,F36,F37,F38)
		LET i = FGL_LASTKEY() - key_f30
		IF i = 8 THEN
			CALL muestra_movimientos_vendedor(0,
				    rm_meses[1], rm_meses[vm_num_meses],
		                    r_obj[1].vendedor, r_obj[2].vendedor, 
				    r_obj[3].vendedor, r_obj[4].vendedor, 
				    r_obj[5].vendedor, r_obj[6].vendedor,
		     		    r_obj[7].vendedor)
		ELSE
			CALL muestra_movimientos_vendedor(r_obj[i].vendedor,
				    rm_meses[1], rm_meses[vm_num_meses],
				    null, null, null, null, null, null, null)
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F31","")
		--#CALL dialog.keysetlabel("F32","")
		--#CALL dialog.keysetlabel("F33","")
		--#CALL dialog.keysetlabel("F34","")
		--#CALL dialog.keysetlabel("F35","")
		--#CALL dialog.keysetlabel("F36","")
		--#CALL dialog.keysetlabel("F37","")
		--#CALL dialog.keysetlabel("F38","")
	AFTER FIELD tecla
		NEXT FIELD tecla
END INPUT
LET int_flag = 0
CLOSE WINDOW w_gr1
RETURN

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



FUNCTION generar_pdf()
DEFINE comando		CHAR(256)

LET comando = "ev.jsp?anio=", rm_par.ano USING "&&&&"
CALL fl_ejecuta_reporte_pdf(vg_codloc, comando, 'F')

END FUNCTION
