{*
 * Titulo               : repp100.4gl -- Mantenimiento Configuración parametros
 *  		  			  por Compañia
 * Elaboración          : 04-feb-2009
 * Autor                : JCM
 * Formato de Ejecución : fglrun  repp100.4gl base RE 1 
 *}
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_pcia   RECORD LIKE rept000.*
DEFINE rm_pcia2  RECORD LIKE rept000.*
DEFINE rm_bod    RECORD LIKE rept002.*
DEFINE rm_cia    RECORD LIKE gent001.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp100.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp100'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_pcia AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_pcia FROM '../forms/repf100_1'
DISPLAY FORM f_pcia
INITIALIZE rm_pcia.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
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
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
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
        COMMAND KEY('E') 'Bloquear/Activar' 'Bloquear o activar registro. '
                CALL control_bloqueo_activacion()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE r_b10		RECORD LIKE ctbt010.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r00_compania, r00_cia_taller, r00_cliente_final,
		 r00_bodega_fact,
		 r00_cred_auto, r00_dias_dev,
		 r00_dias_prof, r00_expi_prof
	ON KEY(F2)
		IF INFIELD(r00_compania) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_cia.g01_compania
		     IF rm_cia.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_cia.g01_compania)
				RETURNING rm_cia.*
			LET rm_pcia.r00_compania = rm_cia.g01_compania
			DISPLAY BY NAME rm_pcia.r00_compania
			DISPLAY rm_cia.g01_razonsocial TO nom_cia
		     END IF
		END IF
		IF INFIELD(r00_cia_taller) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_cia.g01_compania
		     IF rm_cia.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_cia.g01_compania)
				RETURNING rm_cia.*
			LET rm_pcia.r00_cia_taller = rm_cia.g01_compania
			DISPLAY BY NAME rm_pcia.r00_cia_taller
			DISPLAY rm_cia.g01_razonsocial TO nom_cia_tal
		     END IF
		END IF
		IF INFIELD(r00_bodega_fact) THEN
		     CALL fl_ayuda_bodegas_rep(rm_pcia.r00_compania, vg_codloc, 'F')
		     RETURNING rm_bod.r02_codigo, rm_bod.r02_nombre
		     IF rm_bod.r02_codigo IS NOT NULL THEN
			LET rm_pcia.r00_bodega_fact = rm_bod.r02_codigo
			DISPLAY BY NAME rm_pcia.r00_bodega_fact
			DISPLAY rm_bod.r02_nombre TO nom_bod
		     END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows >0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rept000 WHERE ', expr_sql CLIPPED,
		' ORDER BY 1'
PREPARE cons FROM query
DECLARE q_pcia CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_pcia INTO rm_pcia.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
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

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_pcia.* TO NULL
INITIALIZE rm_bod.* TO NULL
INITIALIZE rm_pcia2.* TO NULL
LET vm_flag_mant            = 'I'
LET rm_pcia.r00_estado      = 'A'
LET rm_pcia.r00_dev_mes     = 'S'
LET rm_pcia.r00_cred_auto   = 'S'
LET rm_pcia.r00_tipo_costo  = 'P'
LET rm_pcia.r00_tipo_margen = 'L'
LET rm_pcia.r00_tipo_descto = 'L'
LET rm_pcia.r00_tipo_fact   = 'U'
LET rm_pcia.r00_contr_prof  = 'S'
LET rm_pcia.r00_fact_sstock = 'N'
LET rm_pcia.r00_mespro      = MONTH(TODAY)
LET rm_pcia.r00_anopro      = YEAR(TODAY)
DISPLAY BY NAME rm_pcia.r00_estado
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO rept000 VALUES (rm_pcia.*)
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()

LET vm_flag_mant      = 'M'
IF rm_pcia.r00_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM rept000 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_pcia.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE rept000 SET * = rm_pcia.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp     CHAR(6)
DEFINE i        SMALLINT
DEFINE mensaje  VARCHAR(20)
DEFINE estado   CHAR(1)
                                                                                
LET int_flag = 0

IF rm_pcia.r00_compania IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
        RETURN
END IF

LET mensaje = 'Seguro de bloquear'
IF rm_pcia.r00_estado <> 'A' THEN
        LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
        RETURNING resp
IF resp = 'Yes' THEN
WHENEVER ERROR CONTINUE
        BEGIN WORK
        DECLARE q_del CURSOR FOR SELECT * FROM rept000
                WHERE ROWID = vm_r_rows[vm_row_current]
                FOR UPDATE
        OPEN q_del
        FETCH q_del INTO rm_pcia.*
        IF status < 0 THEN
                COMMIT WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
                WHENEVER ERROR STOP
                RETURN
        END IF
        LET estado = 'B'
        IF rm_pcia.r00_estado <> 'A' THEN
                LET estado = 'A'
        END IF
        UPDATE rept000 SET r00_estado = estado WHERE CURRENT OF q_del
        COMMIT WORK
        LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
        CLEAR FORM
        CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
                                                                                
END FUNCTION



FUNCTION lee_datos()
DEFINE     resp   	CHAR(6)
DEFINE     r_z01	RECORD LIKE cxct001.*
DEFINE r_b10		RECORD LIKE ctbt010.*
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_pcia.r00_compania,    rm_pcia.r00_cia_taller, 
	      rm_pcia.r00_codcli_tal, rm_pcia.r00_cliente_final, 
		  rm_pcia.r00_bodega_fact, 
		  rm_pcia.r00_numlin_fact, rm_pcia.r00_fact_sstock,
	      rm_pcia.r00_cred_auto, rm_pcia.r00_dev_mes,
	      rm_pcia.r00_dias_dev,   
	      rm_pcia.r00_tipo_costo,  
	      rm_pcia.r00_tipo_margen, rm_pcia.r00_tipo_descto,
	      rm_pcia.r00_tipo_fact,   
	      rm_pcia.r00_contr_prof,
	      rm_pcia.r00_dias_prof,   rm_pcia.r00_expi_prof,  
	      rm_pcia.r00_mespro,      rm_pcia.r00_anopro   
	      WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF FIELD_TOUCHED(r00_compania,    r00_cia_taller,
				r00_cliente_final,
			          r00_bodega_fact, r00_dias_prof,
				  r00_expi_prof,   r00_dias_dev, 
				  r00_tipo_fact,   r00_numlin_fact,
				  r00_tipo_margen, r00_tipo_costo,
				  r00_cred_auto,   r00_tipo_descto,
				  r00_codcli_tal,  r00_contr_prof)
                    THEN
                        LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                             LET INT_FLAG = 1
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
		IF INFIELD(r00_codcli_tal) THEN
			CALL fl_ayuda_cliente_general()
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_pcia.r00_codcli_tal = r_z01.z01_codcli
				DISPLAY BY NAME rm_pcia.r00_codcli_tal
				DISPLAY r_z01.z01_nomcli TO nom_cli_tal	
			END IF
		END IF
		IF INFIELD(r00_cliente_final) THEN
			CALL fl_ayuda_cliente_general()
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_pcia.r00_cliente_final = r_z01.z01_codcli
				DISPLAY BY NAME rm_pcia.r00_cliente_final
				DISPLAY r_z01.z01_nomcli TO nom_cli_final	
			END IF
		END IF
		IF INFIELD(r00_compania) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_cia.g01_compania
		     IF rm_cia.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_cia.g01_compania)
				RETURNING rm_cia.*
			LET rm_pcia.r00_compania = rm_cia.g01_compania
			DISPLAY BY NAME rm_pcia.r00_compania
			DISPLAY rm_cia.g01_razonsocial TO nom_cia
		     END IF
		END IF
		IF INFIELD(r00_cia_taller) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_cia.g01_compania
		     IF rm_cia.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_cia.g01_compania)
				RETURNING rm_cia.*
			LET rm_pcia.r00_cia_taller = rm_cia.g01_compania
			DISPLAY BY NAME rm_pcia.r00_cia_taller
			DISPLAY rm_cia.g01_razonsocial TO nom_cia_tal
		     END IF
		END IF
		IF INFIELD(r00_bodega_fact) THEN
		     CALL fl_ayuda_bodegas_rep(rm_pcia.r00_compania, vg_codloc, 'F')
		     	RETURNING rm_bod.r02_codigo, rm_bod.r02_nombre
		     IF rm_bod.r02_codigo IS NOT NULL THEN
			LET rm_pcia.r00_bodega_fact = rm_bod.r02_codigo
			DISPLAY BY NAME rm_pcia.r00_bodega_fact
			DISPLAY rm_bod.r02_nombre TO nom_bod
		     END IF
		END IF
                LET INT_FLAG = 0

	BEFORE  FIELD r00_compania
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF

	AFTER FIELD r00_compania
		IF rm_pcia.r00_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_pcia.r00_compania)
				RETURNING rm_cia.*
			IF rm_cia.g01_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la compañía ','exclamation')
				NEXT FIELD r00_compania
			END IF
			DISPLAY rm_cia.g01_razonsocial TO nom_cia
			CALL fl_lee_compania_repuestos(rm_pcia.r00_compania)
				RETURNING rm_pcia2.*
			IF rm_pcia2.r00_compania IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto, 'Ya existe configuración para esta compañía ','exclamation')
				NEXT FIELD r00_compania
			END IF
		ELSE
			CLEAR nom_cia
		END IF

	AFTER FIELD r00_cia_taller
		IF rm_pcia.r00_cia_taller IS NOT NULL THEN
			CALL fl_lee_compania(rm_pcia.r00_cia_taller)
				RETURNING rm_cia.*
			IF rm_cia.g01_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la compañía ','exclamation')
				NEXT FIELD r00_cia_taller
			END IF
			DISPLAY rm_cia.g01_razonsocial TO nom_cia_tal
		ELSE
			CLEAR nom_cia_tal
		END IF
	
	AFTER FIELD r00_codcli_tal
		IF rm_pcia.r00_codcli_tal IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_pcia.r00_codcli_tal)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fgl_winmessage(vg_producto,'El cliente no existe en la Compañía.','exclamation')
				NEXT FIELD r00_codcli_tal
			END IF
			DISPLAY r_z01.z01_nomcli TO nom_cli_tal
			IF rm_pcia.r00_compania = rm_pcia.r00_cia_taller THEN
				INITIALIZE rm_pcia.r00_codcli_tal TO NULL
				DISPLAY BY NAME rm_pcia.r00_codcli_tal
				CLEAR nom_cli_tal
			END IF
		ELSE
			CLEAR nom_cli_tal
		END IF

	AFTER FIELD r00_cliente_final
		IF rm_pcia.r00_cliente_final IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_pcia.r00_cliente_final)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fgl_winmessage(vg_producto,'El cliente no existe en la Compañía.','exclamation')
				NEXT FIELD r00_cliente_final
			END IF
			DISPLAY BY NAME rm_pcia.r00_cliente_final
			DISPLAY r_z01.z01_nomcli TO nom_cli_final
		ELSE
			CLEAR nom_cli_final
		END IF

	AFTER FIELD r00_bodega_fact
		IF rm_pcia.r00_bodega_fact IS NOT NULL THEN
                	CALL fl_lee_bodega_rep(rm_pcia.r00_compania,
			                       rm_pcia.r00_bodega_fact)
                       		RETURNING rm_bod.*
                        IF rm_bod.r02_codigo IS NULL THEN
                                CALL fgl_winmessage (vg_producto, 'La Bodega no existe en la compañía ','exclamation')
                                NEXT FIELD r00_bodega_fact
                        END IF
			IF rm_bod.r02_factura = 'N' THEN
                                CALL fgl_winmessage (vg_producto, 'La Bodega no factura ','exclamation')
				NEXT FIELD r00_pcia.r00_bodega_fact
			END IF
			DISPLAY rm_bod.r02_nombre TO nom_bod
		ELSE
			CLEAR nom_bod
		END IF

	AFTER FIELD r00_tipo_descto
		IF rm_pcia.r00_tipo_descto = 'L' THEN
			LET rm_pcia.r00_tipo_margen = 'L'
			DISPLAY BY NAME rm_pcia.r00_tipo_margen
		ELSE
			LET rm_pcia.r00_tipo_margen = 'I'
			DISPLAY BY NAME rm_pcia.r00_tipo_margen
		END IF

	AFTER FIELD r00_tipo_margen
		IF rm_pcia.r00_tipo_margen = 'L' THEN
			LET rm_pcia.r00_tipo_descto = 'L'
			DISPLAY BY NAME rm_pcia.r00_tipo_descto
		ELSE
			LET rm_pcia.r00_tipo_descto = 'I'
			DISPLAY BY NAME rm_pcia.r00_tipo_descto
		END IF

	AFTER FIELD r00_numlin_fact
		IF rm_pcia.r00_numlin_fact IS NOT NULL THEN	
			IF rm_pcia.r00_tipo_fact = 'M' THEN
				LET rm_pcia.r00_numlin_fact = 9999
				DISPLAY BY NAME rm_pcia.r00_numlin_fact
			ELSE 
				IF rm_pcia.r00_numlin_fact > 60 THEN
					CALL FGL_WINMESSAGE(vg_producto,'No puede ingresar un número de líneas superior a 60 cuando es una sola página. ','exclamation')
					NEXT FIELD r00_numlin_fact
				END IF
			END IF
		END IF

	AFTER FIELD r00_tipo_fact
		IF rm_pcia.r00_tipo_fact = 'M' THEN
			LET rm_pcia.r00_numlin_fact = 9999
			DISPLAY BY NAME rm_pcia.r00_numlin_fact
		ELSE
			IF rm_pcia.r00_numlin_fact > 60 THEN
				CALL FGL_WINMESSAGE(vg_producto,'No puede ingresar un número de líneas superior a 60 cuando es una sola página. ','exclamation')
				NEXT FIELD r00_numlin_fact
			END IF
		END IF

	AFTER INPUT
		IF rm_pcia.r00_compania <> rm_pcia.r00_cia_taller AND
		   rm_pcia.r00_codcli_tal IS NULL 
		   THEN
			CALL fgl_winmessage(vg_producto,'Digite el cliente de la Compañía Taller. ','exclamation')
			NEXT FIELD r00_codcli_tal
		END IF
		IF rm_pcia.r00_compania = rm_pcia.r00_cia_taller AND
		   rm_pcia.r00_codcli_tal IS NOT NULL 
		   THEN
			CALL fgl_winmessage(vg_producto,'No debe digitar cliente si la Compañía Taller es la misma de Repuesto. ','exclamation')
			NEXT FIELD r00_codcli_tal
		END IF

END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_z01	RECORD LIKE cxct001.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_pcia.* FROM rept000 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_pcia.r00_compania THRU rm_pcia.r00_mespro     
CALL fl_lee_bodega_rep(vg_codcia,rm_pcia.r00_bodega_fact)
	RETURNING rm_bod.*
	DISPLAY rm_bod.r02_nombre TO nom_bod
CALL fl_lee_compania(rm_pcia.r00_compania)
	RETURNING rm_cia.*
	DISPLAY rm_cia.g01_razonsocial TO nom_cia
CALL fl_lee_compania(rm_pcia.r00_cia_taller)
	RETURNING rm_cia.*
	DISPLAY rm_cia.g01_razonsocial TO nom_cia_tal
IF rm_pcia.r00_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF
DISPLAY rm_bod.r02_nombre TO nom_bod

CALL fl_lee_cliente_general(rm_pcia.r00_cliente_final) RETURNING r_z01.*
DISPLAY r_z01.z01_nomcli TO nom_cli_final


END FUNCTION


FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
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

