------------------------------------------------------------------------------
-- Titulo           : ctbp401.4gl - Impresión Balance de Comprobación
-- Elaboracion      : 03-jul-2002
-- Autor            : YEC
-- Formato Ejecucion: fglrun ctbp401 base módulo compañía 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nivel_max	SMALLINT
DEFINE vm_mes_ant	SMALLINT
DEFINE vm_ano_ant	SMALLINT

DEFINE rm_par RECORD 
	moneda		LIKE gent013.g13_moneda,
	n_moneda	LIKE gent013.g13_nombre,
	cuenta_ini	LIKE ctbt010.b10_cuenta,
	n_cuenta_ini	LIKE ctbt010.b10_descripcion,
	cuenta_fin	LIKE ctbt010.b10_cuenta,
	n_cuenta_fin	LIKE ctbt010.b10_descripcion,
	nivel_ini	LIKE ctbt010.b10_nivel,
	n_nivel_ini	LIKE ctbt001.b01_nombre,
	nivel_fin 	LIKE ctbt010.b10_nivel,
	n_nivel_fin	LIKE ctbt001.b01_nombre,
	ano		SMALLINT,
	mes_ini		SMALLINT,
	n_mes_ini	VARCHAR(11),
	mes_fin		SMALLINT,
	n_mes_fin	VARCHAR(11)
END RECORD

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
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
LET vg_proceso  = 'ctbp401'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r_b01		RECORD LIKE ctbt001.*

CALL fl_nivel_isolation()

LET vm_top    = 0
LET vm_left   =	0
LET vm_right  =	120
LET vm_bottom =	4
LET vm_page   = 66

OPEN WINDOW w_mas AT 3,2 WITH 20 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, 
		BORDER, MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/ctbf401_1"
DISPLAY FORM f_rep
INITIALIZE rm_par.* TO NULL
SELECT * INTO r_b01.* FROM ctbt001
	WHERE b01_nivel = (SELECT MAX(b01_nivel) FROM ctbt001)
LET vm_nivel_max = r_b01.b01_nivel
IF vm_nivel_max IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
		'No se ha configurado la estructura de niveles del plan de ' ||
		'cuentas.',
		'stop')
	EXIT PROGRAM
END IF
LET rm_par.nivel_ini   = r_b01.b01_nivel
LET rm_par.n_nivel_ini = r_b01.b01_nombre
LET rm_par.nivel_fin   = r_b01.b01_nivel
LET rm_par.n_nivel_fin = r_b01.b01_nombre
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_reporte()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b01		RECORD LIKE ctbt001.*

LET INT_FLAG   = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
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
				LET rm_par.cuenta_ini   = r_b10.b10_cuenta
				LET rm_par.n_cuenta_ini = r_b10.b10_descripcion
				DISPLAY BY NAME rm_par.*
			END IF	
		END IF
		IF INFIELD(cuenta_fin) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, 0) 
				RETURNING r_b10.b10_cuenta, 
					  r_b10.b10_descripcion 
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_par.cuenta_fin   = r_b10.b10_cuenta
				LET rm_par.n_cuenta_fin = r_b10.b10_descripcion
				DISPLAY BY NAME rm_par.*
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
				LET rm_par.n_nivel_ini = r_b01.b01_nombre
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
				LET rm_par.n_nivel_fin = r_b01.b01_nombre
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
			IF r_b10.b10_cuenta IS NULL THEN
				CALL FGL_WINMESSAGE(vg_producto, 
                            	 	            'Cuenta no ' ||
                                                    'existe',        
                                                    'exclamation')
				NEXT FIELD cuenta_ini  
			END IF
			LET rm_par.n_cuenta_ini = r_b10.b10_descripcion
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.n_cuenta_ini = NULL
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER FIELD cuenta_fin  
		IF rm_par.cuenta_fin IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, rm_par.cuenta_fin)
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL FGL_WINMESSAGE(vg_producto, 
                       		 	            'Cuenta no ' ||
                       	                            'existe',        
                               	                    'exclamation')
				NEXT FIELD cuenta_fin  
			END IF
			LET rm_par.n_cuenta_fin = r_b10.b10_descripcion
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.n_cuenta_fin = NULL
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER FIELD nivel_ini
		IF rm_par.nivel_ini IS NOT NULL THEN
			CALL fl_lee_nivel_cuenta(rm_par.nivel_ini)
				RETURNING r_b01.*
			IF r_b01.b01_nivel IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Nivel no existe.',
					'exclamation')
				NEXT FIELD nivel_ini
			END IF
			LET rm_par.n_nivel_ini = r_b01.b01_nombre
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.nivel_ini = vm_nivel_max
			CALL fl_lee_nivel_cuenta(rm_par.nivel_ini)
				RETURNING r_b01.*
			LET rm_par.n_nivel_ini = r_b01.b01_nombre
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER FIELD nivel_fin
		IF rm_par.nivel_fin IS NOT NULL THEN
			CALL fl_lee_nivel_cuenta(rm_par.nivel_fin)
				RETURNING r_b01.*
			IF r_b01.b01_nivel IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Nivel no existe.',
					'exclamation')
				NEXT FIELD nivel_fin
			END IF
			LET rm_par.n_nivel_fin = r_b01.b01_nombre
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.nivel_fin = vm_nivel_max
			CALL fl_lee_nivel_cuenta(rm_par.nivel_fin)
				RETURNING r_b01.*
			LET rm_par.n_nivel_fin = r_b01.b01_nombre
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER FIELD mes_ini
		IF rm_par.mes_ini IS NOT NULL THEN
			CALL fl_retorna_nombre_mes(rm_par.mes_ini)
				RETURNING rm_par.n_mes_ini
			LET rm_par.n_mes_ini = fl_justifica_titulo('I', 
					       rm_par.n_mes_ini, 10)
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.n_mes_ini = NULL
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER FIELD mes_fin
		IF rm_par.mes_fin IS NOT NULL THEN
			CALL fl_retorna_nombre_mes(rm_par.mes_fin)
				RETURNING rm_par.n_mes_fin
			LET rm_par.n_mes_fin = fl_justifica_titulo('I', 
					       rm_par.n_mes_fin, 10)
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.n_mes_fin = NULL
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER INPUT		 
		IF rm_par.nivel_ini > rm_par.nivel_fin THEN
			CALL fgl_winmessage(vg_producto,
				'Nivel inicial debe ser ' ||
 				'menor o igual al final.',
				'exclamation')
			NEXT FIELD nivel_ini
		END IF
		IF rm_par.mes_ini > rm_par.mes_fin THEN
			CALL fgl_winmessage(vg_producto,
				'Mes inicial debe ser ' ||
 				'menor o igual al final.',
				'exclamation')
			NEXT FIELD mes_ini
		END IF
		IF rm_par.cuenta_fin < rm_par.cuenta_ini THEN
			CALL fgl_winmessage(vg_producto,
				'La cuenta inicial debe ser menor ' ||
 				'o igual a la cuenta final.',
				'exclamation')
			NEXT FIELD cuenta_ini
		END IF	
END INPUT

END FUNCTION



FUNCTION control_reporte()
DEFINE comando		VARCHAR(100)
DEFINE expr_cta		VARCHAR(80)
DEFINE query		VARCHAR(450)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE descripcion	LIKE ctbt010.b10_descripcion
DEFINE fecha		DATE
DEFINE i		SMALLINT
DEFINE valor		DECIMAL(16,2)
DEFINE saldo_ant	DECIMAL(16,2)
DEFINE saldo_fin	DECIMAL(16,2)
DEFINE mov_neto		DECIMAL(16,2)
DEFINE mov_neto_db	DECIMAL(16,2)
DEFINE mov_neto_cr	DECIMAL(16,2)

LET expr_cta = ' 1 = 1 '
IF rm_par.cuenta_ini IS NOT NULL THEN
	LET expr_cta = 'b10_cuenta >= "', rm_par.cuenta_ini CLIPPED, '"'
END IF
IF rm_par.cuenta_fin IS NOT NULL THEN
	LET expr_cta = expr_cta CLIPPED, ' AND ',
	               'b10_cuenta <= "', rm_par.cuenta_fin CLIPPED, '"'
END IF
LET query = 'SELECT b10_cuenta, b10_descripcion FROM ctbt010 ',
		' WHERE b10_compania = ', vg_codcia, 
		' AND ', expr_cta CLIPPED,
		' AND b10_nivel BETWEEN ', rm_par.nivel_ini,
		' AND ', rm_par.nivel_fin,
		' ORDER BY 1'
PREPARE magu FROM query
DECLARE q_magu CURSOR FOR magu
OPEN q_magu
FETCH q_magu
IF status = NOTFOUND THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE q_magu
	RETURN
END IF
CLOSE q_magu
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
LET vm_mes_ant = rm_par.mes_ini - 1
LET vm_ano_ant = rm_par.ano
IF rm_par.mes_ini = 1 THEN
	LET vm_mes_ant = 12
	LET vm_ano_ant = rm_par.ano - 1
END IF
START REPORT rep_bal_comprobacion TO PIPE comando
FOREACH q_magu INTO cuenta, descripcion
	LET fecha = MDY(vm_mes_ant, 1, vm_ano_ant) + 1 UNITS MONTH - 1 UNITS DAY
	CALL fl_obtiene_saldo_contable(vg_codcia, cuenta, rm_par.moneda, 
		fecha, 'S')
		RETURNING saldo_ant
	LET mov_neto = 0
	FOR i = rm_par.mes_ini TO rm_par.mes_fin
		LET fecha = MDY(i, 1, rm_par.ano) + 1 UNITS MONTH 
			    - 1 UNITS DAY
		CALL fl_obtiene_saldo_contable(vg_codcia, cuenta, rm_par.moneda,
			fecha, 'M')
			RETURNING valor
		LET mov_neto = mov_neto + valor
	END FOR
	LET mov_neto_db = mov_neto
	LET mov_neto_cr = 0
	IF mov_neto < 0 THEN
		LET mov_neto_db = 0
		LET mov_neto_cr = mov_neto
	END IF
	LET saldo_fin = saldo_ant + mov_neto
	OUTPUT TO REPORT rep_bal_comprobacion(cuenta, descripcion, saldo_ant, 
			mov_neto_db, mov_neto_cr, saldo_fin)
END FOREACH
FINISH REPORT rep_bal_comprobacion

END FUNCTION



REPORT rep_bal_comprobacion(cuenta, descripcion, saldo_ant, mov_neto_db, 
			mov_neto_cr, saldo_fin)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE descripcion	VARCHAR(34)
DEFINE saldo_ant	DECIMAL(16,2)
DEFINE saldo_fin	DECIMAL(16,2)
DEFINE mov_neto_db	DECIMAL(16,2)
DEFINE mov_neto_cr	DECIMAL(16,2)
DEFINE tit_sdo_ant	CHAR(20)
DEFINE tit_sdo_act	CHAR(20)
DEFINE usuario		VARCHAR(20)
DEFINE modulo		VARCHAR(20)
DEFINE titulo		VARCHAR(30)
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
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 20) RETURNING usuario
	CALL fl_justifica_titulo('C', 'BALANCE DE COMPROBACION', 30)
		RETURNING titulo
	PRINT COLUMN 001, rg_cia.g01_razonsocial,
	      COLUMN 122, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 051, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	IF rm_par.cuenta_ini IS NULL AND rm_par.cuenta_fin IS NULL THEN
		PRINT COLUMN 40, "** Rango Cuentas  : Todas " 
	ELSE
		PRINT COLUMN 40, "** Rango Cuentas  : ", 
				 rm_par.cuenta_ini,  ' a ', rm_par.cuenta_fin 
	END IF
	PRINT COLUMN 40, "** Rango Niveles  : ", rm_par.nivel_ini USING '#', 
					      " a ", rm_par.nivel_fin USING '#'
	PRINT COLUMN 40, "** Moneda         : ", rm_par.moneda, ' ',
						 rm_par.n_moneda
	PRINT COLUMN 40, "** Ano            : ", rm_par.ano USING '####'
	PRINT COLUMN 40, "** Meses          : ", rm_par.n_mes_ini, " a ", 
					         rm_par.n_mes_fin
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 113, usuario
	LET fecha = MDY(vm_mes_ant, 1, vm_ano_ant) + 1 UNITS MONTH 
		    - 1 UNITS DAY
	LET tit_sdo_ant = fecha USING 'dd-mm-yyyy'
	LET tit_sdo_ant = fl_justifica_titulo('D', tit_sdo_ant, 20)
	LET fecha = MDY(rm_par.mes_fin, 1, rm_par.ano) + 1 UNITS MONTH 
		    - 1 UNITS DAY
	LET tit_sdo_act = fecha USING 'dd-mm-yyyy'
	LET tit_sdo_act = fl_justifica_titulo('D', tit_sdo_act, 20)
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 050, '            SALDO AL',
	      COLUMN 071, '         DEBITO NETO',
	      COLUMN 092, '        CREDITO NETO',
	      COLUMN 113, '            SALDO AL'
	PRINT COLUMN 001, 'CUENTA',
	      COLUMN 014, 'DESCRIPCION',
	      COLUMN 050, tit_sdo_ant,
	      COLUMN 071, '             PERIODO',
	      COLUMN 092, '             PERIODO',
	      COLUMN 113, tit_sdo_act
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'
ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, cuenta,
	      COLUMN 014, descripcion,
	      COLUMN 050, saldo_ant USING '((((,(((,(((,((&.##)',
	      COLUMN 071, mov_neto_db USING '((((,(((,(((,((&.##)',
	      COLUMN 092, mov_neto_cr USING '((((,(((,(((,((&.##)',
	      COLUMN 113, saldo_fin USING '((((,(((,(((,((&.##)'
ON LAST ROW
	PRINT COLUMN 071, '--------------------',
	      COLUMN 092, '--------------------'
	PRINT COLUMN 072, SUM(mov_neto_db) USING '((((,(((,(((,((&.##)',
	      COLUMN 092, SUM(mov_neto_db) USING '((((,(((,(((,((&.##)'

END REPORT
	



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
