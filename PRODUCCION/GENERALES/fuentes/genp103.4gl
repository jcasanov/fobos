------------------------------------------------------------------------------
-- Titulo           : genp103.4gl - Mantenimiento de Areas de Negocios
-- Elaboracion      : 25-ago-2001
-- Autor            : RCA
-- Formato Ejecucion: fglrun genp103.4gl base GE 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS
DEFINE rm_area		RECORD LIKE gent003.*
DEFINE cod_cia		LIKE gent003.g03_compania
DEFINE cod_area  	LIKE gent003.g03_areaneg

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'genp103'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
LET vg_codloc   = arg_val(4)
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CLEAR SCREEN
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
INITIALIZE rm_area.* TO NULL
LET vm_max_rows = 1000
OPEN WINDOW  w_area AT 4, 3 WITH FORM '../forms/genf103_1'	
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 1)
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'PROCESOS'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros'
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
DEFINE codigo		LIKE gent003.g03_compania
DEFINE codigo_area	LIKE gent003.g03_areaneg
DEFINE desc_area	LIKE gent003.g03_nombre 
DEFINE mcod_aux         LIKE gent050.g50_modulo
DEFINE mnom_aux         LIKE gent050.g50_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE mcod_aux TO NULL
CONSTRUCT BY NAME expr_sql ON  g03_areaneg, g03_nombre, g03_abreviacion,
                               g03_modulo, g03_usuario, g03_fecing
	ON KEY(F2)
            IF INFIELD(g03_areaneg) THEN
		CALL fl_ayuda_areaneg(vg_codcia) RETURNING codigo_area, desc_area
                  IF codigo_area IS NOT NULL THEN
                        LET rm_area.g03_areaneg = codigo_area
                        DISPLAY BY NAME rm_area.g03_areaneg
                  END IF
            END IF
		IF INFIELD(g03_modulo) THEN
                	CALL fl_ayuda_modulos()
	        	        RETURNING mcod_aux, mnom_aux
        	        LET int_flag = 0
           	     IF mcod_aux IS NOT NULL THEN
                        DISPLAY mcod_aux TO g03_modulo
                       	DISPLAY mnom_aux TO tit_modulo
                     END IF
        	END IF
       ON KEY(interrupt)
		--CALL lee_muestra_registro(vm_rows[vm_row_current])
                RETURN
END CONSTRUCT
IF int_flag THEN
      CALL lee_muestra_registro(vm_rows[vm_row_current])
      CALL muestra_contadores()
      RETURN
END IF
LET query = 'SELECT *, ROWID FROM gent003 WHERE g03_compania = ? AND ', 
		expr_sql CLIPPED

PREPARE cons FROM query
DECLARE q_area CURSOR FOR cons
LET vm_num_rows = 1
OPEN q_area USING vg_codcia
WHILE TRUE
	FETCH q_area INTO rm_area.*, vm_rows[vm_num_rows]
	IF STATUS = NOTFOUND THEN
		EXIT WHILE
	END IF
	LET vm_num_rows = vm_num_rows + 1
END WHILE
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
      LET vm_row_current = 0
      CALL muestra_contadores()
      CLEAR FORM
      RETURN
END IF
LET vm_row_current = 1
CLOSE q_area
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION control_ingreso()
DEFINE codigo 	 	SMALLINT
--DEFINE desc_area   	LIKE gent003.g03_nombre
DEFINE max_area     	LIKE gent003.g03_areaneg

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_area.* TO NULL
CLEAR tit_modulo
LET rm_area.g03_fecing = CURRENT
LET rm_area.g03_usuario = vg_usuario
LET rm_area.g03_compania = vg_codcia
DISPLAY BY NAME rm_area.g03_fecing, rm_area.g03_usuario

CALL ingresa_datos()

IF NOT int_flag THEN
      	SELECT MAX(g03_areaneg) INTO max_area FROM gent003
		WHERE g03_compania = vg_codcia
	IF max_area IS NOT NULL THEN
		LET rm_area.g03_areaneg = max_area + 1 
	ELSE
		LET max_area = 0
		LET rm_area.g03_areaneg = max_area
	END IF
     	INSERT INTO gent003 VALUES (rm_area.*)
      	DISPLAY BY NAME rm_area.g03_areaneg
      	IF rm_area.g03_areaneg IS NOT NULL THEN
           	DISPLAY BY NAME rm_area.g03_areaneg, rm_area.g03_nombre
      	END IF
	CALL fl_mensaje_registro_ingresado()
      	LET vm_num_rows = vm_num_rows + 1
      	LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
      	LET vm_row_current = vm_num_rows
END IF
IF vm_num_rows > 0 THEN
      CALL lee_muestra_registro(vm_rows[vm_row_current])
      IF STATUS = NOTFOUND THEN
            CALL fgl_winmessage(vg_producto,'No existe una compañía con ese código','info')
      END IF
END IF
CALL muestra_contadores()

END FUNCTION




FUNCTION control_modificacion()
DEFINE     	flag   CHAR(1)

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM gent003 WHERE ROWID = vm_rows[vm_row_current]
       FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_area.*
IF status < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
      WHENEVER ERROR STOP
      COMMIT WORK
      RETURN
END IF
CALL ingresa_datos()
IF NOT int_flag THEN
      UPDATE gent003 SET * = rm_area.*
           WHERE CURRENT OF q_up
	CALL fl_mensaje_registro_modificado()
      CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
COMMIT WORK

END FUNCTION
 


FUNCTION ingresa_datos()
DEFINE           	resp    CHAR(6)
DEFINE codigo		LIKE gent003.g03_compania
DEFINE mcod_aux         LIKE gent050.g50_modulo
DEFINE mnom_aux         LIKE gent050.g50_nombre
--DEFINE desc_cia		LIKE gent001.g01_razonsocial
--DEFINE cod_ciudad	LIKE gent002.g02_ciudad
--DEFINE desc_ciudad	LIKE gent031.g31_nombre

OPTIONS INPUT WRAP
LET int_flag = 0 
DISPLAY BY NAME rm_area.g03_fecing
INPUT BY NAME  	rm_area.g03_nombre,    rm_area.g03_abreviacion,   
		rm_area.g03_modulo, rm_area.g03_usuario,   rm_area.g03_fecing 
                WITHOUT DEFAULTS 
	ON KEY (INTERRUPT)
           IF field_touched(  	rm_area.g03_nombre, rm_area.g03_abreviacion,  
                              	rm_area.g03_modulo, rm_area.g03_usuario,
			 	rm_area.g03_fecing )
                  THEN
                  LET int_flag =0
		  CALL fl_mensaje_abandonar_proceso()
                       RETURNING resp
                  IF resp = 'Yes' THEN
                        LET int_flag = 1
			CLEAR FORM
                        RETURN
                  END IF
           ELSE
                  RETURN
           END IF
	ON KEY(F2)
		IF INFIELD(g03_modulo) THEN
	                CALL fl_ayuda_modulos()
        	        RETURNING mcod_aux, mnom_aux
                	LET int_flag = 0
         	       IF mcod_aux IS NOT NULL THEN
                	        LET rm_area.g03_modulo = mcod_aux
                        	DISPLAY BY NAME rm_area.g03_modulo
	                        DISPLAY mnom_aux TO tit_modulo
        	        END IF
	        END IF
        AFTER FIELD g03_modulo
               	IF rm_area.g03_modulo IS NOT NULL THEN
                        CALL fl_lee_modulo(rm_area.g03_modulo)
                                RETURNING rg_mod.*
                        IF rg_mod.g50_modulo IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Módulo no exist
e','exclamation')
                                NEXT FIELD g03_modulo
                        ELSE
                                DISPLAY rg_mod.g50_nombre TO tit_modulo
                        END IF
                ELSE
                        CLEAR tit_modulo
                END IF

END INPUT
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
IF rg_loc.g02_compania <> vg_codcia THEN
	CALL fgl_winmessage(vg_producto, 'Combinación compañía/localidad no existe ', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE desc_area        LIKE gent003.g03_nombre

IF vm_num_rows <= 0 OR num_row <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_area.* FROM gent003 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_area.g03_nombre THRU rm_area.g03_fecing
IF rm_area.g03_areaneg IS NOT NULL THEN
       SELECT g03_nombre INTO desc_area FROM gent003 
              WHERE g03_compania = rm_area.g03_compania 
		AND g03_areaneg = rm_area.g03_areaneg 

       IF STATUS = NOTFOUND THEN
              CALL fgl_winmessage(vg_producto,'No existe una area de negocios con ese código','info')
              CLEAR desc_loc
        END IF   
        DISPLAY BY NAME rm_area.g03_areaneg, rm_area.g03_nombre,
			rm_area.g03_abreviacion, rm_area.g03_modulo
	CALL fl_lee_modulo(rm_area.g03_modulo) RETURNING rg_mod.*
        DISPLAY rg_mod.g50_nombre TO tit_modulo
END IF

END FUNCTION



FUNCTION muestra_contadores() 

DISPLAY '' AT 1,1
DISPLAY vm_row_current,' de ', vm_num_rows AT 1,68

END FUNCTION
