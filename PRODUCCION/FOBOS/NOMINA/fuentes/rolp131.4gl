------------------------------------------------------------------------------
-- Titulo           : rolp131.4gl - Mantenimiento de Casas Comerciales    
-- Elaboracion      : 18-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp131 base modulo compania
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


DEFINE rm_n62		RECORD LIKE rolt062.*
DEFINE rm_par	RECORD 
	n62_cod_almacen		LIKE rolt062.n62_cod_almacen,
	n62_nombre		LIKE rolt062.n62_nombre,
	n62_abreviado		LIKE rolt062.n62_abreviado,
	n62_cod_rubro		LIKE rolt062.n62_cod_rubro,
	n62_usuario		LIKE rolt062.n62_usuario,
	n62_fecing	 	LIKE rolt062.n62_fecing
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'rolp131'

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
OPEN WINDOW w_club AT 3,2 WITH 12 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_club FROM '../forms/rolf131_1'
DISPLAY FORM f_club

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_n62.* TO NULL
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
			CALL control_ingreso()
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
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
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
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

CLEAR FORM
INITIALIZE rm_par.* TO NULL

LET rm_par.n62_usuario = vg_usuario
LET rm_par.n62_fecing  = CURRENT

CALL lee_datos()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

SELECT NVL(MAX(n62_cod_almacen), 0) INTO rm_par.n62_cod_almacen
	FROM rolt062 WHERE n62_compania = vg_codcia
LET rm_par.n62_cod_almacen = rm_par.n62_cod_almacen + 1

INSERT INTO rolt062 VALUES (vg_codcia, rm_par.*)
DISPLAY BY NAME rm_par.n62_cod_almacen

LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM rolt062 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_n62.*
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN
END IF  
WHENEVER ERROR STOP

LET rm_par.n62_cod_almacen = rm_n62.n62_cod_almacen
LET rm_par.n62_nombre      = rm_n62.n62_nombre       
LET rm_par.n62_abreviado   = rm_n62.n62_abreviado  
LET rm_par.n62_cod_rubro   = rm_n62.n62_cod_rubro
LET rm_par.n62_usuario     = rm_n62.n62_usuario
LET rm_par.n62_fecing      = rm_n62.n62_fecing 

CALL lee_datos()
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	FREE  q_upd
	RETURN
END IF 

LET rm_n62.n62_cod_almacen = rm_par.n62_cod_almacen
LET rm_n62.n62_nombre      = rm_par.n62_nombre       
LET rm_n62.n62_abreviado   = rm_par.n62_abreviado
LET rm_n62.n62_cod_rubro   = rm_par.n62_cod_rubro
LET rm_n62.n62_usuario     = rm_par.n62_usuario
LET rm_n62.n62_fecing      = rm_par.n62_fecing 

UPDATE rolt062 SET * = rm_n62.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
FREE  q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		CHAR(6)
DEFINE r_n06		RECORD LIKE rolt006.*

LET INT_FLAG = 0

INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.*) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(n62_cod_rubro) THEN
			CALL fl_ayuda_rubros_generales_roles('DE', 'T', 'T', 
				'N', 'T', 'T') RETURNING r_n06.n06_cod_rubro,
							 r_n06.n06_nombre 
			IF r_n06.n06_cod_rubro IS NOT NULL THEN
				LET rm_par.n62_cod_rubro =
						r_n06.n06_cod_rubro
				DISPLAY BY NAME rm_par.n62_cod_rubro,
						r_n06.n06_nombre
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD n62_cod_rubro
		IF rm_par.n62_cod_rubro IS NULL THEN
			CLEAR n06_nombre
			CONTINUE INPUT
		END IF
		CALL fl_lee_rubro_roles(rm_par.n62_cod_rubro) RETURNING r_n06.*	
		IF r_n06.n06_cod_rubro IS NULL THEN
			CALL fl_mostrar_mensaje('Rubro no existe.', 'exclamation')
			NEXT FIELD n62_cod_rubro
		END IF
		IF r_n06.n06_estado = 'B' THEN
			CALL fl_mostrar_mensaje('Rubro esta bloqueado.', 'exclamation')
			NEXT FIELD n62_cod_rubro
		END IF
		DISPLAY BY NAME rm_par.n62_cod_rubro, r_n06.n06_nombre 	
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE resp 			CHAR(6)
DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_n06			RECORD LIKE rolt006.*
DEFINE r_n62			RECORD LIKE rolt062.*

INITIALIZE rm_par.* TO NULL
CLEAR FORM
LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql ON n62_cod_almacen, n62_nombre, n62_abreviado,
			      n62_cod_rubro, n62_usuario
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(n62_cod_almacen, n62_nombre, 
				     n62_abreviado,   n62_cod_rubro,
				     n62_usuario) 
		THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF infield(n62_cod_almacen) THEN
                        CALL fl_ayuda_casas_comerciales(vg_codcia)
                                RETURNING r_n62.n62_cod_almacen,
					  r_n62.n62_nombre 
                        IF r_n62.n62_cod_almacen IS NOT NULL THEN
                                DISPLAY BY NAME r_n62.n62_cod_almacen,
						r_n62.n62_nombre
                        END IF
                END IF
		IF infield(n62_cod_rubro) THEN
			CALL fl_ayuda_rubros_generales_roles('DE', 'T',
						'T', 'S', 'T', 'T')
				RETURNING r_n06.n06_cod_rubro, 
					  r_n06.n06_nombre 
			IF r_n06.n06_cod_rubro IS NOT NULL THEN
				LET rm_par.n62_cod_rubro =
						r_n06.n06_cod_rubro
				DISPLAY BY NAME rm_par.n62_cod_rubro,
						r_n06.n06_nombre
			END IF
                END IF
                LET int_flag = 0
	AFTER FIELD n62_cod_almacen
		IF rm_par.n62_cod_almacen IS NOT NULL THEN
			CALL fl_lee_casa_comercial(vg_codcia, 
						   rm_par.n62_cod_almacen
						  ) RETURNING r_n62.*	
			IF r_n62.n62_cod_almacen IS NOT NULL THEN
				LET rm_par.n62_cod_almacen = 
					r_n62.n62_cod_almacen
				LET rm_par.n62_nombre      = r_n62.n62_nombre
				DISPLAY BY NAME rm_par.n62_cod_almacen,
						rm_par.n62_nombre
			END IF
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

LET query = 'SELECT *, ROWID FROM rolt062 WHERE n62_compania = ', vg_codcia, 
		' AND ', expr_sql, ' ORDER BY 1, 2' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_n62.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	LET vm_num_rows = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

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



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
DEFINE r_n06		RECORD LIKE rolt006.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_n62.* FROM rolt062 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

LET rm_par.n62_cod_almacen = rm_n62.n62_cod_almacen
LET rm_par.n62_nombre      = rm_n62.n62_nombre       
LET rm_par.n62_abreviado   = rm_n62.n62_abreviado  
LET rm_par.n62_cod_rubro   = rm_n62.n62_cod_rubro
LET rm_par.n62_usuario     = rm_n62.n62_usuario
LET rm_par.n62_fecing      = rm_n62.n62_fecing 

CALL fl_lee_rubro_roles(rm_par.n62_cod_rubro) RETURNING r_n06.*	
DISPLAY BY NAME r_n06.n06_nombre

DISPLAY BY NAME rm_par.*
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 70 

END FUNCTION
