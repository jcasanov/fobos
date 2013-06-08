--------------------------------------------------------------------------------
-- Titulo           : genp104.4gl - Mantenimiento de Usuarios y Grupos de 
--                                  Usuarios 
-- Elaboracion      : 21-ago-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun genp104 base modulo 
-- Ultima Correccion: 28-mar-2002 
-- Motivo Correccion: Se anadio campo g05_tipo a la tabla de usuarios 
--			check (AG, AM, UF)
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows 		ARRAY[1000] OF INTEGER -- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_impresoras	ARRAY[200] OF RECORD
				g07_impresora	LIKE gent007.g07_impresora,
				g06_nombre	LIKE gent006.g06_nombre,
				g07_default	LIKE gent007.g07_default,
				impresora	CHAR(1)
			END RECORD
DEFINE vm_num_imp	SMALLINT
DEFINE vm_max_imp	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp104.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 AND num_args() <> 3 THEN	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
        'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_proceso = 'genp104'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_grp AT 3,2 WITH 10 ROWS, 80 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2)
OPEN FORM f_grp FROM '../forms/genf104_1'
DISPLAY FORM f_grp 
LET vm_num_rows    = 0
LET vm_row_current = 0
INITIALIZE rm_g05.*, rm_g04.* TO NULL
IF num_args() = 3 THEN
	CALL control_usuarios()
	EXIT PROGRAM
END IF
MENU 'OPCIONES'
	COMMAND KEY('G') 'Grupos' 	'Mantenimiento de grupos de usuarios.' 
		CALL control_grupos()
	COMMAND KEY('U') 'Usuarios' 	'Mantenimiento de usuarios.'
		CALL control_usuarios()
	COMMAND KEY('S') 'Salir'    	'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_grupos()
DEFINE r_g05		RECORD LIKE gent005.*

CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.* 
IF r_g05.g05_tipo <> 'AG' THEN
	CALL fgl_winmessage(vg_producto,
		'Solo administradores generales pueden accesar a este ' ||
		'proceso.',
		'exclamation')
	RETURN
END IF
OPEN FORM f_grp FROM '../forms/genf104_1'
DISPLAY FORM f_grp
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso_grp()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion_grp()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta_grp()
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
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro('G')
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro('G')
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    		'Vuelve al menú anterior.'
		EXIT MENU
END MENU
LET vm_row_current = 0
LET vm_num_rows = 0
CALL muestra_contadores()
CLOSE FORM f_grp 
CLEAR FORM

END FUNCTION



FUNCTION control_usuarios()
DEFINE r_g05		RECORD LIKE gent005.*

OPEN WINDOW w_usu AT 3,2 WITH 19 ROWS, 80 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_usu FROM '../forms/genf104_2'
DISPLAY FORM f_usu
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores()
CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
IF num_args() = 3 THEN
	CALL fl_lee_usuario(arg_val(3)) RETURNING r_g05.*
END IF
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Permisos'
		HIDE OPTION 'Impresoras'
		HIDE OPTION 'Bloquear/Activar'
		IF num_args() = 3 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Impresoras'
			CALL control_consulta_usr()
		ELSE
			IF r_g05.g05_tipo = 'UF' THEN
				HIDE OPTION 'Ingresar'
				HIDE OPTION 'Consultar'
				SHOW OPTION 'Modificar'
				LET vm_num_rows    = 1
				LET vm_row_current = 1
				SELECT ROWID INTO vm_rows[vm_row_current]
					FROM gent005
					WHERE g05_usuario = vg_usuario
				CALL lee_muestra_registro('U',
							vm_rows[vm_row_current])
			END IF
			IF r_g05.g05_tipo = 'AM' THEN
				HIDE OPTION 'Ingresar'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso_usr()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Permisos'
			SHOW OPTION 'Impresoras'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion_usr()
	COMMAND KEY('P') 'Permisos'		'Asigna permisos al usuario.'
		CALL control_permisos()
	COMMAND KEY('L') 'Impresoras'		'Asigna impresoras al usuario.'
		CALL control_impresoras()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta_usr()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Permisos'
			SHOW OPTION 'Impresoras'
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Permisos'
				HIDE OPTION 'Impresoras'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Permisos'
			SHOW OPTION 'Impresoras'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF r_g05.g05_tipo <> 'AG' AND r_g05.g05_tipo <> 'AM' THEN
			HIDE OPTION 'Bloquear/Activar'
		END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro('U')
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro('U')
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('B') 'Bloquear/Activar'     'Bloquea o activa registro.'
		CALL control_bloquea_activa_usr('?')
	COMMAND KEY('S') 'Salir'    		'Vuelve al menú anterior.'
		EXIT MENU
END MENU
CLOSE FORM f_usu 
CLOSE WINDOW w_usu
CLEAR FORM

END FUNCTION



FUNCTION control_ingreso_grp()

CLEAR FORM 
INITIALIZE rm_g04.* TO NULL
LET rm_g04.g04_ver_costo = 'N'
CALL lee_datos_grp('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro('G', vm_rows[vm_row_current])
	END IF
	RETURN
END IF
INSERT INTO gent004 VALUES (rm_g04.*)
LET vm_num_rows          = vm_num_rows + 1
LET vm_row_current       = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_ingreso_usr()

CLEAR FORM 
INITIALIZE rm_g05.* TO NULL
LET rm_g05.g05_estado = 'A'
LET rm_g05.g05_tipo   = 'UF'
DISPLAY BY NAME rm_g05.g05_estado
CALL muestra_etiquetas_usr()
CALL lee_datos_usr('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro('U', vm_rows[vm_row_current])
	END IF
	RETURN
END IF
INSERT INTO gent005 VALUES (rm_g05.*)
LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION siguiente_registro(flag)
DEFINE flag		CHAR(1)

IF vm_num_rows = 0 THEN
	RETURN
END IF
IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(flag, vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro(flag)
DEFINE flag		CHAR(1)

IF vm_num_rows = 0 THEN
	RETURN
END IF
IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(flag, vm_rows[vm_row_current])

END FUNCTION



FUNCTION control_modificacion_grp()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL lee_muestra_registro('G', vm_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd_grp CURSOR FOR 
	SELECT * FROM gent004 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd_grp
FETCH q_upd_grp INTO rm_g04.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  
CALL lee_datos_grp('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro('G', vm_rows[vm_row_current])
	CLOSE q_upd_grp
	FREE  q_upd_grp
	RETURN
END IF 
UPDATE gent004 SET * = rm_g04.* WHERE CURRENT OF q_upd_grp
COMMIT WORK
CLOSE q_upd_grp
FREE  q_upd_grp
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_bloquea_activa_usr(flag)
DEFINE flag 	CHAR(1)
DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	CHAR(1)

LET int_flag = 0
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL lee_muestra_registro('U', vm_rows[vm_row_current])
LET resp = 'Yes'
IF flag = '?' THEN
	LET mensaje = 'Seguro de bloquear'
	IF rm_g05.g05_estado <> 'A' THEN
		LET mensaje = 'Seguro de activar'
	END IF
	CALL fl_mensaje_seguro_ejecutar_proceso()
		RETURNING resp
END IF
IF resp = 'Yes' THEN
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_del CURSOR FOR SELECT * FROM gent005 
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_g05.*
	IF status < 0 THEN
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF
	IF flag = '?' THEN
		LET estado = 'B'
		IF rm_g05.g05_estado <> 'A' THEN
			LET estado = 'A'
		END IF
	ELSE 
		LET estado = flag
	END IF
	UPDATE gent005 SET g05_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	CLOSE q_del
	FREE  q_del
	WHENEVER ERROR STOP
	LET int_flag = 0 
	IF flag = '?' THEN
		CALL fl_mensaje_registro_modificado()
		CLEAR FORM
		CALL lee_muestra_registro('U', vm_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion_usr()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL lee_muestra_registro('U', vm_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd_usr CURSOR FOR 
	SELECT * FROM gent005 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd_usr
FETCH q_upd_usr INTO rm_g05.*
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN
END IF  
IF rm_g05.g05_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos_usr('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro('U', vm_rows[vm_row_current])
	CLOSE q_upd_usr
	FREE  q_upd_usr
	RETURN
END IF 
UPDATE gent005 SET * = rm_g05.* WHERE CURRENT OF q_upd_usr
COMMIT WORK
CLOSE q_upd_usr
FREE  q_upd_usr
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta_grp()
DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)
DEFINE grupo 			LIKE gent004.g04_grupo
DEFINE nombre 			LIKE gent004.g04_nombre
DEFINE r_grp			RECORD LIKE gent004.*

CLEAR FORM
INITIALIZE grupo TO NULL
LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql ON g04_grupo, g04_nombre, g04_ver_costo
	ON KEY(F2)
		IF INFIELD(g04_grupo) THEN
			CALL fl_ayuda_grupos_usuarios() RETURNING grupo, nombre 
			IF grupo IS NOT NULL THEN
				LET rm_g04.g04_grupo = grupo
				DISPLAY BY NAME rm_g04.g04_grupo
				DISPLAY nombre TO g04_nombre 
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD g04_grupo
		LET rm_g04.g04_grupo = GET_FLDBUF(g04_grupo)
		IF rm_g04.g04_grupo IS NULL THEN
			DISPLAY '' TO g04_nombre 
		ELSE
			CALL fl_lee_grupo_usuario(rm_g04.g04_grupo) 
				RETURNING r_grp.*
			IF r_grp.g04_grupo IS NULL THEN	
				DISPLAY '' TO g04_nombre 
			ELSE
				DISPLAY r_grp.g04_nombre TO g04_nombre
			END IF 
		END IF
END CONSTRUCT
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro('G', vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM gent004 WHERE ', expr_sql, 'ORDER BY 1' 
PREPARE cons_grp FROM query
DECLARE q_cons_grp CURSOR FOR cons_grp
LET vm_num_rows = 1
FOREACH q_cons_grp INTO rm_g04.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0 
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro('G', vm_rows[vm_row_current])

END FUNCTION



FUNCTION control_consulta_usr()
DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(700)
DEFINE usuario 			LIKE gent005.g05_usuario
DEFINE nombre			LIKE gent005.g05_nombres
DEFINE grupo			LIKE gent004.g04_grupo
DEFINE n_grp			LIKE gent004.g04_nombre
DEFINE r_grp			RECORD LIKE gent004.* 
DEFINE r_usr			RECORD LIKE gent005.* 
DEFINE r_g05			RECORD LIKE gent005.*

CLEAR FORM
IF num_args() <> 3 THEN
	CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
	INITIALIZE usuario TO NULL
	LET INT_FLAG = 0
	CONSTRUCT BY NAME expr_sql ON g05_usuario, g05_estado, g05_nombres, 
				      g05_tipo, g05_grupo
		ON KEY(F2)
			IF INFIELD(g05_usuario) THEN
				CALL fl_ayuda_usuarios()
					RETURNING usuario, nombre
				IF usuario IS NOT NULL THEN
					LET rm_g05.g05_usuario = usuario
					DISPLAY BY NAME rm_g05.g05_usuario
					DISPLAY nombre TO g05_nombres
				END IF
			END IF
			IF INFIELD(g05_grupo) THEN
				CALL fl_ayuda_grupos_usuarios()
					RETURNING grupo, n_grp 
				IF grupo IS NOT NULL THEN
					LET rm_g05.g05_grupo = grupo
					DISPLAY BY NAME rm_g05.g05_grupo
					DISPLAY n_grp TO grupo1 
				END IF
			END IF
			LET INT_FLAG = 0
		AFTER FIELD g05_grupo
			LET rm_g05.g05_grupo = GET_FLDBUF(g05_grupo)
			IF rm_g05.g05_grupo IS NULL THEN
				CLEAR grupo1
			ELSE
				CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) 
					RETURNING r_grp.*
				IF r_grp.g04_grupo IS NULL THEN	
					CLEAR  grupo1
				ELSE
					DISPLAY r_grp.g04_nombre TO grupo1
				END IF 
			END IF
		AFTER FIELD g05_usuario
			LET rm_g05.g05_usuario = GET_FLDBUF(g05_usuario)
			IF rm_g05.g05_usuario IS NULL THEN
				DISPLAY r_usr.g05_nombres TO g05_nombres
			ELSE
				CALL fl_lee_usuario(rm_g05.g05_usuario) 
					RETURNING r_usr.*
				IF r_usr.g05_usuario IS NULL THEN	
					DISPLAY r_usr.g05_nombres TO g05_nombres
				ELSE
					DISPLAY r_usr.g05_nombres TO g05_nombres
				END IF 
			END IF
	END CONSTRUCT
	IF INT_FLAG THEN
		IF vm_num_rows = 0 THEN
			CLEAR FORM
		ELSE	
			CALL lee_muestra_registro('U', vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
	IF r_g05.g05_tipo = 'AG' THEN
		LET query = 'SELECT *, ROWID FROM gent005 WHERE ',
				expr_sql CLIPPED, 
				    'ORDER BY 1' 
	ELSE
		LET query = 'SELECT UNIQUE gent005.*, gent005.ROWID ',
				' FROM gent052, gent005 ',
				' WHERE g52_modulo IN ',
					'(SELECT g52_modulo FROM gent052',
				      '	WHERE g52_usuario = "', vg_usuario, 
				      '"  AND g52_estado  = "A")',
				'   AND g52_estado = "A" ',
				'   AND g05_usuario = g52_usuario ',
				'   AND g05_tipo IN ("AM", "UF") ',
				'   AND ', expr_sql CLIPPED,
				' ORDER BY 1'
	END IF
ELSE
	LET query = 'SELECT *, gent005.ROWID ',
			' FROM gent005 ',
			' WHERE g05_estado  = "A" ',
			'   AND g05_usuario = "', arg_val(3), '"',
			' ORDER BY 1'
END IF
PREPARE cons_usr FROM query
DECLARE q_cons_usr CURSOR FOR cons_usr
LET vm_num_rows = 1
FOREACH q_cons_usr INTO rm_g05.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 3 THEN
		EXIT PROGRAM
	END IF
	LET vm_num_rows    = 0 
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro('U', vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(flag, row)
DEFINE flag 		CHAR(1)
DEFINE row 		INTEGER
DEFINE r_g54 		RECORD LIKE gent054.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
IF flag = 'G' THEN
	SELECT * INTO rm_g04.* FROM gent004 WHERE ROWID = row
ELSE
	SELECT * INTO rm_g05.* FROM gent005 WHERE ROWID = row
END IF
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF
IF flag = 'G' THEN
	DISPLAY BY NAME rm_g04.*
ELSE
	CALL muestra_etiquetas_usr()
	DISPLAY BY NAME rm_g05.*
	IF rm_g05.g05_menu IS NOT NULL THEN
		CALL fl_lee_proceso('GE', rm_g05.g05_menu) RETURNING r_g54.*
		DISPLAY r_g54.g54_nombre TO name_menu
	END IF
END IF
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_etiquetas_usr()
DEFINE r_g04		RECORD LIKE gent004.*

CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING r_g04.*
IF r_g04.g04_grupo IS NULL THEN
	DISPLAY 'Grupo ha sido eliminado' TO grupo1
ELSE
	DISPLAY r_g04.g04_nombre TO grupo1
END IF
IF rm_g05.g05_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO estado
ELSE
	DISPLAY 'BLOQUEADO' TO estado
END IF 

END FUNCTION



FUNCTION lee_datos_grp(flag)
DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE grupo 		LIKE gent004.g04_grupo
DEFINE r_grp		RECORD LIKE gent004.*

LET INT_FLAG = 0
INPUT BY NAME rm_g04.* WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_g04.g04_grupo, rm_g04.g04_nombre) THEN
			RETURN
		END IF
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
			RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	BEFORE FIELD g04_grupo
		IF flag = 'M' THEN
			NEXT FIELD g04_nombre
		END IF
	AFTER FIELD g04_grupo
		CALL fl_lee_grupo_usuario(rm_g04.g04_grupo) RETURNING r_grp.*
		IF r_grp.g04_grupo IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto, 
                                            'Este grupo ya existe',
                                            'exclamation')
			NEXT FIELD g04_grupo
		END IF
	AFTER INPUT
		IF FIELD_TOUCHED(g04_grupo) AND flag = 'M' THEN
			CALL fgl_winmessage(vg_producto,
                                            'No puede modificarse el código ' ||
                                            'del grupo', 'exclamation')
			LET INT_FLAG = 1
			RETURN
		END IF
END INPUT

END FUNCTION



FUNCTION lee_datos_usr(flag)
DEFINE flag		CHAR(1)
DEFINE grupo 		LIKE gent005.g05_grupo
DEFINE n_grupo		LIKE gent004.g04_nombre
DEFINE usuario 		LIKE gent005.g05_usuario
DEFINE resp 		CHAR(6)
DEFINE passwd		CHAR(10)
DEFINE r_user		RECORD LIKE gent005.*
DEFINE r_g54		RECORD LIKE gent054.*
DEFINE r_g05		RECORD LIKE gent005.*

CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
LET INT_FLAG = 0
INPUT rm_g05.g05_usuario, rm_g05.g05_nombres, rm_g05.g05_clave, 
      passwd, rm_g05.g05_tipo, rm_g05.g05_grupo, rm_g05.g05_menu 
      WITHOUT DEFAULTS
      FROM g05_usuario, g05_nombres, g05_clave, clave, g05_tipo, g05_grupo,
	   g05_menu
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_g05.g05_usuario, rm_g05.g05_nombres,
				     rm_g05.g05_grupo, rm_g05.g05_clave, clave ,
				     rm_g05.g05_menu) THEN
			RETURN
		END IF
	
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(g05_grupo) THEN
			CALL fl_ayuda_grupos_usuarios() RETURNING grupo, n_grupo
			IF grupo IS NOT NULL THEN
				LET rm_g05.g05_grupo = grupo
				DISPLAY BY NAME rm_g05.g05_grupo
				DISPLAY n_grupo TO grupo1
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		IF flag = 'M' AND r_g05.g05_tipo = 'UF' THEN
			NEXT FIELD g05_clave
		END IF
	AFTER FIELD g05_clave 
		IF flag = 'M' AND r_g05.g05_tipo = 'UF' THEN
			NEXT FIELD clave
		END IF
	AFTER FIELD clave     
		IF flag = 'M' AND r_g05.g05_tipo = 'UF' THEN
			NEXT FIELD g05_clave
		END IF
	BEFORE FIELD g05_usuario
		IF flag = 'M' THEN
			NEXT FIELD g05_nombres
		END IF
	AFTER FIELD g05_usuario
		CALL fl_lee_usuario(rm_g05.g05_usuario) RETURNING r_user.*
		IF r_user.g05_usuario IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto, 
                                            'Este usuario ya existe.',
                                            'exclamation')
			NEXT FIELD g05_usuario
		END IF
	BEFORE FIELD g05_grupo
			LET grupo = rm_g05.g05_grupo
	AFTER FIELD g05_grupo
		IF rm_g05.g05_grupo IS NULL AND grupo IS NULL THEN
			CONTINUE INPUT 
		END IF
		IF rm_g05.g05_grupo IS NULL AND grupo IS NOT NULL THEN
			CLEAR grupo1
			CONTINUE INPUT
		END IF
		IF grupo <> rm_g05.g05_grupo OR grupo IS NULL THEN
			SELECT g04_grupo, g04_nombre 
				INTO grupo, n_grupo 
				FROM gent004 
				WHERE g04_grupo = rm_g05.g05_grupo
			IF STATUS = NOTFOUND THEN
				CALL FGL_WINMESSAGE(vg_producto, 
                                      	            'Grupo no existe', 
                                                    'exclamation')
				DISPLAY '' TO grupo1
				NEXT FIELD g05_grupo
			ELSE
				DISPLAY n_grupo TO grupo1
			END IF 
		END IF 
	BEFORE FIELD g05_tipo
		IF rm_g05.g05_usuario = 'FOBOS' THEN
			LET rm_g05.g05_tipo = 'AG'
			DISPLAY BY NAME rm_g05.g05_tipo
			NEXT FIELD g05_grupo
		END IF 
	AFTER FIELD g05_menu
		IF rm_g05.g05_menu IS NOT NULL THEN
			SELECT * INTO r_g54.* FROM gent054
				WHERE g54_proceso = rm_g05.g05_menu
			IF status = NOTFOUND THEN
				CALL fgl_winmessage(vg_producto,
                                     'No existe menú', 'exclamation')
				NEXT FIELD g05_menu
			END IF
			IF r_g54.g54_tipo <> 'N' THEN
				CALL fgl_winmessage(vg_producto,
                                     'Código de proceso no es de tipo menú', 'exclamation')
				NEXT FIELD g05_menu
			END IF
			DISPLAY r_g54.g54_nombre TO name_menu
		ELSE
			CLEAR name_menu	
		END IF
	AFTER INPUT 
		IF rm_g05.g05_clave <> passwd THEN
			CALL fgl_winmessage(vg_producto,
                                            'Ambas contraseñas deben ' ||
                                            'coincidir', 'exclamation')
			INITIALIZE rm_g05.g05_clave TO NULL
			INITIALIZE passwd TO NULL
		        NEXT FIELD g05_clave
		END IF
		IF rm_g05.g05_usuario = 'FOBOS' THEN
			LET rm_g05.g05_tipo = 'AG'
			DISPLAY BY NAME rm_g05.g05_tipo
		END IF 
END INPUT

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 70 

END FUNCTION



FUNCTION control_permisos()
DEFINE comando		VARCHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'GENERALES', vg_separador, 'fuentes', 
	      vg_separador, '; fglrun genp129 ', vg_base, ' ',
	      'GE', ' ', rm_g05.g05_usuario
RUN comando

END FUNCTION



FUNCTION control_impresoras()
DEFINE flag		SMALLINT

CREATE TEMP TABLE tmp_impresora(
		g07_impresora	VARCHAR(10,5),
		g06_nombre	VARCHAR(30,15),
		g07_default	CHAR(1),
		impresora	CHAR(1)
	)
OPEN WINDOW w_imp AT 06, 11 WITH 16 ROWS, 61 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST)
OPEN FORM f_imp FROM '../forms/genf104_3'
DISPLAY FORM f_imp 
DISPLAY 'Impresora'        TO tit_col1
DISPLAY 'N o m b r e'      TO tit_col2
DISPLAY 'D'                TO tit_col3
DISPLAY 'C'                TO tit_col4
DISPLAY rm_g05.g05_usuario TO g07_user
LET vm_max_imp = 200
CALL muestra_contadores_det(0)
CALL cargar_impresora() RETURNING flag
IF flag THEN
	CLOSE WINDOW w_imp
	RETURN
END IF
CALL chequear_impresora()
IF NOT int_flag THEN
	CALL grabar_impresora_usr()
END IF
DROP TABLE tmp_impresora
CLOSE WINDOW w_imp

END FUNCTION



FUNCTION cargar_impresora()
DEFINE r_g06		RECORD LIKE gent006.*
DEFINE r_g07		RECORD LIKE gent007.*
DEFINE i		SMALLINT

CALL limpiar_imp()
FOR i = 1 TO vm_max_imp
	INITIALIZE rm_impresoras[i].* TO NULL
END FOR
DECLARE q_g06 CURSOR FOR SELECT * FROM gent006
LET vm_num_imp = 1
FOREACH q_g06 INTO r_g06.*
	LET rm_impresoras[vm_num_imp].g07_impresora = r_g06.g06_impresora
	LET rm_impresoras[vm_num_imp].g06_nombre    = r_g06.g06_nombre
	LET rm_impresoras[vm_num_imp].g07_default   = 'N'
	LET rm_impresoras[vm_num_imp].impresora     = 'N'
	CALL fl_lee_impresora_usr(rm_g05.g05_usuario, r_g06.g06_impresora)
		RETURNING r_g07.*
	IF r_g07.g07_user IS NOT NULL THEN
		LET rm_impresoras[vm_num_imp].g07_default = r_g07.g07_default
		LET rm_impresoras[vm_num_imp].impresora   = 'S'
	END IF
	INSERT INTO tmp_impresora VALUES(rm_impresoras[vm_num_imp].*)
	LET vm_num_imp = vm_num_imp + 1
	IF vm_num_imp > vm_max_imp THEN
		CALL fl_mensaje_arreglo_incompleto()
		RETURN 1
	END IF
END FOREACH
LET vm_num_imp = vm_num_imp - 1
IF vm_num_imp = 0 THEN
	CALL fl_mostrar_mensaje('No hay impresoras definidas en el sistema.','exclamation')
	RETURN 1
END IF
CALL cargar_query_temp(3, "DESC", 4, "DESC")
CALL mostrar_imp()
RETURN 0

END FUNCTION



FUNCTION limpiar_imp()
DEFINE i, arr		SMALLINT

LET arr = fgl_scr_size('rm_impresoras')
FOR i = 1 TO arr
	CLEAR rm_impresoras[i].*
END FOR

END FUNCTION



FUNCTION mostrar_imp()
DEFINE i, arr		SMALLINT

LET arr = fgl_scr_size('rm_impresoras')
IF vm_num_imp <= arr THEN
	LET arr = vm_num_imp
END IF
FOR i = 1 TO arr
	DISPLAY rm_impresoras[i].* TO rm_impresoras[i].*
END FOR

END FUNCTION



FUNCTION chequear_impresora()
DEFINE resp             CHAR(6)
DEFINE i, j, resul	SMALLINT
DEFINE salir, col	SMALLINT
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE flag_tod		SMALLINT
DEFINE flag_nin		SMALLINT

LET i 	  = 1
LET salir = 0
OPTIONS
	INSERT KEY F30,
	DELETE KEY F31
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col           = 3
LET rm_orden[col] = 'DESC'
LET vm_columna_1  = col
LET vm_columna_2  = 4
LET rm_orden[4]   = 'DESC'
WHILE NOT salir
	CALL cargar_query_temp(vm_columna_1, rm_orden[vm_columna_1],
				vm_columna_2, rm_orden[vm_columna_2])
	CALL set_count(vm_num_imp)
	LET int_flag = 0
	INPUT ARRAY rm_impresoras WITHOUT DEFAULTS FROM rm_impresoras.*
		ON KEY(INTERRUPT)
       			LET int_flag = 0
	               	CALL fl_mensaje_abandonar_proceso()
		               	RETURNING resp
       			IF resp = 'Yes' THEN
				CALL muestra_contadores_det(0)
 	      			LET int_flag = 1
				EXIT WHILE	
       	       		END IF	
		ON KEY(F5)
			IF flag_tod THEN
				CALL chequear_todo()
				LET flag_tod = 0
				LET flag_nin = 1
				CALL dialog.keysetlabel('F5', '')
				CALL dialog.keysetlabel('F6', 'Ninguna')
			END IF
		ON KEY(F6)
			IF flag_nin THEN
				CALL chequear_ninguno()
				LET flag_nin = 0
				LET flag_tod = 1
				CALL dialog.keysetlabel('F6', '')
				CALL dialog.keysetlabel('F5', 'Todas')
			END IF
		ON KEY(F15)
			LET col = 1
			EXIT INPUT
		ON KEY(F16)
			LET col = 2
			EXIT INPUT
		ON KEY(F17)
			LET col = 3
			EXIT INPUT
		ON KEY(F18)
			LET col = 4
			EXIT INPUT
		BEFORE INPUT
			CALL dialog.keysetlabel('DELETE','')
			CALL dialog.keysetlabel('INSERT','')
			CALL buscar_check('N', 'N') RETURNING flag_tod
			IF flag_tod THEN
				CALL dialog.keysetlabel('F5', 'Todas')
			ELSE
				CALL dialog.keysetlabel('F5', '')
			END IF
			CALL buscar_check('S', 'S') RETURNING flag_nin
			IF flag_nin THEN
				CALL dialog.keysetlabel('F6', 'Ninguna')
			ELSE
				CALL dialog.keysetlabel('F6', '')
			END IF
		BEFORE ROW
	       		LET i = arr_curr()
       			LET j = scr_line()
			CALL muestra_contadores_det(i)
			CALL buscar_check('N', 'N') RETURNING flag_tod
			IF flag_tod THEN
				CALL dialog.keysetlabel('F5', 'Todas')
			ELSE
				CALL dialog.keysetlabel('F5', '')
			END IF
			CALL buscar_check('S', 'S') RETURNING flag_nin
			IF flag_nin THEN
				CALL dialog.keysetlabel('F6', 'Ninguna')
			ELSE
				CALL dialog.keysetlabel('F6', '')
			END IF
		BEFORE INSERT
			EXIT INPUT
		AFTER FIELD g07_default
			CALL contar_def() RETURNING resul
			IF resul > 1 THEN
				NEXT FIELD rm_impresoras[i].g07_default
			END IF
			UPDATE tmp_impresora
				SET g07_default = rm_impresoras[i].g07_default
				WHERE g07_impresora = rm_impresoras[i].g07_impresora
		AFTER FIELD impresora
			UPDATE tmp_impresora
				SET impresora = rm_impresoras[i].impresora
				WHERE g07_impresora = rm_impresoras[i].g07_impresora
		AFTER INPUT
			LET salir = 1
	END INPUT
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
LET vm_num_imp = arr_count()

END FUNCTION



FUNCTION grabar_impresora_usr()
DEFINE i, flag		SMALLINT

BEGIN WORK
DELETE FROM gent007 WHERE g07_user = rm_g05.g05_usuario
LET flag = 0
FOR i = 1 TO vm_num_imp
	IF rm_impresoras[i].impresora = 'N' THEN
		CONTINUE FOR
	END IF
	INSERT INTO gent007
		VALUES(rm_g05.g05_usuario, rm_impresoras[i].g07_impresora, 
			rm_impresoras[i].g07_default, vg_usuario, CURRENT)
	LET flag = 1
END FOR
COMMIT WORK
IF flag THEN
	CALL fl_mostrar_mensaje('Impresoras asignadas Ok.','info')
ELSE
	CALL fl_mostrar_mensaje('Usuario sin impresoras asignadas Ok.','info')
END IF

END FUNCTION



FUNCTION cargar_query_temp(col1, crit1, col2, crit2)
DEFINE col1		SMALLINT
DEFINE crit1		CHAR(4)
DEFINE col2		SMALLINT
DEFINE crit2		CHAR(4)
DEFINE query		VARCHAR(255)
DEFINE i		SMALLINT

LET query = 'SELECT * FROM tmp_impresora ',
	    ' 	ORDER BY ', col1, ' ', crit1, ', ', col2, ' ', crit2
PREPARE t1 FROM query
DECLARE q_t1 CURSOR FOR t1
LET i = 1
FOREACH q_t1 INTO rm_impresoras[i].*
	LET i = i + 1
END FOREACH

END FUNCTION



FUNCTION contar_def()
DEFINE i, cont		SMALLINT

LET cont = 0
FOR i = 1 TO vm_num_imp
	IF rm_impresoras[i].g07_default = 'S' THEN
		LET cont = cont + 1
	END IF
END FOR
IF cont > 1 THEN
	CALL fl_mostrar_mensaje('No puede asignar mas de una impresora default a un usuario.','exclamation')
END IF
RETURN cont

END FUNCTION



FUNCTION buscar_check(c1, c2)
DEFINE c1, c2		CHAR(1)
DEFINE i, encont	SMALLINT

LET encont = 0
FOR i = 1 TO vm_num_imp
	IF rm_impresoras[i].g07_default = c1 AND rm_impresoras[i].impresora = c2
	THEN
		LET encont = 1
		EXIT FOR
	END IF
END FOR
RETURN encont

END FUNCTION



FUNCTION chequear_todo()
DEFINE unavez, i	SMALLINT

LET unavez = 1
FOR i = 1 TO vm_num_imp
	LET rm_impresoras[i].g07_default = 'N'
	LET rm_impresoras[i].impresora   = 'S'
	IF unavez THEN
		LET rm_impresoras[i].g07_default = 'S'
		LET unavez = 0
	END IF
	UPDATE tmp_impresora
		SET g07_default = rm_impresoras[i].g07_default,
		    impresora   = rm_impresoras[i].impresora
		WHERE g07_impresora = rm_impresoras[i].g07_impresora
END FOR
CALL limpiar_imp()
CALL mostrar_imp()
CALL fl_mostrar_mensaje('Chequeadas TODAS las Impresoras Ok.','info')

END FUNCTION



FUNCTION chequear_ninguno()
DEFINE i		SMALLINT

FOR i = 1 TO vm_num_imp
	LET rm_impresoras[i].g07_default = 'N'
	LET rm_impresoras[i].impresora   = 'N'
	UPDATE tmp_impresora
		SET g07_default = rm_impresoras[i].g07_default,
		    impresora   = rm_impresoras[i].impresora
		WHERE g07_impresora = rm_impresoras[i].g07_impresora
END FOR
CALL limpiar_imp()
CALL mostrar_imp()
CALL fl_mostrar_mensaje('Ninguna Impresora asignada Ok.','info')

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor                 SMALLINT

DISPLAY "" AT 6, 1
DISPLAY cor, " de ", vm_num_imp AT 6, 50

END FUNCTION
