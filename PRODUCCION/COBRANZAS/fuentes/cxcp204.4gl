{
 * Titulo           : cxcp204.4gl - Solicitud cobros a clientes por pago de
 *                                  documentos 
 * Elaboracion      : 16-nov-2001
 * Autor            : JCM
 * Formato Ejecucion: fglrun cxcp204 base modulo compania localidad
}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

DEFINE vm_cheque	CHAR(2)
DEFINE vm_efectivo	CHAR(2)

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT

---
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_z24			RECORD LIKE cxct024.*

DEFINE vm_indice        SMALLINT
DEFINE vm_max_indice    SMALLINT
DEFINE rm_docs  ARRAY[1000] OF  RECORD 
    tipo_doc            LIKE cxct025.z25_tipo_doc,
    num_doc             LIKE cxct025.z25_num_doc,
    dividendo           LIKE cxct025.z25_dividendo,
    interes             LIKE cxct025.z25_valor_int,
    capital             LIKE cxct025.z25_valor_cap,
    valor_pagar         DECIMAL (12,2)          
END RECORD
DEFINE r_z101 ARRAY[50] OF RECORD 
	forma_pago		LIKE cxct101.z101_codigo_pago, 
	moneda			LIKE cxct101.z101_moneda, 
	cod_bco_tarj	LIKE cxct101.z101_cod_bco_tarj, 
	num_ch_aut		LIKE cxct101.z101_num_ch_aut, 
	num_cta_tarj	LIKE cxct101.z101_num_cta_tarj,
	valor			LIKE cxct101.z101_valor 
END RECORD
DEFINE vm_fecha ARRAY[1000] OF 	LIKE cxct020.z20_fecha_vcto



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp204.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp204'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE i 		SMALLINT

CALL fl_nivel_isolation()
CALL fl_control_status_caja(vg_codcia, vg_codloc, 'S') RETURNING int_flag
IF int_flag <> 0 THEN
	RETURN
END IF	
CALL fl_chequeo_mes_proceso_cxc(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_204 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_204 FROM '../forms/cxcf204_1'
DISPLAY FORM f_204

LET vm_cheque   = 'CH'
LET vm_efectivo = 'EF'

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_z24.* TO NULL
CALL muestra_contadores()
CALL setea_nombre_botones_f1()

CREATE TEMP TABLE tmp_detalle(
	tipo_doc            CHAR(2), 
	num_doc             CHAR(15),                
	dividendo           SMALLINT,                   
	interes             DECIMAL(12,2),             
	capital             DECIMAL(12,2),              
	valor_pagar         DECIMAL(12,2),
	fecha_vcto	    DATE
)
CREATE UNIQUE INDEX tmp_pk
	ON tmp_detalle(tipo_doc ASC, num_doc ASC, dividendo ASC)

FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

LET vm_max_rows   = 1000
LET vm_max_indice = 1000

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Detalle'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN

		   IF fl_control_permiso_opcion('Modificar') THEN
			   SHOW OPTION 'Modificar'
		   END IF
		   IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   END IF
			
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			IF vm_num_rows > 0 THEN
				SHOW OPTION 'Detalle'
			END IF
		END IF
		CALL setea_nombre_botones_f1()
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
		CALL setea_nombre_botones_f1()
	COMMAND KEY('P') 'Imprimir'			'Imprime la solicitud de cobo.'
		CALL imprimir()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN

		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
		   
		   IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   END IF
			
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
		   
		   IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   END If
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		CALL setea_nombre_botones_f1()
	COMMAND KEY('D') 'Detalle'		'Ver detalles'
		CALL control_detalle()
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

DEFINE rowid 		SMALLINT
DEFINE done  		SMALLINT
DEFINE i     		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

CLEAR FORM
INITIALIZE rm_z24.* TO NULL

LET rm_z24.z24_compania   = vg_codcia
LET rm_z24.z24_localidad  = vg_codloc
LET rm_z24.z24_usuario    = vg_usuario
LET rm_z24.z24_fecing     = CURRENT
LET rm_z24.z24_tipo       = 'P' -- Solicitud de cobro de documentos
LET rm_z24.z24_tasa_mora  = 0	-- Hasta que se im[lemente el proceso 
LET rm_z24.z24_total_mora = 0   -- para calcular el interes por mora
LET rm_z24.z24_subtipo    = 1	-- No se sabe que es
LET rm_z24.z24_estado     = 'A'
DISPLAY 'ACTIVO' TO n_estado

LET rm_z24.z24_moneda     = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_z24.z24_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda
LET rm_z24.z24_paridad = 
	calcula_paridad(rm_z24.z24_moneda, rg_gen.g00_moneda_base)
DISPLAY BY NAME rm_z24.z24_paridad

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

CALL ingresa_detalle('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET done = 0
FOR i = 1 TO vm_indice 
	IF rm_docs[i].valor_pagar > 0 THEN
		LET done = 1
		EXIT FOR
	END IF
END FOR

IF NOT done THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

LET rm_z24.z24_total_int = 0
LET rm_z24.z24_total_cap = 0
FOR i = 1 TO vm_indice
	IF rm_docs[i].valor_pagar <= rm_docs[i].interes THEN
		LET rm_z24.z24_total_int =
			rm_z24.z24_total_int + rm_docs[i].valor_pagar
	ELSE
		LET rm_z24.z24_total_int =
			rm_z24.z24_total_int + rm_docs[i].interes     
		LET rm_z24.z24_total_cap = 
			rm_z24.z24_total_cap + 
			(rm_docs[i].valor_pagar - rm_docs[i].interes)
	END IF
END FOR

SELECT MAX(z24_numero_sol) INTO rm_z24.z24_numero_sol
	FROM cxct024
	WHERE z24_compania  = vg_codcia
	  AND z24_localidad = vg_codloc
IF rm_z24.z24_numero_sol IS NULL THEN
	LET rm_z24.z24_numero_sol = 1
ELSE
	LET rm_z24.z24_numero_sol = rm_z24.z24_numero_sol + 1
END IF

INSERT INTO cxct024 VALUES (rm_z24.*)
DISPLAY BY NAME rm_z24.z24_numero_sol

LET rowid = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                -- procesada
LET done = graba_detalle()
IF NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF

LET done = actualiza_caja()
IF NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF

CALL mantenimiento_medio_de_pago('I')

COMMIT WORK

LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = rowid            

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

DEFINE done 		SMALLINT
DEFINE i    		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_z24.z24_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,
		'No puede modificar este registro.',
		'exclamation')
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR 
	SELECT * FROM cxct024 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_z24.*
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN
END IF  
WHENEVER ERROR STOP

CALL lee_datos('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

CALL ingresa_detalle('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF

LET rm_z24.z24_total_int = 0
LET rm_z24.z24_total_cap = 0
FOR i = 1 TO vm_indice
	IF rm_docs[i].valor_pagar <= rm_docs[i].interes THEN
		LET rm_z24.z24_total_int =
			rm_z24.z24_total_int + rm_docs[i].valor_pagar
	ELSE
		LET rm_z24.z24_total_int =
			rm_z24.z24_total_int + rm_docs[i].interes     
		LET rm_z24.z24_total_cap = 
			rm_z24.z24_total_cap + 
			(rm_docs[i].valor_pagar - rm_docs[i].interes)
	END IF
END FOR

LET int_flag = 0

UPDATE cxct024 SET * = rm_z24.* WHERE CURRENT OF q_upd

LET done = graba_detalle()
IF NOT done THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

LET done = actualiza_caja()
IF NOT done THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

CALL mantenimiento_medio_de_pago('M')

COMMIT WORK
CLOSE q_upd
FREE  q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z05		RECORD LIKE cxct005.*
DEFINE r_mon		RECORD LIKE gent013.*

LET INT_FLAG = 0
INPUT BY NAME rm_z24.z24_codcli,  rm_z24.z24_areaneg, rm_z24.z24_linea, 
	      rm_z24.z24_estado,
	      rm_z24.z24_moneda,  rm_z24.z24_cobrador, rm_z24.z24_referencia,
	      rm_z24.z24_usuario, rm_z24.z24_fecing 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(z24_areaneg, z24_codcli, z24_moneda,
				     z24_cobrador, z24_referencia, z24_linea 
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
		IF INFIELD(z24_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
				RETURNING r_g03.g03_areaneg,
					  r_g03.g03_nombre
			IF r_g03.g03_areaneg IS NOT NULL THEN
				LET rm_z24.z24_areaneg = r_g03.g03_areaneg
				DISPLAY BY NAME rm_z24.z24_areaneg
				DISPLAY r_g03.g03_nombre TO n_areaneg
			END IF
		END IF
		IF INFIELD(z24_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia) 
				RETURNING r_g20.g20_grupo_linea,
					  r_g20.g20_nombre
			IF r_g20.g20_grupo_linea IS NOT NULL THEN
				LET rm_z24.z24_linea = r_g20.g20_grupo_linea
				DISPLAY BY NAME rm_z24.z24_linea
				DISPLAY r_g20.g20_nombre TO n_linea
			END IF
		END IF
		IF INFIELD(z24_codcli) THEN
         	  	CALL fl_ayuda_cliente_general() 
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN	
                  		LET rm_z24.z24_codcli = r_z01.z01_codcli
                 		DISPLAY BY NAME rm_z24.z24_codcli  
				DISPLAY r_z01.z01_nomcli TO n_cliente
			END IF
		END IF
		IF INFIELD(z24_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_z24.z24_moneda = r_mon.g13_moneda
				DISPLAY BY NAME rm_z24.z24_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		IF INFIELD(z24_cobrador) THEN
			CALL fl_ayuda_cobradores(vg_codcia) 
					RETURNING r_z05.z05_codigo,
						  r_z05.z05_nombres
			IF r_z05.z05_codigo IS NOT NULL THEN
				LET rm_z24.z24_cobrador = r_z05.z05_codigo
				DISPLAY BY NAME rm_z24.z24_cobrador
				DISPLAY r_z05.Z05_nombres TO n_cobrador
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_nombre_botones_f1()
	AFTER FIELD z24_areaneg
		IF rm_z24.z24_areaneg IS NULL THEN
			CLEAR n_areaneg
			CONTINUE INPUT
		END IF
		CALL fl_lee_area_negocio(vg_codcia, rm_z24.z24_areaneg)
			RETURNING r_g03.*
		IF r_g03.g03_areaneg IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Area de negocio no existe.',
				'exclamation')
			CLEAR n_areaneg
			NEXT FIELD z24_areaneg
		END IF
		DISPLAY r_g03.g03_nombre TO n_areaneg
	AFTER FIELD z24_linea
		IF rm_z24.z24_linea IS NULL THEN
			CLEAR n_linea
			CONTINUE INPUT
		END IF
		CALL fl_lee_grupo_linea(vg_codcia, rm_z24.z24_linea)
			RETURNING r_g20.*
		IF r_g20.g20_grupo_linea IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Grupo de linea no existe.',
				'exclamation')
			CLEAR n_linea
			NEXT FIELD z24_linea
		END IF
		IF rm_z24.z24_areaneg IS NOT NULL THEN
			IF rm_z24.z24_areaneg <> r_g20.g20_areaneg THEN
				CALL fgl_winmessage(vg_producto, 
					'El grupo de línea no pertenece ' ||
					'al área de negocio.',
					'exclamation')
				CLEAR n_linea
				NEXT FIELD z24_linea 
			END IF
		ELSE
			CALL fl_lee_area_negocio(vg_codcia, r_g20.g20_areaneg)
				RETURNING r_g03.*
			LET rm_z24.z24_areaneg = r_g20.g20_areaneg
			DISPLAY BY NAME rm_z24.z24_areaneg
			DISPLAY r_g03.g03_nombre TO n_areaneg
		END IF
		DISPLAY r_g20.g20_nombre TO n_linea
	AFTER FIELD z24_codcli
		IF rm_z24.z24_codcli IS NULL THEN
			CLEAR n_cliente
		ELSE
			CALL fl_lee_cliente_general(rm_z24.z24_codcli) 
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'No existe un cliente '||
                                                    'con ese código',
                                                    'exclamation')
				CLEAR n_cliente
				NEXT FIELD z24_codcli     
        		END IF   
			IF r_z01.z01_estado = 'B' THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'El cliente '||
                                                    'está bloqueado',
                                                    'exclamation')
				CLEAR n_cliente
				NEXT FIELD z24_codcli      
			END IF
			LET rm_z24.z24_codcli = r_z01.z01_codcli
        		DISPLAY BY NAME rm_z24.z24_codcli     
			DISPLAY r_z01.z01_nomcli TO n_cliente
		END IF
	AFTER FIELD z24_moneda
		IF rm_z24.z24_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_z24.z24_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				CLEAR n_moneda
				NEXT FIELD z24_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_moneda
					NEXT FIELD z24_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
					LET rm_z24.z24_paridad =
						calcula_paridad(
							rm_z24.z24_moneda,
							rg_gen.g00_moneda_base)
					IF rm_z24.z24_paridad IS NULL THEN
						LET rm_z24.z24_moneda =
							rg_gen.g00_moneda_base
						DISPLAY BY NAME 
							rm_z24.z24_moneda
						LET rm_z24.z24_paridad =
							calcula_paridad(
						   	     rm_z24.z24_moneda,							      rg_gen.g00_moneda_base)
					END IF
					DISPLAY BY NAME rm_z24.z24_paridad
					CALL muestra_etiquetas()
				END IF
			END IF 
		END IF
	AFTER FIELD z24_cobrador
		IF rm_z24.z24_cobrador IS NULL THEN
			CLEAR n_cobrador
			CONTINUE INPUT
		END IF
		CALL fl_lee_cobrador_cxc(vg_codcia, rm_z24.z24_cobrador)
			RETURNING r_z05.*
		IF r_z05.z05_codigo IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Cobrador no existe.',
				'exclamation')
			CLEAR n_cobrador
			NEXT FIELD z24_cobrador
		END IF
		IF r_z05.z05_estado = 'B' THEN
			CALL fgl_winmessage(vg_producto,
				'Cobrador está bloqueado.',
				'exclamation')
			CLEAR n_cobrador
			NEXT FIELD z24_cobrador
		END IF
		DISPLAY r_z05.z05_nombres TO n_cobrador	
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_z05		RECORD LIKE cxct005.*
DEFINE r_mon		RECORD LIKE gent013.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON z24_numero_sol, z24_estado, z24_codcli, z24_areaneg, z24_linea,
	   z24_moneda, z24_cobrador, z24_referencia, z24_usuario 
	ON KEY(F2)
		IF INFIELD(z24_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
				RETURNING r_g03.g03_areaneg,
					  r_g03.g03_nombre
			IF r_g03.g03_areaneg IS NOT NULL THEN
				LET rm_z24.z24_areaneg = r_g03.g03_areaneg
				DISPLAY BY NAME rm_z24.z24_areaneg
				DISPLAY r_g03.g03_nombre TO n_areaneg
			END IF
		END IF
		IF INFIELD(z24_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia) 
				RETURNING r_g20.g20_grupo_linea,
					  r_g20.g20_nombre
			IF r_g20.g20_grupo_linea IS NOT NULL THEN
				LET rm_z24.z24_linea = r_g20.g20_grupo_linea
				DISPLAY BY NAME rm_z24.z24_linea
				DISPLAY r_g20.g20_nombre TO n_linea
			END IF
		END IF
		IF INFIELD(z24_codcli) THEN
         	  	CALL fl_ayuda_cliente_general() 
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN	
                  		LET rm_z24.z24_codcli = r_z01.z01_codcli
                 		DISPLAY BY NAME rm_z24.z24_codcli  
				DISPLAY r_z01.z01_nomcli TO n_cliente
			END IF
		END IF
		IF INFIELD(z24_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_z24.z24_moneda = r_mon.g13_moneda
				DISPLAY BY NAME rm_z24.z24_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		IF INFIELD(z24_cobrador) THEN
			CALL fl_ayuda_cobradores(vg_codcia) 
					RETURNING r_z05.z05_codigo,
						  r_z05.z05_nombres
			IF r_z05.z05_codigo IS NOT NULL THEN
				LET rm_z24.z24_cobrador = r_z05.z05_codigo
				DISPLAY BY NAME rm_z24.z24_cobrador
				DISPLAY r_z05.Z05_nombres TO n_cobrador
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE CONSTRUCT
		CALL setea_nombre_botones_f1()
	AFTER FIELD z24_areaneg
		LET rm_z24.z24_areaneg = GET_FLDBUF(z24_areaneg)
		IF rm_z24.z24_areaneg IS NULL THEN
			CLEAR n_areaneg
			CONTINUE CONSTRUCT
		END IF
		CALL fl_lee_area_negocio(vg_codcia, rm_z24.z24_areaneg)
			RETURNING r_g03.*
		IF r_g03.g03_areaneg IS NULL THEN
			CLEAR n_areaneg
		END IF
		DISPLAY r_g03.g03_nombre TO n_areaneg
	AFTER FIELD z24_linea
		LET rm_z24.z24_linea = GET_FLDBUF(z24_linea)
		IF rm_z24.z24_linea IS NULL THEN
			CLEAR n_linea
			CONTINUE CONSTRUCT
		END IF
		CALL fl_lee_grupo_linea(vg_codcia, rm_z24.z24_linea)
			RETURNING r_g20.*
		IF r_g20.g20_grupo_linea IS NULL THEN
			CLEAR n_linea
		END IF
		IF rm_z24.z24_areaneg IS NOT NULL THEN
			IF rm_z24.z24_areaneg <> r_g20.g20_areaneg THEN
				CLEAR n_linea
			END IF
		ELSE
			CALL fl_lee_area_negocio(vg_codcia, r_g20.g20_areaneg)
				RETURNING r_g03.*
			LET rm_z24.z24_areaneg = r_g20.g20_areaneg
			DISPLAY BY NAME rm_z24.z24_areaneg
			DISPLAY r_g03.g03_nombre TO n_areaneg
		END IF
		DISPLAY r_g20.g20_nombre TO n_linea
	AFTER FIELD z24_codcli
		LET rm_z24.z24_codcli = GET_FLDBUF(z24_codcli)
		IF rm_z24.z24_codcli IS NULL THEN
			CLEAR n_cliente
		ELSE
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
				rm_z24.z24_codcli) RETURNING r_z02.*
			IF r_z02.z02_codcli IS NULL THEN
				CLEAR n_cliente
			END IF
			CALL fl_lee_cliente_general(rm_z24.z24_codcli) 
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CLEAR n_cliente
        		END IF   
			IF r_z01.z01_estado = 'B' THEN
				CLEAR n_cliente
			END IF
			LET rm_z24.z24_codcli = r_z01.z01_codcli
        		DISPLAY BY NAME rm_z24.z24_codcli     
			DISPLAY r_z01.z01_nomcli TO n_cliente
		END IF
	AFTER FIELD z24_moneda
		LET rm_z24.z24_moneda = GET_FLDBUF(z24_moneda)
		IF rm_z24.z24_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_z24.z24_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
				END IF
			END IF 
		END IF
	AFTER FIELD z24_cobrador
		LET rm_z24.z24_cobrador = GET_FLDBUF(z24_cobrador)
		IF rm_z24.z24_cobrador IS NULL THEN
			CLEAR n_cobrador
			CONTINUE CONSTRUCT
		END IF
		CALL fl_lee_cobrador_cxc(vg_codcia, rm_z24.z24_cobrador)
			RETURNING r_z05.*
		IF r_z05.z05_codigo IS NULL THEN
			CLEAR n_cobrador
		END IF
		IF r_z05.z05_estado = 'B' THEN
			CLEAR n_cobrador
		END IF
		DISPLAY r_z05.z05_nombres TO n_cobrador	
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM cxct024 ',  
            ' WHERE z24_compania  = ', vg_codcia, 
	    '   AND z24_localidad = ', vg_codloc,
	    '   AND z24_tipo = "P"', 
	    '   AND ', expr_sql CLIPPED,
	    ' ORDER BY 1, 2, 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_z24.*, vm_rows[vm_num_rows]
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



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_z24.* FROM cxct024 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_z24.z24_numero_sol,
                rm_z24.z24_areaneg,
		rm_z24.z24_linea,
		rm_z24.z24_estado,
		rm_z24.z24_codcli,     
		rm_z24.z24_referencia, 
		rm_z24.z24_moneda,     
		rm_z24.z24_paridad,
		rm_z24.z24_cobrador,  
		rm_z24.z24_usuario,
		rm_z24.z24_fecing   
CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()
CALL setea_nombre_botones_f1()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

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



FUNCTION muestra_etiquetas()

DEFINE r_g20		RECORD LIKE gent020.*	
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z05		RECORD LIKE cxct005.*
DEFINE r_g13		RECORD LIKE gent013.*

DEFINE nom_estado		CHAR(9)

CASE rm_z24.z24_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'P' LET nom_estado = 'PROCESADO'
END CASE

CALL fl_lee_grupo_linea(vg_codcia, rm_z24.z24_linea) RETURNING r_g20.*
CALL fl_lee_area_negocio(vg_codcia, rm_z24.z24_areaneg) RETURNING r_g03.*
CALL fl_lee_cliente_general(rm_z24.z24_codcli) RETURNING r_z01.*
CALL fl_lee_moneda(rm_z24.z24_moneda) RETURNING r_g13.*
CALL fl_lee_cobrador_cxc(vg_codcia, rm_z24.z24_cobrador) RETURNING r_z05.*

DISPLAY nom_estado TO n_estado
DISPLAY r_g20.g20_nombre  TO n_linea
DISPLAY r_g03.g03_nombre  TO n_areaneg
DISPLAY r_z01.z01_nomcli  TO n_cliente
DISPLAY r_g13.g13_nombre  TO n_moneda
DISPLAY r_z05.z05_nombres TO n_cobrador

END FUNCTION



FUNCTION setea_nombre_botones_f1()

DISPLAY 'Tp'            TO bt_tipo_doc
DISPLAY 'Número Doc.'   TO bt_nro_doc  
DISPLAY '#'	        TO bt_dividendo 
DISPLAY 'Saldo Interés' TO bt_interes
DISPLAY 'Saldo Capital' TO bt_capital
DISPLAY 'Valor a Pagar' TO bt_valor 

END FUNCTION



FUNCTION ingresa_detalle(flag)

DEFINE flag		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE i    		SMALLINT
DEFINE j    		SMALLINT
DEFINE k    		SMALLINT
DEFINE salir		SMALLINT

DEFINE col              SMALLINT
DEFINE query            VARCHAR(500)

CASE flag          
	WHEN 'I'
		CALL lee_dividendos()
	WHEN 'M'
		CALL lee_solicitud_cobro()
END CASE
IF INT_FLAG THEN
	RETURN
END IF

IF vm_indice > vm_max_indice THEN
	CALL fl_mensaje_arreglo_incompleto()
	LET INT_FLAG = 1
	RETURN
END IF

IF vm_indice = 0 THEN
	CALL fgl_winmessage(vg_producto,
		'Cliente no tiene deudas en este área de negocio.',    
		'exclamation')
	LET INT_FLAG = 1
	RETURN
END IF

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31

LET vm_columna_1 = 7
LET vm_columna_2 = 5
LET rm_orden[vm_columna_1]  = 'ASC'
LET rm_orden[vm_columna_2]  = 'DESC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
        LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE deto FROM query
        DECLARE q_deto CURSOR FOR deto 
        LET i = 1
        FOREACH q_deto INTO rm_docs[i].*, vm_fecha[i]
		IF rm_docs[i].valor_pagar IS NULL THEN
			LET rm_docs[i].valor_pagar = 0
		END IF
                LET i = i + 1
                IF i > vm_max_indice THEN
                        EXIT FOREACH
                END IF
        END FOREACH

	LET i = 1
	LET j = 1
	LET INT_FLAG = 0
	CALL set_count(vm_indice)
	INPUT ARRAY rm_docs WITHOUT DEFAULTS FROM ra_docs.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				EXIT INPUT
			END IF
		ON KEY(F5)
			FOR i = 1 TO vm_indice
				LET rm_docs[i].valor_pagar = 
					rm_docs[i].interes + rm_docs[i].capital
			END FOR
			EXIT INPUT
      		ON KEY(F15)
      			LET rm_docs[i].valor_pagar = GET_FLDBUF(valor_pagar[j])
      			IF rm_docs[i].valor_pagar > 
				(rm_docs[i].capital + rm_docs[i].interes)
			THEN
				CALL fgl_winmessage(vg_producto,
					'Valor a pagar debe ser menor o ' ||
					'igual al saldo de la deuda.',
					'exclamation')
				NEXT FIELD valor_pagar
			END IF
			CALL graba_valores(i)
                        LET col = 1
                        EXIT INPUT  
                ON KEY(F16)
                	LET rm_docs[i].valor_pagar = GET_FLDBUF(valor_pagar[j])
      			IF rm_docs[i].valor_pagar > 
				(rm_docs[i].capital + rm_docs[i].interes)
			THEN
				CALL fgl_winmessage(vg_producto,
					'Valor a pagar debe ser menor o ' ||
					'igual al saldo de la deuda.',
					'exclamation')
				NEXT FIELD valor_pagar
			END IF
			CALL graba_valores(i)
                        LET col = 2
                        EXIT INPUT  
                ON KEY(F17)
                	LET rm_docs[i].valor_pagar = GET_FLDBUF(valor_pagar[j])
      			IF rm_docs[i].valor_pagar > 
				(rm_docs[i].capital + rm_docs[i].interes)
			THEN
				CALL fgl_winmessage(vg_producto,
					'Valor a pagar debe ser menor o ' ||
					'igual al saldo de la deuda.',
					'exclamation')
				NEXT FIELD valor_pagar
			END IF
			CALL graba_valores(i)
                        LET col = 3
                        EXIT INPUT  
                ON KEY(F18)
                	LET rm_docs[i].valor_pagar = GET_FLDBUF(valor_pagar[j])
      			IF rm_docs[i].valor_pagar > 
				(rm_docs[i].capital + rm_docs[i].interes)
			THEN
				CALL fgl_winmessage(vg_producto,
					'Valor a pagar debe ser menor o ' ||
					'igual al saldo de la deuda.',
					'exclamation')
				NEXT FIELD valor_pagar
			END IF
			CALL graba_valores(i)
                        LET col = 4
                        EXIT INPUT  
                ON KEY(F19)
                	LET rm_docs[i].valor_pagar = GET_FLDBUF(valor_pagar[j])
      			IF rm_docs[i].valor_pagar > 
				(rm_docs[i].capital + rm_docs[i].interes)
			THEN
				CALL fgl_winmessage(vg_producto,
					'Valor a pagar debe ser menor o ' ||
					'igual al saldo de la deuda.',
					'exclamation')
				NEXT FIELD valor_pagar
			END IF
			CALL graba_valores(i)
                        LET col = 5
                        EXIT INPUT  
                ON KEY(F20)
                	LET rm_docs[i].valor_pagar = GET_FLDBUF(valor_pagar[j])
      			IF rm_docs[i].valor_pagar > 
				(rm_docs[i].capital + rm_docs[i].interes)
			THEN
				CALL fgl_winmessage(vg_producto,
					'Valor a pagar debe ser menor o ' ||
					'igual al saldo de la deuda.',
					'exclamation')
				NEXT FIELD valor_pagar
			END IF
			CALL graba_valores(i)
                        LET col = 6
                        EXIT INPUT  
		BEFORE INPUT
			CALL setea_nombre_botones_f1()
			CALL dialog.keysetlabel('INSERT', '')
			CALL dialog.keysetlabel('DELETE', '')
			CALL calcula_totales()
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			DISPLAY vm_fecha[i] TO z20_fecha_vcto 
			IF vm_fecha[i] >= TODAY THEN
				DISPLAY 'Por vencer' TO n_estado_vcto
			ELSE
				DISPLAY 'Vencido' TO n_estado_vcto
			END IF
			CALL calcula_totales()
		BEFORE DELETE	
			EXIT INPUT
		BEFORE INSERT
			EXIT INPUT	
		AFTER FIELD valor_pagar
			IF rm_docs[i].valor_pagar IS NULL THEN
				LET rm_docs[i].valor_pagar = 0
				DISPLAY rm_docs[i].valor_pagar 
					TO ra_docs[j].valor_pagar
			END IF
			IF rm_docs[i].valor_pagar > 
				(rm_docs[i].capital + rm_docs[i].interes)
			THEN
				CALL fgl_winmessage(vg_producto,
					'Valor a pagar debe ser menor o ' ||
					'igual al saldo de la deuda.',
					'exclamation')
				NEXT FIELD valor_pagar
			END IF
			CALL graba_valores(i)
		AFTER INPUT
			CALL calcula_totales() 
			LET salir = 1
	END INPUT
	IF INT_FLAG THEN
		RETURN
	END IF

	IF col IS NOT NULL AND NOT salir THEN
        	IF col <> vm_columna_1 THEN
        	        LET vm_columna_2           = vm_columna_1
        	        LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
        	        LET vm_columna_1           = col
        	END IF
        	IF rm_orden[vm_columna_1] = 'ASC' THEN
        	        LET rm_orden[vm_columna_1] = 'DESC'
        	ELSE
        	        LET rm_orden[vm_columna_1] = 'ASC'
        	END IF
		INITIALIZE col TO NULL
	END IF
END WHILE

END FUNCTION



FUNCTION graba_valores(i)

DEFINE i 		SMALLINT

UPDATE tmp_detalle SET valor_pagar = rm_docs[i].valor_pagar
	WHERE tipo_doc  = rm_docs[i].tipo_doc
	  AND num_doc   = rm_docs[i].num_doc
	  AND dividendo = rm_docs[i].dividendo
			  
END FUNCTION

 
			  
FUNCTION lee_dividendos()

DELETE FROM tmp_detalle

INSERT INTO tmp_detalle
	SELECT z20_tipo_doc, z20_num_doc, z20_dividendo, z20_saldo_int, 
	       z20_saldo_cap, 0, z20_fecha_vcto
		FROM cxct020
		WHERE z20_compania  = vg_codcia
		  AND z20_localidad = vg_codloc
		  AND z20_codcli    = rm_z24.z24_codcli
		  AND z20_areaneg   = rm_z24.z24_areaneg
		  AND z20_moneda    = rm_z24.z24_moneda
		  AND z20_linea     = rm_z24.z24_linea
		  AND z20_saldo_cap > 0

SELECT COUNT(*) INTO vm_indice FROM tmp_detalle

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE veht036.v36_moneda
DEFINE moneda_dest	LIKE veht036.v36_moneda
DEFINE paridad		LIKE veht036.v36_paridad_mb

DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto, 
				    'No existe factor de conversión ' ||
				    'para esta moneda.',
				    'exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION calcula_totales()

DEFINE i      	 	SMALLINT

DEFINE interes  	LIKE cxct024.z24_total_int
DEFINE capital  	LIKE cxct024.z24_total_cap
DEFINE tot_val_pagar	LIKE cxct024.z24_total_cap

LET interes       = 0
LET capital       = 0
LET tot_val_pagar = 0
FOR i = 1 TO vm_indice
	IF rm_docs[i].interes IS NOT NULL THEN
		LET interes = interes + rm_docs[i].interes
	END IF
	IF rm_docs[i].capital IS NOT NULL THEN
		LET capital = capital + rm_docs[i].capital
	END IF
	IF rm_docs[i].valor_pagar IS NOT NULL THEN
		LET tot_val_pagar = tot_val_pagar + rm_docs[i].valor_pagar
	END IF
END FOR

LET rm_z24.z24_total_cap = capital
LET rm_z24.z24_total_int = interes

DISPLAY BY NAME tot_val_pagar,
		rm_z24.z24_total_cap,
		rm_z24.z24_total_int
		
END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
CALL fgl_winquestion(vg_producto, 
		     'Registro bloqueado por otro usuario, desea ' ||
                     'intentarlo nuevamente', 'No', 'Yes|No', 'question', 1)
				RETURNING resp
IF resp = 'No' THEN
	CALL fl_mensaje_abandonar_proceso()
		 RETURNING resp
	IF resp = 'Yes' THEN
		LET intentar = 0
	END IF	
END IF

RETURN intentar

END FUNCTION



FUNCTION graba_detalle()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE orden   		SMALLINT
DEFINE i		SMALLINT

DEFINE r_z25		RECORD LIKE cxct025.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_z25 CURSOR FOR
			SELECT * FROM cxct025
				WHERE z25_compania   = vg_codcia         
				  AND z25_localidad  = vg_codloc          
				  AND z25_numero_sol = rm_z24.z24_numero_sol
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

FOREACH q_z25
	DELETE FROM cxct025 WHERE CURRENT OF q_z25         
END FOREACH
FREE q_z25

LET r_z25.z25_compania   = vg_codcia
LET r_z25.z25_localidad  = vg_codloc
LET r_z25.z25_numero_sol = rm_z24.z24_numero_sol

LET r_z25.z25_codcli     = rm_z24.z24_codcli
LET r_z25.z25_valor_mora = 0

LET orden = 1
FOR i = 1 TO vm_indice
	IF rm_docs[i].valor_pagar <= 0 THEN
		CONTINUE FOR
	END IF

	LET r_z25.z25_orden      = orden
	LET orden = orden + 1                      

	LET r_z25.z25_tipo_doc   = rm_docs[i].tipo_doc
    	LET r_z25.z25_num_doc    = rm_docs[i].num_doc  
    	LET r_z25.z25_dividendo  = rm_docs[i].dividendo

	IF rm_docs[i].valor_pagar <= rm_docs[i].interes THEN
		LET r_z25.z25_valor_int = rm_docs[i].valor_pagar
		LET r_z25.z25_valor_cap = 0
	ELSE
		LET r_z25.z25_valor_int = rm_docs[i].interes
    		LET r_z25.z25_valor_cap = 
			rm_docs[i].valor_pagar - rm_docs[i].interes
	END IF 

	INSERT INTO cxct025 VALUES (r_z25.*)
END FOR 
LET done = 1

RETURN done

END FUNCTION



FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE tot_val_pagar 	LIKE cxct024.z24_total_cap

LET filas_pant = fgl_scr_size('ra_docs')

FOR i = 1 TO filas_pant 
	INITIALIZE rm_docs[i].* TO NULL
	CLEAR ra_docs[i].*
END FOR

CALL lee_detalle_cxct025()
IF vm_indice = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF

IF vm_indice < filas_pant THEN
	LET filas_pant = vm_indice
END IF

DECLARE q_q1 CURSOR FOR SELECT * FROM tmp_detalle
	
LET i = 1
FOREACH q_q1 INTO rm_docs[i].*, vm_fecha[i]
        LET i = i + 1
        IF i > filas_pant THEN
		EXIT FOREACH
	END IF
END FOREACH

SELECT SUM(capital), SUM(interes), SUM(valor_pagar)
	INTO rm_z24.z24_total_cap, rm_z24.z24_total_int, tot_val_pagar
	FROM tmp_detalle

DISPLAY BY NAME tot_val_pagar,
		rm_z24.z24_total_cap,
		rm_z24.z24_total_int

FOR i = 1 TO filas_pant   
	DISPLAY rm_docs[i].* TO ra_docs[i].*
END FOR
DISPLAY vm_fecha[1] TO z20_fecha_vcto
IF vm_fecha[1] >= TODAY THEN
	DISPLAY 'Por vencer' TO n_estado_vcto
ELSE
	DISPLAY 'Vencido' TO n_estado_vcto
END IF

END FUNCTION



FUNCTION lee_solicitud_cobro()

DELETE FROM tmp_detalle;

INSERT INTO tmp_detalle
	SELECT z20_tipo_doc, z20_num_doc, z20_dividendo, z20_saldo_int,
	       z20_saldo_cap, (z25_valor_cap + z25_valor_int), z20_fecha_vcto
		FROM cxct020, OUTER cxct025
		WHERE z20_compania   = vg_codcia
		  AND z20_localidad  = vg_codloc
		  AND z20_codcli     = rm_z24.z24_codcli
		  AND z20_areaneg    = rm_z24.z24_areaneg
		  AND z20_moneda     = rm_z24.z24_moneda
		  AND z20_saldo_cap  > 0
		  AND z25_compania   = z20_compania 
		  AND z25_localidad  = z20_localidad
		  AND z25_numero_sol = rm_z24.z24_numero_sol
		  AND z25_codcli     = z20_codcli
		  AND z25_tipo_doc   = z20_tipo_doc
		  AND z25_num_doc    = z20_num_doc
		  AND z25_dividendo  = z20_dividendo

SELECT count(*) INTO vm_indice FROM tmp_detalle

END FUNCTION



FUNCTION lee_detalle_cxct025()

DELETE FROM tmp_detalle;

INSERT INTO tmp_detalle
	SELECT z25_tipo_doc, z25_num_doc, z25_dividendo, z20_saldo_int,
	       z20_saldo_cap, (z25_valor_cap + z25_valor_int), z20_fecha_vcto
		FROM cxct025, cxct020
		WHERE z25_compania   = vg_codcia
		  AND z25_localidad  = vg_codloc
		  AND z25_numero_sol = rm_z24.z24_numero_sol
		  AND z20_compania   = z25_compania 
		  AND z20_localidad  = z25_localidad
		  AND z20_codcli     = z25_codcli
		  AND z20_tipo_doc   = z25_tipo_doc
		  AND z20_num_doc    = z25_num_doc
		  AND z20_dividendo  = z25_dividendo

SELECT COUNT(*) INTO vm_indice FROM tmp_detalle

END FUNCTION



FUNCTION actualiza_caja()

DEFINE intentar		SMALLINT
DEFINE done    		SMALLINT

DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_upd		RECORD LIKE cajt010.*

CALL fl_lee_cliente_general(rm_z24.z24_codcli) RETURNING r_z01.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_j10 CURSOR FOR
			SELECT * FROM cajt010
				WHERE j10_compania    = vg_codcia      
				  AND j10_localidad   = vg_codloc       
				  AND j10_tipo_fuente = 'SC'
				  AND j10_num_fuente  =	rm_z24.z24_numero_sol
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF

OPEN q_j10
FETCH q_j10 INTO r_j10.*
	IF STATUS = NOTFOUND THEN
		-- El registro no existe, hay que grabarlo
		LET r_j10.j10_areaneg     = rm_z24.z24_areaneg
		LET r_j10.j10_codcli      = rm_z24.z24_codcli
		LET r_j10.j10_nomcli      = r_z01.z01_nomcli
		LET r_j10.j10_moneda      = rm_z24.z24_moneda
		LET r_j10.j10_valor       = 
			rm_z24.z24_total_cap + rm_z24.z24_total_int
		LET r_j10.j10_fecha_pro   = CURRENT
		LET r_j10.j10_usuario     = vg_usuario 
		LET r_j10.j10_fecing      = CURRENT
		LET r_j10.j10_compania    = vg_codcia
		LET r_j10.j10_localidad   = vg_codloc
		LET r_j10.j10_tipo_fuente = 'SC'
		LET r_j10.j10_num_fuente  = rm_z24.z24_numero_sol
		LET r_j10.j10_estado      = 'A'

		INITIALIZE r_j10.j10_codigo_caja,   
		 	   r_j10.j10_tipo_destino, 
		 	   r_j10.j10_num_destino,     
		 	   r_j10.j10_referencia,     
		 	   r_j10.j10_banco,         
			   r_j10.j10_numero_cta,   
			   r_j10.j10_tip_contable,
			   r_j10.j10_num_contable
			TO NULL    
                                                                
		INSERT INTO cajt010 VALUES(r_j10.*)
	ELSE
		LET r_j10.j10_areaneg   = rm_z24.z24_areaneg
		LET r_j10.j10_codcli    = rm_z24.z24_codcli
		LET r_j10.j10_nomcli    = r_z01.z01_nomcli
		LET r_j10.j10_moneda    = rm_z24.z24_moneda
		LET r_j10.j10_valor     = 
			rm_z24.z24_total_cap + rm_z24.z24_total_int
		LET r_j10.j10_fecha_pro = CURRENT
		LET r_j10.j10_usuario   = vg_usuario 
		LET r_j10.j10_fecing    = CURRENT
	
		UPDATE cajt010 SET * = r_j10.* WHERE CURRENT OF q_j10
	END IF
CLOSE q_j10
FREE q_j10

RETURN done

END FUNCTION



FUNCTION control_detalle()

DEFINE i	        SMALLINT
DEFINE salir            SMALLINT
DEFINE col              SMALLINT
DEFINE query            VARCHAR(500)

IF vm_num_rows <= 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

LET vm_columna_1 = 7
LET vm_columna_2 = 5
LET rm_orden[vm_columna_1]  = 'ASC'
LET rm_orden[vm_columna_2]  = 'DESC'
INITIALIZE col TO NULL

CALL lee_detalle_cxct025()

LET salir = 0
WHILE NOT salir
        LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE deto2 FROM query
        DECLARE q_deto2 CURSOR FOR deto2 
        LET i = 1
        FOREACH q_deto2 INTO rm_docs[i].*, vm_fecha[i]
                LET i = i + 1
                IF i > vm_max_indice THEN
                        EXIT FOREACH
                END IF
        END FOREACH

	LET i = 1
	LET INT_FLAG = 0
	CALL set_count(vm_indice)
	DISPLAY ARRAY rm_docs TO ra_docs.*
      		ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY  
                ON KEY(F18)
                        LET col = 4
                        EXIT DISPLAY
                ON KEY(F19)
                        LET col = 5
                        EXIT DISPLAY
                ON KEY(F20)
                        LET col = 6
                        EXIT DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			DISPLAY vm_fecha[i] TO z20_fecha_vcto 
			IF vm_fecha[i] >= TODAY THEN
				DISPLAY 'Por vencer' TO n_estado_vcto
			ELSE
				DISPLAY 'Vencido' TO n_estado_vcto
			END IF
		ON KEY(INTERRUPT)
			LET salir = 1
			EXIT DISPLAY
		AFTER DISPLAY
			CONTINUE DISPLAY
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT', '')
			CALL setea_nombre_botones_f1()
			CALL calcula_totales()
	END DISPLAY
	IF col IS NOT NULL THEN
        	IF col <> vm_columna_1 THEN
        	        LET vm_columna_2           = vm_columna_1
        	        LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
        	        LET vm_columna_1           = col
        	END IF
        	IF rm_orden[vm_columna_1] = 'ASC' THEN
        	        LET rm_orden[vm_columna_1] = 'DESC'
        	ELSE
        	        LET rm_orden[vm_columna_1] = 'ASC'
        	END IF
		INITIALIZE col TO NULL
	END IF
END WHILE

END FUNCTION




FUNCTION mantenimiento_medio_de_pago(tipo_mant)

DEFINE tipo_mant	CHAR(1)			{ Valores pueden ser 'I' o 'M' } 
DEFINE banco		LIKE gent009.g09_banco
DEFINE nom_bco		VARCHAR(20)
DEFINE tipo_cta		LIKE gent009.g09_tipo_cta
DEFINE numero_cta 	LIKE gent009.g09_numero_cta
DEFINE i			SMALLINT
DEFINE j			SMALLINT
DEFINE salir		SMALLINT
DEFINE resp			CHAR(6)

DEFINE secuencia	LIKE cxct101.z101_secuencia
DEFINE paridad		LIKE cxct101.z101_paridad

DEFINE vl_numelm	SMALLINT
DEFINE vl_maxelm	SMALLINT

DEFINE total		LIKE cxct101.z101_valor
DEFINE valor_ef		LIKE cxct101.z101_valor
DEFINE vl_valor		LIKE cxct101.z101_valor

DEFINE bco_tarj		SMALLINT

DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_j01		RECORD LIKE cajt001.*

DEFINE r_z101_ins	RECORD LIKE cxct101.*

LET vl_maxelm = 50
LET vl_numelm = 0

LET vl_valor = rm_z24.z24_total_cap + rm_z24.z24_total_int

OPEN WINDOW w2_cxcw204 AT 05, 02 WITH 18 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST)
OPEN FORM f_204_2 FROM '../forms/cxcf204_2'
DISPLAY FORM f_204_2

CALL setea_botones()
DISPLAY BY NAME rm_z24.z24_areaneg, rm_z24.z24_codcli, rm_z24.z24_moneda
CALL fl_lee_area_negocio(vg_codcia, rm_z24.z24_areaneg) RETURNING r_g03.*
CALL fl_lee_cliente_general(rm_z24.z24_codcli) RETURNING r_z01.*
CALL fl_lee_moneda(rm_z24.z24_moneda) RETURNING r_g13.*
DISPLAY r_g03.g03_nombre  TO n_areaneg
DISPLAY r_z01.z01_nomcli  TO nomcli
DISPLAY r_g13.g13_nombre  TO n_moneda

DISPLAY rm_z24.z24_total_cap + rm_z24.z24_total_int + rm_z24.z24_total_mora
	 TO valor

IF tipo_mant = 'M' THEN
	DECLARE q_medio CURSOR FOR 
		SELECT z101_codigo_pago, z101_moneda, z101_cod_bco_tarj, 
			   z101_num_ch_aut,  z101_num_cta_tarj, z101_valor 
 		  FROM cxct101 
		 WHERE z101_compania   = vg_codcia
		   AND z101_localidad  = vg_codloc
		   AND z101_numero_sol = rm_z24.z24_numero_sol

	LET vl_numelm = 1
	FOREACH q_medio INTO r_z101[vl_numelm].*
		LET vl_numelm = vl_numelm + 1
		IF vl_numelm > vl_maxelm THEN
			CALL fl_mensaje_arreglo_lleno()
			EXIT FOREACH
		END IF
	END FOREACH
	LET vl_numelm = vl_numelm - 1
END IF

OPTIONS INSERT KEY F30

LET salir = 0
WHILE NOT salir

LET i = 1
LET j = 1
LET INT_FLAG = 0
CALL set_count(vl_numelm)
INPUT ARRAY r_z101 WITHOUT DEFAULTS FROM ra_z101.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(z101_codigo_pago) THEN
			CALL fl_ayuda_forma_pago(vg_codcia) RETURNING r_j01.j01_codigo_pago,
														  r_j01.j01_nombre
			IF r_j01.j01_codigo_pago IS NOT NULL THEN
				LET r_z101[i].forma_pago = r_j01.j01_codigo_pago
				DISPLAY r_z101[i].forma_pago TO ra_z101[j].z101_codigo_pago
			END IF
		END IF
		IF INFIELD(z101_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
											  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET r_z101[i].moneda = r_mon.g13_moneda
				DISPLAY r_z101[i].moneda TO ra_z101[j].z101_moneda
			END IF	
		END IF
		IF INFIELD(z101_cod_bco_tarj) THEN
			IF r_z101[i].forma_pago = 'DP' THEN
				CALL fl_ayuda_cuenta_banco(vg_codcia) RETURNING banco, nom_bco, 
				               									tipo_cta, 
																numero_cta 
				IF numero_cta IS NOT NULL THEN
					LET r_z101[i].cod_bco_tarj = banco
					LET r_z101[i].num_cta_tarj = numero_cta
					DISPLAY r_z101[i].cod_bco_tarj TO ra_z101[j].z101_cod_bco_tarj
					DISPLAY r_z101[i].num_cta_tarj TO ra_z101[j].z101_num_cta_tarj
				END IF	
			ELSE
				CALL ayudas_bco_tarj(r_z101[i].forma_pago) 
					RETURNING r_z101[i].cod_bco_tarj
				DISPLAY r_z101[i].cod_bco_tarj TO ra_z101[j].z101_cod_bco_tarj
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')
		CALL calcula_total(arr_count()) RETURNING total
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	AFTER ROW
		LET vl_numelm = arr_count()
		LET total = calcula_total(vl_numelm)
		LET valor_ef = valor_efectivo(vl_numelm)
	AFTER FIELD z101_codigo_pago
		IF r_z101[i].forma_pago IS NULL THEN
			IF fgl_lastkey() <> fgl_keyval('up') THEN
				NEXT FIELD z101_codigo_pago
			ELSE
				CONTINUE INPUT
			END IF
		END IF 
		CALL fl_lee_tipo_pago_caja(vg_codcia, r_z101[i].forma_pago) RETURNING r_j01.*
		IF r_j01.j01_codigo_pago IS NULL THEN
			CALL fgl_winmessage(vg_producto, 'Forma de Pago no existe.', 'exclamation')
			NEXT FIELD z101_codigo_pago
		END IF
		IF r_j01.j01_estado = 'B' THEN
			CALL fgl_winmessage(vg_producto, 'Forma de Pago está bloqueada.', 
											 'exclamation')
			NEXT FIELD z101_codigo_pago
		END IF
	AFTER FIELD z101_moneda
		IF r_z101[i].moneda IS NULL THEN
			NEXT FIELD z101_moneda
		END IF 

		CALL fl_lee_moneda(r_z101[i].moneda) RETURNING r_mon.*

		-- Validaciones sobre la moneda
		IF r_mon.g13_moneda IS NULL THEN	
			CALL fgl_winmessage(vg_producto, 'Moneda no existe', 'exclamation')
			NEXT FIELD z101_moneda
		END IF
		IF r_mon.g13_estado = 'B' THEN
			CALL FGL_WINMESSAGE(vg_producto, 'Moneda está bloqueada', 'exclamation')
			NEXT FIELD z101_moneda
		END IF

		IF calcula_paridad(r_z101[i].moneda, rm_z24.z24_moneda) IS NULL
		THEN
			LET r_z101[i].moneda = rm_z24.z24_moneda
			DISPLAY r_z101[i].moneda TO ra_z101[j].z101_moneda
		END IF
		CALL calcula_total(arr_count()) RETURNING total
		IF r_z101[i].valor IS NOT NULL THEN
			LET valor_ef = valor_efectivo(vl_numelm)
		END IF
	AFTER FIELD z101_valor
		IF r_z101[i].valor IS NULL THEN
			NEXT FIELD z101_valor
		END IF
		IF r_z101[i].valor <= 0 THEN
			CALL fgl_winmessage(vg_producto,
				'El valor debe ser mayor a cero.',
				'exclamation')
			NEXT FIELD z101_valor
		END IF	
		LET vl_numelm = arr_count()
		LET total = calcula_total(vl_numelm)
		LET valor_ef = valor_efectivo(vl_numelm)
		IF fgl_lastkey() = fgl_keyval('return') THEN
			NEXT FIELD ra_z101[j-1].z101_codigo_pago
		END IF
	AFTER FIELD z101_cod_bco_tarj
		IF r_z101[i].cod_bco_tarj IS NULL THEN
			CONTINUE INPUT
		END IF
		LET bco_tarj = banco_tarjeta(r_z101[i].forma_pago)
		IF bco_tarj IS NULL OR bco_tarj = 3 THEN
			INITIALIZE r_z101[i].cod_bco_tarj TO NULL
			CLEAR ra_z101[j].z101_cod_bco_tarj
		END IF
		IF bco_tarj = 1 THEN
			CALL fl_lee_banco_general(r_z101[i].cod_bco_tarj) RETURNING r_g08.* 
			IF r_g08.g08_banco IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Banco no existe.', 'exclamation')
				NEXT FIELD z101_cod_bco_tarj
			END IF
		END IF
		IF bco_tarj = 2 THEN
			CALL fl_lee_tarjeta_credito(r_z101[i].cod_bco_tarj) RETURNING r_g10.* 
			IF r_g10.g10_tarjeta IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Tarjeta no existe.', 'exclamation')
				NEXT FIELD z101_cod_bco_tarj
			END IF
		END IF
	AFTER FIELD z101_num_ch_aut
		LET bco_tarj = banco_tarjeta(r_z101[i].forma_pago)
		IF bco_tarj IS NULL  THEN
			INITIALIZE r_z101[i].num_ch_aut TO NULL
			CLEAR ra_z101[j].z101_num_ch_aut
		END IF
	AFTER FIELD z101_num_cta_tarj
		LET bco_tarj = banco_tarjeta(r_z101[i].forma_pago)
		IF bco_tarj IS NULL OR bco_tarj = 3 THEN
			INITIALIZE r_z101[i].num_cta_tarj TO NULL
			CLEAR ra_z101[j].z101_num_cta_tarj
		END IF
		IF r_z101[i].forma_pago = 'DP' THEN
			IF  r_z101[i].num_cta_tarj IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Digite cuenta de compañía.',
									'exclamation')
				NEXT FIELD z101_num_cta_tarj
			END IF
			CALL fl_lee_banco_compania(vg_codcia, r_z101[i].cod_bco_tarj,
									   r_z101[i].num_cta_tarj) RETURNING r_g09.*
			IF r_g09.g09_numero_cta IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe cuenta en este banco.',
									'exclamation')
				NEXT FIELD z101_num_cta_tarj
			END IF
		END IF
	AFTER DELETE
		LET vl_numelm = arr_count()
		CALL calcula_total(vl_numelm) RETURNING total
		EXIT INPUT
	AFTER INPUT
		LET vl_numelm = arr_count()
		FOR i = 1 TO vl_numelm 
			IF banco_tarjeta(r_z101[i].forma_pago) = 1
			OR banco_tarjeta(r_z101[i].forma_pago) = 2 
			THEN
				IF r_z101[i].cod_bco_tarj IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Debe ingresar el código ' ||
						'del banco o de la tarjeta.',
						'exclamation')
					NEXT FIELD z101_cod_bco_tarj
				END IF
				IF r_z101[i].num_cta_tarj IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Debe ingresar el número ' ||
						'de la cuenta o de la ' ||
						'tarjeta.',
						'exclamation')
					NEXT FIELD z101_num_cta_tarj
				END IF
			END IF
			IF r_z101[i].forma_pago = vm_cheque
			OR r_z101[i].forma_pago = 'TJ'
			OR r_z101[i].forma_pago = 'RT'
			THEN
				IF r_z101[i].num_ch_aut IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Debe ingresar el número ' ||
						'del cheque/retención/aut. ' ||
						'tarjeta.',
						'exclamation')
					NEXT FIELD z101_num_ch_aut
				END IF
			END IF
		END FOR
		LET total = calcula_total(vl_numelm)
		IF total <> vl_valor THEN
			IF total > vl_valor THEN
				LET valor_ef = valor_efectivo(vl_numelm)
			ELSE
				CALL fgl_winmessage(vg_producto,
					'El total en la moneda de la ' ||
					'facturación debe ser igual al ' ||
					'valor a recaudar.',
					'exclamation')
				CONTINUE INPUT
			END IF 
		END IF
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w2_cxcw204
	RETURN
END IF

END WHILE

DELETE FROM cxct101 
 WHERE z101_compania   = vg_codcia
   AND z101_localidad  = vg_codloc
   AND z101_numero_sol = rm_z24.z24_numero_sol

LET secuencia = 1
FOR i = 1 TO vl_numelm 

	INITIALIZE r_z101_ins.* TO NULL

	LET r_z101_ins.z101_compania    = vg_codcia
	LET r_z101_ins.z101_localidad   = vg_codloc
	LET r_z101_ins.z101_numero_sol  = rm_z24.z24_numero_sol

	LET paridad = calcula_paridad(r_z101[i].moneda, rm_z24.z24_moneda)
	IF paridad IS NULL THEN
		CALL fgl_winmessage(vg_producto,
			'No existe paridad de cambio para esta moneda.',
			'stop')
		EXIT PROGRAM
	END IF
	
	IF r_z101[i].valor = 0 THEN
		CONTINUE FOR
	END IF

	LET r_z101_ins.z101_secuencia   = secuencia
	LET secuencia = secuencia + 1
	LET r_z101_ins.z101_codigo_pago = r_z101[i].forma_pago
	LET r_z101_ins.z101_moneda      = r_z101[i].moneda
	LET r_z101_ins.z101_paridad     = paridad
	LET r_z101_ins.z101_valor       = r_z101[i].valor
	IF banco_tarjeta(r_z101[i].forma_pago) IS NOT NULL THEN
		LET r_z101_ins.z101_cod_bco_tarj = r_z101[i].cod_bco_tarj
		LET r_z101_ins.z101_num_ch_aut   = r_z101[i].num_ch_aut
		LET r_z101_ins.z101_num_cta_tarj = r_z101[i].num_cta_tarj
	END IF
	
	INSERT INTO cxct101 VALUES (r_z101_ins.*)
END FOR

CLOSE WINDOW w2_cxcw204

END FUNCTION



FUNCTION banco_tarjeta(forma_pago)

DEFINE forma_pago	LIKE cajt001.j01_codigo_pago
DEFINE ret_val		SMALLINT

-- En el CASE se le asignara:

-- 1 (UNO) a la variable ret_val si el codigo está relacionado a un
-- banco 
-- 2 (DOS) a la variable ret_val si el codigo está relacionado a una
-- tarjeta de crédito 
-- 3 (TRES) a la variable ret_val si el codigo requiere que se ingrese 
-- un numero pero no un banco ni tarjeta

CASE forma_pago
	WHEN vm_cheque LET ret_val = 1 
	WHEN 'DP' LET ret_val = 1 
	WHEN 'CD' LET ret_val = 1 
	WHEN 'DA' LET ret_val = 1 
	
	WHEN 'TJ' LET ret_val = 2

	WHEN 'RT' LET ret_val = 3
	
	OTHERWISE  
		-- Estas formas de pago no necesitan informacion del
		-- banco o tarjeta de crédito:
		-- 'EF', 'OC', 'OT'
		INITIALIZE ret_val TO NULL
END CASE 

RETURN ret_val

END FUNCTION



FUNCTION ayudas_bco_tarj(forma_pago)

DEFINE forma_pago		LIKE cajt001.j01_codigo_pago
DEFINE cod_bco_tarj		LIKE cxct101.z101_cod_bco_tarj

DEFINE r_g08			RECORD LIKE gent008.*
DEFINE r_g10			RECORD LIKE gent010.*

LET cod_bco_tarj = banco_tarjeta(forma_pago)

IF cod_bco_tarj = 1 THEN
	CALL fl_ayuda_bancos() RETURNING r_g08.g08_banco, r_g08.g08_nombre
	IF r_g08.g08_banco IS NOT NULL THEN
		LET cod_bco_tarj = r_g08.g08_banco
	ELSE
		INITIALIZE cod_bco_tarj TO NULL
	END IF
	RETURN cod_bco_tarj
END IF
IF cod_bco_tarj = 2 THEN
	CALL fl_ayuda_tarjeta() RETURNING r_g10.g10_tarjeta, r_g10.g10_nombre
	IF r_g10.g10_tarjeta IS NOT NULL THEN
		LET cod_bco_tarj = r_g10.g10_tarjeta
	ELSE
		INITIALIZE cod_bco_tarj TO NULL
	END IF
	RETURN cod_bco_tarj
END IF

IF cod_bco_tarj = 3 THEN
	INITIALIZE cod_bco_tarj TO NULL
	RETURN cod_bco_tarj
END IF

RETURN cod_bco_tarj

END FUNCTION




FUNCTION valor_efectivo(num_elm)

DEFINE num_elm		SMALLINT
DEFINE i		SMALLINT
DEFINE paridad		LIKE cxct101.z101_paridad

DEFINE valor		LIKE cxct101.z101_valor

LET valor = 0
FOR i = 1 TO num_elm
	IF r_z101[i].forma_pago = vm_efectivo THEN
		LET paridad = calcula_paridad(r_z101[i].moneda,
					      rm_z24.z24_moneda)
		IF paridad IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'No existe paridad de cambio para esta moneda.',
				'stop')
			EXIT PROGRAM
		END IF
		LET valor = valor + (r_z101[i].valor * paridad)
	END IF
END FOR

RETURN valor

END FUNCTION




FUNCTION calcula_total(num_elm)

DEFINE i		SMALLINT
DEFINE num_elm		SMALLINT
DEFINE paridad		LIKE cxct101.z101_paridad

DEFINE total		LIKE cxct101.z101_valor

LET total = 0
FOR i = 1 TO num_elm
	IF r_z101[i].valor IS NOT NULL THEN
		LET paridad = calcula_paridad(r_z101[i].moneda,
					      rm_z24.z24_moneda)
		IF paridad IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'No existe paridad de cambio para esta moneda.',
				'stop')
			EXIT PROGRAM
		END IF
		LET total = total + (r_z101[i].valor * paridad)
	END IF
END FOR 

DISPLAY total TO total_mf

RETURN total

END FUNCTION



FUNCTION imprimir()
DEFINE comando			CHAR(250)

	LET comando = 'cd ..', vg_separador, '..', vg_separador,
                  'COBRANZAS', vg_separador, 'fuentes',
                  vg_separador, '; fglrun cxcp404 ', vg_base, ' ',
                  'CO', vg_codcia, ' ', vg_codloc,
                  ' ', rm_z24.z24_numero_sol
	RUN comando

END FUNCTION



FUNCTION setea_botones()

DISPLAY 'FP'			TO 	bt_codigo_pago
DISPLAY 'Mon'			TO 	bt_moneda
DISPLAY 'Bco/Tarj'		TO 	bt_bco_tarj
DISPLAY 'Nro. Che./Aut.'	TO 	bt_che_aut
DISPLAY 'Nro. Cta./Tarj.'	TO 	bt_cta_tarj
DISPLAY 'Valor'			TO 	bt_valor

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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
