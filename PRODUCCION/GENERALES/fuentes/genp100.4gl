-------------------------------------------------------------------------------
-- Titulo           : genp100.4gl -- Configuracion General Facturación
-- Elaboracion      : 20-ago-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun genp100 base modulo
-- Ultima Correccion: 21-ago-2001
-- Motivo Correccion: Estandarizacion
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_imp 	 	RECORD LIKE 	gent000.*

DEFINE vm_demonios	VARCHAR(12)

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'genp100'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_imp AT 3,2 WITH 16 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_imp FROM '../forms/genf100_1'
DISPLAY FORM f_imp

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_imp.* TO NULL
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
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
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
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
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION 



FUNCTION control_ingreso()

CLEAR FORM
INITIALIZE rm_imp.* TO NULL

LET rm_imp.g00_fecing = CURRENT
LET rm_imp.g00_usuario = vg_usuario

CALL lee_datos()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET rm_imp.g00_serial = 0
INSERT INTO gent000 VALUES (rm_imp.*)
LET rm_imp.g00_serial = SQLCA.SQLERRD[2]	-- Obtiene el numero secuencial 
				        	-- asignado por informix
DISPLAY BY NAME rm_imp.g00_serial
LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		CHAR(6)

DEFINE r_mon		RECORD LIKE gent013.*
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE g13_moneda       LIKE gent013.g13_moneda
DEFINE decimales	LIKE gent013.g13_decimales
DEFINE nombre		LIKE gent013.g13_nombre

DEFINE r_g14		RECORD LIKE gent014.*

LET INT_FLAG = 0
INPUT BY NAME rm_imp.* WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(g00_porc_impto, 
             			     g00_label_impto,
                                     g00_moneda_base, 
     				     g00_decimal_mb
                                    ) THEN
			RETURN
		END IF
	
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                      RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
		
	ON KEY(F2)
		IF INFIELD(g00_moneda_base) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_imp.g00_moneda_base = g13_moneda
				DISPLAY g13_moneda TO g00_moneda_base
				DISPLAY nombre TO moneda1
				DISPLAY decimales TO g00_decimal_mb
			END IF	
		END IF
		IF INFIELD(g00_moneda_alt) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_imp.g00_moneda_alt = g13_moneda
				DISPLAY g13_moneda TO g00_moneda_alt
				DISPLAY nombre TO moneda2
				DISPLAY decimales TO g00_decimal_ma
			END IF	
		END IF
		LET INT_FLAG = 0
	BEFORE FIELD g00_moneda_base
			LET moneda = rm_imp.g00_moneda_base
	AFTER FIELD g00_moneda_base
		IF rm_imp.g00_moneda_base IS NULL AND moneda IS NULL THEN
			CLEAR moneda1
			INITIALIZE rm_imp.g00_decimal_mb TO NULL
			DISPLAY BY NAME rm_imp.g00_decimal_mb
			CONTINUE INPUT
		END IF
		IF rm_imp.g00_moneda_base IS NULL AND moneda IS NOT NULL THEN
			DISPLAY '' TO moneda1
			INITIALIZE rm_imp.g00_decimal_mb TO NULL
			DISPLAY '' to g00_decimal_mb
			CONTINUE INPUT
		END IF
		IF moneda <> rm_imp.g00_moneda_base OR moneda IS NULL THEN
			CALL fl_lee_moneda(rm_imp.g00_moneda_base) 
                             RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                                      	            'Moneda no existe',        
                                                    'exclamation')
				INITIALIZE rm_imp.g00_decimal_mb TO NULL
				DISPLAY BY NAME rm_imp.g00_decimal_mb
				CLEAR moneda1
				NEXT FIELD g00_moneda_base
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                                      	 	           'Moneda está ' ||
                                                           'bloqueada',        
                                                           'exclamation')
					INITIALIZE rm_imp.g00_decimal_mb TO NULL
					DISPLAY BY NAME rm_imp.g00_decimal_mb
					CLEAR moneda1
					NEXT FIELD g00_moneda_base
				ELSE
					DISPLAY r_mon.g13_decimales TO g00_decimal_mb
					LET rm_imp.g00_decimal_mb = r_mon.g13_decimales
					DISPLAY r_mon.g13_nombre TO moneda1
				END IF
			END IF 
		END IF 
		IF rm_imp.g00_moneda_base = moneda THEN
			CALL fl_lee_moneda(rm_imp.g00_moneda_base) 
                        	RETURNING r_mon.*
				IF r_mon.g13_moneda IS NULL THEN	
					CALL FGL_WINMESSAGE(vg_producto, 
                                      		            'Moneda no existe',
			                                    'exclamation')
					INITIALIZE rm_imp.g00_decimal_mb TO NULL
					DISPLAY BY NAME rm_imp.g00_decimal_mb
					CLEAR moneda1
					NEXT FIELD g00_moneda_base
				ELSE
					IF r_mon.g13_estado = 'B' THEN
						CALL FGL_WINMESSAGE(vg_producto,
	                                                       'Moneda está ' ||
                                                               'bloqueada', 
                                                               'exclamation')
						INITIALIZE rm_imp.g00_decimal_mb
							TO NULL
						DISPLAY BY NAME 
							rm_imp.g00_decimal_mb
						CLEAR moneda1
						NEXT FIELD g00_moneda_base
					ELSE
					IF rm_imp.g00_moneda_alt IS NOT NULL 
					THEN
					CALL fl_lee_factor_moneda(
						r_mon.g13_moneda,
						rm_imp.g00_moneda_alt)
							RETURNING r_g14.*
					IF r_g14.g14_tasa IS NULL THEN
						CALL fgl_winmessage(vg_producto,							'Esta moneda no ' ||
							'tiene tasa de ' ||
							'conversión a la ' ||
							'moneda alterna',
							'exclamation')
						NEXT FIELD g00_moneda_base
					END IF
					END IF
					DISPLAY r_mon.g13_decimales 
						TO g00_decimal_mb
					LET rm_imp.g00_decimal_mb = 
						r_mon.g13_decimales
					DISPLAY r_mon.g13_nombre TO moneda1
					END IF
				END IF
		END IF
	BEFORE FIELD g00_moneda_alt
		LET moneda = rm_imp.g00_moneda_alt
	AFTER FIELD g00_moneda_alt
		IF rm_imp.g00_moneda_alt IS NULL AND moneda IS NULL THEN
			CLEAR moneda2
			CLEAR g00_decimal_ma
			CONTINUE INPUT
		END IF
		IF rm_imp.g00_moneda_alt IS NULL AND moneda IS NOT NULL THEN
			DISPLAY '' TO moneda2
			INITIALIZE rm_imp.g00_decimal_ma TO NULL
			DISPLAY BY NAME rm_imp.g00_decimal_ma
			CONTINUE INPUT
		END IF
		IF moneda <> rm_imp.g00_moneda_alt OR moneda IS NULL THEN
			CALL fl_lee_moneda(rm_imp.g00_moneda_alt) 
                             RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                                      	            'Moneda no existe',                                                             'exclamation')
				CLEAR g00_decimal_ma
				CLEAR moneda2
				NEXT FIELD g00_moneda_alt 
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                                      	 	           'Moneda está ' ||
                                                           'bloqueada',        
                                                           'exclamation')
					CLEAR g00_decimal_ma
					CLEAR moneda2
					NEXT FIELD g00_moneda_alt
				ELSE
					IF rm_imp.g00_moneda_base IS NOT NULL 
					THEN
					CALL fl_lee_factor_moneda(
						r_mon.g13_moneda,
						rm_imp.g00_moneda_base)
							RETURNING r_g14.*
					IF r_g14.g14_tasa IS NULL THEN
						CALL fgl_winmessage(vg_producto,							'Esta moneda no ' ||
							'tiene tasa de ' ||
							'conversión a la ' ||
							'moneda base',
							'exclamation')
						NEXT FIELD g00_moneda_alt 
					END IF
					END IF
					DISPLAY r_mon.g13_decimales 
						TO g00_decimal_ma
					LET rm_imp.g00_decimal_ma = 
						r_mon.g13_decimales
					DISPLAY r_mon.g13_nombre TO moneda2
				END IF
			END IF 
		END IF 
		IF rm_imp.g00_moneda_alt = moneda THEN
			CALL fl_lee_moneda(rm_imp.g00_moneda_alt) 
                        	RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                                      	            'Moneda no existe',                                                             'exclamation')
				CLEAR g00_decimal_ma
				CLEAR moneda2
				NEXT FIELD g00_moneda_alt 
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                                        	            'Moneda está ' ||
                                                	    'bloqueada',        
                                      		            'exclamation')
					INITIALIZE rm_imp.g00_decimal_ma TO NULL
					DISPLAY BY NAME rm_imp.g00_decimal_ma
					CLEAR moneda2
					NEXT FIELD g00_moneda_alt
				ELSE
					DISPLAY r_mon.g13_decimales TO g00_decimal_ma
					LET rm_imp.g00_decimal_ma = r_mon.g13_decimales
					DISPLAY r_mon.g13_nombre TO moneda2
				END IF
			END IF
		END IF
	AFTER FIELD g00_decimal_mb
		IF rm_imp.g00_moneda_base IS NOT NULL THEN
			IF rm_imp.g00_decimal_mb IS NULL THEN
				LET rm_imp.g00_decimal_mb = 0
				DISPLAY BY NAME rm_imp.g00_decimal_mb
			END IF
		END IF
		IF rm_imp.g00_moneda_base IS NULL THEN 
			INITIALIZE rm_imp.g00_decimal_mb TO NULL
			DISPLAY BY NAME rm_imp.g00_decimal_mb
		END IF
	AFTER FIELD g00_decimal_ma
		IF rm_imp.g00_moneda_alt IS NOT NULL THEN 
			IF rm_imp.g00_decimal_ma IS NULL THEN
				LET rm_imp.g00_decimal_ma = 0
				DISPLAY BY NAME rm_imp.g00_decimal_ma
			END IF
		END IF
		IF rm_imp.g00_moneda_alt IS NULL THEN 
			INITIALIZE rm_imp.g00_decimal_ma TO NULL
			DISPLAY BY NAME rm_imp.g00_decimal_ma
		END IF
	AFTER INPUT
		IF rm_imp.g00_moneda_base = rm_imp.g00_moneda_alt THEN
			CALL FGL_WINMESSAGE(vg_producto, 
                         	           'La moneda base y la alterna no ' ||
                                           'pueden ser iguales' ,        
                                           'exclamation')
			INITIALIZE rm_imp.g00_decimal_ma TO NULL
			CLEAR moneda2
			NEXT FIELD g00_moneda_alt
		END IF
	-- VALIDA QUE LAS MONEDAS NO HAYAN SIDO BLOQUEADAS
		CALL fl_lee_moneda(rm_imp.g00_moneda_base) 
                       	RETURNING r_mon.*
		IF r_mon.g13_estado = 'B' THEN
			CALL FGL_WINMESSAGE(vg_producto, 
                                            'Moneda base fue ' ||
                                            'bloqueada',        
                                            'exclamation')
			INITIALIZE rm_imp.g00_decimal_mb TO NULL
			DISPLAY BY NAME rm_imp.g00_decimal_mb
			CLEAR moneda1
			NEXT FIELD g00_moneda_base
		ELSE
			DISPLAY r_mon.g13_decimales TO g00_decimal_mb
			LET rm_imp.g00_decimal_mb = r_mon.g13_decimales
			DISPLAY r_mon.g13_nombre TO moneda1
		END IF
		CALL fl_lee_moneda(rm_imp.g00_moneda_alt) 
                       	RETURNING r_mon.*
		IF r_mon.g13_estado = 'B' THEN
			CALL FGL_WINMESSAGE(vg_producto, 
                                            'Moneda alterna fue ' ||
                                            'bloqueada',        
                                            'exclamation')
			INITIALIZE rm_imp.g00_decimal_ma TO NULL
			DISPLAY BY NAME rm_imp.g00_decimal_ma
			CLEAR moneda2
			NEXT FIELD g00_moneda_alt
		ELSE
			DISPLAY r_mon.g13_decimales TO g00_decimal_ma
			LET rm_imp.g00_decimal_ma = r_mon.g13_decimales
			DISPLAY r_mon.g13_nombre TO moneda2
		END IF
END INPUT

END FUNCTION



FUNCTION control_modificacion()

DEFINE last		LIKE gent000.g00_serial
IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])
-- Los registros historicos no deben ser modificados
SELECT MAX(g00_serial) INTO last FROM gent000
IF rm_imp.g00_serial <> last THEN
	CALL FGL_WINMESSAGE(vg_producto, 
                            'No se pueden modificar los registros históricos',
			    'exclamation')
	RETURN
END IF
--

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM gent000 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_imp.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL lee_datos()

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	FREE  q_upd
	RETURN
END IF 

UPDATE gent000 SET * = rm_imp.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
FREE  q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE impto 			LIKE gent000.g00_serial
DEFINE porc			LIKE gent000.g00_porc_impto    -- DUMMY
DEFINE label			LIKE gent000.g00_label_impto   -- DUMMY

DEFINE r_mon			RECORD LIKE gent013.*

DEFINE g13_moneda		LIKE gent013.g13_moneda
DEFINE decimales		LIKE gent013.g13_decimales
DEFINE nombre			LIKE gent013.g13_nombre

CLEAR FORM

LET INT_FLAG = 0
INITIALIZE impto TO NULL
INITIALIZE r_mon.* TO NULL

CONSTRUCT BY NAME expr_sql ON g00_serial, g00_porc_impto, g00_label_impto,
                              g00_moneda_base, g00_moneda_alt, g00_decimal_mb,
                              g00_decimal_ma, g00_usuario
	ON KEY(F2)
		IF INFIELD(g00_serial) THEN
			CALL fl_ayuda_imptos() RETURNING impto, porc, label
			IF impto IS NOT NULL THEN
				LET rm_imp.g00_serial = impto
				DISPLAY impto TO g00_serial
			END IF
		END IF
		IF INFIELD(g00_moneda_base) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_imp.g00_moneda_base = g13_moneda
				DISPLAY g13_moneda TO g00_moneda_base
				DISPLAY nombre TO moneda1
			END IF	
			IF rm_imp.g00_moneda_base = '' THEN
				DISPLAY '' TO moneda1
			END IF
		END IF
		IF INFIELD(g00_moneda_alt) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_imp.g00_moneda_alt = g13_moneda
				DISPLAY g13_moneda TO g00_moneda_alt
				DISPLAY nombre TO moneda2
			END IF	
		END IF
		LET INT_FLAG = 0
	AFTER FIELD g00_moneda_base
		LET rm_imp.g00_moneda_base = GET_FLDBUF(g00_moneda_base)
		IF rm_imp.g00_moneda_base IS NULL THEN
			CLEAR moneda1
		ELSE
			CALL fl_lee_moneda(rm_imp.g00_moneda_base) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR  moneda1
			ELSE
				DISPLAY r_mon.g13_nombre TO moneda1
			END IF 
		END IF
	AFTER FIELD g00_moneda_alt
		LET rm_imp.g00_moneda_alt = GET_FLDBUF(g00_moneda_alt)
		IF rm_imp.g00_moneda_alt IS NULL THEN
			CLEAR moneda2
		ELSE
			CALL fl_lee_moneda(rm_imp.g00_moneda_alt) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR  moneda2
			ELSE
				DISPLAY r_mon.g13_nombre TO moneda2
			END IF 
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM gent000 WHERE ', expr_sql, 'ORDER BY 1 DESC' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_imp.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_imp.* FROM gent000 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_imp.*
DISPLAY '' TO moneda2  
CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 70 

END FUNCTION



FUNCTION  muestra_etiquetas()

DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_lee_moneda(rm_imp.g00_moneda_base) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	DISPLAY 'Moneda ha sido eliminada' TO moneda1
ELSE 
	DISPLAY r_g13.g13_nombre TO moneda1
END IF
IF rm_imp.g00_moneda_alt IS NOT NULL THEN
	CALL fl_lee_moneda(rm_imp.g00_moneda_alt) RETURNING r_g13.*
	IF r_g13.g13_moneda IS NULL THEN
		DISPLAY 'Moneda ha sido eliminada' TO moneda2
	ELSE 
		DISPLAY r_g13.g13_nombre TO moneda2
	END IF
END IF


END FUNCTION



FUNCTION no_validar_parametros()

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
