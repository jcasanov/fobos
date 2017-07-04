-------------------------------------------------------------------------------
-- Titulo               : actp102.4gl -- Mantenimiento Tipos de Activos Fijos 
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  actp102.4gl base GE (compañía) 
-- Ultima Correción     : 09-jun-2003
-- Motivo Corrección    : (RCA) Revision y Correccion Aceros 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_activo RECORD
		a02_compania	LIKE actt002.a02_compania,	 
		a02_tipo_act	LIKE actt002.a02_tipo_act,
		a02_nombre	LIKE actt002.a02_nombre,
		a02_grupo_act	LIKE actt002.a02_grupo_act,
		a02_usuario	LIKE actt002.a02_usuario,
		a02_fecing	LIKE actt002.a02_fecing
		END RECORD

DEFINE activo 		ARRAY[1000] OF INTEGER 
DEFINE vm_indice	INTEGER       
DEFINE vm_num_rows      INTEGER      
DEFINE vm_max_rows      INTEGER     
DEFINE vm_programa      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp102.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
        CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
        EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'actp102'
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

OPEN WINDOW wf AT 3,2 WITH 15 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 3, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)

OPEN FORM frm_activo FROM '../forms/actf102_1'
DISPLAY FORM frm_activo
INITIALIZE rm_activo.* TO NULL
LET vm_num_rows = 0
LET vm_indice   = 0
CALL muestra_contadores()
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
		IF vm_indice > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_indice = vm_num_rows THEN
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
		IF vm_indice <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_indice > 0 THEN
			CALL lee_muestra_registro(activo[vm_indice])
		END IF

	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_indice < vm_num_rows THEN
			LET vm_indice = vm_indice + 1 
		END IF	
		CALL lee_muestra_registro(activo[vm_indice])
		IF vm_indice = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF

	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		IF vm_indice > 1 THEN
			LET vm_indice = vm_indice - 1 
		END IF
		CALL lee_muestra_registro(activo[vm_indice])
		IF vm_indice = 1 THEN
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
DEFINE codigo		LIKE actt002.a02_grupo_act
DEFINE nombre		LIKE actt002.a02_nombre
DEFINE codigo1		LIKE actt001.a01_grupo_act
DEFINE nombre1		LIKE actt001.a01_nombre
DEFINE expr_sql		VARCHAR(600)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE rm_activo.* TO NULL
CONSTRUCT BY NAME expr_sql ON a02_tipo_act, a02_nombre, 
			      a02_grupo_act, a02_usuario, a02_fecing

	ON KEY(INTERRUPT)
		CLEAR FORM
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(a02_tipo_act) THEN
			CALL fl_ayuda_tipo_activo(vg_codcia,
						rm_activo.a02_grupo_act)
				RETURNING codigo, nombre
			IF codigo IS NOT NULL THEN
				LET rm_activo.a02_tipo_act = codigo
				LET rm_activo.a02_nombre = nombre
				DISPLAY BY NAME rm_activo.a02_tipo_act,
						rm_activo.a02_nombre
			END IF 
			LET int_flag = 0
		END IF

	
		IF INFIELD(a02_grupo_act) THEN
			CALL fl_ayuda_grupo_activo(vg_codcia) 
			     RETURNING codigo1, nombre1
			IF codigo1 IS NOT NULL THEN
				LET rm_activo.a02_grupo_act = codigo1
				DISPLAY BY NAME rm_activo.a02_grupo_act
				DISPLAY nombre1 TO activo
			END IF 
			LET int_flag = 0
		END IF
	AFTER FIELD a02_grupo_act
		LET rm_activo.a02_grupo_act = GET_FLDBUF(a02_grupo_act)
	
END CONSTRUCT

IF int_flag THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(activo[vm_indice])
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID ',
		' FROM actt002 ',
		' WHERE a02_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2 '
PREPARE cons FROM query
DECLARE q_act CURSOR FOR cons
LET vm_num_rows = 1

FOREACH q_act INTO rm_activo.*, activo[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_indice = 0
	CALL muestra_contadores()
        CLEAR FORM
        RETURN
END IF
LET vm_indice = 1
CALL lee_muestra_registro(activo[vm_indice])

END FUNCTION



FUNCTION control_ingreso()
DEFINE maximo		VARCHAR(5)
DEFINE l		SMALLINT

OPTIONS INPUT WRAP, ACCEPT KEY F12
CLEAR FORM
INITIALIZE rm_activo.* TO NULL
LET vm_flag_mant           = 'I'
LET rm_activo.a02_fecing   = CURRENT
LET rm_activo.a02_usuario  = vg_usuario
LET rm_activo.a02_compania = vg_codcia
DISPLAY BY NAME rm_activo.a02_tipo_act,
		rm_activo.a02_nombre,
		rm_activo.a02_grupo_act,
		rm_activo.a02_usuario,
		rm_activo.a02_fecing

CALL lee_datos()
IF NOT int_flag THEN
	SELECT LPAD(NVL(MAX(a02_tipo_act) + 1, 1), 3, 0)
		INTO maximo
		FROM actt002 
		WHERE a02_compania  = vg_codcia
		  AND a02_grupo_act = rm_activo.a02_grupo_act
	IF maximo[1, 1] = '0' THEN
		LET l      = LENGTH(maximo)
		LET maximo = rm_activo.a02_grupo_act USING "&", maximo[2, l]
	END IF
	LET rm_activo.a02_tipo_act = maximo USING "#####"
	LET rm_activo.a02_fecing   = CURRENT
	INSERT INTO actt002 VALUES (rm_activo.*)
	DISPLAY BY NAME rm_activo.a02_tipo_act,
			rm_activo.a02_nombre,
			rm_activo.a02_grupo_act,
			rm_activo.a02_usuario,
			rm_activo.a02_fecing
	
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET activo[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_indice = vm_num_rows
	CALL muestra_contadores()
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(activo[vm_indice])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE     	flag   CHAR(1)

LET vm_flag_mant = 'M'

WHENEVER ERROR CONTINUE
BEGIN WORK

DECLARE q_up CURSOR FOR 
	SELECT * FROM actt002 WHERE ROWID = activo[vm_indice]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_activo.*

WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF

CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE actt002 SET * = rm_activo.* WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(activo[vm_indice])
END IF
CLOSE q_up

END FUNCTION



FUNCTION lee_datos()
DEFINE nombre1		LIKE actt001.a01_nombre
DEFINE codigo1		LIKE actt001.a01_grupo_act
DEFINE resp		CHAR(6)
DEFINE cuantos		INTEGER
DEFINE query		VARCHAR(250)
DEFINE expr_row		VARCHAR(40)
DEFINE mensaje		VARCHAR(100)
DEFINE vez		VARCHAR(8)

OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME  	rm_activo.a02_tipo_act,
		rm_activo.a02_nombre,
		rm_activo.a02_grupo_act,
		rm_activo.a02_usuario,
		rm_activo.a02_fecing WITHOUT DEFAULTS

	AFTER FIELD a02_nombre
		LET expr_row = NULL
		IF vm_flag_mant = 'M' THEN
			LET expr_row = '   AND ROWID      <> ',activo[vm_indice]
		END IF
		LET query = 'SELECT COUNT(*) FROM actt002 ',
				' WHERE a02_compania = ', vg_codcia,
				'   AND a02_nombre   = "',
						rm_activo.a02_nombre, '"',
				expr_row CLIPPED
		PREPARE sel_r02 FROM query
		DECLARE q_nombre CURSOR FOR sel_r02
		OPEN q_nombre
		FETCH q_nombre INTO cuantos
		CLOSE q_nombre
		FREE q_nombre
		IF cuantos > 0 THEN
			IF cuantos = 1 THEN
				LET vez = ' vez.'
			ELSE
				LET vez = ' veces.'
			END IF
			LET mensaje = 'El nombre esta repetido ',
					cuantos USING "<<<<<", vez CLIPPED
			CALL fgl_winmessage(vg_producto, mensaje, 'info')
			NEXT FIELD a02_nombre
		END IF

	AFTER FIELD a02_grupo_act
		IF rm_activo.a02_grupo_act IS NOT NULL THEN
			SELECT a01_nombre INTO nombre1
			FROM actt001
			WHERE a01_grupo_act = rm_activo.a02_grupo_act
			IF nombre1 IS NOT NULL THEN
				DISPLAY nombre1 TO activo
			ELSE
				CALL fgl_winmessage('PHOBOS', 
					'El código de grupo no existe', 'info')	
				NEXT FIELD a02_grupo_act
			END IF
			INITIALIZE nombre1 TO NULL
		END IF

        ON KEY(INTERRUPT)
		 IF field_touched(a02_tipo_act, a02_nombre, 
				  a02_grupo_act, a02_usuario, a02_fecing)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                                LET int_flag = 1
                                CLEAR FORM
				EXIT INPUT
                        END IF
                ELSE
                        CLEAR FORM
			EXIT INPUT
                END IF 

	ON KEY(F2)
		IF infield(a02_grupo_act) THEN
			CALL fl_ayuda_grupo_activo(vg_codcia) 
			     RETURNING codigo1, nombre1
			IF codigo1 IS NOT NULL THEN
				LET rm_activo.a02_grupo_act = codigo1
				DISPLAY BY NAME rm_activo.a02_grupo_act
				DISPLAY nombre1 TO activo
			END IF 
			LET int_flag = 0
		END IF
		      	
END INPUT
                                                                                
END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE descripcion	LIKE actt001.a01_nombre
IF vm_num_rows < 1 THEN
	CLEAR FORM
	RETURN
END IF

SELECT * INTO rm_activo.* FROM actt002 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF

DISPLAY BY NAME rm_activo.a02_tipo_act,
		rm_activo.a02_nombre,
		rm_activo.a02_grupo_act,
		rm_activo.a02_usuario,
		rm_activo.a02_fecing
SELECT a01_nombre INTO descripcion
	FROM actt001
	WHERE a01_compania  = vg_codcia
	  AND a01_grupo_act = rm_activo.a02_grupo_act
DISPLAY descripcion TO activo	
CALL muestra_contadores()

END FUNCTION


                                                                                
FUNCTION muestra_contadores()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_indice, " de ", vm_num_rows AT 1, 69
                                                                                
END FUNCTION
