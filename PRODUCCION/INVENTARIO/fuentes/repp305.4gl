------------------------------------------------------------------------------
-- Titulo           : repp305.4gl - Consulta Estadísticas por Bodegas
-- Elaboracion      : 17-Nov-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp305.4gl base_datos modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion:
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_campo_orden	SMALLINT
DEFINE vm_tipo_orden	CHAR(4)
DEFINE rm_par RECORD
	ano		SMALLINT,
	moneda		LIKE gent013.g13_moneda,
	tit_mon		VARCHAR(30),
	linea		LIKE rept003.r03_codigo,
	tit_lin		VARCHAR(30),
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
	name_bod	LIKE rept002.r02_nombre,
	valor_1		DECIMAL(14,2),
	valor_2		DECIMAL(14,2),
	valor_3		DECIMAL(14,2),
	tot_val		DECIMAL(14,2)
	END RECORD
DEFINE rm_bod ARRAY[200] OF CHAR(2)
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE vm_cant_val	CHAR(1)
DEFINE vm_num_meses	SMALLINT
DEFINE vm_num_bod	SMALLINT
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
CALL startlog('../logs/repp305.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'repp305'
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
OPEN WINDOW w_repf305_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_cons FROM '../forms/repf305_1'
DISPLAY FORM f_cons
DISPLAY 'B o d e g a' TO tit_bod
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
CLOSE WINDOW w_repf305_1
EXIT PROGRAM

END FUNCTION



FUNCTION lee_parametros()
DEFINE resp		CHAR(3)
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE lin_aux		LIKE rept003.r03_codigo
DEFINE num_dec		SMALLINT
DEFINE r_lin		RECORD LIKE rept003.*

DISPLAY 'Enero'    TO tit_mes1
DISPLAY 'Febrero'  TO tit_mes2
DISPLAY 'Marzo'    TO tit_mes3 
DISPLAY 'Subtotal' TO tit_subt
LET int_flag = 0
DISPLAY BY NAME rm_par.tit_mon
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.ano, rm_par.moneda,
				     rm_par.linea) THEN
			RETURN
		END IF
		LET INT_FLAG = 0
		--CALL FGL_WINQUESTION(vg_producto,'Desea salir de la consulta','No','Yes|No|Cancel','question',1)
		CALL fl_hacer_pregunta('Desea salir de la consulta','No')
			RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
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
		IF INFIELD(linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia) RETURNING lin_aux,rm_par.tit_lin
			IF lin_aux IS NOT NULL THEN
				LET rm_par.linea = lin_aux
				DISPLAY BY NAME rm_par.linea, rm_par.tit_lin
			END IF
		END IF
	AFTER FIELD ano
		IF rm_par.ano > YEAR(TODAY) THEN
			--CALL fgl_winmessage(vg_producto,'Año incorrecto.','exclamation')
			CALL fl_mostrar_mensaje('Año incorrecto.','exclamation')
			NEXT FIELD ano
		END IF
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
			IF rm_mon.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
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
			CALL fl_lee_linea_rep(vg_codcia, rm_par.linea) RETURNING r_lin.*
			IF r_lin.r03_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Línea no existe', 'exclamation')
				CALL fl_mostrar_mensaje('Línea no existe.','exclamation')
				NEXT FIELD linea
			END IF
			LET rm_par.tit_lin = r_lin.r03_nombre
			DISPLAY BY NAME rm_par.tit_lin
		ELSE
			LET rm_par.tit_lin = NULL
			CLEAR tit_lin
		END IF
	AFTER INPUT 
		IF rm_par.mes1  = 'N' AND rm_par.mes2  = 'N' AND
		   rm_par.mes3  = 'N' AND rm_par.mes4  = 'N' AND
		   rm_par.mes5  = 'N' AND rm_par.mes6  = 'N' AND
		   rm_par.mes7  = 'N' AND rm_par.mes8  = 'N' AND
		   rm_par.mes9  = 'N' AND rm_par.mes10 = 'N' AND
		   rm_par.mes11 = 'N' AND rm_par.mes12 = 'N' THEN
			--CALL fgl_winmessage(vg_producto,'Seleccion un mes por lo menos.','exclamation')
			CALL fl_mostrar_mensaje('Seleccion un mes por lo menos.','exclamation')
			NEXT FIELD mes1
		END IF
END INPUT

END FUNCTION



FUNCTION genera_tabla_temporal()
DEFINE cod_bod		LIKE rept002.r02_codigo
DEFINE mes, i		SMALLINT
DEFINE valor, val	DECIMAL(14,2)
DEFINE r		RECORD LIKE rept002.*
DEFINE campo_v		VARCHAR(15)
DEFINE campo_c		VARCHAR(15)
DEFINE expr1, expr2	VARCHAR(80)
DEFINE query		VARCHAR(500)
DEFINE expr_ins		VARCHAR(300)
DEFINE mes_c		CHAR(10)

ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
CREATE TEMP TABLE temp_acum
       (te_bodega	CHAR(2),
	te_nombre	VARCHAR(40),
	te_mes1 	DECIMAL(14,2),
	te_mes2 	DECIMAL(14,2),
	te_mes3 	DECIMAL(14,2),
	te_mes4 	DECIMAL(14,2),
	te_mes5 	DECIMAL(14,2),
	te_mes6 	DECIMAL(14,2),
	te_mes7 	DECIMAL(14,2),
	te_mes8 	DECIMAL(14,2),
	te_mes9 	DECIMAL(14,2),
	te_mes10 	DECIMAL(14,2),
	te_mes11 	DECIMAL(14,2),
	te_mes12 	DECIMAL(14,2))
LET expr1 = ' 1 = 1 '
IF rm_par.linea IS NOT NULL THEN
	LET expr1 = " r60_linea = '", rm_par.linea CLIPPED, "' "
END IF
LET query = 'SELECT r60_bodega, MONTH(r60_fecha), SUM(r60_precio) ',
		' FROM rept060 ',
		' WHERE r60_compania = ', vg_codcia, ' AND ',
		'  YEAR(r60_fecha) = ? AND r60_moneda = ? AND ',
		  expr1 CLIPPED,
		' GROUP BY 1, 2 '
PREPARE men FROM query
DECLARE q_men CURSOR FOR men
OPEN q_men USING rm_par.ano, rm_par.moneda
LET vm_num_bod = 0
WHILE TRUE
	FETCH q_men INTO cod_bod, mes, valor
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
	LET campo_v = 'te_mes', mes_c
	LET expr_ins = NULL
	FOR i = 1 TO 12
		IF mes = i THEN
			LET val = valor
		ELSE
			LET val = 0
		END IF
		LET expr_ins = expr_ins CLIPPED, ',', val
	END FOR
	SELECT * FROM temp_acum WHERE te_bodega = cod_bod
	IF status = NOTFOUND THEN
		IF vm_num_bod = vm_max_rows THEN
			CONTINUE WHILE
		END IF
		LET vm_num_bod = vm_num_bod + 1
		CALL fl_lee_bodega_rep(vg_codcia, cod_bod)
			RETURNING r.*
		LET query = "INSERT INTO temp_acum VALUES('", cod_bod, "', '",
			     r.r02_nombre CLIPPED, "'", expr_ins CLIPPED, ')'
		PREPARE in_temp FROM query
		EXECUTE in_temp 
	ELSE
		LET query = 'UPDATE temp_acum SET ', 
				campo_v, '= ', campo_v, ' + ? ',
				' WHERE te_bodega = ?'
		PREPARE up_temp FROM query
		EXECUTE up_temp USING valor, cod_bod 
	END IF
END WHILE
LET int_flag = 0
IF vm_num_bod = 0 THEN
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
IF vm_cant_val = 'V' THEN
	UPDATE temp_acum1 SET te_mes1 = te_mes1 / vm_divisor,
                      te_mes2  = te_mes2  / vm_divisor,
                      te_mes3  = te_mes3  / vm_divisor,
                      te_mes4  = te_mes4  / vm_divisor,
                      te_mes5  = te_mes5  / vm_divisor,
                      te_mes6  = te_mes6  / vm_divisor,
                      te_mes7  = te_mes7  / vm_divisor,
                      te_mes8  = te_mes8  / vm_divisor,
                      te_mes9  = te_mes9  / vm_divisor,
                      te_mes10 = te_mes10 / vm_divisor,
                      te_mes11 = te_mes11 / vm_divisor,
                      te_mes12 = te_mes12 / vm_divisor
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
	LET expr_meses = expr_meses CLIPPED, ', te_mes', mes_c CLIPPED
END FOR
LET expr_suma  = ',0'
FOR i = 1 TO vm_num_meses
	LET mes_c = rm_meses[i]
	LET expr_suma  = expr_suma  CLIPPED, '+ te_mes', mes_c CLIPPED
END FOR
LET query = 'SELECT te_nombre ', 
		expr_meses CLIPPED,
		expr_ceros CLIPPED,
		expr_suma CLIPPED,
		', te_bodega ',
		' FROM temp_acum1 ',
		' ORDER BY ', vm_campo_orden, ' ', vm_tipo_orden
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET t_valor_1 = 0
LET t_valor_2 = 0
LET t_valor_3 = 0
LET t_tot_val = 0
LET i = 1
FOREACH q_cons INTO rm_cons[i].*, rm_bod[i]
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
DEFINE bod_aux		LIKE rept002.r02_nombre
DEFINE resp		CHAR(3)

ERROR " " ATTRIBUTE(NORMAL) 
CALL set_count(vm_num_bod)
LET nuevo_DISPLAY = 0
WHILE TRUE
	CALL muestra_nombre_meses()
	CALL muestra_precision()
	DISPLAY BY NAME t_valor_1, t_valor_2, t_valor_3, t_tot_val
	LET int_flag = 0
	IF vm_pantallas > 1 THEN
		--#CALL fgl_keysetlabel('F6','Más Meses')
	ELSE
		--#CALL fgl_keysetlabel('F6','')
	END IF
	DISPLAY ARRAY rm_cons TO rm_cons.*
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("RETURN","")
			--#CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			IF nuevo_DISPLAY THEN
				CALL dialog.setcurrline(pos_pantalla,pos_arreglo)
				LET nuevo_DISPLAY = 0
			END IF
			LET i = arr_curr()
			MESSAGE i, ' de ', vm_num_bod
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL muestra_movimientos_bodega(rm_bod[i], rm_meses[vm_ind_ini], rm_meses[vm_ind_ini])
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
				LET nuevo_DISPLAY = 1
				LET pos_pantalla = scr_line()
				LET pos_arreglo  = arr_curr()
				CALL carga_arreglo_consulta()
				EXIT DISPLAY
			END IF
		ON KEY(F8)
			CALL muestra_grafico_lineas()
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
		LET nuevo_DISPLAY = 1
		LET pos_pantalla  = scr_line()
		LET pos_arreglo   = arr_curr()
		LET bod_aux      = rm_cons[pos_arreglo].name_bod
		CALL carga_arreglo_consulta()
		IF vm_num_bod > fgl_scr_size('rm_cons') THEN
			FOR i = 1 TO vm_num_bod
				IF rm_cons[i].name_bod = bod_aux THEN
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



FUNCTION muestra_movimientos_bodega(cod_bod, mes_ini, mes_fin)
DEFINE cod_bod		LIKE rept002.r02_codigo
DEFINE mes_ini, mes_fin	SMALLINT
DEFINE fec_ini, fec_fin	DATE
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE r_cab		RECORD LIKE rept019.*
DEFINE r_det		RECORD LIKE rept020.*
DEFINE num_rows, i	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE tot_uni		DECIMAL(8,2)
DEFINE tot_val, valor	DECIMAL(14,2)
DEFINE comando		VARCHAR(140)
DEFINE descri_cli	CHAR(28)
DEFINE descri_item	CHAR(28)
DEFINE columna_act	SMALLINT
DEFINE columna_ant	SMALLINT
DEFINE orden_act	CHAR(4)
DEFINE orden_ant	CHAR(4)
DEFINE orden		VARCHAR(100)
DEFINE query		VARCHAR(300)
DEFINE expr_bod		VARCHAR(120)
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
	 te_unidades	DECIMAL (8,2),
	 te_valor	DECIMAL(14,2))
LET max_rows = 4000
OPEN WINDOW w_mov AT 4,5 WITH FORM "../forms/repf305_2"
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
	rm_par.tit_mon, rm_par.linea, rm_par.tit_lin
DISPLAY cod_bod TO bodega
CALL fl_lee_bodega_rep(vg_codcia, cod_bod) RETURNING r_bod.*
DISPLAY r_bod.r02_nombre TO tit_bod
LET expr_bod = ' 1 = 1 '
IF cod_bod IS NOT NULL THEN
	LET expr_bod = ' r19_bodega_ori = "', cod_bod CLIPPED, '"'
END IF
LET int_flag = 0
INPUT BY NAME fec_ini, fec_fin WITHOUT DEFAULTS
	AFTER INPUT
		IF fec_ini > fec_fin THEN
			--CALL fgl_winmessage(vg_producto,'Rango de fechas incorrecto', 'exclamation')
			CALL fl_mostrar_mensaje('Rango de fechas incorrecto.','exclamation')
			NEXT FIELD fec_ini
		END IF
END INPUT			
IF int_flag THEN
	LET int_flag = 0
	DROP TABLE temp_mov
	CLOSE WINDOW w_mov
	RETURN
END IF
ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT * FROM rept019 ',
		' WHERE r19_compania = ? AND ',
		--expr_bod, ' AND ',
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
	IF r_cab.r19_cod_tran <> 'FA' AND r_cab.r19_cod_tran <> 'DF' AND
	   r_cab.r19_cod_tran <> 'AF' THEN
		CONTINUE WHILE
	END IF
	IF rm_par.moneda <> r_cab.r19_moneda THEN
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
		IF cod_bod IS NOT NULL AND 
			r_det.r20_bodega <> cod_bod THEN
			CONTINUE FOREACH
		END IF
		LET valor = (r_det.r20_precio * r_det.r20_cant_ven) - 
			     r_det.r20_val_descto
		IF r_cab.r19_cod_tran = 'DF' OR r_cab.r19_cod_tran = 'AF' THEN
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
	DROP TABLE temp_mov
	CLOSE WINDOW w_mov
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
		IF i > max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH 
	LET i = i - 1
	CALL set_count(num_rows)
	DISPLAY ARRAY r_mov TO r_mov.*
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("RETURN","")
			--#CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
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
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			LET comando = 'fglrun repp308 ' || vg_base || ' RE ' || 
			       	vg_codcia || ' ' ||
			       	vg_codloc || ' ' || r_mov[i].tipo || ' ' ||
			       	r_mov[i].numero
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



FUNCTION muestra_grafico_lineas()
DEFINE inicio_x		SMALLINT
DEFINE inicio_y		SMALLINT
DEFINE maximo_x		SMALLINT
DEFINE maximo_y		SMALLINT
DEFINE factor_y		DECIMAL(16,6)
DEFINE elementos_y	SMALLINT
DEFINE elementos_x	SMALLINT
DEFINE intervalo_x	SMALLINT
DEFINE intervalo_y	SMALLINT

DEFINE pos_fin_x	SMALLINT
DEFINE pos_fin_y	SMALLINT
DEFINE pos_ant_x	SMALLINT
DEFINE pos_ant_y	SMALLINT
DEFINE marca_x		SMALLINT
DEFINE marca_y		SMALLINT
DEFINE pos_ini		SMALLINT

DEFINE inicio2_x	SMALLINT
DEFINE inicio2_y	SMALLINT

DEFINE max_valor	DECIMAL(14,2)
DEFINE valor_c 		CHAR(10)

DEFINE mes, i, indice	SMALLINT
DEFINE divisor       	SMALLINT
DEFINE valor_rango     	DECIMAL(11,0)
DEFINE valor_aux     	DECIMAL(11,0)
DEFINE valor		DECIMAL(14,2)
DEFINE key_n		SMALLINT
DEFINE key_c		CHAR(3)
DEFINE key_f30		SMALLINT
DEFINE tecla		CHAR(1)
DEFINE titulo, tit_pos	CHAR(75)
DEFINE tit_val		CHAR(16)
DEFINE siglas_mes	CHAR(3)
DEFINE nombre_mes	CHAR(11)
DEFINE r_obj ARRAY[12] OF RECORD
	id_obj_rec1	SMALLINT,
	id_obj_rec2	SMALLINT
	END RECORD

CALL carga_colores()
LET inicio_x    = 120
LET inicio_y    = 100
LET maximo_x    = 600
LET maximo_y    = 750
LET elementos_y = 10
LET elementos_x = 12
LET intervalo_x = maximo_x / elementos_x
LET intervalo_y = maximo_y / elementos_y

SELECT 1 te_mes, SUM(te_mes1) te_valor FROM temp_acum
UNION ALL
SELECT 2 te_mes, SUM(te_mes2) te_valor FROM temp_acum
UNION ALL
SELECT 3 te_mes, SUM(te_mes3) te_valor FROM temp_acum
UNION ALL
SELECT 4 te_mes, SUM(te_mes4) te_valor FROM temp_acum
UNION ALL
SELECT 5 te_mes, SUM(te_mes5) te_valor FROM temp_acum
UNION ALL
SELECT 6 te_mes, SUM(te_mes6) te_valor FROM temp_acum
UNION ALL
SELECT 7 te_mes, SUM(te_mes7) te_valor FROM temp_acum
UNION ALL
SELECT 8 te_mes, SUM(te_mes8) te_valor FROM temp_acum
UNION ALL
SELECT 9 te_mes, SUM(te_mes9) te_valor FROM temp_acum
UNION ALL
SELECT 10 te_mes, SUM(te_mes10) te_valor FROM temp_acum
UNION ALL
SELECT 11 te_mes, SUM(te_mes11) te_valor FROM temp_acum
UNION ALL
SELECT 12 te_mes, SUM(te_mes12) te_valor FROM temp_acum
INTO TEMP temp_lin
SELECT MAX(te_valor) INTO max_valor FROM temp_lin
LET titulo = 'FACTURACION INVENTARIO ANO: ', rm_par.ano USING '####'
DECLARE q_lin CURSOR FOR SELECT te_mes, te_valor FROM temp_lin
	ORDER BY 1
CALL drawinit()
OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/repf304_3"
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
CALL drawselect('c001')
CALL drawanchor('w')
CALL drawlinewidth(2)
CALL DrawFillColor("black")
LET i = drawline(inicio_y, inicio_x, 0, maximo_x)
LET i = drawline(inicio_y, inicio_x, maximo_y, 0)
--
LET i = drawtext(960,10,titulo CLIPPED)
LET divisor = 1
IF max_valor > 999999 THEN
	LET divisor = 1000
	LET i = drawtext(920,10,'Valores expresados en miles')
END IF
LET valor_rango = max_valor / divisor / elementos_y
LET factor_y  = maximo_y / max_valor 
LET pos_ant_y = inicio_y
LET pos_ant_x = inicio_x
LET marca_x   = inicio_x + intervalo_x
LET marca_y   = inicio_y + intervalo_y
LET pos_ini   = 900
LET indice    = 0
LET valor_aux = valor_rango 
FOREACH q_lin INTO mes, valor
	LET indice = indice + 1
	CALL DrawFillColor("black")
	CALL drawlinewidth(1)
	CASE mes
		WHEN 1
			LET siglas_mes = 'Ene'
		WHEN 2
			LET siglas_mes = 'Feb'
		WHEN 3
			LET siglas_mes = 'Mar'
		WHEN 4
			LET siglas_mes = 'Abr'
		WHEN 5
			LET siglas_mes = 'May'
		WHEN 6
			LET siglas_mes = 'Jun'
		WHEN 7
			LET siglas_mes = 'Jul'
		WHEN 8
			LET siglas_mes = 'Ago'
		WHEN 9
			LET siglas_mes = 'Sep'
		WHEN 10
			LET siglas_mes = 'Oct'
		WHEN 11
			LET siglas_mes = 'Nov'
		WHEN 12
			LET siglas_mes = 'Dic'
	END CASE
	IF indice <= elementos_x THEN
		LET i = drawline(inicio_y - 10, marca_x, 20, 0)
		LET i = drawline(inicio_y, marca_x, maximo_y, 0)
		LET i = drawtext(inicio_y - 20, marca_x - 20, siglas_mes)
	END IF
	IF indice <= elementos_y THEN
		IF indice = elementos_y AND divisor = 1 THEN
			LET valor_aux = max_valor
		END IF
		LET valor_c = valor_aux USING "##,###,##&"
		LET i = drawline(marca_y, inicio_x - 10, 0, 20)
		LET i = drawline(marca_y, inicio_x, 0, maximo_x)
		LET i = drawtext(marca_y, inicio_x - 150, valor_c)
	END IF
	LET valor_aux = valor_aux + valor_rango
	LET marca_x = marca_x + intervalo_x
	LET marca_y = marca_y + intervalo_y
	CALL drawlinewidth(2)
	--CALL DrawFillColor(rm_color[mes])
	LET pos_fin_x = pos_ant_x + intervalo_x
	LET pos_fin_y = (factor_y  * valor) + inicio_y
	CALL DrawFillColor("cyan")
	LET r_obj[mes].id_obj_rec1 =
		drawline(pos_ant_y, pos_ant_x, pos_fin_y - pos_ant_y, 
			 pos_fin_x - pos_ant_x)
	LET nombre_mes = fl_retorna_nombre_mes(mes)
	LET r_obj[indice].id_obj_rec2 = drawrectangle(pos_ini,900,25,75)
	LET i = drawtext(pos_ini + 40, 830, nombre_mes)
	LET pos_ini = pos_ini - 80
	LET pos_ant_x = pos_fin_x
	LET pos_ant_y = pos_fin_y
END FOREACH
LET i = drawtext(30,10,'Haga click sobre un mes para ver detalles')
FOR i = 1 TO 12
	LET key_n = i + 30
	LET key_c = 'F', key_n
	CALL drawbuttonleft(r_obj[i].id_obj_rec2, key_c)
END FOR
LET key_f30 = FGL_KEYVAL("F30")
LET int_flag = 0
INPUT BY NAME tecla
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
		--#CALL dialog.keysetlabel("F39","")
		--#CALL dialog.keysetlabel("F40","")
		--#CALL dialog.keysetlabel("F41","")
		--#CALL dialog.keysetlabel("F42","")
	ON KEY(F31,F32,F33,F34,F35,F36,F37,F38,F39,F40,F41,F42)
		LET i = FGL_LASTKEY() - key_f30
		CALL muestra_movimientos_bodega('', i, i)
	AFTER FIELD tecla
		NEXT FIELD tecla	
END INPUT
DROP TABLE temp_lin
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



FUNCTION no_validar_parametros()

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
