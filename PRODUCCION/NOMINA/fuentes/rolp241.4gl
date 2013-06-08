------------------------------------------------------------------------------
-- Titulo           : rolp241.4gl - Mantenimiento de Poliza Fondo de Censatía
-- Elaboracion      : 12-Nov-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp241 base modulo compañía [num_poliza]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n81, rm_ult	RECORD LIKE rolt081.*
DEFINE rm_dettrab_inac	ARRAY[30] OF RECORD
				n80_cod_trab	LIKE rolt080.n80_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				saldo		DECIMAL(14,2)
			END RECORD
DEFINE vm_max_det1	SMALLINT
DEFINE vm_num_det1	SMALLINT
DEFINE vm_incluir_trab	CHAR(1)
DEFINE total_cap	DECIMAL(14,2)
DEFINE valor_ret	DECIMAL(14,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp241.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 THEN	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp241'
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

CALL fl_nivel_isolation()                                     
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
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
	OPEN FORM f_rolf241_1 FROM '../forms/rolf241_1'
ELSE
	OPEN FORM f_rolf241_1 FROM '../forms/rolf241_1c'
END IF
DISPLAY FORM f_rolf241_1
LET vm_max_rows	   = 1000
LET vm_max_det1	   = 30
LET vm_num_det1	   = 0
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'OPCIONES'                                                                 
	BEFORE MENU                                                             
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Eliminar'
		IF num_args() <> 3 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Eliminar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Eliminar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Eliminar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Eliminar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
       	COMMAND KEY('E') 'Eliminar' 'Eliminar registro corriente. '
		CALL control_eliminacion()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF 
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder' 
			SHOW OPTION 'Avanzar'   
			NEXT OPTION 'Avanzar'  
		ELSE 
			SHOW OPTION 'Avanzar'  
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION bloquear_poliza()

WHENEVER ERROR CONTINUE
DECLARE q_n81 CURSOR FOR
	SELECT * FROM rolt081
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_n81
FETCH q_n81 INTO rm_n81.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Este registro no existe. Ha ocurrido un error interno de la base de datos. Llame al Administrador.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP
RETURN 1

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE num_aux, cont	INTEGER
DEFINE resul		SMALLINT
DEFINE fecha		DATE

SELECT COUNT(*) INTO cont FROM rolt081
	WHERE n81_compania = vg_codcia
	  AND n81_estado   = 'A'
IF cont > 0 THEN
	CALL fl_mostrar_mensaje('Existe una Poliza Activa. No puede ingresar otra.', 'exclamation')
	RETURN
END IF
LET vm_incluir_trab = 'S'
CALL control_empleados_inactivos()
IF int_flag OR vm_incluir_trab = 'N' THEN
	IF vm_incluir_trab = 'N' THEN
		CALL fl_mostrar_mensaje('Ejecute el proceso de Retiro de Fondo de Censatía para los empleados que tengan que retirar su fondo.', 'info')
	END IF
	RETURN
END IF
DECLARE q_ult CURSOR FOR SELECT * FROM rolt081
	WHERE n81_compania = vg_codcia AND n81_estado = 'P'
	ORDER BY n81_fec_vcto DESC
OPEN q_ult 
FETCH q_ult INTO rm_ult.*
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe una Póliza procesada. Pida ayuda a Sistemas.', 'exclamation')
	RETURN
END IF

CALL fl_retorna_usuario()
CLEAR FORM
INITIALIZE rm_n81.* TO NULL
LET rm_n81.n81_compania   = vg_codcia
LET rm_n81.n81_estado     = 'A'
LET rm_n81.n81_dias_plazo = 90
LET rm_n81.n81_porc_int   = 0
LET rm_n81.n81_fec_firma  = rm_ult.n81_fec_vcto
CALL generar_fec_vcto()
LET rm_n81.n81_moneda     = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_n81.n81_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada una moneda base en el sistema.', 'stop')
	EXIT PROGRAM
END IF
CALL retorna_paridad() RETURNING rm_n81.n81_paridad, resul
SELECT SUM(n80_san_trab + n80_val_retiro), SUM(n80_san_patr), 
       SUM(n80_sac_int),  SUM(n80_sac_dscto) 
	INTO rm_n81.n81_cap_trab, rm_n81.n81_cap_patr, rm_n81.n81_cap_int,
             rm_n81.n81_cap_dscto
	FROM rolt080
	WHERE n80_compania = vg_codcia AND 
	      n80_ano      = YEAR(rm_ult.n81_fec_vcto) AND
	      n80_mes      = MONTH(rm_ult.n81_fec_vcto)
{
LET rm_n81.n81_cap_trab   = 0
LET rm_n81.n81_cap_patr   = 0
LET rm_n81.n81_cap_int    = 0
LET rm_n81.n81_cap_dscto  = 0
}
LET rm_n81.n81_cod_liqrol = 'Q2'
LET fecha                 = rm_ult.n81_fec_vcto - 1 UNITS MONTH
CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_n81.n81_cod_liqrol,
					YEAR(fecha), MONTH(fecha))
	RETURNING rm_n81.n81_fecha_ini, rm_n81.n81_fecha_fin
LET rm_n81.n81_val_int    = 0
LET rm_n81.n81_val_dscto  = 0
LET rm_n81.n81_usuario    = vg_usuario
LET rm_n81.n81_fecing     = CURRENT
LET total_cap             = 0
LET valor_ret             = 0
CALL muestra_poliza('I')
CALL leer_datos()
IF int_flag THEN
	CALL mostrar_salir()
	RETURN
END IF
BEGIN WORK
	--CALL obtener_valores_ultima_poliza()
	LET rm_n81.n81_cap_trab = rm_n81.n81_cap_trab + valor_ret
	LET rm_n81.n81_fecing = CURRENT
	INSERT INTO rolt081 VALUES (rm_n81.*)
	LET num_aux = SQLCA.SQLERRD[6] 
COMMIT WORK
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current            = vm_num_rows
LET vm_r_rows[vm_row_current] = num_aux
CALL muestrar_reg()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_consulta()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n81		RECORD LIKE rolt081.*
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(1000)
DEFINE num_reg		INTEGER

CLEAR FORM
IF num_args() <> 3 THEN
	LET expr_sql = ' n81_num_poliza = ', arg_val(4)
ELSE
	LET int_flag = 0 
	CONSTRUCT BY NAME expr_sql ON n81_estado, n81_num_poliza,n81_dias_plazo,
		n81_porc_int, n81_fec_firma, n81_fec_vcto, n81_moneda,
		n81_paridad, n81_cap_trab, n81_cap_patr, n81_cap_int,
		n81_cap_dscto, n81_referencia, n81_cod_liqrol, n81_fecha_ini,
		n81_fecha_fin, n81_fec_distri, n81_val_int, n81_val_dscto,
		n81_usuario
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(n81_num_poliza) THEN
				CALL fl_ayuda_poliza_fondo_cen(vg_codcia, 'T')
					RETURNING r_n81.n81_num_poliza
				IF r_n81.n81_num_poliza IS NOT NULL THEN
					LET rm_n81.n81_num_poliza =
							r_n81.n81_num_poliza
					DISPLAY BY NAME rm_n81.n81_num_poliza
				END IF
			END IF
			IF INFIELD(n81_moneda) THEN
				CALL fl_ayuda_monedas()
					RETURNING r_g13.g13_moneda,
						  r_g13.g13_nombre,
						  r_g13.g13_decimales
				IF r_g13.g13_moneda IS NOT NULL THEN
					LET rm_n81.n81_moneda = r_g13.g13_moneda
					DISPLAY BY NAME rm_n81.n81_moneda,
							r_g13.g13_nombre
				END IF
			END IF
			IF INFIELD(n81_cod_liqrol) THEN
				CALL fl_ayuda_procesos_roles()
					RETURNING r_n03.n03_proceso,
						  r_n03.n03_nombre
				IF r_n03.n03_proceso IS NOT NULL THEN
					LET rm_n81.n81_cod_liqrol =
							r_n03.n03_proceso
					DISPLAY BY NAME rm_n81.n81_cod_liqrol,
							r_n03.n03_nombre  
				END IF
			END IF
			LET int_flag = 0
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		AFTER FIELD n81_estado
			LET rm_n81.n81_estado = get_fldbuf(n81_estado)
			IF rm_n81.n81_estado IS NOT NULL THEN
				CALL muestra_estado()
			ELSE
				CLEAR n81_estado, tit_estado
			END IF
	END CONSTRUCT
	IF int_flag THEN
		CALL mostrar_salir()
		RETURN
	END IF
END IF
LET query = 'SELECT *, ROWID FROM rolt081 ',
		' WHERE n81_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2 ' CLIPPED
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_n81.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() <> 3 THEN
		EXIT PROGRAM
	END IF
	CLEAR FORM
	LET vm_row_current = 0
	CALL muestra_contadores()
	RETURN
END IF
LET vm_row_current = 1
CALL muestrar_reg()

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resul, i		SMALLINT
DEFINE resp		CHAR(6)

IF rm_n81.n81_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('No puede Eliminar una Poliza que no este Activa.', 'exclamation')
	RETURN
END IF
CALL fl_hacer_pregunta('Realmente desea Eliminar esta Poliza ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
BEGIN WORK
CALL bloquear_poliza() RETURNING resul
IF NOT resul THEN
	ROLLBACK WORK
	RETURN
END IF
DELETE FROM rolt081 WHERE CURRENT OF q_n81
COMMIT WORK
CALL fl_mostrar_mensaje('Poliza ha sido Eliminada Ok.', 'info')
IF vm_num_rows = 1 THEN
	LET vm_row_current = 0
	LET vm_num_rows    = 0
	CLEAR FORM
	RETURN
END IF
FOR i = vm_row_current TO vm_num_rows - 1
	LET vm_r_rows[i] = vm_r_rows[i + 1]
END FOR
LET vm_r_rows[vm_num_rows] = NULL
LET vm_row_current         = vm_row_current - 1
LET vm_num_rows            = vm_num_rows    - 1
CALL muestrar_reg()

END FUNCTION



FUNCTION control_empleados_inactivos()
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE saldo		DECIMAL(14,2)
DEFINE i, lim		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE fecha		DATE
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

DECLARE q_n30 CURSOR FOR
	SELECT * FROM rolt030
		WHERE n30_compania = vg_codcia
		  AND n30_estado   = 'I'
		ORDER BY n30_nombres
OPEN q_n30
FETCH q_n30 INTO r_n30.*
IF STATUS = NOTFOUND THEN
	CLOSE q_n30
	FREE q_n30
	RETURN
END IF
FOR i = 1 TO vm_max_det1
	INITIALIZE rm_dettrab_inac[i].* TO NULL
END FOR
LET fecha = TODAY - 1 UNITS MONTH
CALL fl_retorna_rango_fechas_proceso(vg_codcia, 'Q2', YEAR(fecha), MONTH(fecha))
	RETURNING fecha_ini, fecha_fin
LET vm_num_det1 = 1
FOREACH q_n30 INTO r_n30.*
	LET saldo = 0
	SELECT (n80_sac_trab + n80_sac_patr + n80_sac_int + n80_sac_dscto +
		n80_val_retiro) sald
	INTO saldo
	FROM rolt080
	WHERE n80_compania = r_n30.n30_compania
	  AND n80_ano      = YEAR(fecha_fin)
	  AND n80_mes      = MONTH(fecha_fin)
	  AND n80_cod_trab = r_n30.n30_cod_trab
	IF saldo = 0 THEN
		CONTINUE FOREACH
	END IF
	LET rm_dettrab_inac[vm_num_det1].n80_cod_trab = r_n30.n30_cod_trab
	LET rm_dettrab_inac[vm_num_det1].n30_nombres  = r_n30.n30_nombres
	LET rm_dettrab_inac[vm_num_det1].saldo        = saldo
	LET vm_num_det1 = vm_num_det1 + 1
	IF vm_num_det1 > vm_max_det1 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det1 = vm_num_det1 - 1
IF vm_num_det1 = 0 THEN
	RETURN
END IF
LET lin_menu = 0
LET row_ini  = 5
LET num_rows = 16
LET num_cols = 64
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol2 AT row_ini, 9 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf241_2 FROM '../forms/rolf241_2'
ELSE
	OPEN FORM f_rolf241_2 FROM '../forms/rolf241_2c'
END IF
DISPLAY FORM f_rolf241_2
--#DISPLAY 'Cod.'	TO tit_col1
--#DISPLAY 'Empleado'	TO tit_col2
--#DISPLAY 'Saldo'	TO tit_col3
LET lim = vm_num_det1
IF lim > fgl_scr_size('rm_dettrab_inac') THEN
	LET lim = fgl_scr_size('rm_dettrab_inac')
END IF
FOR i = 1 TO lim
	DISPLAY rm_dettrab_inac[i].* TO rm_dettrab_inac[i].*
END FOR
LET int_flag = 0 
INPUT BY NAME vm_incluir_trab
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END INPUT
CLOSE WINDOW w_rol2
RETURN

END FUNCTION



FUNCTION obtener_valores_ultima_poliza()

SELECT SUM(n80_sac_trab), SUM(n80_sac_patr), SUM(n80_sac_int),
	SUM(n80_sac_dscto), SUM(n80_val_retiro)
	INTO rm_n81.n81_cap_trab, rm_n81.n81_cap_patr, rm_n81.n81_cap_int,
		rm_n81.n81_cap_dscto, valor_ret
	FROM rolt080
	WHERE n80_compania = vg_codcia
	  AND n80_ano      = YEAR(rm_n81.n81_fecha_fin)
	  AND n80_mes      = MONTH(rm_n81.n81_fecha_fin)
IF rm_n81.n81_cap_trab = 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe valores de capital para la poliza. revise la tabla de acumulados.', 'stop')
	EXIT PROGRAM
END IF
LET total_cap = rm_n81.n81_cap_trab + rm_n81.n81_cap_patr + rm_n81.n81_cap_int +
		rm_n81.n81_cap_dscto + valor_ret

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n81		RECORD LIKE rolt081.*
DEFINE fec_firma	LIKE rolt081.n81_fec_firma
DEFINE fec_vcto		LIKE rolt081.n81_fec_vcto

LET int_flag = 0 
INPUT BY NAME rm_n81.n81_num_poliza, rm_n81.n81_dias_plazo, rm_n81.n81_porc_int,
	rm_n81.n81_fec_firma, rm_n81.n81_fec_vcto, rm_n81.n81_moneda,
	rm_n81.n81_referencia
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n81.n81_num_poliza, rm_n81.n81_dias_plazo,
				 rm_n81.n81_porc_int, rm_n81.n81_fec_firma,
				 rm_n81.n81_fec_vcto, rm_n81.n81_moneda,
				 rm_n81.n81_referencia)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(n81_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING r_g13.g13_moneda,
					  r_g13.g13_nombre,
					  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_n81.n81_moneda = r_g13.g13_moneda
				DISPLAY BY NAME rm_n81.n81_moneda,
						r_g13.g13_nombre
				CALL retorna_paridad()
					RETURNING rm_n81.n81_paridad, resul
				DISPLAY BY NAME rm_n81.n81_paridad
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD n81_fec_firma
		LET fec_firma = rm_n81.n81_fec_firma
	BEFORE FIELD n81_fec_vcto
		LET fec_vcto = rm_n81.n81_fec_vcto
	AFTER FIELD n81_num_poliza
		IF rm_n81.n81_num_poliza IS NOT NULL THEN
			CALL fl_lee_poliza_cesantia(vg_codcia,
							rm_n81.n81_num_poliza)
				RETURNING r_n81.*
			IF r_n81.n81_num_poliza IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Esta poliza ya existe en la compañía.', 'exclamation')
				NEXT FIELD n81_num_poliza
			END IF
		END IF
	AFTER FIELD n81_dias_plazo
		CALL generar_fec_vcto()
	AFTER FIELD n81_fec_firma
		IF rm_n81.n81_fec_firma IS NULL THEN
			LET rm_n81.n81_fec_firma = fec_firma
			DISPLAY BY NAME rm_n81.n81_fec_firma
		END IF
		IF rm_n81.n81_fec_firma >= rm_n81.n81_fec_vcto THEN
			CALL fl_mostrar_mensaje('La fecha de la firma no puede ser mayor o igual a la fecha de vencimiento.', 'exclamation')
			NEXT FIELD n81_fec_firma
		END IF
		CALL generar_fec_vcto()
	AFTER FIELD n81_fec_vcto
		IF rm_n81.n81_fec_vcto IS NULL THEN
			LET rm_n81.n81_fec_vcto = fec_vcto
			DISPLAY BY NAME rm_n81.n81_fec_vcto
		END IF
		IF rm_n81.n81_fec_vcto <= rm_n81.n81_fec_firma THEN
			CALL fl_mostrar_mensaje('La fecha de vencimiento no puede ser menor o igual a la fecha de la firma.', 'exclamation')
			NEXT FIELD n81_fec_vcto
		END IF
	AFTER FIELD n81_moneda
		IF rm_n81.n81_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_n81.n81_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto, 'Moneda no existe.', 'exclamation')
				NEXT FIELD n81_moneda
			END IF
			DISPLAY BY NAME r_g13.g13_nombre
			IF r_g13.g13_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n81_moneda
			END IF
			CALL retorna_paridad()
				RETURNING rm_n81.n81_paridad, resul
			IF resul THEN
				NEXT FIELD n81_moneda
			END IF
			DISPLAY BY NAME rm_n81.n81_paridad
                ELSE
                        CALL fl_lee_moneda(rg_gen.g00_moneda_base)
				RETURNING r_g13.*
			LET rm_n81.n81_moneda  = rg_gen.g00_moneda_base
			CALL retorna_paridad()
				RETURNING rm_n81.n81_paridad, resul
			DISPLAY BY NAME rm_n81.n81_moneda, rm_n81.n81_paridad,
					r_g13.g13_nombre
		END IF
END INPUT

END FUNCTION



FUNCTION generar_fec_vcto()

LET rm_n81.n81_fec_vcto = rm_n81.n81_fec_firma + rm_n81.n81_dias_plazo UNITS DAY
DISPLAY BY NAME rm_n81.n81_fec_vcto

END FUNCTION



FUNCTION retorna_paridad()
DEFINE r_g14		RECORD LIKE gent014.*

IF rm_n81.n81_moneda = rg_gen.g00_moneda_base THEN
	LET r_g14.g14_tasa = 1
ELSE
	CALL fl_lee_factor_moneda(rm_n81.n81_moneda, rg_gen.g00_moneda_base)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('La paridad para está moneda no existe.','exclamation')
		RETURN r_g14.g14_tasa, 1
	END IF
END IF
RETURN r_g14.g14_tasa, 0

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY BY NAME vm_row_current, vm_num_rows

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestrar_reg()

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestrar_reg()

END FUNCTION



FUNCTION mostrar_salir()

CLEAR FORM
IF vm_row_current > 0 THEN
	CALL muestrar_reg()
END IF

END FUNCTION



FUNCTION muestrar_reg()

CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_cons1 CURSOR FOR SELECT * FROM rolt081 WHERE ROWID = num_registro
OPEN q_cons1
FETCH q_cons1 INTO rm_n81.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current, 'exclamation')
	RETURN
END IF
INITIALIZE rm_ult.* TO NULL
DECLARE q_fff CURSOR FOR SELECT * FROM rolt081
	WHERE n81_compania = vg_codcia AND n81_estado = 'P'
	  AND n81_fec_vcto < rm_n81.n81_fec_vcto
	ORDER BY n81_fec_vcto DESC
OPEN q_fff 
FETCH q_fff INTO rm_ult.*
CALL muestra_poliza('C')
CLOSE q_cons1
FREE q_cons1

END FUNCTION



FUNCTION muestra_poliza(flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n03		RECORD LIKE rolt003.*

LET valor_ret = 0
IF flag_mant = 'I' THEN
	SELECT SUM(n80_val_retiro) INTO valor_ret
		FROM rolt080
		--WHERE n80_compania = vg_codcia
	  	--AND n80_ano      = YEAR(rm_n81.n81_fecha_fin)
	  	--AND n80_mes      = MONTH(rm_n81.n81_fecha_fin)
		WHERE n80_compania = vg_codcia AND 
	      	      n80_ano      = YEAR(rm_ult.n81_fec_vcto) AND
	      	      n80_mes      = MONTH(rm_ult.n81_fec_vcto)
	IF valor_ret IS NULL THEN
		LET valor_ret = 0
	END IF
END IF
LET total_cap = rm_n81.n81_cap_trab + rm_n81.n81_cap_patr + rm_n81.n81_cap_int +
		rm_n81.n81_cap_dscto + valor_ret
DISPLAY BY NAME	rm_n81.n81_num_poliza, rm_n81.n81_dias_plazo,
		rm_n81.n81_porc_int, rm_n81.n81_fec_firma, rm_n81.n81_fec_vcto,
		rm_n81.n81_moneda, rm_n81.n81_paridad, rm_n81.n81_cap_trab,
		rm_n81.n81_cap_patr, rm_n81.n81_cap_int, rm_n81.n81_cap_dscto,
		total_cap, valor_ret, rm_n81.n81_referencia,
		rm_n81.n81_cod_liqrol, rm_n81.n81_fecha_ini,
		rm_n81.n81_fecha_fin, rm_n81.n81_fec_distri, rm_n81.n81_val_int,
		rm_n81.n81_val_dscto, rm_n81.n81_usuario, rm_n81.n81_fecing
CALL fl_lee_moneda(rm_n81.n81_moneda) RETURNING r_g13.*
DISPLAY BY NAME r_g13.g13_nombre
CALL fl_lee_proceso_roles(rm_n81.n81_cod_liqrol) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre
CALL muestra_estado()

END FUNCTION



FUNCTION muestra_estado()
DEFINE estado		LIKE rolt081.n81_estado

LET estado = rm_n81.n81_estado
DISPLAY BY NAME rm_n81.n81_estado
CASE estado
	WHEN 'A'
		DISPLAY 'ACTIVA'    TO tit_estado
	WHEN 'P'
		DISPLAY 'PROCESADA' TO tit_estado
	OTHERWISE
		CLEAR n81_estado, tit_estado
END CASE

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
