-------------------------------------------------------------------------------
-- Titulo               : actp105.4gl -- Mantenimiento distribucion de activos
--					 fijos por departamentos
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  actp105.4gl base AF compañía 
-- Ultima Correción     : 09-jun-2003
-- Motivo Corrección    : (RCA) Revision y Correccion Aceros 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_detalle ARRAY[40] OF RECORD
		a11_cod_depto	LIKE actt011.a11_cod_depto,	 
		descr_depto	LIKE gent034.g34_nombre,
		a11_porcentaje	LIKE actt011.a11_porcentaje
		END RECORD

DEFINE rm_distribucion	RECORD LIKE actt011.*
DEFINE distribucion	ARRAY[1000] OF INTEGER 
DEFINE vm_indice	INTEGER       
DEFINE vm_num_rows      INTEGER      
DEFINE vm_max_rows      INTEGER     
DEFINE vm_programa      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)
DEFINE vm_max_detalle	INTEGER
DEFINE vm_num_detalle	INTEGER



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
LET vg_proceso = 'actp105'
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
LET vm_max_detalle = 40


OPEN WINDOW wf AT 3,2 WITH 20 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 3, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)

OPEN FORM frm_distribucion FROM '../forms/actf105_1'
DISPLAY FORM frm_distribucion
INITIALIZE rm_distribucion.* TO NULL
CALL setea_botones()
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
		CALL setea_botones()

        COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
                IF vm_num_rows > 0 THEN
                        CALL control_modificacion()
                ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
		CALL setea_botones()


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
			CALL lee_muestra_registro(distribucion[vm_indice])
		END IF
		CALL setea_botones()
		

	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_indice < vm_num_rows THEN
			LET vm_indice = vm_indice + 1 
		END IF	
		CALL lee_muestra_registro(distribucion[vm_indice])
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
		CALL lee_muestra_registro(distribucion[vm_indice])
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



FUNCTION setea_botones()

DISPLAY 'Código' TO tit_col1
DISPLAY 'Departamento' TO tit_col2
DISPLAY 'Porcentaje' TO tit_col3

END FUNCTION



FUNCTION control_consulta()
DEFINE codbien          LIKE actt010.a10_codigo_bien
DEFINE desc_bien        LIKE actt010.a10_descripcion
--DEFINE codigo		LIKE actt002.a02_tipo_act
--DEFINE nombre		LIKE actt002.a02_nombre
DEFINE expr_sql		VARCHAR(600)
DEFINE query		VARCHAR(600)

CLEAR FORM

LET int_flag = 0
INITIALIZE rm_distribucion.* TO NULL
LET rm_distribucion.a11_compania = vg_codcia
CONSTRUCT BY NAME expr_sql ON a11_codigo_bien 
	BEFORE CONSTRUCT
		CALL setea_botones()

	ON KEY(INTERRUPT)
		CLEAR FORM
		RETURN
            
	ON KEY(F2)
		IF INFIELD(a11_codigo_bien) THEN
			CALL fl_ayuda_codigo_bien(vg_codcia, NULL, NULL, 'T', 0)
				RETURNING codbien, desc_bien
                        IF codbien IS NOT NULL THEN
--                                LET a11_codigo_bien = codbien
--                                DISPLAY BY NAME a11_codigo_bien
				DISPLAY codbien   TO a11_codigo_bien
                                DISPLAY desc_bien TO descr_bien
                        END IF
			LET int_flag = 0
		END IF

END CONSTRUCT

IF int_flag THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(distribucion[vm_indice])
	END IF
	RETURN
END IF
LET query = 'SELECT UNIQUE a11_codigo_bien ',
		' FROM actt011 ',
		' WHERE a11_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 1'
PREPARE cons FROM query
DECLARE q_des CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_des INTO distribucion[vm_num_rows]
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
CALL lee_muestra_registro(distribucion[vm_indice])

END FUNCTION



FUNCTION control_ingreso()
DEFINE 	i  		SMALLINT

OPTIONS INPUT WRAP, ACCEPT KEY F12
CLEAR FORM
INITIALIZE rm_distribucion.* TO NULL
LET vm_flag_mant       = 'I'
LET rm_distribucion.a11_compania = vg_codcia

CALL lee_datos()
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(distribucion[vm_indice])	
	END IF
	RETURN
END IF

LET vm_num_detalle = 0
CALL control_ingresa_detalle()
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(distribucion[vm_indice])	
	END IF
	RETURN
END IF

FOR i = 1 TO vm_num_detalle
	IF rm_detalle.a11_cod_depto IS NULL 
		AND rm_detalle.a11_porcentaje IS NULL THEN
		CONTINUE FOR
	END IF
	INSERT INTO actt011 VALUES(rm_distribucion.a11_compania, 
				rm_distribucion.a11_codigo_bien,
				rm_detalle[i].a11_cod_depto, 
				rm_detalle[i].a11_porcentaje)
END FOR

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET distribucion[vm_num_rows] = rm_distribucion.a11_codigo_bien
LET vm_indice = vm_num_rows
CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()
END FUNCTION



FUNCTION control_modificacion()
DEFINE	i  SMALLINT


LET vm_flag_mant = 'M'
CALL lee_muestra_registro(distribucion[vm_indice])

WHENEVER ERROR CONTINUE
BEGIN WORK

DECLARE q_up CURSOR FOR 
	SELECT * FROM actt011
		WHERE a11_compania = rm_distribucion.a11_compania
		AND a11_codigo_bien = rm_distribucion.a11_codigo_bien
	FOR UPDATE
OPEN q_up

WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
CALL control_ingresa_detalle()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(distribucion[vm_indice])
	RETURN
END IF
DELETE FROM actt011 
	WHERE a11_compania = rm_distribucion.a11_compania 
		AND a11_codigo_bien = rm_distribucion.a11_codigo_bien

FOR i = 1 TO vm_num_detalle
	IF rm_detalle.a11_cod_depto IS NULL 
		AND rm_detalle.a11_porcentaje IS NULL THEN
		CONTINUE FOR
	END IF
	INSERT INTO actt011 VALUES(rm_distribucion.a11_compania,
				rm_distribucion.a11_codigo_bien,
				rm_detalle[i].a11_cod_depto, 
				rm_detalle[i].a11_porcentaje)
END FOR
COMMIT WORK
CALL fl_mensaje_registro_modificado() 

END FUNCTION


FUNCTION lee_datos()
DEFINE codbien          LIKE actt010.a10_codigo_bien
DEFINE desc_bien        LIKE actt010.a10_descripcion
DEFINE resp		VARCHAR(3)
DEFINE bien		INTEGER

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_distribucion.a11_codigo_bien WITHOUT DEFAULTS
	BEFORE INPUT
		CALL setea_botones()

        ON KEY(INTERRUPT)
		IF field_touched(a11_codigo_bien) THEN
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
		IF INFIELD(a11_codigo_bien) THEN
			CALL fl_ayuda_codigo_bien(vg_codcia, NULL, NULL, 'T', 0)
				RETURNING codbien, desc_bien
                        IF codbien IS NOT NULL THEN
                                LET rm_distribucion.a11_codigo_bien = codbien
                                DISPLAY BY NAME rm_distribucion.a11_codigo_bien
                                DISPLAY desc_bien TO descr_bien
                        END IF
                END IF


END INPUT
 
SELECT COUNT(a11_codigo_bien) INTO bien FROM actt011
	WHERE a11_compania = vg_codcia 
		AND a11_codigo_bien = rm_distribucion.a11_codigo_bien

IF bien > 0 THEN
	CALL fgl_winmessage(vg_producto,
			'Registro ya fue ingresado',
			'exclamation')
	LET int_flag = 1
END IF
END FUNCTION



FUNCTION control_dep_repetido(row)
DEFINE	row	SMALLINT
DEFINE  i	SMALLINT

FOR i = 1 TO row
	IF rm_detalle[i].a11_cod_depto = rm_detalle[row].a11_cod_depto 
	   AND i < row THEN
			
		CALL fgl_winmessage(vg_producto,
			'Ya fue ingresado el departamento',
			'Exclamation')
		RETURN '1' 
	END IF  
END FOR
RETURN '0'  -- Indica que el detalle actual no está repetido

END FUNCTION


FUNCTION control_dep_porc_null()
DEFINE i		SMALLINT
DEFINE vm_num_detalle	SMALLINT

LET vm_num_detalle = arr_count()
FOR i = 1 TO vm_num_detalle
	IF rm_detalle[i].a11_cod_depto IS NULL THEN
		RETURN '1' -- Departamento es Null
	END IF

	IF rm_detalle[i].a11_porcentaje IS NULL THEN
		RETURN '2' -- Porcentaje es Null
	END IF
END FOR
RETURN '0'  -- Porcentajes estan ingresados
END FUNCTION

FUNCTION control_ingresa_detalle()
DEFINE rm_act		RECORD LIKE actt002.*
DEFINE rm_dep		RECORD LIKE gent034.*
DEFINE codigo1		LIKE gent034.g34_cod_depto
DEFINE nombre1		LIKE gent034.g34_nombre
DEFINE suma_porcentaje  LIKE actt011.a11_porcentaje
DEFINE resp		VARCHAR(9)
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE ok		CHAR(1)  -- Controla departamento repetido y
DEFINE dep_porc_null	CHAR(1)	 -- Controla si departamento y porcentaje 
				 -- es NULL

IF vm_flag_mant = 'I' THEN
	INITIALIZE rm_detalle[1].* TO NULL
END IF

LET i = 1
LET j = 1
CALL set_count(vm_num_detalle)
LET int_flag = 0
INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.* 
        BEFORE INPUT
		CALL setea_botones()

	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()

	ON KEY(INTERRUPT)
                LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso()
                RETURNING resp
                IF resp = 'Yes' THEN
                   LET int_flag = 1
                   CLEAR FORM
                   RETURN
		END IF

	ON KEY(F2)
		IF infield(a11_cod_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia) 
			     RETURNING codigo1, nombre1
			IF codigo1 IS NOT NULL THEN
				LET rm_detalle[i].a11_cod_depto = codigo1 
				DISPLAY codigo1 TO rm_detalle[j].a11_cod_depto
				DISPLAY nombre1 TO rm_detalle[j].descr_depto
			END IF 
		END IF


	AFTER FIELD a11_cod_depto
		
		IF rm_detalle[i].a11_cod_depto IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia, 
						rm_detalle[i].a11_cod_depto) 
				RETURNING rm_dep.*
			IF rm_dep.g34_cod_depto IS NOT NULL THEN
				LET rm_detalle[i].a11_cod_depto = 
						rm_dep.g34_cod_depto
				LET rm_detalle[i].descr_depto = 
						rm_dep.g34_nombre   
				DISPLAY rm_dep.g34_nombre TO 
						rm_detalle[j].descr_depto
			ELSE
				CALL fgl_winmessage(vg_producto,
						'No existe departamento',
						'Exclamation')
				NEXT FIELD a11_cod_depto
			END IF
			LET ok = '0'
			LET i = arr_curr()
			CALL control_dep_repetido(i) RETURNING ok

			-- Si ok retorna '1', entonces el código del 
			-- departamento está repetido
 			IF ok = '1' THEN
				NEXT FIELD a11_cod_depto
			END IF
		END IF

	AFTER FIELD a11_porcentaje
		LET vm_num_detalle = arr_count() 
		CALL control_suma_porcentaje() RETURNING suma_porcentaje
--OJO
                IF suma_porcentaje <> 100  THEN
                        CALL fgl_winmessage(vg_producto,
                                'El porcentaje total debe de ser 100%',
                                'exclamation')
                        NEXT FIELD a11_cod_depto
                END IF

	AFTER INPUT
		LET vm_num_detalle = arr_count()
		CALL control_suma_porcentaje() RETURNING suma_porcentaje
		IF suma_porcentaje <> 100  THEN
			CALL fgl_winmessage(vg_producto, 
				'El porcentaje total debe de ser 100%', 
				'exclamation')
			NEXT FIELD a11_cod_depto
		END IF
		LET dep_porc_null = '0'
		CALL control_dep_porc_null() RETURNING dep_porc_null
		IF dep_porc_null = '2' THEN
			CALL fgl_winmessage(vg_producto,
					'Debe ingresar porcentaje',
					'exclamation')
			CONTINUE INPUT
		END IF
		IF dep_porc_null = '1' THEN
			CALL fgl_winmessage(vg_producto,
					'Debe ingresar departamento',
					'exclamation')
		
			CONTINUE INPUT
		END IF

	AFTER ROW
		LET vm_num_detalle = arr_count() 
		CALL control_suma_porcentaje() RETURNING suma_porcentaje
END INPUT

END FUNCTION

FUNCTION control_suma_porcentaje()
DEFINE porcentaje	LIKE actt011.a11_porcentaje
DEFINE i		SMALLINT

LET porcentaje = 0
LET vm_num_detalle = arr_count()
FOR i = 1 TO vm_num_detalle
	IF rm_detalle[i].a11_porcentaje IS NOT NULL THEN	
		LET porcentaje = porcentaje + rm_detalle[i].a11_porcentaje
	ELSE		
	END IF
END FOR
DISPLAY porcentaje TO total
RETURN porcentaje	
END FUNCTION


FUNCTION lee_muestra_registro(codigo_bien)
DEFINE codigo_bien      LIKE actt011.a11_codigo_bien
DEFINE suma_porcentaje	LIKE actt011.a11_porcentaje
DEFINE rm_act		RECORD LIKE actt002.*                                                                               
IF vm_num_rows < 1 THEN
        CLEAR FORM
        RETURN
END IF

DECLARE q_dis1 CURSOR FOR
	 SELECT * FROM actt011 WHERE a11_codigo_bien = codigo_bien  

OPEN q_dis1

IF STATUS = NOTFOUND THEN
        CALL fgl_winmessage(vg_producto, 'No existe registro', 'exclamation')
	CLOSE q_dis1
	RETURN
END IF

CLOSE q_dis1
LET rm_distribucion.a11_codigo_bien = codigo_bien
DISPLAY codigo_bien TO a11_codigo_bien  
CALL fl_lee_tipo_activo(rm_distribucion.a11_compania, 
			rm_distribucion.a11_codigo_bien) 
			RETURNING rm_act.*

IF rm_act.a02_tipo_act IS NOT NULL THEN
	DISPLAY rm_act.a02_nombre TO descr_bien
END IF

CALL muestra_contadores()
CALL control_muestra_detalle()
CALL control_suma_porcentaje() RETURNING suma_porcentaje

END FUNCTION



FUNCTION control_muestra_detalle()
DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT


LET filas_pant = fgl_scr_size('rm_detalle') -- de la forma
FOR  i = 1 TO filas_pant
	INITIALIZE  rm_detalle[i].* TO NULL
	CLEAR rm_detalle[i].*
END FOR
 
DECLARE q_detalle CURSOR FOR
	SELECT a11_cod_depto, g34_nombre, a11_porcentaje 	
	FROM actt011, gent034 
	WHERE a11_compania = rm_distribucion.a11_compania AND 
		a11_codigo_bien =  rm_distribucion.a11_codigo_bien AND 
		g34_compania = actt011.a11_compania AND
 		g34_cod_depto = a11_cod_depto

LET i = 1
FOREACH q_detalle INTO rm_detalle[i].*
	LET i = i + 1
	IF i > vm_max_detalle THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	RETURN
END IF
CALL SET_COUNT(i)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
BEFORE DISPLAY 
	CALL setea_botones()
	EXIT DISPLAY
END DISPLAY 

END FUNCTION



                                                                                
FUNCTION muestra_contadores()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_indice, " de ", vm_num_rows AT 1, 69
                                                                                
END FUNCTION

