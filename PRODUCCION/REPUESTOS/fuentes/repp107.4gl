
--------------------------------------------------------------------------------
-- Titulo           : repp107.4gl - Configuracion descuentos por Linea Venta
--					/  Indice Rotacion 
-- Elaboracion      : 13-sep-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp107 base RE 1 
-- Ultima Correccion: 23-oct-2001 
-- Motivo Correccion: Volverlo Hacer en forma de Input Array
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

		---- CONFIGURACION LINEA DE VENTA ----
DEFINE vm_rows ARRAY[400] OF RECORD            -- REGISTROS DEL MANTENIMIENTO
	 r07_linea 	LIKE rept007.r07_linea,
	 r07_moneda 	LIKE rept007.r07_moneda,
	 r07_cont_cred	LIKE rept007.r07_cont_cred
	END RECORD
		--------------------------------------
		---- CONFIGURACION INDICE DE ROTACION ----
DEFINE vm_rows_2 ARRAY[400] OF RECORD           -- REGISTROS DEL MANTENIMIENTO
	 r08_rotacion 	LIKE rept008.r08_rotacion,
	 r08_moneda 	LIKE rept008.r08_moneda,
	 r08_cont_cred	LIKE rept008.r08_cont_cred
	END RECORD
		--------------------------------------
DEFINE vm_row_current	SMALLINT      -- FILA CORRIENTE DEL ARREGLO LINEA VTA
DEFINE vm_row_current_2	SMALLINT      -- FILA CORRIENTE DEL ARREGLO IND ROTACION
DEFINE vm_num_rows	SMALLINT	 -- CANTIDAD DE FILAS LEIDAS LINEA VTA
DEFINE vm_num_rows_2	SMALLINT	 -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
					 -- INDICE ROTACION

DEFINE vm_num_configuracion 	SMALLINT -- NUM ELEMENTOS DE LA CONFIGURACION
DEFINE vm_num_configuracion_2   SMALLINT -- NUM ELEMENTOS DE LA CONFIGURACION
DEFINE vm_ind_arr            SMALLINT
DEFINE vm_filas_pant            SMALLINT
DEFINE rm_r07		RECORD LIKE rept007.*
DEFINE rm_r03	 	RECORD LIKE rept003.*
DEFINE rm_r08		RECORD LIKE rept008.*
DEFINE rm_r04		RECORD LIKE rept004.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE vm_configuracion CHAR(1)
DEFINE vm_flag_mant	CHAR(1)
DEFINE vm_elementos	SMALLINT

DEFINE r_detalle ARRAY[200] OF RECORD
	r07_monto_ini 	LIKE rept007.r07_monto_ini,
	r07_monto_fin	LIKE rept007.r07_monto_fin,
	r07_descuento 	LIKE rept007.r07_descuento
	END RECORD

DEFINE r_detalle_2 ARRAY[200] OF RECORD
	r08_monto_ini 	LIKE rept008.r08_monto_ini,
	r08_monto_fin	LIKE rept008.r08_monto_fin,
	r08_descuento 	LIKE rept008.r08_descuento
	END RECORD
		


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
        'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp107'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows  = 400
LET vm_elementos = 200
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_repf107_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2)
OPEN FORM f_repf107_1 FROM '../forms/repf107_1'
DISPLAY FORM f_repf107_1 
CALL control_display_botones()

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r07.* TO NULL
INITIALIZE rm_r08.* TO NULL
MENU 'OPCIONES'
	COMMAND KEY('L') 'Linea de Venta'
		LET vm_configuracion = 'L'
		CALL funcion_master()
	COMMAND KEY('I') 'Indice Rotación'
		LET vm_configuracion = 'I'
		CALL funcion_master_2()
	COMMAND KEY('S') 'Salir'   
		EXIT PROGRAM
END MENU

END FUNCTION


##      <<<<<<<< FUNCION MASTER DE LINEA DE VENTA  >>>>>>>>>

FUNCTION funcion_master()

OPEN FORM f_repf107_1 FROM '../forms/repf107_1'
DISPLAY FORM f_repf107_1
CALL control_display_botones()

LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Mantenimiento'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows <= 1 THEN
		   IF fl_control_permiso_opcion('Mantenimiento') THEN
			SHOW OPTION 'Mantenimiento'
		   END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Retroceder'
				HIDE OPTION 'Mantenimiento'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
 		    SHOW OPTION 'Mantenimiento'
			
		END IF
	COMMAND KEY('M') 'Mantenimiento' 'Mantenimiento a las Configuraciones.'
		IF vm_num_rows > 0  AND rm_r07.r07_linea IS NOT NULL THEN
			CALL control_mantenimiento()
		END IF
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Retroceder'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		LET vm_flag_mant = ''
		CALL control_consulta()
		IF vm_num_rows < 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Retroceder'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		    SHOW OPTION 'Mantenimiento'
		
		END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_row_current < vm_num_rows THEN
			LET vm_row_current = vm_row_current + 1 
		END IF	
		CALL lee_muestra_registro(vm_rows[vm_row_current].*)
		CALL muestra_contadores()
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
		CALL lee_muestra_registro(vm_rows[vm_row_current].*)
		CALL muestra_contadores()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar' 
			SHOW OPTION 'Retroceder' 
			NEXT OPTION 'Retroceder' 
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			IF vm_row_current = 1 THEN
				HIDE OPTION 'Retroceder'
			END IF
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		LET vm_num_rows = 0
		LET vm_row_current = 0
		CALL muestra_contadores()
		CLEAR FORM
		CALL control_display_botones()
		EXIT MENU
END MENU

END FUNCTION



##      <<<<<<<< FUNCION MASTER DE INDICE DE ROTACION  >>>>>>>>>

FUNCTION funcion_master_2()
DEFINE i SMALLINT

OPEN FORM f_repf107_2  FROM '../forms/repf107_2'
DISPLAY FORM f_repf107_2
CALL control_display_botones()

INITIALIZE rm_r08.* TO NULL
LET vm_num_rows_2 = 0
LET vm_row_current_2 = 0
CALL muestra_contadores_2()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Mantenimiento'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros.'
		CALL control_ingreso_2()
		IF vm_num_rows_2 <= 1 THEN
			  SHOW OPTION 'Mantenimiento'
		    
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows_2 = 0 THEN
				HIDE OPTION 'Retroceder'
				HIDE OPTION 'Mantenimiento'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Mantenimiento'
		    
		END IF
	COMMAND KEY('M') 'Mantenimiento' 'Mantenimiento a las Configuraciones.'
		IF vm_num_rows_2 > 0  AND rm_r08.r08_rotacion IS NOT NULL THEN
			CALL control_mantenimiento_2()
		END IF
		IF vm_num_rows_2 <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows_2 = 0 THEN
				HIDE OPTION 'Retroceder'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		LET vm_flag_mant = ''
		CALL control_consulta_2()
		IF vm_num_rows_2 < 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows_2 = 0 THEN
				HIDE OPTION 'Retroceder'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Mantenimiento'
		    
		END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_row_current_2 < vm_num_rows_2 THEN
			LET vm_row_current_2 = vm_row_current_2 + 1 
		END IF	
		CALL lee_muestra_registro_2(vm_rows_2[vm_row_current_2].*)
		CALL muestra_contadores_2()
		IF vm_row_current_2 = vm_num_rows_2 THEN
			HIDE OPTION 'Avanzar' 
			SHOW OPTION 'Retroceder' 
			NEXT OPTION 'Retroceder' 
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		IF vm_row_current_2 > 1 THEN
			LET vm_row_current_2 = vm_row_current_2 - 1 
		END IF
		CALL lee_muestra_registro_2(vm_rows_2[vm_row_current_2].*)
		CALL muestra_contadores_2()
		IF vm_row_current_2 = vm_num_rows_2 THEN
			HIDE OPTION 'Avanzar' 
			SHOW OPTION 'Retroceder' 
			NEXT OPTION 'Retroceder' 
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			IF vm_row_current_2 = 1 THEN
				HIDE OPTION 'Retroceder'
			END IF
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		LET vm_num_rows_2    = 0
		LET vm_row_current_2 = 0
		CALL muestra_contadores_2()
		CLEAR FORM
		CALL control_display_botones()
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'Monto Inicial'		TO tit_col1
DISPLAY 'Monto Final'		TO tit_col2
DISPLAY 'Desc.%'		TO tit_col3

END FUNCTION


--------------------------------------------------------------------------------
--##  <<<<<< CONFIGURACION LINEAS DE VENTA >>>>>>>
--------------------------------------------------------------------------------

FUNCTION control_mantenimiento()
DEFINE expr_sql		VARCHAR(100)
DEFINE i		SMALLINT
DEFINE r_conf	 	RECORD LIKE rept007.*

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR SELECT * FROM rept007 
	WHERE r07_compania  = vg_codcia 
	AND   r07_linea     = rm_r07.r07_linea
	AND   r07_moneda    = rm_r07.r07_moneda
	AND   r07_cont_cred = rm_r07.r07_cont_cred
	FOR   UPDATE
OPEN q_upd
FETCH q_upd INTO r_conf.*
CLOSE q_upd
WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()	
	RETURN
END IF
CALL control_cargar_configuracion_descuentos()
CALL lee_detalle()
LET vm_flag_mant = 'M'
IF NOT int_flag THEN
	DELETE FROM rept007 
		WHERE r07_compania  = vg_codcia 
		AND   r07_linea     = rm_r07.r07_linea
		AND   r07_moneda    = rm_r07.r07_moneda
		AND   r07_cont_cred = rm_r07.r07_cont_cred
	LET rm_r07.r07_serial = 0
	FOR i = 1 TO arr_count()
		INSERT INTO rept007
	 	VALUES (rm_r07.r07_serial, vg_codcia, rm_r07.r07_linea, 
			rm_r07.r07_moneda, rm_r07.r07_cont_cred, 
			r_detalle[i].r07_monto_ini, 
			r_detalle[i].r07_monto_fin,
			r_detalle[i].r07_descuento)
	END FOR
	COMMIT WORK
	IF arr_count() > 0 THEN
		CALL fl_mensaje_registro_modificado()
	ELSE 
		CALL fgl_winmessage(vg_producto,'Se eliminaron todas las configuraciones de descuentos para esta Línea, Moneda, y Tipo de factura.','exclamation')
		CLEAR FORM
		CALL control_display_botones()
		LET vm_num_rows    = 0
		LET vm_row_current = 0
		CALL muestra_contadores()
		RETURN
	END IF
	CALL lee_muestra_registro(vm_rows[vm_row_current].*)
ELSE 
	ROLLBACK WORK
	IF NOT int_flag THEN
		CALL fl_mensaje_consultar_primero()
	END IF
	CALL lee_muestra_registro(vm_rows[vm_row_current].*)
END IF

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
CALL control_display_botones()

LET int_flag = 0
LET vm_flag_mant = 'C'
CONSTRUCT BY NAME expr_sql 
			ON r07_linea, r07_moneda, r07_cont_cred
	ON KEY(F2)
                IF INFIELD(r07_linea) THEN
                     CALL fl_ayuda_lineas_rep(vg_codcia)
                     RETURNING rm_r03.r03_codigo, rm_r03.r03_nombre
                     IF rm_r03.r03_codigo IS NOT NULL THEN
                        LET rm_r07.r07_linea = rm_r03.r03_codigo
                        DISPLAY BY NAME rm_r07.r07_linea
                        DISPLAY  rm_r03.r03_nombre TO nom_linea
                     END IF
                END IF
                IF INFIELD(r07_moneda) THEN
                     CALL fl_ayuda_monedas()
                        RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
                                  rm_g13.g13_decimales
                     IF rm_g13.g13_moneda IS NOT NULL THEN
                            LET rm_r07.r07_moneda = rm_g13.g13_moneda
                            DISPLAY BY NAME rm_r07.r07_moneda
                            DISPLAY rm_g13.g13_nombre TO nom_mon
                     END IF
                END IF
                LET int_flag = 0
		
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	CALL control_display_botones()
	IF vm_num_rows >0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current].*)
	END IF
	CALL muestra_contadores()
	RETURN
END IF
CALL valida_mantenimiento(expr_sql)

END FUNCTION



FUNCTION valida_mantenimiento(expr_sql)
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

LET query = 'SELECT UNIQUE r07_linea, r07_moneda, r07_cont_cred ',
		 'FROM rept007 ', 
		 'WHERE r07_compania = ', vg_codcia,
		' AND ', expr_sql CLIPPED, ' ORDER BY 1'
PREPARE cons FROM query
DECLARE q_conf CURSOR FOR cons

LET vm_num_rows = 1

FOREACH q_conf INTO vm_rows[vm_num_rows].*
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 AND  vm_flag_mant <> 'M' AND vm_flag_mant <> 'I' THEN
	CALL fgl_winmessage(vg_producto, 'No se encontraron registros con el criterio indicado', 'exclamation')
	LET vm_row_current = 0
	CALL muestra_contadores()
        CLEAR FORM
	CALL control_display_botones()
        RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current].*)
CALL muestra_contadores()

END FUNCTION



FUNCTION control_ingreso()
DEFINE i		SMALLINT
DEFINE expr_sql		VARCHAR(100)
DEFINE r_conf 		RECORD LIKE rept007.*

OPTIONS INPUT WRAP
CLEAR FORM
CALL control_display_botones()

INITIALIZE rm_r07.* TO NULL
LET vm_flag_mant         = 'I'
LET rm_r07.r07_compania  = vg_codcia
LET rm_r07.r07_cont_cred = 'C'

CALL lee_cabecera()
IF int_flag THEN
	CLEAR FORM
	CALL control_display_botones()
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current].*)
	END IF
	RETURN
END IF
CALL control_cargar_configuracion_descuentos()

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd2 CURSOR FOR SELECT * FROM rept007 
	WHERE r07_compania  = vg_codcia 
	AND   r07_linea     = rm_r07.r07_linea
	AND   r07_moneda    = rm_r07.r07_moneda
	AND   r07_cont_cred = rm_r07.r07_cont_cred
	FOR   UPDATE
OPEN q_upd2
FETCH q_upd2 INTO r_conf.*
WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()	
	RETURN
END IF

CALL lee_detalle()
IF int_flag THEN
	CLEAR FORM
	CALL control_display_botones()
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current].*)
	END IF
	RETURN
ELSE
	SELECT UNIQUE r07_linea, r07_moneda, r07_cont_cred
		FROM rept007
		WHERE r07_compania  = vg_codcia
		AND   r07_linea     = rm_r07.r07_linea
		AND   r07_moneda    = rm_r07.r07_moneda
		AND   r07_cont_cred = rm_r07.r07_cont_cred
	IF status <> NOTFOUND AND vm_num_rows >= 1 THEN
		LET vm_num_rows = vm_num_rows - 1 
	END IF
	DELETE FROM rept007 
		WHERE r07_compania  = vg_codcia 
		AND   r07_linea     = rm_r07.r07_linea
		AND   r07_moneda    = rm_r07.r07_moneda
		AND   r07_cont_cred = rm_r07.r07_cont_cred
	LET rm_r07.r07_serial = 0
	FOR i = 1 TO arr_count()
		INSERT INTO rept007
	 	VALUES (rm_r07.r07_serial, rm_r07.r07_compania,rm_r07.r07_linea,
			rm_r07.r07_moneda, rm_r07.r07_cont_cred, 
			r_detalle[i].r07_monto_ini, 
			r_detalle[i].r07_monto_fin,
			r_detalle[i].r07_descuento)
	END FOR
	COMMIT WORK
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_row_current = vm_num_rows
	LET vm_rows[vm_num_rows].r07_linea     = rm_r07.r07_linea
	LET vm_rows[vm_num_rows].r07_moneda    = rm_r07.r07_moneda
	LET vm_rows[vm_num_rows].r07_cont_cred = rm_r07.r07_cont_cred
	IF arr_count() > 0 THEN
		CALL fgl_winmessage (vg_producto,'Registro grabado Ok.','info')
	ELSE 
		LET vm_row_current = 0
		CALL fgl_winmessage(vg_producto,'No existen Configuración de descuentos para la Línea, Moneda, Tipo Factura. ','exclamation')
		CLEAR FORM
		CALL control_display_botones()
	END IF
END IF
IF vm_num_rows > 0 THEN
	CALL muestra_contadores()
	CALL lee_muestra_registro(vm_rows[vm_row_current].*)
END IF

END FUNCTION



FUNCTION lee_cabecera()
DEFINE  resp            CHAR(6)
DEFINE  serial          LIKE rept007.r07_serial
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_r07.r07_linea, rm_r07.r07_moneda, rm_r07.r07_cont_cred
              WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
                 IF field_touched( rm_r07.r07_linea, rm_r07.r07_moneda)
                 THEN
                        LET int_flag = 0
                        CALL fl_mensaje_abandonar_proceso()
                                RETURNING resp
                        IF resp = 'Yes' THEN
                          	 LET int_flag = 1
                           	CLEAR FORM
				CALL control_display_botones()
                           	RETURN
                        END IF
                ELSE
                        IF vm_flag_mant = 'I' THEN
                                CLEAR FORM
				CALL control_display_botones()
                        END IF
                        RETURN
                END IF
        ON KEY(F2)
                IF INFIELD(r07_linea) THEN
                     CALL fl_ayuda_lineas_rep(vg_codcia)
                     RETURNING rm_r03.r03_codigo, rm_r03.r03_nombre
                     IF rm_r03.r03_codigo IS NOT NULL THEN
                        LET rm_r07.r07_linea = rm_r03.r03_codigo
                        DISPLAY BY NAME rm_r07.r07_linea
                        DISPLAY  rm_r03.r03_nombre TO nom_linea
                     END IF
                END IF
                IF INFIELD(r07_moneda) THEN
                     CALL fl_ayuda_monedas()
                        RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
                                  rm_g13.g13_decimales
                     IF rm_g13.g13_moneda IS NOT NULL THEN
                            LET rm_r07.r07_moneda = rm_g13.g13_moneda
                            DISPLAY BY NAME rm_r07.r07_moneda
                            DISPLAY rm_g13.g13_nombre TO nom_mon
                     END IF
                END IF
                LET int_flag = 0
        AFTER FIELD r07_linea
                IF rm_r07.r07_linea IS NOT NULL THEN
                    CALL fl_lee_linea_rep(vg_codcia, rm_r07.r07_linea)
                                RETURNING rm_r03.*
                        IF rm_r03.r03_codigo IS NULL THEN
                                CALL fgl_winmessage (vg_producto, 'La Línea de v
enta no existe en la compañía ','exclamation')
                                NEXT FIELD r07_linea
                        END IF
                   DISPLAY rm_r03.r03_nombre TO nom_linea
                ELSE
                        CLEAR nom_linea
                END IF
        AFTER FIELD r07_moneda
                IF rm_r07.r07_moneda IS NOT NULL THEN
                	CALL fl_lee_moneda(rm_r07.r07_moneda) 
				RETURNING rm_g13.*
                   	IF rm_g13.g13_moneda IS NULL THEN
                        	CALL fgl_winmessage(vg_producto,
				                    'Moneda no existe',
                                               	    'exclamation')
                        	NEXT FIELD r07_moneda
                   	END IF
                   	IF rm_g13.g13_estado = 'B' THEN
                        	CALL fgl_winmessage(vg_producto,
						    'Moneda está bloqueada',
                                                    'exclamation')
                        	NEXT FIELD r07_moneda
                   	END IF
			IF rm_r07.r07_moneda <> rg_gen.g00_moneda_base AND
			   rm_r07.r07_moneda <> rg_gen.g00_moneda_alt
			   THEN			   
				CALL fgl_winmessage(vg_producto,'La moneda ingresada no está configurada como moneda base ni alterna. ','exclamation')
				NEXT FIELD r07_moneda
			END IF
                   	DISPLAY rm_g13.g13_nombre TO nom_mon
                ELSE
                	CLEAR nom_mon
                END IF
END INPUT
                                                                                
END FUNCTION



FUNCTION lee_detalle()
DEFINE resp      			CHAR(6)
DEFINE i,j,k,filas_max,filas_pant       	SMALLINT

OPTIONS 
	INPUT WRAP,
	INSERT KEY F30
LET i = vm_num_configuracion
WHILE TRUE
LET j = 1
LET int_flag   = 0 
CALL set_count(i)
INPUT ARRAY r_detalle  WITHOUT DEFAULTS FROM r_detalle.*
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT','')
        ON KEY(INTERRUPT)
		LET int_flag = 0
                CALL fl_mensaje_abandonar_proceso()   
			RETURNING resp
                LET int_flag = 0
                IF resp = 'Yes' THEN
                	LET int_flag = 1
			IF vm_num_rows = 0 THEN
		            	CLEAR FORM
				CALL control_display_botones()
			END IF
			EXIT INPUT
		END IF
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	BEFORE FIELD r07_monto_ini
		IF i <> 1 THEN
			LET r_detalle[i].r07_monto_ini = 
			    r_detalle[i - 1].r07_monto_fin + 1
		ELSE
			LET r_detalle[i].r07_monto_ini = 0
		END IF
		DISPLAY r_detalle[i].r07_monto_ini TO
			r_detalle[j].r07_monto_ini
		NEXT FIELD NEXT
	AFTER FIELD r07_monto_ini
	    	IF r_detalle[i].r07_monto_ini IS NOT NULL THEN
			IF r_detalle[i].r07_monto_fin IS NOT NULL THEN
				IF r_detalle[i].r07_monto_ini >=
				   r_detalle[i].r07_monto_fin 
				   THEN
					CALL fgl_winmessage(vg_producto,'El monto inicial debe ser menor al monto final. ','exclamation')
					NEXT FIELD r07_monto_ini
				END IF 
			END IF
			FOR k = 1 TO arr_count()
				IF r_detalle[i].r07_monto_ini >=
				   r_detalle[k].r07_monto_ini AND
				   r_detalle[i].r07_monto_ini <= 
				   r_detalle[k].r07_monto_fin AND 
				   i <> k 
				   THEN
					CALL fgl_winmessage(vg_producto,'No puede ingresar un monto que se encuentre dentro de un rango ya ingresado.','exclamation')
					NEXT FIELD r07_monto_ini
               			END IF
			END FOR
		ELSE
			IF r_detalle[i].r07_monto_fin IS NOT NULL OR 
			   r_detalle[i].r07_descuento IS NOT NULL AND 
			   r_detalle[i].r07_monto_ini IS NULL
			THEN
				NEXT FIELD r07_monto_ini
			END IF 
		END IF
	AFTER FIELD r07_monto_fin
	    	IF r_detalle[i].r07_monto_fin IS NOT NULL THEN
			IF r_detalle[i].r07_monto_fin <= 
			   r_detalle[i].r07_monto_ini
			   THEN
				CALL fgl_winmessage(vg_producto,'El monto final debe ser mayor al monto inicial. ','exclamation')
				NEXT FIELD r07_monto_fin
			END IF
			FOR k = 1 TO arr_count()
				IF r_detalle[i].r07_monto_fin >=
				   r_detalle[k].r07_monto_ini AND
				   r_detalle[i].r07_monto_fin <= 
				   r_detalle[k].r07_monto_fin AND 
				   i <> k 
				   THEN
					CALL fgl_winmessage(vg_producto,'No puede ingresar un monto que se encuentre dentro de un rango ya ingresado.','exclamation')
					NEXT FIELD r07_monto_fin
               			END IF
			END FOR
		ELSE
			IF r_detalle[i].r07_descuento IS NOT NULL AND 
			   r_detalle[i].r07_monto_fin IS NULL
			THEN
				NEXT FIELD r07_monto_fin
			END IF 
		END IF
	AFTER DELETE
		IF i = 1 AND r_detalle[i].r07_monto_fin IS NULL THEN
			EXIT WHILE
		END IF
		LET i = arr_count()
		EXIT INPUT
	AFTER INPUT
		EXIT WHILE
END INPUT
IF int_flag THEN
	RETURN
END IF

END WHILE

END FUNCTION



FUNCTION control_cargar_configuracion_descuentos()
DEFINE i 	SMALLINT

FOR i = 1 TO fgl_scr_size('r_detalle')
	INITIALIZE r_detalle[i].* TO NULL
END FOR 

DECLARE q_conf_3 CURSOR FOR
	SELECT r07_monto_ini, r07_monto_fin, r07_descuento
	  FROM rept007 
	 WHERE r07_compania  = vg_codcia 
	 AND   r07_linea     = rm_r07.r07_linea 
	 AND   r07_moneda    = rm_r07.r07_moneda 
	 AND   r07_cont_cred = rm_r07.r07_cont_cred 
LET vm_num_configuracion = 1
FOREACH q_conf_3 INTO r_detalle[vm_num_configuracion].*
	LET vm_num_configuracion = vm_num_configuracion + 1
END FOREACH
LET vm_num_configuracion = vm_num_configuracion - 1

END FUNCTION



FUNCTION lee_muestra_registro(r_num_configuracion)
DEFINE r_num_configuracion  RECORD
        r07_linea	LIKE rept007.r07_linea,
        r07_moneda	LIKE rept007.r07_moneda,
        r07_cont_cred   LIKE rept007.r07_cont_cred
        END RECORD
DEFINE i	SMALLINT
DEFINE j	SMALLINT

LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR j = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[j].* TO NULL
	CLEAR r_detalle[j].*
END FOR
IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_conf2 CURSOR FOR 
	SELECT r07_monto_ini, r07_monto_fin, r07_descuento
		 FROM rept007
		WHERE r07_compania  = vg_codcia 
		AND   r07_linea     = r_num_configuracion.r07_linea
		AND   r07_moneda    = r_num_configuracion.r07_moneda
		AND   r07_cont_cred = r_num_configuracion.r07_cont_cred

LET i = 1
OPEN q_conf2
FETCH q_conf2 INTO r_detalle[i].*
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ',r_num_configuracion.* 
END IF
LET rm_r07.r07_linea     = r_num_configuracion.r07_linea
LET rm_r07.r07_moneda    = r_num_configuracion.r07_moneda
LET rm_r07.r07_cont_cred = r_num_configuracion.r07_cont_cred
DISPLAY BY NAME rm_r07.r07_linea, rm_r07.r07_moneda, rm_r07.r07_cont_cred
CALL control_mostrar_etiquetas()
FOREACH q_conf2 INTO r_detalle[i].*
	LET i = i + 1
	IF i > vm_elementos THEN
		CALL fl_mensaje_arreglo_lleno()
		RETURN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_ind_arr = i
LET i = i - 1
IF vm_ind_arr < vm_filas_pant THEN
	LET vm_filas_pant = vm_ind_arr
END IF
FOR j = 1 TO vm_filas_pant
	DISPLAY r_detalle[j].* TO r_detalle[j].*
END FOR

END FUNCTION



FUNCTION control_mostrar_etiquetas()

CALL fl_lee_moneda(rm_r07.r07_moneda) 
	RETURNING rm_g13.*
        DISPLAY rm_g13.g13_nombre TO nom_mon
CALL fl_lee_linea_rep(vg_codcia, rm_r07.r07_linea)
	RETURNING rm_r03.*
        DISPLAY rm_r03.r03_nombre TO nom_linea

END FUNCTION

                                                                                
FUNCTION muestra_contadores()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68
                                                                                
END FUNCTION

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--##		  <<<<<< CONFIGURACION INDICES DE ROTACION >>>>>>>
--------------------------------------------------------------------------------


FUNCTION control_mantenimiento_2()
DEFINE expr_sql		VARCHAR(100)
DEFINE i		SMALLINT
DEFINE r_conf	 	RECORD LIKE rept008.*

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd_4 CURSOR FOR SELECT * FROM rept008 
	WHERE r08_compania  = vg_codcia 
	AND   r08_rotacion     = rm_r08.r08_rotacion
	AND   r08_moneda    = rm_r08.r08_moneda
	AND   r08_cont_cred = rm_r08.r08_cont_cred
	FOR   UPDATE
OPEN q_upd_4
FETCH q_upd_4 INTO r_conf.*
CLOSE q_upd_4
WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()	
	RETURN
END IF
CALL control_cargar_configuracion_descuentos_2()
CALL lee_detalle_2()
LET vm_flag_mant = 'M'
IF NOT int_flag THEN
	DELETE FROM rept008 
		WHERE r08_compania  = vg_codcia 
		AND   r08_rotacion     = rm_r08.r08_rotacion
		AND   r08_moneda    = rm_r08.r08_moneda
		AND   r08_cont_cred = rm_r08.r08_cont_cred
	LET rm_r08.r08_serial = 0
	FOR i = 1 TO arr_count()
		INSERT INTO rept008
	 	VALUES (rm_r08.r08_serial, vg_codcia, rm_r08.r08_rotacion, 
			rm_r08.r08_moneda, rm_r08.r08_cont_cred, 
			r_detalle_2[i].r08_monto_ini, 
			r_detalle_2[i].r08_monto_fin,
			r_detalle_2[i].r08_descuento)
	END FOR
	COMMIT WORK
	IF arr_count() > 0 THEN
		CALL fl_mensaje_registro_modificado()
	ELSE 
		CALL fgl_winmessage(vg_producto,'Se eliminaron todas las configuracionres de descuentos para esta Línea, Moneda, y Tipo de factura.','exclamation')
		CLEAR FORM
		CALL control_display_botones()
		LET vm_num_rows_2    = 0
		LET vm_row_current_2 = 0
		CALL muestra_contadores_2()
		RETURN
	END IF
	CALL lee_muestra_registro_2(vm_rows_2[vm_row_current_2].*)
ELSE 
	ROLLBACK WORK
	IF NOT int_flag THEN
		CALL fl_mensaje_consultar_primero()
	END IF
	CALL lee_muestra_registro_2(vm_rows_2[vm_row_current_2].*)
END IF

END FUNCTION



FUNCTION control_consulta_2()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
CALL control_display_botones()

LET int_flag = 0
LET vm_flag_mant = 'C'
CONSTRUCT BY NAME expr_sql 
			ON r08_rotacion, r08_moneda, r08_cont_cred
	ON KEY(F2)
		IF INFIELD(r08_rotacion) THEN
			CALL fl_ayuda_clases(vg_codcia)
		     		RETURNING rm_r04.r04_rotacion, 
					  rm_r04.r04_nombre
		     	IF rm_r04.r04_rotacion IS NOT NULL THEN
				LET rm_r08.r08_rotacion = rm_r04.r04_rotacion
				DISPLAY BY NAME rm_r08.r08_rotacion
				DISPLAY  rm_r04.r04_nombre TO nom_rotacion
		     	END IF
		END IF
                IF INFIELD(r08_moneda) THEN
                     CALL fl_ayuda_monedas()
                        RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
                                  rm_g13.g13_decimales
                     IF rm_g13.g13_moneda IS NOT NULL THEN
                            LET rm_r08.r08_moneda = rm_g13.g13_moneda
                            DISPLAY BY NAME rm_r08.r08_moneda
                            DISPLAY rm_g13.g13_nombre TO nom_mon
                     END IF
                END IF
                LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	CALL control_display_botones()
	IF vm_num_rows_2 >0 THEN
		CALL lee_muestra_registro_2(vm_rows_2[vm_row_current_2].*)
	END IF
	CALL muestra_contadores_2()
	RETURN
END IF
CALL valida_mantenimiento_2(expr_sql)

END FUNCTION



FUNCTION valida_mantenimiento_2(expr_sql)
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

LET query = 'SELECT UNIQUE r08_rotacion, r08_moneda, r08_cont_cred ',
		 'FROM rept008 ', 
		 'WHERE r08_compania = ', vg_codcia,
		' AND ', expr_sql CLIPPED, ' ORDER BY 1'
PREPARE cons2 FROM query
DECLARE q_conf_7 CURSOR FOR cons2

LET vm_num_rows_2 = 1

FOREACH q_conf_7 INTO vm_rows_2[vm_num_rows_2].*
	LET vm_num_rows_2 = vm_num_rows_2 + 1
        IF vm_num_rows_2 > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH

LET vm_num_rows_2 = vm_num_rows_2 - 1
IF vm_num_rows_2 = 0 AND  vm_flag_mant <> 'M' AND vm_flag_mant <> 'I' THEN
	CALL fgl_winmessage(vg_producto, 'No se encontraron registros con el criterio indicado', 'exclamation')
	LET vm_row_current_2 = 0
	CALL muestra_contadores_2()
        CLEAR FORM
	CALL control_display_botones()
        RETURN
END IF

LET vm_row_current_2 = 1
CALL lee_muestra_registro_2(vm_rows_2[vm_row_current_2].*)
CALL muestra_contadores_2()

END FUNCTION



FUNCTION control_ingreso_2()
DEFINE i		SMALLINT
DEFINE expr_sql		VARCHAR(100)
DEFINE r_conf 		RECORD LIKE rept008.*

OPTIONS INPUT WRAP
CLEAR FORM
CALL control_display_botones()

INITIALIZE rm_r08.* TO NULL
LET vm_flag_mant         = 'I'
LET rm_r08.r08_compania  = vg_codcia
LET rm_r08.r08_cont_cred = 'C'

CALL lee_cabecera_2()
IF int_flag THEN
	CLEAR FORM
	CALL control_display_botones()
	IF vm_num_rows_2 > 0 THEN
		CALL lee_muestra_registro(vm_rows_2[vm_row_current_2].*)
	END IF
	RETURN
END IF

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd2_4 CURSOR FOR SELECT * FROM rept008 
	WHERE r08_compania  = vg_codcia 
	AND   r08_rotacion     = rm_r08.r08_rotacion
	AND   r08_moneda    = rm_r08.r08_moneda
	AND   r08_cont_cred = rm_r08.r08_cont_cred
	FOR   UPDATE
OPEN q_upd2_4
FETCH q_upd2_4 INTO r_conf.*
WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()	
	RETURN
END IF
IF NOT int_flag THEN
	CALL lee_detalle_2()
ELSE
	ROLLBACK WORK
	--RETURN
END IF
IF NOT int_flag THEN
	SELECT UNIQUE r08_rotacion, r08_moneda, r08_cont_cred
		FROM rept008
		WHERE r08_compania  = vg_codcia
		AND   r08_rotacion     = rm_r08.r08_rotacion
		AND   r08_moneda    = rm_r08.r08_moneda
		AND   r08_cont_cred = rm_r08.r08_cont_cred
	IF status <> NOTFOUND AND vm_num_rows_2 >= 1 THEN
		LET vm_num_rows_2 = vm_num_rows_2 - 1 
	END IF
	DELETE FROM rept008 
		WHERE r08_compania  = vg_codcia 
		AND   r08_rotacion     = rm_r08.r08_rotacion
		AND   r08_moneda    = rm_r08.r08_moneda
		AND   r08_cont_cred = rm_r08.r08_cont_cred
	LET rm_r08.r08_serial = 0
	FOR i = 1 TO arr_count()
		INSERT INTO rept008
	 	VALUES (rm_r08.r08_serial,    rm_r08.r08_compania,
			rm_r08.r08_rotacion,  rm_r08.r08_moneda, 
			rm_r08.r08_cont_cred, r_detalle_2[i].r08_monto_ini, 
			r_detalle_2[i].r08_monto_fin,
			r_detalle_2[i].r08_descuento)
	END FOR
	COMMIT WORK
        IF vm_num_rows_2 = vm_max_rows THEN
                LET vm_num_rows_2 = 1
        ELSE
                LET vm_num_rows_2 = vm_num_rows_2 + 1
        END IF
	LET vm_row_current_2 = vm_num_rows_2
	LET vm_rows_2[vm_num_rows_2].r08_rotacion  = rm_r08.r08_rotacion
	LET vm_rows_2[vm_num_rows_2].r08_moneda    = rm_r08.r08_moneda
	LET vm_rows_2[vm_num_rows_2].r08_cont_cred = rm_r08.r08_cont_cred
	IF arr_count() > 0 THEN
		CALL fgl_winmessage (vg_producto,'Registro grabado Ok.','info')
	ELSE 
		LET vm_row_current_2 = 0
		CALL fgl_winmessage(vg_producto,'No existen Configuración de descuentos para la Línea, Moneda, Tipo Factura. ','exclamation')
		CLEAR FORM
		CALL control_display_botones()
	END IF
END IF
IF vm_num_rows_2 > 0 THEN
	CALL lee_muestra_registro_2(vm_rows_2[vm_row_current_2].*)
	CALL muestra_contadores_2()
END IF

END FUNCTION



FUNCTION lee_cabecera_2()
DEFINE  resp            CHAR(6)
DEFINE  serial          LIKE rept008.r08_serial
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_r08.r08_rotacion, rm_r08.r08_moneda, rm_r08.r08_cont_cred
              WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
                 IF field_touched( rm_r08.r08_rotacion, rm_r08.r08_moneda)
                 THEN
                        LET int_flag = 0
                        CALL fl_mensaje_abandonar_proceso()
                                RETURNING resp
                        IF resp = 'Yes' THEN
                           	LET int_flag = 1
                       		CLEAR FORM
				CALL control_display_botones()
                           	RETURN
                        END IF
                ELSE
                        IF vm_flag_mant = 'I' THEN
                                CLEAR FORM
				CALL control_display_botones()
                        END IF
                        RETURN
                END IF
        ON KEY(F2)
		IF INFIELD(r08_rotacion) THEN
			CALL fl_ayuda_clases(vg_codcia)
		     		RETURNING rm_r04.r04_rotacion, 
					  rm_r04.r04_nombre
		     	IF rm_r04.r04_rotacion IS NOT NULL THEN
				LET rm_r08.r08_rotacion = rm_r04.r04_rotacion
				DISPLAY BY NAME rm_r08.r08_rotacion
				DISPLAY  rm_r04.r04_nombre TO nom_rotacion
		     	END IF
		END IF
                IF INFIELD(r08_moneda) THEN
                     CALL fl_ayuda_monedas()
                        RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
                                  rm_g13.g13_decimales
                     IF rm_g13.g13_moneda IS NOT NULL THEN
                            LET rm_r08.r08_moneda = rm_g13.g13_moneda
                            DISPLAY BY NAME rm_r08.r08_moneda
                            DISPLAY rm_g13.g13_nombre TO nom_mon
                     END IF
                END IF
                LET int_flag = 0
        AFTER FIELD r08_rotacion
                IF rm_r08.r08_rotacion IS NOT NULL THEN
                    CALL fl_lee_indice_rotacion(vg_codcia, rm_r08.r08_rotacion)
                                RETURNING rm_r04.*
                        IF rm_r04.r04_rotacion IS NULL THEN
                                CALL fgl_winmessage (vg_producto, 'El Indice de Rotación no existe en la Compañía ','exclamation')
                                NEXT FIELD r08_rotacion
                        END IF
                   DISPLAY rm_r04.r04_nombre TO nom_rotacion
                ELSE
                        CLEAR nom_rotacion
                END IF
        AFTER FIELD r08_moneda
                IF rm_r08.r08_moneda IS NOT NULL THEN
                	CALL fl_lee_moneda(rm_r08.r08_moneda) 
				RETURNING rm_g13.*
                   	IF rm_g13.g13_moneda IS NULL THEN
                        	CALL fgl_winmessage(vg_producto,
				                    'Moneda no existe',
                                               	    'exclamation')
                        	NEXT FIELD r08_moneda
                   	END IF
                   	IF rm_g13.g13_estado = 'B' THEN
                        	CALL fgl_winmessage(vg_producto,
						    'Moneda está bloqueada',
                                                    'exclamation')
                        	NEXT FIELD r08_moneda
                   	END IF
			IF rm_r08.r08_moneda <> rg_gen.g00_moneda_base AND
			   rm_r08.r08_moneda <> rg_gen.g00_moneda_alt
			   THEN			   
				CALL fgl_winmessage(vg_producto,'La moneda ingresada no está configurada como moneda base ni alterna. ','exclamation')
				NEXT FIELD r08_moneda
			END IF
                   	DISPLAY rm_g13.g13_nombre TO nom_mon
                ELSE
                	CLEAR nom_mon
                END IF
END INPUT
                                                                                
END FUNCTION



FUNCTION lee_detalle_2()
DEFINE resp      			CHAR(6)
DEFINE i,j,k,filas_max,filas_pant       	SMALLINT

OPTIONS 
	INPUT WRAP,
	INSERT KEY F30
LET i = vm_num_configuracion_2
WHILE TRUE
LET j = 1
LET int_flag   = 0 
CALL set_count(i)
INPUT ARRAY r_detalle_2  WITHOUT DEFAULTS FROM r_detalle_2.*
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT','')
        ON KEY(INTERRUPT)
		LET int_flag = 0
                CALL fl_mensaje_abandonar_proceso()   
			RETURNING resp
                LET int_flag = 0
                IF resp = 'Yes' THEN
                	LET int_flag = 1
			IF vm_num_rows_2 = 0 THEN
		            	CLEAR FORM
				CALL control_display_botones()
			END IF
			EXIT INPUT
		END IF
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	BEFORE FIELD r08_monto_ini
		IF i <> 1 THEN
			LET r_detalle_2[i].r08_monto_ini = 
			    r_detalle_2[i - 1].r08_monto_fin + 1
		ELSE
			LET r_detalle_2[i].r08_monto_ini = 0
		END IF
		DISPLAY r_detalle_2[i].r08_monto_ini TO
			r_detalle_2[j].r08_monto_ini
		NEXT FIELD NEXT
	AFTER FIELD r08_monto_ini
	    	IF r_detalle_2[i].r08_monto_ini IS NOT NULL THEN
			IF r_detalle_2[i].r08_monto_fin IS NOT NULL THEN
				IF r_detalle_2[i].r08_monto_ini >=
				   r_detalle_2[i].r08_monto_fin 
				   THEN
					CALL fgl_winmessage(vg_producto,'El monto inicial debe ser menor al monto final. ','exclamation')
					NEXT FIELD r08_monto_ini
				END IF 
			END IF
			FOR k = 1 TO arr_count()
				IF r_detalle_2[i].r08_monto_ini >=
				   r_detalle_2[k].r08_monto_ini AND
				   r_detalle_2[i].r08_monto_ini <= 
				   r_detalle_2[k].r08_monto_fin AND 
				   i <> k 
				   THEN
					CALL fgl_winmessage(vg_producto,'No puede ingresar un monto que se encuentre dentro de un rango ya ingresado.','exclamation')
					NEXT FIELD r08_monto_ini
               			END IF
			END FOR
		ELSE
			IF r_detalle_2[i].r08_monto_fin IS NOT NULL OR 
			   r_detalle_2[i].r08_descuento IS NOT NULL AND 
			   r_detalle_2[i].r08_monto_ini IS NULL
			THEN
				NEXT FIELD r08_monto_ini
			END IF 
		END IF
	AFTER FIELD r08_monto_fin
	    	IF r_detalle_2[i].r08_monto_fin IS NOT NULL THEN
			IF r_detalle_2[i].r08_monto_fin <= 
			   r_detalle_2[i].r08_monto_ini
			   THEN
				CALL fgl_winmessage(vg_producto,'El monto final debe ser mayor al monto inicial. ','exclamation')
				NEXT FIELD r08_monto_fin
			END IF
			FOR k = 1 TO arr_count()
				IF r_detalle_2[i].r08_monto_fin >=
				   r_detalle_2[k].r08_monto_ini AND
				   r_detalle_2[i].r08_monto_fin <= 
				   r_detalle_2[k].r08_monto_fin AND 
				   i <> k 
				   THEN
					CALL fgl_winmessage(vg_producto,'No puede ingresar un monto que se encuentre dentro de un rango ya ingresado.','exclamation')
					NEXT FIELD r08_monto_fin
               			END IF
			END FOR
		ELSE
			IF r_detalle_2[i].r08_descuento IS NOT NULL AND 
			   r_detalle_2[i].r08_monto_fin IS NULL
			THEN
				NEXT FIELD r08_monto_fin
			END IF 
		END IF
	AFTER DELETE
		IF i = 1 AND r_detalle_2[i].r08_monto_fin IS NULL THEN
			EXIT WHILE
		END IF
		LET i = arr_count()
		EXIT INPUT
	AFTER INPUT
		EXIT WHILE
END INPUT
IF int_flag THEN
	RETURN
END IF

END WHILE

END FUNCTION



FUNCTION control_cargar_configuracion_descuentos_2()
DEFINE i 	SMALLINT

FOR i = 1 TO fgl_scr_size('r_detalle_2')
	INITIALIZE r_detalle_2[i].* TO NULL
END FOR 

DECLARE q_conf_6 CURSOR FOR
	SELECT r08_monto_ini, r08_monto_fin, r08_descuento
	  FROM rept008 
	 WHERE r08_compania  = vg_codcia 
	 AND   r08_rotacion     = rm_r08.r08_rotacion 
	 AND   r08_moneda    = rm_r08.r08_moneda 
	 AND   r08_cont_cred = rm_r08.r08_cont_cred 
LET vm_num_configuracion_2 = 1
FOREACH q_conf_6 INTO r_detalle_2[vm_num_configuracion_2].*
	LET vm_num_configuracion_2 = vm_num_configuracion_2 + 1
END FOREACH
LET vm_num_configuracion_2 = vm_num_configuracion_2 - 1

END FUNCTION



FUNCTION lee_muestra_registro_2(r_num_configuracion)
DEFINE r_num_configuracion  RECORD
        r08_rotacion	LIKE rept008.r08_rotacion,
        r08_moneda	LIKE rept008.r08_moneda,
        r08_cont_cred   LIKE rept008.r08_cont_cred
        END RECORD
DEFINE i	SMALLINT
DEFINE j	SMALLINT

LET vm_filas_pant = fgl_scr_size('r_detalle_2')
FOR j = 1 TO vm_filas_pant 
	INITIALIZE r_detalle_2[j].* TO NULL
	CLEAR r_detalle_2[j].*
END FOR
IF vm_num_rows_2 <= 0 THEN
	RETURN
END IF
DECLARE q_conf2_4 CURSOR FOR 
	SELECT r08_monto_ini, r08_monto_fin, r08_descuento
		 FROM rept008
		WHERE r08_compania  = vg_codcia 
		AND   r08_rotacion     = r_num_configuracion.r08_rotacion
		AND   r08_moneda    = r_num_configuracion.r08_moneda
		AND   r08_cont_cred = r_num_configuracion.r08_cont_cred

LET i = 1
OPEN q_conf2_4
FETCH q_conf2_4 INTO r_detalle_2[i].*
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ',r_num_configuracion.* 
END IF
LET rm_r08.r08_rotacion     = r_num_configuracion.r08_rotacion
LET rm_r08.r08_moneda    = r_num_configuracion.r08_moneda
LET rm_r08.r08_cont_cred = r_num_configuracion.r08_cont_cred
DISPLAY BY NAME rm_r08.r08_rotacion, rm_r08.r08_moneda, rm_r08.r08_cont_cred
CALL control_mostrar_etiquetas_2()
FOREACH q_conf2_4 INTO r_detalle_2[i].*
	LET i = i + 1
	IF i > vm_elementos THEN
		CALL fl_mensaje_arreglo_lleno()
		RETURN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_ind_arr = i
LET i = i - 1
IF vm_ind_arr < vm_filas_pant THEN
	LET vm_filas_pant = vm_ind_arr
END IF
FOR j = 1 TO vm_filas_pant
	DISPLAY r_detalle_2[j].* TO r_detalle_2[j].*
END FOR

END FUNCTION



FUNCTION control_mostrar_etiquetas_2()

CALL fl_lee_moneda(rm_r08.r08_moneda) 
	RETURNING rm_g13.*
        DISPLAY rm_g13.g13_nombre TO nom_mon
CALL fl_lee_indice_rotacion(vg_codcia, rm_r08.r08_rotacion)
	RETURNING rm_r04.*
        DISPLAY rm_r04.r04_nombre TO nom_rotacion

END FUNCTION

                                                                                
FUNCTION muestra_contadores_2()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_row_current_2, " de ", vm_num_rows_2 AT 1, 68
                                                                                
END FUNCTION

--------------------------------------------------------------------------------



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
