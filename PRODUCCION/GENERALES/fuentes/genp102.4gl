------------------------------------------------------------------------------
-- Titulo           : genp102.4gl - Mantenimiento de Localidades
-- Elaboracion      : 10-ago-2001
-- Autor            : RCA
-- Formato Ejecucion: fglrun genp102.4gl base GE compania 
-- Ultima Correccion: 21-ago-2001
-- Motivo Correccion: Estandarización 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_ciu		RECORD LIKE gent031.*
DEFINE cod_cia		LIKE gent002.g02_compania
DEFINE cod_loc  	LIKE gent002.g02_localidad

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'genp102'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
INITIALIZE rm_loc.* TO NULL
LET vm_max_rows = 1000
OPEN WINDOW  w_loc AT 4, 3 WITH FORM '../forms/genf102_1'	
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
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros'
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
	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear Agencias'
            CALL control_bloqueo()
	COMMAND KEY('S') 'Salir' 'Salir del programa'
            EXIT MENU
END MENU

END FUNCTION


FUNCTION control_consulta()
DEFINE codigo		LIKE gent002.g02_compania
DEFINE codigo_loc	LIKE gent002.g02_localidad
DEFINE desc_loc		LIKE gent002.g02_nombre
DEFINE cod_ciudad	LIKE gent002.g02_ciudad
DEFINE desc_ciudad	LIKE gent031.g31_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE pais		LIKE gent031.g31_pais

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON  g02_localidad, g02_nombre, g02_abreviacion ,
                               g02_estado,    g02_numruc, g02_ciudad, 
                               g02_correo,    g02_direccion, g02_telefono1,
                               g02_telefono2, g02_fax1 ,  g02_fax2, 	
                               g02_casilla,   g02_matriz, g02_numaut_sri, 
			       g02_fecaut_sri,g02_fecexp_sri,
			       g02_serie_cia, g02_serie_loc,
			       g02_usuario,   g02_fecing 
	ON KEY(F2)
            IF INFIELD(g02_localidad) THEN
                  CALL fl_ayuda_localidad(vg_codcia) RETURNING codigo_loc, desc_loc
                  IF codigo_loc IS NOT NULL THEN
                        LET rm_loc.g02_localidad = codigo_loc
                        DISPLAY BY NAME rm_loc.g02_localidad, desc_loc
                  END IF
            END IF
            IF INFIELD(g02_ciudad) THEN
         	  CALL fl_ayuda_ciudad('00') RETURNING cod_ciudad, desc_ciudad
                  LET rm_loc.g02_ciudad = cod_ciudad
                  DISPLAY BY NAME rm_loc.g02_ciudad, desc_ciudad 
            END IF
       ON KEY(interrupt)
		CLEAR FORM
		--CALL lee_muestra_registro(vm_rows[vm_row_current])
                RETURN
END CONSTRUCT
IF int_flag THEN
      CALL lee_muestra_registro(vm_rows[vm_row_current])
      CALL muestra_contadores()
      RETURN
END IF
LET query = 'SELECT *, ROWID FROM gent002 WHERE g02_compania = ? AND ', 
		expr_sql CLIPPED

PREPARE cons FROM query
DECLARE q_loc CURSOR FOR cons
LET vm_num_rows = 1
OPEN q_loc USING vg_codcia
WHILE TRUE
	FETCH q_loc INTO rm_loc.*, vm_rows[vm_num_rows]
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
CLOSE q_loc
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION




FUNCTION control_ingreso()
DEFINE codigo 	 	SMALLINT
DEFINE desc_loc   	LIKE gent002.g02_nombre
DEFINE max_loc     	LIKE gent002.g02_compania

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_loc.* TO NULL
LET rm_loc.g02_fecing = CURRENT
LET rm_loc.g02_usuario = vg_usuario
LET rm_loc.g02_matriz = 'N'
LET rm_loc.g02_localidad = 1
DISPLAY BY NAME rm_loc.g02_fecing, rm_loc.g02_usuario
DISPLAY 'ACTIVO' TO tit_estado
LET rm_loc.g02_estado = 'A'

CALL ingresa_datos()

IF NOT int_flag THEN
      SELECT MAX(g02_localidad) INTO max_loc FROM gent002
		WHERE g02_compania = vg_codcia
      IF max_loc IS NOT NULL THEN
      		LET rm_loc.g02_localidad =  max_loc  + 1
      ELSE
		LET max_loc = 1
		LET rm_loc.g02_localidad = max_loc
      END IF
      LET rm_loc.g02_compania  =  vg_codcia
      INSERT INTO gent002 VALUES (rm_loc.*)
      DISPLAY BY  NAME rm_loc.g02_localidad
      IF rm_loc.g02_localidad IS NOT NULL THEN
           LET desc_loc =  rm_loc.g02_nombre
           DISPLAY BY NAME rm_loc.g02_localidad, desc_loc
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
            CLEAR desc_cia
      END IF
END IF
CALL muestra_contadores()

END FUNCTION



FUNCTION control_modificacion()
DEFINE     	flag   CHAR(1)

IF rm_loc.g02_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM gent002 WHERE ROWID = vm_rows[vm_row_current]
       FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_loc.*
IF status < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
      WHENEVER ERROR STOP
      COMMIT WORK
      RETURN
END IF
CALL ingresa_datos()
IF NOT int_flag THEN
      UPDATE gent002 SET * = rm_loc.*
           WHERE CURRENT OF q_up
	CALL fl_mensaje_registro_modificado()
      CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
COMMIT WORK

END FUNCTION
 


FUNCTION control_bloqueo()
DEFINE resp    	CHAR(6)
DEFINE i		SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado 	CHAR(1)

LET int_flag = 0
IF rm_loc.g02_compania AND rm_loc.g02_localidad IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
      	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_blo CURSOR FOR SELECT * FROM gent002 WHERE ROWID = vm_rows[vm_row_current]
      FOR UPDATE
OPEN q_blo
FETCH q_blo INTO rm_loc.*
IF status < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
      WHENEVER ERROR STOP
      COMMIT WORK
      RETURN
END IF
LET mensaje = 'Seguro de bloquear'
LET estado = 'B'
IF rm_loc.g02_estado <> 'A' THEN
      LET mensaje = 'Seguro de activar'
      LET estado = 'A'
END IF	
CALL fl_mensaje_seguro_ejecutar_proceso()
      RETURNING resp
IF resp = 'Yes' THEN
      UPDATE gent002 set g02_estado = estado WHERE CURRENT OF q_blo
      DISPLAY 'BLOQUEADO' TO tit_estado
      DISPLAY 'B' TO g02_estado
      LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
      WHENEVER ERROR STOP	
      COMMIT WORK
      CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

CALL muestra_contadores()

END FUNCTION



FUNCTION ingresa_datos()
DEFINE           	resp    CHAR(6)
DEFINE codigo		LIKE gent002.g02_compania
DEFINE matriz           LIKE gent002.g02_matriz
DEFINE desc_cia		LIKE gent001.g01_razonsocial
DEFINE cod_ciudad	LIKE gent002.g02_ciudad
DEFINE desc_ciudad	LIKE gent031.g31_nombre
DEFINE pais		LIKE gent031.g31_pais

OPTIONS INPUT WRAP
IF rm_loc.g02_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	LET int_flag = 1
	RETURN
END IF
LET int_flag = 0 
DISPLAY BY NAME rm_loc.g02_fecing
INPUT BY NAME  	rm_loc.g02_nombre,    rm_loc.g02_abreviacion,   
               	rm_loc.g02_estado,    rm_loc.g02_numruc,    
          	rm_loc.g02_ciudad,    rm_loc.g02_correo,
                rm_loc.g02_direccion, rm_loc.g02_telefono1,
	 	rm_loc.g02_telefono2, 
		rm_loc.g02_fax1,      rm_loc.g02_fax2,   
		rm_loc.g02_casilla,
		rm_loc.g02_matriz,    rm_loc.g02_numaut_sri,
		rm_loc.g02_fecaut_sri,rm_loc.g02_fecexp_sri, 
		rm_loc.g02_serie_cia, rm_loc.g02_serie_loc, 
		rm_loc.g02_usuario,   rm_loc.g02_fecing 
                WITHOUT DEFAULTS 
	ON KEY(F2)
            IF INFIELD(g02_ciudad) THEN
         	  CALL fl_ayuda_ciudad('00') RETURNING cod_ciudad, desc_ciudad
                  LET rm_loc.g02_ciudad = cod_ciudad
                  DISPLAY BY NAME rm_loc.g02_ciudad, desc_ciudad 
            END IF
	ON KEY (INTERRUPT)
           IF field_touched(  	rm_loc.g02_nombre, rm_loc.g02_abreviacion,  
                             	rm_loc.g02_estado,rm_loc.g02_numruc, 
				rm_loc.g02_ciudad,  rm_loc.g02_correo,
                              	rm_loc.g02_direccion, rm_loc.g02_telefono1,
				rm_loc.g02_telefono2,
                              	rm_loc.g02_fax1,   rm_loc.g02_fax2,   
		 		rm_loc.g02_casilla,
                              	rm_loc.g02_matriz, rm_loc.g02_usuario,
			 	rm_loc.g02_fecing )
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
                  RETURN
           END IF
	AFTER FIELD g02_ciudad
	IF rm_loc.g02_ciudad IS NOT NULL THEN
		CLEAR desc_ciudad
		CALL fl_lee_ciudad(rm_loc.g02_ciudad) RETURNING rm_ciu.*
		IF rm_ciu.g31_ciudad IS NULL THEN
              		CALL fgl_winmessage(vg_producto,'No existe una ciudad con ese código','exclamation')
			NEXT FIELD g02_ciudad
        	END IF   
		LET rm_loc.g02_ciudad 	= rm_ciu.g31_ciudad
		LET desc_ciudad     	= rm_ciu.g31_nombre
        	DISPLAY BY NAME rm_loc.g02_ciudad, desc_ciudad
	END IF
	AFTER FIELD g02_fecaut_sri
		IF rm_loc.g02_fecaut_sri IS NOT NULL THEN
			IF rm_loc.g02_fecaut_sri > TODAY THEN
				CALL fgl_winmessage(vg_producto,'Fecha de autorización es incorrecta.','exclamation')
				NEXT FIELD g02_fecaut_sri
			END IF
			IF rm_loc.g02_fecexp_sri IS NOT NULL THEN
				IF rm_loc.g02_fecaut_sri
				>= rm_loc.g02_fecexp_sri THEN
					CALL fgl_winmessage(vg_producto,'La fecha de autorización debe ser menor a la fecha de expiración.','exclamation')
					NEXT FIELD g02_fecaut_sri
				END IF
			END IF
		END IF
	AFTER FIELD g02_fecexp_sri
		IF rm_loc.g02_fecexp_sri IS NOT NULL
		AND rm_loc.g02_fecaut_sri IS NOT NULL THEN
			IF rm_loc.g02_fecexp_sri <= rm_loc.g02_fecaut_sri THEN
				CALL fgl_winmessage(vg_producto,'La fecha de expiración debe ser mayor a la fecha de autorización.','exclamation')
				NEXT FIELD g02_fecexp_sri
			END IF
		END IF
	AFTER INPUT
	IF rm_loc.g02_matriz = 'S' THEN
              SELECT g02_matriz INTO matriz FROM gent002
               WHERE g02_compania = rm_loc.g02_compania
                 AND g02_localidad <> rm_loc.g02_localidad
                 AND g02_matriz = 'S'
		IF STATUS <> NOTFOUND THEN
              		CALL fgl_winmessage(vg_producto,'Ya existe una Matriz para esta Compañía','info')
			LET rm_loc.g02_matriz = 'N'
			NEXT FIELD rm_loc.g02_matriz
		END IF
	END IF
	IF rm_loc.g02_numaut_sri IS NULL OR rm_loc.g02_fecaut_sri IS NULL
	OR rm_loc.g02_fecexp_sri IS NULL OR rm_loc.g02_serie_cia IS NULL
	OR rm_loc.g02_serie_loc IS NULL THEN
		CALL fgl_winmessage(vg_producto,'Ingrese los datos completo del SRI.','info')
		IF rm_loc.g02_numaut_sri IS NULL THEN
			NEXT FIELD g02_numaut_sri
		END IF
		IF rm_loc.g02_fecaut_sri IS NULL THEN
			NEXT FIELD g02_fecaut_sri
		END IF
		IF rm_loc.g02_fecexp_sri IS NULL THEN
			NEXT FIELD g02_fecexp_sri
		END IF
		IF rm_loc.g02_serie_cia IS NULL THEN
			NEXT FIELD g02_serie_cia
		END IF
		IF rm_loc.g02_serie_loc IS NULL THEN
			NEXT FIELD g02_serie_loc
		END IF
	END IF

END INPUT

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
{
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
}

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE desc_cia         LIKE gent001.g01_razonsocial
DEFINE desc_loc         LIKE gent002.g02_nombre
DEFINE cod_ciudad       LIKE gent002.g02_ciudad
DEFINE desc_ciudad      LIKE gent031.g31_nombre


IF vm_num_rows <= 0 OR num_row <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_loc.* FROM gent002 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
IF rm_loc.g02_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF
DISPLAY BY NAME rm_loc.g02_localidad THRU rm_loc.g02_fecing
IF rm_loc.g02_localidad IS NOT NULL THEN
       SELECT g02_nombre INTO desc_loc FROM gent002 
              WHERE g02_compania = rm_loc.g02_compania 
		AND g02_localidad = rm_loc.g02_localidad 

       IF STATUS = NOTFOUND THEN
              CALL fgl_winmessage(vg_producto,'No existe una compañía con ese código','info')
              CLEAR desc_loc
        END IF   
        DISPLAY BY NAME rm_loc.g02_localidad, desc_loc
END IF

IF rm_loc.g02_ciudad IS NOT NULL THEN
       SELECT g31_nombre INTO desc_ciudad FROM gent031 
              WHERE g31_ciudad = rm_loc.g02_ciudad
       IF STATUS = NOTFOUND THEN
              CALL fgl_winmessage(vg_producto,'No existe una ciudad con ese código','info')
              CLEAR desc_ciudad
        END IF   
        DISPLAY BY NAME rm_loc.g02_ciudad, desc_ciudad
END IF
END FUNCTION



FUNCTION muestra_contadores() 

DISPLAY '' AT 1,1
DISPLAY vm_row_current,' de ', vm_num_rows AT 1,70

END FUNCTION
