-------------------------------------------------------------------------------
-- Titulo               : rolp107.4gl -- Mantenimiento de Procesos de Roles
-- Elaboración          : 03-dic-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  rolp200 base modulo  
-- Ultima Correción     : 11-jun-2003
-- Motivo Corrección    : (RCA) Revision y Correccion Aceros
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE vm_rows		ARRAY[50] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   INTEGER        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      INTEGER        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      INTEGER        -- MAXIMO NUMERO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)
DEFINE rm_n03   	RECORD LIKE rolt003.*



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp107.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso  = 'rolp107'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 50
OPEN WINDOW w_rolp107 AT 03, 02 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
OPEN FORM f_rolp107 FROM '../forms/rolf107_1'
DISPLAY FORM f_rolp107
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'

	COMMAND KEY('I') 'Ingresar' 	'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF

        COMMAND KEY('M') 'Modificar' 	'Modificar registro corriente. '
                IF vm_num_rows > 0 THEN
                        CALL control_modificacion()
                ELSE
			CALL fl_mensaje_consultar_primero()
		END IF

	COMMAND KEY('C') 'Consultar' 	'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF

	COMMAND KEY('A') 'Avanzar' 	'Ver siguiente registro'
		IF vm_row_current < vm_num_rows THEN
			LET vm_row_current = vm_row_current + 1 
		END IF	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF

	COMMAND KEY('R') 'Retroceder'  		'Ver anterior registro. '
		IF vm_row_current > 1 THEN
			LET vm_row_current = vm_row_current - 1 
		END IF
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF

	COMMAND KEY('E') 'Bloquear/Activar' 	'Bloquear o activar registro. '
		CALL control_bloqueo_activacion()

	COMMAND KEY('S') 'Salir' 	'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(400)
DEFINE query		VARCHAR(500)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON n03_proceso,     n03_nombre,      n03_estado,
			      n03_nombre_abr,  n03_dia_ini,     n03_dia_fin, 
			      n03_mes_ini,     n03_mes_fin,     n03_provisionar,
			      n03_acep_descto, n03_benefic_liq, n03_frecuencia,
			      n03_tipo_calc,   n03_usuario,     n03_fecing
	ON KEY(F2)
		IF INFIELD(n03_proceso) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING rm_n03.n03_proceso,
					  rm_n03.n03_nombre
			IF rm_n03.n03_proceso IS NOT NULL THEN
				DISPLAY BY NAME rm_n03.n03_proceso,
						rm_n03.n03_nombre
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT

IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM rolt003 WHERE ', expr_sql CLIPPED,
		' ORDER BY 2'

PREPARE cons FROM query
DECLARE q_rolt003 CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_rolt003 INTO rm_n03.*, vm_rows[vm_num_rows]

	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF

END FOREACH

LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores()
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1

CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_n05		RECORD LIKE rolt005.*

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_n03.* TO NULL
LET vm_flag_mant           = 'I'
LET rm_n03.n03_estado      = 'A'
LET rm_n03.n03_frecuencia  = 'M'
LET rm_n03.n03_tipo_calc   = 'L'
LET rm_n03.n03_benefic_liq = 'T'
LET rm_n03.n03_provisionar = 'N'
LET rm_n03.n03_acep_descto = 'N'
LET rm_n03.n03_valor       = 0.00
LET rm_n03.n03_fecing      = CURRENT
LET rm_n03.n03_usuario     = vg_usuario
DISPLAY BY NAME rm_n03.n03_fecing, rm_n03.n03_usuario, rm_n03.n03_estado
DISPLAY 'ACTIVO' TO tit_estado
CALL control_lee_rolt003()
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
BEGIN WORK
INSERT INTO rolt003 VALUES (rm_n03.*)
INITIALIZE r_n05.* TO NULL
LET r_n05.n05_compania    = vg_codcia
LET r_n05.n05_proceso     = rm_n03.n03_proceso
LET r_n05.n05_activo      = 'N' 
LET r_n05.n05_fec_ultcie  = MDY(12,31,2000) 
LET r_n05.n05_fec_cierre  = MDY(12,31,2000)
LET r_n05.n05_usuario     = vg_usuario 
LET r_n05.n05_fecing      = CURRENT 
INSERT INTO rolt005 VALUES (r_n05.*)
COMMIT WORK
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
LET vm_row_current = vm_num_rows
CALL muestra_contadores()
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF rm_n03.n03_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt003
		WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n03.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL control_lee_rolt003()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF
UPDATE rolt003 SET * = rm_n03.* WHERE CURRENT OF q_up
IF rm_n03.n03_acep_descto = 'S' THEN
	IF rm_n03.n03_mes_ini IS NOT NULL AND rm_n03.n03_dia_ini IS NOT NULL AND
	   rm_n03.n03_mes_fin IS NOT NULL AND rm_n03.n03_dia_fin IS NOT NULL
	THEN
		IF NOT regenerar_periodo_calculo_anticipo_vigente() THEN
			ROLLBACK WORK
			CALL lee_muestra_registro(vm_rows[vm_row_current])
			RETURN
		END IF
	END IF
END IF
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION regenerar_periodo_calculo_anticipo_vigente()
DEFINE resul		SMALLINT
DEFINE query		CHAR(1500)

LET resul = 1
WHENEVER ERROR CONTINUE
LET query = 'UPDATE rolt046 ',
		' SET n46_fecha_ini = MDY(', rm_n03.n03_mes_ini, ', ',
					'CASE WHEN ',rm_n03.n03_mes_ini,' = 2 ',
					'AND MOD(YEAR(n46_fecha_ini), 4) <> 0 ',
					'THEN 28 ',
					'ELSE ', rm_n03.n03_dia_ini, ' ',
					'END, ',
					' YEAR(n46_fecha_ini)), ',
		    ' n46_fecha_fin = MDY(', rm_n03.n03_mes_fin, ', ',
					'CASE WHEN ',rm_n03.n03_mes_fin,' = 2 ',
					'AND MOD(YEAR(n46_fecha_fin), 4) <> 0 ',
					'THEN 28 ',
					'ELSE ', rm_n03.n03_dia_fin, ' ',
					'END, ',
					' YEAR(n46_fecha_fin)) ',
		' WHERE n46_compania    = ', vg_codcia,
		'   AND n46_cod_liqrol  = "', rm_n03.n03_proceso, '"',
		'   AND n46_saldo       > 0 '
PREPARE exec_up FROM query
EXECUTE exec_up
IF STATUS <> 0 THEN
	CALL fl_mostrar_mensaje('No se pudo regenerar el periodo de calculo en los anticipos vigentes para este proceso. LLAME AL ADMINISTRADOR.', 'stop')
	LET resul = 0
END IF
WHENEVER ERROR STOP
RETURN resul

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE estado		LIKE rolt003.n03_estado
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(100)

IF rm_n03.n03_proceso IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_del CURSOR FOR
	SELECT * FROM rolt003
		WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_del
FETCH q_del INTO rm_n03.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET estado = 'B'
IF rm_n03.n03_estado <> 'A' THEN
	LET estado = 'A'
END IF
UPDATE rolt003 SET n03_estado = estado WHERE CURRENT OF q_del
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
LET mensaje = 'Registro se ha '
IF rm_n03.n03_estado = 'A' THEN
	LET mensaje = mensaje CLIPPED, ' Activado. OK'
ELSE
	LET mensaje = mensaje CLIPPED, ' Bloqueado. OK'
END IF
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION control_lee_rolt003()
DEFINE resp      CHAR(6)
DEFINE r_n03     RECORD LIKE rolt003.*

OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_n03.n03_proceso,  rm_n03.n03_nombre,  rm_n03.n03_nombre_abr,  
	      rm_n03.n03_dia_ini, rm_n03.n03_dia_fin, 
	      rm_n03.n03_mes_ini,  rm_n03.n03_mes_fin, rm_n03.n03_valor, 
	      rm_n03.n03_provisionar,
	      rm_n03.n03_acep_descto, rm_n03.n03_benefic_liq, 
	      rm_n03.n03_frecuencia,  rm_n03.n03_tipo_calc
	      WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(n03_proceso, n03_nombre,  n03_nombre_abr,
 				     n03_dia_ini,     n03_dia_fin, n03_mes_ini,
				     n03_mes_fin,     n03_provisionar, 
				     n03_acep_descto, n03_benefic_liq, 
				     n03_frecuencia,  n03_tipo_calc)
                    THEN
			LET int_flag = 1
                        RETURN
                END IF       	
                LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso()
                       	RETURNING resp
                IF resp = 'Yes' THEN
			LET int_flag = 1
                        CLEAR FORM
                        RETURN
                END IF

	 BEFORE FIELD n03_proceso
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF	

	 AFTER FIELD n03_proceso
		CALL fl_lee_proceso_roles(rm_n03.n03_proceso)	
			RETURNING r_n03.*
                IF r_n03.n03_proceso IS NOT NULL THEN
		    	CALL fgl_winmessage (vg_producto, 'El Proceso ya existe en la Companía.','exclamation')
                        NEXT FIELD n03_proceso
                END IF

	 AFTER FIELD n03_dia_ini
		IF rm_n03.n03_dia_ini IS NOT NULL THEN
			IF rm_n03.n03_dia_fin IS NOT NULL THEN
{
				IF rm_n03.n03_dia_ini >= rm_n03.n03_dia_fin
				   THEN
					CALL fgl_winmessage(vg_producto,'El día inicial debe ser menor que el día final.','exclamation')
					NEXT FIELD n03_dia_ini
				END IF
}
			END IF
		END IF

	 AFTER FIELD n03_dia_fin
		IF rm_n03.n03_dia_fin IS NOT NULL THEN
			IF rm_n03.n03_dia_ini IS NOT NULL THEN
{
				IF rm_n03.n03_dia_fin <= rm_n03.n03_dia_ini
				   THEN
					CALL fgl_winmessage(vg_producto,'El día final debe ser mayor que el día inicial.','exclamation')
					NEXT FIELD n03_dia_fin
				END IF
}
			END IF
		END IF

	 AFTER FIELD n03_mes_ini
		IF rm_n03.n03_mes_ini IS NOT NULL THEN
			CALL control_display_mes(rm_n03.n03_mes_ini)
			IF rm_n03.n03_mes_fin IS NOT NULL THEN
{
				IF rm_n03.n03_mes_ini >= rm_n03.n03_mes_fin
				   THEN
					CALL fgl_winmessage(vg_producto,'El mes inicial debe ser menor que el mes final.','exclamation')
					NEXT FIELD n03_mes_ini
				END IF
}
			END IF
		END IF

	 AFTER FIELD n03_mes_fin
		IF rm_n03.n03_mes_fin IS NOT NULL THEN
			CALL control_display_mes_2(rm_n03.n03_mes_fin)
			IF rm_n03.n03_mes_ini IS NOT NULL THEN
{
				IF rm_n03.n03_mes_fin <= rm_n03.n03_mes_ini
				   THEN
					CALL fgl_winmessage(vg_producto,'El mes final debe ser mayor que el mes inicial.','exclamation')
					NEXT FIELD n03_mes_fin
				END IF
}
			END IF
		END IF

	AFTER INPUT
	      	IF rm_n03.n03_tipo_calc = 'F' THEN
			IF rm_n03.n03_valor = 0 THEN
				CALL fgl_winmessage(vg_producto,'Digite valor.','exclamation')
				NEXT FIELD n03_valor
			END IF
		END IF
		IF vm_flag_mant = 'M' THEN
			IF NOT FIELD_TOUCHED(n03_proceso, n03_nombre,  n03_nombre_abr, n03_dia_ini, n03_dia_fin, n03_valor, n03_mes_ini, n03_mes_fin, n03_provisionar, n03_acep_descto, n03_benefic_liq, n03_frecuencia,  n03_tipo_calc)
                   	   THEN
				LET int_flag = 1
                        	RETURN
                	END IF       	
                END IF       	

END INPUT
                                                                                
END FUNCTION



FUNCTION control_display_mes(mes)
DEFINE mes 	LIKE rolt003.n03_mes_ini

IF mes IS NULL THEN
	CLEAR nom_mes
END IF
CASE mes
	WHEN 1
		DISPLAY 'ENERO' TO nom_mes
	WHEN 2
		DISPLAY 'FEBRERO' TO nom_mes
	WHEN 3
		DISPLAY 'MARZO' TO nom_mes
	WHEN 4
		DISPLAY 'ABRIL' TO nom_mes
	WHEN 5
		DISPLAY 'MAYO' TO nom_mes
	WHEN 6
		DISPLAY 'JUNIO' TO nom_mes
	WHEN 7
		DISPLAY 'JULIO' TO nom_mes
	WHEN 8
		DISPLAY 'AGOSTO' TO nom_mes
	WHEN 9
		DISPLAY 'SEPTIEMBRE' TO nom_mes
	WHEN 10
		DISPLAY 'OCTUBRE' TO nom_mes
	WHEN 11
		DISPLAY 'NOVIEMBRE' TO nom_mes
	WHEN 12
		DISPLAY 'DICIEMBRE' TO nom_mes
END CASE 

END FUNCTION



FUNCTION control_display_mes_2(mes)
DEFINE mes 	LIKE rolt003.n03_mes_fin

IF mes IS NULL THEN
	CLEAR nom_mes2
END IF
CASE mes
	WHEN 1
		DISPLAY 'ENERO' TO nom_mes2 
	WHEN 2
		DISPLAY 'FEBRERO' TO nom_mes2
	WHEN 3
		DISPLAY 'MARZO' TO nom_mes2
	WHEN 4
		DISPLAY 'ABRIL' TO nom_mes2
	WHEN 5
		DISPLAY 'MAYO' TO nom_mes2
	WHEN 6
		DISPLAY 'JUNIO' TO nom_mes2
	WHEN 7
		DISPLAY 'JULIO' TO nom_mes2
	WHEN 8
		DISPLAY 'AGOSTO' TO nom_mes2
	WHEN 9
		DISPLAY 'SEPTIEMBRE' TO nom_mes2
	WHEN 10
		DISPLAY 'OCTUBRE' TO nom_mes2
	WHEN 11
		DISPLAY 'NOVIEMBRE' TO nom_mes2
	WHEN 12
		DISPLAY 'DICIEMBRE' TO nom_mes2
END CASE 

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_n03.* FROM rolt003 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_n03.n03_proceso,
		rm_n03.n03_nombre,
		rm_n03.n03_nombre_abr,
		rm_n03.n03_estado,
		rm_n03.n03_frecuencia,
		rm_n03.n03_dia_ini,
		rm_n03.n03_mes_ini,
		rm_n03.n03_dia_fin,
		rm_n03.n03_mes_fin,
		rm_n03.n03_tipo_calc,
		rm_n03.n03_benefic_liq,
		rm_n03.n03_acep_descto,
		rm_n03.n03_provisionar,
		rm_n03.n03_usuario,
		rm_n03.n03_valor,
		rm_n03.n03_fecing

IF rm_n03.n03_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado
ELSE
        DISPLAY 'BLOQUEADO' TO tit_estado
END IF
CALL control_display_mes(rm_n03.n03_mes_ini)
CALL control_display_mes_2(rm_n03.n03_mes_fin)
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 69
                                                                                
END FUNCTION
