--------------------------------------------------------------------------------
-- Titulo           : cxcp205.4gl - Solicitud cobros a clientes 
--                                  por Pagos Anticipados 
-- Elaboracion      : 19-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxcp205 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_entidad	LIKE gent011.g11_tiporeg

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 20000 ELEMENTOS
DEFINE vm_rows		ARRAY[20000] OF INTEGER	-- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT
---
-- DEFINE RECORD(S) HERE
---
DEFINE rm_z24		RECORD LIKE cxct024.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp205.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN	-- Validar # par�metros correcto
	CALL fl_mostrar_mensaje('N�mero de par�metros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp205'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i 		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
IF num_args() = 4 THEN
	CALL fl_control_status_caja(vg_codcia, vg_codloc, 'S')
		RETURNING int_flag
	IF int_flag <> 0 THEN
		RETURN
	END IF	
	CALL fl_chequeo_mes_proceso_cxc(vg_codcia) RETURNING int_flag 
	IF int_flag THEN
		RETURN
	END IF
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 20
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_205 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_205 FROM '../forms/cxcf205_1'
ELSE
	OPEN FORM f_205 FROM '../forms/cxcf205_1c'
END IF
DISPLAY FORM f_205

LET vm_entidad = 'PA'
IF num_args() <> 4 THEN
	LET vm_entidad = arg_val(6)
END IF

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_z24.* TO NULL
CALL muestra_contadores()

LET vm_max_rows   = 20000

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		IF num_args() <> 4 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
		END IF
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
DEFINE rowid_aux	INTEGER
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
LET rowid_aux = SQLCA.SQLERRD[6]	-- Rowid de la ultima fila 
	                                -- procesada

DISPLAY BY NAME rm_z24.z24_numero_sol

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
LET vm_rows[vm_num_rows] = rowid_aux            

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

CALL lee_muestra_registro(vm_rows[vm_row_current])

IF rm_z24.z24_estado = 'P' THEN
	CALL fl_mostrar_mensaje('No puede modificar este registro.','exclamation')
	RETURN
END IF

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM cxct024 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_z24.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

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
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_z05		RECORD LIKE cxct005.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE dummy		LIKE gent011.g11_nombre

LET INT_FLAG = 0
INPUT BY NAME rm_z24.z24_codcli,     rm_z24.z24_areaneg,   rm_z24.z24_linea,
              rm_z24.z24_estado,     rm_z24.z24_moneda,    rm_z24.z24_subtipo,  
	      rm_z24.z24_cobrador,   rm_z24.z24_referencia,rm_z24.z24_total_cap,
	      rm_z24.z24_usuario,    rm_z24.z24_fecing 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_z24.z24_codcli, rm_z24.z24_areaneg,
				     rm_z24.z24_linea, rm_z24.z24_estado,
				     rm_z24.z24_moneda, rm_z24.z24_subtipo,
				     rm_z24.z24_cobrador, rm_z24.z24_referencia,
				     rm_z24.z24_total_cap, rm_z24.z24_usuario,
				     rm_z24.z24_fecing)
		THEN
			LET int_flag = 1
			EXIT INPUT
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
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
         	  	CALL fl_ayuda_cliente_localidad_cobrar(vg_codcia,
								vg_codloc, 'F') 
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
		IF INFIELD(z24_cobrador) THEN
			CALL fl_ayuda_cobradores(vg_codcia, 'T', 'T', 'A') 
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
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD z24_areaneg
		IF rm_z24.z24_areaneg IS NULL THEN
			CLEAR n_areaneg
			CONTINUE INPUT
		END IF
		CALL fl_lee_area_negocio(vg_codcia, rm_z24.z24_areaneg)
			RETURNING r_g03.*
		IF r_g03.g03_areaneg IS NULL THEN
			CALL fl_mostrar_mensaje('Area de negocio no existe.','exclamation')
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
			CALL fl_mostrar_mensaje('Grupo de linea no existe.','exclamation')
			CLEAR n_linea
			NEXT FIELD z24_linea
		END IF
		IF rm_z24.z24_areaneg IS NOT NULL THEN
			IF rm_z24.z24_areaneg <> r_g20.g20_areaneg THEN
				CALL fl_mostrar_mensaje('El grupo de l�nea no pertenece al �rea de negocio.','exclamation')
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
				CALL fl_mostrar_mensaje('No existe un cliente con ese c�digo.','exclamation')
				CLEAR n_cliente
				NEXT FIELD z24_codcli     
        		END IF   
			IF r_z01.z01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				CLEAR n_cliente
				NEXT FIELD z24_codcli      
			END IF
			LET rm_z24.z24_codcli = r_z01.z01_codcli
        		DISPLAY BY NAME rm_z24.z24_codcli     
			DISPLAY r_z01.z01_nomcli TO n_cliente
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							rm_z24.z24_codcli)
		 		RETURNING r_z02.*
			IF r_z02.z02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no est� activado para esta localidad.', 'exclamation')
				NEXT FIELD z24_codcli
			END IF
		END IF
	AFTER FIELD z24_moneda
		IF rm_z24.z24_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_z24.z24_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				CLEAR n_moneda
				NEXT FIELD z24_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
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
			CALL fl_mostrar_mensaje('El valor a pagar debe ser mayor a cero.','exclamation')
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
			CALL fl_mostrar_mensaje('C�digo no existe.','exclamation')
			CLEAR n_motivo
			NEXT FIELD z24_subtipo
		END IF
		DISPLAY r_g12.g12_nombre TO n_motivo
	AFTER FIELD z24_cobrador
		IF rm_z24.z24_cobrador IS NULL THEN
			CLEAR n_cobrador
			CONTINUE INPUT
		END IF
		CALL fl_lee_cobrador_cxc(vg_codcia, rm_z24.z24_cobrador)
			RETURNING r_z05.*
		IF r_z05.z05_codigo IS NULL THEN
			CALL fl_mostrar_mensaje('Cobrador no existe.','exclamation')
			CLEAR n_cobrador
			NEXT FIELD z24_cobrador
		END IF
		IF r_z05.z05_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			CLEAR n_cobrador
			NEXT FIELD z24_cobrador
		END IF
		DISPLAY r_z05.z05_nombres TO n_cobrador	
	AFTER INPUT
		IF rm_z24.z24_cobrador IS NULL THEN
			CALL fl_mostrar_mensaje('Digite el Cobrador.', 'exclamation')
			NEXT FIELD z24_cobrador
		END IF
		LET rm_z24.z24_total_cap = 
			fl_retorna_precision_valor(rm_z24.z24_moneda,
						   rm_z24.z24_total_cap)
END INPUT

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1200)
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_z05		RECORD LIKE cxct005.*
DEFINE r_z24		RECORD LIKE cxct024.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE dummy		LIKE gent011.g11_nombre

CLEAR FORM
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql 
		ON z24_numero_sol, z24_estado, z24_codcli, z24_areaneg,
			z24_linea, z24_moneda, z24_subtipo, z24_cobrador,
			z24_referencia, z24_total_cap, z24_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(z24_numero_sol) THEN
			CALL fl_ayuda_solicitudes_cobro(vg_codcia,vg_codloc,'A')
				RETURNING r_z24.z24_numero_sol
			IF r_z24.z24_numero_sol IS NOT NULL THEN
				LET rm_z24.z24_numero_sol = r_z24.z24_numero_sol
				DISPLAY BY NAME rm_z24.z24_numero_sol
			END IF
		END IF
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
         	  	CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
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
		IF INFIELD(z24_cobrador) THEN
			CALL fl_ayuda_cobradores(vg_codcia, 'T', 'T', 'A') 
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
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
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
	END CONSTRUCT
	IF int_flag THEN
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'z24_numero_sol = ', arg_val(5)
END IF
LET query = 'SELECT *, ROWID FROM cxct024 ',
		' WHERE z24_compania  = ', vg_codcia,
		'   AND z24_localidad = ', vg_codloc,
		'   AND z24_tipo      = "A" ',
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 1, 2, 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_z24.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() <> 4 THEN
		EXIT PROGRAM
	END IF
	LET vm_num_rows    = 0
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
		rm_z24.z24_cobrador,  
		rm_z24.z24_paridad,
		rm_z24.z24_usuario,
		rm_z24.z24_fecing   
CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 17
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY vm_row_current, " de ", vm_num_rows AT nrow, 67

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
CALL fl_lee_cobrador_cxc(vg_codcia, rm_z24.z24_cobrador) RETURNING r_z05.*

DISPLAY nom_estado TO n_estado
DISPLAY r_g20.g20_nombre  TO n_linea
DISPLAY r_g03.g03_nombre  TO n_areaneg
DISPLAY r_z01.z01_nomcli  TO n_cliente
DISPLAY r_g13.g13_nombre  TO n_moneda
DISPLAY r_g12.g12_nombre  TO n_motivo
DISPLAY r_z05.z05_nombres TO n_cobrador

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
		CALL fl_mostrar_mensaje('No existe factor de conversi�n para esta moneda.','exclamation')
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
CALL fl_hacer_pregunta('Registro bloqueado por otro usuario, desea intentarlo nuevamente','No')
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



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
