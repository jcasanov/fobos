------------------------------------------------------------------------------
-- Titulo           : ctbp402.4gl - Impresion Balance General          
-- Elaboracion      : 15-feb-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun ctbp402 base módulo compañía 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g01		RECORD LIKE gent001.*

DEFINE rm_par RECORD 
	anho		SMALLINT,
	mes		SMALLINT,
	n_mes		VARCHAR(10),
	nivel    	LIKE ctbt010.b10_nivel,
	n_nivel		LIKE ctbt001.b01_nombre,
	imprime_saldos	CHAR(1),
	moneda		LIKE gent013.g13_moneda,
	n_moneda	LIKE gent013.g13_nombre
END RECORD

DEFINE vm_grupo		VARCHAR(1)
DEFINE vm_quiebre	SMALLINT
DEFINE vm_pasivo	DECIMAL(14,2)
DEFINE vm_patrimonio	DECIMAL(14,2)

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp402.error')
CALL fgl_init4js()
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
LET vg_proceso = 'ctbp402'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_nivel_isolation()

LET vm_top    = 0
LET vm_left   =	6
LET vm_right  =	120
LET vm_bottom =	4
LET vm_page   = 66

INITIALIZE rm_par.* TO NULL
LET rm_par.anho           = YEAR(TODAY)
LET rm_par.mes            = MONTH(TODAY)
LET rm_par.n_mes 	  = get_month_name(rm_par.mes) CLIPPED
LET rm_par.imprime_saldos = 'S'	
LET rm_par.moneda         = rg_gen.g00_moneda_base

CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
LET rm_par.n_moneda = r_g13.g13_nombre

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

OPEN WINDOW w_mas AT 3,2 WITH 10 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, 
		BORDER, MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/ctbf402_1"
DISPLAY FORM f_rep

CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT

DEFINE resp	CHAR(6)
DEFINE fecha DATE
DEFINE saldo DECIMAL(14,2)
DEFINE print0	INTEGER

DEFINE r_det		RECORD 
	cuenta		LIKE ctbt010.b10_cuenta,
	descripcion	LIKE ctbt010.b10_descripcion,
	nivel		LIKE ctbt010.b10_nivel
END RECORD

INITIALIZE r_det.* TO NULL 

WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF

	CALL fgl_winquestion(vg_producto, 'Desea imprimir cuentas con saldo cero? ', 
			     'No', 'Yes|No', 'question', 1) RETURNING resp
	IF resp = 'No' THEN
		LET print0 = 0
	ELSE
		LET print0 = 1
	END IF
	
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
	
	LET query = prepare_query()
	
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0
	LET vm_quiebre = 0
	INITIALIZE vm_grupo TO NULL

	START REPORT rep_cuentas TO PIPE comando
	FOREACH	q_deto INTO r_det.*
		LET data_found = 1
		IF vm_grupo IS NULL OR vm_grupo <> r_det.cuenta[1] THEN
			LET vm_quiebre = 1	
			LET vm_grupo   = r_det.cuenta[1]
		END IF
		LET fecha = MDY(rm_par.mes, 1, rm_par.anho)+ 1 UNITS MONTH - 1 UNITS DAY
		LET saldo = fl_obtiene_saldo_contable(vg_codcia, r_det.cuenta, rm_par.moneda,
					      	      fecha, 'A')
		IF print0 = 0 AND saldo = 0 THEN
			CONTINUE FOREACH
		END IF
		OUTPUT TO REPORT rep_cuentas(r_det.*, saldo, fecha)
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

DEFINE i		SMALLINT
DEFINE j		SMALLINT

DEFINE query	 	VARCHAR(1000)

LET query = 'SELECT b10_cuenta, b10_descripcion, b10_nivel ',  
	    	' FROM ctbt010 ', 
	    	' WHERE b10_compania = ', vg_codcia,
		'   AND b10_tipo_cta = "B" ',
		'   AND b10_nivel <= ', rm_par.nivel,
	  	' ORDER BY 1'
	    	  
RETURN query

END FUNCTION



REPORT rep_cuentas(cuenta, n_cuenta, nivel, saldo, fecha)

DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE n_cuenta		LIKE ctbt010.b10_descripcion
DEFINE nivel		LIKE ctbt010.b10_nivel

DEFINE saldo		DECIMAL(14,2)

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i, long		SMALLINT
DEFINE fecha		DATE

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page
FORMAT
PAGE HEADER
	LET modulo  = "Módulo: Contabilidad"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'BALANCE GENERAL', 30)
		RETURNING titulo
	
	PRINT '@'
	PRINT COLUMN 1, rm_g01.g01_razonsocial,
	      COLUMN 110, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 45, titulo CLIPPED,
	      COLUMN 110, UPSHIFT(vg_proceso)
      
	SKIP 1 LINES
	PRINT COLUMN 20, "** Saldos a ", 
			 fl_justifica_titulo('I', rm_par.n_mes, 10) CLIPPED, 
			 " del ", fl_justifica_titulo('I', rm_par.anho, 4)
	PRINT COLUMN 20, "** Nivel  : ", rm_par.nivel
	IF rm_par.moneda IS NOT NULL THEN
		PRINT COLUMN 20, "** Moneda         : ", rm_par.n_moneda 
	END IF
	
	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 101 , usuario
	SKIP 1 LINES

	IF rm_par.imprime_saldos = 'N' THEN
		PRINT COLUMN 1,  "Cuenta",
		      COLUMN 30, "Descripción"
	ELSE
		PRINT COLUMN 1,  "Cuenta",
		      COLUMN 30, "Descripción",
		      COLUMN 92, fl_justifica_titulo('D', "Saldo", 17),
		      COLUMN 113, "Signo"
	END IF

	IF rm_par.imprime_saldos = 'N' THEN
		PRINT COLUMN 1,  '------------------------------',
		      COLUMN 30, '-------------------------------------------',
				 '---------------------'
	ELSE
		PRINT COLUMN 1,  '------------------------------',
		      COLUMN 30, '-------------------------------------------',
				 '---------------------',
		      COLUMN 92, '--------------------',
		      COLUMN 110, '-----'
	END IF

ON EVERY ROW
--	LET fecha = MDY(rm_par.mes, 1, rm_par.anho)+ 1 UNITS MONTH - 1 UNITS DAY

	FOR i = 1 TO (nivel - 1)
		LET n_cuenta = '   ' || n_cuenta
	END FOR

--	LET saldo = fl_obtiene_saldo_contable(vg_codcia, cuenta, rm_par.moneda,
--					      fecha, 'A')

	IF vm_quiebre = 1 THEN
		CASE vm_grupo           
			WHEN 2       
				LET vm_pasivo = saldo
				SKIP 1 LINES
			WHEN 3 
				LET vm_patrimonio = saldo
				SKIP 1 LINES
		END CASE
		LET vm_quiebre = 0
	END IF
	
	IF rm_par.imprime_saldos = 'N' THEN
		PRINT COLUMN 1, retorna_cuenta_expandida(cuenta) CLIPPED,
	      	      COLUMN 30, n_cuenta CLIPPED
	ELSE
		IF saldo >= 0 THEN
			PRINT COLUMN 1, retorna_cuenta_expandida(cuenta) CLIPPED,
	      	      	      COLUMN 30, n_cuenta CLIPPED,
	              	      COLUMN 92, saldo USING '###,###,###,##&.##',
	              	      COLUMN 115, "Db"
		ELSE
			PRINT COLUMN 1, retorna_cuenta_expandida(cuenta) CLIPPED,
		              COLUMN 30, n_cuenta CLIPPED,
		              COLUMN 92, saldo USING '###,###,###,##&.##',
		              COLUMN 115, "Cr"
		END IF
	END IF

ON LAST ROW
	IF rm_par.imprime_saldos = 'S' THEN
		SKIP 1 LINES
		PRINT COLUMN 30, 'TOTAL PASIVO + PATRIMONIO',
		      COLUMN 92, vm_pasivo + vm_patrimonio USING '###,###,###,##&.##'
	END IF

END REPORT



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
