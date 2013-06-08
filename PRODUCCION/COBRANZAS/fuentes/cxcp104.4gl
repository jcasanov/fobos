------------------------------------------------------------------------------
-- Titulo           : cxcp104.4gl - Mantenimiento de Zonas de Cobro
-- Elaboracion      : 02-sep-2001
-- Autor            : RCA
-- Formato Ejecucion: fglrun programa.4gl base modulo
-- Ultima Correccion: 
-- Motivo Correccion:  
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS
DEFINE rm_zoncob	RECORD LIKE cxct006.*
MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cxcp104'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

LET vm_max_rows = 1000
--CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
OPEN WINDOW  w_cia AT 4, 3 WITH FORM '../forms/cxcf104_1'	
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
INITIALIZE rm_zoncob.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'PROCESOS'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registos'
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
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente'
		IF vm_num_rows > 0 THEN
			CALL control_modificacion()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
	COMMAND KEY('C') 'Consultar' 'Consultar un registro'
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
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_row_current < vm_num_rows THEN
			LET vm_row_current = vm_row_current + 1 
		END IF	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		CALL muestra_contadores()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro'
		IF vm_row_current > 1 THEN
			LET vm_row_current = vm_row_current - 1 
		END IF
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		CALL muestra_contadores()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa'
		EXIT MENU
END MENU

END FUNCTION

 
 
FUNCTION control_consulta()
DEFINE zona_cobro	LIKE cxct006.z06_zona_cobro
DEFINE nombre		LIKE cxct006.z06_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON z06_zona_cobro,   z06_nombre, 	
				z06_usuario,	z06_fecing
	ON KEY(F2)
		IF INFIELD(z06_zona_cobro) THEN
			CALL fl_ayuda_zona_cobro()RETURNING zona_cobro, nombre  
			IF zona_cobro IS NOT NULL THEN
				LET rm_zoncob.z06_zona_cobro = zona_cobro
				LET rm_zoncob.z06_nombre     = nombre
				DISPLAY BY NAME rm_zoncob.z06_zona_cobro, rm_zoncob.z06_nombre
			END IF
		END IF
	ON KEY(interrupt)
		RETURN
END CONSTRUCT
IF int_flag THEN
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CALL muestra_contadores()
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM cxct006 WHERE ', expr_sql CLIPPED
PREPARE cons FROM query
DECLARE q_zoncob CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_zoncob INTO rm_zoncob.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
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
CLOSE q_zoncob
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION


  

FUNCTION control_modificacion()
DEFINE     	flag   CHAR(1)

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM cxct006 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_zoncob.*
IF status < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	COMMIT WORK
	RETURN
END IF
CALL ingresa_datos()
IF NOT int_flag THEN
    	UPDATE cxct006 SET * = rm_zoncob.*
		WHERE CURRENT OF q_up
	CALL fl_mensaje_registro_modificado()
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
COMMIT WORK

END FUNCTION

  

FUNCTION control_ingreso()
DEFINE max_zona		LIKE cxct006.z06_zona_cobro
OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_zoncob.* TO NULL
LET rm_zoncob.z06_fecing = CURRENT
LET rm_zoncob.z06_usuario = vg_usuario 
LET rm_zoncob.z06_zona_cobro = 1
DISPLAY BY NAME rm_zoncob.z06_fecing, rm_zoncob.z06_usuario
CALL ingresa_datos()
IF NOT int_flag THEN
      	SELECT MAX(z06_zona_cobro) INTO max_zona FROM cxct006
	IF max_zona IS NOT NULL THEN 
      		LET rm_zoncob.z06_zona_cobro =  max_zona  + 1
	ELSE
		LET max_zona = 1
      		LET rm_zoncob.z06_zona_cobro =  max_zona  
	END IF
      	INSERT INTO cxct006 VALUES (rm_zoncob.*)
	DISPLAY BY  NAME rm_zoncob.z06_zona_cobro
	CALL fl_mensaje_registro_ingresado()
	LET vm_num_rows = vm_num_rows + 1
	LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
CALL muestra_contadores()

END FUNCTION




FUNCTION ingresa_datos()
DEFINE resp   		CHAR(6)
DEFINE zona_cobro	LIKE cxct006.z06_zona_cobro
DEFINE nombre		LIKE cxct006.z06_nombre
DEFINE r		RECORD LIKE cxct006.*

OPTIONS INPUT WRAP
LET int_flag = 0 
DISPLAY BY NAME rm_zoncob.z06_fecing
INPUT BY NAME   rm_zoncob.z06_nombre,
		rm_zoncob.z06_usuario,
		rm_zoncob.z06_fecing
		WITHOUT DEFAULTS                                                           
	ON KEY (INTERRUPT)
		IF field_touched(
 				 rm_zoncob.z06_nombre,
				 rm_zoncob.z06_usuario,
				 rm_zoncob.z06_fecing) THEN
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
            IF INFIELD(z06_zona_cobro) THEN
         	  CALL fl_ayuda_zona_cobro() RETURNING zona_cobro, nombre
                  LET rm_zoncob.z06_zona_cobro = zona_cobro
		  LET rm_zoncob.z06_nombre     = nombre
                  DISPLAY BY NAME rm_zoncob.z06_zona_cobro, rm_zoncob.z06_nombre
            END IF
{ 
	AFTER FIELD z06_zona_cobro
	IF rm_zoncob.z06_zona_cobro IS NOT NULL THEN
		CLEAR rm_zoncob.z06_nombre
		CALL fl_lee_zona_cobro(rm_zoncob.z06_zona_cobro) 
				RETURNING r.*
		IF r.z06_zona_cobro IS NULL THEN
              		CALL fgl_winmessage(vg_producto,'No existe una Zona de Cobro con ese código','exclamation')
			NEXT FIELD z06_zona_cobro
        	END IF   
		LET rm_zoncob.z06_zona_cobro	= zona_cobro
		LET rm_zoncob.z06_nombre	= nombre
        	DISPLAY BY NAME rm_zoncob.z06_zona_cobro, rm_zoncob.z06_nombre
	END IF
} 
END INPUT
                                                                                
END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_zoncob.* FROM cxct006 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_zoncob.*
END FUNCTION



FUNCTION muestra_contadores() 

DISPLAY '' AT 1,1
DISPLAY vm_row_current, ' de ',vm_num_rows AT 1,70

END FUNCTION



FUNCTION no_validar_parametros()

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




