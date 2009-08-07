------------------------------------------------------------------------------
-- Titulo           : vehp302.4gl - Consulta Estadísticas por Modelos
-- Elaboracion      : 21-Sep-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun vehp302.4gl base_datos modulo compañía
-- Ultima Correccion: 22-Sep-2001 
-- Motivo Correccion: Habilitación de Gráficos 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
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
	linea		LIKE veht003.v03_linea,
	tit_lin		VARCHAR(30),
	vendedor	LIKE veht001.v01_vendedor,
        tit_vend	LIKE veht001.v01_nombres,
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
	modelo		LIKE veht020.v20_modelo,
	valor_1		DECIMAL(14,2),
	valor_2		DECIMAL(14,2),
	valor_3		DECIMAL(14,2),
	tot_val		DECIMAL(14,2)
	END RECORD
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE vm_cant_val	CHAR(1)
DEFINE vm_num_meses	SMALLINT
DEFINE vm_num_mod	SMALLINT
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
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp302'
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
LET rm_par.tit_mon = rm_mon.g13_nombre
LET vm_campo_orden= 5
LET vm_tipo_orden = 'DESC'
LET rm_par.ano    = YEAR(TODAY)
LET vm_cant_val   = 'V'
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
OPEN FORM f_cons FROM '../forms/vehf302_1'
DISPLAY FORM f_cons
DISPLAY 'M o d e l o' TO tit_mod
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
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE lin_aux		LIKE veht003.v03_linea
DEFINE ven_aux		LIKE veht001.v01_vendedor
DEFINE num_dec		SMALLINT
DEFINE r_lin		RECORD LIKE veht003.*
DEFINE r_ven		RECORD LIKE veht001.*

DISPLAY 'Enero'    TO tit_mes1
DISPLAY 'Febrero'  TO tit_mes2
DISPLAY 'Marzo'    TO tit_mes3 
DISPLAY 'Subtotal' TO tit_subt
LET int_flag = 0
DISPLAY BY NAME rm_par.tit_mon
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.ano, rm_par.moneda, rm_par.vendedor,
				     rm_par.linea) THEN
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
		IF infield(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux,rm_par.tit_mon,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda = mon_aux
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF infield(linea) THEN
			CALL fl_ayuda_lineas_veh(vg_codcia) RETURNING lin_aux,rm_par.tit_lin
			IF lin_aux IS NOT NULL THEN
				LET rm_par.linea = lin_aux
				DISPLAY BY NAME rm_par.linea, rm_par.tit_lin
			END IF
		END IF
		IF infield(vendedor) THEN
			CALL fl_ayuda_vendedores_veh(vg_codcia) RETURNING ven_aux, rm_par.tit_vend
			IF ven_aux IS NOT NULL THEN
				LET rm_par.vendedor = ven_aux
				DISPLAY BY NAME rm_par.vendedor, rm_par.tit_vend
			END IF
		END IF
		LET int_flag = 0
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
	AFTER FIELD linea
		IF rm_par.linea IS NOT NULL THEN
			CALL fl_lee_linea_veh(vg_codcia, rm_par.linea) RETURNING r_lin.*
			IF r_lin.v03_linea IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Línea no existe', 'exclamation')
				NEXT FIELD linea
			END IF
			LET rm_par.tit_lin = r_lin.v03_nombre
			DISPLAY BY NAME rm_par.tit_lin
		ELSE
			LET rm_par.tit_lin = NULL
			CLEAR tit_lin
		END IF
	AFTER FIELD vendedor
		IF rm_par.vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_veh(vg_codcia, rm_par.vendedor) RETURNING r_ven.*
			IF r_ven.v01_vendedor IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Vendedor no existe', 'exclamation')
				NEXT FIELD vendedor
			END IF
			LET rm_par.tit_vend = r_ven.v01_nombres
			DISPLAY BY NAME rm_par.tit_vend
		ELSE
			LET rm_par.tit_vend = NULL
			CLEAR tit_vend
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
DEFINE modelo		LIKE veht020.v20_modelo
DEFINE mes, i		SMALLINT
DEFINE valor, val	DECIMAL(14,2)
DEFINE cant,  can 	SMALLINT
DEFINE r		RECORD LIKE veht001.*
DEFINE campo_v		VARCHAR(15)
DEFINE campo_c		VARCHAR(15)
DEFINE expr1, expr2	VARCHAR(80)
DEFINE query		VARCHAR(500)
DEFINE expr_ins		VARCHAR(300)
DEFINE mes_c		CHAR(10)

ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
CREATE TEMP TABLE temp_acum
       (te_modelo	VARCHAR(25),
	te_mes1v	DECIMAL(14,2),
	te_mes1c	SMALLINT,
	te_mes2v	DECIMAL(14,2),
	te_mes2c	SMALLINT,
	te_mes3v	DECIMAL(14,2),
	te_mes3c	SMALLINT,
	te_mes4v	DECIMAL(14,2),
	te_mes4c	SMALLINT,
	te_mes5v	DECIMAL(14,2),
	te_mes5c	SMALLINT,
	te_mes6v	DECIMAL(14,2),
	te_mes6c	SMALLINT,
	te_mes7v	DECIMAL(14,2),
	te_mes7c	SMALLINT,
	te_mes8v	DECIMAL(14,2),
	te_mes8c	SMALLINT,
	te_mes9v	DECIMAL(14,2),
	te_mes9c	SMALLINT,
	te_mes10v	DECIMAL(14,2),
	te_mes10c	SMALLINT,
	te_mes11v	DECIMAL(14,2),
	te_mes11c	SMALLINT,
	te_mes12v	DECIMAL(14,2),
	te_mes12c	SMALLINT)
LET expr1 = ' 1 = 1 '
LET expr2 = ' 1 = 1 '
IF rm_par.linea IS NOT NULL THEN
	LET expr1 = " v40_linea = '", rm_par.linea CLIPPED, "' "
END IF
IF rm_par.vendedor IS NOT NULL THEN
	LET expr2 = " v40_vendedor = ", rm_par.vendedor CLIPPED, " "
END IF
LET query = 'SELECT v40_modelo, v40_mes, SUM(v40_valor), SUM(v40_uni_venta) ',
		' FROM veht040 ',
		' WHERE v40_compania = ', vg_codcia, ' AND ',
		' v40_ano = ? AND v40_moneda = ? AND ',
		  expr1, ' AND ',
		  expr2, 
		' GROUP BY 1, 2 '
PREPARE men FROM query
DECLARE q_men CURSOR FOR men
OPEN q_men USING rm_par.ano, rm_par.moneda
LET vm_num_mod = 0
WHILE TRUE
	FETCH q_men INTO modelo, mes, valor, cant
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
	LET campo_v = 'te_mes', mes_c CLIPPED, 'v'
	LET campo_c = 'te_mes', mes_c CLIPPED, 'c'
	LET expr_ins = NULL
	FOR i = 1 TO 12
		IF mes = i THEN
			LET val = valor
			LET can = cant
		ELSE
			LET val = 0
			LET can = 0
		END IF
		LET expr_ins = expr_ins CLIPPED, ',', val, ',', can 
	END FOR
	SELECT * FROM temp_acum WHERE te_modelo = modelo
	IF status = NOTFOUND THEN
		IF vm_num_mod = vm_max_rows THEN
			CONTINUE WHILE
		END IF
		LET vm_num_mod = vm_num_mod + 1
		LET query = "INSERT INTO temp_acum VALUES('", modelo CLIPPED,
			      "' ", expr_ins CLIPPED, ')'
		PREPARE in_temp FROM query
		EXECUTE in_temp 
	ELSE
		LET query = 'UPDATE temp_acum SET ', 
				campo_v, '= ', campo_v, ' + ?, ',
				campo_c, '= ', campo_c, ' + ?',
				' WHERE te_modelo = ?'
		PREPARE up_temp FROM query
		EXECUTE up_temp USING valor, cant, modelo 
	END IF
END WHILE
LET int_flag = 0
IF vm_num_mod = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
	RETURN
END IF
SELECT SUM(te_mes1v+te_mes2v+te_mes3v+te_mes4v+te_mes5v+te_mes6v+
           te_mes7v+te_mes8v+te_mes9v+te_mes10v+te_mes11v+te_mes12v)
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
IF vm_cant_val = 'V' THEN
	UPDATE temp_acum1 SET te_mes1v = te_mes1v / vm_divisor,
                      te_mes2v = te_mes2v / vm_divisor,
                      te_mes3v = te_mes3v / vm_divisor,
                      te_mes4v = te_mes4v / vm_divisor,
                      te_mes5v = te_mes5v / vm_divisor,
                      te_mes6v = te_mes6v / vm_divisor,
                      te_mes7v = te_mes7v / vm_divisor,
                      te_mes8v = te_mes8v / vm_divisor,
                      te_mes9v = te_mes9v / vm_divisor,
                      te_mes10v= te_mes10v/ vm_divisor,
                      te_mes11v= te_mes11v/ vm_divisor,
                      te_mes12v= te_mes12v/ vm_divisor
END IF
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
	LET expr_meses = expr_meses CLIPPED, ', te_mes', mes_c CLIPPED, 
			 DOWNSHIFT(vm_cant_val)
END FOR
LET expr_suma  = ',0'
FOR i = 1 TO vm_num_meses
	LET mes_c = rm_meses[i]
	LET expr_suma  = expr_suma  CLIPPED, '+ te_mes', mes_c CLIPPED,
			 DOWNSHIFT(vm_cant_val)
END FOR
LET query = 'SELECT te_modelo ', 
		expr_meses CLIPPED,
		expr_ceros CLIPPED,
		expr_suma CLIPPED,
		' FROM temp_acum1 ',
		' ORDER BY ', vm_campo_orden, ' ', vm_tipo_orden
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET t_valor_1 = 0
LET t_valor_2 = 0
LET t_valor_3 = 0
LET t_tot_val = 0
LET i = 1
FOREACH q_cons INTO rm_cons[i].*
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
DEFINE mod_aux		LIKE veht020.v20_modelo
DEFINE resp		CHAR(3)

ERROR " " ATTRIBUTE(NORMAL) 
CALL set_count(vm_num_mod)
LET nuevo_display = 0
WHILE TRUE
	CALL muestra_nombre_meses()
	IF vm_cant_val = 'V' THEN
		DISPLAY '*** Valores ***' TO tit_cant_val
	ELSE
		DISPLAY '*** Cantidades ***' TO tit_cant_val
	END IF
	CALL muestra_precision()
	DISPLAY BY NAME t_valor_1, t_valor_2, t_valor_3, t_tot_val
	LET int_flag = 0
	CALL fgl_keysetlabel('F9','Gráfico')
	IF vm_cant_val = 'V' THEN
		CALL fgl_keysetlabel('F5','Cantidades')
		CALL fgl_keysetlabel('F8','Precisión')
	ELSE
		CALL fgl_keysetlabel('F5','Valores')
		CALL fgl_keysetlabel('F8','')
	END IF
	IF vm_pantallas > 1 THEN
		CALL fgl_keysetlabel('F7','Más Meses')
	ELSE
		CALL fgl_keysetlabel('F7','')
	END IF
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
			MESSAGE i, ' de ', vm_num_mod
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			IF vm_cant_val = 'V' THEN
				LET vm_cant_val = 'C'
			ELSE
				LET vm_cant_val = 'V'
			END IF
			LET nuevo_display = 1
			LET pos_pantalla = scr_line()
			LET pos_arreglo  = arr_curr()
			LET mod_aux      = rm_cons[pos_arreglo].modelo
			CALL carga_arreglo_consulta()
			FOR i = 1 TO vm_num_mod
				IF rm_cons[i].modelo = mod_aux THEN
					LET pos_arreglo = i
					EXIT FOR
				END IF
			END FOR
			EXIT DISPLAY
		ON KEY(F6)
			LET i = arr_curr()
			CALL muestra_movimientos_modelo(rm_cons[i].modelo, rm_meses[vm_ind_ini], rm_meses[vm_ind_ini], null, null, null, null, null, null, null)
		ON KEY(F7)
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
		ON KEY(F8)
			IF vm_cant_val = 'V' THEN
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
			END IF
		ON KEY(F9)
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
		LET mod_aux       = rm_cons[pos_arreglo].modelo
		CALL carga_arreglo_consulta()
		IF vm_num_mod > fgl_scr_size('rm_cons') THEN
			FOR i = 1 TO vm_num_mod
				IF rm_cons[i].modelo = mod_aux THEN
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



FUNCTION muestra_movimientos_modelo(modelo, mes_ini, mes_fin, out1, out2, out3,
			 out4, out5, out6, out7)
DEFINE modelo		LIKE veht020.v20_modelo
DEFINE mes_ini, mes_fin	SMALLINT
DEFINE out1, out2, out3	LIKE veht020.v20_modelo
DEFINE out4, out5, out6	LIKE veht020.v20_modelo
DEFINE out7		LIKE veht020.v20_modelo
DEFINE fec_ini, fec_fin	DATE
DEFINE r_cab		RECORD LIKE veht030.*
DEFINE r_det		RECORD LIKE veht031.*
DEFINE r_veh		RECORD LIKE veht022.*
DEFINE num_rows, i	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE valor, tot_val	DECIMAL(14,2)
DEFINE comando		VARCHAR(140)
DEFINE descri_cli	CHAR(28)
DEFINE linea		LIKE veht003.v03_linea
DEFINE columna_act	SMALLINT
DEFINE columna_ant	SMALLINT
DEFINE orden_act	CHAR(4)
DEFINE orden_ant	CHAR(4)
DEFINE orden		VARCHAR(100)
DEFINE query		VARCHAR(300)
DEFINE r_mov ARRAY[1000] OF RECORD
	fecha		DATE,
	bodega		LIKE veht002.v02_bodega,
	tipo		LIKE veht030.v30_cod_tran,
	numero		LIKE veht030.v30_num_tran,
	nomcli		LIKE veht030.v30_nomcli,
	valor		DECIMAL(14,2)
	END RECORD

CREATE TEMP TABLE temp_mov
	(te_fecha	DATETIME YEAR TO SECOND,
	 te_bodega	CHAR(2),
	 te_tipo	CHAR(2),
	 te_numero	INTEGER,
	 te_nomcli	CHAR(40),
	 te_valor	DECIMAL(14,2))
LET max_rows = 1000
OPEN WINDOW w_mov AT 2,5 WITH FORM "../forms/vehf302_2"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
DISPLAY 'Fecha' TO tit_col1
DISPLAY 'Bd'    TO tit_col2
DISPLAY 'Tp'    TO tit_col3
DISPLAY '# Documento' TO tit_col4
DISPLAY 'Cliente' TO tit_col5
DISPLAY 'V a l o r' TO tit_col6
LET fec_ini = MDY(mes_ini, 01, rm_par.ano)
LET fec_fin = MDY(mes_fin, 01, rm_par.ano) + 1 UNITS MONTH - 1 UNITS DAY
DISPLAY BY NAME fec_ini, fec_fin, rm_par.moneda,
	rm_par.tit_mon, rm_par.linea,
	rm_par.tit_lin, rm_par.vendedor, rm_par.tit_vend
IF modelo <> '0' THEN
	DISPLAY BY NAME modelo
ELSE
	DISPLAY 'OTROS' TO modelo
END IF
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
DECLARE q_cab CURSOR FOR 
	SELECT * FROM veht030
		WHERE v30_compania = vg_codcia AND v30_localidad = vg_codloc AND
	              v30_fecing BETWEEN EXTEND(fec_ini, YEAR TO SECOND) AND
	              EXTEND(fec_fin, YEAR TO SECOND) + 23 UNITS HOUR + 
		      59 UNITS MINUTE
		ORDER BY v30_fecing
LET num_rows = 0
LET tot_val = 0
FOREACH q_cab INTO r_cab.*
	IF r_cab.v30_cod_tran <> 'FA' AND r_cab.v30_cod_tran <> 'DF' THEN
		CONTINUE FOREACH
	END IF
	IF rm_par.vendedor IS NOT NULL AND 
		r_cab.v30_vendedor <> rm_par.vendedor THEN
		CONTINUE FOREACH
	END IF
	IF rm_par.moneda <> r_cab.v30_moneda THEN
		CONTINUE FOREACH
	END IF
	IF num_rows >= max_rows THEN
		EXIT FOREACH
	END IF
	DECLARE q_det CURSOR FOR 
		SELECT * FROM veht031
			WHERE v31_compania  = vg_codcia AND 
			      v31_localidad = vg_codloc AND
		              v31_cod_tran  = r_cab.v30_cod_tran AND
		              v31_num_tran  = r_cab.v30_num_tran
	FOREACH q_det INTO r_det.*
		CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, r_det.v31_codigo_veh)
			RETURNING r_veh.*
		IF r_veh.v22_codigo_veh IS NULL THEN
			CONTINUE FOREACH
		END IF
		IF modelo = '0' THEN
			IF r_veh.v22_modelo = out1 OR
			   r_veh.v22_modelo = out2 OR
			   r_veh.v22_modelo = out3 OR
			   r_veh.v22_modelo = out4 OR
			   r_veh.v22_modelo = out5 OR
			   r_veh.v22_modelo = out6 OR
			   r_veh.v22_modelo = out7 THEN
				CONTINUE FOREACH
			END IF
		ELSE	
			IF modelo <> r_veh.v22_modelo THEN
				CONTINUE FOREACH
			END IF
		END IF
		LET linea = 'X'
		SELECT v20_linea INTO linea FROM veht020
			WHERE v20_compania = vg_codcia AND 
			      v20_modelo = modelo
		IF rm_par.linea IS NOT NULL AND linea <> rm_par.linea THEN
			CONTINUE FOREACH
		END IF
		LET valor = r_det.v31_precio - r_det.v31_val_descto
		IF r_cab.v30_cod_tran = 'DF' THEN
			LET valor = valor * -1
		END IF
		INSERT INTO temp_mov VALUES (r_cab.v30_fecing, 	
			r_cab.v30_bodega_ori, r_det.v31_cod_tran,
			r_det.v31_num_tran,   r_cab.v30_nomcli, valor)
		LET tot_val = tot_val + valor
		LET num_rows = num_rows + 1
		IF num_rows = max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
END FOREACH
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
ERROR ' '
DISPLAY BY NAME tot_val
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
	LET int_flag = 0
	DISPLAY ARRAY r_mov TO r_mov.*
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
			LET comando = 'fglrun vehp304 ', vg_base, ' ',
				       vg_modulo, ' ', vg_codcia, ' ', 
				       vg_codloc, ' ',
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
DEFINE i		SMALLINT

LET i = vm_ind_ini 
LET tit_mes1 = fl_retorna_nombre_mes(rm_meses[i])
LET tit_mes2 = ''
LET tit_mes3 = ''
LET i = i + 1
IF i <= vm_num_meses THEN
	LET tit_mes2 = fl_retorna_nombre_mes(rm_meses[i])
	LET i = i + 1
	IF i <= vm_num_meses THEN
		LET tit_mes3 = fl_retorna_nombre_mes(rm_meses[i])
	END IF
END IF
DISPLAY BY NAME tit_mes1, tit_mes2, tit_mes3	
DISPLAY 'Subtotal' TO tit_subt

END FUNCTION



FUNCTION muestra_precision()
	
IF vm_cant_val = 'V' THEN
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
ELSE
	CLEAR tit_precision
END IF

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
DEFINE modelo		LIKE veht020.v20_modelo
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
	etiqueta	LIKE veht020.v20_modelo,
	valor		DECIMAL(14,2),
	id_obj_arc	SMALLINT,
	id_obj_rec	SMALLINT
	END RECORD

LET mes_c = rm_par.ano
IF vm_cant_val = 'V' THEN
	LET titulo = 'VALORES VENDIDOS POR MODELO DURANTE LOS MESES SELECCIONADOS DEL ANO: ' || mes_c
ELSE
	LET titulo = 'UNIDADES VENDIDAS POR MODELO DURANTE LOS MESES SELECCIONADOS DEL ANO: ' || mes_c
END IF
--
-- Solo 8 elementos se mostraran. Desde el 8vo. hasta el final se acumularán
-- como uno solo, bajo el título 'OTROS'.
--
LET limite = 8		
				
LET max_elementos = vm_num_mod 
IF vm_num_mod > limite THEN
	LET max_elementos = limite
END IF 
LET expr_suma  = '0'
FOR i = 1 TO 12
	LET mes_c = i
	LET expr_suma  = expr_suma  CLIPPED, '+ te_mes', mes_c CLIPPED,
			 DOWNSHIFT(vm_cant_val)
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
LET query = 'SELECT te_modelo, ', expr_suma CLIPPED,
		' FROM temp_acum ',
		' ORDER BY 2 DESC'
PREPARE gr1 FROM query
DECLARE q_gr1 CURSOR FOR gr1
CALL drawinit()
OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/vehf302_4"
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
CALL drawselect('c001')
CALL drawanchor('w')
LET i = drawtext(960,10,titulo CLIPPED)
LET titulo = 'Total: ', tot_valor USING "#,###,###,##&.##"
CALL drawfillcolor('blue')
LET i = drawtext(910,10, titulo)
LET i = drawtext(030,10,'Haga click sobre un modelo para ver detalles')
LET factor = 360 / tot_valor  -- Factor para obtener los grados de c/elemento.
LET indice = 1
LET grados_ini = 0 
LET residuo = tot_valor
LET pos_ini = 810
FOR i = 1 TO limite
	LET r_obj[i].etiqueta = NULL
END FOR
FOREACH q_gr1 INTO modelo, valor
	LET r_obj[indice].valor = valor
	IF indice = max_elementos THEN
		LET grados_fin = 360 - grados_ini
		IF indice = limite THEN
			LET r_obj[indice].etiqueta = 'OTROS'
			LET r_obj[indice].valor    = residuo
		ELSE
			LET r_obj[indice].etiqueta = modelo
		END IF
	ELSE
		LET grados_fin = valor * factor
		LET r_obj[indice].etiqueta = modelo
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
			CALL muestra_movimientos_modelo('0',
				    rm_meses[1], rm_meses[vm_num_meses],
		                    r_obj[1].etiqueta, r_obj[2].etiqueta, 
				    r_obj[3].etiqueta, r_obj[4].etiqueta, 
				    r_obj[5].etiqueta, r_obj[6].etiqueta,
		     		    r_obj[7].etiqueta)
		ELSE
			CALL muestra_movimientos_modelo(r_obj[i].etiqueta,
				    rm_meses[1], rm_meses[vm_num_meses],
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
DEFINE modelo		LIKE veht020.v20_modelo
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
	etiqueta	LIKE veht020.v20_modelo,
	valor		DECIMAL(14,2),
	id_obj_rec1	SMALLINT,
	id_obj_rec2	SMALLINT
	END RECORD

LET mes_c = rm_par.ano
IF vm_cant_val = 'V' THEN
	LET titulo = 'VALORES VENDIDOS POR MODELO DURANTE LOS MESES SELECCIONADOS DEL ANO: ' || mes_c
ELSE
	LET titulo = 'UNIDADES VENDIDAS POR MODELO DURANTE LOS MESES SELECCIONADOS DEL ANO: ' || mes_c
END IF
LET limite = 8
LET expr_suma  = '0'
FOR i = 1 TO 12
	LET mes_c = i
	LET expr_suma  = expr_suma  CLIPPED, '+ te_mes', mes_c CLIPPED,
			 DOWNSHIFT(vm_cant_val)
END FOR
LET query = 'SELECT te_modelo, ', expr_suma CLIPPED,
		' FROM temp_acum ',
		' ORDER BY 2 DESC'
PREPARE gr2 FROM query
DECLARE q_gr2 CURSOR FOR gr2
CREATE TEMP TABLE temp_bar
	(te_modelo	VARCHAR(20),
	 te_valor	DECIMAL(14,2),
         te_indice	SMALLINT)
LET i = 1
LET val_x = 0
LET tot_valor = 0
FOREACH q_gr2 INTO modelo, valor
	LET tot_valor = tot_valor + valor
	IF i <= limite - 1 THEN
		INSERT INTO temp_bar VALUES (modelo, valor, i)
		LET i = i + 1
	ELSE
		LET val_x = val_x + valor
	END IF	
END FOREACH
IF i = 1 THEN
	RETURN
END IF
IF val_x > 0 THEN
	INSERT INTO temp_bar VALUES ('OTROS', val_x, i)
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
OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/vehf302_4"
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
LET i = drawtext(030,10,'Haga click sobre un modelo para ver detalles')

LET max_elementos = vm_num_mod
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
	ORDER BY 3
FOREACH q_bar INTO modelo, valor
        CALL DrawFillColor(rm_color[indice+1])
	LET r_obj[indice + 1].valor = valor
	LET r_obj[indice + 1].etiqueta = modelo
        LET r_obj[indice + 1].id_obj_rec1 = DrawRectangle (start_y,
                         start_bar + bar_width * segments * indice,
                         scale * valor, bar_width)
        LET r_obj[indice + 1].id_obj_rec2 = DrawRectangle (key_y, startkey_x, key_width,  key_length)
        LET i = DrawText(key_y + 40, start_key_text, modelo)
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
			CALL muestra_movimientos_modelo('0',
				    rm_meses[1], rm_meses[vm_num_meses],
		                    r_obj[1].etiqueta, r_obj[2].etiqueta, 
				    r_obj[3].etiqueta, r_obj[4].etiqueta, 
				    r_obj[5].etiqueta, r_obj[6].etiqueta,
		     		    r_obj[7].etiqueta)
		ELSE
			CALL muestra_movimientos_modelo(r_obj[i].etiqueta,
				    rm_meses[1], rm_meses[vm_num_meses],
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
