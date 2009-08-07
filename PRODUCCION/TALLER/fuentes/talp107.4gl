-------------------------------------------------------------------------------
-- Titulo               : talp107.4gl -- Mantenimiento Tareas
-- Elaboración          : 10-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun talp107 base TA 1 
-- Ultima Correción     : 21-ene-2002
-- Motivo Corrección    : Tempario por modelos. Se cambiaron references.
--			  Antes era contra talt001 ahora es contra talt004. 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_tar   RECORD LIKE talt007.*
DEFINE rm_tar2  RECORD LIKE talt007.*
DEFINE rm_conf  RECORD LIKE gent000.*
DEFINE rm_cmon  RECORD LIKE gent014.*
DEFINE rm_mar   RECORD LIKE talt004.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp107.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'talp107'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_tar AT 3,2 WITH 19 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_tar FROM '../forms/talf107_1'
DISPLAY FORM f_tar
INITIALIZE rm_tar.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
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
        COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
                IF vm_num_rows > 0 THEN
                        CALL control_modificacion()
                ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
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
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_row_current < vm_num_rows THEN
			LET vm_row_current = vm_row_current + 1 
		END IF	
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		IF vm_row_current > 1 THEN
			LET vm_row_current = vm_row_current - 1 
		END IF
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
        COMMAND KEY('E') 'Bloquear/Activar' 'Bloquear o activar registro. '
                CALL control_bloqueo_activacion()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
INITIALIZE rm_tar.* TO NULL

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON t07_modelo, t07_codtarea, t07_nombre,
		 t07_pto_default, t07_val_defa_mb, t07_val_defa_ma, t07_tipo, 
		 t07_usuario, t07_fecing
	ON KEY(F2)
		IF INFIELD(t07_codtarea) THEN
		     CALL fl_ayuda_tempario(vg_codcia, rm_tar.t07_modelo)
				RETURNING rm_tar.t07_codtarea, rm_tar.t07_nombre
		     IF rm_tar.t07_codtarea IS NOT NULL THEN
			DISPLAY BY NAME rm_tar.t07_codtarea, rm_tar.t07_nombre
		     END IF
		END IF
		IF INFIELD(t07_modelo) THEN
		     CALL fl_ayuda_tipos_vehiculos(vg_codcia)
				RETURNING rm_mar.t04_modelo, rm_mar.t04_linea
		     IF rm_mar.t04_modelo IS NOT NULL THEN
			LET rm_tar.t07_modelo = rm_mar.t04_modelo
			DISPLAY BY NAME rm_tar.t07_modelo
		     END IF
		END IF
                LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM talt007 WHERE ', expr_sql CLIPPED,
		' ORDER BY 1, 2, 3'
PREPARE cons FROM query
DECLARE q_tar CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_tar INTO rm_tar.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_ingreso()

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_tar.* TO NULL
LET vm_flag_mant           = 'I'
LET rm_tar.t07_compania    = vg_codcia
LET rm_tar.t07_fecing      = CURRENT
LET rm_tar.t07_usuario     = vg_usuario
LET rm_tar.t07_tipo        = 'P'
LET rm_tar.t07_estado      = 'A'
LET rm_tar.t07_pto_default = 0
LET rm_tar.t07_val_defa_mb = 0
LET rm_tar.t07_val_defa_ma = 0
DISPLAY BY NAME rm_tar.t07_estado, rm_tar.t07_fecing, rm_tar.t07_usuario
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO talt007 VALUES (rm_tar.*)
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()

LET vm_flag_mant      = 'M'
IF rm_tar.t07_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM talt007 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_tar.*
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
LET rm_tar2.t07_nombre = rm_tar.t07_nombre
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE talt007 SET * = rm_tar.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp     CHAR(6)
DEFINE i        SMALLINT
DEFINE mensaje  VARCHAR(20)
DEFINE estado   CHAR(1)
                                                                                
LET int_flag = 0

IF rm_tar.t07_codtarea IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
        RETURN
END IF

LET mensaje = 'Seguro de bloquear'
IF rm_tar.t07_estado <> 'A' THEN
        LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
        RETURNING resp
IF resp = 'Yes' THEN
WHENEVER ERROR CONTINUE
        BEGIN WORK
        DECLARE q_del CURSOR FOR SELECT * FROM talt007
                WHERE ROWID = vm_r_rows[vm_row_current]
                FOR UPDATE
        OPEN q_del
        FETCH q_del INTO rm_tar.*
        IF status < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
                WHENEVER ERROR STOP
                RETURN
        END IF
        LET estado = 'B'
        IF rm_tar.t07_estado <> 'A' THEN
                LET estado = 'A'
        END IF
        UPDATE talt007 SET t07_estado = estado WHERE CURRENT OF q_del
        COMMIT WORK
        LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
        CLEAR FORM
        CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CLOSE q_del
                                                                                
END FUNCTION



FUNCTION lee_datos()
DEFINE           resp      CHAR(6)
DEFINE           codigo    LIKE talt007.t07_modelo  
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_tar.t07_modelo, rm_tar.t07_codtarea, rm_tar.t07_nombre,
	      rm_tar.t07_pto_default, rm_tar.t07_val_defa_mb,
	      rm_tar.t07_val_defa_ma, rm_tar.t07_tipo
              WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF field_touched(rm_tar.t07_modelo, rm_tar.t07_nombre,
			rm_tar.t07_codtarea, rm_tar.t07_val_defa_mb,
			rm_tar.t07_val_defa_ma)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                             LET int_flag = 1
			    IF vm_flag_mant = 'I' THEN
                                	CLEAR FORM
			    END IF
                            RETURN
                        END IF
                ELSE
			IF vm_flag_mant = 'I' THEN
                	        CLEAR FORM
			END IF
                        RETURN
                END IF       	
 ON KEY(F2)
		IF INFIELD(t07_modelo) THEN
		     CALL fl_ayuda_tipos_vehiculos(vg_codcia)
				RETURNING rm_mar.t04_modelo, rm_mar.t04_linea
		     IF rm_mar.t04_modelo IS NOT NULL THEN
			LET rm_tar.t07_modelo = rm_mar.t04_modelo
			DISPLAY BY NAME rm_tar.t07_modelo
		     END IF
		END IF
                LET int_flag = 0
	BEFORE  FIELD t07_modelo
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE  FIELD t07_codtarea
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD t07_modelo
		IF rm_tar.t07_modelo IS NOT NULL THEN
			CALL fl_lee_tipo_vehiculo(vg_codcia, rm_tar.t07_modelo)
				RETURNING rm_mar.*
			IF rm_mar.t04_modelo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'No existe modelo en el taller.',
					'exclamation')
				NEXT FIELD t07_modelo
			END IF
		END IF
	AFTER FIELD t07_pto_default
		IF rm_tar.t07_pto_default IS NOT NULL THEN
			IF rm_tar.t07_tipo = 'V' AND rm_tar.t07_pto_default <> 0			THEN
				CALL fgl_winmessage(vg_producto,'El tipo de tarea es por valor por lo tanto solo requiere el Valor Default de la Moneda Base','exclamation')
				LET rm_tar.t07_pto_default = 0
				DISPLAY BY NAME rm_tar.t07_pto_default
				NEXT FIELD NEXT
			END IF
		END IF
	AFTER FIELD t07_val_defa_mb
		IF rm_tar.t07_val_defa_mb IS NOT NULL THEN
		     IF rm_tar.t07_tipo = 'V' THEN
			CALL fl_lee_configuracion_facturacion()
                     		RETURNING rm_conf.*
                     	IF rm_conf.g00_serial IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe la configuración para la facturación ', 'stop')
				NEXT FIELD t07_val_defa_mb
                     	END IF
			IF rm_conf.g00_moneda_alt IS NULL
			OR rm_conf.g00_moneda_alt = ''
			THEN
				LET rm_tar.t07_val_defa_ma = 0
				DISPLAY BY NAME rm_tar.t07_val_defa_ma
				NEXT FIELD NEXT
			END IF
			CALL fl_lee_factor_moneda(rm_conf.g00_moneda_base,
						  rm_conf.g00_moneda_alt)
				RETURNING rm_cmon.*
			IF rm_cmon.g14_serial IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe la conversion entre monedas ', 'stop')
				NEXT FIELD t07_val_defa_mb
			END IF
			LET rm_tar.t07_val_defa_ma = rm_tar.t07_val_defa_mb *
						      rm_cmon.g14_tasa
			DISPLAY BY NAME rm_tar.t07_val_defa_ma
		   ELSE
			IF rm_tar.t07_val_defa_mb <> 0 THEN
				CALL fgl_winmessage(vg_producto,'El tipo de tarea es Puntuable por lo tanto solo requiere el Tiempo Optimo ','exclamation')
				LET rm_tar.t07_val_defa_mb = 0
				LET rm_tar.t07_val_defa_ma = 0
				DISPLAY BY NAME rm_tar.t07_val_defa_mb,
						rm_tar.t07_val_defa_ma
				NEXT FIELD PREVIOUS
		        END IF
		   END IF
		END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' THEN 
		     CALL fl_lee_tarea(vg_codcia, rm_tar.t07_modelo,
				       rm_tar.t07_codtarea)
		     	RETURNING rm_tar2.*
		     IF rm_tar2.t07_modelo IS NOT NULL THEN
			   CALL fgl_winmessage(vg_producto, 
				'La Tarea ya existe en la compañía ',
				'exclamation')
			   NEXT FIELD t07_codtarea
		     END IF
		END IF
		{
		IF rm_tar2.t07_nombre <> rm_tar.t07_nombre 
		OR vm_flag_mant = 'I'
		THEN 
		     SELECT t07_modelo INTO codigo FROM talt007
	      	     WHERE t07_compania = vg_codcia
	      	     AND   t07_nombre   = rm_tar.t07_nombre
	      	     IF status <> NOTFOUND THEN
                          CALL fgl_winmessage(vg_producto, 
				'El nombre de la tarea ya ha sido asignada ' ||
                                'al registro de codigo  '|| codigo,
                                'exclamation')
	                  NEXT FIELD t07_nombre  
              	     END IF
             	END IF
		}
		IF rm_tar.t07_pto_default <= 0 
		AND rm_tar.t07_tipo = 'P' 
		THEN
			CALL fgl_winmessage(vg_producto, 'El tipo de tarea es puntuable por lo tanto debe ingresar un Tiempo Optimo mayor a cero ','exclamation')
			LET rm_tar.t07_val_defa_mb = 0
			LET rm_tar.t07_val_defa_ma = 0
			DISPLAY BY NAME rm_tar.t07_val_defa_mb,
					rm_tar.t07_val_defa_ma
			NEXT FIELD t07_pto_default
             	END IF
		IF rm_tar.t07_val_defa_mb <= 0 
		AND rm_tar.t07_tipo = 'V' 
		THEN
			CALL fgl_winmessage(vg_producto, 'El tipo de tarea es por valor por lo tanto debe ingresar un Valor Default en la Moneda Base mayor a cero ','exclamation')
			LET rm_tar.t07_pto_default = 0
			DISPLAY BY NAME rm_tar.t07_pto_default
			NEXT FIELD t07_val_defa_mb
             	END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_tar.* FROM talt007 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_tar.t07_modelo, rm_tar.t07_nombre, rm_tar.t07_val_defa_mb,
		rm_tar.t07_pto_default, rm_tar.t07_val_defa_ma,	rm_tar.t07_tipo,		rm_tar.t07_estado,rm_tar.t07_usuario, rm_tar.t07_fecing,
		rm_tar.t07_codtarea

CALL fl_lee_tipo_vehiculo(vg_codcia, rm_tar.t07_modelo) RETURNING rm_mar.*
IF rm_tar.t07_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION

                                                                                
                                                                                
FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'sto
p')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'st
op')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 			 'stop')
     EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
        LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc,
			    'stop')
        EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION

