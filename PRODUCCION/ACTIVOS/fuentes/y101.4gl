
                                                                                
-------------------------------------------------------------------------------
-- Titulo               : actp101.4gl -- Mantenimiento Grupos de Activos Fijos
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  actp101.4gl base GE (compañía) 
-- Ultima Correción     : ?
-- Motivo Corrección    : ? 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '/FOBOS/CLIENTES/DITECA/PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_last_lvl		LIKE ctbt001.b01_nivel
                                                                                
DEFINE rm_activo  RECORD  
	a01_compania 		LIKE actt001.a01_compania,
	a01_grupo_act		LIKE actt001.a01_grupo_act,
	a01_nombre		LIKE actt001.a01_nombre,
	a01_depreciable		LIKE actt001.a01_depreciable,
	a01_anos_util		LIKE actt001.a01_anos_util,
	a01_porc_deprec		LIKE actt001.a01_porc_deprec,
	a01_aux_activo		LIKE actt001.a01_aux_activo,
	a01_aux_reexpr		LIKE actt001.a01_aux_reexpr,
	a01_aux_dep_act		LIKE actt001.a01_aux_dep_act,
	a01_aux_dep_reex	LIKE actt001.a01_aux_dep_reex,
	a01_usuario		LIKE actt001.a01_usuario,
	a01_fecing		LIKE actt001.a01_fecing
	END RECORD


DEFINE activo 		ARRAY[1000] OF INTEGER 
DEFINE vm_indice	SMALLINT       
DEFINE vm_num_rows      SMALLINT      
DEFINE vm_max_rows      SMALLINT     
DEFINE vm_programa      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)


MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 3 THEN   
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vm_programa = 'actp101'
CALL fl_seteos_defaults()
CALL fgl_settitle(vm_programa || ' - ' || vg_producto)
CALL fl_activar_base_datos(vg_base)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vm_programa)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000

OPEN WINDOW wf AT 3,2 WITH 20 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 3, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)

OPEN FORM frm_activo FROM '../forms/actf101_1'
DISPLAY FORM frm_activo
INITIALIZE rm_activo.* TO NULL

INITIALIZE vm_last_lvl TO NULL
SELECT MAX(b01_nivel) INTO vm_last_lvl FROM ctbt001 
IF vm_last_lvl IS NULL THEN
	CALL fgl_winmessage('FOBOS',
		'No se han configurado los niveles de cuenta.',
		'exclamation')
	EXIT PROGRAM
END IF

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
DEFINE codigo		LIKE actt001.a01_grupo_act
DEFINE nombre		LIKE actt001.a01_nombre
DEFINE cuenta    	LIKE ctbt010.b10_cuenta
DEFINE descripcion  	LIKE ctbt010.b10_descripcion
DEFINE expr_sql		VARCHAR(600)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE rm_activo.* TO NULL
CONSTRUCT BY NAME expr_sql ON a01_grupo_act, a01_nombre, 
			      a01_depreciable,  a01_anos_util, 
			      a01_porc_deprec, a01_aux_activo,
			      a01_aux_reexpr, a01_aux_dep_act, 
			      a01_aux_dep_reex, a01_usuario, a01_fecing

	ON KEY(INTERRUPT)
		CLEAR FORM
		RETURN
	
	ON KEY(F2)
		IF infield(a01_grupo_act) THEN
			CALL fl_ayuda_grupo_activo(vg_codcia) 
			     RETURNING codigo, nombre
			IF codigo IS NOT NULL THEN
				LET rm_activo.a01_grupo_act = codigo
				LET rm_activo.a01_nombre = nombre
				DISPLAY BY NAME rm_activo.a01_grupo_act,	
				rm_activo.a01_nombre, rm_activo.a01_depreciable,
                                rm_activo.a01_anos_util, 
				rm_activo.a01_porc_deprec,
				rm_activo.a01_aux_activo, 
				rm_activo.a01_aux_reexpr,
	                        rm_activo.a01_aux_dep_act,
				rm_activo.a01_aux_dep_reex,
				rm_activo.a01_usuario,
				rm_activo.a01_fecing
			END IF 
			LET int_flag = 0
		END IF
	

		IF infield(a01_aux_activo) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_activo.a01_aux_activo = cuenta
				DISPLAY BY NAME rm_activo.a01_aux_activo
				DISPLAY descripcion TO descripcion1
			END IF 
			LET int_flag = 0
		END IF
	
	

		IF infield(a01_aux_reexpr) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_activo.a01_aux_reexpr = cuenta
				DISPLAY BY NAME rm_activo.a01_aux_reexpr
				DISPLAY descripcion TO descripcion2
			END IF
			LET int_flag = 0 
		END IF 


		IF infield(a01_aux_dep_act) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_activo.a01_aux_dep_act = cuenta
				DISPLAY BY NAME rm_activo.a01_aux_dep_act
				DISPLAY descripcion TO descripcion3
			END IF 
			LET int_flag = 0
		END IF 


		IF infield(a01_aux_dep_reex) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_activo.a01_aux_dep_reex = cuenta
				DISPLAY BY NAME rm_activo.a01_aux_dep_reex
				DISPLAY descripcion TO descripcion4
			END IF 
			LET int_flag = 0
		END IF

END CONSTRUCT

IF int_flag THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(activo[vm_indice])
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM actt001  WHERE ', expr_sql CLIPPED,
		' ORDER BY 1'
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
DEFINE maximo SMALLINT

OPTIONS INPUT WRAP, ACCEPT KEY F12
CLEAR FORM
INITIALIZE rm_activo.* TO NULL
LET vm_flag_mant       = 'I'
LET rm_activo.a01_depreciable = 'N'
LET rm_activo.a01_fecing   = CURRENT
LET rm_activo.a01_usuario  = vg_usuario
LET rm_activo.a01_compania = vg_codcia

DISPLAY BY NAME rm_activo.a01_grupo_act,	
	rm_activo.a01_nombre, rm_activo.a01_depreciable,
        rm_activo.a01_anos_util, 
	rm_activo.a01_porc_deprec,
	rm_activo.a01_aux_activo, 
	rm_activo.a01_aux_reexpr,
	rm_activo.a01_aux_dep_act,
	rm_activo.a01_aux_dep_reex,
	rm_activo.a01_usuario,
	rm_activo.a01_fecing


CALL lee_datos()
IF NOT int_flag THEN
	SELECT MAX(a01_grupo_act) INTO maximo FROM actt001 
		WHERE a01_compania = vg_codcia
	IF maximo IS NULL THEN
		LET maximo  = 0
	END IF
	LET rm_activo.a01_grupo_act = maximo + 1 
	LET rm_activo.a01_fecing  = CURRENT
	INSERT INTO actt001 VALUES (rm_activo.*) 
	DISPLAY BY NAME rm_activo.a01_grupo_act,	
			rm_activo.a01_nombre, 
			rm_activo.a01_depreciable,
                	rm_activo.a01_anos_util, 
			rm_activo.a01_porc_deprec,
			rm_activo.a01_aux_activo, 
			rm_activo.a01_aux_reexpr,
	        	rm_activo.a01_aux_dep_act,
			rm_activo.a01_aux_dep_reex,
			rm_activo.a01_usuario,
			rm_activo.a01_fecing

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
	SELECT * FROM actt001 WHERE ROWID = activo[vm_indice]
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
    	UPDATE actt001 SET * = rm_activo.* WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(activo[vm_indice])
END IF
CLOSE q_up

END FUNCTION



FUNCTION lee_datos()
DEFINE   resp      	CHAR(6)
DEFINE   cuenta    	LIKE ctbt010.b10_cuenta
DEFINE   descripcion    LIKE ctbt010.b10_descripcion
DEFINE   vf_cuenta	LIKE ctbt010.b10_cuenta
DEFINE   vf_nivel	LIKE ctbt010.b10_nivel
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_activo.a01_grupo_act, rm_activo.a01_nombre, 
		rm_activo.a01_depreciable, rm_activo.a01_anos_util,
		rm_activo.a01_porc_deprec, rm_activo.a01_aux_activo,
		rm_activo.a01_aux_reexpr, rm_activo.a01_aux_dep_act,
		rm_activo.a01_aux_dep_reex, rm_activo.a01_usuario,
		rm_activo.a01_fecing 

WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		 IF field_touched(a01_grupo_act, a01_nombre, a01_depreciable, 
				  a01_anos_util, a01_porc_deprec, 
				  a01_aux_activo, a01_aux_reexpr,
				  a01_aux_dep_act, a01_aux_dep_reex,
				  a01_usuario, a01_fecing)
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
		IF infield(a01_aux_activo) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_activo.a01_aux_activo = cuenta
				DISPLAY BY NAME rm_activo.a01_aux_activo
			END IF 
		END IF

		IF infield(a01_aux_reexpr) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_activo.a01_aux_reexpr = cuenta
				DISPLAY BY NAME rm_activo.a01_aux_reexpr
			END IF
		END IF 

		IF infield(a01_aux_dep_act) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_activo.a01_aux_dep_act = cuenta
				DISPLAY BY NAME rm_activo.a01_aux_dep_act
			END IF 
		END IF 

		IF infield(a01_aux_dep_reex) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_activo.a01_aux_dep_reex = cuenta
				DISPLAY BY NAME rm_activo.a01_aux_dep_reex
			END IF 
		END IF


	AFTER FIELD a01_nombre
		IF vm_flag_mant = 'M' THEN
			SELECT a01_nombre FROM actt001 
				WHERE a01_nombre =  rm_activo.a01_nombre
				and ROWID <> activo[vm_indice]
		ELSE
			SELECT a01_nombre FROM actt001
				WHERE a01_nombre = rm_activo.a01_nombre
		END IF
		IF status <> NOTFOUND THEN
			CALL fgl_winmessage('PHOBOS', 
					'El nombre está repetido', 'info')
			NEXT FIELD a01_nombre
		END IF


        AFTER FIELD a01_anos_util
		IF rm_activo.a01_depreciable = 'S'  THEN
			LET rm_activo.a01_porc_deprec = 
				(100/rm_activo.a01_anos_util)
				DISPLAY BY NAME rm_activo.a01_porc_deprec
			
		ELSE
			LET rm_activo.a01_anos_util = 9999
			LET rm_activo.a01_porc_deprec = 0.0
			DISPLAY BY NAME rm_activo.a01_anos_util, 
					rm_activo.a01_porc_deprec
			
		END IF


	AFTER FIELD a01_aux_activo
		IF rm_activo.a01_aux_activo IS NOT NULL THEN
			INITIALIZE vf_cuenta, vf_nivel TO NULL
			SELECT b10_cuenta, b10_descripcion, b10_nivel 
			INTO vf_cuenta, descripcion, vf_nivel 
			FROM ctbt010 
			WHERE b10_compania = vg_codcia AND
				b10_cuenta = rm_activo.a01_aux_activo
			IF vf_cuenta IS NULL THEN
				CALL fgl_winmessage('PHOBOS', 
						'No existe esa cuenta.',
						'exclamation')
				NEXT FIELD a01_aux_activo
			ELSE
				DISPLAY descripcion TO descripcion1
			END IF	
			IF vf_nivel <> vm_last_lvl THEN
				CALL fgl_winmessage('PHOBOS',
					'Cuenta debe ser del último nivel.',
					'exclamation')
				NEXT FIELD a01_aux_activo
			END IF
			INITIALIZE vf_cuenta TO NULL
		ELSE
			CLEAR descripcion1
		END IF

	AFTER FIELD a01_aux_reexpr
		IF rm_activo.a01_aux_reexpr IS NOT NULL THEN
			INITIALIZE vf_cuenta, vf_nivel TO NULL
			SELECT b10_cuenta, b10_descripcion, b10_nivel 
				INTO vf_cuenta, descripcion, vf_nivel 
				FROM ctbt010 
				WHERE b10_compania = vg_codcia AND
				      b10_cuenta = rm_activo.a01_aux_reexpr
			IF vf_cuenta IS NULL THEN
				CALL fgl_winmessage('PHOBOS', 
						'No existe esa cuenta',
						'exclamation')
				NEXT FIELD a01_aux_reexpr
			ELSE
				DISPLAY descripcion TO descripcion2
			END IF	
			IF vf_nivel <> vm_last_lvl THEN
				CALL fgl_winmessage('PHOBOS',
					'Cuenta debe ser del último nivel.',
					'exclamation')
				NEXT FIELD a01_aux_activo
			END IF
			INITIALIZE vf_cuenta TO NULL
		ELSE
			CLEAR descripcion2
		END IF


	AFTER FIELD a01_aux_dep_act
		IF rm_activo.a01_aux_dep_act IS NOT NULL THEN
			INITIALIZE vf_cuenta, vf_nivel TO NULL
			SELECT b10_cuenta, b10_descripcion, b10_nivel 
				INTO vf_cuenta, descripcion, vf_nivel 
				FROM ctbt010 
				WHERE b10_compania = vg_codcia AND
				      b10_cuenta = rm_activo.a01_aux_dep_act
			IF vf_cuenta IS NULL THEN
				CALL fgl_winmessage('PHOBOS', 
						'No existe esa cuenta',
						'exclamation')
				NEXT FIELD a01_aux_dep_act
			ELSE
				DISPLAY descripcion TO descripcion3
			END IF	
			IF vf_nivel <> vm_last_lvl THEN
				CALL fgl_winmessage('PHOBOS',
					'Cuenta debe ser del último nivel.',
					'exclamation')
				NEXT FIELD a01_aux_activo
			END IF
			INITIALIZE vf_cuenta TO NULL
		ELSE
			CLEAR descripcion3
		END IF


	AFTER FIELD a01_aux_dep_reex
		IF rm_activo.a01_aux_dep_reex IS NOT NULL THEN
			INITIALIZE vf_cuenta, vf_nivel TO NULL
			SELECT b10_cuenta, b10_descripcion, b10_nivel 
				INTO vf_cuenta, descripcion, vf_nivel 
				FROM ctbt010 
				WHERE b10_compania = vg_codcia AND
				      b10_cuenta = rm_activo.a01_aux_dep_reex
			IF vf_cuenta IS NULL THEN
				CALL fgl_winmessage('PHOBOS', 
						'No existe esa cuenta',
						'exclamation')
				NEXT FIELD a01_aux_dep_reex
			ELSE
				DISPLAY descripcion TO descripcion4
			END IF	
			IF vf_nivel <> vm_last_lvl THEN
				CALL fgl_winmessage('PHOBOS',
					'Cuenta debe ser del último nivel.',
					'exclamation')
				NEXT FIELD a01_aux_activo
			END IF
			INITIALIZE vf_cuenta TO NULL
		ELSE
			CLEAR descripcion4
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows < 1 THEN
	CLEAR FORM
	RETURN
END IF

SELECT * INTO rm_activo.* FROM actt001 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_activo.a01_grupo_act,	
rm_activo.a01_nombre, rm_activo.a01_depreciable,                                rm_activo.a01_anos_util, 
rm_activo.a01_porc_deprec,
rm_activo.a01_aux_activo, 
rm_activo.a01_aux_reexpr,
rm_activo.a01_aux_dep_act,
rm_activo.a01_aux_dep_reex,
rm_activo.a01_usuario,
rm_activo.a01_fecing

CALL muestra_contadores()

END FUNCTION


                                                                                
FUNCTION muestra_contadores()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_indice, " de ", vm_num_rows AT 1, 69
                                                                                
END FUNCTION


