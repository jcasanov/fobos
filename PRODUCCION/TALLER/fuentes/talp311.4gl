------------------------------------------------------------------------------
-- Titulo           : talp311.4gl - Consulta Mano Obra Mecánicos
-- Elaboracion      : 04-Sep-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun talp311.4gl base_datos modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE tit_mes1		VARCHAR(11)
DEFINE tit_mes2		VARCHAR(11)
DEFINE tit_mes3		VARCHAR(11)
DEFINE tit_subt		VARCHAR(10)
DEFINE vm_campo_orden	SMALLINT
DEFINE vm_tipo_orden	CHAR(4)
DEFINE rm_par RECORD
	localidad	LIKE gent002.g02_localidad,
	tit_local	LIKE gent002.g02_nombre,
	ano		SMALLINT,
	moneda		LIKE gent013.g13_moneda,
	tit_mon		VARCHAR(30),
	modelo		LIKE talt004.t04_modelo,
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
	name_meca	LIKE talt003.t03_nombres,
	valor_1		DECIMAL(14,2),
	valor_2		DECIMAL(14,2),
	valor_3		DECIMAL(14,2),
	tot_val		DECIMAL(14,2)
	END RECORD
DEFINE rm_meca ARRAY[200] OF INTEGER
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE vm_num_meses	SMALLINT
DEFINE vm_num_meca	SMALLINT
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
CALL startlog('../logs/talp311.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'talp311'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*

INITIALIZE rm_par.* TO NULL
CALL fl_lee_configuracion_facturacion() RETURNING r.*
LET rm_par.moneda = r.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
CALL fl_lee_localidad(vg_codcia, rm_par.localidad) 
	RETURNING rg_loc.*
LET vm_campo_orden= 5
LET vm_tipo_orden = 'DESC'
LET rm_par.tit_local = rg_loc.g02_nombre
LET rm_par.tit_mon = rm_mon.g13_nombre
LET rm_par.ano     = YEAR(TODAY)
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
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_cons FROM '../forms/talf311_1'
DISPLAY FORM f_cons
LET vm_max_rows = 200
CALL carga_colores()
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		RETURN
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

END FUNCTION



FUNCTION lee_parametros()
DEFINE resp		CHAR(3)
DEFINE loc_aux		LIKE gent002.g02_localidad
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE mod_aux		LIKE talt004.t04_modelo
DEFINE lin_aux		LIKE talt001.t01_linea
DEFINE num_dec		SMALLINT
DEFINE r_mod		RECORD LIKE talt004.*
DEFINE r_loc		RECORD LIKE gent002.*

DISPLAY 'M e c á n i c o' TO tit_meca
DISPLAY 'Enero'    TO tit_mes1
DISPLAY 'Febrero'  TO tit_mes2
DISPLAY 'Marzo'    TO tit_mes3 
DISPLAY 'Subtotal' TO tit_subt
LET int_flag = 0
#DISPLAY BY NAME rm_par.tit_mon
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.ano, rm_par.moneda, rm_par.modelo,
				     rm_par.localidad) THEN
			RETURN
		END IF
		LET INT_FLAG = 0
		CALL FGL_WINQUESTION(vg_producto, 
                                     'Desea salir de la consulta',
                                     'No', 'Yes|No|Cancel',
                                     'question', 1) RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF infield(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING loc_aux, rm_par.tit_local
			IF loc_aux IS NOT NULL THEN
				LET rm_par.localidad = loc_aux
				DISPLAY BY NAME rm_par.localidad, rm_par.tit_local
			END IF
		END IF
		IF infield(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux,rm_par.tit_mon,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda = mon_aux
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF infield(modelo) THEN
			CALL fl_ayuda_tipos_vehiculos(vg_codcia) RETURNING mod_aux, lin_aux
			IF mod_aux IS NOT NULL THEN
				LET rm_par.modelo = mod_aux
				DISPLAY BY NAME rm_par.modelo
			END IF
		END IF
		LET int_flag = 0
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
	AFTER FIELD ano
		IF rm_par.ano > YEAR(TODAY) THEN
			CALL fgl_winmessage(vg_producto, 'Año incorrecto', 'exclamation')
			NEXT FIELD ano
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
	AFTER FIELD modelo
		IF rm_par.modelo IS NOT NULL THEN
			CALL fl_lee_tipo_vehiculo(vg_codcia, rm_par.modelo) RETURNING r_mod.*
			IF r_mod.t04_modelo IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Modelo no existe', 'exclamation')
				NEXT FIELD modelo
			END IF
		END IF
	AFTER INPUT 
		IF rm_par.mes1  = 'N' AND rm_par.mes2  = 'N' AND
		   rm_par.mes3  = 'N' AND rm_par.mes4  = 'N' AND
		   rm_par.mes5  = 'N' AND rm_par.mes6  = 'N' AND
		   rm_par.mes7  = 'N' AND rm_par.mes8  = 'N' AND
		   rm_par.mes9  = 'N' AND rm_par.mes10 = 'N' AND
		   rm_par.mes11 = 'N' AND rm_par.mes12 = 'N' THEN
			CALL fgl_winmessage(vg_producto, 'Seleccion un mes por lo menos', 'exclamation')
			NEXT FIELD mes1
		END IF
END INPUT

END FUNCTION



FUNCTION genera_tabla_temporal()
DEFINE cod_meca		LIKE talt003.t03_mecanico
DEFINE mes, i		SMALLINT
DEFINE valor, val	DECIMAL(14,2)
DEFINE r		RECORD LIKE talt003.*
DEFINE campo		VARCHAR(15)
DEFINE expr1, expr2	VARCHAR(80)
DEFINE query		VARCHAR(400)
DEFINE expr_ins		VARCHAR(200)
DEFINE mes_c		CHAR(10)

ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
CREATE TEMP TABLE temp_acum
       (te_mecanico	SMALLINT,
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
IF rm_par.localidad IS NOT NULL THEN
	LET expr1 = " t41_localidad = '", rm_par.localidad CLIPPED, "' "
END IF
IF rm_par.modelo IS NOT NULL THEN
	LET expr2 = " t41_modelo = '", rm_par.modelo CLIPPED, "' "
END IF
LET query = 'SELECT t41_mecanico, t41_mes, SUM(t41_mano_obra) ',
		' FROM talt041 ',
		' WHERE t41_ano = ? AND t41_moneda = ? AND ',
		  expr1, ' AND ',
		  expr2,
		' GROUP BY 1, 2 '
PREPARE men FROM query
DECLARE q_men CURSOR FOR men
OPEN q_men USING rm_par.ano, rm_par.moneda
LET vm_num_meca = 0
WHILE TRUE
	FETCH q_men INTO cod_meca, mes, valor
	IF status = NOTFOUND THEN
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
	SELECT * FROM temp_acum WHERE te_mecanico = cod_meca
	IF status = NOTFOUND THEN
		IF vm_num_meca = vm_max_rows THEN
			CONTINUE WHILE
		END IF
		LET vm_num_meca = vm_num_meca + 1
		CALL fl_lee_mecanico(vg_codcia, cod_meca)
			RETURNING r.*
		LET query = "INSERT INTO temp_acum VALUES(", cod_meca, ", '",
			     r.t03_nombres CLIPPED, "'", expr_ins CLIPPED, ')'
		PREPARE in_temp FROM query
		EXECUTE in_temp 
	ELSE
		LET query = 'UPDATE temp_acum SET ', campo, '= ', campo, ' + ?',
				' WHERE te_mecanico = ?'
		PREPARE up_temp FROM query
		EXECUTE up_temp USING valor, cod_meca 
	END IF
END WHILE
LET int_flag = 0
IF vm_num_meca = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
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
		expr_suma CLIPPED,
		', te_mecanico',
		' FROM temp_acum1 ',
		' ORDER BY ', vm_campo_orden, ' ', vm_tipo_orden
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET t_valor_1 = 0
LET t_valor_2 = 0
LET t_valor_3 = 0
LET t_tot_val = 0
LET i = 1
FOREACH q_cons INTO rm_cons[i].*, rm_meca[i]
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
DEFINE nuevo_display	SMALLINT
DEFINE pos_pantalla	SMALLINT
DEFINE pos_arreglo	SMALLINT
DEFINE meca_aux		LIKE veht001.v01_nombres
DEFINE resp		CHAR(3)

ERROR " " ATTRIBUTE(NORMAL) 
CALL set_count(vm_num_meca)
LET nuevo_display = 0
WHILE TRUE
	CALL muestra_nombre_meses()
	CALL muestra_precision()
	DISPLAY BY NAME t_valor_1, t_valor_2, t_valor_3, t_tot_val
	LET int_flag = 0
	CALL fgl_keysetlabel('F8','Gráfico')
	DISPLAY ARRAY rm_cons TO rm_cons.*
		BEFORE DISPLAY 
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			IF nuevo_display THEN
				CALL dialog.setcurrline(pos_pantalla,pos_arreglo)
				LET nuevo_display = 0
			END IF
			LET i = arr_curr()
			MESSAGE i, ' de ', vm_num_meca
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL muestra_movimientos_mecanico(rm_meca[i], rm_cons[i].name_meca, rm_meses[vm_ind_ini], NULL, NULL, NULL, NULL, NULL, NULL, NULL)
		ON KEY(F6)
			IF vm_pantallas > 1 THEN
				IF vm_pant_cor = 4 OR vm_pant_cor = vm_pantallas THEN
					LET vm_pant_cor = 1
				ELSE
					LET vm_pant_cor = vm_pant_cor + 1
				END IF
				LET nuevo_display = 1
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
			LET nuevo_display = 1
			LET pos_pantalla = scr_line()
			LET pos_arreglo  = arr_curr()
			CALL carga_arreglo_consulta()
			EXIT DISPLAY
		ON KEY(F8)
			CALL FGL_WINQUESTION(vg_producto, 
                                     'Desea gráfico de barras',
                                     'Yes', 'Yes|No|Cancel',
                                     'question', 1) RETURNING resp
			IF resp = 'Yes' THEN
				CALL muestra_grafico_barras()
			END IF
			IF resp = 'No' THEN
				CALL muestra_grafico_pastel()
			END IF
			LET int_flag = 0
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
	END DISPLAY
	IF int_flag = 1 THEN
		RETURN
	END IF
	IF int_flag = 2 THEN
		CALL asigna_orden()
		LET nuevo_display = 1
		LET pos_pantalla  = scr_line()
		LET pos_arreglo   = arr_curr()
		LET meca_aux      = rm_cons[pos_arreglo].name_meca
		CALL carga_arreglo_consulta()
		IF vm_num_meca > fgl_scr_size('rm_cons') THEN
			FOR i = 1 TO vm_num_meca
				IF rm_cons[i].name_meca = meca_aux THEN
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



FUNCTION muestra_movimientos_mecanico(cod_meca, name_meca, mes, out1, out2, 
			 out3, out4, out5, out6, out7)
DEFINE name_meca	LIKE talt003.t03_nombres
DEFINE cod_meca, meca	LIKE talt003.t03_mecanico
DEFINE mes		SMALLINT
DEFINE out1, out2, out3	LIKE talt003.t03_mecanico
DEFINE out4, out5, out6	LIKE talt003.t03_mecanico
DEFINE out7		LIKE talt003.t03_mecanico
DEFINE fec_ini, fec_fin	DATE
DEFINE num_rows, i	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE valor, tot_val	DECIMAL(14,2)
DEFINE columna_act	SMALLINT
DEFINE columna_ant	SMALLINT
DEFINE orden_act	CHAR(4)
DEFINE orden_ant	CHAR(4)
DEFINE orden		VARCHAR(100)
DEFINE query		VARCHAR(300)
DEFINE comando		VARCHAR(140)
DEFINE modelo		LIKE talt004.t04_modelo
DEFINE localidad	LIKE gent002.g02_localidad
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE r_mot ARRAY[2000] OF RECORD
	fecha		DATE,
	num_ot		LIKE talt023.t23_orden,
	num_fa		LIKE talt023.t23_num_factura,
	descri_tar	LIKE talt024.t24_descripcion,
	valor		DECIMAL(14,2)
	END RECORD

CREATE TEMP TABLE temp_mov
	(te_fecha	DATETIME YEAR TO SECOND,
	 te_num_ot	INTEGER,
	 te_num_fa	INTEGER,
	 te_descri_tar	CHAR(40),
	 te_valor	DECIMAL(14,2))
LET max_rows = 2000
OPEN WINDOW w_mov AT 4,3 WITH FORM "../forms/talf311_2"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
DISPLAY 'Fecha'     TO tit_col1
DISPLAY 'Orden'     TO tit_col2
DISPLAY 'Factura'   TO tit_col3
DISPLAY 'T a r e a' TO tit_col4
DISPLAY 'V a l o r' TO tit_col5
LET fec_ini = MDY(mes, 01, rm_par.ano)
LET fec_fin = fec_ini + 1 UNITS MONTH - 1 UNITS DAY
DISPLAY BY NAME fec_ini, fec_fin, rm_par.moneda,
	rm_par.tit_mon, rm_par.modelo, name_meca
LET int_flag = 0
INPUT BY NAME fec_ini, fec_fin WITHOUT DEFAULTS
	AFTER INPUT
		IF fec_ini > fec_fin THEN
			CALL fgl_winmessage(vg_producto, 'Rango de fechas incorrecto', 'exclamation')
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
DECLARE q_tar CURSOR FOR 
	SELECT t24_fecing, t24_orden, t23_num_factura, t24_descripcion,
	       t24_valor_tarea, t23_localidad, t23_modelo, t23_moneda, 
	       t24_mecanico
	        FROM talt024, talt023
		WHERE t24_compania  = vg_codcia AND 
                      #t24_mecanico  = cod_meca AND
	              t24_fecing BETWEEN EXTEND(fec_ini, YEAR TO SECOND) AND
	              EXTEND(fec_fin, YEAR TO SECOND) + 23 UNITS HOUR + 
		      59 UNITS MINUTE AND
		      t24_compania  = t23_compania AND 
		      t24_localidad = t23_localidad AND 
		      t24_orden     = t23_orden
		ORDER BY 1
LET num_rows = 1
LET tot_val = 0
FOREACH q_tar INTO r_mot[num_rows].*, localidad, modelo, moneda, meca
	IF cod_meca = 0 THEN
		IF meca = out1 OR meca = out2 OR meca = out3 OR meca = out4 OR
		   meca = out5 OR meca = out6 OR meca = out7 THEN
			CONTINUE FOREACH
		END IF
	ELSE	
		IF cod_meca <> meca THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF rm_par.localidad IS NOT NULL AND localidad <> rm_par.localidad THEN
		CONTINUE FOREACH
	END IF
	IF rm_par.moneda <> moneda THEN 
		CONTINUE FOREACH
	END IF
	IF rm_par.modelo IS NOT NULL AND modelo <> rm_par.modelo THEN
		CONTINUE FOREACH
	END IF
	LET tot_val = tot_val + r_mot[num_rows].valor
	INSERT INTO temp_mov VALUES (r_mot[num_rows].*)
	LET num_rows = num_rows + 1
	IF num_rows = max_rows + 1 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_rows = num_rows - 1
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
DISPLAY BY NAME tot_val
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
	FOREACH q_mt INTO r_mot[i].*
		LET i = i + 1
	END FOREACH 
	CALL set_count(num_rows)
	DISPLAY ARRAY r_mot TO r_mot.*
		BEFORE DISPLAY 
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			LET comando = 'cd ', vg_dir_fobos CLIPPED, vg_separador,
				      'TALLER', vg_separador, 'fuentes; ',
				      'fglrun talp204 ', vg_base, 
				      ' TA ', vg_codcia, ' ', vg_codloc, ' ',
				      r_mot[i].num_ot, ' O'
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
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE WINDOW w_mov
DROP TABLE temp_mov
LET int_flag = 0

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
DEFINE mecanico		LIKE talt003.t03_mecanico
DEFINE nombres		LIKE talt003.t03_nombres
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
	mecanico	LIKE talt003.t03_mecanico,
	etiqueta	LIKE talt003.t03_nombres,
	valor		DECIMAL(14,2),
	id_obj_arc	SMALLINT,
	id_obj_rec	SMALLINT
	END RECORD

LET mes_c = rm_par.ano
LET titulo = 'MANO OBRA DE MECANICOS DURANTE MESES SELECCIONADOS DEL ANO: ' || mes_c
--
-- Solo 8 elementos se mostraran. Desde el 8vo. hasta el final se acumularán
-- como uno solo, bajo el título 'OTROS'.
--
LET limite = 8		
				
LET max_elementos = vm_num_meca 
IF vm_num_meca > limite THEN
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
LET query = 'SELECT te_mecanico, te_nombres, ', expr_suma CLIPPED,
		' FROM temp_acum ',
		' ORDER BY 3 DESC'
PREPARE gr1 FROM query
DECLARE q_gr1 CURSOR FOR gr1
CALL drawinit()
OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/talf310_3"
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
CALL drawselect('c001')
CALL drawanchor('w')
LET i = drawtext(960,10,titulo CLIPPED)
LET titulo = 'Total: ', tot_valor USING "#,###,###,##&.##"
CALL drawfillcolor('blue')
LET i = drawtext(910,10, titulo)
LET i = drawtext(030,10,'Haga click sobre un mecánico para ver detalles')
LET factor = 360 / tot_valor  -- Factor para obtener los grados de c/elemento.
LET indice = 1
LET grados_ini = 0 
LET residuo = tot_valor
LET pos_ini = 810
FOR i = 1 TO limite
	LET r_obj[i].etiqueta = NULL
END FOR
FOREACH q_gr1 INTO mecanico, nombres, valor
	LET r_obj[indice].valor    = valor
	LET r_obj[indice].mecanico = mecanico
	IF indice = max_elementos THEN
		LET grados_fin = 360 - grados_ini
		IF indice = limite THEN
			LET nombres = 'OTROS'
			LET r_obj[indice].etiqueta = nombres
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
	LET r_obj[indice].id_obj_rec = drawrectangle(pos_ini,900,25,75)
	LET val_aux = r_obj[indice].valor USING "#,###,###,##&.##"
	LET nombres = fl_justifica_titulo('D', nombres, 30)
	LET i = drawtext(pos_ini + 45,580, nombres)
	LET i = drawtext(pos_ini + 12,680, val_aux)
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
LET key_f30 = FGL_KEYVAL("F30")
INPUT BY NAME tecla
	BEFORE INPUT
		CALL dialog.keysetlabel("ACCEPT","")
		CALL dialog.keysetlabel("F31","")
		CALL dialog.keysetlabel("F32","")
		CALL dialog.keysetlabel("F33","")
		CALL dialog.keysetlabel("F34","")
		CALL dialog.keysetlabel("F35","")
		CALL dialog.keysetlabel("F36","")
		CALL dialog.keysetlabel("F37","")
		CALL dialog.keysetlabel("F38","")
	ON KEY(F31,F32,F33,F34,F35,F36,F37,F38)
		LET i = FGL_LASTKEY() - key_f30
		IF i = 8 THEN
			CALL muestra_movimientos_mecanico(0,
				    'OTROS', rm_meses[vm_num_meses],
		                    r_obj[1].mecanico, r_obj[2].mecanico, 
				    r_obj[3].mecanico, r_obj[4].mecanico, 
				    r_obj[5].mecanico, r_obj[6].mecanico,
		     		    r_obj[7].mecanico)
		ELSE
			CALL muestra_movimientos_mecanico(r_obj[i].mecanico,
				    r_obj[i].etiqueta, rm_meses[vm_ind_ini],
				    null, null, null, null, null, null, null)
		END IF
	AFTER FIELD tecla
		NEXT FIELD tecla
END INPUT
CLOSE WINDOW w_gr1

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
DEFINE mecanico		LIKE talt003.t03_mecanico
DEFINE nombres		LIKE talt003.t03_nombres
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
	mecanico	LIKE talt003.t03_mecanico,
	etiqueta	LIKE talt003.t03_nombres,
	valor		DECIMAL(14,2),
	id_obj_rec1	SMALLINT,
	id_obj_rec2	SMALLINT
	END RECORD

LET mes_c = rm_par.ano
LET titulo = 'MANO OBRA DE MECANICOS DURANTE MESES SELECCIONADOS DEL ANO: ' || mes_c
LET limite = 8
LET expr_suma  = '0'
FOR i = 1 TO 12
	LET mes_c = i
	LET expr_suma  = expr_suma  CLIPPED, '+ te_mes', mes_c CLIPPED
END FOR
LET query = 'SELECT te_mecanico, te_nombres, ', expr_suma CLIPPED,
		' FROM temp_acum ',
		' ORDER BY 3 DESC'
PREPARE gr2 FROM query
DECLARE q_gr2 CURSOR FOR gr2
CREATE TEMP TABLE temp_bar
	(te_mecanico	SMALLINT,
	 te_nombres	VARCHAR(30),
	 te_valor	DECIMAL(14,2),
         te_indice	SMALLINT)
LET i = 1
LET val_x = 0
LET tot_valor = 0
FOREACH q_gr2 INTO mecanico, nombres, valor
	LET tot_valor = tot_valor + valor
	IF i <= limite - 1 THEN
		INSERT INTO temp_bar VALUES (mecanico, nombres, valor, i)
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
LET startkey_x = 900
LET startkey_y = 800
LET key_interval = 90
LET key_width = 25
LET key_length = 75
#LET start_key_text = startkey_x + key_length + 25
LET start_key_text = startkey_x
---------

CALL drawinit()
OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/talf310_3"
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
LET i = drawtext(030,10,'Haga click sobre un mecáico para ver detalles')

LET max_elementos = vm_num_meca
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
FOREACH q_bar INTO mecanico, nombres, valor, i
        CALL DrawFillColor(rm_color[indice+1])
	LET r_obj[indice + 1].valor    = valor
	LET r_obj[indice + 1].mecanico = mecanico
	LET r_obj[indice + 1].etiqueta = nombres
        LET r_obj[indice + 1].id_obj_rec1 = DrawRectangle (start_y,
                         start_bar + bar_width * segments * indice,
                         scale * valor, bar_width)
        LET r_obj[indice + 1].id_obj_rec2 = DrawRectangle (key_y, startkey_x, key_width,  key_length)
	LET nombres = fl_justifica_titulo('D', nombres, 30)
        LET i = DrawText(key_y + 40, start_key_text - 320, nombres)
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
LET key_f30 = FGL_KEYVAL("F30")
INPUT BY NAME tecla
	BEFORE INPUT
		CALL dialog.keysetlabel("ACCEPT","")
		CALL dialog.keysetlabel("F31","")
		CALL dialog.keysetlabel("F32","")
		CALL dialog.keysetlabel("F33","")
		CALL dialog.keysetlabel("F34","")
		CALL dialog.keysetlabel("F35","")
		CALL dialog.keysetlabel("F36","")
		CALL dialog.keysetlabel("F37","")
		CALL dialog.keysetlabel("F38","")
	ON KEY(F31,F32,F33,F34,F35,F36,F37,F38)
		LET i = FGL_LASTKEY() - key_f30
		IF i = 8 THEN
			CALL muestra_movimientos_mecanico('0', 'OTROS',
				    rm_meses[vm_ind_ini],
		                    r_obj[1].etiqueta, r_obj[2].etiqueta, 
				    r_obj[3].etiqueta, r_obj[4].etiqueta, 
				    r_obj[5].etiqueta, r_obj[6].etiqueta,
		     		    r_obj[7].etiqueta)
		ELSE
			CALL muestra_movimientos_mecanico(r_obj[i].mecanico, 
				    r_obj[i].etiqueta,
				    rm_meses[vm_ind_ini],
				    null, null, null, null, null, null, null)
		END IF
	AFTER FIELD tecla
		NEXT FIELD tecla
END INPUT
CLOSE WINDOW w_gr1

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



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
