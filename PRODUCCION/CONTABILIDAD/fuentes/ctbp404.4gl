------------------------------------------------------------------------------
-- Titulo           : ctbp404.4gl - Plan de cuentas
-- Elaboracion      : 23-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun ctbp404 base módulo compañía 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nivel_max	SMALLINT
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_par		RECORD 
				nivel_ini	LIKE ctbt010.b10_nivel,
				nivel_fin 	LIKE ctbt010.b10_nivel,
				cuenta_ini	LIKE ctbt010.b10_cuenta,
				cuenta_fin	LIKE ctbt010.b10_cuenta,
				n_cuenta 	LIKE ctbt010.b10_descripcion,
				imprime_saldos	CHAR(1),
				moneda		LIKE gent013.g13_moneda,
				n_moneda	LIKE gent013.g13_nombre,
				anho		SMALLINT,
				mes		SMALLINT,
				n_mes		VARCHAR(11),
				tipo_cta	LIKE ctbt010.b10_tipo_cta
			END RECORD
DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN
DEFINE vm_archivo	CHAR(6)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp404.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 
		'Número de parámetros incorrecto', 
		'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso  = 'ctbp404'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_top    = 1
LET vm_left   =	0
LET vm_right  =	80
LET vm_bottom =	3
LET vm_page   = 66
INITIALIZE rm_par.* TO NULL
LET rm_par.tipo_cta       = 'B'
LET rm_par.imprime_saldos = 'N'	
SELECT MAX(b01_nivel) INTO vm_nivel_max FROM ctbt001
IF vm_nivel_max IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
		'No se ha configurado la estructura de niveles del plan de ' ||
		'cuentas.',
		'stop')
	EXIT PROGRAM
END IF
OPEN WINDOW w_mas AT 3,2 WITH 10 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, 
		BORDER, MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/ctbf404_1"
DISPLAY FORM f_rep
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE r_det		RECORD 
				cuenta		LIKE ctbt010.b10_cuenta,
				descripcion	LIKE ctbt010.b10_descripcion,
				saldo		DECIMAL(14,2)
			END RECORD
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT
DEFINE registro		CHAR(400)
DEFINE enter		SMALLINT
DEFINE fecha		DATE
DEFINE val1, val2	DECIMAL(14,2)
DEFINE fec_ini, fec_fin	DATE
DEFINE flag		CHAR(1)

LET enter = 13
INITIALIZE r_det.* TO NULL 
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	LET int_flag = 0
	CALL fl_hacer_pregunta('Desea generar también un archivo de texto ?',
				'No')
		RETURNING vm_archivo
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
	LET query = prepare_query()
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0
	START REPORT rep_cuentas TO PIPE comando
	FOREACH	q_deto INTO r_det.*
		LET r_det.saldo = 0
		IF rm_par.imprime_saldos = 'S' THEN
			LET fecha = MDY(rm_par.mes, 1, rm_par.anho)
					+ 1 UNITS MONTH - 1 UNITS DAY
			IF r_det.cuenta[1, 1] <> '3' THEN
				LET r_det.saldo =
					fl_obtiene_saldo_contable(vg_codcia,
						r_det.cuenta, rm_par.moneda,
						fecha, 'A')
			ELSE
				LET fec_ini = MDY(MONTH(fecha), 1, YEAR(fecha))
				LET fec_fin = fecha
				LET flag    = 'S'
				CALL fl_lee_cuenta(vg_codcia, r_det.cuenta)
					RETURNING r_b10.*
				IF r_b10.b10_nivel = vm_nivel_max THEN
					LET fec_ini = fecha
					LET fec_fin = TODAY
					LET flag    = 'A'
				END IF
				CALL fl_obtener_saldo_cuentas_patrimonio(vg_codcia,
						r_det.cuenta, rm_par.moneda,
						fec_ini, fec_fin, flag)
					RETURNING val1, val2
				LET r_det.saldo = val1 + val2
			END IF
		END IF
		LET data_found = 1
		IF vm_archivo = 'Yes' THEN
			LET registro = fl_justifica_titulo('D',r_det.cuenta,12),
				'|', fl_justifica_titulo('D', r_det.descripcion,
				40)
			IF rm_par.imprime_saldos = 'S' THEN
				LET registro = registro CLIPPED,
					'|', r_det.saldo USING '###,###,##&.##'
			END IF
			DISPLAY registro CLIPPED, ASCII(enter)
		END IF
		OUTPUT TO REPORT rep_cuentas(r_det.*)
	END FOREACH
	FINISH REPORT rep_cuentas
	FREE q_deto

	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF

END WHILE

END FUNCTION



FUNCTION lee_parametros()

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b01		RECORD LIKE ctbt001.*

LET INT_FLAG   = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.*) THEN
			EXIT PROGRAM
		END IF
		LET INT_FLAG = 1 
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
		IF INFIELD(cuenta_ini) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, 0) 
				RETURNING r_b10.b10_cuenta, 
					  r_b10.b10_descripcion 
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_par.cuenta_ini = r_b10.b10_cuenta
				DISPLAY BY NAME rm_par.cuenta_ini
			END IF	
		END IF
		IF INFIELD(cuenta_fin) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, 0) 
				RETURNING r_b10.b10_cuenta, 
					  r_b10.b10_descripcion 
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_par.cuenta_fin = r_b10.b10_cuenta
				DISPLAY BY NAME rm_par.cuenta_fin
			END IF	
		END IF
		IF INFIELD(nivel_ini) THEN
			CALL fl_ayuda_nivel_cuentas() 
				RETURNING r_b01.b01_nivel,
					  r_b01.b01_nombre,
					  r_b01.b01_posicion_i,
					  r_b01.b01_posicion_f
			IF r_b01.b01_nivel IS NOT NULL THEN
				LET rm_par.nivel_ini   = r_b01.b01_nivel
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(nivel_fin) THEN
			CALL fl_ayuda_nivel_cuentas() 
				RETURNING r_b01.b01_nivel,
					  r_b01.b01_nombre,
					  r_b01.b01_posicion_i,
					  r_b01.b01_posicion_f
			IF r_b01.b01_nivel IS NOT NULL THEN
				LET rm_par.nivel_fin   = r_b01.b01_nivel
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET INT_FLAG = 0
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
			LET rm_par.n_moneda = NULL
			CLEAR n_moneda
		END IF
	AFTER FIELD cuenta_ini  
		IF rm_par.cuenta_ini IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, rm_par.cuenta_ini)
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NOT NULL THEN
				IF r_b10.b10_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Cuenta está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					NEXT FIELD cuenta_ini  
				END IF
			ELSE
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Cuenta no ' ||
                               	                            'existe',        
                                       	                    'exclamation')
					NEXT FIELD cuenta_ini  
			END IF
		END IF
	AFTER FIELD cuenta_fin  
		IF rm_par.cuenta_fin IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, rm_par.cuenta_fin)
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NOT NULL THEN
				IF r_b10.b10_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Cuenta está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					NEXT FIELD cuenta_fin  
				END IF
			ELSE
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Cuenta no ' ||
                               	                            'existe',        
                                       	                    'exclamation')
					NEXT FIELD cuenta_fin  
			END IF
		END IF
	AFTER FIELD nivel_ini
		IF rm_par.nivel_ini IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_par.nivel_ini > vm_nivel_max THEN
			CALL fgl_winmessage(vg_producto,
				'Nivel no existe.',
				'exclamation')
			NEXT FIELD nivel_ini
		END IF	
	AFTER FIELD nivel_fin
		IF rm_par.nivel_fin IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_par.nivel_fin > vm_nivel_max THEN
			CALL fgl_winmessage(vg_producto,
				'Nivel no existe.',
				'exclamation')
			NEXT FIELD nivel_fin
		END IF	
	BEFORE FIELD moneda
		IF rm_par.imprime_saldos = 'N' THEN
			NEXT FIELD tipo_cta
		END IF
	BEFORE FIELD anho
		IF rm_par.imprime_saldos = 'N' THEN
			NEXT FIELD tipo_cta
		END IF
	BEFORE FIELD mes 
		IF rm_par.imprime_saldos = 'N' THEN
			IF fgl_lastkey() = fgl_keyval('up') THEN
				NEXT FIELD imprime_saldos
			ELSE 
				NEXT FIELD tipo_cta
			END IF
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
		IF rm_par.nivel_ini IS NOT NULL AND rm_par.nivel_fin IS NULL 
		THEN
			CALL fgl_winmessage(vg_producto,
				'Si ingresa nivel inicial debe ingresar ' ||
 				'un nivel final.',
				'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_par.nivel_fin IS NOT NULL AND rm_par.nivel_ini IS NULL 
		THEN
			CALL fgl_winmessage(vg_producto,
				'Si ingresa nivel final debe ingresar ' ||
 				'un nivel inicial.',
				'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_par.nivel_fin < rm_par.nivel_ini THEN
			CALL fgl_winmessage(vg_producto,
				'El nivel final no puede ser menor ' ||
 				'al nivel inicial.',
				'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_par.cuenta_ini  IS NOT NULL 
		AND rm_par.cuenta_fin IS NOT NULL
		THEN
			IF rm_par.cuenta_fin < rm_par.cuenta_ini THEN
				CALL fgl_winmessage(vg_producto,
					'La cuenta final no puede ser menor ' ||
 					'a la cuenta inicial.',
					'exclamation')
				CONTINUE INPUT
			END IF
		END IF	
		IF rm_par.imprime_saldos = 'S' THEN
			IF rm_par.moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Debe indicar el saldo de que ' ||
					'moneda desea imprimir.',
					'exclamation')
				CONTINUE INPUT
			END IF
			IF rm_par.anho   IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Debe indicar el año del que desea ' ||
					'imprimir el saldo.',
					'exclamation')
				CONTINUE INPUT
			END IF
			IF rm_par.mes    IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Debe indicar el mes del que desea ' ||
					'imprimir el saldo.',
					'exclamation')
				CONTINUE INPUT
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION prepare_query()
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE query	 	VARCHAR(1000)
DEFINE expr_tipo_cta	VARCHAR(30)
DEFINE expr_nivel	VARCHAR(30)
DEFINE expr_cuenta_ini	VARCHAR(35)
DEFINE expr_cuenta_fin	VARCHAR(35)
DEFINE expr_descripcion VARCHAR(30)

CASE rm_par.tipo_cta 
	WHEN 'B'
		LET expr_tipo_cta = ' AND b10_tipo_cta = "B" '
	WHEN 'R'
		LET expr_tipo_cta = ' AND b10_tipo_cta = "R" '
	OTHERWISE
		LET expr_tipo_cta = ' '
END CASE

LET expr_nivel = ' '
IF rm_par.nivel_ini IS NOT NULL THEN
	LET expr_nivel = ' AND b10_nivel BETWEEN ' || rm_par.nivel_ini ||
			 		   ' AND ' || rm_par.nivel_fin
END IF

LET expr_descripcion = ' '
IF rm_par.n_cuenta IS NOT NULL THEN
	LET expr_descripcion = ' AND b10_descripcion '
	LET j = length(rm_par.n_cuenta)
	FOR i = 1 TO j 
		IF rm_par.n_cuenta[i] = '*' THEN
			LET expr_descripcion =  expr_descripcion || 
					        'LIKE "' || rm_par.n_cuenta ||
						'" '
			EXIT FOR
		END IF
	END FOR 
	IF i > j THEN
		LET expr_descripcion =  expr_descripcion || 
				        '= "' || rm_par.n_cuenta || '" '
	END IF
END IF 

LET expr_cuenta_ini = ' '
IF rm_par.cuenta_ini IS NOT NULL THEN
	LET expr_cuenta_ini = ' AND b10_cuenta >= "' || rm_par.cuenta_ini || '"'
END IF

LET expr_cuenta_fin = ' '
IF rm_par.cuenta_fin IS NOT NULL THEN
	LET expr_cuenta_fin = ' AND b10_cuenta <= "' || rm_par.cuenta_fin || '"'
END IF

LET query = 'SELECT b10_cuenta, b10_descripcion ',  
	    	' FROM ctbt010 ', 
	    	' WHERE b10_compania = ', vg_codcia,
	    	'   AND b10_estado = "A" ', 
		expr_cuenta_ini  CLIPPED,
		expr_cuenta_fin  CLIPPED,
		expr_descripcion CLIPPED,
		expr_tipo_cta    CLIPPED,
		expr_nivel       CLIPPED,
	  	' ORDER BY 1'
	    	  
RETURN query

END FUNCTION



REPORT rep_cuentas(cuenta, n_cuenta, saldo)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE n_cuenta		LIKE ctbt010.b10_descripcion
DEFINE saldo		DECIMAL(14,2)
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE tit_sist		VARCHAR(40)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
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
	LET modulo  = "MÓDULO: CONTABILIDAD"
	LET long    = LENGTH(modulo)
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'PLAN DE CUENTAS', 80)
		RETURNING titulo
	CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING r_g02.*
	LET tit_sist = r_g02.g02_nombre CLIPPED, " - ", vg_base CLIPPED, " (",
			vg_servidor CLIPPED, ")"
	CALL fl_justifica_titulo('C', tit_sist, 40) RETURNING tit_sist
	--PRINT '@'
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 01,  rm_g01.g01_razonsocial CLIPPED,
	      COLUMN 21,  tit_sist CLIPPED,
	      COLUMN 70,  "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 01,  titulo CLIPPED
	PRINT COLUMN 01,  modulo CLIPPED,
	      COLUMN 74,  UPSHIFT(vg_proceso)
	SKIP 1 LINES
	IF rm_par.nivel_ini IS NOT NULL THEN
		PRINT COLUMN 20, "** RANGO NIVELES  : ", rm_par.nivel_ini, 
					      " HASTA ", rm_par.nivel_fin
	END IF
	IF rm_par.cuenta_ini IS NOT NULL THEN
		IF rm_par.cuenta_fin IS NULL THEN
			PRINT COLUMN 20, "** RANGO CUENTAS  : DESDE ", 
					 rm_par.cuenta_ini 
		ELSE
			PRINT COLUMN 20, "** RANGO CUENTAS  : DESDE ", 
					 rm_par.cuenta_ini, " HASTA ",
					 rm_par.cuenta_fin 
		END IF
	ELSE
		IF rm_par.cuenta_fin IS NULL THEN
			PRINT COLUMN 20, "** RANGO CUENTAS  : TODAS " 
		ELSE
			PRINT COLUMN 20, "** RANGO CUENTAS  : HASTA ",
					 rm_par.cuenta_fin 
		END IF
	END IF
	IF rm_par.n_cuenta IS NOT NULL THEN
		PRINT COLUMN 20, "** PATRÓN BUSQUEDA: ",
				 rm_par.n_cuenta
	END IF
	IF rm_par.tipo_cta = 'B' THEN
		PRINT COLUMN 20, "** TIPO CUENTA    : BALANCE"
	ELSE
		IF rm_par.tipo_cta = 'R' THEN
			PRINT COLUMN 20, "** TIPO CUENTA    : RESULTADO"
		END IF
	END IF
	IF rm_par.moneda IS NOT NULL THEN
		PRINT COLUMN 20, "** MONEDA         : ", rm_par.n_moneda 
	END IF
	IF rm_par.anho IS NOT NULL THEN
		PRINT COLUMN 20, "** SALDOS A ", get_month_name(rm_par.mes) CLIPPED, 
				 " del ", fl_justifica_titulo('I', rm_par.anho, 4)
	END IF
	SKIP 1 LINES
	PRINT COLUMN 01, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 61, usuario
	SKIP 1 LINES
	PRINT COLUMN 01,  '--------------------------------------------------------------------------------'
	IF rm_par.imprime_saldos = 'N' THEN
		PRINT COLUMN 01,  "CUENTA",
		      COLUMN 30,  "DESCRIPCION"
	ELSE
		PRINT COLUMN 01,  "CUENTA",
		      COLUMN 20,  "DESCRIPCION",
		      COLUMN 62,  "SALDO",
		      COLUMN 76,  "SIGNO"
	END IF
	PRINT COLUMN 01,  '--------------------------------------------------------------------------------'

ON EVERY ROW
	IF rm_par.imprime_saldos = 'N' THEN
		PRINT COLUMN 01,  retorna_cuenta_expandida(cuenta) CLIPPED,
		      COLUMN 30,  n_cuenta CLIPPED
	ELSE
		PRINT COLUMN 01,  retorna_cuenta_expandida(cuenta) 
				  CLIPPED,
	      	      COLUMN 20,  n_cuenta CLIPPED,
	              COLUMN 62,  saldo USING '###,###,##&.##';
		IF saldo >= 0 THEN
			PRINT COLUMN 77,  "DB"
		ELSE
			PRINT COLUMN 77,  "CR"
		END IF
	END IF

ON LAST ROW
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION retorna_cuenta_expandida(cuenta)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE nvl_cta		VARCHAR(25)
DEFINE i		SMALLINT
DEFINE j		SMALLINT

DEFINE r_b01		RECORD LIKE ctbt001.*

DECLARE q_nivel CURSOR FOR SELECT * FROM ctbt001 ORDER BY b01_nivel ASC
OPEN  q_nivel
FETCH q_nivel INTO r_b01.*
	LET j = r_b01.b01_posicion_i
CLOSE q_nivel
FOREACH q_nivel INTO r_b01.*
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
