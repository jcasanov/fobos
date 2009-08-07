{*
 * Titulo           : genp104.4gl - Mantenimiento de Usuarios y Grupos de 
 *                                  Usuarios 
 * Elaboracion      : 21-ago-2001
 * Autor            : JCM
 * Formato Ejecucion: fglrun genp104 base modulo 
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS

DEFINE rm_grp		RECORD LIKE gent004.*
DEFINE rm_usr		RECORD LIKE gent005.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp104.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
        'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'genp104'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
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

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_usr.* TO NULL
INITIALIZE rm_grp.* TO NULL

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

CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*

OPEN WINDOW w_usu AT 3,2 WITH 19 ROWS, 80 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_usu FROM '../forms/genf104_2'
DISPLAY FORM f_usu

LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Permisos'
		HIDE OPTION 'Bloquear/Activar'
		IF r_g05.g05_tipo = 'UF' THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Modificar'
			LET vm_num_rows    = 1
			LET vm_row_current = 1
			SELECT ROWID INTO vm_rows[vm_row_current]
				FROM gent005 WHERE g05_usuario = vg_usuario
			CALL lee_muestra_registro('U', vm_rows[vm_row_current])
		END IF
		IF r_g05.g05_tipo = 'AM' THEN
			HIDE OPTION 'Ingresar'
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
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta_usr()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Permisos'
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Permisos'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Permisos'
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
INITIALIZE rm_grp.* TO NULL

LET rm_grp.g04_ver_costo = 'N'

CALL lee_datos_grp('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro('G', vm_rows[vm_row_current])
	END IF
	RETURN
END IF

INSERT INTO gent004 VALUES (rm_grp.*)

LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_ingreso_usr()

DEFINE query 	VARCHAR(100)

CLEAR FORM 
INITIALIZE rm_usr.* TO NULL

LET rm_usr.g05_estado = 'A'
LET rm_usr.g05_tipo   = 'UF'
DISPLAY BY NAME rm_usr.g05_estado
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

BEGIN WORK

INSERT INTO gent005 VALUES (rm_usr.*)
LET query = 'GRANT DBA TO ' || rm_usr.g05_usuario CLIPPED 
PREPARE stmt1 FROM query
EXECUTE stmt1

COMMIT WORK

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
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd_grp CURSOR FOR 
	SELECT * FROM gent004 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd_grp
FETCH q_upd_grp INTO rm_grp.*
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

UPDATE gent004 SET * = rm_grp.* WHERE CURRENT OF q_upd_grp
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
	IF rm_usr.g05_estado <> 'A' THEN
		LET mensaje = 'Seguro de activar'
	END IF
	CALL fl_mensaje_seguro_ejecutar_proceso()
		RETURNING resp
END IF
IF resp = 'Yes' THEN
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM gent005 
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_usr.*
	IF status < 0 THEN
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF

	IF flag = '?' THEN
		LET estado = 'B'
		IF rm_usr.g05_estado <> 'A' THEN
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

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd_usr CURSOR FOR 
	SELECT * FROM gent005 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd_usr
FETCH q_upd_usr INTO rm_usr.*
WHENEVER ERROR STOP

IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  
IF rm_usr.g05_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	ROLLBACK WORK
	RETURN
END IF

CALL lee_datos_usr('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro('U', vm_rows[vm_row_current])
	CLOSE q_upd_usr
	FREE  q_upd_usr
	RETURN
END IF 

UPDATE gent005 SET * = rm_usr.* WHERE CURRENT OF q_upd_usr
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
				LET rm_grp.g04_grupo = grupo
				DISPLAY BY NAME rm_grp.g04_grupo
				DISPLAY nombre TO g04_nombre 
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD g04_grupo
		LET rm_grp.g04_grupo = GET_FLDBUF(g04_grupo)
		IF rm_grp.g04_grupo IS NULL THEN
			DISPLAY '' TO g04_nombre 
		ELSE
			CALL fl_lee_grupo_usuario(rm_grp.g04_grupo) 
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
FOREACH q_cons_grp INTO rm_grp.*, vm_rows[vm_num_rows]
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

CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*

CLEAR FORM

INITIALIZE usuario TO NULL
LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql ON g05_usuario, g05_estado, g05_nombres, 
			      g05_tipo, g05_grupo
	ON KEY(F2)
		IF INFIELD(g05_usuario) THEN
			CALL fl_ayuda_usuarios() RETURNING usuario, nombre
			IF usuario IS NOT NULL THEN
				LET rm_usr.g05_usuario = usuario
				DISPLAY BY NAME rm_usr.g05_usuario
				DISPLAY nombre TO g05_nombres
			END IF
		END IF
		IF INFIELD(g05_grupo) THEN
			CALL fl_ayuda_grupos_usuarios() RETURNING grupo, n_grp 
			IF grupo IS NOT NULL THEN
				LET rm_usr.g05_grupo = grupo
				DISPLAY BY NAME rm_usr.g05_grupo
				DISPLAY n_grp TO grupo1 
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD g05_grupo
		LET rm_usr.g05_grupo = GET_FLDBUF(g05_grupo)
		IF rm_usr.g05_grupo IS NULL THEN
			CLEAR grupo1
		ELSE
			CALL fl_lee_grupo_usuario(rm_usr.g05_grupo) 
				RETURNING r_grp.*
			IF r_grp.g04_grupo IS NULL THEN	
				CLEAR  grupo1
			ELSE
				DISPLAY r_grp.g04_nombre TO grupo1
			END IF 
		END IF
	AFTER FIELD g05_usuario
		LET rm_usr.g05_usuario = GET_FLDBUF(g05_usuario)
		IF rm_usr.g05_usuario IS NULL THEN
			DISPLAY r_usr.g05_nombres TO g05_nombres
		ELSE
			CALL fl_lee_usuario(rm_usr.g05_usuario) 
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
	LET query = 'SELECT *, ROWID FROM gent005 WHERE ', expr_sql CLIPPED, 
		    'ORDER BY 1' 
ELSE
	LET query = 'SELECT UNIQUE gent005.*, gent005.ROWID ',
			' FROM gent052, gent005 ',
			' WHERE g52_modulo IN (SELECT g52_modulo FROM gent052',
				      '	WHERE g52_usuario = "', vg_usuario, 
				      '"  AND g52_estado  = "A")',
			'   AND g52_estado = "A" ',
			'   AND g05_usuario = g52_usuario ',
			'   AND g05_tipo IN ("AM", "UF") ',
			'   AND ', expr_sql CLIPPED,
			' ORDER BY 1'
END IF
PREPARE cons_usr FROM query
DECLARE q_cons_usr CURSOR FOR cons_usr
LET vm_num_rows = 1
FOREACH q_cons_usr INTO rm_usr.*, vm_rows[vm_num_rows]
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
	SELECT * INTO rm_grp.* FROM gent004 WHERE ROWID = row
ELSE
	SELECT * INTO rm_usr.* FROM gent005 WHERE ROWID = row
END IF

IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

IF flag = 'G' THEN
	DISPLAY BY NAME rm_grp.*
ELSE
	CALL muestra_etiquetas_usr()
	DISPLAY BY NAME rm_usr.*
	IF rm_usr.g05_menu IS NOT NULL THEN
		CALL fl_lee_proceso('GE', rm_usr.g05_menu) RETURNING r_g54.*
		DISPLAY r_g54.g54_nombre TO name_menu
	END IF
END IF

CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_etiquetas_usr()

DEFINE r_g04		RECORD LIKE gent004.*

CALL fl_lee_grupo_usuario(rm_usr.g05_grupo) RETURNING r_g04.*
IF r_g04.g04_grupo IS NULL THEN
	DISPLAY 'Grupo ha sido eliminado' TO grupo1
ELSE
	DISPLAY r_g04.g04_nombre TO grupo1
END IF

IF rm_usr.g05_estado = 'A' THEN
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

INPUT BY NAME rm_grp.* WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_grp.g04_grupo, rm_grp.g04_nombre) THEN
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
		CALL fl_lee_grupo_usuario(rm_grp.g04_grupo) RETURNING r_grp.*
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
INPUT rm_usr.g05_usuario, rm_usr.g05_nombres, rm_usr.g05_clave, 
      passwd, rm_usr.g05_tipo, rm_usr.g05_grupo, rm_usr.g05_menu 
      WITHOUT DEFAULTS
      FROM g05_usuario, g05_nombres, g05_clave, clave, g05_tipo, g05_grupo,
	   g05_menu
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_usr.g05_usuario, rm_usr.g05_nombres,
				     rm_usr.g05_grupo, rm_usr.g05_clave, clave ,
				     rm_usr.g05_menu) THEN
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
				LET rm_usr.g05_grupo = grupo
				DISPLAY BY NAME rm_usr.g05_grupo
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
		CALL fl_lee_usuario(rm_usr.g05_usuario) RETURNING r_user.*
		IF r_user.g05_usuario IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto, 
                                            'Este usuario ya existe.',
                                            'exclamation')
			NEXT FIELD g05_usuario
		END IF
	BEFORE FIELD g05_grupo
			LET grupo = rm_usr.g05_grupo
	AFTER FIELD g05_grupo
		IF rm_usr.g05_grupo IS NULL AND grupo IS NULL THEN
			CONTINUE INPUT 
		END IF
		IF rm_usr.g05_grupo IS NULL AND grupo IS NOT NULL THEN
			CLEAR grupo1
			CONTINUE INPUT
		END IF
		IF grupo <> rm_usr.g05_grupo OR grupo IS NULL THEN
			SELECT g04_grupo, g04_nombre 
				INTO grupo, n_grupo 
				FROM gent004 
				WHERE g04_grupo = rm_usr.g05_grupo
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
		IF rm_usr.g05_usuario = 'FOBOS' THEN
			LET rm_usr.g05_tipo = 'AG'
			DISPLAY BY NAME rm_usr.g05_tipo
			NEXT FIELD g05_grupo
		END IF 
	AFTER FIELD g05_menu
		IF rm_usr.g05_menu IS NOT NULL THEN
			SELECT * INTO r_g54.* FROM gent054
				WHERE g54_proceso = rm_usr.g05_menu
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
		IF rm_usr.g05_clave <> passwd THEN
			CALL fgl_winmessage(vg_producto,
                                            'Ambas contraseñas deben ' ||
                                            'coincidir', 'exclamation')
			INITIALIZE rm_usr.g05_clave TO NULL
			INITIALIZE passwd TO NULL
		        NEXT FIELD g05_clave
		END IF
		IF rm_usr.g05_usuario = 'FOBOS' THEN
			LET rm_usr.g05_tipo = 'AG'
			DISPLAY BY NAME rm_usr.g05_tipo
			NEXT FIELD g05_grupo
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
	      'GE', ' ', rm_usr.g05_usuario

RUN comando

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_compania <> vg_codcia THEN
	CALL fgl_winmessage(vg_producto, 'Combinación compañía/localidad no ' ||
                            'existe ', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
