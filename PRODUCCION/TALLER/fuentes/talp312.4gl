------------------------------------------------------------------------------
-- Titulo           : talp312.4gl - Analisis Productividad Taller
-- Elaboracion      : 29-dic-2003
-- Autor            : RCA
-- Formato Ejecucion: fglrun talp312 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_saldo_pyg	DECIMAL(16,2)
DEFINE rm_par   RECORD 
		ano		SMALLINT,
		mes		SMALLINT,
		tit_mes		VARCHAR(10),
		moneda		LIKE gent013.g13_moneda,
		tit_mon		LIKE gent013.g13_nombre,
		t01_linea	LIKE talt001.t01_linea,
		tit_linea	LIKE talt001.t01_nombre,
		formato		CHAR(1),
		b10_nivel	LIKE ctbt010.b10_nivel
	END RECORD
DEFINE rm_pyg   ARRAY[7000] OF RECORD 
		b10_cuenta	LIKE ctbt010.b10_cuenta,
		b10_descripcion	LIKE ctbt010.b10_descripcion,
		saldo		DECIMAL(14,2),
		signo		CHAR(2)
	END RECORD
DEFINE rm_color ARRAY[10] OF VARCHAR(10)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp312.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN    -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'talp312'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL drawinit()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE comando		VARCHAR(100)
DEFINE r_mon		RECORD LIKE gent013.*

LET vm_max_rows	= 7000
OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 30,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_bal FROM "../forms/talf312_1"
DISPLAY FORM f_bal
INITIALIZE rm_par.* TO NULL
LET rm_par.moneda  = rg_gen.g00_moneda_base
LET rm_par.ano     = YEAR(TODAY)
LET rm_par.mes     = MONTH(TODAY)
LET rm_par.tit_mes = fl_retorna_nombre_mes(rm_par.mes)
LET rm_par.formato = 'A'
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
LET rm_par.tit_mon = r_mon.g13_nombre
DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon, rm_par.ano, rm_par.mes, 
		rm_par.tit_mes
CALL genera_grafico() 
WHILE TRUE
	CALL lee_parametros_grafico()
	IF int_flag THEN
		RETURN
	END IF
	CALL genera_grafico() 
END WHILE

END FUNCTION



FUNCTION lee_parametros_grafico()
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_aux		LIKE gent013.g13_nombre
DEFINE mes_aux		SMALLINT	
DEFINE tit_mes		VARCHAR(20)              
DEFINE i, j		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE rn		RECORD LIKE ctbt001.*
DEFINE rc		RECORD LIKE gent033.*
DEFINE r_t01		RECORD LIKE talt001.*

LET int_flag = 0
DISPLAY BY NAME rm_par.tit_mon
INPUT BY NAME rm_par.ano, rm_par.mes, rm_par.tit_mes, rm_par.moneda, 
              rm_par.t01_linea WITHOUT DEFAULTS
	ON KEY(F2)
		IF infield(moneda) THEN
                       	CALL fl_ayuda_monedas() RETURNING mon_aux, tit_aux, i
                       	IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda  = mon_aux
				LET rm_par.tit_mon = tit_aux
                               	DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
                       	END IF
                END IF
		IF INFIELD(t01_linea) THEN
			CALL fl_ayuda_marcas_taller(vg_codcia)
				RETURNING r_t01.t01_linea, r_t01.t01_nombre
			IF r_t01.t01_linea IS NOT NULL THEN
				LET rm_par.t01_linea = r_t01.t01_linea
				LET rm_par.tit_linea = r_t01.t01_nombre
				DISPLAY BY NAME rm_par.t01_linea,
						rm_par.tit_linea
			END IF
		END IF
{
		IF INFIELD(mes) THEN
			CALL fl_ayuda_mostrar_meses() RETURNING mes_aux, tit_mes
			IF mes_aux IS NOT NULL THEN
				LET rm_par.mes = mes_aux
				LET rm_par.tit_mes = tit_mes
				DISPLAY BY NAME rm_par.mes, rm_par.tit_mes
			END IF
		END IF
} 
               LET int_flag = 0
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Moneda no existe', 'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = r_mon.g13_nombre
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			DISPLAY BY NAME rm_par.tit_mon
		END IF
	AFTER FIELD ano
		IF rm_par.ano > YEAR(TODAY) THEN
			CALL fgl_winmessage(vg_producto, 'Año incorrecto', 'exclamation')
			NEXT FIELD ano
		END IF
	AFTER FIELD t01_linea
		IF rm_par.t01_linea IS NOT NULL THEN
			CALL fl_lee_linea_taller(vg_codcia, rm_par.t01_linea)
				RETURNING r_t01.*
			IF r_t01.t01_linea IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe esa Línea en la Compañía.','exclamation')
				NEXT FIELD t01_linea
			END IF
			LET rm_par.t01_linea = r_t01.t01_linea
			LET rm_par.tit_linea = r_t01.t01_nombre
			DISPLAY BY NAME rm_par.t01_linea,
					rm_par.tit_linea
		ELSE
			CLEAR tit_linea
		END IF
	AFTER FIELD mes
		IF rm_par.mes IS NULL THEN
			CLEAR mes, tit_mes
		END IF
		CALL fl_retorna_nombre_mes(rm_par.mes) RETURNING rm_par.tit_mes
		DISPLAY BY NAME rm_par.mes, rm_par.tit_mes
END INPUT

END FUNCTION



FUNCTION genera_grafico()
DEFINE tarea		CHAR(2)	
DEFINE hora_ini		LIKE talt034.t34_hora_ini
DEFINE hora_fin		LIKE talt034.t34_hora_fin
DEFINE minutos		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE expr_linea	VARCHAR(500)

DEFINE inicio_x		SMALLINT
DEFINE inicio_y		SMALLINT
DEFINE maximo_x		SMALLINT
DEFINE maximo_y		SMALLINT
DEFINE factor_y		DECIMAL(26,10)
DEFINE elementos_ydb	SMALLINT
DEFINE elementos_ycr	SMALLINT
DEFINE elementos_y	SMALLINT
DEFINE elementos_x	SMALLINT
DEFINE intervalo_x	SMALLINT
DEFINE intervalo_y	SMALLINT

DEFINE pos_ini_x	SMALLINT
DEFINE pos_fin_x	SMALLINT
DEFINE pos_fin_y	SMALLINT
DEFINE pos_ant_x	SMALLINT
DEFINE pos_ant_y	SMALLINT
DEFINE marca_x		SMALLINT
DEFINE marca_y		SMALLINT
DEFINE pos_ini		SMALLINT
DEFINE pos_ini_y	SMALLINT
DEFINE aux		SMALLINT

DEFINE inicio2_x	SMALLINT
DEFINE inicio2_y	SMALLINT

DEFINE max_valor	DECIMAL(14,2)
DEFINE valor_c 		CHAR(10)

DEFINE mes, i, indice	SMALLINT
DEFINE j		SMALLINT
DEFINE divisor       	SMALLINT
DEFINE valor_rango  	DECIMAL(11,0)
DEFINE valor_rango_db  	DECIMAL(11,0)
DEFINE valor_rango_cr  	DECIMAL(11,0)
DEFINE valor_aux     	DECIMAL(11,0)
DEFINE valor, saldo	DECIMAL(14,2)
DEFINE puntos_y    	INTEGER
DEFINE max_valor_cr	DECIMAL(14,2)
DEFINE max_valor_db	DECIMAL(14,2)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
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
	valor		DECIMAL(14,2)
	END RECORD

CALL carga_colores()
LET inicio_x    = 120
LET inicio_y    = 100
LET maximo_x    = 800
LET maximo_y    = 750
LET elementos_y = 10
LET intervalo_y = 65
CREATE TEMP TABLE temp_tareas 
	(te_codtarea	CHAR(2),
	 te_valor	DECIMAL(14,2),
	 te_orden	SMALLINT)

LET expr_linea = ' '
IF rm_par.t01_linea IS NOT NULL THEN
	LET expr_linea = ' AND t34_modelo IN (SELECT t04_modelo FROM talt004 ',
				' WHERE t04_compania = ', vg_codcia,
				'   AND t04_linea = "', rm_par.t01_linea CLIPPED, '")'
END IF

DECLARE q_tareas CURSOR FOR
	SELECT t35_codtarea[1,2] FROM talt035 GROUP BY 1 ORDER BY 1

LET i = 1
FOREACH q_tareas INTO tarea
	LET fecha_ini = MDY(rm_par.mes, 1, rm_par.ano)
	LET fecha_fin = MDY(rm_par.mes, 1, rm_par.ano) 
			+ 1 UNITS MONTH - 1 UNITS DAY

	LET query = 'SELECT t34_hora_ini, t34_hora_fin ',
		    ' 	FROM talt023, talt034 ',
		    '	WHERE t23_compania      =  ', vg_codcia,
		    '     AND t23_localidad     =  ', vg_codloc,
		    '     AND t23_moneda        = "', rm_par.moneda, '"',
		    '	  AND t34_compania      = t23_compania ',
		    '     AND t34_localidad     = t23_localidad ',
		    '     AND t34_orden         = t23_orden     ',
		    '	  AND t34_codtarea[1,2] = "', tarea CLIPPED, '"',
		    '	  AND t34_fecha BETWEEN DATE("', fecha_ini, '")',
					'   AND DATE("', fecha_fin, '")', 
		    expr_linea CLIPPED

	PREPARE cons FROM query
	DECLARE q_horas CURSOR FOR cons
	
	LET minutos = 0
	FOREACH q_horas INTO hora_ini, hora_fin
		LET minutos = minutos + convertir_horas_numero(hora_fin - hora_ini) 
	END FOREACH

	INSERT INTO temp_tareas VALUES (tarea, minutos, i)
	LET i = i + 1
END FOREACH	
UPDATE temp_tareas SET te_valor = te_valor / 60 WHERE 1 = 1
LET elementos_x = i - 1
LET intervalo_x = maximo_x / elementos_x

-- Aparentemente son los limites del grafico
-- el limite hacia abajo siempre va a ser 0
SELECT MAX(te_valor) INTO max_valor_cr FROM temp_tareas
	WHERE te_valor > 0
IF max_valor_cr IS NULL THEN
	LET max_valor_cr = 0
END IF
SELECT MIN(te_valor) INTO max_valor_db FROM temp_tareas
	WHERE te_valor < 0
IF max_valor_db IS NULL THEN
	LET max_valor_db = 0
END IF
LET max_valor_db = max_valor_db * -1
IF max_valor_cr + max_valor_db = 0 THEN
	CALL fgl_winmessage(vg_producto, 'No hay valores que mostrar.',
					'exclamation')
	DROP TABLE temp_tareas
	RETURN
END IF
DECLARE q_lin CURSOR FOR SELECT te_codtarea, (te_valor * -1), te_orden 
	FROM temp_tareas
	ORDER BY 3
CALL drawselect('c001')
CALL drawclear()
CALL drawanchor('w')
CALL drawlinewidth(2)
CALL DrawFillColor("black")
--LET aux = (maximo_y * max_valor_db) / max_valor_cr
LET aux = (maximo_y * max_valor_db) / (max_valor_cr + max_valor_db)
LET inicio2_y = inicio_y + aux
LET i = drawline(inicio2_y, inicio_x, 0, maximo_x)
LET i = drawline(inicio_y, inicio_x, maximo_y, 0)
LET elementos_ydb = aux / intervalo_y
LET elementos_ycr = (maximo_y - aux)  / intervalo_y
--
LET divisor = 1
LET max_valor = max_valor_cr
IF max_valor_db > max_valor THEN
	LET max_valor = max_valor_db
END IF	
IF max_valor > 999999 THEN
	LET divisor = 1000
	LET i = drawtext(920,10,'Valores expresados en miles')
END IF
IF max_valor_cr > 0 THEN
	LET i = drawtext(inicio_y + maximo_y + 20,80,'TIEMPOS')
END IF
LET valor_rango_cr = max_valor_cr / divisor / elementos_ycr
LET valor_rango_db = max_valor_db / divisor / elementos_ydb
LET valor_rango = valor_rango_cr
IF valor_rango_db > valor_rango_cr THEN
	LET valor_rango = valor_rango_db
END IF
LET valor_aux = ((intervalo_y * (elementos_ycr + elementos_ydb)) * 
		(max_valor_cr + max_valor_db)) /
		((elementos_ycr + elementos_ydb) * valor_rango)
LET factor_y  = valor_aux / (max_valor_db + max_valor_cr)
--LET factor_y  = (intervalo_y * (elementos_ycr + elementos_ydb))  
		--/ (max_valor_db + max_valor_cr)
LET marca_x   = inicio_x + intervalo_x
LET marca_y   = inicio2_y + intervalo_y
LET pos_ini   = 900
LET indice    = 0
LET valor_aux = valor_rango 
LET valor_c   = "         0"
LET i = drawline(inicio2_y, inicio_x - 10, 0, 20)
LET i = drawtext(inicio2_y, inicio_x - 150, valor_c)
FOR j = 1 TO elementos_ycr
	IF j = elementos_ycr AND divisor = 1 THEN
		IF max_valor_cr > valor_aux THEN
			LET valor_aux = max_valor_cr
		END IF
	END IF
	LET valor_c = valor_aux USING "##,###,##&"
	LET i = drawline(marca_y, inicio_x - 10, 0, 20)
	LET i = drawtext(marca_y, inicio_x - 150, valor_c)
	LET valor_aux = valor_aux + valor_rango
	LET marca_y = marca_y + intervalo_y
END FOR
LET valor_aux = valor_rango 
LET marca_y   = inicio2_y - intervalo_y
FOR j = 1 TO elementos_ydb
	IF j = elementos_ydb AND divisor = 1 THEN
		IF max_valor_db > valor_aux THEN
			LET valor_aux = max_valor_db
		END IF
	END IF
	LET valor_c = valor_aux USING "##,###,##&"
	LET i = drawline(marca_y, inicio_x - 10, 0, 20)
	LET i = drawtext(marca_y, inicio_x - 150, valor_c)
	LET valor_aux = valor_aux + valor_rango
	LET marca_y = marca_y - intervalo_y
END FOR
LET pos_ant_y = inicio2_y
LET pos_ini_x = inicio_x + 40
FOREACH q_lin INTO tarea, valor, mes
	CALL drawlinewidth(1)
	CALL DrawFillColor("blue")
	LET puntos_y = factor_y * valor
	IF puntos_y < 0 THEN
		LET puntos_y = puntos_y * -1
	END IF
	IF valor > 0 THEN
		LET pos_ini_y = inicio2_y - puntos_y
		CALL DrawFillColor("red")
		LET pos_fin_y = puntos_y
	ELSE
		LET pos_ini_y = inicio2_y
		LET pos_fin_y = puntos_y
	END IF
	LET r_obj[mes].id_obj_rec1 = drawrectangle(pos_ini_y,pos_ini_x,pos_fin_y,75)
	LET r_obj[mes].valor       = valor
	LET pos_ini_x = pos_ini_x + intervalo_x 
END FOREACH
CALL DrawFillColor("black")
LET marca_x = inicio_x + 40 + 45 
FOREACH q_lin INTO tarea, valor, mes
	LET siglas_mes = tarea 
	IF r_obj[j].valor = 0 THEN
		LET i = drawline(inicio2_y - 10, marca_x, 20, 0)
	END IF
	LET i = drawtext(inicio2_y - 20, marca_x - 20, siglas_mes)
	LET marca_x = marca_x + intervalo_x
END FOREACH

FOREACH q_lin INTO tarea, valor, i
	LET key_n = i + 30
	LET key_c = 'F', key_n
	CALL drawbuttonleft(r_obj[i].id_obj_rec1, key_c)
END FOREACH

LET key_f30 = FGL_KEYVAL("F30")
LET int_flag = 0
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
		CALL dialog.keysetlabel("F39","")
		CALL dialog.keysetlabel("F40","")
		CALL dialog.keysetlabel("F41","")
		CALL dialog.keysetlabel("F42","")
	ON KEY(F31,F32,F33,F34,F35,F36,F37,F38,F39,F40,F41,F42)
		LET mes = FGL_LASTKEY() - key_f30
		SELECT te_codtarea INTO tarea FROM temp_tareas
			WHERE te_orden = mes
		CALL genera_grafico_detalle(tarea)
	AFTER FIELD tecla
		NEXT FIELD tecla	
END INPUT
DROP TABLE temp_tareas
	
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



FUNCTION convertir_horas_numero(hora)
DEFINE hora		CHAR(6)	
DEFINE fraccion		SMALLINT
DEFINE num_hora		SMALLINT	

LET fraccion = obtener_fraccion_horas(hora)
LET num_hora = fraccion * 60

LET fraccion = obtener_fraccion_minutos(hora)
LET num_hora = num_hora + fraccion

RETURN num_hora

END FUNCTION



FUNCTION obtener_fraccion_horas(hora)
DEFINE hora		CHAR(6)	
DEFINE fraccion		SMALLINT

	LET fraccion = hora[2,2] * 10
	IF fraccion IS NULL THEN
		LET fraccion = 0
	END IF
	LET fraccion = fraccion + (hora[3,3] * 1)

	RETURN fraccion
END FUNCTION



FUNCTION obtener_fraccion_minutos(hora)
DEFINE hora		CHAR(6)	
DEFINE fraccion		SMALLINT

	LET fraccion = fraccion + (hora[5,5] * 10)
	LET fraccion = fraccion + (hora[6,6] * 1)

	RETURN fraccion
END FUNCTION



FUNCTION genera_grafico_detalle(cod_tarea)
DEFINE cod_tarea	CHAR(2)	
DEFINE tarea		LIKE talt034.t34_codtarea
DEFINE hora_ini		LIKE talt034.t34_hora_ini
DEFINE hora_fin		LIKE talt034.t34_hora_fin
DEFINE minutos		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE expr_linea	VARCHAR(500)

DEFINE inicio_x		SMALLINT
DEFINE inicio_y		SMALLINT
DEFINE maximo_x		SMALLINT
DEFINE maximo_y		SMALLINT
DEFINE factor_y		DECIMAL(26,10)
DEFINE elementos_ydb	SMALLINT
DEFINE elementos_ycr	SMALLINT
DEFINE elementos_y	SMALLINT
DEFINE elementos_x	SMALLINT
DEFINE intervalo_x	SMALLINT
DEFINE intervalo_y	SMALLINT

DEFINE pos_ini_x	SMALLINT
DEFINE pos_fin_x	SMALLINT
DEFINE pos_fin_y	SMALLINT
DEFINE pos_ant_x	SMALLINT
DEFINE pos_ant_y	SMALLINT
DEFINE marca_x		SMALLINT
DEFINE marca_y		SMALLINT
DEFINE pos_ini		SMALLINT
DEFINE pos_ini_y	SMALLINT
DEFINE aux		SMALLINT

DEFINE inicio2_x	SMALLINT
DEFINE inicio2_y	SMALLINT

DEFINE max_valor	DECIMAL(14,2)
DEFINE valor_c 		CHAR(10)

DEFINE mes, i, indice	SMALLINT
DEFINE j		SMALLINT
DEFINE divisor       	SMALLINT
DEFINE valor_rango  	DECIMAL(11,0)
DEFINE valor_rango_db  	DECIMAL(11,0)
DEFINE valor_rango_cr  	DECIMAL(11,0)
DEFINE valor_aux     	DECIMAL(11,0)
DEFINE valor, saldo	DECIMAL(14,2)
DEFINE puntos_y    	INTEGER
DEFINE max_valor_cr	DECIMAL(14,2)
DEFINE max_valor_db	DECIMAL(14,2)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
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
	valor		DECIMAL(14,2)
	END RECORD

OPEN WINDOW wfdet AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 30,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_det FROM "../forms/talf312_2"
DISPLAY FORM f_det

CASE cod_tarea
	WHEN 'HF'
		LET titulo = 'Horas Hombre Facturables'
	WHEN 'HO'
		LET titulo = 'Horas Hombre Otras'
	WHEN 'HD'
		LET titulo = 'Horas Hombre Transferibles a Otros Departamentos'
	WHEN 'HS'
		LET titulo = 'Horas Hombre Departamento de Servicios'
	OTHERWISE
		LET titulo = 'Horas Hombre Desconocidas'
END CASE
DISPLAY BY NAME titulo

CALL carga_colores()
LET inicio_x    = 120
LET inicio_y    = 100
LET maximo_x    = 800
LET maximo_y    = 750
LET elementos_y = 10
LET intervalo_y = 65
CREATE TEMP TABLE temp_tareas2 
	(te_codtarea	CHAR(3),
	 te_valor	DECIMAL(14,2),
	 te_orden	SMALLINT)

LET expr_linea = ' '
IF rm_par.t01_linea IS NOT NULL THEN
	LET expr_linea = ' AND t34_modelo IN (SELECT t04_modelo FROM talt004 ',
				' WHERE t04_compania = ', vg_codcia,
				'   AND t04_linea = "', rm_par.t01_linea CLIPPED, '")'
END IF

DECLARE q_subtareas CURSOR FOR
	SELECT t35_codtarea FROM talt035 
		WHERE t35_codtarea[1,2] = cod_tarea
		ORDER BY 1

LET i = 1
FOREACH q_subtareas INTO tarea
	LET fecha_ini = MDY(rm_par.mes, 1, rm_par.ano)
	LET fecha_fin = MDY(rm_par.mes, 1, rm_par.ano) 
			+ 1 UNITS MONTH - 1 UNITS DAY

	LET query = 'SELECT t34_hora_ini, t34_hora_fin ',
		    ' 	FROM talt023, talt034 ',
		    '	WHERE t23_compania      =  ', vg_codcia,
		    '     AND t23_localidad     =  ', vg_codloc,
		    '     AND t23_moneda        = "', rm_par.moneda, '"',
		    '	  AND t34_compania      = t23_compania ',
		    '     AND t34_localidad     = t23_localidad ',
		    '     AND t34_orden         = t23_orden     ',
		    '	  AND t34_codtarea      = "', tarea CLIPPED, '"',
		    '	  AND t34_fecha BETWEEN DATE("', fecha_ini, '")',
					'   AND DATE("', fecha_fin, '")', 
		    expr_linea CLIPPED

	PREPARE cons2 FROM query
	DECLARE q_horas2 CURSOR FOR cons2
	
	LET minutos = 0
	FOREACH q_horas2 INTO hora_ini, hora_fin
		LET minutos = minutos + convertir_horas_numero(hora_fin - hora_ini) 
	END FOREACH

	INSERT INTO temp_tareas2 VALUES (tarea, minutos, i)
	LET i = i + 1
END FOREACH	
UPDATE temp_tareas2 SET te_valor = te_valor / 60 WHERE 1 = 1
LET elementos_x = i - 1
LET intervalo_x = maximo_x / elementos_x

-- Aparentemente son los limites del grafico
-- el limite hacia abajo siempre va a ser 0
SELECT MAX(te_valor) INTO max_valor_cr FROM temp_tareas2
	WHERE te_valor > 0
IF max_valor_cr IS NULL THEN
	LET max_valor_cr = 0
END IF
SELECT MIN(te_valor) INTO max_valor_db FROM temp_tareas2
	WHERE te_valor < 0
IF max_valor_db IS NULL THEN
	LET max_valor_db = 0
END IF
LET max_valor_db = max_valor_db * -1
IF max_valor_cr + max_valor_db = 0 THEN
	CALL fgl_winmessage(vg_producto, 'No hay valores que mostrar.',
					'exclamation')
	DROP TABLE temp_tareas2
	CLOSE WINDOW wfdet
	RETURN
END IF
DECLARE q_lin2 CURSOR FOR SELECT te_codtarea, (te_valor * -1), te_orden 
	FROM temp_tareas2
	ORDER BY 3
CALL drawselect('c001')
CALL drawclear()
CALL drawanchor('w')
CALL drawlinewidth(2)
CALL DrawFillColor("black")
--LET aux = (maximo_y * max_valor_db) / max_valor_cr
LET aux = (maximo_y * max_valor_db) / (max_valor_cr + max_valor_db)
LET inicio2_y = inicio_y + aux
LET i = drawline(inicio2_y, inicio_x, 0, maximo_x)
LET i = drawline(inicio_y, inicio_x, maximo_y, 0)
LET elementos_ydb = aux / intervalo_y
LET elementos_ycr = (maximo_y - aux)  / intervalo_y
--
LET divisor = 1
LET max_valor = max_valor_cr
IF max_valor_db > max_valor THEN
	LET max_valor = max_valor_db
END IF	
IF max_valor > 999999 THEN
	LET divisor = 1000
	LET i = drawtext(920,10,'Valores expresados en miles')
END IF
IF max_valor_cr > 0 THEN
	LET i = drawtext(inicio_y + maximo_y + 20,80,'TIEMPOS')
END IF
LET valor_rango_cr = max_valor_cr / divisor / elementos_ycr
LET valor_rango_db = max_valor_db / divisor / elementos_ydb
LET valor_rango = valor_rango_cr
IF valor_rango_db > valor_rango_cr THEN
	LET valor_rango = valor_rango_db
END IF
LET valor_aux = ((intervalo_y * (elementos_ycr + elementos_ydb)) * 
		(max_valor_cr + max_valor_db)) /
		((elementos_ycr + elementos_ydb) * valor_rango)
LET factor_y  = valor_aux / (max_valor_db + max_valor_cr)
--LET factor_y  = (intervalo_y * (elementos_ycr + elementos_ydb))  
		--/ (max_valor_db + max_valor_cr)
LET marca_x   = inicio_x + intervalo_x
LET marca_y   = inicio2_y + intervalo_y
LET pos_ini   = 900
LET indice    = 0
LET valor_aux = valor_rango 
LET valor_c   = "         0"
LET i = drawline(inicio2_y, inicio_x - 10, 0, 20)
LET i = drawtext(inicio2_y, inicio_x - 150, valor_c)
FOR j = 1 TO elementos_ycr
	IF j = elementos_ycr AND divisor = 1 THEN
		IF max_valor_cr > valor_aux THEN
			LET valor_aux = max_valor_cr
		END IF
	END IF
	LET valor_c = valor_aux USING "##,###,##&"
	LET i = drawline(marca_y, inicio_x - 10, 0, 20)
	LET i = drawtext(marca_y, inicio_x - 150, valor_c)
	LET valor_aux = valor_aux + valor_rango
	LET marca_y = marca_y + intervalo_y
END FOR
LET valor_aux = valor_rango 
LET marca_y   = inicio2_y - intervalo_y
FOR j = 1 TO elementos_ydb
	IF j = elementos_ydb AND divisor = 1 THEN
		IF max_valor_db > valor_aux THEN
			LET valor_aux = max_valor_db
		END IF
	END IF
	LET valor_c = valor_aux USING "##,###,##&"
	LET i = drawline(marca_y, inicio_x - 10, 0, 20)
	LET i = drawtext(marca_y, inicio_x - 150, valor_c)
	LET valor_aux = valor_aux + valor_rango
	LET marca_y = marca_y - intervalo_y
END FOR
LET pos_ant_y = inicio2_y
LET pos_ini_x = inicio_x + 40
FOREACH q_lin2 INTO tarea, valor, mes
	CALL drawlinewidth(1)
	CALL DrawFillColor("blue")
	LET puntos_y = factor_y * valor
	IF puntos_y < 0 THEN
		LET puntos_y = puntos_y * -1
	END IF
	IF valor > 0 THEN
		LET pos_ini_y = inicio2_y - puntos_y
		CALL DrawFillColor("red")
		LET pos_fin_y = puntos_y
	ELSE
		LET pos_ini_y = inicio2_y
		LET pos_fin_y = puntos_y
	END IF
	LET r_obj[mes].id_obj_rec1 = drawrectangle(pos_ini_y,pos_ini_x,pos_fin_y,75)
	LET r_obj[mes].valor       = valor
	LET pos_ini_x = pos_ini_x + intervalo_x 
END FOREACH
CALL DrawFillColor("black")
LET marca_x = inicio_x + 40 + 45 
FOREACH q_lin2 INTO tarea, valor, mes
	LET siglas_mes = tarea 
	IF r_obj[j].valor = 0 THEN
		LET i = drawline(inicio2_y - 10, marca_x, 20, 0)
	END IF
	LET i = drawtext(inicio2_y - 20, marca_x - 20, siglas_mes)
	LET marca_x = marca_x + intervalo_x
END FOREACH

FOREACH q_lin2 INTO tarea, valor, i
	LET key_n = i + 30
	LET key_c = 'F', key_n
	CALL drawbuttonleft(r_obj[i].id_obj_rec1, key_c)
END FOREACH

LET key_f30 = FGL_KEYVAL("F30")
LET int_flag = 0
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
		CALL dialog.keysetlabel("F39","")
		CALL dialog.keysetlabel("F40","")
		CALL dialog.keysetlabel("F41","")
		CALL dialog.keysetlabel("F42","")
	ON KEY(F31,F32,F33,F34,F35,F36,F37,F38,F39,F40,F41,F42)
		LET mes = FGL_LASTKEY() - key_f30
		SELECT te_codtarea INTO tarea FROM temp_tareas2
			WHERE te_orden = mes
		CALL mostrar_detalle(tarea)
	AFTER FIELD tecla
		NEXT FIELD tecla	
END INPUT
DROP TABLE temp_tareas2

CLOSE WINDOW wfdet
	
END FUNCTION



FUNCTION mostrar_detalle(tarea)
DEFINE tarea		LIKE talt034.t34_codtarea
DEFINE tit_tarea	LIKE talt035.t35_nombre
DEFINE query		VARCHAR(1000)
DEFINE expr_linea	VARCHAR(500)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

DEFINE num_rows		INTEGER
DEFINE max_rows		INTEGER

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE r_t03		RECORD LIKE talt003.*
DEFINE r_t23		RECORD LIKE talt023.*

DEFINE r_detalle ARRAY[1000]	OF	RECORD 
	orden		LIKE talt024.t24_orden,	
	actividad	LIKE talt024.t24_descripcion,	
	mecanico	LIKE talt024.t24_mecanico,	
	fecha		LIKE talt034.t34_fecha,	
	hora_ini	LIKE talt034.t34_hora_ini,	
	hora_fin	LIKE talt034.t34_hora_fin	
END RECORD

OPEN WINDOW wfdet2 AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 30,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_det2 FROM "../forms/talf312_3"
DISPLAY FORM f_det2

LET max_rows = 1000

SELECT t35_nombre INTO tit_tarea
	FROM talt035
	WHERE t35_compania = vg_codcia
	  AND t35_codtarea = tarea

DISPLAY tarea, tit_tarea TO codtarea, tit_tarea

DISPLAY 'Orden' TO bt_orden
DISPLAY 'Actividad' TO bt_actividad
DISPLAY 'Mec.' TO bt_mecanico
DISPLAY 'Fecha' TO bt_fecha
DISPLAY 'INI' TO bt_hora_ini
DISPLAY 'FIN' TO bt_hora_fin

LET expr_linea = ' '
IF rm_par.t01_linea IS NOT NULL THEN
	LET expr_linea = ' AND t24_modelo IN (SELECT t04_modelo FROM talt004 ',
				' WHERE t04_compania = ', vg_codcia,
				'   AND t04_linea = "', rm_par.t01_linea CLIPPED, '")'
END IF

LET fecha_ini = MDY(rm_par.mes, 1, rm_par.ano)
LET fecha_fin = MDY(rm_par.mes, 1, rm_par.ano) + 1 UNITS MONTH - 1 UNITS DAY

LET query = 'SELECT t34_orden, t24_descripcion, t24_mecanico, t34_fecha, ',
            '       t34_hora_ini, t34_hora_fin ',
	    ' 	FROM talt023, talt024, talt034 ',
	    '	WHERE t23_compania      =  ', vg_codcia,
	    '     AND t23_localidad     =  ', vg_codloc,
	    '     AND t23_moneda        = "', rm_par.moneda, '"',
	    '	  AND t24_compania      = t23_compania ',
	    '     AND t24_localidad     = t23_localidad ',
	    '     AND t24_orden         = t23_orden     ',
	    expr_linea CLIPPED,
	    '	  AND t24_codtarea      = "', tarea CLIPPED, '"',
	    '	  AND t34_compania      = t24_compania  ',
	    '     AND t34_localidad     = t24_localidad ',
	    '     AND t34_orden         = t24_orden     ',
	    '     AND t34_modelo        = t24_modelo    ',
	    '	  AND t34_codtarea      = t24_codtarea  ',
	    '	  AND t34_secuencia     = t24_secuencia ',
	    '	  AND t34_fecha BETWEEN DATE("', fecha_ini, '")',
				'   AND DATE("', fecha_fin, '")',
	    ' ORDER BY t34_fecha, t34_hora_ini '

PREPARE cons_det FROM query
DECLARE q_detalle CURSOR FOR cons_det 

LET num_rows = 1
FOREACH q_detalle INTO r_detalle[num_rows].*
	LET num_rows = num_rows + 1
	IF num_rows > max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_rows = num_rows - 1

IF num_rows > 0 THEN
	CALL set_count(num_rows)
END IF
DISPLAY ARRAY r_detalle TO r_detalle.*
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, 
					  r_detalle[i].orden) 
			RETURNING r_t23.*
		CALL fl_lee_mecanico(vg_codcia, r_detalle[i].mecanico) 
			RETURNING r_t03.*
		DISPLAY r_t23.t23_nom_cliente, r_t03.t03_nombres
			TO tit_cliente, tit_mecanico
END DISPLAY

CLOSE WINDOW wfdet2

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
