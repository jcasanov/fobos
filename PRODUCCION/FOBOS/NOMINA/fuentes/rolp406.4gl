--------------------------------------------------------------------------------
-- Titulo           : rolp406.4gl - Impresión de la Carta al Banco
-- Elaboracion      : 26-Ago-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp406 base modulo compañía
--			[cod_liqrol] [fecha_ini] [fecha_fin]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g08		RECORD LIKE gent008.*
DEFINE rm_g09		RECORD LIKE gent009.*
DEFINE rm_g31		RECORD LIKE gent031.*
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE vm_cargo_dir	VARCHAR(40)
DEFINE vm_atentamente1	VARCHAR(40)
DEFINE vm_atentamente2	VARCHAR(40)
DEFINE vm_tot_neto	DECIMAL(14,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp406.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 6 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp406'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE resul	 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_ciudad(rm_loc.g02_ciudad) RETURNING rm_g31.*
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 21
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf406_1 FROM '../forms/rolf406_1'
ELSE
	OPEN FORM f_rolf406_1 FROM '../forms/rolf406_1c'
END IF
DISPLAY FORM f_rolf406_1
INITIALIZE rm_g08.*, rm_g09.*, rm_n32.* TO NULL
LET rm_n32.n32_fecha_ini = TODAY
LET rm_n32.n32_fecha_fin = TODAY
IF num_args() <> 3 THEN
	--CALL llamada_otro_prog()
	RETURN
END IF
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_reporte()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE nro_cta		LIKE gent009.g09_numero_cta

LET int_flag = 0
INPUT BY NAME rm_g09.g09_banco, rm_g09.g09_numero_cta, rm_n32.n32_cod_liqrol,
	rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin, rm_g09.g09_atencion_rol,
	vm_cargo_dir, vm_atentamente1, vm_atentamente2
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(g09_banco) THEN
			CALL fl_ayuda_bancos()
				RETURNING r_g08.g08_banco, r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_g09.g09_banco  = r_g08.g08_banco
				LET rm_g08.g08_nombre = r_g08.g08_nombre
				DISPLAY BY NAME rm_g09.g09_banco,
						r_g08.g08_nombre
			END IF
		END IF
		IF INFIELD(g09_numero_cta) THEN
			CALL fl_ayuda_cuenta_banco(vg_codcia, 'T') 
				RETURNING r_g09.g09_banco, r_g08.g08_nombre,
				          r_g09.g09_tipo_cta, 
				          r_g09.g09_numero_cta 
			IF r_g09.g09_numero_cta IS NOT NULL THEN
				LET rm_g09.g09_banco      = r_g09.g09_banco
				LET rm_g08.g08_nombre     = r_g08.g08_nombre
				LET rm_g09.g09_numero_cta = r_g09.g09_numero_cta
				CALL fl_lee_banco_compania(vg_codcia,
							rm_g09.g09_banco,
							r_g09.g09_numero_cta)
					RETURNING r_g09.*
				LET rm_g09.g09_atencion_rol =
							r_g09.g09_atencion_rol
				LET rm_g09.g09_moneda = r_g09.g09_moneda
				DISPLAY BY NAME rm_g09.g09_banco,
						r_g08.g08_nombre,
					        r_g09.g09_numero_cta,
						r_g09.g09_atencion_rol
			END IF	
		END IF
		IF INFIELD(n32_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso,
					  r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_n32.n32_cod_liqrol = r_n03.n03_proceso
				DISPLAY BY NAME rm_n32.n32_cod_liqrol,
						r_n03.n03_nombre  
				CALL mostrar_fechas()
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD n32_fecha_ini
		LET fecha_ini = rm_n32.n32_fecha_ini
	BEFORE FIELD n32_fecha_fin
		LET fecha_fin = rm_n32.n32_fecha_fin
	AFTER FIELD g09_banco
		IF rm_g09.g09_banco IS NULL THEN
			INITIALIZE rm_g09.* TO NULL
			CLEAR g08_nombre, g09_numero_cta, g09_atencion_rol
			CONTINUE INPUT
		END IF
		CALL fl_lee_banco_general(rm_g09.g09_banco) RETURNING r_g08.*
		IF r_g08.g08_banco IS NULL THEN	
			CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
			NEXT FIELD g09_banco
		END IF 
		LET rm_g08.g08_nombre = r_g08.g08_nombre
		DISPLAY BY NAME r_g08.g08_nombre
	AFTER FIELD g09_numero_cta
		IF rm_g09.g09_numero_cta IS NULL THEN
			INITIALIZE rm_g09.* TO NULL
			CLEAR g09_banco, g08_nombre, g09_atencion_rol
			CONTINUE INPUT
		END IF
		IF rm_g09.g09_banco IS NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar un banco primero.','exclamation')
			NEXT FIELD g09_banco
		END IF
		LET nro_cta = rm_g09.g09_numero_cta
		CALL fl_lee_banco_compania(vg_codcia, rm_g09.g09_banco,
						rm_g09.g09_numero_cta)
			RETURNING r_g09.*
		IF r_g09.g09_numero_cta IS NULL THEN
			CALL fl_mostrar_mensaje('No existe cuenta en este banco.','exclamation')
			LET rm_g09.g09_numero_cta = nro_cta
			NEXT FIELD g09_numero_cta
		END IF
		LET rm_g09.g09_moneda       = r_g09.g09_moneda
		LET rm_g09.g09_atencion_rol = r_g09.g09_atencion_rol
		DISPLAY BY NAME rm_g09.g09_atencion_rol
		IF r_g09.g09_estado = 'B' THEN
			CALL fl_mostrar_mensaje('La cuenta está bloqueada.','exclamation')
			NEXT FIELD g09_numero_cta
		END IF
		IF r_g09.g09_pago_roles = 'N' THEN
			CALL fl_mostrar_mensaje('La cuenta de este banco no paga nomina de empleados.','exclamation')
			NEXT FIELD g09_numero_cta
		END IF
	AFTER FIELD n32_cod_liqrol
		IF rm_n32.n32_cod_liqrol IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol)
                        	RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD n32_cod_liqrol
			END IF
			DISPLAY BY NAME r_n03.n03_nombre
			CALL mostrar_fechas()
		ELSE
			CLEAR n03_nombre
		END IF
	AFTER FIELD n32_fecha_ini
		IF rm_n32.n32_fecha_ini IS NOT NULL THEN
			{--
			IF rm_n32.n32_fecha_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual a la fecha de hoy.','exclamation')
				NEXT FIELD n32_fecha_ini
			END IF
			--}
		ELSE
			LET rm_n32.n32_fecha_ini = fecha_ini
			DISPLAY BY NAME rm_n32.n32_fecha_ini
		END IF
	AFTER FIELD n32_fecha_fin
		IF rm_n32.n32_fecha_fin IS NOT NULL THEN
			{--
			IF rm_n32.n32_fecha_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha final debe ser menor o igual a la fecha de hoy.','exclamation')
				NEXT FIELD n32_fecha_fin
			END IF
			--}
		ELSE
			LET rm_n32.n32_fecha_fin = fecha_fin
			DISPLAY BY NAME rm_n32.n32_fecha_fin
		END IF
	AFTER INPUT  
		IF rm_n32.n32_fecha_ini > rm_n32.n32_fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha n32_fecha_fin.','exclamation')
			NEXT FIELD n32_fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION mostrar_fechas()
DEFINE r_n32		RECORD LIKE rolt032.*

DECLARE q_n32 CURSOR FOR SELECT * FROM rolt032
	WHERE n32_compania   = vg_codcia
	  AND n32_cod_liqrol = rm_n32.n32_cod_liqrol
	  AND n32_estado     = "C"
	ORDER BY n32_fecing DESC
OPEN q_n32
FETCH q_n32 INTO r_n32.*
IF STATUS <> NOTFOUND THEN
	LET rm_n32.n32_fecha_ini = r_n32.n32_fecha_ini
	LET rm_n32.n32_fecha_fin = r_n32.n32_fecha_fin
	DISPLAY BY NAME rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin
END IF
CLOSE q_n32
FREE q_n32

END FUNCTION



FUNCTION control_reporte()
DEFINE comando		VARCHAR(100)
DEFINE resul		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL preparar_query() RETURNING resul
IF resul THEN
	RETURN
END IF
START REPORT reporte_carta TO PIPE comando
--START REPORT reporte_carta TO FILE "carta_bco.txt"
OUTPUT TO REPORT reporte_carta()
FINISH REPORT reporte_carta

END FUNCTION



FUNCTION preparar_query()

IF rm_n32.n32_cod_liqrol[1, 1] = 'M' OR rm_n32.n32_cod_liqrol[1, 1] = 'Q'
   OR rm_n32.n32_cod_liqrol[1, 1] = 'S'
THEN
	UNLOAD TO "carta_bco_liq.unl"
		SELECT n32_cta_trabaj, n32_tot_neto, n30_nombres
			FROM rolt032, rolt030
			WHERE n32_compania    = vg_codcia
			  AND n32_cod_liqrol  = rm_n32.n32_cod_liqrol
			  AND n32_fecha_ini   = rm_n32.n32_fecha_ini
			  AND n32_fecha_fin   = rm_n32.n32_fecha_fin
			  AND n32_estado      IN ("A", "C")
			  AND n32_bco_empresa = rm_g09.g09_banco
			  AND n32_cta_empresa = rm_g09.g09_numero_cta
			  AND n32_tot_neto    > 0
			  AND n32_compania    = n30_compania
			  AND n32_cod_trab    = n30_cod_trab
			ORDER BY n30_nombres
	--RUN 'mv carta_bco_liq.unl /acero/fobos/tmp/carta_bco_liq.unl'
	RUN 'mv carta_bco_liq.unl $HOME/tmp/carta_bco_liq.unl'
	SELECT SUM(n32_tot_neto) INTO vm_tot_neto
		FROM rolt032
		WHERE n32_compania    = vg_codcia
		  AND n32_cod_liqrol  = rm_n32.n32_cod_liqrol
		  AND n32_fecha_ini   = rm_n32.n32_fecha_ini
		  AND n32_fecha_fin   = rm_n32.n32_fecha_fin
		  AND n32_estado      IN ("A", "C")
		  AND n32_bco_empresa = rm_g09.g09_banco
		  AND n32_cta_empresa = rm_g09.g09_numero_cta
	IF vm_tot_neto IS NULL THEN
		CALL fl_mostrar_mensaje('No ha encontrado ningún valor para presentar al banco con estos parametros. Probablemente no existe o no esté cerrada la liquidación.', 'exclamation')
		RETURN 1
	END IF
	IF vm_tot_neto = 0 THEN
		CALL fl_mostrar_mensaje('No ha encontrado ningún valor para presentar al banco con este código de proceso.', 'exclamation')
		RETURN 1
	END IF
END IF
IF rm_n32.n32_cod_liqrol = 'DT' OR rm_n32.n32_cod_liqrol = 'DC' THEN
	UNLOAD TO "carta_bco_dec.unl"
		SELECT n36_cta_trabaj, n36_valor_neto, n30_nombres
			FROM rolt036, rolt030
			WHERE n36_compania    = vg_codcia
			  AND n36_proceso     = rm_n32.n32_cod_liqrol
			  AND n36_fecha_ini   = rm_n32.n32_fecha_ini
			  AND n36_fecha_fin   = rm_n32.n32_fecha_fin
			  AND n36_estado      IN ("A", "P")
			  AND n36_bco_empresa = rm_g09.g09_banco
			  AND n36_cta_empresa = rm_g09.g09_numero_cta
			  AND n36_valor_neto  > 0
			  AND n36_compania    = n30_compania
			  AND n36_cod_trab    = n30_cod_trab
			ORDER BY n30_nombres
	--RUN 'mv carta_bco_dec.unl /acero/fobos/tmp/carta_bco_dec.unl'
	RUN 'mv carta_bco_dec.unl $HOME/tmp/carta_bco_dec.unl'
	SELECT SUM(n36_valor_neto) INTO vm_tot_neto
		FROM rolt036
		WHERE n36_compania    = vg_codcia
		  AND n36_proceso     = rm_n32.n32_cod_liqrol
		  AND n36_fecha_ini   = rm_n32.n32_fecha_ini
		  AND n36_fecha_fin   = rm_n32.n32_fecha_fin
		  AND n36_estado      IN ("A", "P")
		  AND n36_bco_empresa = rm_g09.g09_banco
		  AND n36_cta_empresa = rm_g09.g09_numero_cta
	IF vm_tot_neto IS NULL THEN
		CALL fl_mostrar_mensaje('No ha encontrado ningún valor para presentar al banco para el proceso de los décimos.', 'exclamation')
		RETURN 1
	END IF
	IF vm_tot_neto = 0 THEN
		CALL fl_mostrar_mensaje('No ha encontrado ningún valor para presentar al banco con este código de proceso.', 'exclamation')
		RETURN 1
	END IF
END IF
RETURN 0

END FUNCTION



REPORT reporte_carta()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE valor1		VARCHAR(80)
DEFINE valor2		VARCHAR(80)
DEFINE tot_neto		VARCHAR(15)
DEFINE mes		VARCHAR(11)
DEFINE pal		VARCHAR(6)
DEFINE i, lim		SMALLINT

OUTPUT
	TOP MARGIN	8
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(MONTH(TODAY)), 10)
		RETURNING mes
	PRINT COLUMN 001, rm_g31.g31_nombre CLIPPED, ", ", mes CLIPPED, " ",
		DAY(TODAY) USING "&&", " ", YEAR(TODAY) USING "&&&&"
	SKIP 3 LINES
	PRINT COLUMN 001, "Senores"
	PRINT COLUMN 001, rm_g08.g08_nombre
	PRINT COLUMN 001, "Presente."
	SKIP 3 LINES
	PRINT COLUMN 001, "Att.",
	      COLUMN 008, rm_g09.g09_atencion_rol
	PRINT COLUMN 008, vm_cargo_dir
	SKIP 3 LINES
	PRINT COLUMN 001, "De mi consideracion:"
	SKIP 2 LINES

ON EVERY ROW
	CALL fl_lee_moneda(rm_g09.g09_moneda) RETURNING r_g13.*
	LET tot_neto = vm_tot_neto USING "--,---,--&.##"
	CALL valor_letras_formato(fl_retorna_letras(rm_g09.g09_moneda,
					vm_tot_neto))
		RETURNING valor1, valor2
	IF (LENGTH(valor1) > 74) OR valor2 IS NULL THEN
		LET valor1 = " (", valor1, ")."
	ELSE
		LET valor1 = " (", valor1, valor2, "). "
		LET valor2 = NULL
		--LET valor2 = valor2, "). "
	END IF
	PRINT COLUMN 001, "Favor acreditar en las cuentas de los empleados segun detalle del archivo "
	PRINT COLUMN 001, "adjunto."
	SKIP 1 LINES
	CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
	IF r_n03.n03_proceso[1, 1] = 'Q' THEN
		LET pal = "la "
	END IF
	IF r_n03.n03_proceso[1, 1] = 'D' THEN
		LET pal = "el "
	END IF
	IF r_n03.n03_proceso[1, 1] = 'U' THEN
		LET pal = "las "
	END IF
	PRINT COLUMN 001, "El valor total de acreditacion que corresponde a ",
		pal CLIPPED, " ", r_n03.n03_nombre CLIPPED, " es: "
	PRINT COLUMN 001, r_g13.g13_simbolo, " ",
		fl_justifica_titulo('I', tot_neto, 13) CLIPPED,	valor1
	PRINT COLUMN 001, valor2 CLIPPED, "De la cuenta corriente ",
		rm_g09.g09_numero_cta CLIPPED, "."
	SKIP 2 LINES
	PRINT COLUMN 001, "Por su atencion, anticipamos nuestro agradecimiento."

ON LAST ROW
	SKIP 3 LINES
	PRINT COLUMN 001, "Atentamente,"
	SKIP 4 LINES
	LET lim = LENGTH(vm_atentamente1)
	IF LENGTH(vm_atentamente2) > lim THEN
		LET lim = LENGTH(vm_atentamente2)
	END IF
	LET i = 1
	WHILE (i <= lim)
		PRINT COLUMN 001, "-";
		LET i = i + 1
	END WHILE
	PRINT 1 SPACES
	PRINT COLUMN 001, vm_atentamente1
	PRINT COLUMN 001, vm_atentamente2
	PRINT COLUMN 001, rm_cia.g01_razonsocial

END REPORT



FUNCTION valor_letras_formato(valor_letras)
DEFINE valor_letras	VARCHAR(200)
DEFINE i,l		SMALLINT
DEFINE vl1		VARCHAR(100)
DEFINE vl2		VARCHAR(100)

INITIALIZE vl1, vl2 TO NULL
LET l   = LENGTH(valor_letras)
LET vl1 = valor_letras
IF l > 29 THEN
	FOR i = l TO 1 STEP -1
		IF (valor_letras[i] = ' ') AND (i <= 29) THEN
			LET vl1 = valor_letras[1, i]
			LET vl2 = valor_letras[i + 1, l]
			EXIT FOR
		END IF
	END FOR
END IF
RETURN vl1, vl2

END FUNCTION 
