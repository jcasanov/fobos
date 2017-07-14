------------------------------------------------------------------------------
-- Titulo           : ctbp306.4gl - Consulta Pérdidas y Ganancias
-- Elaboracion      : 25-ene-2002
-- Autor            : YEC
-- Formato Ejecucion: fglrun ctbp306 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_nivel	LIKE ctbt001.b01_nivel
DEFINE vm_saldo_pyg	DECIMAL(16,2)
DEFINE tot_saldo	DECIMAL(16,2)
DEFINE tot_saldo_mes	DECIMAL(16,2)
DEFINE rg_cont		RECORD LIKE ctbt000.*
DEFINE rm_par		RECORD 
				ano		SMALLINT,
				mes		SMALLINT,
				tit_mes		VARCHAR(10),
				moneda		LIKE gent013.g13_moneda,
				tit_mon		LIKE gent013.g13_nombre,
				ccosto		LIKE gent033.g33_cod_ccosto,
				tit_ccosto	LIKE gent033.g33_nombre,
				b10_nivel	LIKE ctbt010.b10_nivel,
				diario_cie	CHAR(1)
			END RECORD
DEFINE rm_pyg		ARRAY[7000] OF RECORD 
				b10_cuenta	LIKE ctbt010.b10_cuenta,
				b10_descripcion	LIKE ctbt010.b10_descripcion,
				saldo_mes	DECIMAL(14,2),
				saldo		DECIMAL(14,2)
			END RECORD
DEFINE rm_color		ARRAY[10] OF VARCHAR(10)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp306.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN    -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ctbp306'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
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
OPEN FORM f_bal FROM "../forms/ctbf306_2"
DISPLAY FORM f_bal
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rg_cont.*
INITIALIZE rm_par.* TO NULL
LET rm_par.moneda  = rg_cont.b00_moneda_base
LET rm_par.ano     = YEAR(TODAY)
LET rm_par.mes     = MONTH(TODAY)
SELECT MAX(b01_nivel) INTO vm_max_nivel FROM ctbt001
IF vm_max_nivel IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Nivel no está configurado.','stop')
	EXIT PROGRAM
END IF
LET rm_par.b10_nivel  = vm_max_nivel
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
LET rm_par.tit_mon    = r_mon.g13_nombre
LET rm_par.diario_cie = 'N'
DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon, rm_par.ano, rm_par.diario_cie
CALL quitar_diario_cierre_anio(rm_par.ano, 'D')
CALL genera_grafico() 
WHILE TRUE
	CALL lee_parametros_grafico()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF rm_par.diario_cie = 'N' THEN
		CALL quitar_diario_cierre_anio(rm_par.ano, 'D')
	END IF
	CALL genera_grafico() 
	IF rm_par.diario_cie = 'N' THEN
		CALL quitar_diario_cierre_anio(rm_par.ano, 'M')
	END IF
END WHILE
CALL quitar_diario_cierre_anio(rm_par.ano, 'M')

END FUNCTION



FUNCTION control_detalle_pyg()

OPEN WINDOW wd AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 30,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_detpyg FROM "../forms/ctbf306_1"
DISPLAY FORM f_detpyg
DISPLAY "Cuenta"	TO tit_col1
DISPLAY "Descripción"	TO tit_col2
DISPLAY "Mov. del Mes"	TO tit_col3
DISPLAY "Saldo al Mes"	TO tit_col4
CALL lee_parametros_detalle()
IF int_flag THEN
	CLOSE WINDOW wd
	RETURN
END IF
CALL carga_arreglo()
IF NOT int_flag THEN
	CALL muestra_pyg()
END IF

END FUNCTION



FUNCTION lee_parametros_grafico()
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_aux		LIKE gent013.g13_nombre
DEFINE nivel		LIKE ctbt001.b01_nivel
DEFINE i, j		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE rn		RECORD LIKE ctbt001.*
DEFINE rc		RECORD LIKE gent033.*
DEFINE ccosto		LIKE gent033.g33_cod_ccosto
DEFINE ncosto		LIKE gent033.g33_nombre

LET int_flag = 0
DISPLAY BY NAME rm_par.tit_mon
INPUT BY NAME rm_par.ano, rm_par.diario_cie, rm_par.moneda, rm_par.ccosto
	WITHOUT DEFAULTS
	ON KEY(F2)
		IF INFIELD(moneda) THEN
                       	CALL fl_ayuda_monedas() RETURNING mon_aux, tit_aux, i
                       	IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda  = mon_aux
				LET rm_par.tit_mon = tit_aux
                               	DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
                       	END IF
                END IF
		IF INFIELD(ccosto) THEN
                       	CALL fl_ayuda_ccostos(vg_codcia) 
				RETURNING ccosto, ncosto
                       	IF ccosto IS NOT NULL THEN
				LET rm_par.ccosto     = ccosto
				LET rm_par.tit_ccosto = ncosto
                               	DISPLAY BY NAME rm_par.ccosto, rm_par.tit_ccosto
                       	END IF
		END IF
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
	AFTER FIELD ccosto
		IF rm_par.ccosto IS NOT NULL THEN
			CALL fl_lee_centro_costo(vg_codcia, rm_par.ccosto)
				RETURNING rc.*
			IF rc.g33_cod_ccosto IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Centro de costo no existe', 'exclamation')
				NEXT FIELD ccosto
			END IF
			LET rm_par.tit_ccosto = rc.g33_nombre
			DISPLAY BY NAME rm_par.tit_ccosto
		ELSE
			CLEAR tit_ccosto
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros_detalle()
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_aux		LIKE gent013.g13_nombre
DEFINE nivel		LIKE ctbt001.b01_nivel
DEFINE i, j		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE rn		RECORD LIKE ctbt001.*
DEFINE rc		RECORD LIKE gent033.*
DEFINE ccosto		LIKE gent033.g33_cod_ccosto
DEFINE ncosto		LIKE gent033.g33_nombre

CALL fl_retorna_nombre_mes(rm_par.mes) RETURNING rm_par.tit_mes
LET rm_par.tit_mes = fl_justifica_titulo('I', rm_par.tit_mes, 10)
LET int_flag = 0
DISPLAY BY NAME rm_par.*
INPUT BY NAME rm_par.b10_nivel
	WITHOUT DEFAULTS
	ON KEY(F2)
		IF INFIELD(b10_nivel) THEN
                       	CALL fl_ayuda_nivel_cuentas() 
				RETURNING nivel, tit_aux, i, j
                       	IF nivel IS NOT NULL THEN
				LET rm_par.b10_nivel = nivel
                               	DISPLAY BY NAME rm_par.b10_nivel
                       	END IF
                END IF
                LET int_flag = 0
	AFTER FIELD b10_nivel
		IF rm_par.b10_nivel IS NOT NULL THEN
			CALL fl_lee_nivel_cuenta(rm_par.b10_nivel)
				RETURNING rn.*
			IF rn.b01_nivel IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Nivel de cuenta no existe', 'exclamation')
				NEXT FIELD b10_nivel
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION carga_arreglo()
DEFINE r_ctas		RECORD LIKE ctbt010.*
DEFINE i		SMALLINT
DEFINE cuantos		INTEGER
DEFINE suma		CHAR(3)
DEFINE saldo		DECIMAL(14,2)
DEFINE saldo_mes	DECIMAL(14,2)
DEFINE fecha		DATE

LET fecha = MDY(rm_par.mes, 1, rm_par.ano) + 1 UNITS MONTH - 1 UNITS DAY
DECLARE q_ctas CURSOR FOR SELECT * FROM ctbt010
	WHERE b10_compania = vg_codcia AND
	      b10_tipo_cta = 'R'       AND
	      b10_nivel   <= rm_par.b10_nivel
	ORDER BY b10_cuenta
LET vm_num_rows   = 1 
LET vm_saldo_pyg  = 0
LET tot_saldo     = 0
LET tot_saldo_mes = 0
FOREACH q_ctas INTO r_ctas.*
	IF rm_par.ccosto IS NOT NULL THEN
		IF rm_par.ccosto <> r_ctas.b10_cod_ccosto OR
			r_ctas.b10_cod_ccosto IS NULL THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF r_ctas.b10_estado = 'B' THEN
		SELECT COUNT(*) INTO cuantos
			FROM ctbt013
			WHERE b13_compania = vg_codcia
			  AND b13_cuenta   = r_ctas.b10_cuenta
		IF cuantos = 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	LET rm_pyg[vm_num_rows].b10_cuenta      = r_ctas.b10_cuenta
	LET rm_pyg[vm_num_rows].b10_descripcion = r_ctas.b10_descripcion
	LET saldo = fl_obtiene_saldo_contable(vg_codcia, r_ctas.b10_cuenta,
						rm_par.moneda, fecha, 'A')
	LET saldo_mes = fl_obtiene_saldo_contable(vg_codcia, r_ctas.b10_cuenta,
						rm_par.moneda, fecha, 'M')
	LET rm_pyg[vm_num_rows].saldo           = saldo
	IF rm_par.ccosto IS NULL THEN
		IF r_ctas.b10_nivel = 1 THEN
			LET vm_saldo_pyg = vm_saldo_pyg + saldo
		END IF
	ELSE
		IF r_ctas.b10_nivel = rm_par.b10_nivel THEN
			LET vm_saldo_pyg = vm_saldo_pyg + saldo
		END IF
	END IF	
	LET rm_pyg[vm_num_rows].saldo_mes       = saldo_mes
	IF r_ctas.b10_nivel = 1 THEN
		LET tot_saldo                   = tot_saldo + saldo
		LET tot_saldo_mes               = tot_saldo_mes + saldo_mes
	END IF
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
END IF

END FUNCTION



FUNCTION muestra_pyg()
DEFINE i		SMALLINT

DISPLAY BY NAME tot_saldo, tot_saldo_mes
DISPLAY vm_saldo_pyg TO saldo_pyg
DISPLAY vm_num_rows TO max_row
CALL set_count(vm_num_rows)
LET int_flag = 0
DISPLAY ARRAY rm_pyg TO rm_pyg.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
		LET i = arr_curr()
		CALL control_movimientos(rm_pyg[i].b10_cuenta) 
	ON KEY(F6)
		CALL imprimir()
		LET int_flag = 0
	BEFORE DISPLAY 
		--#CALL dialog.keysetlabel("ACCEPT","")
	BEFORE ROW 
		LET i = arr_curr()
		DISPLAY i TO num_row
	AFTER DISPLAY 
		CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_movimientos(cuenta)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE min_nivel	SMALLINT
DEFINE r_cta		RECORD LIKE ctbt010.*
DEFINE mensaje		VARCHAR(62)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE comando		VARCHAR(130)

CALL fl_lee_cuenta(vg_codcia, cuenta) RETURNING r_cta.*
LET min_nivel = vm_max_nivel - 2
IF r_cta.b10_permite_mov = 'N' THEN
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
	RETURN
END IF
LET fecha_ini = MDY(rm_par.mes, 1, rm_par.ano)
LET fecha_fin = fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
LET comando = 'fglrun ctbp302 ' || vg_base || ' ' ||
		vg_modulo || ' ' ||
		vg_codcia || ' ' ||
		cuenta || ' ' ||
		fecha_ini || ' ' ||
		fecha_fin || ' ' ||
		rm_par.moneda
RUN comando

END FUNCTION



FUNCTION imprimir()
DEFINE comando          CHAR(200)

LET comando = 'fglrun ctbp403 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		rm_par.ano, ' ', rm_par.mes, ' "', rm_par.tit_mes, '" ',
		rm_par.b10_nivel, ' "S" "', rm_par.moneda, '" "',
		rm_par.tit_mon, '" "', rm_par.diario_cie, '"'
RUN comando

END FUNCTION



FUNCTION obtiene_signo_contable(valor)
DEFINE valor		DECIMAL(15,2)

IF valor < 0 THEN
	RETURN 'Cr'
END IF
IF valor > 0 THEN
	RETURN 'Db'
END IF
RETURN '  '

END FUNCTION



FUNCTION genera_grafico()
DEFINE nivel		LIKE ctbt001.b01_nivel
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
DEFINE fecha		DATE
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
LET elementos_x = 12
LET intervalo_x = maximo_x / elementos_x
LET intervalo_y = 65
CREATE TEMP TABLE temp_conta 
	(te_mes		SMALLINT,
	 te_valor	DECIMAL(14,2))
LET nivel = 1 
IF rm_par.ccosto IS NOT NULL THEN
	LET nivel = 6
END IF
FOR i = 1 TO 12
	LET fecha = MDY(i, 1, rm_par.ano) + 1 UNITS MONTH - 1 UNITS DAY
	LET saldo = fl_saldo_cuenta_utilidad(vg_codcia, rm_par.moneda, fecha, 
		    nivel, rm_par.ccosto, 'M')
	INSERT INTO temp_conta VALUES (i, saldo)
END FOR	
SELECT MAX(te_valor) INTO max_valor_db FROM temp_conta
	WHERE te_valor > 0
IF max_valor_db IS NULL THEN
	LET max_valor_db = 0
END IF
SELECT MIN(te_valor) INTO max_valor_cr FROM temp_conta
	WHERE te_valor < 0
IF max_valor_cr IS NULL THEN
	LET max_valor_cr = 0
END IF
LET max_valor_cr = max_valor_cr * -1
IF max_valor_cr + max_valor_db = 0 THEN
	CALL fgl_winmessage(vg_producto, 'No hay valores que mostrar.',
					'exclamation')
	DROP TABLE temp_conta
	RETURN
END IF
DECLARE q_lin CURSOR FOR SELECT te_mes, te_valor FROM temp_conta
	ORDER BY 1
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
	LET i = drawtext(inicio_y + maximo_y + 20,80,'UTILIDAD')
END IF
IF max_valor_db > 0 THEN
	LET i = drawtext(inicio_y - 50,80,'PERDIDA')
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
FOREACH q_lin INTO mes, valor
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
	LET r_obj[mes].id_obj_rec1 = drawrectangle(pos_ini_y,pos_ini_x,pos_fin_y,45)
	LET r_obj[mes].valor       = valor
	LET pos_ini_x = pos_ini_x + intervalo_x 
END FOREACH
CALL DrawFillColor("black")
LET marca_x = inicio_x + intervalo_x
FOR j = 1 TO 12
	LET nombre_mes = fl_retorna_nombre_mes(j)
	LET siglas_mes = fl_justifica_titulo('I', nombre_mes, 10)
	IF r_obj[j].valor = 0 THEN
		LET i = drawline(inicio2_y - 10, marca_x, 20, 0)
	END IF
	IF r_obj[j].valor >= 0 THEN
		LET i = drawtext(inicio2_y + 20, marca_x - 20, siglas_mes)
	ELSE
		LET i = drawtext(inicio2_y - 20, marca_x - 20, siglas_mes)
	END IF
	LET marca_x = marca_x + intervalo_x
END FOR
FOR i = 1 TO 12
	LET key_n = i + 30
	LET key_c = 'F', key_n
	CALL drawbuttonleft(r_obj[i].id_obj_rec1, key_c)
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
		LET rm_par.mes = FGL_LASTKEY() - key_f30
		CALL control_detalle_pyg()
	AFTER FIELD tecla
		NEXT FIELD tecla	
END INPUT
DROP TABLE temp_conta
	
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



FUNCTION quitar_diario_cierre_anio(anio, flag_m)
DEFINE anio		SMALLINT
DEFINE flag_m		CHAR(1)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b50		RECORD LIKE ctbt050.*

INITIALIZE r_b50.* TO NULL
DECLARE q_b50 CURSOR FOR
	SELECT * FROM ctbt050
		WHERE b50_compania = vg_codcia
		  AND b50_anio     = anio
OPEN q_b50
FETCH q_b50 INTO r_b50.*
IF r_b50.b50_compania IS NULL THEN
	CLOSE q_b50
	FREE q_b50
	RETURN
END IF
CLOSE q_b50
FREE q_b50
CALL fl_lee_comprobante_contable(r_b50.b50_compania, r_b50.b50_tipo_comp,
				 r_b50.b50_num_comp)
	RETURNING r_b12.*
IF r_b12.b12_estado = 'E' THEN
	CALL fl_mostrar_mensaje('El Diario de cierre de año ha sido Eliminado.', 'stop')
	EXIT PROGRAM
END IF
IF r_b12.b12_estado = 'M' AND flag_m = 'M' THEN
	RETURN
END IF
IF r_b12.b12_estado = 'A' AND flag_m = 'D' THEN
	RETURN
END IF
CALL fl_mayoriza_comprobante_ult(vg_codcia, r_b50.b50_tipo_comp,
					r_b50.b50_num_comp, flag_m)

END FUNCTION
