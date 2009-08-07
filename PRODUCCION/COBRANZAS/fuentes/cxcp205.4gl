------------------------------------------------------------------------------
-- Titulo           : cxcp205.4gl - Solicitud cobros a clientes 
--                                  por Pagos Anticipados 
-- Elaboracion      : 19-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxcp205 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE vm_entidad	LIKE gent011.g11_tiporeg

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT

---
-- DEFINE RECORD(S) HERE
---
DEFINE rm_z24			RECORD LIKE cxct024.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
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
LET vg_proceso = 'cxcp205'
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
OPEN WINDOW w_205 AT 3,2 WITH 18 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_205 FROM '../forms/cxcf205_1'
DISPLAY FORM f_205

LET vm_entidad = 'PA'

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_z24.* TO NULL
CALL muestra_contadores()

LET vm_max_rows   = 1000

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
LET rm_z24.z24_tipo       = 'A' -- Solicitud de cobro de pago anticipado
LET rm_z24.z24_tasa_mora  = 0	-- Hasta que se implemente el proceso 
LET rm_z24.z24_total_mora = 0   -- para calcular el interes por mora
LET rm_z24.z24_total_int  = 0
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

BEGIN WORK

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
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
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

UPDATE cxct024 SET * = rm_z24.* WHERE CURRENT OF q_upd

LET done = actualiza_caja()
IF NOT done THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

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
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE dummy		LIKE gent011.g11_nombre

LET INT_FLAG = 0
INPUT BY NAME rm_z24.z24_codcli,     rm_z24.z24_areaneg,   rm_z24.z24_linea,
              rm_z24.z24_estado,     rm_z24.z24_moneda,    rm_z24.z24_subtipo,  
	      rm_z24.z24_referencia, rm_z24.z24_total_cap, rm_z24.z24_usuario, 
              rm_z24.z24_fecing 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(z24_areaneg, z24_linea,      z24_codcli, 
                                     z24_moneda,  z24_referencia, z24_total_cap
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
		IF INFIELD(z24_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(vm_entidad)
				RETURNING r_g12.g12_tiporeg, r_g12.g12_subtipo,
					  r_g12.g12_nombre,  dummy
			IF r_g12.g12_tiporeg IS NOT NULL THEN
				LET rm_z24.z24_subtipo = r_g12.g12_subtipo
				DISPLAY BY NAME rm_z24.z24_subtipo
				DISPLAY r_g12.g12_nombre TO n_motivo
			END IF
		END IF
		LET INT_FLAG = 0
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
                             		            'Moneda no existe.',        
                                        	    'exclamation')
				CLEAR n_moneda
				NEXT FIELD z24_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada.',       
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
	AFTER FIELD z24_total_cap
		IF rm_z24.z24_total_cap IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_z24.z24_total_cap <= 0 THEN
			CALL fgl_winmessage(vg_producto,
				'El valor a pagar debe ser mayor a cero.',
				'exclamation')
			NEXT FIELD z24_total_cap
		END IF
	AFTER FIELD z24_subtipo
		IF rm_z24.z24_subtipo IS NULL THEN
			CLEAR n_motivo
			CONTINUE INPUT
		END IF
		CALL fl_lee_subtipo_entidad(vm_entidad, rm_z24.z24_subtipo)
			RETURNING r_g12.*
		IF r_g12.g12_tiporeg IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Código no existe.',
				'exclamation')
			CLEAR n_motivo
			NEXT FIELD z24_subtipo
		END IF
		DISPLAY r_g12.g12_nombre TO n_motivo
	AFTER INPUT
		LET rm_z24.z24_total_cap = 
			fl_retorna_precision_valor(rm_z24.z24_moneda,
						   rm_z24.z24_total_cap)
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE dummy		LIKE gent011.g11_nombre

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON z24_estado,  z24_codcli, z24_areaneg, z24_linea, z24_moneda, 
	   z24_subtipo, z24_referencia, z24_total_cap, z24_usuario 
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
		IF INFIELD(z24_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(vm_entidad)
				RETURNING r_g12.g12_tiporeg, r_g12.g12_subtipo,
					  r_g12.g12_nombre,  dummy
			IF r_g12.g12_tiporeg IS NOT NULL THEN
				LET rm_z24.z24_subtipo = r_g12.g12_subtipo
				DISPLAY BY NAME rm_z24.z24_subtipo
				DISPLAY r_g12.g12_nombre TO n_motivo
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
		LET INT_FLAG = 0
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
	AFTER FIELD z24_subtipo
		LET rm_z24.z24_subtipo = GET_FLDBUF(z24_subtipo)
		IF rm_z24.z24_subtipo IS NULL THEN
			CLEAR n_motivo
		END IF
		CALL fl_lee_subtipo_entidad(vm_entidad, rm_z24.z24_subtipo)
			RETURNING r_g12.*
		IF r_g12.g12_tiporeg IS NULL THEN
			CLEAR n_motivo
		END IF
		DISPLAY r_g12.g12_nombre TO n_motivo
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
	    '   AND z24_tipo = "A"',
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
		rm_z24.z24_total_cap,
		rm_z24.z24_moneda,     
		rm_z24.z24_subtipo,
		rm_z24.z24_paridad,
		rm_z24.z24_usuario,
		rm_z24.z24_fecing   
CALL muestra_etiquetas()
CALL muestra_contadores()

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
DEFINE r_g12		RECORD LIKE gent012.*

DEFINE nom_estado		CHAR(9)

CASE rm_z24.z24_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'P' LET nom_estado = 'PROCESADO'
END CASE

CALL fl_lee_grupo_linea(vg_codcia, rm_z24.z24_linea) RETURNING r_g20.*
CALL fl_lee_area_negocio(vg_codcia, rm_z24.z24_areaneg) RETURNING r_g03.*
CALL fl_lee_cliente_general(rm_z24.z24_codcli) RETURNING r_z01.*
CALL fl_lee_moneda(rm_z24.z24_moneda) RETURNING r_g13.*
CALL fl_lee_subtipo_entidad(vm_entidad, rm_z24.z24_subtipo) RETURNING r_g12.*

DISPLAY nom_estado TO n_estado
DISPLAY r_g20.g20_nombre  TO n_linea
DISPLAY r_g03.g03_nombre  TO n_areaneg
DISPLAY r_z01.z01_nomcli  TO n_cliente
DISPLAY r_g13.g13_nombre  TO n_moneda
DISPLAY r_g12.g12_nombre  TO n_motivo

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
		LET r_j10.j10_valor       = rm_z24.z24_total_cap
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
		LET r_j10.j10_valor     = rm_z24.z24_total_cap 
		LET r_j10.j10_fecha_pro = CURRENT
		LET r_j10.j10_usuario   = vg_usuario 
		LET r_j10.j10_fecing    = CURRENT
	
		UPDATE cajt010 SET * = r_j10.* WHERE CURRENT OF q_j10
	END IF
CLOSE q_j10
FREE q_j10

RETURN done

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
