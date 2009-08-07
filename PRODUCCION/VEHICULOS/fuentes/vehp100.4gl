------------------------------------------------------------------------------
-- Titulo           : vehp100.4gl - Configuración parametros por compañía
-- Elaboracion      : 06-sep-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp100 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS

DEFINE vm_cartera	LIKE gent011.g11_tiporeg
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v00		RECORD LIKE veht000.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp100'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_v00 AT 3,2 WITH 19 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_v00 FROM '../forms/vehf100_1'
DISPLAY FORM f_v00

LET vm_cartera = 'CR'

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v00.* TO NULL
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
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
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
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
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('B') 'Bloquear/Activar'     'Bloquea o activa registro.'
		CALL control_bloquea_activa()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

CLEAR FORM
INITIALIZE rm_v00.* TO NULL

LET rm_v00.v00_estado = 'A'
DISPLAY 'ACTIVO' TO n_estado
LET rm_v00.v00_genera_op  = 'N'
LET rm_v00.v00_gen_aju_op = 'N'
LET rm_v00.v00_dev_mes    = 'N'
LET rm_v00.v00_mespro     = MONTH(TODAY)
LET rm_v00.v00_anopro     = YEAR(TODAY)

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

INSERT INTO veht000 VALUES (rm_v00.*)

LET vm_num_rows    = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
CALL muestra_contadores()
CALL muestra_etiquetas()

CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_v00.v00_estado = 'B' THEN 
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht000 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v00.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF  

CALL lee_datos('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

UPDATE veht000 SET * = rm_v00.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)
DEFINE cia 		LIKE gent001.g01_compania

DEFINE taller		LIKE talt000.t00_compania
DEFINE nom_taller	LIKE gent001.g01_razonsocial
DEFINE est_taller	LIKE talt000.t00_estado

DEFINE entidad		LIKE gent011.g11_tiporeg,
       n_entidad	LIKE gent011.g11_nombre,
       subtipo		LIKE gent012.g12_subtipo,
       n_subtipo	LIKE gent012.g12_nombre

DEFINE r_cia		RECORD LIKE gent001.*
DEFINE r_v00		RECORD LIKE veht000.*
DEFINE r_t00		RECORD LIKE talt000.*
DEFINE r_g12		RECORD LIKE gent012.*

CLEAR FORM

INITIALIZE r_cia.* TO NULL
INITIALIZE r_v00.* TO NULL
INITIALIZE r_t00.* TO NULL
INITIALIZE r_g12.* TO NULL

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON v00_compania, v00_estado, v00_genera_op, v00_gen_aju_op, 
           v00_cia_taller, v00_dias_prof, v00_expi_prof,
	   v00_dias_dev, v00_dev_mes, v00_cart_cred, v00_cart_cif
	ON KEY(F2)
		IF INFIELD(v00_compania) THEN
			CALL fl_ayuda_compania() 
				RETURNING cia 
			IF cia IS NOT NULL THEN
				CALL fl_lee_compania(cia) 
 					RETURNING r_cia.*
				LET rm_v00.v00_compania = cia
				DISPLAY cia TO v00_compania
				DISPLAY r_cia.g01_razonsocial TO n_compania
			END IF	
		END IF
		IF INFIELD(v00_cia_taller) THEN
			CALL fl_ayuda_companias_taller() 
				RETURNING taller, nom_taller 
			IF taller IS NOT NULL THEN
				LET rm_v00.v00_cia_taller = taller
				DISPLAY taller TO v00_cia_taller
				DISPLAY nom_taller TO n_taller
			END IF	
		END IF
		IF INFIELD(v00_cart_cred) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING subtipo, n_subtipo
                        IF subtipo IS NOT NULL THEN
				LET rm_v00.v00_cart_cred = subtipo
				DISPLAY BY NAME rm_v00.v00_cart_cred
				DISPLAY n_subtipo TO n_credito
			END IF
		END IF
		IF INFIELD(v00_cart_cif) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING subtipo, n_subtipo
                        IF subtipo IS NOT NULL THEN
				LET rm_v00.v00_cart_cif = subtipo
				DISPLAY BY NAME rm_v00.v00_cart_cif
				DISPLAY n_subtipo TO n_cif
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER  FIELD v00_compania
		LET rm_v00.v00_compania = GET_FLDBUF(v00_compania)
		CALL fl_lee_compania(rm_v00.v00_compania) RETURNING r_cia.*
		IF r_cia.g01_compania IS NULL THEN
			CLEAR n_compania
		ELSE
			IF r_cia.g01_estado = 'B' THEN
				CLEAR n_compania
			ELSE
				DISPLAY r_cia.g01_razonsocial TO n_compania
			END IF
		END IF
	AFTER  FIELD v00_cia_taller
		LET rm_v00.v00_cia_taller = GET_FLDBUF(v00_cia_taller)
		CALL fl_lee_configuracion_taller(rm_v00.v00_cia_taller)
			RETURNING r_t00.*
		IF r_t00.t00_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_v00.v00_cia_taller)
				RETURNING r_cia.*
			IF r_cia.g01_compania IS NULL THEN
				CLEAR n_taller
			ELSE
				IF r_cia.g01_estado = 'B' THEN
					CLEAR n_taller
				ELSE
					DISPLAY r_cia.g01_razonsocial 
						TO n_taller
				END IF
			END IF
		ELSE
			CLEAR n_taller
		END IF
	AFTER  FIELD v00_cart_cred
		LET rm_v00.v00_cart_cred = GET_FLDBUF(v00_cart_cred)
		CALL fl_lee_subtipo_entidad(vm_cartera, rm_v00.v00_cart_cred)
			RETURNING r_g12.*
		IF r_g12.g12_subtipo IS NULL THEN
			CLEAR n_credito
		ELSE
			DISPLAY r_g12.g12_nombre TO n_credito
		END IF
	AFTER  FIELD v00_cart_cif
		LET rm_v00.v00_cart_cif = GET_FLDBUF(v00_cart_cif)
		CALL fl_lee_subtipo_entidad(vm_cartera, rm_v00.v00_cart_cif)
			RETURNING r_g12.*
		IF r_g12.g12_subtipo IS NULL THEN
			CLEAR n_cif
		ELSE
			DISPLAY r_g12.g12_nombre TO n_cif
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM veht000 WHERE ', expr_sql, 
            ' ORDER BY 1' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v00.*, vm_rows[vm_num_rows]
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
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE cia 		LIKE gent001.g01_compania

DEFINE taller		LIKE talt000.t00_compania
DEFINE nom_taller	LIKE gent001.g01_razonsocial
DEFINE est_taller	LIKE talt000.t00_estado

DEFINE r_cia		RECORD LIKE gent001.*
DEFINE r_v00		RECORD LIKE veht000.*
DEFINE r_g12		RECORD LIKE gent012.*

DEFINE entidad		LIKE gent011.g11_tiporeg,
       n_entidad	LIKE gent011.g11_nombre,
       subtipo          LIKE gent012.g12_subtipo,
       n_subtipo        LIKE gent012.g12_nombre


INITIALIZE r_cia.* TO NULL
INITIALIZE r_v00.* TO NULL
INITIALIZE r_g12.* TO NULL

LET INT_FLAG = 0
INPUT BY NAME rm_v00.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(v00_compania, v00_genera_op,
                                     v00_gen_aju_op, v00_cia_taller,
                                     v00_dias_prof,
                                     v00_expi_prof, v00_dias_dev,
                                     v00_dev_mes, v00_cart_cred,
                                     v00_cart_cif) THEN
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
		IF INFIELD(v00_compania) THEN
			CALL fl_ayuda_compania() 
				RETURNING cia 
			IF cia IS NOT NULL THEN
				CALL fl_lee_compania(cia) 
 					RETURNING r_cia.*
				LET rm_v00.v00_compania = cia
				DISPLAY cia TO v00_compania
				DISPLAY r_cia.g01_razonsocial TO n_compania
			END IF	
		END IF
		IF INFIELD(v00_cia_taller) THEN
			CALL fl_ayuda_companias_taller() 
				RETURNING taller, nom_taller 
			IF taller IS NOT NULL THEN
				LET rm_v00.v00_cia_taller = taller
				DISPLAY taller TO v00_cia_taller
				DISPLAY nom_taller TO n_taller
			END IF	
		END IF
		IF INFIELD(v00_cart_cred) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING subtipo, n_subtipo
                        IF subtipo IS NOT NULL THEN
				LET rm_v00.v00_cart_cred = subtipo
				DISPLAY BY NAME rm_v00.v00_cart_cred
				DISPLAY n_subtipo TO n_credito
			END IF
		END IF
		IF INFIELD(v00_cart_cif) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING subtipo, n_subtipo
                        IF subtipo IS NOT NULL THEN
				LET rm_v00.v00_cart_cif = subtipo
				DISPLAY BY NAME rm_v00.v00_cart_cif
				DISPLAY n_subtipo TO n_cif
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE FIELD v00_compania
		IF flag = 'M' THEN
			NEXT FIELD v00_genera_op
		END IF
	AFTER  FIELD v00_compania 
		IF rm_v00.v00_compania IS NULL THEN
			CLEAR n_compania
		ELSE
			CALL fl_lee_compania_vehiculos(rm_v00.v00_compania)
				RETURNING r_v00.*
			IF r_v00.v00_compania IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto, 'Ya se han' ||
					    ' ingresado parámetros para ' ||
                                            'esta compañía.', 'exclamation')
				NEXT FIELD v00_compania
			END IF
			CALL fl_lee_compania(rm_v00.v00_compania) 
				RETURNING r_cia.*
			IF r_cia.g01_compania IS NULL THEN	
				CLEAR n_compania
				CALL fgl_winmessage(vg_producto,
					            'Compañía no existe.',
						    'exclamation')
				NEXT FIELD v00_compania
			ELSE
				IF r_cia.g01_estado = 'B' THEN
					CLEAR n_compania
					CALL fgl_winmessage(vg_producto,
						           'Compañía está' ||
                                                           ' bloqueada.',
						    	   'exclamation')
					NEXT FIELD v00_compania
				ELSE
					DISPLAY r_cia.g01_razonsocial 
						TO n_compania
				END IF
			END IF 
		END IF
	AFTER  FIELD v00_genera_op
		IF rm_v00.v00_genera_op = 'N' THEN
			LET rm_v00.v00_gen_aju_op = 'N'
			DISPLAY 'N' TO v00_gen_aju_op
		END IF
	AFTER  FIELD v00_gen_aju_op
		IF rm_v00.v00_genera_op = 'N' THEN
			LET rm_v00.v00_gen_aju_op = 'N'
			DISPLAY 'N' TO v00_gen_aju_op
		END IF
	AFTER  FIELD v00_cia_taller 
		IF rm_v00.v00_cia_taller IS NULL THEN
			CLEAR n_taller
		ELSE
			INITIALIZE taller TO NULL
			SELECT t00_compania, g01_razonsocial, t00_estado
				INTO taller, nom_taller, est_taller 
				FROM talt000, gent001
				WHERE t00_compania = g01_compania
				  AND g01_compania = rm_v00.v00_cia_taller
			IF taller IS NULL THEN	
				CLEAR n_taller
				CALL fgl_winmessage(vg_producto,
					            'Compañía no existe.',
						    'exclamation')
				NEXT FIELD v00_cia_taller
			ELSE
				IF est_taller = 'B' THEN
					CLEAR n_taller
					CALL fgl_winmessage(vg_producto,
						           'Compañía está' ||
                                                           ' bloqueada',
						    	   'exclamation')
					NEXT FIELD v00_cia_taller
				ELSE
					DISPLAY nom_taller TO n_taller
				END IF
			END IF 
		END IF
	AFTER  FIELD v00_cart_cred
		IF rm_v00.v00_cart_cred IS NULL THEN
			CLEAR n_credito
		ELSE
			CALL fl_lee_subtipo_entidad(vm_cartera, 
                                                    rm_v00.v00_cart_cred) 
                                                    	RETURNING r_g12.*
			IF r_g12.g12_subtipo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
                                                    'Cartera no existe',
                                                    'exclamation')
				CLEAR n_credito
				NEXT FIELD v00_cart_cred
			ELSE
				DISPLAY r_g12.g12_nombre TO n_credito
			END IF
		END IF				 	
	AFTER  FIELD v00_cart_cif
		IF rm_v00.v00_cart_cif IS NULL THEN
			CLEAR n_cif
		ELSE
			CALL fl_lee_subtipo_entidad(vm_cartera, 
                                                    rm_v00.v00_cart_cif) 
						    	RETURNING r_g12.*
			IF r_g12.g12_subtipo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
                                                    'Cartera no existe',
                                                    'exclamation')
				CLEAR n_cif
				NEXT FIELD v00_cart_cif
			ELSE
				DISPLAY r_g12.g12_nombre TO n_cif
			END IF
		END IF				 	
END INPUT

END FUNCTION



FUNCTION control_bloquea_activa()

DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	CHAR(1)

LET int_flag = 0
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])
LET resp = 'Yes'
LET mensaje = 'Seguro de bloquear'
IF rm_v00.v00_estado <> 'A' THEN
	LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM veht000 
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_v00.*
	IF status < 0 THEN
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF

	LET estado = 'B'
	IF rm_v00.v00_estado <> 'A' THEN
		LET estado = 'A'
	END IF

	UPDATE veht000 SET v00_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	CLOSE q_del
	WHENEVER ERROR STOP
	LET int_flag = 0 
	
	CALL fl_mensaje_registro_modificado()

	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v00.* FROM veht000 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v00.*
CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 70 

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_etiquetas()

DEFINE nom_compania		LIKE gent001.g01_razonsocial
DEFINE nom_estado		CHAR(9)
DEFINE nom_taller		LIKE gent001.g01_razonsocial
DEFINE nom_credito		LIKE gent012.g12_nombre
DEFINE nom_cif    		LIKE gent012.g12_nombre

DEFINE r_g01			RECORD LIKE gent001.*
DEFINE r_g12			RECORD LIKE gent012.*

CALL fl_lee_compania(rm_v00.v00_compania) RETURNING r_g01.*
LET nom_compania = r_g01.g01_razonsocial

CALL fl_lee_compania(rm_v00.v00_cia_taller) RETURNING r_g01.*
LET nom_taller = r_g01.g01_razonsocial

CALL fl_lee_subtipo_entidad(vm_cartera, rm_v00.v00_cart_cred) RETURNING r_g12.*
LET nom_credito = r_g12.g12_nombre

CALL fl_lee_subtipo_entidad(vm_cartera, rm_v00.v00_cart_cif) RETURNING r_g12.*
LET nom_cif = r_g12.g12_nombre

IF rm_v00.v00_estado = 'A' THEN
	LET nom_estado = 'ACTIVO'
ELSE
	LET nom_estado = 'BLOQUEADO'
END IF

DISPLAY nom_compania TO n_compania
DISPLAY nom_taller   TO n_taller
DISPLAY nom_estado   TO n_estado
DISPLAY nom_credito  TO n_credito
DISPLAY nom_cif      TO n_cif

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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
