--------------------------------------------------------------------------------
-- Titulo           : repp201.4gl - Mantenimiento de Ventas Perdidas 
-- Elaboracion      : 20-sep-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp201 base RE 1 [item] [bodega] 
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'


DEFINE vm_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT      -- FILA CORRIENTE DEL ARREGLO LINEA VTA
DEFINE vm_num_rows	SMALLINT	 -- CANTIDAD DE FILAS LEIDAS LINEA VTA
DEFINE vm_r_rows   ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS 

DEFINE rm_item		RECORD LIKE rept010.*
DEFINE rm_bod		RECORD LIKE rept002.*
DEFINE rm_per		RECORD LIKE rept013.*
DEFINE rm_per2		RECORD LIKE rept013.*
DEFINE vm_flag_mant	CHAR(1)
DEFINE vm_max_rows	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp201.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
-- Validar # parámetros correcto
IF num_args() <> 4 AND num_args() <> 6 THEN 
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
        'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp201'
LET vm_max_rows = 1000

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE resp 		CHAR(6)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r02		RECORD LIKE rept002.*

CALL fl_nivel_isolation()
OPEN WINDOW w_sus AT 3,2 WITH 19 ROWS, 80 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2)
OPEN FORM f_per FROM '../forms/repf201_1'
DISPLAY FORM f_per 
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)

IF num_args() = 6 THEN
	INITIALIZE rm_per.* TO NULL
	LET rm_per.r13_compania   = vg_codcia
	LET rm_per.r13_localidad  = vg_codloc
	LET rm_per.r13_usuario    = vg_usuario
	LET rm_per.r13_fecing     = CURRENT
	LET rm_per.r13_serial     = 0
	LET rm_per.r13_estado     = 'A'
	LET rm_per.r13_item       = arg_val(5)
	LET rm_per.r13_bodega     = arg_val(6)
	DISPLAY BY NAME rm_per.r13_usuario, rm_per.r13_fecing, rm_per.r13_estado
	DISPLAY BY NAME rm_per.r13_item, rm_per.r13_bodega

	CALL fl_lee_item(vg_codcia, rm_per.r13_item) RETURNING r_r10.*
	CALL fl_lee_bodega_rep(vg_codcia, rm_per.r13_bodega) RETURNING r_r02.*

	DISPLAY r_r02.r02_nombre TO nom_bod	
	DISPLAY r_r10.r10_nombre TO nom_item	

	DISPLAY 'ACTIVO' TO tit_estado

	INPUT BY NAME    
		 rm_per.r13_cantidad, rm_per.r13_cod_tran,rm_per.r13_num_tran,
		 rm_per.r13_referencia
  		 WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	IF field_touched( r13_cantidad, 
				 r13_referencia, r13_cod_tran, r13_num_tran)
		THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                            LET int_flag = 1
			    IF vm_flag_mant = 'I' THEN
                                	CLEAR FORM
			    END IF
                        END IF
                END IF       	
                RETURN
	END INPUT
	IF int_flag THEN
		EXIT PROGRAM
	END IF
	INSERT INTO rept013 VALUES(rm_per.*)
	CALL fl_mensaje_registro_ingresado()

	EXIT PROGRAM
END IF  


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
		IF vm_num_rows > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF		
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente'
		IF vm_num_rows > 0 THEN
			CALL control_modificacion()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
        COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
		IF vm_num_rows < 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
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
		IF vm_row_current = vm_num_rows THEN
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

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r13_serial, r13_item, r13_bodega, r13_cantidad,
                              r13_referencia, r13_cod_tran, r13_num_tran,
			      r13_estado, r13_usuario, r13_fecing
	ON KEY(F2)
		IF INFIELD(r13_serial) THEN
			CALL fl_ayuda_ventas_perdidas(vg_codcia)
				RETURNING rm_per2.r13_serial,
					  rm_per2.r13_item,
					  rm_item.r10_nombre
			IF rm_per2.r13_serial IS NOT NULL THEN
				LET rm_per.r13_serial = rm_per2.r13_serial
				LET rm_per.r13_item   = rm_per2.r13_item
				DISPLAY BY NAME  rm_per.r13_serial,
					rm_per.r13_item
				DISPLAY  rm_item.r10_nombre TO nom_item 
			END IF
		END IF
		IF INFIELD(r13_item) THEN
		     CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
		     RETURNING rm_item.r10_codigo, rm_item.r10_nombre
		     IF rm_item.r10_codigo IS NOT NULL THEN
			LET rm_per.r13_item = rm_item.r10_codigo
			DISPLAY BY NAME rm_per.r13_item
			DISPLAY rm_item.r10_nombre TO nom_item
		     END IF
		END IF
		IF INFIELD(r13_bodega) THEN
		     CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'F')
		     RETURNING rm_bod.r02_codigo, rm_bod.r02_nombre
		     IF rm_bod.r02_codigo IS NOT NULL THEN
			LET rm_per.r13_bodega = rm_bod.r02_codigo
			DISPLAY BY NAME rm_per.r13_bodega
			DISPLAY rm_bod.r02_nombre TO nom_bod
		     END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rept013 WHERE ', expr_sql CLIPPED
		
PREPARE cons FROM query
DECLARE q_per CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_per INTO rm_per.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
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

CLEAR FORM
INITIALIZE rm_per.* TO NULL
LET vm_flag_mant           = 'I'
LET rm_per.r13_compania   = vg_codcia
LET rm_per.r13_localidad  = vg_codloc
LET rm_per.r13_usuario    = vg_usuario
LET rm_per.r13_fecing     = CURRENT
LET rm_per.r13_serial     = 0
LET rm_per.r13_estado     = 'A'
DISPLAY BY NAME rm_per.r13_usuario, rm_per.r13_fecing, rm_per.r13_estado
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO rept013 VALUES(rm_per.*)
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()

IF rm_per.r13_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,'No puede modificar un registro que se encuentra procesado ','exclamation')
	RETURN
END IF
LET vm_flag_mant      = 'M'
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM rept013 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_per.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE 	rept013 SET r13_bodega = rm_per.r13_bodega,
		r13_item = rm_per.r13_item, 
		r13_cantidad = rm_per.r13_cantidad, 
		r13_referencia = rm_per.r13_referencia,
		r13_cod_tran = rm_per.r13_cod_tran, 
		r13_num_tran = rm_per.r13_num_tran
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 	VARCHAR(6)

INPUT BY NAME    rm_per.r13_item, rm_per.r13_bodega,
		 rm_per.r13_cantidad, rm_per.r13_cod_tran,rm_per.r13_num_tran,
		 rm_per.r13_referencia
  		 WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	IF field_touched(r13_item,       r13_bodega,   r13_cantidad, 
				 r13_referencia, r13_cod_tran, r13_num_tran)
		THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                            LET int_flag = 1
			    IF vm_flag_mant = 'I' THEN
                                	CLEAR FORM
			    END IF
                        END IF
                END IF       	
                RETURN
	ON KEY(F2)
		IF INFIELD(r13_item) THEN
		     CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
		     RETURNING rm_item.r10_codigo, rm_item.r10_nombre
		     IF rm_item.r10_codigo IS NOT NULL THEN
			LET rm_per.r13_item = rm_item.r10_codigo
			DISPLAY BY NAME rm_per.r13_item
			DISPLAY rm_item.r10_nombre TO nom_item
		     END IF
		END IF
		IF INFIELD(r13_bodega) THEN
		     CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'F')
		     RETURNING rm_bod.r02_codigo, rm_bod.r02_nombre
		     	IF rm_bod.r02_codigo IS NOT NULL THEN
				LET rm_per.r13_bodega = rm_bod.r02_codigo
				DISPLAY BY NAME rm_per.r13_bodega
				DISPLAY rm_bod.r02_nombre TO nom_bod
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r13_item
		IF rm_per.r13_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_per.r13_item)
				RETURNING rm_item.*
			IF rm_item.r10_codigo IS  NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el Item en la Compañía ','exclamation')
				NEXT FIELD r13_item
			END IF
			DISPLAY rm_item.r10_nombre TO nom_item
		ELSE
			CLEAR nom_item
		END IF
	AFTER FIELD r13_bodega
		IF rm_per.r13_bodega IS NOT NULL THEN
                        CALL fl_lee_bodega_rep(vg_codcia, rm_per.r13_bodega)
                                RETURNING rm_bod.*
                        IF rm_bod.r02_codigo IS  NULL THEN
                                CALL fgl_winmessage (vg_producto, 'La Bodega no existe en la Compañía ','exclamation')
                                NEXT FIELD r13_bodega
                        END IF
			DISPLAY rm_bod.r02_nombre TO nom_bod
			IF rm_bod.r02_factura = 'N' THEN
                                CALL fgl_winmessage (vg_producto, 'La Bodega no factura ','exclamation')
				NEXT FIELD r13_per.r13_bodega
			END IF
			DISPLAY rm_bod.r02_nombre TO nom_bod
		ELSE
			CLEAR nom_bod
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_per.* FROM rept013 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME  rm_per.r13_serial, rm_per.r13_item, rm_per.r13_bodega,
		 rm_per.r13_cantidad, rm_per.r13_referencia,rm_per.r13_cod_tran,
		 rm_per.r13_num_tran, rm_per.r13_estado, rm_per.r13_usuario,
		 rm_per.r13_fecing

CALL fl_lee_item(vg_codcia, rm_per.r13_item)
	RETURNING rm_item.*
	DISPLAY rm_item.r10_nombre TO nom_item
CALL fl_lee_bodega_rep(vg_codcia, rm_per.r13_bodega)
        RETURNING rm_bod.*
	DISPLAY rm_bod.r02_nombre TO nom_bod
CASE rm_per.r13_estado
	WHEN 'A'
		DISPLAY 'ACTIVO' TO tit_estado
	WHEN 'P'
		DISPLAY 'PROCESADO' TO tit_estado
END CASE

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_compania <> vg_codcia THEN
	CALL fgl_winmessage(vg_producto, 'Combinación compañía/localidad no ' ||
                            'existe ', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
