-------------------------------------------------------------------------------
-- Titulo               : repp102.4gl -- Mantenimiento de Bodegas
-- Elaboración          : 4-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  repp102.4gl base módulo compañía
-- Ultima Correción     : 5-sep-2001
-- Motivo Corrección    : 2
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_bod		RECORD LIKE rept002.*
DEFINE rm_bod2		RECORD LIKE rept002.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER -- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp102.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'repp102'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_bod AT 3, 2 WITH 16 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_bod FROM '../forms/repf102_1'
DISPLAY FORM f_bod
INITIALIZE rm_bod.* TO NULL
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
DEFINE nomloc		LIKE gent002.g02_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(800)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r02_codigo, r02_estado, r02_nombre, r02_localidad,
	r02_tipo, r02_factura, r02_usuario, r02_area
	ON KEY(F2)
		IF INFIELD(r02_codigo) THEN
		     CALL fl_ayuda_bodegas_rep(vg_codcia, 'T', 'T', 'T', 'A', 'T')
		     	RETURNING rm_bod.r02_codigo, rm_bod.r02_nombre
		     IF rm_bod.r02_codigo IS NOT NULL THEN
			DISPLAY BY NAME rm_bod.r02_codigo, rm_bod.r02_nombre
		     END IF
		END IF
                IF INFIELD(r02_localidad) THEN
                     CALL fl_ayuda_localidad(vg_codcia)
                     	RETURNING rm_bod2.r02_localidad, nomloc
                     IF rm_bod2.r02_localidad IS NOT NULL THEN
			LET rm_bod.r02_localidad = rm_bod2.r02_localidad
                        DISPLAY BY NAME rm_bod.r02_localidad
			DISPLAY  nomloc TO nom_loc
                     END IF
                END IF
                LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows >0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID ',
		' FROM rept002 ',
		' WHERE r02_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3, 5'
PREPARE cons FROM query
DECLARE q_bod CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_bod INTO rm_bod.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
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
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_g02		RECORD LIKE gent002.*

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_bod.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_bod.r02_compania   = vg_codcia
LET rm_bod.r02_estado     = 'A'
LET rm_bod.r02_tipo       = 'F'
LET rm_bod.r02_area       = 'R'
LET rm_bod.r02_factura    = 'S'
LET rm_bod.r02_localidad  = vg_codloc
LET rm_bod.r02_fecing     = CURRENT
LET rm_bod.r02_usuario    = vg_usuario
DISPLAY BY NAME rm_bod.r02_fecing, rm_bod.r02_usuario, rm_bod.r02_estado,
		rm_bod.r02_localidad
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING r_g02.*
DISPLAY r_g02.g02_nombre TO nom_loc	
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO rept002 VALUES (rm_bod.*)
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
	CALL fl_mensaje_registro_ingresado()
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION control_modificacion()

LET vm_flag_mant = 'M'
IF rm_bod.r02_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rept002
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_bod.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET rm_bod2.r02_nombre = rm_bod.r02_nombre
CALL lee_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
UPDATE rept002 SET * = rm_bod.*	WHERE CURRENT OF q_up
COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	LIKE rept002.r02_estado

LET int_flag = 0
IF rm_bod.r02_codigo IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET mensaje = 'Seguro de bloquear'
IF rm_bod.r02_estado <> 'A' THEN
	LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_del CURSOR FOR SELECT * FROM rept002 
		WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_bod.*
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	LET estado = 'B'
	IF rm_bod.r02_estado <> 'A' THEN
		LET estado = 'A'
	END IF
	UPDATE rept002 SET r02_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
	CLEAR FORM	
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_datos()
DEFINE resp		CHAR(6)
DEFINE codigo		LIKE rept002.r02_codigo
DEFINE nombre		LIKE rept002.r02_nombre
DEFINE nomloc		LIKE gent002.g02_nombre
DEFINE locali		LIKE gent002.g02_localidad
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE mensaje		VARCHAR(100)
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_bod.r02_codigo, rm_bod.r02_nombre, rm_bod.r02_localidad,
	rm_bod.r02_factura, rm_bod.r02_tipo, rm_bod.r02_area
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF FIELD_TOUCHED(rm_bod.r02_codigo, rm_bod.r02_nombre,
				  rm_bod.r02_localidad, rm_bod.r02_factura,
				  rm_bod.r02_tipo, rm_bod.r02_area)
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
		IF vm_flag_mant = 'M' THEN
			CONTINUE INPUT
		END IF
                IF INFIELD(r02_localidad) THEN
                      CALL fl_ayuda_localidad(vg_codcia)
                      RETURNING rm_bod2.r02_localidad, nomloc
                      IF rm_bod2.r02_localidad IS NOT NULL THEN
			   LET rm_bod.r02_localidad = rm_bod2.r02_localidad 
                           DISPLAY BY NAME rm_bod.r02_localidad
                           DISPLAY nomloc TO  nom_loc
                      END IF
                END IF
                LET int_flag = 0
	BEFORE FIELD r02_codigo
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD r02_localidad
		LET locali = rm_bod.r02_localidad
	AFTER FIELD r02_codigo
		IF rm_bod.r02_codigo IS NOT NULL THEN
                        CALL fl_lee_bodega_rep(vg_codcia, rm_bod.r02_codigo)
                                RETURNING rm_bod2.*
                        IF rm_bod2.r02_codigo IS NOT NULL THEN
				CALL fl_mostrar_mensaje('La Bodega ya existe en la base de datos.','exclamation')
                                NEXT FIELD r02_codigo
                        END IF
		END IF
	AFTER FIELD r02_localidad
		IF vm_flag_mant = 'M' THEN
			LET rm_bod.r02_localidad = locali
			DISPLAY BY NAME rm_bod.r02_localidad
			CALL fl_lee_localidad(vg_codcia, rm_bod.r02_localidad)
				RETURNING rm_loc.*
			DISPLAY rm_loc.g02_nombre TO nom_loc
			CONTINUE INPUT
		END IF
		IF rm_bod.r02_localidad IS NULL THEN
			LET rm_bod.r02_localidad = locali
		END IF
		IF rm_bod.r02_localidad <> vg_codloc THEN
			IF rm_bod.r02_localidad <> 5 THEN
				LET rm_bod.r02_localidad = vg_codloc
			END IF
		END IF
		IF rm_bod.r02_localidad = 5 AND vg_codloc <> 3 THEN
			LET rm_bod.r02_localidad = vg_codloc
		END IF
		DISPLAY BY NAME rm_bod.r02_localidad
		CALL fl_lee_localidad(vg_codcia, rm_bod.r02_localidad)
			RETURNING rm_loc.*
		DISPLAY rm_loc.g02_nombre TO nom_loc
		IF rm_loc.g02_localidad IS NULL THEN
			CALL fl_mostrar_mensaje('No existe la localidad.','exclamation')
			NEXT FIELD r02_localidad
		END IF
		IF rm_loc.g02_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD r02_localidad
		END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' OR rm_bod2.r02_nombre <> rm_bod.r02_nombre
		THEN
	      		SELECT r02_codigo INTO codigo FROM rept002
	      		WHERE r02_compania = vg_codcia
	      		AND   r02_nombre   = rm_bod.r02_nombre
	      		IF status <> NOTFOUND THEN
				LET mensaje = 'El nombre de la bodega ya ha ',
						'sido asignada al registro ',
						'de código ', codigo
                 		--CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	         		NEXT FIELD r02_nombre  
              		END IF
             	END IF
		IF rm_bod.r02_tipo = 'S' THEN
			INITIALIZE r_r02.* TO NULL
			DECLARE q_bds CURSOR FOR
				SELECT * FROM rept002
					WHERE r02_compania  = vg_codcia
					  AND r02_localidad = rm_bod.r02_localidad
					  AND r02_estado   = "A"
					  AND r02_tipo     = "S"
			OPEN q_bds
			FETCH q_bds INTO r_r02.*
			CLOSE q_bds
			IF r_r02.r02_compania IS NOT NULL THEN
				IF r_r02.r02_codigo = rm_bod.r02_codigo THEN
					IF vm_flag_mant = 'M' THEN
						EXIT INPUT
					END IF
				END IF
				CALL fl_mostrar_mensaje('Ya existe una bodega sin stock.','exclamation')
                	       	NEXT FIELD r02_tipo
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_bod.* FROM rept002 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_bod.r02_codigo, rm_bod.r02_nombre, rm_bod.r02_estado, 
		rm_bod.r02_tipo, rm_bod.r02_area, rm_bod.r02_factura, 
		rm_bod.r02_localidad, rm_bod.r02_usuario, rm_bod.r02_fecing
IF rm_bod.r02_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado
ELSE
        DISPLAY 'BLOQUEADO' TO tit_estado
END IF
CALL fl_lee_localidad(vg_codcia, rm_bod.r02_localidad)
RETURNING rm_loc.*
DISPLAY rm_loc.g02_nombre TO nom_loc

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION
