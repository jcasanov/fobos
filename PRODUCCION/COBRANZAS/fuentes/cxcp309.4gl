------------------------------------------------------------------------------
-- Titulo           : cxcp309.4gl - Análisis Cartera Por Cobrar vs Por Pagar
-- Elaboracion      : 23-May-2002
-- Autor            : YEC
-- Formato Ejecucion: fglrun cxcp309.4gl base_datos modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion:
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_color ARRAY[10] OF VARCHAR(10)
DEFINE vm_divisor	SMALLINT
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_cartera ARRAY[3] OF RECORD 
	vencido		DECIMAL(14,0),
	id_obj_venc	SMALLINT,
	xvencer		DECIMAL(14,0),
	id_obj_xvenc	SMALLINT,
	total		DECIMAL(14,0)
	END RECORD
DEFINE rm_docfav ARRAY[3] OF RECORD 
	valor		DECIMAL(14,0),
	id_objeto	SMALLINT
	END RECORD

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cxcp309'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL drawinit()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE first_time	SMALLINT

OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_cons FROM '../forms/cxcf309_1'
DISPLAY FORM f_cons
LET first_time = 1
LET fecha_ini  = vg_fecha 
LET fecha_fin  = vg_fecha + 15 
LET moneda     = rg_gen.g00_moneda_base
DISPLAY BY NAME fecha_ini, fecha_fin, moneda
CALL fl_lee_moneda(moneda) RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO tit_mon
WHILE TRUE
	IF NOT first_time THEN
		CALL lee_rango_fechas()
		IF int_flag THEN
			RETURN
		END IF
	END IF	
	LET first_time = 0
	CALL genera_resumen_x_cobrar()
	CALL genera_resumen_x_pagar()
	CALL muestra_grafico_barras()
END WHILE

END FUNCTION



FUNCTION lee_rango_fechas()
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_mon		LIKE gent013.g13_nombre
DEFINE i		SMALLINT

LET int_flag = 0
INPUT BY NAME moneda, fecha_ini, fecha_fin WITHOUT DEFAULTS
	ON KEY(F2)
		IF INFIELD(moneda) THEN
                       	CALL fl_ayuda_monedas() RETURNING mon_aux, tit_mon, i
                       	IF mon_aux IS NOT NULL THEN
				LET moneda = mon_aux
                               	DISPLAY BY NAME moneda
                               	DISPLAY BY NAME tit_mon
                       	END IF
               	END IF
               	LET int_flag = 0
	AFTER FIELD moneda
		IF moneda IS NOT NULL THEN
			CALL fl_lee_moneda(moneda) RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Moneda no existe', 'exclamation')
				NEXT FIELD moneda
			END IF
			DISPLAY rm_g13.g13_nombre TO tit_mon
		ELSE
			CLEAR tit_mon
		END IF
	AFTER INPUT
		IF fecha_fin < fecha_ini THEN
			CALL fgl_winmessage(vg_producto, 'Fecha final incorrecta', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
END INPUT

END FUNCTION



FUNCTION genera_resumen_x_cobrar()
DEFINE vencido, xvencer	DECIMAL(14,2)
DEFINE val_favor	DECIMAL(14,2)
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE i		SMALLINT

FOR i = 1 TO 3
	LET rm_cartera[i].vencido = 0
	LET rm_cartera[i].xvencer = 0
	LET rm_cartera[i].total   = 0
	IF i <= 2 THEN
		LET rm_docfav[i].valor = 0
	END IF
END FOR
DECLARE cu_dcxc CURSOR FOR SELECT * FROM cxct020
	WHERE z20_compania    = vg_codcia AND 
	      z20_localidad   = vg_codloc AND 
	      z20_saldo_cap + z20_saldo_int > 0 AND 
	      z20_moneda = moneda
LET vencido = 0
LET xvencer = 0
FOREACH cu_dcxc INTO r_z20.*
	LET r_z20.z20_saldo_cap = r_z20.z20_saldo_cap + r_z20.z20_saldo_int
	IF r_z20.z20_fecha_vcto < fecha_ini THEN
		LET vencido = vencido + r_z20.z20_saldo_cap
	ELSE
		IF r_z20.z20_fecha_vcto >= fecha_ini AND 
			r_z20.z20_fecha_vcto < fecha_fin THEN
			LET xvencer = xvencer + r_z20.z20_saldo_cap
		END IF
	END IF
END FOREACH
SELECT SUM(z21_saldo) INTO val_favor FROM cxct021
	WHERE z21_compania    = vg_codcia AND 
	      z21_localidad   = vg_codloc AND 
	      z21_saldo > 0 AND
	      z21_fecha_emi <= fecha_fin
IF val_favor IS NULL THEN
	LET val_favor = 0
END IF
LET rm_cartera[1].vencido = vencido
LET rm_cartera[1].xvencer = xvencer
LET rm_cartera[1].total   = rm_cartera[1].vencido + rm_cartera[1].xvencer
LET rm_docfav[1].valor	  = val_favor

END FUNCTION



FUNCTION genera_resumen_x_pagar()
DEFINE vencido, xvencer	DECIMAL(14,2)
DEFINE val_favor	DECIMAL(14,2)
DEFINE r_p20		RECORD LIKE cxpt020.*

DECLARE cu_dcxp CURSOR FOR SELECT * FROM cxpt020
	WHERE p20_compania    = vg_codcia AND 
	      p20_localidad   = vg_codloc AND 
	      p20_saldo_cap + p20_saldo_int > 0 AND
	      p20_moneda = moneda
LET vencido = 0
LET xvencer = 0
FOREACH cu_dcxp INTO r_p20.*
	LET r_p20.p20_saldo_cap = r_p20.p20_saldo_cap + r_p20.p20_saldo_int
	IF r_p20.p20_fecha_vcto < fecha_ini THEN
		LET vencido = vencido + r_p20.p20_saldo_cap
	ELSE
		IF r_p20.p20_fecha_vcto >= fecha_ini AND 
			r_p20.p20_fecha_vcto < fecha_fin THEN
			LET xvencer = xvencer + r_p20.p20_saldo_cap
		END IF
	END IF
END FOREACH
SELECT SUM(p21_saldo) INTO val_favor FROM cxpt021
	WHERE p21_compania    = vg_codcia AND 
	      p21_localidad   = vg_codloc AND 
	      p21_saldo > 0 AND
	      p21_fecha_emi <= fecha_fin
IF val_favor IS NULL THEN
	LET val_favor = 0
END IF
LET rm_cartera[2].vencido = vencido
LET rm_cartera[2].xvencer = xvencer
LET rm_cartera[2].total   = rm_cartera[2].vencido + rm_cartera[2].xvencer
LET rm_docfav[2].valor	  = val_favor
LET rm_cartera[3].vencido = rm_cartera[1].vencido - rm_cartera[2].vencido
LET rm_cartera[3].xvencer = rm_cartera[1].xvencer - rm_cartera[2].xvencer
LET rm_cartera[3].total   = rm_cartera[1].total   - rm_cartera[2].total  

END FUNCTION



FUNCTION muestra_grafico_barras()
DEFINE inicio_x		SMALLINT
DEFINE inicio_y		SMALLINT
DEFINE ini_x		SMALLINT
DEFINE ini_y		SMALLINT
DEFINE fin_y		SMALLINT
DEFINE maximo_x		SMALLINT
DEFINE maximo_y		SMALLINT
DEFINE factor_y		DECIMAL(16,6)
DEFINE elementos_y	SMALLINT
DEFINE intervalo_y	DECIMAL(12,0)
DEFINE valor_aux	DECIMAL(12,0)
DEFINE marca_y		DECIMAL(12,0)
DEFINE rango_valor	DECIMAL(12,0)
DEFINE valor_c		CHAR(10)
DEFINE ancho_barra	SMALLINT
DEFINE inicio2_x	SMALLINT
DEFINE max_valor	DECIMAL(14,2)
DEFINE codigo		SMALLINT
DEFINE descri		VARCHAR(35)
DEFINE valor		DECIMAL(14,2)
DEFINE key_n		SMALLINT
DEFINE key_c		CHAR(3)
DEFINE key_f30		SMALLINT
DEFINE cant_val		CHAR(1)
DEFINE query		VARCHAR(200)
DEFINE i, j, indice	SMALLINT
DEFINE tecla		CHAR(1)
DEFINE titulo, tit_pos	CHAR(75)
DEFINE label          	CHAR(10)
DEFINE tit_val		CHAR(16)
DEFINE campos		CHAR(45)
DEFINE campo		CHAR(13)
DEFINE ind_venc		CHAR(1)
DEFINE flag		CHAR(1)
DEFINE loc		SMALLINT
DEFINE comando		VARCHAR(100)

CALL carga_colores()
LET inicio_x   = 150
LET inicio_y   = 110
LET maximo_x   = 500
LET maximo_y   = 670
LET ancho_barra = 70
LET elementos_y = 10

LET ini_x      = inicio_x
LET ini_y      = inicio_y
LET max_valor = rm_cartera[1].total
IF rm_cartera[2].total > max_valor THEN
	LET max_valor = rm_cartera[2].total
END IF
IF rm_docfav[1].valor > max_valor THEN
	LET max_valor = rm_docfav[1].valor
END IF
IF rm_docfav[2].valor > max_valor THEN
	LET max_valor = rm_docfav[2].valor
END IF
CALL drawclear()
CALL drawselect('c001')
CALL drawanchor('w')
IF max_valor > 999999 THEN
	LET i = drawtext(950, 20, 'Valores expresados en miles')
	LET max_valor = max_valor / 1000
	FOR i = 1 TO 2
		LET rm_cartera[i].vencido = rm_cartera[i].vencido / 1000
		LET rm_cartera[i].xvencer = rm_cartera[i].xvencer / 1000
		LET rm_cartera[i].total   = rm_cartera[i].vencido +  
					    rm_cartera[i].xvencer
		LET rm_docfav[i].valor    = rm_docfav[i].valor / 1000
	END FOR
	LET rm_cartera[3].vencido = rm_cartera[1].vencido -
				    rm_cartera[2].vencido
	LET rm_cartera[3].xvencer = rm_cartera[1].xvencer -
				    rm_cartera[2].xvencer
	LET rm_cartera[3].total   = rm_cartera[1].total -
				    rm_cartera[2].total
END IF
CALL DrawFillColor('green')
LET i = drawrectangle(230, 750, 25, 40)
LET i = drawtext(240, 800, 'POR VENCER')
CALL DrawFillColor('red')
LET i = drawrectangle(180, 750, 25, 40)
LET i = drawtext(190, 800, 'VENCIDO')
CALL DrawFillColor('blue')
LET i = drawrectangle(130, 750, 25, 40)
LET i = drawtext(140, 800, 'ANTICIPOS')

CALL DrawFillColor('black')
LET i = drawline(inicio_y, inicio_x - 50, 0, maximo_x)
LET i = drawline(inicio_y, inicio_x - 50, maximo_y + inicio_y, 0)
LET rango_valor = max_valor / elementos_y
LET intervalo_y = maximo_y / elementos_y
LET valor_aux   = rango_valor
LET marca_y     = inicio_y + intervalo_y
FOR j = 1 TO elementos_y
	IF j = elementos_y THEN	
		LET valor_aux = max_valor
	END IF
	LET valor_c   = valor_aux USING '##,###,##&'
	LET i = drawline(marca_y, inicio_x - 57, 0, 20)
	LET i = drawtext(marca_y, inicio_x - 186, valor_c)
	LET valor_aux = valor_aux + rango_valor
	LET marca_y   = marca_y   + intervalo_y	
END FOR
CALL drawanchor('w')
LET i = drawtext(inicio_y - 50, inicio_x, 'CUENTAS X COBRAR')
--
LET factor_y = maximo_y / max_valor 
--LET i = drawtext(960,10,titulo CLIPPED)

LET fin_y = factor_y * rm_cartera[1].vencido
CALL DrawFillColor('red')
LET rm_cartera[1].id_obj_venc = 
	drawrectangle(ini_y, ini_x, fin_y, ancho_barra)
CALL DrawFillColor('green')
LET ini_y = inicio_y + fin_y
LET fin_y = factor_y * rm_cartera[1].xvencer
LET rm_cartera[1].id_obj_xvenc =
	drawrectangle(ini_y, ini_x, fin_y, ancho_barra)
LET ini_x = ini_x + ancho_barra + 10
CALL DrawFillColor('blue')
LET ini_y = inicio_y
LET fin_y = factor_y * rm_docfav[1].valor
LET rm_docfav[1].id_objeto = 
	drawrectangle(ini_y, ini_x, fin_y, ancho_barra)

LET ini_x = ini_x + ancho_barra + 100
LET i = drawtext(inicio_y - 50, ini_x, 'CUENTAS X PAGAR')
LET fin_y = factor_y * rm_cartera[2].vencido
CALL DrawFillColor('red')
LET rm_cartera[2].id_obj_venc = 
	drawrectangle(ini_y, ini_x, fin_y, ancho_barra)
CALL DrawFillColor('green')
LET ini_y = inicio_y + fin_y
LET fin_y = factor_y * rm_cartera[2].xvencer
LET rm_cartera[2].id_obj_xvenc =
	drawrectangle(ini_y, ini_x, fin_y, ancho_barra)
LET ini_x = ini_x + ancho_barra + 10
CALL DrawFillColor('blue')
LET ini_y = inicio_y
LET fin_y = factor_y * rm_docfav[2].valor
LET rm_docfav[2].id_objeto = 
	drawrectangle(ini_y, ini_x, fin_y, ancho_barra)

CALL DrawFillColor('white')
LET i = drawrectangle(700, 480, 280, 500)
LET titulo = '            VENCIDA  VENCER    TOTAL'
LET i = drawtext(900, 490, titulo)
LET titulo = 'POR COBRAR: ', rm_cartera[1].vencido USING '###,##&', ' ',
			     rm_cartera[1].xvencer USING '###,##&', '  ',
			     rm_cartera[1].total   USING '###,##&'
LET i = drawtext(850, 490, titulo)
LET titulo = 'POR PAGAR : ', rm_cartera[2].vencido USING '###,##&', ' ',
			     rm_cartera[2].xvencer USING '###,##&', '  ',
			     rm_cartera[2].total   USING '###,##&'
LET i = drawtext(800, 490, titulo)
CALL DrawFillColor('black')
LET i = drawline(780, 650, 0, 300)
LET titulo = 'DIFERENCIA: ', rm_cartera[3].vencido USING '###,##&', ' ',
			     rm_cartera[3].xvencer USING '###,##&', '  ',
			     rm_cartera[3].total   USING '###,##&'
LET i = drawtext(750, 490, titulo)

LET key_n = i + 30
			LET key_c = 'F', key_n
CALL drawbuttonleft(rm_cartera[1].id_obj_venc,  'F31')
CALL drawbuttonleft(rm_cartera[1].id_obj_xvenc, 'F32')
CALL drawbuttonleft(rm_cartera[2].id_obj_venc,  'F33')
CALL drawbuttonleft(rm_cartera[2].id_obj_xvenc, 'F34')
CALL drawbuttonleft(rm_docfav[1].id_objeto, 'F35')
CALL drawbuttonleft(rm_docfav[2].id_objeto, 'F36')
LET key_f30 = FGL_KEYVAL("F30")
INPUT BY NAME tecla
	BEFORE INPUT
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F31","")
		--#CALL dialog.keysetlabel("F32","")
		--#CALL dialog.keysetlabel("F33","")
		--#CALL dialog.keysetlabel("F34","")
		--#CALL dialog.keysetlabel("F35","")
		--#CALL dialog.keysetlabel("F36","")
	ON KEY(F31,F32,F33,F34,F35,F36)
		LET i = FGL_LASTKEY() - key_f30
		CASE 
			WHEN i = 1 OR i = 3
				LET ind_venc = 'V'
			WHEN i = 2 OR i = 4
				LET ind_venc = 'P'
		END CASE
		IF i = 1 OR i = 2 THEN
			LET comando = 'fglrun cxcp307 ', vg_base, ' ', 
			       vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
			       moneda, ' 0 X ',
			       ind_venc, ' S'
		END IF
		IF i = 3 OR i = 4 THEN
			LET comando = 'cd ..', vg_separador, '..', 
				vg_separador, 'TESORERIA', vg_separador, 
				'fuentes; ',
				'fglrun cxpp302 ', vg_base, ' ', 
				' TE ', vg_codcia, ' ', vg_codloc, ' ',
				moneda, ' 0 X ', 
			       ind_venc, ' S'
		END IF
		IF i = 5 THEN
			LET comando = 'cd ..', vg_separador, '..', 
				vg_separador, 'COBRANZAS', vg_separador, 
				'fuentes; ',
				'fglrun cxcp300 ', vg_base, ' ', 
				' CO ', vg_codcia, ' ', vg_codloc, ' ',
				moneda, ' ', MDY(01,01,2000), ' ', 
				MDY(01,01,2200)
		END IF
		IF i = 6 THEN
			LET comando = 'cd ..', vg_separador, '..', 
				vg_separador, 'TESORERIA', vg_separador, 
				'fuentes; ',
				'fglrun cxpp305 ', vg_base, ' ', 
				' TE ', vg_codcia, ' ', vg_codloc, ' ',
				moneda, ' ', MDY(01,01,2000), ' ', 
				MDY(01,01,2200)
		END IF
		RUN comando
END INPUT
	
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
