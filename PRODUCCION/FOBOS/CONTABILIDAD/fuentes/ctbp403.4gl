------------------------------------------------------------------------------
-- Titulo           : ctbp403.4gl - Impresion Estado de Perdidas y Ganancias
-- Elaboracion      : 18-feb-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun ctbp403 base módulo compañía 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_par		RECORD 
				anho		SMALLINT,
				mes		SMALLINT,
				n_mes		VARCHAR(10),
				nivel    	LIKE ctbt010.b10_nivel,
				n_nivel		LIKE ctbt001.b01_nombre,
				imprime_saldos	CHAR(1),
				moneda		LIKE gent013.g13_moneda,
				n_moneda	LIKE gent013.g13_nombre,
				diario_cie	CHAR(1)
			END RECORD
DEFINE vm_quiebre	SMALLINT
DEFINE vm_saldo 	DECIMAL(14,2)
DEFINE vm_grupo		VARCHAR(1)
DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp403.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 11 THEN	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ctbp403'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_nivel_isolation()
LET vm_top    = 1
LET vm_left   =	0
LET vm_right  =	132
LET vm_bottom =	4
LET vm_page   = 66
INITIALIZE rm_par.* TO NULL
IF num_args() = 11 THEN
	CALL llamada_otro_prog()
	EXIT PROGRAM
END IF
LET rm_par.anho           = YEAR(TODAY)
LET rm_par.mes            = MONTH(TODAY)
LET rm_par.n_mes 	  = get_month_name(rm_par.mes) CLIPPED
LET rm_par.imprime_saldos = 'S'	
LET rm_par.moneda         = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
LET rm_par.n_moneda       = r_g13.g13_nombre
LET rm_par.diario_cie     = 'N'

SELECT b01_nivel, b01_nombre INTO rm_par.nivel, rm_par.n_nivel
	FROM ctbt001
	WHERE b01_nivel = (SELECT MAX(b01_nivel) FROM ctbt001)
IF rm_par.nivel IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
		'No se ha configurado la estructura de niveles del plan de ' ||
		'cuentas.',
		'stop')
	EXIT PROGRAM
END IF

OPEN WINDOW w_mas AT 3, 2 WITH 13 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, 
		BORDER, MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/ctbf403_1"
DISPLAY FORM f_rep

CALL control_reporte()

END FUNCTION



FUNCTION llamada_otro_prog()

LET rm_par.anho           = arg_val(4)
LET rm_par.mes            = arg_val(5)
LET rm_par.n_mes 	  = arg_val(6)
LET rm_par.nivel 	  = arg_val(7)
LET rm_par.imprime_saldos = arg_val(8)
LET rm_par.moneda         = arg_val(9)
LET rm_par.n_moneda       = arg_val(10)
LET rm_par.diario_cie     = arg_val(11)
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE r_det		RECORD 
				cuenta		LIKE ctbt010.b10_cuenta,
				descripcion	LIKE ctbt010.b10_descripcion,
				nivel		LIKE ctbt010.b10_nivel
			END RECORD
DEFINE r_aux		RECORD 
				cuenta		LIKE ctbt010.b10_cuenta,
				n_cuenta	LIKE ctbt010.b10_descripcion,
				nivel		LIKE ctbt010.b10_nivel
			END RECORD
DEFINE estado		LIKE ctbt010.b10_estado
DEFINE query		VARCHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE cuantos, i	INTEGER
DEFINE data_found	SMALLINT
DEFINE resp		CHAR(6)
DEFINE registro		CHAR(400)
DEFINE enter		SMALLINT
DEFINE fecha		DATE
DEFINE saldo_mes	DECIMAL(14,2)
DEFINE saldo		DECIMAL(14,2)

LET enter = 13
INITIALIZE r_det.* TO NULL 
WHILE TRUE
	IF num_args() = 3 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	CALL fl_hacer_pregunta('Desea generar también un archivo de texto ?',
				'No')
		RETURNING resp
	LET int_flag = 0
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		IF num_args() <> 3 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
	LET query = prepare_query()
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0
	LET vm_quiebre = 0
	LET vm_saldo   = 0
	INITIALIZE vm_grupo TO NULL
	IF rm_par.diario_cie = 'N' AND num_args() = 3 THEN
		CALL quitar_diario_cierre_anio(rm_par.anho, 'D')
	END IF
	START REPORT rep_cuentas TO PIPE comando
	FOREACH	q_deto INTO r_det.*, estado
		IF estado = 'B' THEN
			SELECT COUNT(*) INTO cuantos
				FROM ctbt013
				WHERE b13_compania = vg_codcia
				  AND b13_cuenta   = r_det.cuenta
			IF cuantos = 0 THEN
				CONTINUE FOREACH
			END IF
		END IF
		LET data_found = 1
		IF vm_grupo IS NULL OR vm_grupo <> r_det.cuenta[1] THEN
			LET vm_quiebre = 1	
		END IF
		IF resp = 'Yes' THEN
			LET r_aux.* = r_det.*
			LET fecha = MDY(rm_par.mes, 1, rm_par.anho)
					+ 1 UNITS MONTH - 1 UNITS DAY
			FOR i = 1 TO (r_aux.nivel - 1)
				LET r_aux.n_cuenta = '   ', r_aux.n_cuenta
			END FOR
			LET saldo     = fl_obtiene_saldo_contable(vg_codcia,
						r_aux.cuenta, rm_par.moneda,
						fecha, 'A')
			LET saldo_mes = fl_obtiene_saldo_contable(vg_codcia,
						r_aux.cuenta, rm_par.moneda,
						fecha, 'M')
			LET registro = retorna_cuenta_expandida(
					r_aux.cuenta) CLIPPED, '|',
					r_aux.n_cuenta CLIPPED
			IF rm_par.imprime_saldos = 'S' THEN
				LET registro = registro CLIPPED, '|',
				saldo_mes USING '---,---,---,--&.##', '|',
				saldo USING '---,---,---,--&.##'
			END IF
			IF vg_gui = 1 THEN
				--#DISPLAY registro CLIPPED, ASCII(enter)
			ELSE
				DISPLAY registro CLIPPED
			END IF
		END IF
		OUTPUT TO REPORT rep_cuentas(r_det.*)
	END FOREACH
	FINISH REPORT rep_cuentas
	FREE q_deto
	IF rm_par.diario_cie = 'N' AND num_args() = 3 THEN
		CALL quitar_diario_cierre_anio(rm_par.anho, 'M')
	END IF
	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
	IF resp = 'Yes' THEN
		RUN 'mv ctbp403.txt $HOME/tmp'
		CALL fl_mostrar_mensaje('Se generó el Archivo ctbp403.txt', 'info')
	END IF
	IF num_args() <> 3 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b01		RECORD LIKE ctbt001.*

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.*) THEN
			EXIT PROGRAM
		END IF
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda, 
					  		  r_g13.g13_nombre,
					  		  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_par.moneda   = r_g13.g13_moneda
				LET rm_par.n_moneda = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(nivel) THEN
			CALL fl_ayuda_nivel_cuentas() 
				RETURNING r_b01.b01_nivel,
					  r_b01.b01_nombre,
					  r_b01.b01_posicion_i,
					  r_b01.b01_posicion_f
			IF r_b01.b01_nivel IS NOT NULL THEN
				LET rm_par.nivel   = r_b01.b01_nivel
				LET rm_par.n_nivel = r_b01.b01_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Moneda no existe.', 
					'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.n_moneda = r_g13.g13_nombre
			DISPLAY BY NAME rm_par.n_moneda
		ELSE
			INITIALIZE rm_par.n_moneda TO NULL
			CLEAR n_moneda
		END IF
	AFTER FIELD nivel
		IF rm_par.nivel IS NULL THEN
			INITIALIZE rm_par.n_nivel TO NULL
			CLEAR n_nivel
			CONTINUE INPUT
		END IF
		CALL fl_lee_nivel_cuenta(rm_par.nivel) RETURNING r_b01.*
		IF r_b01.b01_nivel IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Nivel no existe.',
				'exclamation')
			NEXT FIELD nivel
		END IF	
		LET rm_par.n_nivel = r_b01.b01_nombre
		DISPLAY BY NAME rm_par.n_nivel
	BEFORE FIELD moneda
		IF rm_par.imprime_saldos = 'N' THEN
			NEXT FIELD anho    
		END IF
	AFTER FIELD imprime_saldos
		IF rm_par.imprime_saldos = 'N' THEN
			INITIALIZE rm_par.moneda, rm_par.n_moneda TO NULL
			CLEAR moneda, n_moneda
		END IF      
	AFTER FIELD mes
		IF rm_par.mes IS NULL THEN
			INITIALIZE rm_par.n_mes TO NULL
			CLEAR n_mes
			CONTINUE INPUT
		END IF
		LET rm_par.n_mes = get_month_name(rm_par.mes) CLIPPED  
		DISPLAY BY NAME rm_par.n_mes
	AFTER INPUT		 
		IF rm_par.imprime_saldos = 'S' THEN
			IF rm_par.moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Debe indicar el saldo de que ' ||
					'moneda desea imprimir.',
					'exclamation')
				CONTINUE INPUT
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION prepare_query()
DEFINE i, j		SMALLINT
DEFINE query	 	VARCHAR(1000)

LET query = 'SELECT b10_cuenta, b10_descripcion, b10_nivel, b10_estado ',
	    	' FROM ctbt010 ', 
	    	' WHERE b10_compania  = ', vg_codcia,
		'   AND b10_tipo_cta  = "R" ',
		'   AND b10_nivel    <= ', rm_par.nivel,
	  	' ORDER BY 1'
	    	  
RETURN query

END FUNCTION



REPORT rep_cuentas(cuenta, n_cuenta, nivel)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE n_cuenta		VARCHAR(60)
DEFINE nivel		LIKE ctbt010.b10_nivel

DEFINE r_g02		RECORD LIKE gent002.*
DEFINE valor		DECIMAL(14,2)
DEFINE saldo		DECIMAL(14,2)
DEFINE saldo_mes	DECIMAL(14,2)

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE tit_sist		VARCHAR(40)
DEFINE modulo		VARCHAR(40)
DEFINE i, long		SMALLINT
DEFINE fecha		DATE
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo      = "Módulo: Contabilidad"
	LET long        = LENGTH(modulo)
	LET usuario     = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'ESTADO DE PERDIDAS Y GANANCIAS', 30)
		RETURNING titulo
	CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING r_g02.*
	LET tit_sist = r_g02.g02_nombre CLIPPED, " - ", vg_base CLIPPED, " (",
			vg_servidor CLIPPED, ")"
	CALL fl_justifica_titulo('C', tit_sist, 40) RETURNING tit_sist
	
	--PRINT '@'
	--SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
	      COLUMN 047, tit_sist CLIPPED,
	      COLUMN 121, "Pagina: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 052, titulo CLIPPED,
	      COLUMN 125, UPSHIFT(vg_proceso)
      
	SKIP 1 LINES
	PRINT COLUMN 040, "** Saldos a ", 
			 fl_justifica_titulo('I', rm_par.n_mes, 10) CLIPPED, 
			 " del ", fl_justifica_titulo('I', rm_par.anho, 4)
	PRINT COLUMN 040, "** Nivel  : ", rm_par.nivel USING "<<<&"
	IF rm_par.moneda IS NOT NULL THEN
		PRINT COLUMN 040, "** Moneda : ", rm_par.n_moneda 
	END IF
	
	SKIP 1 LINES
	PRINT COLUMN 001, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 113 , usuario
	SKIP 1 LINES

	IF rm_par.imprime_saldos = 'N' THEN
		PRINT COLUMN 001, "Cuenta",
		      COLUMN 030, "Descripción"
	ELSE
		PRINT COLUMN 001, "Cuenta",
		      COLUMN 030, "Descripción",
		      COLUMN 090, fl_justifica_titulo('D', "Mov. Del Mes", 18),
		      COLUMN 110, fl_justifica_titulo('D', "Saldo Al Mes", 18)
	END IF

	IF rm_par.imprime_saldos = 'N' THEN
		PRINT COLUMN 001, '------------------------------',
		      COLUMN 030, '-------------------------------------------',
				  '---------------------'
	ELSE
		PRINT COLUMN 001, '------------------------------',
		      COLUMN 030, '-------------------------------------------',
				  '---------------------',
		      COLUMN 090, '--------------------',
		      COLUMN 110, '-----------------'
	END IF

ON EVERY ROW

	LET fecha = MDY(rm_par.mes, 1, rm_par.anho)+ 1 UNITS MONTH - 1 UNITS DAY
	FOR i = 1 TO (nivel - 1)
		LET n_cuenta = '   ', n_cuenta
	END FOR

	LET saldo     = fl_obtiene_saldo_contable(vg_codcia, cuenta,
					rm_par.moneda, fecha, 'A')

	LET saldo_mes = fl_obtiene_saldo_contable(vg_codcia, cuenta,
					rm_par.moneda, fecha, 'M')

	IF vm_quiebre = 1 THEN
		IF vm_grupo IS NOT NULL THEN
			SKIP 1 LINES
		END IF
		LET vm_grupo   = cuenta[1]
		LET vm_quiebre = 0
	END IF

	IF nivel = 1 THEN
		LET vm_saldo = vm_saldo + saldo
	END IF
	
	IF rm_par.imprime_saldos = 'N' THEN
		PRINT COLUMN 001, retorna_cuenta_expandida(cuenta) CLIPPED,
	      	      COLUMN 030, n_cuenta CLIPPED
	ELSE
		PRINT COLUMN 001, retorna_cuenta_expandida(cuenta) CLIPPED,
	      	      COLUMN 030, n_cuenta CLIPPED,
	              COLUMN 090, saldo_mes USING '---,---,---,--&.##',
	              COLUMN 110, saldo     USING '---,---,---,--&.##'
	END IF

ON LAST ROW
	IF rm_par.imprime_saldos = 'S' THEN
		SKIP 1 LINES
		PRINT COLUMN 030, 'UTILIDAD/PERDIDA DEL PERIODO',
		      COLUMN 110, vm_saldo USING '---,---,---,--&.##'
	END IF
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



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



FUNCTION retorna_cuenta_expandida(cuenta)

DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE nvl_cta		VARCHAR(25)
DEFINE i		SMALLINT
DEFINE j		SMALLINT

DEFINE r_b01		RECORD LIKE ctbt001.*

INITIALIZE j TO NULL

DECLARE q_nivel CURSOR FOR SELECT * FROM ctbt001 ORDER BY b01_nivel ASC
FOREACH q_nivel INTO r_b01.*
	IF j IS NULL THEN
		LET j = r_b01.b01_posicion_i
	END IF
	FOR i = r_b01.b01_posicion_i TO r_b01.b01_posicion_f
		IF cuenta[i] = ' ' THEN
			EXIT FOREACH
		END IF
		LET nvl_cta[j] = cuenta[i]
		LET j = j + 1
	END FOR
	LET nvl_cta[j] = '.'
	LET j = j + 1
END FOREACH 
FREE q_nivel

LET j = j - 1 
IF nvl_cta[j] = '.' THEN
	LET nvl_cta[j] = ' '
END IF

RETURN nvl_cta 

END FUNCTION



FUNCTION get_month_name(mes)

DEFINE mes   		SMALLINT
DEFINE n_mes   		VARCHAR(15)

LET n_mes = fl_retorna_nombre_mes(mes)
LET n_mes = fl_justifica_titulo('I', n_mes, 15)

RETURN UPSHIFT(n_mes)

END FUNCTION
