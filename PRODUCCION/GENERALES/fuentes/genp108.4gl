------------------------------------------------------------------------------
-- Titulo           : genp108.4gl - Mantenimiento de Tarjetas de Crédito
-- Elaboracion      : 27-ago-2001
-- Autor            : JCM 
-- Formato Ejecucion: fglrun genp108 base modulo
-- Ultima Correccion: 27-ago-2001
-- Motivo Correccion:  
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS

DEFINE rm_tarj		RECORD LIKE gent010.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'genp108'

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
OPEN WINDOW  w_cia AT 4, 3 WITH 14 ROWS, 80 COLUMNS 	
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_imp FROM '../forms/genf108_1'
DISPLAY FORM f_imp

INITIALIZE rm_tarj.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registos'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			--SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro'
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
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  		'Ver anterior registro'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir' 		'Salir del programa'
		EXIT MENU
END MENU

END FUNCTION

 

FUNCTION control_consulta()
DEFINE codigo		LIKE gent010.g10_tarjeta
DEFINE nom_tarjeta	LIKE gent010.g10_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE cod_cobranzas	LIKE cxct001.z01_codcli
DEFINE nom_cliente	LIKE cxct001.z01_nomcli

DEFINE r_cligen		RECORD LIKE cxct001.*
DEFINE r_tarjeta	RECORD LIKE gent010.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON g10_tarjeta, g10_nombre, g10_codcobr, g10_usuario
	ON KEY(F2)
		IF INFIELD(g10_tarjeta) THEN
			CALL fl_ayuda_tarjeta() RETURNING codigo, nom_tarjeta  
			IF codigo IS NOT NULL THEN
				LET rm_tarj.g10_tarjeta = codigo
				LET rm_tarj.g10_nombre  = nom_tarjeta
				DISPLAY BY NAME rm_tarj.g10_tarjeta, 
                                                rm_tarj.g10_nombre
			END IF
		END IF
            	IF INFIELD(g10_codcobr) THEN
         	  	CALL fl_ayuda_cliente_general() 
				RETURNING cod_cobranzas, nom_cliente
			IF cod_cobranzas IS NOT NULL THEN
                  		LET rm_tarj.g10_codcobr = cod_cobranzas
                  		DISPLAY BY NAME rm_tarj.g10_codcobr 
                                DISPLAY BY NAME nom_cliente 
			END IF 
            	END IF
		LET INT_FLAG = 0
	AFTER FIELD g10_tarjeta
		LET rm_tarj.g10_tarjeta = GET_FLDBUF(g10_tarjeta)
		IF rm_tarj.g10_tarjeta IS NULL THEN
			DISPLAY '' TO g10_nombre
		ELSE
			CALL fl_lee_tarjeta_credito(rm_tarj.g10_tarjeta) 
				RETURNING r_tarjeta.*
			IF r_tarjeta.g10_tarjeta IS NULL THEN
				DISPLAY '' TO g10_nombre
        		END IF   
			DISPLAY r_tarjeta.g10_nombre TO g10_nombre
		END IF
	AFTER FIELD g10_codcobr
		LET rm_tarj.g10_codcobr = GET_FLDBUF(g10_codcobr)
		IF rm_tarj.g10_codcobr IS NULL THEN
			CLEAR nom_cliente
		ELSE
			CALL fl_lee_cliente_general(rm_tarj.g10_codcobr) 
				RETURNING r_cligen.*
			IF r_cligen.z01_codcli IS NULL THEN
				CLEAR nom_cliente
        		END IF   
			IF r_cligen.z01_estado = 'B' THEN
				CLEAR nom_cliente
				NEXT FIELD g10_codcobr
			END IF
			DISPLAY r_cligen.z01_nomcli TO nom_cliente
		END IF
END CONSTRUCT

IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	CALL muestra_contadores()
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM gent010 WHERE ', expr_sql, 'ORDER BY 1'  
PREPARE cons FROM query
DECLARE q_tarj CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_tarj INTO rm_tarj.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows = 1000 THEN
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
CLOSE q_tarj
FREE  q_tarj
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

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
	SELECT * FROM gent010 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_tarj.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL lee_datos()

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	FREE  q_upd
	RETURN
END IF 

UPDATE gent010 SET * = rm_tarj.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
FREE  q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION
 


FUNCTION control_ingreso()

CLEAR FORM
INITIALIZE rm_tarj.* TO NULL

LET rm_tarj.g10_fecing = CURRENT
LET rm_tarj.g10_usuario = vg_usuario 

CALL lee_datos()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET rm_tarj.g10_tarjeta = 0
INSERT INTO gent010 VALUES (rm_tarj.*)
LET rm_tarj.g10_tarjeta = SQLCA.SQLERRD[2]	-- Obtiene el numero secuencial 
				        	-- asignado por informix
DISPLAY BY NAME rm_tarj.g10_tarjeta
LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION lee_datos()
DEFINE resp   		CHAR(6)
DEFINE cod_cobranzas	LIKE cxct001.z01_codcli
DEFINE nom_cliente	LIKE cxct001.z01_nomcli
DEFINE r_cligen 	RECORD LIKE cxct001.*

OPTIONS INPUT WRAP
LET int_flag = 0 

INPUT BY NAME 	rm_tarj.* WITHOUT DEFAULTS                                     
	ON KEY (INTERRUPT)
		IF field_touched(rm_tarj.g10_nombre,
				 rm_tarj.g10_codcobr
				) THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
				RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
            	IF INFIELD(g10_codcobr) THEN
         	  	CALL fl_ayuda_cliente_general() 
				RETURNING cod_cobranzas, nom_cliente
                  	LET rm_tarj.g10_codcobr = cod_cobranzas
                 	DISPLAY BY NAME rm_tarj.g10_codcobr, nom_cliente 
            	END IF
	AFTER FIELD g10_codcobr
		IF rm_tarj.g10_codcobr IS NULL THEN
			CLEAR nom_cliente
		ELSE
			CALL fl_lee_cliente_general(rm_tarj.g10_codcobr) 
				RETURNING r_cligen.*
			IF r_cligen.z01_codcli IS NULL THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'No existe un cliente '||
                                                    'con ese código',
                                                    'exclamation')
				CLEAR nom_cliente
				NEXT FIELD g10_codcobr
        		END IF   
			IF r_cligen.z01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				CLEAR nom_cliente
				NEXT FIELD g10_codcobr
			END IF
			LET rm_tarj.g10_codcobr	= r_cligen.z01_codcli
        		DISPLAY BY NAME rm_tarj.g10_codcobr
			DISPLAY r_cligen.z01_nomcli TO nom_cliente
		END IF
END INPUT
                                                                                
END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_tarj.* FROM gent010 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_tarj.*
CALL muestra_contadores()

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



FUNCTION muestra_contadores() 

DISPLAY '' AT 1,1
DISPLAY vm_row_current, ' de ',vm_num_rows AT 1,70

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION




