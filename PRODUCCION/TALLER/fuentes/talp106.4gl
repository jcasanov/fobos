-------------------------------------------------------------------------------
-- Titulo               : talp106.4gl -- Mantenimiento de Subtipos de Ordenes
--					 de Trabajo
-- Elaboración          : 8-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  talp106.4gl base TA 1 
-- Ultima Correción     : 10-sep-2001
-- Motivo Corrección    : 2
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_sord   RECORD LIKE talt006.*
DEFINE rm_sord2  RECORD LIKE talt006.*
DEFINE rm_tord   RECORD LIKE talt005.*
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
CALL startlog('../logs/talp106.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'talp106'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_sord AT 3,2 WITH 13 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_sord FROM '../forms/talf106_1'
DISPLAY FORM f_sord
INITIALIZE rm_sord.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
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
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
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
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE nomloc		LIKE gent002.g02_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON t06_tipord, t06_subtipo, t06_nombre,
			      t06_usuario, t06_fecing
	ON KEY(F2)
		IF INFIELD(t06_tipord) THEN
		     CALL fl_ayuda_tipo_orden_trabajo(vg_codcia)
		     RETURNING rm_sord.t06_tipord, rm_tord.t05_nombre
		     IF rm_sord.t06_tipord IS NOT NULL THEN
			DISPLAY BY NAME rm_sord.t06_tipord
			DISPLAY rm_tord.t05_nombre TO  nom_tipo
		     END IF
		END IF
                IF INFIELD(t06_subtipo) THEN
			IF rm_sord.t06_tipord IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Debe ingresar primero el tipo de orden','exclamation')
				NEXT FIELD t06_tipord
			END IF
                     	CALL fl_ayuda_subtipo_orden(vg_codcia,
						    rm_sord.t06_tipord)
                     	RETURNING rm_sord2.t06_tipord, rm_sord2.t06_subtipo,
			          rm_sord2.t06_nombre
                     	IF rm_sord2.t06_subtipo IS NOT NULL THEN
 				LET rm_sord.t06_subtipo = rm_sord2.t06_subtipo
 				LET rm_sord.t06_nombre  = rm_sord2.t06_nombre
                        	DISPLAY BY NAME rm_sord.t06_subtipo, 
						rm_sord.t06_nombre
                     	END IF
                END IF
		AFTER FIELD t06_tipord
			LET rm_sord.t06_tipord = get_fldbuf(t06_tipord)
               		IF rm_sord.t06_tipord IS NOT NULL THEN
				CALL fl_lee_tipo_orden_taller(vg_codcia,
							rm_sord.t06_tipord)
		    			RETURNING rm_tord.*
		     		IF rm_tord.t05_tipord IS NULL THEN
					CALL fgl_winmessage(vg_producto, 'No existe el tipo de orden de trabajo en la compañía ','exclamation')
			   		NEXT FIELD t06_tipord
		     		END IF
		     		DISPLAY  rm_tord.t05_nombre TO nom_tipo	
			ELSE
				CLEAR nom_tipo
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
LET query = 'SELECT *, ROWID FROM talt006 WHERE ', expr_sql CLIPPED,
		' ORDER BY 1, 2'
PREPARE cons FROM query
DECLARE q_sord CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_sord INTO rm_sord.*, vm_r_rows[vm_num_rows]
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
INITIALIZE rm_sord.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_sord.t06_compania   = vg_codcia
LET rm_sord.t06_fecing     = CURRENT
LET rm_sord.t06_usuario    = vg_usuario
DISPLAY BY NAME rm_sord.t06_fecing, rm_sord.t06_usuario
LET rm_sord2.t06_nombre = rm_sord.t06_nombre
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO talt006 VALUES (rm_sord.*)
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
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM talt006 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_sord.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
LET rm_sord2.t06_nombre = rm_sord.t06_nombre
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE talt006 SET * = rm_sord.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION



FUNCTION lee_datos()
DEFINE           resp      CHAR(6)
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_sord.t06_tipord, rm_sord.t06_subtipo, rm_sord.t06_nombre              WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF field_touched(rm_sord.t06_tipord, rm_sord.t06_subtipo,
			rm_sord.t06_nombre)
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
                IF INFIELD(t06_tipord) THEN
                      CALL fl_ayuda_tipo_orden_trabajo(vg_codcia)
                      RETURNING rm_sord2.t06_tipord, rm_tord.t05_nombre
                      IF rm_sord2.t06_tipord IS NOT NULL THEN
			  LET rm_sord.t06_tipord = rm_sord2.t06_tipord
                          DISPLAY BY NAME rm_sord.t06_tipord
                          DISPLAY rm_tord.t05_nombre TO  nom_tipo
                      END IF
                END IF
                LET int_flag = 0
	BEFORE  FIELD t06_subtipo
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD t06_tipord
               IF rm_sord.t06_tipord IS NOT NULL THEN
		    CALL fl_lee_tipo_orden_taller(vg_codcia, rm_sord.t06_tipord)
		    RETURNING rm_tord.*
		     IF rm_tord.t05_tipord IS NULL THEN
			   CALL fgl_winmessage(vg_producto, 'No existe el tipo de orden de trabajo en la compañía ','exclamation')
			   NEXT FIELD t06_tipord
		     END IF
		     DISPLAY  rm_tord.t05_nombre TO nom_tipo	
		ELSE
			CLEAR nom_tipo
		END IF
	AFTER INPUT
               IF vm_flag_mant = 'I' THEN
			CALL fl_lee_subtipo_orden_taller(vg_codcia, rm_sord.t06_tipord, rm_sord.t06_subtipo) 
				RETURNING rm_sord2.*
	      		IF rm_sord2.t06_subtipo IS NOT NULL THEN
                 	   CALL fgl_winmessage (vg_producto, 'El subtipo de orden ya existe en la compañía','exclamation')
	         	   NEXT FIELD t06_subtipo  
              		END IF
              	END IF
		IF rm_sord2.t06_nombre <> rm_sord.t06_nombre
		 	OR vm_flag_mant = 'I'
		 THEN
	      		SELECT t06_subtipo INTO rm_sord2.t06_subtipo
			FROM  talt006
	      		WHERE t06_compania = vg_codcia
	      		AND   t06_nombre   = rm_sord.t06_nombre
	      		IF status <> NOTFOUND THEN
                 	   CALL fgl_winmessage (vg_producto, 'El nombre del subtipo de orden ya ha sido asignada al registro de codigo  '|| rm_sord2.t06_subtipo,'exclamation')
	         	   NEXT FIELD t06_nombre  
              		END IF
              	END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_sord.* FROM talt006 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_sord.t06_tipord, rm_sord.t06_nombre, rm_sord.t06_subtipo,
		rm_sord.t06_usuario, rm_sord.t06_fecing
CALL fl_lee_tipo_orden_taller(vg_codcia, rm_sord.t06_tipord)
	RETURNING rm_tord.*
DISPLAY rm_tord.t05_nombre TO nom_tipo

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

