--------------------------------------------------------------------------------
-- Titulo           : rolp111.4gl - Mantenimiento sueldos empleados
-- Elaboracion      : 04-Ene-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp111 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_par		RECORD 
				n30_cod_depto	LIKE rolt030.n30_cod_depto,
				g34_nombre	LIKE gent034.g34_nombre,
				cod_trab	LIKE rolt030.n30_cod_trab,
				tit_nombres	LIKE rolt030.n30_nombres,
				sueldo_ini	DECIMAL(12,2),
				sueldo_fin	DECIMAL(12,2),
				valor_aum	DECIMAL(12,2),
				porc_aum	DECIMAL(5,2),
				valor_tope	DECIMAL(12,2)
			END RECORD
DEFINE rm_emp		ARRAY[1000] OF RECORD
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n30_sueldo_mes	LIKE rolt030.n30_sueldo_mes,
				n30_factor_hora	LIKE rolt030.n30_factor_hora,
				sueldo_mes_nue	LIKE rolt030.n30_sueldo_mes,
				factor_hora_nue	LIKE rolt030.n30_factor_hora
			END RECORD
DEFINE vm_numelm 	INTEGER
DEFINE vm_maxelm 	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp111.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parametros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parametros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp111'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE salir 		INTEGER

CALL fl_nivel_isolation()
OPEN WINDOW w_rolf111 AT 03, 02 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_rolf111 FROM '../forms/rolf111_1'
DISPLAY FORM f_rolf111
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existen configuración general para este módulo.', 'stop')
	CLOSE WINDOW w_rolf111
	EXIT PROGRAM
END IF
LET vm_maxelm = 1000
LET salir     = 0
WHILE salir = 0
	CLEAR FORM
	CALL limpia_pantalla()
	CALL mostrar_botones()
	CALL control_ingresar()
	IF int_flag THEN
		LET salir = 1
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_rolf111
EXIT PROGRAM

END FUNCTION



FUNCTION control_ingresar()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE resp 		VARCHAR(6)
DEFINE i		INTEGER
DEFINE mensaje		VARCHAR(255)

INITIALIZE rm_par.*, r_n05.* TO NULL
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe configuración para esta compañía.', 'stop')
        EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fgl_winmessage(vg_producto, 'Compañía no esta activa.', 'stop')
        EXIT PROGRAM
END IF
SELECT * INTO r_n05.*
	FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S'
CALL leer_cabecera()
IF int_flag THEN
	CLEAR FORM
	CALL limpia_pantalla()
	CALL mostrar_botones()
        RETURN
END IF
CALL carga_trabajadores()
IF int_flag THEN
	LET int_flag = 0
	CLEAR FORM
	CALL limpia_pantalla()
	CALL mostrar_botones()
        RETURN
END IF
CALL leer_detalle()
IF int_flag THEN
	LET int_flag = 0
	CLEAR FORM
	CALL limpia_pantalla()
	CALL mostrar_botones()
        RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'No' THEN
	LET int_flag = 0
	CLEAR FORM
	CALL limpia_pantalla()
	CALL mostrar_botones()
        RETURN
END IF
FOR i = 1 TO vm_numelm
	IF rm_emp[i].sueldo_mes_nue = 0 THEN
		CONTINUE FOR
	END IF
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_up CURSOR WITH HOLD FOR
		SELECT * FROM rolt030
			WHERE n30_compania = vg_codcia
			  AND n30_cod_trab = rm_emp[i].n30_cod_trab
		FOR UPDATE
	OPEN q_up
	FETCH q_up INTO r_n30.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		LET mensaje = 'El empleado ',
				rm_emp[i].n30_cod_trab USING "<<<<<&", ' ',
				rm_emp[i].n30_nombres CLIPPED,
				' esta bloqueado por otro proceso.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		WHENEVER ERROR STOP
		CLEAR FORM
		CALL limpia_pantalla()
		CALL mostrar_botones()
		RETURN
	END IF
	IF STATUS = NOTFOUND THEN
		ROLLBACK WORK
		LET mensaje = 'El empleado ',
				rm_emp[i].n30_cod_trab USING "<<<<<&", ' ',
				rm_emp[i].n30_nombres CLIPPED,
				' no esta en la base de datos. ',
				'Ocurrió un Error grave llame al ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		WHENEVER ERROR STOP
		CLEAR FORM
		CALL limpia_pantalla()
		CALL mostrar_botones()
		RETURN
	END IF
	WHENEVER ERROR STOP
	UPDATE rolt030
		SET n30_sueldo_mes  = rm_emp[i].sueldo_mes_nue,
		    n30_factor_hora = rm_emp[i].factor_hora_nue
		WHERE CURRENT OF q_up
	IF STATUS < 0 THEN
		ROLLBACK WORK
		LET mensaje = 'El empleado ',
				rm_emp[i].n30_cod_trab USING "<<<<<&", ' ',
				rm_emp[i].n30_nombres CLIPPED,
				' no se ha podido actualizar el sueldo.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		WHENEVER ERROR STOP
		CLEAR FORM
		CALL limpia_pantalla()
		CALL mostrar_botones()
		RETURN
	END IF
	COMMIT WORK
END FOR
IF r_n05.n05_compania IS NOT NULL THEN
	IF r_n05.n05_proceso[1] = 'M' OR r_n05.n05_proceso[1] = 'Q' OR
	   r_n05.n05_proceso[1] = 'S'
	THEN
		IF mensaje_continuar_nomina_activa() THEN
			FOR i = 1 TO vm_numelm
				IF rm_emp[i].sueldo_mes_nue = 0 THEN
					CONTINUE FOR
				END IF
				CALL regenerar_novedades(rm_emp[i].n30_cod_trab,
							r_n05.*)
			END FOR
		END IF
	END IF
END IF
CALL fl_mostrar_mensaje('Proceso Terminado OK.', 'info')

END FUNCTION



FUNCTION leer_cabecera()
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE resp 		VARCHAR(6)

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_par.*) THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(n30_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING r_g34.g34_cod_depto, r_g34.g34_nombre
                        IF r_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_par.n30_cod_depto = r_g34.g34_cod_depto
				LET rm_par.g34_nombre    = r_g34.g34_nombre
                                DISPLAY BY NAME rm_par.n30_cod_depto,
						rm_par.g34_nombre
                        END IF
                END IF
		IF INFIELD(cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_par.cod_trab    = r_n30.n30_cod_trab
                                LET rm_par.tit_nombres = r_n30.n30_nombres
                                DISPLAY BY NAME rm_par.cod_trab,
						rm_par.tit_nombres
                        END IF
                END IF
		LET int_flag = 0
	AFTER FIELD n30_cod_depto
                IF rm_par.n30_cod_depto IS NOT NULL THEN
                        CALL fl_lee_departamento(vg_codcia,rm_par.n30_cod_depto)
                                RETURNING r_g34.*
                        IF r_g34.g34_compania IS NULL  THEN
                                CALL fgl_winmessage(vg_producto, 'Departamento no existe.','exclamation')
                                NEXT FIELD n30_cod_depto
                        END IF
			LET rm_par.g34_nombre = r_g34.g34_nombre
		ELSE
			LET rm_par.g34_nombre = NULL
                END IF
		DISPLAY BY NAME rm_par.g34_nombre
	AFTER FIELD cod_trab
		IF rm_par.cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia, rm_par.cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD cod_trab
			END IF
			LET rm_par.tit_nombres = r_n30.n30_nombres
			IF r_n30.n30_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El Empleado no esta Activo.', 'exclamation')
				NEXT FIELD cod_trab
			END IF
		ELSE
			LET rm_par.tit_nombres = NULL
                END IF
		DISPLAY BY NAME rm_par.tit_nombres
	AFTER FIELD valor_aum
		IF rm_par.valor_aum IS NOT NULL THEN
			IF rm_par.porc_aum IS NOT NULL THEN
				LET rm_par.porc_aum = NULL
				DISPLAY BY NAME rm_par.porc_aum
	                END IF
		END IF
	AFTER FIELD porc_aum
		IF rm_par.porc_aum IS NOT NULL THEN
			IF rm_par.valor_aum IS NOT NULL THEN
				LET rm_par.valor_aum = NULL
				DISPLAY BY NAME rm_par.valor_aum
	                END IF
		END IF
	AFTER FIELD valor_tope
		IF rm_par.valor_tope IS NOT NULL THEN
			IF rm_par.porc_aum IS NOT NULL THEN
				LET rm_par.porc_aum = NULL
				DISPLAY BY NAME rm_par.porc_aum
	                END IF
		END IF
	AFTER INPUT
		IF rm_par.sueldo_ini IS NOT NULL THEN
			IF rm_par.sueldo_fin IS NOT NULL THEN
				IF rm_par.sueldo_ini > rm_par.sueldo_fin THEN
					CALL fl_mostrar_mensaje('El sueldo inicial no puede ser mayor que el sueldo final.', 'exclamation')
					NEXT FIELD sueldo_ini
	                	END IF
	                END IF
		END IF
END INPUT

END FUNCTION



FUNCTION carga_trabajadores()
DEFINE query		CHAR(1000)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_dpto	VARCHAR(100)
DEFINE expr_val		VARCHAR(200)
DEFINE expr_fac		VARCHAR(200)
DEFINE expr_sue1	VARCHAR(100)
DEFINE expr_sue2	VARCHAR(100)

INITIALIZE expr_trab, expr_dpto, expr_val, expr_fac TO NULL
IF rm_par.cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n30_cod_trab  = ', rm_par.cod_trab
END IF
IF rm_par.n30_cod_depto IS NOT NULL THEN
	LET expr_dpto = '   AND n30_cod_depto = ', rm_par.n30_cod_depto
END IF
LET expr_val = ' 0 '
LET expr_fac = ' 0 '
IF rm_par.valor_aum IS NOT NULL THEN
	LET expr_val = ' n30_sueldo_mes + ', rm_par.valor_aum
	LET expr_fac = ' (n30_sueldo_mes + ', rm_par.valor_aum, ') / (',
			rm_n00.n00_dias_mes, ' * ', rm_n00.n00_horas_dia, ') '
END IF
IF rm_par.porc_aum IS NOT NULL THEN
	LET expr_val = ' n30_sueldo_mes + (n30_sueldo_mes * ', rm_par.porc_aum,
			' / 100) '
	LET expr_fac = ' (n30_sueldo_mes + (n30_sueldo_mes * ', rm_par.porc_aum,
			' / 100)) / (', rm_n00.n00_dias_mes, ' * ',
			rm_n00.n00_horas_dia, ') '
END IF
LET expr_sue1 = NULL
IF rm_par.sueldo_ini IS NOT NULL THEN
	LET expr_sue1 = '   AND n30_sueldo_mes >= ', rm_par.sueldo_ini
END IF
LET expr_sue2 = NULL
IF rm_par.sueldo_fin IS NOT NULL THEN
	LET expr_sue2 = '   AND n30_sueldo_mes <= ', rm_par.sueldo_fin
END IF
LET query = 'SELECT n30_cod_trab, n30_nombres, n30_sueldo_mes, ',
			'n30_factor_hora, ', expr_val CLIPPED, ', ',
			expr_fac CLIPPED,
		' FROM rolt030 ',
		' WHERE n30_compania  = ', vg_codcia,
		'   AND n30_estado    = "A" ',
		expr_trab CLIPPED,
		expr_dpto CLIPPED,
		expr_sue1 CLIPPED,
		expr_sue2 CLIPPED,
		' ORDER BY n30_nombres '
PREPARE cons_emp FROM query
DECLARE q_trab CURSOR FOR cons_emp
LET vm_numelm = 1
FOREACH q_trab INTO rm_emp[vm_numelm].*
	IF rm_par.valor_tope IS NOT NULL THEN
		IF rm_emp[vm_numelm].sueldo_mes_nue > rm_par.valor_tope AND
		   rm_emp[vm_numelm].n30_sueldo_mes < rm_par.valor_tope
		THEN
			LET rm_emp[vm_numelm].sueldo_mes_nue = rm_par.valor_tope
			LET rm_emp[vm_numelm].factor_hora_nue=
				rm_par.valor_tope /
				(rm_n00.n00_dias_mes * rm_n00.n00_horas_dia)
		END IF
	END IF
	LET vm_numelm = vm_numelm + 1
	IF vm_numelm > vm_maxelm THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_numelm = vm_numelm - 1
IF vm_numelm = 0 THEN
	LET int_flag = 1
	CALL fl_mensaje_consulta_sin_registros()
END IF

END FUNCTION



FUNCTION leer_detalle()
DEFINE resp		VARCHAR(6)
DEFINE i, j, salir	INTEGER
DEFINE sueldo		LIKE rolt030.n30_sueldo_mes

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
LET salir = 0
WHILE (salir = 0)
	LET int_flag = 0
	CALL set_count(vm_numelm)
	INPUT ARRAY rm_emp WITHOUT DEFAULTS FROM rm_emp.*
		ON KEY(INTERRUPT)
        		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ON KEY(F5)
			LET i = arr_curr()
			CALL mostrar_empleado(rm_emp[i].n30_cod_trab)
			LET int_flag = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT','')
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('F5','Empleado')
			CALL calcula_totales()
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			DISPLAY i         TO num_rows
			DISPLAY vm_numelm TO max_rows
		BEFORE INSERT
			LET salir = 0
			EXIT INPUT
		BEFORE FIELD sueldo_mes_nue
			LET sueldo = rm_emp[i].sueldo_mes_nue
		AFTER FIELD sueldo_mes_nue
			IF rm_emp[i].sueldo_mes_nue IS NOT NULL THEN
				IF rm_emp[i].sueldo_mes_nue <=
					rm_emp[i].n30_sueldo_mes AND
				   rm_emp[i].sueldo_mes_nue <> 0 AND
				   (rm_par.valor_aum IS NULL OR
				    rm_par.valor_aum > 0)
				THEN
					{
					CALL fl_mostrar_mensaje('El nuevo sueldo no pude ser menor o igual al sueldo anterior.', 'exclamation')
					LET rm_emp[i].sueldo_mes_nue  = 0
					LET rm_emp[i].factor_hora_nue = 0
					DISPLAY rm_emp[i].* TO rm_emp[j].*
					NEXT FIELD sueldo_mes_nue
					}
				END IF
				LET rm_emp[i].factor_hora_nue =
					rm_emp[i].sueldo_mes_nue /
					(rm_n00.n00_dias_mes *
					rm_n00.n00_horas_dia)
				DISPLAY rm_emp[i].* TO rm_emp[j].*
			ELSE
				LET rm_emp[i].sueldo_mes_nue = sueldo
				DISPLAY rm_emp[i].* TO rm_emp[j].*
			END IF		
			CALL calcula_totales()
		AFTER INPUT 
			CALL calcula_totales()
			LET salir = 1
	END INPUT
	IF int_flag = 1 THEN
		LET salir = 1
	END IF
END WHILE

END FUNCTION



FUNCTION limpia_pantalla()
DEFINE i		INTEGER

INITIALIZE rm_par.* TO NULL
FOR i = 1 TO fgl_scr_size('ra_scr')
	INITIALIZE rm_emp[i].* TO NULL
	DISPLAY rm_emp[i].* TO ra_scr[i].*	
END FOR

END FUNCTION



FUNCTION calcula_totales()
DEFINE i		INTEGER
DEFINE total_sue_mes	DECIMAL(12,2)
DEFINE total_sue_nue	DECIMAL(12,2)

LET total_sue_mes = 0
LET total_sue_nue = 0
FOR i = 1 TO vm_numelm
	LET total_sue_mes = total_sue_mes + rm_emp[i].n30_sueldo_mes
	LET total_sue_nue = total_sue_nue + rm_emp[i].sueldo_mes_nue
END FOR 
DISPLAY BY NAME total_sue_mes, total_sue_nue

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Cod.'			TO tit_col1
DISPLAY 'E m p l e a d o'	TO tit_col2
DISPLAY 'Sueldo A.'		TO tit_col3
DISPLAY 'F.H. Ant.'		TO tit_col4
DISPLAY 'Sueldo N.'		TO tit_col5
DISPLAY 'F.H. Nue.'		TO tit_col6

END FUNCTION



FUNCTION mensaje_continuar_nomina_activa()
DEFINE resp		CHAR(6)

CALL fl_hacer_pregunta('Existe un Proceso de Pago de Nómina Activo. Desea continuar para generar novedades de este Empleado ?.', 'Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION mostrar_empleado(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE param		VARCHAR(60)

LET param = ' ', cod_trab
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp108 ', param)

END FUNCTION



FUNCTION regenerar_novedades(cod_trab, r_n05)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE param		VARCHAR(60)

LET param = ' ', r_n05.n05_proceso[1], ' ', cod_trab, ' ', r_n05.n05_proceso,
		' ', r_n05.n05_fecini_act, ' ', r_n05.n05_fecfin_act
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp200 ', param)

END FUNCTION
 


FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo, vg_separador,
		'fuentes', vg_separador, run_prog, prog, vg_base, ' ', mod, ' ',
		vg_codcia, ' ', param
RUN comando

END FUNCTION
