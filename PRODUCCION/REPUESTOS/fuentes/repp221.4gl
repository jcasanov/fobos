--------------------------------------------------------------------------------
-- Titulo               : repp221.4gl -- Mantenimiento Proceso Cambio Precios
-- Elaboración          : 21-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun repp221.4gl base RE 1
-- Ultima Correción     : 21-sep-2001
-- Motivo Corrección    : 1
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cam 		RECORD LIKE rept032.*
DEFINE rm_cam2 		RECORD LIKE rept032.*
DEFINE rm_lin 		RECORD LIKE rept003.*
DEFINE rm_rot 		RECORD LIKE rept004.*
DEFINE rm_titem 	RECORD LIKE rept006.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_flag_mant         CHAR(1)

MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base	= arg_val(1)
LET vg_modulo	= arg_val(2)
LET vg_codcia	= arg_val(3)
LET vg_proceso	= 'repp221'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_cam AT 3,2 WITH 20 ROWS, 80 COLUMNS 
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_cam FROM '../forms/repf221_1'
DISPLAY FORM f_cam
INITIALIZE rm_cam.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
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
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
        COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
                IF vm_row_current < vm_num_rows THEN
                        LET vm_row_current = vm_row_current + 1
                END IF
                CALL lee_muestra_registro(vm_r_rows[vm_row_current])
                CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
        COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
                IF vm_row_current > 1 THEN
                        LET vm_row_current = vm_row_current - 1
                END IF
                CALL lee_muestra_registro(vm_r_rows[vm_row_current])
                CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = 1 THEN
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
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE  numreg 		LIKE rept032.r32_numreg
DEFINE  linea 		LIKE rept032.r32_linea
DEFINE  porcentaje	LIKE rept032.r32_porc_fact
DEFINE  usuario		LIKE rept032.r32_usuario

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r32_numreg, r32_estado, r32_linea, r32_rotacion,
	r32_tipo_item, r32_porc_fact, r32_moneda, r32_rubro_base, r32_usuario,
	r32_fecing
	ON KEY(F2)
		IF INFIELD(r32_numreg) THEN
			CALL fl_ayuda_cambio_precios(vg_codcia,'T')
			RETURNING numreg, porcentaje, linea, usuario
			IF numreg IS NOT NULL THEN
			    LET rm_cam.r32_numreg    = numreg
			    LET rm_cam.r32_linea     = linea
			    LET rm_cam.r32_porc_fact = porcentaje
			    DISPLAY BY NAME rm_cam.r32_numreg,
					rm_cam.r32_linea,
					rm_cam.r32_porc_fact
			END IF
		END IF
		IF INFIELD(r32_linea) THEN
		     CALL fl_ayuda_lineas_rep(vg_codcia)
		     RETURNING rm_lin.r03_codigo, rm_lin.r03_nombre
		     IF rm_lin.r03_codigo IS NOT NULL THEN
			LET rm_cam.r32_linea = rm_lin.r03_codigo
			DISPLAY BY NAME rm_cam.r32_linea
			DISPLAY rm_lin.r03_nombre TO nom_lin
		     END IF
		END IF
		IF INFIELD(r32_rotacion) THEN
		     CALL fl_ayuda_clases(vg_codcia)
		     RETURNING rm_rot.r04_rotacion, rm_rot.r04_nombre
		     IF rm_rot.r04_rotacion IS NOT NULL THEN
			LET rm_cam.r32_rotacion = rm_rot.r04_rotacion
			DISPLAY BY NAME rm_cam.r32_rotacion
			DISPLAY rm_rot.r04_nombre TO nom_rot
		     END IF
		END IF
		IF INFIELD(r32_tipo_item) THEN
		     CALL fl_ayuda_tipo_item()
		     RETURNING rm_titem.r06_codigo, rm_titem.r06_nombre
		     IF rm_titem.r06_codigo IS NOT NULL THEN
		        LET rm_cam.r32_tipo_item = rm_titem.r06_codigo
			DISPLAY BY NAME rm_cam.r32_tipo_item
			DISPLAY rm_titem.r06_nombre TO nom_tipo
		     END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r32_estado
		LET rm_cam.r32_estado = get_fldbuf(r32_estado)
		IF rm_cam.r32_estado IS NOT NULL THEN
			CALL muestra_estado()
		ELSE
			CLEAR tit_estado
		END IF
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rept032 WHERE r32_compania = ',
	     vg_codcia, ' AND ', expr_sql CLIPPED
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_cam.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_ingreso()

LET vm_flag_mant = 'I'
CLEAR FORM
INITIALIZE rm_cam.* TO NULL
LET rm_cam.r32_fecing     = CURRENT
LET rm_cam.r32_fecpro     = CURRENT
LET rm_cam.r32_usuario    = vg_usuario
LET rm_cam.r32_compania   = vg_codcia
LET rm_cam.r32_moneda     = 'A'
LET rm_cam.r32_estado     = 'A'
LET rm_cam.r32_rubro_base = 'P'
DISPLAY BY NAME rm_cam.r32_estado, rm_cam.r32_fecing, 
		rm_cam.r32_usuario, rm_cam.r32_fecpro, rm_cam.r32_moneda
CALL muestra_estado()
SELECT MAX(r32_numreg) + 1 INTO rm_cam.r32_numreg FROM rept032
        WHERE r32_compania = vg_codcia
        IF rm_cam.r32_numreg IS NULL THEN
                LET rm_cam.r32_numreg = 1
        END IF
CALL lee_datos()
IF NOT int_flag THEN
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	INSERT INTO rept032 VALUES (rm_cam.*)
	IF status < 0 THEN
	    SELECT MAX(r32_numreg) + 1 INTO rm_cam.r32_numreg FROM rept032
                   WHERE r32_compania = vg_codcia
            IF rm_cam.r32_numreg IS NULL THEN
                 LET rm_cam.r32_numreg = 1
            END IF
	    WHENEVER ERROR STOP
	    INSERT INTO rept032 VALUES (rm_cam.*)
	END IF 
	COMMIT WORK
	CALL fl_mensaje_registro_ingresado()
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION


                                                                                
FUNCTION control_modificacion()

IF rm_cam.r32_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,'No puede modificar un registro que se encuentra procesado ','exclamation')
	RETURN
END IF
LET vm_flag_mant = 'M'
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM rept032 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_cam.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE rept032
	SET 	r32_rubro_base = rm_cam.r32_rubro_base, 
		r32_porc_fact  = rm_cam.r32_porc_fact,
		r32_linea      = rm_cam.r32_linea,
		r32_rotacion   = rm_cam.r32_rotacion,
		r32_moneda     = rm_cam.r32_moneda,
		r32_tipo_item  = rm_cam.r32_tipo_item
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
END IF

END FUNCTION



FUNCTION lee_datos()
DEFINE  resp    	CHAR(6)
DEFINE 	serial 	 	LIKE rept032.r32_numreg

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME 	rm_cam.r32_linea, rm_cam.r32_rotacion, rm_cam.r32_tipo_item,
		rm_cam.r32_porc_fact, rm_cam.r32_moneda, rm_cam.r32_rubro_base
		WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched( rm_cam.r32_linea, rm_cam.r32_rotacion, 
		rm_cam.r32_tipo_item, rm_cam.r32_porc_fact)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                           LET int_flag = 1
                           IF vm_flag_mant = 'I' THEN
				 CLEAR FORM
			   END IF
                           RETURN
                        END IF
                ELSE
                        IF vm_flag_mant = 'I' THEN
				CLEAR FORM
			END IF
		        RETURN
                END IF
	ON KEY(F2)
		IF INFIELD(r32_linea) THEN
		     CALL fl_ayuda_lineas_rep(vg_codcia)
		     RETURNING rm_lin.r03_codigo, rm_lin.r03_nombre
		     IF rm_lin.r03_codigo IS NOT NULL THEN
			LET rm_cam.r32_linea = rm_lin.r03_codigo
			DISPLAY BY NAME rm_cam.r32_linea
			DISPLAY rm_lin.r03_nombre TO nom_lin
		     END IF
		END IF
		IF INFIELD(r32_rotacion) THEN
		     CALL fl_ayuda_clases(vg_codcia)
		     RETURNING rm_rot.r04_rotacion, rm_rot.r04_nombre
		     IF rm_rot.r04_rotacion IS NOT NULL THEN
			LET rm_cam.r32_rotacion = rm_rot.r04_rotacion
			DISPLAY BY NAME rm_cam.r32_rotacion
			DISPLAY rm_rot.r04_nombre TO nom_rot
		     END IF
		END IF
		IF INFIELD(r32_tipo_item) THEN
		     CALL fl_ayuda_tipo_item()
		     RETURNING rm_titem.r06_codigo, rm_titem.r06_nombre
		     IF rm_titem.r06_codigo IS NOT NULL THEN
		        LET rm_cam.r32_tipo_item = rm_titem.r06_codigo
			DISPLAY BY NAME rm_cam.r32_tipo_item
			DISPLAY rm_titem.r06_nombre TO nom_tipo
		     END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r32_tipo_item
                IF rm_cam.r32_tipo_item IS NOT NULL THEN
                    CALL fl_lee_tipo_item(rm_cam.r32_tipo_item)
                                RETURNING rm_titem.*
                        IF rm_titem.r06_codigo IS NULL THEN
                                CALL fgl_winmessage (vg_producto, 'El Tipo de Item no existe en la compañía ','exclamation')
                                NEXT FIELD r32_tipo_item
                        END IF
			DISPLAY rm_titem.r06_nombre TO nom_tipo
		ELSE
			CLEAR nom_tipo
                END IF
	AFTER FIELD r32_linea
                IF rm_cam.r32_linea IS NOT NULL THEN
                    CALL fl_lee_linea_rep(vg_codcia, rm_cam.r32_linea)
                                RETURNING rm_lin.*
                        IF rm_lin.r03_codigo IS NULL THEN
                                CALL fgl_winmessage (vg_producto, 'La Línea de venta no existe en la compañía ','exclamation')
                                NEXT FIELD r32_linea
                        END IF
			DISPLAY rm_lin.r03_nombre TO nom_lin
		ELSE 
			CLEAR nom_lin
                END IF
	AFTER FIELD r32_rotacion
                IF rm_cam.r32_rotacion IS NOT NULL THEN
                    CALL fl_lee_indice_rotacion(vg_codcia, rm_cam.r32_rotacion)
                                RETURNING rm_rot.*
                        IF rm_rot.r04_rotacion IS NULL THEN
                                CALL fgl_winmessage (vg_producto, 'El Indice de Rotación no existe en la compañía ','exclamation')
                                NEXT FIELD r32_rotacion
                        END IF
			DISPLAY rm_rot.r04_nombre TO nom_rot
		ELSE 
			CLEAR nom_rot
                END IF
	AFTER INPUT
		IF rm_cam.r32_moneda = 'B' THEN
			IF rg_gen.g00_moneda_alt IS NULL
			OR rg_gen.g00_moneda_alt = ' '
				THEN 
					CALL fgl_winmessage(vg_producto,'No esta configurada la Moneda Alterna.','exclamation')
					NEXT FIELD r32_moneda
			END IF
		END IF
		CASE rm_cam.r32_moneda
			WHEN 'A'
				LET rm_cam.r32_moneda = rg_gen.g00_moneda_base
			WHEN 'B'
				LET rm_cam.r32_moneda = rg_gen.g00_moneda_alt
		END CASE
	
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_cam.* FROM rept032 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
IF rm_cam.r32_moneda = rg_gen.g00_moneda_base THEN
	LET rm_cam.r32_moneda = 'A'
ELSE
	LET rm_cam.r32_moneda = 'B'
END IF
DISPLAY BY NAME rm_cam.r32_numreg, rm_cam.r32_estado, rm_cam.r32_linea, 
		rm_cam.r32_rotacion, rm_cam.r32_tipo_item, rm_cam.r32_moneda,
		rm_cam.r32_porc_fact, rm_cam.r32_rubro_base,
		rm_cam.r32_usuario, rm_cam.r32_fecing, rm_cam.r32_fecpro
DISPLAY 'ACTIVO' TO tit_estado
IF rm_cam.r32_rotacion IS NOT NULL THEN
	CALL fl_lee_indice_rotacion(vg_codcia, rm_cam.r32_rotacion)
        	RETURNING rm_rot.*
		DISPLAY rm_rot.r04_nombre TO nom_rot
END IF
CALL fl_lee_linea_rep(vg_codcia, rm_cam.r32_linea)
        RETURNING rm_lin.*
	DISPLAY rm_lin.r03_nombre TO nom_lin
IF rm_cam.r32_tipo_item IS NOT NULL THEN
	CALL fl_lee_tipo_item(rm_cam.r32_tipo_item)
		RETURNING rm_titem.*
		DISPLAY rm_titem.r06_nombre TO nom_tipo
END IF

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION muestra_estado()

CASE rm_cam.r32_estado
	WHEN 'A' 
        	DISPLAY 'ACTIVO' TO tit_estado
	WHEN 'P'
		DISPLAY 'PROCESADO' TO tit_estado
	OTHERWISE
		CLEAR r32_estado, tit_estado
END CASE

END FUNCTION



FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'sto
p')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'st
op')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 			 'stop')
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
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION
