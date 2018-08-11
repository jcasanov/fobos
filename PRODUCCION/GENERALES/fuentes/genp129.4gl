------------------------------------------------------------------------------
-- Titulo           : genp129.4gl - Asignacion de procesos a usuarios 
-- Elaboracion      : 31-ago-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun genp129 base GE [usuario]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_usuario		LIKE gent005.g05_usuario
DEFINE rm_par		RECORD 
	usuario		LIKE gent005.g05_usuario,
	n_usuario	LIKE gent005.g05_nombres,
	grupo		LIKE gent005.g05_grupo,
	n_grupo		LIKE gent004.g04_nombre,
	tipo		LIKE gent005.g05_tipo,
	n_tipo		VARCHAR(25)
END RECORD

DEFINE rm_mgr		RECORD LIKE gent005.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 AND num_args() <> 3 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
INITIALIZE vm_usuario TO NULL
IF num_args() = 3 THEN
	LET vm_usuario = arg_val(3)
END IF
LET vg_proceso = 'genp129'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12,
	DELETE KEY F40,
	INSERT KEY F51
OPEN WINDOW w_f1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_f1 FROM '../forms/genf129_1'
DISPLAY FORM f_f1  

CALL setea_botones_f1()

CALL fl_lee_usuario(vg_usuario) RETURNING rm_mgr.*
IF rm_mgr.g05_tipo = 'UF' THEN
	CALL fgl_winmessage(vg_producto,
		'El usuario ' || vg_usuario CLIPPED || 
		' no es un administrador.',
		'stop')
	EXIT PROGRAM
END IF

MENU 'OPCIONES'
	BEFORE MENU
		IF vm_usuario IS NOT NULL THEN
			CALL asigna_modulos()
			EXIT MENU    
		END IF
	COMMAND KEY ('U') 'Usuarios'	'Asigna varios procesos a un usuario.'
		CALL asigna_modulos()
	COMMAND KEY ('P') 'Procesos'    'Asigna un proceso a varios usuarios.'
		CALL asignaProcesoAUsuarios()
	COMMAND KEY ('S') 'Salir'	'Sale del Programa'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION asignaUsuarioAProcesos(modulo, usr)

DEFINE modulo		LIKE gent050.g50_modulo
DEFINE usr		LIKE gent005.g05_usuario
DEFINE cia		LIKE gent001.g01_compania 

DEFINE ra_proc ARRAY[1000] OF RECORD
	check			CHAR(1),
	g54_tipo		CHAR(1),
	g54_proceso		CHAR(15),
	g54_nombre		CHAR(50)
END RECORD

DEFINE i		SMALLINT
DEFINE j		SMALLINT

DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE resp		CHAR(6)
DEFINE modified		CHAR(1)
DEFINE chk		CHAR(1)		-- Guarda el valor anterior de check

DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE salir     	SMALLINT

DEFINE lastkey		SMALLINT

OPEN WINDOW w_imp AT 3,2 WITH 24 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_proc FROM '../forms/genf129_2'
DISPLAY FORM f_proc

CALL setea_botones_f_proc()

LET filas_max  = 1000
LET filas_pant = 10

CALL ingresa_datos('U', modulo, usr) RETURNING modulo, cia, usr
IF INT_FLAG THEN
	CLOSE WINDOW w_imp
	RETURN
END IF

LET query = 'SELECT g54_tipo, g54_proceso, g54_nombre', 
       	    ' FROM gent054 ',
	    ' WHERE g54_modulo LIKE "', modulo, '"',
	    ' ORDER BY 1, 2'
PREPARE prcons2 FROM query
DECLARE q_prcons2 CURSOR FOR prcons2
LET i = 1
FOREACH q_prcons2 INTO ra_proc[i].g54_tipo, ra_proc[i].g54_proceso,
       	               ra_proc[i].g54_nombre 
	LET ra_proc[i].check = 'S'
	IF NOT canAccessProcessInCia(usr, modulo, ra_proc[i].g54_proceso, cia) 
	THEN
		LET ra_proc[i].check = 'N'
	END IF
	LET i = i + 1
	IF i > filas_max THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF

LET salir = 0
WHILE NOT salir
	LET INT_FLAG = 0
	LET modified = 0
	CALL set_count(i)
	INPUT ARRAY ra_proc WITHOUT DEFAULTS FROM ra_proc.*
		ON KEY(INTERRUPT)
			IF NOT modified THEN
				EXIT INPUT		
			END IF

			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso()
				RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1   
				EXIT INPUT 
			END IF
		ON KEY(F7)
			LET INT_FLAG = 0
			CALL addModuleToUser(modulo, usr)
			IF INT_FLAG THEN
				CALL fgl_winmessage(vg_producto, 
                                                    'Le ha dado acceso ' ||
                                                    'total al módulo a ' || usr,
                                                    'exclamation')
			END IF
			LET INT_FLAG = 1
			EXIT INPUT
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT', '')
			--#CALL dialog.keysetlabel('DELETE', '')
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		BEFORE FIELD check 
			LET chk = ra_proc[j].check
		AFTER  FIELD check
			IF chk <> ra_proc[j].check THEN
				LET modified = 1
			END IF
		AFTER INPUT
			LET salir = 1
	END INPUT
	IF INT_FLAG THEN
		--CLOSE WINDOW w_imp
		EXIT WHILE
	END IF

	-- SI SE CONCEDIO O QUITO ALGUN PERMISO AQUI DEBE SER MANEJADO
	LET j = 0
	FOR j = 1 TO i
		IF ra_proc[j].check = 'S' THEN
			CALL grantUserToModuleInCia(usr, modulo, cia)
			CALL grantUserToProcess(usr, modulo, 
                                                ra_proc[j].g54_proceso,
                                       		cia)
		ELSE	
			CALL revokeGrantsToUserInProcess(usr, modulo, 
       		                                         ra_proc[j].g54_proceso,
                                                         cia)
		END IF
	END FOR

END WHILE

CLOSE WINDOW w_imp

END FUNCTION



FUNCTION ingresa_datos(flag, modulo, usr)

DEFINE flag		CHAR(1)
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE cia		LIKE gent001.g01_compania
DEFINE usr              LIKE gent005.g05_usuario
DEFINE usr2             LIKE gent005.g05_usuario

DEFINE nom_modulo 	LIKE gent050.g50_nombre
DEFINE nom_usr		LIKE gent005.g05_nombres
DEFINE nom_cia		LIKE gent001.g01_razonsocial

DEFINE r_cia		RECORD LIKE gent001.*
DEFINE r_usr		RECORD LIKE gent005.*
DEFINE r_mod		RECORD LIKE gent050.*

DEFINE query		VARCHAR(500)
DEFINE campo		VARCHAR(50)
DEFINE tabla		VARCHAR(50)
DEFINE i		SMALLINT
DEFINE resp		CHAR(6)

INITIALIZE cia TO NULL
IF flag = 'P' THEN
	INITIALIZE modulo, usr TO NULL
	CLEAR n_modulo, n_usuario
END IF

CLEAR n_compania

LET INT_FLAG = 0
INPUT modulo, cia, usr WITHOUT DEFAULTS FROM g54_modulo, compania, usuario
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(g54_modulo, usuario, compania) THEN
			RETURN NULL, NULL, NULL
		END IF
	
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN NULL, NULL, NULL
		END IF
	ON KEY(F2)
		IF INFIELD(usuario) AND NOT flag = 'P' THEN
			CALL fl_ayuda_usuarios("A") RETURNING usr2, nom_usr
			IF usr2 IS NOT NULL THEN
				DISPLAY usr2 TO usuario
				LET usr = usr2
				DISPLAY nom_usr TO n_usuario
			END IF
		END IF
		IF INFIELD(compania) AND NOT flag = 'P' THEN
			CALL fl_ayuda_compania() RETURNING cia
			IF cia IS NOT NULL THEN
				DISPLAY cia TO compania
			END IF
		END IF
		IF INFIELD(g54_modulo) THEN
			CALL fl_ayuda_modulos() 
				RETURNING modulo, nom_modulo
			DISPLAY modulo TO g54_modulo
			DISPLAY nom_modulo TO n_modulo
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_botones_f_proc()
		IF flag = 'U' THEN
			CALL fl_lee_usuario(usr)   RETURNING r_usr.*
			DISPLAY r_usr.g05_nombres TO n_usuario
			CALL fl_lee_modulo(modulo) RETURNING r_mod.*
			DISPLAY r_mod.g50_nombre TO n_modulo

			CALL moduleInfo(modulo) RETURNING tabla, campo
			LET query = 'SELECT ' || campo CLIPPED || ' FROM ' || 
				    tabla
			PREPARE stmnt2 FROM query
			DECLARE q_cias CURSOR FOR stmnt2
			LET i = 0 
			FOREACH q_cias INTO cia
				LET i = i + 1
			END FOREACH
			IF i = 0 THEN
				CALL fgl_winmessage(vg_producto, 
					'No hay compañías configuradas para ' ||
					'este módulo.',
					'exclamation')
				RETURN NULL, NULL, NULL
			END IF
			IF i = 1 THEN
				CALL fl_lee_compania(cia) RETURNING r_cia.*
				DISPLAY r_cia.g01_razonsocial TO n_compania
				DISPLAY cia                   TO compania
				RETURN modulo, cia, usr 
			END IF
			INITIALIZE cia TO NULL
		END IF
	BEFORE FIELD g54_modulo
		IF flag = 'U' THEN
			NEXT FIELD compania
		END IF
	AFTER FIELD g54_modulo
		IF modulo IS NOT NULL THEN
			CALL fl_lee_modulo(modulo) RETURNING r_mod.*
			IF r_mod.g50_modulo IS NULL THEN
				CALL FGL_WINMESSAGE(vg_producto, 
                         		            'Módulo no existe', 
                                                    'exclamation')
				CLEAR n_modulo 
				NEXT FIELD g54_modulo
			ELSE 
				DISPLAY r_mod.g50_nombre TO n_modulo
			END IF
		ELSE
			DISPLAY '' TO n_modulo
			INITIALIZE modulo TO NULL
		END IF
		IF rm_mgr.g05_tipo = 'AM' THEN
			SELECT * FROM gent052 WHERE g52_modulo  = modulo
						AND g52_usuario = vg_usuario 
			IF STATUS = NOTFOUND THEN
				CALL fgl_winmessage(vg_producto,
					'El usuario ' || vg_usuario CLIPPED ||
					' no tiene acceso a este módulo.',
					'exclamation')
				NEXT FIELD g54_modulo 
			END IF
		END IF
		IF modulo IS NULL THEN
			NEXT FIELD g54_modulo
		END IF
		IF not flag = 'U' THEN
			EXIT INPUT
		END IF
	BEFORE FIELD usuario   
		IF flag = 'U' THEN
			NEXT FIELD compania
		END IF
	AFTER FIELD usuario 
		IF usr IS NOT NULL THEN
			CALL fl_lee_usuario(usr) RETURNING r_usr.*
			IF r_usr.g05_usuario IS NULL THEN	
				CALL fgl_winmessage(vg_producto, 
                                                    'No existe usuario', 
                                                    'exclamation')
				NEXT FIELD usuario
			ELSE
				IF r_usr.g05_estado <> 'A' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD usuario
				ELSE
					DISPLAY r_usr.g05_nombres
						TO n_usuario
				END IF
			END IF
		ELSE
			DISPLAY '' TO n_usuario
		END IF
	AFTER FIELD compania
		IF cia IS NOT NULL THEN
			CALL fl_lee_compania(cia) RETURNING r_cia.*
			IF r_cia.g01_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
                                                    'No existe compañía', 
                                                    'exclamation')
				CLEAR n_compania
				NEXT FIELD compania
			ELSE
				IF r_cia.g01_estado <> 'A' THEN
					CALL fgl_winmessage(vg_producto, 
                                            	    'Compañía no está activa',
			            		    'exclamation')
					CLEAR n_compania
					NEXT FIELD compania
				ELSE
					DISPLAY r_cia.g01_razonsocial
						TO n_compania
				END IF
			END IF
		ELSE
			DISPLAY '' TO n_compania
		END IF
	AFTER INPUT
		IF flag = 'U' THEN
			IF cia IS NULL OR usr IS NULL THEN
				NEXT FIELD usuario	
			END IF
			IF NOT ciaIsInModule(cia, modulo) THEN
				CALL fgl_winmessage(vg_producto,
						    'La compañía no tiene ' ||
						    'acceso al módulo',
                                                    'exclamation')
				CONTINUE INPUT
			END IF	
		END IF
END INPUT

RETURN modulo, cia, usr

END FUNCTION



FUNCTION asignaProcesoAUsuarios()

DEFINE ra_proc ARRAY[1000] OF RECORD
	check			CHAR(1),
	g54_tipo		CHAR(1),
	g54_proceso		CHAR(15),
	g54_nombre		CHAR(50)
END RECORD

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE ind		SMALLINT
DEFINE salir		SMALLINT

DEFINE query		CHAR(500)	## Contiene todo el query preparado

DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla

DEFINE modulo		LIKE gent050.g50_modulo
define cia		like gent001.g01_compania
define usr		like gent005.g05_usuario

LET filas_max  = 1000
LET filas_pant = 10

OPEN WINDOW w_imp AT 3,2 WITH 24 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_proc FROM '../forms/genf129_2'
DISPLAY FORM f_proc

CALL setea_botones_f_proc()

WHILE TRUE
	LET int_flag = 0
	CALL ingresa_datos('P', modulo, usr) returning modulo, cia, usr
	IF int_flag THEN
		CLOSE WINDOW w_imp 
		RETURN 
	END IF
	
	LET query = 'SELECT g54_tipo, g54_proceso, g54_nombre', 
                    ' FROM gent054 ',
	            ' WHERE g54_modulo LIKE "', modulo, '"',
		    ' ORDER BY 1, 2'
	PREPARE prcons FROM query
	DECLARE q_prcons CURSOR FOR prcons
	LET i = 1
	FOREACH q_prcons INTO ra_proc[i].g54_tipo, ra_proc[i].g54_proceso,
                              ra_proc[i].g54_nombre 
		LET ra_proc[i].check = 'N'
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF

	LET salir = 0
	LET ind = i
	WHILE NOT salir
		CALL set_count(i)
		INPUT ARRAY ra_proc WITHOUT DEFAULTS FROM ra_proc.*
			BEFORE INPUT  
				--#CALL dialog.keysetlabel('ACCEPT', '')
				--#CALL dialog.keysetlabel('INSERT', '')
				--#CALL dialog.keysetlabel('DELETE', '')
			AFTER INPUT  
				CONTINUE INPUT  
			ON KEY(INTERRUPT)
				LET salir = 1
				EXIT INPUT  
			ON KEY(F5)
				CALL usuarios(modulo, ra_proc[i].g54_proceso)
			BEFORE ROW
				LET i = arr_curr()
				LET j = scr_line()
				MESSAGE i, ' de ', ind           
			AFTER FIELD check
				IF ra_proc[i].check = 'S' THEN
					LET ra_proc[i].check = 'N'
					DISPLAY ra_proc[i].* TO ra_proc[j].*
					NEXT FIELD ra_proc[j].check
				END IF
			BEFORE INSERT
				LET i = ind
				EXIT INPUT
			BEFORE DELETE
				LET i = ind
				EXIT INPUT
		END INPUT  
	END WHILE
	FOR i = 1 TO filas_pant
		CLEAR ra_proc[i].*
	END FOR
END WHILE
IF int_flag THEN
	LET INT_FLAG = 0
END IF

CLOSE WINDOW w_imp

END FUNCTION



FUNCTION usuarios(modulo, proceso)

DEFINE modulo		LIKE gent054.g54_modulo
DEFINE proceso		LIKE gent054.g54_proceso
DEFINE compania		LIKE gent001.g01_compania
DEFINE r_cia		RECORD LIKE gent001.*
DEFINE i		SMALLINT

DEFINE r_g55		RECORD LIKE gent055.*

DEFINE query		CHAR(100)

DEFINE chk		CHAR(1)
DEFINE modified	 	CHAR(1)	

DEFINE ra_usu ARRAY[1000] OF RECORD
	chk		CHAR(1),
	usuario		LIKE gent005.g05_usuario
	END RECORD

DEFINE salir		SMALLINT
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE scr_index	SMALLINT	## Posición actual en ra_usu_scr

DEFINE expr_tipo	VARCHAR(100)
DEFINE resp		CHAR(6)

LET filas_max = 1000
LET filas_pant = 10

OPEN WINDOW w_usu AT 7,20 WITH 17 ROWS, 38 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, BORDER, MESSAGE LINE LAST,
                  COMMENT LINE LAST) 

OPEN FORM f_usu FROM '../forms/genf129_3'
DISPLAY FORM f_usu

DISPLAY proceso TO n_proceso

LET INT_FLAG = 0
INPUT compania FROM cia
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(cia) THEN
			EXIT INPUT
		END IF
	
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		CALL fl_ayuda_compania() RETURNING compania
		IF compania IS NOT NULL THEN
			DISPLAY compania TO cia
		END IF
	AFTER FIELD cia
		IF compania IS NOT NULL THEN
			CALL fl_lee_compania(compania) RETURNING r_cia.*
			IF r_cia.g01_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
                                                    'No existe compañía.', 
                                                    'exclamation')
				CLEAR n_cia
				NEXT FIELD cia
			ELSE
				IF r_cia.g01_estado <> 'A' THEN
					CALL fgl_winmessage(vg_producto, 
                                            	    'Compañía no está activa.',
			            		    'exclamation')
					CLEAR n_cia
					NEXT FIELD cia
				ELSE
					DISPLAY r_cia.g01_abreviacion
						TO n_cia
				END IF
			END IF
		ELSE
			CLEAR n_cia
			NEXT FIELD cia
		END IF
	AFTER INPUT
		IF NOT ciaIsInModule(compania, modulo) THEN
			CALL fgl_winmessage(vg_producto,
					    'La compañía no tiene ' ||
					    'acceso al módulo.',
                                            'exclamation')
			CONTINUE INPUT
		END IF	
END INPUT
IF INT_FLAG THEN 
	CLOSE WINDOW w_usu
	RETURN 
END IF

LET r_g55.g55_modulo = modulo
LET r_g55.g55_proceso = proceso
LET r_g55.g55_compania = compania

LET i = 1

LET expr_tipo = ' '
IF rm_mgr.g05_tipo = 'AM' THEN
	LET expr_tipo = ' AND g05_tipo IN ("AM", "UF") '
END IF

LET query = 'SELECT g05_usuario FROM gent005 WHERE g05_estado <> "B" ' || 
	    expr_tipo || ' ORDER BY 1'
PREPARE c_usu FROM query
DECLARE q_usu CURSOR FOR c_usu

FOREACH q_usu INTO ra_usu[i].usuario
	LET r_g55.g55_user = ra_usu[i].usuario

	SELECT * FROM gent055
		WHERE g55_user     = r_g55.g55_user
		  AND g55_compania = r_g55.g55_compania
		  AND g55_modulo   = r_g55.g55_modulo
		  AND g55_proceso  = r_g55.g55_proceso
	IF STATUS = NOTFOUND THEN
		LET ra_usu[i].chk = 'S'
	ELSE
		LET ra_usu[i].chk = 'N'
	END IF

	SELECT * FROM gent053
		WHERE g53_modulo   = r_g55.g55_modulo
		  AND g53_compania = r_g55.g55_compania
		  AND g53_usuario  = r_g55.g55_user
	IF STATUS = NOTFOUND THEN
		LET ra_usu[i].chk = 'N'
	END IF		

	LET i = i + 1
	IF i > 1000 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_usu
	RETURN
END IF

LET salir = 0
WHILE NOT salir
CALL set_count(i)
LET int_flag = 0
LET modified = 0

INPUT ARRAY ra_usu WITHOUT DEFAULTS FROM ra_usu_scr.*
	ON KEY(INTERRUPT)
		IF NOT modified THEN
			EXIT INPUT
		END IF
		
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
			RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel('INSERT', '')
		--#CALL dialog.keysetlabel('DELETE', '')
	BEFORE ROW
		LET j = arr_curr()
	BEFORE FIELD checkbox
		LET chk = ra_usu[j].chk
	AFTER  FIELD checkbox
		IF chk <> ra_usu[j].chk THEN
			LET modified = 1
		END IF
	AFTER INPUT
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	EXIT WHILE
END IF
END WHILE
IF INT_FLAG THEN
	CLOSE WINDOW w_usu
	RETURN
END IF
-- SI SE CONCEDIO O QUITO ALGUN PERMISO AQUI DEBE SER MANEJADO
LET j = 0
FOR j = 1 TO i
	IF ra_usu[j].chk = 'S' THEN
		CALL grantUserToModule(ra_usu[j].usuario, r_g55.g55_modulo)
		CALL grantUserToModuleInCia(ra_usu[j].usuario,
                                            r_g55.g55_modulo,
                                            r_g55.g55_compania)
		CALL grantUserToProcess(ra_usu[j].usuario,
                                        r_g55.g55_modulo,
		           	        r_g55.g55_proceso,
                                        r_g55.g55_compania)
	ELSE	
		CALL revokeGrantsToUserInProcess(ra_usu[j].usuario,
                                                 r_g55.g55_modulo,
					         r_g55.g55_proceso,
                                                 r_g55.g55_compania)
	END IF
END FOR
--------------------------------------------------------------

CLOSE WINDOW w_usu

END FUNCTION



FUNCTION grantUserToModule(usuario, modulo)

DEFINE usuario		LIKE gent005.g05_usuario
DEFINE modulo 		LIKE gent050.g50_modulo

IF usuario IS NULL THEN
	RETURN
END IF
SELECT * FROM gent052 WHERE g52_modulo = modulo AND g52_usuario = usuario
IF STATUS = NOTFOUND THEN
	INSERT INTO gent052 VALUES(modulo, usuario, 'A')
END IF

END FUNCTION



FUNCTION grantUserToModuleInCia(usuario, modulo, cia)

DEFINE usuario		LIKE gent005.g05_usuario
DEFINE modulo 		LIKE gent050.g50_modulo
DEFINE cia		LIKE gent001.g01_compania

DEFINE r_g53		RECORD LIKE gent053.*

LET r_g53.g53_usuario  = usuario
LET r_g53.g53_modulo   = modulo
LET r_g53.g53_compania = cia

IF NOT canAccessModuleInCia(r_g53.g53_usuario, r_g53.g53_modulo,
                            r_g53.g53_compania) THEN
	INSERT INTO gent053 VALUES(r_g53.*)
END IF

END FUNCTION



FUNCTION grantUserToProcess(usuario, modulo, proc, cia)

DEFINE usuario		LIKE gent005.g05_usuario
DEFINE modulo 		LIKE gent050.g50_modulo
DEFINE proc		LIKE gent054.g54_proceso
DEFINE cia		LIKE gent001.g01_compania

DEFINE r_g55		RECORD LIKE gent055.*

LET r_g55.g55_user     = usuario
LET r_g55.g55_modulo   = modulo
LET r_g55.g55_proceso  = proc
LET r_g55.g55_compania = cia

IF NOT canAccessProcessInCia(r_g55.g55_user, r_g55.g55_modulo,
                             r_g55.g55_proceso, r_g55.g55_compania
                            ) THEN
	DELETE FROM gent055 
 		WHERE g55_user     = r_g55.g55_user
                  AND g55_compania = r_g55.g55_compania
                  AND g55_modulo   = r_g55.g55_modulo
                  AND g55_proceso  = r_g55.g55_proceso
END IF

END FUNCTION



FUNCTION revokeGrantsToUserInProcess(usuario, modulo, proc, cia)

DEFINE usuario		LIKE gent005.g05_usuario
DEFINE modulo 		LIKE gent050.g50_modulo
DEFINE proc		LIKE gent054.g54_proceso
DEFINE cia		LIKE gent001.g01_compania

DEFINE r_g55		RECORD LIKE gent055.*

LET r_g55.g55_user     = usuario
LET r_g55.g55_modulo   = modulo
LET r_g55.g55_compania = cia
LET r_g55.g55_proceso  = proc
LET r_g55.g55_usuario  = vg_usuario
LET r_g55.g55_fecing   = fl_current() 

IF canAccessProcessInCia(r_g55.g55_user, r_g55.g55_modulo,
			     r_g55.g55_proceso, r_g55.g55_compania) THEN
	INSERT INTO gent055 VALUES (r_g55.*)
END IF

END FUNCTION



FUNCTION canAccessModuleInCia(usuario, modulo, cia)

DEFINE usuario		LIKE gent005.g05_usuario
DEFINE modulo 		LIKE gent050.g50_modulo
DEFINE cia		LIKE gent001.g01_compania

DEFINE r_g53		RECORD LIKE gent053.*

DEFINE returnValue	SMALLINT

LET r_g53.g53_usuario  = usuario
LET r_g53.g53_modulo   = modulo
LET r_g53.g53_compania = cia

SELECT * FROM gent053
	WHERE g53_usuario  = r_g53.g53_usuario
	  AND g53_modulo   = r_g53.g53_modulo
	  AND g53_compania = r_g53.g53_compania
IF STATUS = NOTFOUND THEN
	LET returnValue = 0
ELSE
	LET returnValue = 1
END IF
RETURN returnValue

END FUNCTION



FUNCTION canAccessProcessInCia(usuario, modulo, proc, cia)

DEFINE usuario		LIKE gent005.g05_usuario
DEFINE modulo 		LIKE gent050.g50_modulo
DEFINE proc		LIKE gent054.g54_proceso
DEFINE cia		LIKE gent001.g01_compania

DEFINE r_g55		RECORD LIKE gent055.*
DEFINE r_g53		RECORD LIKE gent053.*

DEFINE returnValue	SMALLINT

LET r_g55.g55_user     = usuario
LET r_g55.g55_modulo   = modulo
LET r_g55.g55_compania = cia
LET r_g55.g55_proceso  = proc
SELECT * FROM gent055
	WHERE g55_user     = r_g55.g55_user
	  AND g55_compania = r_g55.g55_compania
	  AND g55_modulo   = r_g55.g55_modulo
	  AND g55_proceso  = r_g55.g55_proceso
IF STATUS = NOTFOUND THEN
	LET returnValue = 1
ELSE
	LET returnValue = 0
END IF

LET r_g53.g53_usuario  = usuario
LET r_g53.g53_modulo   = modulo
LET r_g53.g53_compania = cia
SELECT * FROM gent053
	WHERE g53_modulo   = r_g53.g53_modulo
	  AND g53_compania = r_g53.g53_compania
	  AND g53_usuario  = r_g53.g53_usuario
IF STATUS = NOTFOUND THEN
	LET returnValue = 0
END IF	
	
RETURN returnValue

END FUNCTION



FUNCTION addModuleToUser(modulo, usuario)

DEFINE modulo		LIKE gent050.g50_modulo
DEFINE usuario		LIKE gent005.g05_usuario

DEFINE r_g52		RECORD LIKE gent052.*

DEFINE resp		CHAR(6)

CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
	LET r_g52.g52_usuario = usuario
	LET r_g52.g52_modulo  = modulo
	LET r_g52.g52_estado  = 'A'
	SELECT * FROM gent052 
		WHERE g52_usuario = r_g52.g52_usuario
                  AND g52_modulo = r_g52.g52_modulo
	IF STATUS = NOTFOUND THEN
		INSERT INTO gent052 VALUES(r_g52.*)
	END IF
	CALL addInAllCompanies(modulo, usuario)
	LET INT_FLAG = 1 
ELSE
	LET INT_FLAG = 0
END IF

END FUNCTION



FUNCTION addInAllCompanies(modulo, usuario)

DEFINE modulo		LIKE gent050.g50_modulo
DEFINE usuario 		LIKE gent005.g05_usuario
DEFINE cia		LIKE gent001.g01_compania

DEFINE r_g53		RECORD LIKE gent053.*

DEFINE tabla		CHAR(7)
DEFINE campo		CHAR(15)

DEFINE query		CHAR(70)	## Contiene todo el query preparado

CALL moduleInfo(modulo) RETURNING tabla, campo
IF INT_FLAG THEN 
	RETURN
END IF

LET query = 'SELECT ', campo CLIPPED, ' FROM ', tabla
PREPARE cons FROM query
DECLARE q_umc CURSOR FOR cons

FOREACH q_umc INTO cia
	LET r_g53.g53_usuario  = usuario
	LET r_g53.g53_modulo   = modulo
	LET r_g53.g53_compania = cia
	SELECT * FROM gent053 
		WHERE g53_modulo   = r_g53.g53_modulo 
		  AND g53_usuario  = r_g53.g53_usuario
                  AND g53_compania = r_g53.g53_compania
	IF STATUS = NOTFOUND THEN
		INSERT INTO gent053 VALUES(r_g53.*)
	END IF
	CALL grantUserInAllProcesses(modulo, usuario, cia)
END FOREACH

END FUNCTION



FUNCTION grantUserInAllProcesses(modulo, usuario, cia)

DEFINE modulo		LIKE gent050.g50_modulo
DEFINE usuario		LIKE gent005.g05_usuario
DEFINE cia 		LIKE gent001.g01_compania

DEFINE r_g55		RECORD LIKE gent055.*

LET r_g55.g55_usuario  = usuario
LET r_g55.g55_modulo   = modulo
LET r_g55.g55_compania = cia

DELETE FROM gent055 
	WHERE g55_user     = r_g55.g55_usuario 
	  AND g55_modulo   = r_g55.g55_modulo 
	  AND g55_compania = r_g55.g55_compania

END FUNCTION



FUNCTION ciaIsInModule(cia, module)

DEFINE cia		LIKE gent001.g01_compania
DEFINE module		LIKE gent050.g50_modulo

DEFINE tabla		CHAR(7)
DEFINE campo		CHAR(15)

DEFINE query		CHAR(100)
DEFINE flag		CHAR(1)

CALL moduleInfo(module) RETURNING tabla, campo	

LET query = 'SELECT ', campo, ' FROM ', tabla, 
            ' WHERE ', campo, ' = \'', cia, '\''   
PREPARE consult FROM query
DECLARE q_cm CURSOR FOR consult 

LET flag = 0
FOREACH q_cm INTO cia
	LET flag = 1
	EXIT FOREACH
END FOREACH

IF flag THEN
	RETURN TRUE
ELSE
	RETURN FALSE
END IF

END FUNCTION



FUNCTION moduleInfo(modulo)

DEFINE modulo 		LIKE gent050.g50_modulo
DEFINE tabla		CHAR(7)
DEFINE campo		CHAR(15)

INITIALIZE tabla TO NULL
INITIALIZE campo TO NULL

LET INT_FLAG = 0
CASE modulo
	WHEN 'GE' 	-- GENERALES
		LET tabla = 'gent001'
		LET campo = 'g01_compania'
	WHEN 'RE'	-- REPUESTOS
		LET tabla = 'rept000'
		LET campo = 'r00_compania'
	WHEN 'CO'	-- COBRANZAS
		LET tabla = 'cxct000'
		LET campo = 'z00_compania'
	WHEN 'TA'	-- TALLER
		LET tabla = 'talt000'
		LET campo = 't00_compania'
	WHEN 'VE'	-- VEHICULOS
		LET tabla = 'veht000'
		LET campo = 'v00_compania'
	WHEN 'TE'	-- CUENTAS POR PAGAR
		LET tabla = 'cxpt000'
		LET campo = 'p00_compania'
	WHEN 'RO'	-- ROLES
		LET tabla = 'rolt001'
		LET campo = 'n01_compania'
	WHEN 'CB'	-- CONTABILIDAD
		LET tabla = 'ctbt000'
		LET campo = 'b00_compania'
	WHEN 'OC'	-- ???????
		LET tabla = 'ordt000'
		LET campo = 'c00_compania'
	WHEN 'CH'	-- CAJA CHICA
		LET tabla = 'ccht001'
		LET campo = 'h01_compania'
	WHEN 'CG'	-- CAJA GENERAL
		LET tabla = 'cajt000'
		LET campo = 'j00_compania'
	WHEN 'AF'	-- ACTIVOS FIJOS
		LET tabla = 'actt000'
		LET campo = 'a00_compania'
	OTHERWISE
		CALL fgl_winmessage(vg_producto, 
				'Módulo ' || modulo || 'no existe.', 
                                'exclamation')
		LET INT_FLAG = 1
END CASE
	
RETURN tabla, campo

END FUNCTION



FUNCTION setea_botones_f1()
	
DISPLAY 'Módulo'     TO bt_modulo

END FUNCTION



FUNCTION asigna_modulos()

DEFINE resp		CHAR(6)
DEFINE i, j		SMALLINT
DEFINE salir		SMALLINT
DEFINE num_elm		SMALLINT
DEFINE max_rows		SMALLINT
DEFINE r_mod ARRAY[25] OF RECORD
	check		CHAR(1),
	modulo		LIKE gent050.g50_modulo,
	n_modulo	LIKE gent050.g50_nombre 
END RECORD

DEFINE query		VARCHAR(500)
DEFINE chk_ant		CHAR(1)

DEFINE r_g05		RECORD LIKE gent005.*

LET max_rows = 25

INITIALIZE rm_par.* TO NULL

IF vm_usuario IS NOT NULL THEN
	LET rm_par.usuario = vm_usuario
	CALL obtiene_datos()
END IF

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(usuario) THEN
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(usuario) THEN
			CALL fl_ayuda_usuarios("A") RETURNING r_g05.g05_usuario,
							   r_g05.g05_nombres
			IF r_g05.g05_usuario IS NOT NULL THEN
				LET rm_par.usuario   = r_g05.g05_usuario
				LET rm_par.n_usuario = r_g05.g05_nombres
				DISPLAY BY NAME rm_par.usuario, rm_par.n_usuario
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		IF vm_usuario IS NOT NULL THEN
			EXIT INPUT
		END IF
	AFTER FIELD usuario	
		IF rm_par.usuario IS NOT NULL THEN
			CALL fl_lee_usuario(rm_par.usuario) RETURNING r_g05.* 
			IF r_g05.g05_usuario IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Usuario no existe.',
					'exclamation')
				NEXT FIELD usuario
			END IF
			IF r_g05.g05_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto,
					'Usuario está bloqueado.',
					'exclamation')
				NEXT FIELD usuario
			END IF
			IF rm_mgr.g05_tipo = 'AM' THEN
				IF r_g05.g05_tipo = 'AG' THEN
					CALL fgl_winmessage(vg_producto,
						'El usuario ' || 
						vg_usuario CLIPPED ||
						' no puede cambiar permisos ' ||
						'a un administrador general.',
						'exclamation')
					NEXT FIELD usuario
				END IF
			END IF
		END IF
		CALL obtiene_datos()
		DISPLAY BY NAME rm_par.*
END INPUT
IF int_flag THEN
	CLEAR FORM
	CALL setea_botones_f1()
	RETURN
END IF

CASE rm_mgr.g05_tipo
	WHEN 'AM'
		LET query = 'SELECT "S", g50_modulo, g50_nombre ',
			    '	FROM gent050 ',
			    '	WHERE g50_modulo IN (SELECT g52_modulo ',
			    		 	    ' FROM gent052 ',
						    ' WHERE g52_usuario = "',
								vg_usuario,
						    '"  AND g52_estado = "A") ',
			    '	  AND g50_estado = "A" '
	WHEN 'AG'
		LET query = 'SELECT "S", g50_modulo, g50_nombre FROM gent050 ',
			    ' WHERE g50_estado = "A" '
END CASE

PREPARE stmnt1 FROM query
DECLARE q_mod CURSOR FOR stmnt1

LET num_elm = 1
FOREACH q_mod INTO r_mod[num_elm].*
	SELECT * FROM gent052 WHERE g52_modulo  = r_mod[num_elm].modulo
		                AND g52_usuario = rm_par.usuario
				AND g52_estado  = 'A'	
	IF STATUS = NOTFOUND THEN
		LET r_mod[num_elm].check = 'N'
	END IF
	LET num_elm = num_elm + 1
	IF num_elm > max_rows THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM 
	END IF
END FOREACH

LET num_elm = num_elm - 1

IF num_elm = 0 THEN
	CALL fgl_winmessage(vg_producto,
		'El usuario ' || vg_usuario CLIPPED || ' no tiene acceso a ' ||
		'ningún módulo del sistema.',
		'stop')
	EXIT PROGRAM
END IF

BEGIN WORK

LET salir = 0
WHILE NOT salir
	LET int_flag = 0
	CALL set_count(num_elm)
	INPUT ARRAY r_mod WITHOUT DEFAULTS FROM ra_modulo.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ON KEY(F5)
			IF r_mod[i].check = 'N' THEN
				CALL fgl_winmessage(vg_producto,
					'Primero debe darle acceso al módulo.',
					'exclamation')
				CONTINUE INPUT
			END IF
			CALL asignaUsuarioAProcesos(r_mod[i].modulo, 
						    rm_par.usuario)
			LET int_flag = 0
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT', '')
			--#CALL dialog.keysetlabel('DELETE', '')
			--#CALL dialog.keysetlabel('F5', 'Asigna Procesos')
		BEFORE INSERT
			EXIT INPUT
		BEFORE FIELD check
			LET chk_ant = r_mod[i].check
		AFTER  FIELD check
			IF r_mod[i].check <> chk_ant THEN
				IF r_mod[i].check = 'S' THEN
					CALL grantUserToModule(rm_par.usuario,
							       r_mod[i].modulo)
				END IF
				IF r_mod[i].check = 'N' THEN
					CALL revokeAccessToModule(
						rm_par.usuario,
						r_mod[i].modulo
					)
				END IF
			END IF	
		AFTER INPUT
			LET salir = 1
	END INPUT
	IF int_flag THEN
		CLEAR FORM
		CALL setea_botones_f1()
		ROLLBACK WORK
		RETURN
	END IF
END WHILE

COMMIT WORK

CALL fgl_winmessage(vg_producto, 'Proceso realizado OK.', 'exclamation')
CLEAR FORM
CALL setea_botones_f1()

END FUNCTION



FUNCTION obtiene_datos()

DEFINE r_g04		RECORD LIKE gent004.*
DEFINE r_g05		RECORD LIKE gent005.*

CALL fl_lee_usuario(rm_par.usuario)        RETURNING r_g05.*
CALL fl_lee_grupo_usuario(r_g05.g05_grupo) RETURNING r_g04.*

LET rm_par.n_usuario = r_g05.g05_nombres
LET rm_par.grupo     = r_g05.g05_grupo
LET rm_par.n_grupo   = r_g04.g04_nombre
LET rm_par.tipo      = r_g05.g05_tipo

CASE r_g05.g05_tipo
	WHEN 'AG'
		LET rm_par.n_tipo = 'ADMINISTRADOR GENERAL'
	WHEN 'AM'
		LET rm_par.n_tipo = 'ADMINISTRADOR DEL MODULO'
	WHEN 'UF'
		LET rm_par.n_tipo = 'USUARIO FINAL'
END CASE

END FUNCTION



FUNCTION revokeAccessToModule(usuario, modulo)

DEFINE usuario		LIKE gent005.g05_usuario
DEFINE modulo		LIKE gent050.g50_modulo

DELETE FROM gent055 WHERE g55_user   = usuario AND g55_modulo  = modulo
DELETE FROM gent053 WHERE g53_modulo = modulo  AND g53_usuario = usuario
DELETE FROM gent052 WHERE g52_modulo = modulo  AND g52_usuario = usuario

END FUNCTION



FUNCTION setea_botones_f_proc()
	
	DISPLAY 'T.'          TO bt_tipo
	DISPLAY 'Proceso'     TO bt_proceso
	DISPLAY 'Descripción' TO bt_descripcion

END FUNCTION



FUNCTION no_validar_parametros()

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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
