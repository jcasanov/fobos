-------------------------------------------------------------------------------
-- Titulo               : actp103.4gl -- Mantenimiento Responsables de A.F.
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  actp103.4gl base AF compañía 
-- Ultima Correción     : 09-jun-2003
-- Motivo Corrección    : (RCA) Revision y Correccion Aceros 

--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_custodio RECORD
		a03_compania	LIKE actt003.a03_compania,	 
		a03_responsable	LIKE actt003.a03_responsable,
		a03_nombres	LIKE actt003.a03_nombres,
		a03_estado	LIKE actt003.a03_estado,
		a03_ciarol	LIKE actt003.a03_ciarol,
		a03_codrol	LIKE actt003.a03_codrol,
		a03_usuario	LIKE actt003.a03_usuario,
		a03_fecing	LIKE actt003.a03_fecing
		END RECORD

DEFINE custodio		ARRAY[1000] OF INTEGER 
DEFINE vm_indice	INTEGER       
DEFINE vm_num_rows      INTEGER      
DEFINE vm_max_rows      INTEGER     
DEFINE vm_programa      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)


MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
        CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
        EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'actp103'
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

OPEN FORM frm_custodio FROM '../forms/actf103_1'
DISPLAY FORM frm_custodio
INITIALIZE rm_custodio.* TO NULL
LET vm_num_rows = 0
LET vm_indice   = 0
CALL muestra_contadores()
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


        COMMAND KEY('B') 'Bloquear/Activar' 'Activa o bloquea registro corriente. '
                IF vm_num_rows > 0 THEN
                        CALL control_eliminacion()
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
		IF vm_indice <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_indice > 0 THEN
			CALL lee_muestra_registro(custodio[vm_indice])
		END IF

	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_indice < vm_num_rows THEN
			LET vm_indice = vm_indice + 1 
		END IF	
		CALL lee_muestra_registro(custodio[vm_indice])
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
		CALL lee_muestra_registro(custodio[vm_indice])
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
DEFINE codigo		LIKE actt003.a03_responsable
DEFINE nombre		LIKE actt003.a03_nombres
DEFINE codigo1		LIKE rolt030.n30_cod_trab
DEFINE nombre1		LIKE rolt030.n30_nombres
DEFINE codigo3		LIKE actt003.a03_ciarol
DEFINE descripcion	LIKE gent001.g01_razonsocial
DEFINE expr_sql		VARCHAR(600)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE rm_custodio.* TO NULL
CONSTRUCT BY NAME expr_sql ON a03_responsable, a03_nombres, a03_estado, 
			     	a03_ciarol, a03_codrol, a03_usuario, 
				a03_fecing	

	ON KEY(INTERRUPT)
		CLEAR FORM
		RETURN
            
	ON KEY(F2)
		IF infield(a03_responsable) THEN
			CALL fl_ayuda_responsable(vg_codcia) 
			     RETURNING codigo, nombre
			IF codigo IS NOT NULL THEN
				LET rm_custodio.a03_responsable = codigo
				LET rm_custodio.a03_nombres = nombre
				DISPLAY BY NAME rm_custodio.a03_responsable,
						rm_custodio.a03_nombres
			END IF 
			LET int_flag = 0
		END IF


		IF infield(a03_codrol) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
			     RETURNING codigo1, nombre1
			IF codigo1 IS NOT NULL THEN
				LET rm_custodio.a03_codrol = codigo1
				DISPLAY BY NAME rm_custodio.a03_codrol
				DISPLAY nombre1 TO trabajador 
			END IF 
			LET int_flag = 0
		END IF

		IF infield(a03_ciarol) THEN
			CALL fl_ayuda_companias_roles() 
			     RETURNING codigo3, descripcion 
			IF codigo3 IS NOT NULL THEN
				LET rm_custodio.a03_ciarol = codigo3
				DISPLAY BY NAME rm_custodio.a03_ciarol
				DISPLAY descripcion TO compania
			END IF 
			LET int_flag = 0
		END IF

END CONSTRUCT

IF int_flag THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(custodio[vm_indice])
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID ',
		' FROM actt003 ',
		' WHERE a03_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3'
PREPARE cons FROM query
DECLARE q_res CURSOR FOR cons
LET vm_num_rows = 1

FOREACH q_res INTO rm_custodio.*, custodio[vm_num_rows]
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
CALL lee_muestra_registro(custodio[vm_indice])

END FUNCTION



FUNCTION control_ingreso()
DEFINE maximo SMALLINT

OPTIONS INPUT WRAP, ACCEPT KEY F12
CLEAR FORM
INITIALIZE rm_custodio.* TO NULL
LET vm_flag_mant       = 'I'
LET rm_custodio.a03_fecing   = CURRENT
LET rm_custodio.a03_usuario  = vg_usuario
LET rm_custodio.a03_compania = vg_codcia
LET rm_custodio.a03_estado = 'A'
DISPLAY 'ACTIVO' TO estado 
DISPLAY BY NAME rm_custodio.a03_fecing,
		rm_custodio.a03_usuario,
		rm_custodio.a03_estado

CALL lee_datos()
IF NOT int_flag THEN
	SELECT MAX(a03_responsable) INTO maximo FROM actt003 
		WHERE a03_compania = vg_codcia
	IF maximo IS NULL THEN
		LET maximo  = 0
	END IF
	LET rm_custodio.a03_responsable = maximo + 1
	LET rm_custodio.a03_fecing  = CURRENT
	INSERT INTO actt003 VALUES (rm_custodio.*)
	DISPLAY BY NAME rm_custodio.a03_responsable,
			rm_custodio.a03_nombres,
			rm_custodio.a03_estado,
			rm_custodio.a03_ciarol,
			rm_custodio.a03_codrol,
			rm_custodio.a03_usuario,
			rm_custodio.a03_fecing
	
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET custodio[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_indice = vm_num_rows
	CALL muestra_contadores()
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(custodio[vm_indice])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE     	flag   CHAR(1)

LET vm_flag_mant = 'M'

WHENEVER ERROR CONTINUE
BEGIN WORK

DECLARE q_up CURSOR FOR 
	SELECT * FROM actt003 WHERE ROWID = custodio[vm_indice]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_custodio.*

WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE actt003 SET * = rm_custodio.* WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(custodio[vm_indice])
END IF
CLOSE q_up

END FUNCTION

FUNCTION control_eliminacion()
DEFINE     	flag   CHAR(1)

LET vm_flag_mant = 'M'

WHENEVER ERROR CONTINUE
BEGIN WORK

DECLARE q_eli CURSOR FOR 
	SELECT * FROM actt003 WHERE ROWID = custodio[vm_indice]
	FOR UPDATE
OPEN q_eli
FETCH q_eli INTO rm_custodio.*

WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
IF NOT int_flag THEN
	IF rm_custodio.a03_estado='A' THEN
		LET rm_custodio.a03_estado = 'B'
		DISPLAY 'BLOQUEADO' TO estado
	ELSE
		LET rm_custodio.a03_estado = 'A'
		DISPLAY 'ACTIVADO' TO estado
	END IF
	DISPLAY BY NAME rm_custodio.a03_estado	
	UPDATE actt003 SET a03_estado = rm_custodio.a03_estado
		 WHERE CURRENT OF q_eli
	COMMIT WORK
	
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(custodio[vm_indice])
END IF
CLOSE q_eli
END FUNCTION

FUNCTION lee_datos()
DEFINE resp   		CHAR(6)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE rm_rol		RECORD LIKE rolt030.*
DEFINE nombre1		LIKE rolt030.n30_nombres
DEFINE codigo1		LIKE rolt030.n30_cod_trab
DEFINE codigo3		LIKE actt003.a03_ciarol
DEFINE descripcion	LIKE gent001.g01_razonsocial


                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME  	rm_custodio.a03_responsable,
		rm_custodio.a03_nombres,
		rm_custodio.a03_estado,
		rm_custodio.a03_ciarol,
		rm_custodio.a03_codrol,
		rm_custodio.a03_usuario,
		rm_custodio.a03_fecing WITHOUT DEFAULTS

	AFTER FIELD a03_nombres
		IF vm_flag_mant = 'M' THEN
			SELECT a03_nombres FROM actt003 
				WHERE a03_nombres =  rm_custodio.a03_nombres
				and ROWID <> custodio[vm_indice]
		ELSE
			SELECT a03_nombres FROM actt003
				WHERE a03_nombres = rm_custodio.a03_nombres
		END IF
		IF status <> NOTFOUND THEN
			CALL fgl_winmessage('PHOBOS', 
					'El nombre está repetido', 'info')
			NEXT FIELD a03_nombres
		END IF
	
	AFTER FIELD a03_ciarol
		IF rm_custodio.a03_ciarol IS NOT NULL THEN
			CALL fl_lee_compania_roles(rm_custodio.a03_ciarol)
				RETURNING r_n01.*
			IF r_n01.n01_compania IS NULL THEN
				CALL fgl_winmessage('PHOBOS',
						'Companía no existe',
						'exclamation')
				NEXT FIELD a03_ciarol
			ELSE
				CALL fl_lee_compania(rm_custodio.a03_ciarol) 
					RETURNING r_g01.*
				DISPLAY r_g01.g01_razonsocial TO compania
			END IF
		END IF


	AFTER FIELD a03_codrol
		IF rm_custodio.a03_codrol IS NOT NULL AND
		   rm_custodio.a03_ciarol IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(rm_custodio.a03_ciarol, 
				rm_custodio.a03_codrol) RETURNING rm_rol.*
			IF rm_rol.n30_compania IS NULL THEN
				CALL fgl_winmessage('PHOBOS',
						'Trabajador no existe',
						'exclamation')
				NEXT FIELD a03_codrol
			ELSE
				DISPLAY rm_rol.n30_nombres TO trabajador

			END IF
		END IF
	

	
        ON KEY(INTERRUPT)
		 IF field_touched(a03_responsable, a03_nombres, a03_estado, 
				 a03_ciarol, a03_codrol, a03_usuario,
				 a03_fecing)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                                LET int_flag = 1
                                CLEAR FORM
                                RETURN
                        END IF
                ELSE
                        CLEAR FORM
                        RETURN
                END IF 

	ON KEY(F2)
		IF infield(a03_codrol) THEN
			IF rm_custodio.a03_ciarol IS NULL THEN
				CALL fl_ayuda_codigo_empleado(vg_codcia) 
				     RETURNING codigo1, nombre1
			ELSE
				CALL fl_ayuda_codigo_empleado(
							rm_custodio.a03_ciarol) 
				     RETURNING codigo1, nombre1
			END IF
			IF codigo1 IS NOT NULL THEN
				LET rm_custodio.a03_codrol = codigo1
				DISPLAY BY NAME rm_custodio.a03_codrol
				DISPLAY nombre1 TO trabajador
			END IF 
			LET int_flag = 0
		END IF
				
		IF infield(a03_ciarol) THEN
			CALL fl_ayuda_companias_roles() 
			     RETURNING codigo3, descripcion 
			IF codigo3 IS NOT NULL THEN
				LET rm_custodio.a03_ciarol = codigo3
				DISPLAY BY NAME rm_custodio.a03_ciarol
				DISPLAY descripcion TO compania
			END IF 
			LET int_flag = 0
		END IF
		      	
END INPUT
                                                                                
END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE razonsocial	LIKE gent001.g01_razonsocial
DEFINE nombres		LIKE rolt030.n30_nombres

IF vm_num_rows < 1 THEN
	CLEAR FORM
	RETURN
END IF

SELECT * INTO rm_custodio.* FROM actt003 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF

DISPLAY BY NAME rm_custodio.a03_responsable,
		rm_custodio.a03_nombres,
		rm_custodio.a03_estado,
		rm_custodio.a03_ciarol,
		rm_custodio.a03_codrol,
		rm_custodio.a03_usuario,
		rm_custodio.a03_fecing

SELECT g01_razonsocial, n30_nombres INTO razonsocial, nombres
	FROM gent001, rolt030 
	WHERE rolt030.n30_compania = rm_custodio.a03_ciarol
	  AND rolt030.n30_cod_trab = rm_custodio.a03_codrol 
	  AND gent001.g01_compania = rolt030.n30_compania   

DISPLAY razonsocial TO compania
DISPLAY nombres TO trabajador
IF rm_custodio.a03_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO estado
ELSE
	DISPLAY 'BLOQUEADO' TO estado
END IF
CALL muestra_contadores()

END FUNCTION


                                                                                
FUNCTION muestra_contadores()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_indice, " de ", vm_num_rows AT 1, 69
                                                                                
END FUNCTION

