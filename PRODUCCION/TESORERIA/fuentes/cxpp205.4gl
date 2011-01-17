------------------------------------------------------------------------------
-- Titulo           : cxpp205.4gl - Solicitud cobros a clientes 
--                                  por Pagos Anticipados 
-- Elaboracion      : 29-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxpp205 base modulo compania localidad [ord_pago]
--		Si (ord_pago <> 0) el programa se esta ejcutando en modo de
--			solo consulta
--		Si (ord_pago = 0) el programa se esta ejecutando en forma 
--			independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_ord_pago	LIKE cxpt024.p24_orden_pago

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
DEFINE rm_p24			RECORD LIKE cxpt024.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cxpp205'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

LET vm_ord_pago = 0
IF num_args() = 5 THEN
	LET vm_ord_pago  = arg_val(5)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE i 		SMALLINT

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_205 AT 3,2 WITH 19 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_205 FROM '../forms/cxpf205_1'
DISPLAY FORM f_205

LET vm_entidad = 'PA'

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_p24.* TO NULL
CALL muestra_contadores()

LET vm_max_rows   = 1000

IF vm_ord_pago <> 0 THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Estado Cuenta'
		IF vm_ord_pago <> 0 THEN         -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			IF vm_num_rows > 0 THEN
				SHOW OPTION 'Estado Cuenta'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		HIDE OPTION 'Estado Cuenta'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF
			
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Estado Cuenta'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Estado Cuenta'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF
		
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF
			
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
                IF vm_num_rows > 0 THEN
			SHOW OPTION 'Estado Cuenta'
		END IF
	COMMAND KEY('E') 'Estado Cuenta'	'Ver estado de cuenta del proveedor'
		CALL ver_estado_cuenta()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Estado Cuenta'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Estado Cuenta'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Estado Cuenta'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Estado Cuenta'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE rowid 		SMALLINT
DEFINE done  		SMALLINT
DEFINE i     		SMALLINT

CLEAR FORM
INITIALIZE rm_p24.* TO NULL

LET rm_p24.p24_compania   = vg_codcia
LET rm_p24.p24_localidad  = vg_codloc
LET rm_p24.p24_usuario    = vg_usuario
LET rm_p24.p24_fecing     = CURRENT
LET rm_p24.p24_tipo       = 'A' -- Solicitud de cobro de pago anticipado
LET rm_p24.p24_tasa_mora  = 0	-- Hasta que se implemente el proceso 
LET rm_p24.p24_total_mora = 0   -- para calcular el interes por mora
LET rm_p24.p24_total_int  = 0
LET rm_p24.p24_total_ret  = 0
LET rm_p24.p24_estado     = 'A'
DISPLAY 'ACTIVO' TO n_estado

LET rm_p24.p24_medio_pago = 'C'

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

LET rm_p24.p24_total_che = rm_p24.p24_total_cap

SELECT MAX(p24_orden_pago) INTO rm_p24.p24_orden_pago
	FROM cxpt024
	WHERE p24_compania  = vg_codcia
	  AND p24_localidad = vg_codloc
IF rm_p24.p24_orden_pago IS NULL THEN
	LET rm_p24.p24_orden_pago = 1
ELSE
	LET rm_p24.p24_orden_pago = rm_p24.p24_orden_pago + 1
END IF

INSERT INTO cxpt024 VALUES (rm_p24.*)
DISPLAY BY NAME rm_p24.p24_orden_pago

LET rowid = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                -- procesada
-- OjO                                
{
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
}

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

IF rm_p24.p24_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,
		'No puede modificar este registro.',
		'exclamation')
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM cxpt024 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_p24.*
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

LET rm_p24.p24_total_che = rm_p24.p24_total_cap

UPDATE cxpt024 SET * = rm_p24.* WHERE CURRENT OF q_upd

-- OjO
{
LET done = actualiza_caja()
IF NOT done THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF
}
COMMIT WORK
CLOSE q_upd
FREE  q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE nro_cta		LIKE gent009.g09_numero_cta

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE dummy		LIKE gent011.g11_nombre
DEFINE dummy2		LIKE gent008.g08_nombre

LET INT_FLAG = 0
INPUT BY NAME rm_p24.p24_codprov,   rm_p24.p24_estado,
	      rm_p24.p24_banco,     rm_p24.p24_numero_cta,
	      rm_p24.p24_moneda,    rm_p24.p24_subtipo,  rm_p24.p24_referencia,
              rm_p24.p24_total_cap, rm_p24.p24_usuario,  rm_p24.p24_fecing 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(p24_codprov, p24_moneda,
				     p24_banco, p24_numero_cta,
				     p24_referencia, p24_total_cap
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
		IF INFIELD(p24_codprov) THEN
         	  	CALL fl_ayuda_proveedores() 
				RETURNING r_p01.p01_codprov, r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN	
                  		LET rm_p24.p24_codprov = r_p01.p01_codprov
                 		DISPLAY BY NAME rm_p24.p24_codprov  
				DISPLAY r_p01.p01_nomprov TO n_proveedor
			END IF
		END IF
		IF INFIELD(p24_banco) THEN
			CALL fl_ayuda_bancos() RETURNING r_g08.g08_banco,
							 r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_p24.p24_banco = r_g08.g08_banco
				DISPLAY BY NAME rm_p24.p24_banco
				DISPLAY r_g08.g08_nombre TO n_banco
			END IF
		END IF
		IF INFIELD(p24_numero_cta) THEN
			CALL fl_ayuda_cuenta_banco(vg_codcia) 
				RETURNING r_g09.g09_banco, dummy2, 
				          r_g09.g09_tipo_cta, 
				          r_g09.g09_numero_cta 
			IF r_g09.g09_numero_cta IS NOT NULL THEN
				LET rm_p24.p24_banco = r_g09.g09_banco
				LET rm_p24.p24_numero_cta = 
					r_g09.g09_numero_cta
				LET r_g08.g08_nombre = dummy2
				DISPLAY BY NAME rm_p24.p24_banco,
						rm_p24.p24_numero_cta
				DISPLAY r_g08.g08_nombre TO n_banco
			END IF	
		END IF
		IF INFIELD(p24_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(vm_entidad)
				RETURNING r_g12.g12_tiporeg, r_g12.g12_subtipo,
					  r_g12.g12_nombre,  dummy
			IF r_g12.g12_tiporeg IS NOT NULL THEN
				LET rm_p24.p24_subtipo = r_g12.g12_subtipo
				DISPLAY BY NAME rm_p24.p24_subtipo
				DISPLAY r_g12.g12_nombre TO n_motivo
			END IF
		END IF
		LET INT_FLAG = 0
     	ON KEY(F5)
     		IF rm_p24.p24_codprov IS NULL OR rm_p24.p24_moneda IS NULL
     		THEN
     			CALL fgl_winmessage(vg_producto,
     				'Debe ingresar un proveedor y la moneda.',
     				'exclamation')
     			CONTINUE INPUT
     		END IF
     		CALL ver_estado_cuenta()
     		LET INT_FLAG = 0
	AFTER FIELD p24_codprov
		IF rm_p24.p24_codprov IS NULL THEN
			CLEAR n_proveedor
		ELSE
			CALL fl_lee_proveedor(rm_p24.p24_codprov) 
				RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'No existe proveedor.',
                                                    'exclamation')
				CLEAR n_proveedor
				NEXT FIELD p24_codprov     
        		END IF   
			IF r_p01.p01_estado = 'B' THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'El proveedor '||
                                                    'está bloqueado',
                                                    'exclamation')
				CLEAR n_proveedor
				NEXT FIELD p24_codprov      
			END IF
			LET rm_p24.p24_codprov = r_p01.p01_codprov
        		DISPLAY BY NAME rm_p24.p24_codprov     
			DISPLAY r_p01.p01_nomprov TO n_proveedor
		END IF
	AFTER FIELD p24_banco
		IF rm_p24.p24_banco IS NULL THEN
			INITIALIZE rm_p24.p24_numero_cta TO NULL
			DISPLAY BY NAME rm_p24.p24_numero_cta
			CLEAR n_banco
		ELSE
			CALL fl_lee_banco_general(rm_p24.p24_banco) 
				RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN	
				CLEAR n_banco
				INITIALIZE rm_p24.p24_numero_cta TO NULL
				DISPLAY BY NAME rm_p24.p24_numero_cta
				CALL fgl_winmessage(vg_producto,
					            'Banco no existe.',
						    'exclamation')
				NEXT FIELD p24_banco
			ELSE
				DISPLAY r_g08.g08_nombre TO n_banco
			END IF 
		END IF
	AFTER FIELD p24_numero_cta
		IF rm_p24.p24_numero_cta IS NULL THEN
			CONTINUE INPUT
		ELSE
			IF rm_p24.p24_banco IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Debe ingresar un banco primero.',
					'exclamation')
				INITIALIZE rm_p24.p24_numero_cta TO NULL
				DISPLAY BY NAME rm_p24.p24_numero_cta
				NEXT FIELD p24_banco
			END IF
			LET nro_cta = rm_p24.p24_numero_cta
			CALL fl_lee_banco_compania(vg_codcia, rm_p24.p24_banco,
				rm_p24.p24_numero_cta) RETURNING r_g09.*
			IF r_g09.g09_numero_cta IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'No existe cuenta en este banco.',
					'exclamation')
				LET rm_p24.p24_numero_cta = nro_cta
				NEXT FIELD p24_numero_cta
			END IF
			IF r_g09.g09_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto,
					'La cuenta está bloqueada.',
					'exclamation')
				NEXT FIELD p24_numero_cta
			END IF
			CALL fl_lee_moneda(r_g09.g09_moneda) RETURNING r_mon.*
			LET rm_p24.p24_moneda = r_mon.g13_moneda
			DISPLAY BY NAME rm_p24.p24_moneda
			DISPLAY r_mon.g13_nombre TO n_moneda
			LET rm_p24.p24_paridad = 
				calcula_paridad(rm_p24.p24_moneda,
						rg_gen.g00_moneda_base)
			IF rm_p24.p24_paridad IS NULL THEN
				LET rm_p24.p24_moneda = rg_gen.g00_moneda_base
				DISPLAY BY NAME rm_p24.p24_moneda
				LET rm_p24.p24_paridad =
					calcula_paridad(rm_p24.p24_moneda,
							rg_gen.g00_moneda_base)
			END IF
			DISPLAY BY NAME rm_p24.p24_paridad
		END IF
	AFTER FIELD p24_total_cap
		IF rm_p24.p24_total_cap IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_p24.p24_total_cap <= 0 THEN
			CALL fgl_winmessage(vg_producto,
				'El valor a pagar debe ser mayor a cero.',
				'exclamation')
			NEXT FIELD p24_total_cap
		END IF
	AFTER FIELD p24_subtipo
		IF rm_p24.p24_subtipo IS NULL THEN
			CLEAR n_motivo
			CONTINUE INPUT
		END IF
		CALL fl_lee_subtipo_entidad(vm_entidad, rm_p24.p24_subtipo)
			RETURNING r_g12.*
		IF r_g12.g12_tiporeg IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Código no existe.',
				'exclamation')
			CLEAR n_motivo
			NEXT FIELD p24_subtipo
		END IF
		DISPLAY r_g12.g12_nombre TO n_motivo
	AFTER INPUT
		IF rm_p24.p24_subtipo IS NULL THEN
			NEXT FIELD p24_subtipo
		END IF
		IF rm_p24.p24_referencia IS NULL THEN
			NEXT FIELD p24_referencia
		END IF
		LET rm_p24.p24_total_cap = 
			fl_retorna_precision_valor(rm_p24.p24_moneda,
						   rm_p24.p24_total_cap)
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE dummy		LIKE gent011.g11_nombre
DEFINE dummy2		LIKE gent008.g08_nombre

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON p24_estado, p24_codprov,  p24_banco, p24_numero_cta,
	   p24_moneda, p24_subtipo, p24_referencia, p24_total_cap, 
	   p24_usuario 
	ON KEY(F2)
		IF INFIELD(p24_codprov) THEN
         	  	CALL fl_ayuda_proveedores() 
				RETURNING r_p01.p01_codprov, r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN	
                  		LET rm_p24.p24_codprov = r_p01.p01_codprov
                 		DISPLAY BY NAME rm_p24.p24_codprov  
				DISPLAY r_p01.p01_nomprov TO n_proveedor
			END IF
		END IF
		IF INFIELD(p24_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(vm_entidad)
				RETURNING r_g12.g12_tiporeg, r_g12.g12_subtipo,
					  r_g12.g12_nombre,  dummy
			IF r_g12.g12_tiporeg IS NOT NULL THEN
				LET rm_p24.p24_subtipo = r_g12.g12_subtipo
				DISPLAY BY NAME rm_p24.p24_subtipo
				DISPLAY r_g12.g12_nombre TO n_motivo
			END IF
		END IF
		IF INFIELD(p24_banco) THEN
			CALL fl_ayuda_bancos() RETURNING r_g08.g08_banco,
							 r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_p24.p24_banco = r_g08.g08_banco
				DISPLAY BY NAME rm_p24.p24_banco
				DISPLAY r_g08.g08_nombre TO n_banco
			END IF
		END IF
		IF INFIELD(p24_numero_cta) THEN
			CALL fl_ayuda_cuenta_banco(vg_codcia) 
				RETURNING r_g09.g09_banco, dummy2, 
				          r_g09.g09_tipo_cta, 
				          r_g09.g09_numero_cta 
			IF r_g09.g09_numero_cta IS NOT NULL THEN
				LET rm_p24.p24_banco = r_g09.g09_banco
				LET rm_p24.p24_numero_cta = 
					r_g09.g09_numero_cta
				LET r_g08.g08_nombre = dummy2
				DISPLAY BY NAME rm_p24.p24_banco,
						rm_p24.p24_numero_cta
				DISPLAY r_g08.g08_nombre TO n_banco
			END IF	
		END IF
		IF INFIELD(p24_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_p24.p24_moneda = r_mon.g13_moneda
				DISPLAY BY NAME rm_p24.p24_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		LET INT_FLAG = 0
	AFTER FIELD p24_codprov
		LET rm_p24.p24_codprov = GET_FLDBUF(p24_codprov)
		IF rm_p24.p24_codprov IS NULL THEN
			CLEAR n_proveedor
		ELSE
			CALL fl_lee_proveedor(rm_p24.p24_codprov) 
				RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CLEAR n_proveedor
        		END IF   
			IF r_p01.p01_estado = 'B' THEN
				CLEAR n_proveedor
			END IF
			LET rm_p24.p24_codprov = r_p01.p01_codprov
        		DISPLAY BY NAME rm_p24.p24_codprov     
			DISPLAY r_p01.p01_nomprov TO n_proveedor
		END IF
	AFTER FIELD p24_moneda
		LET rm_p24.p24_moneda = GET_FLDBUF(p24_moneda)
		IF rm_p24.p24_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_p24.p24_moneda) RETURNING r_mon.*
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
	AFTER FIELD p24_subtipo
		LET rm_p24.p24_subtipo = GET_FLDBUF(p24_subtipo)
		IF rm_p24.p24_subtipo IS NULL THEN
			CLEAR n_motivo
		END IF
		CALL fl_lee_subtipo_entidad(vm_entidad, rm_p24.p24_subtipo)
			RETURNING r_g12.*
		IF r_g12.g12_tiporeg IS NULL THEN
			CLEAR n_motivo
		END IF
		DISPLAY r_g12.g12_nombre TO n_motivo
	AFTER FIELD p24_banco
		LET rm_p24.p24_banco = GET_FLDBUF(p24_banco)
		IF rm_p24.p24_banco IS NULL THEN
			CLEAR n_banco
		ELSE
			CALL fl_lee_banco_general(rm_p24.p24_banco) 
				RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN	
				CLEAR n_banco
			ELSE
				DISPLAY r_g08.g08_nombre TO n_banco
			END IF 
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM cxpt024 ',  
            ' WHERE p24_compania  = ', vg_codcia, 
	    '   AND p24_localidad = ', vg_codloc,
	    '   AND p24_tipo = "A"',
	    '   AND ', expr_sql CLIPPED,
	    ' ORDER BY 1, 2, 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_p24.*, vm_rows[vm_num_rows]
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

SELECT * INTO rm_p24.* FROM cxpt024 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_p24.p24_orden_pago,
		rm_p24.p24_estado,
		rm_p24.p24_codprov,     
		rm_p24.p24_referencia, 
		rm_p24.p24_total_cap,
		rm_p24.p24_banco,
		rm_p24.p24_numero_cta,
		rm_p24.p24_moneda,     
		rm_p24.p24_subtipo,
		rm_p24.p24_paridad,
		rm_p24.p24_usuario,
		rm_p24.p24_fecing   
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

DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE r_g08		RECORD LIKE gent008.*

DEFINE nom_estado		CHAR(9)

CASE rm_p24.p24_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'P' LET nom_estado = 'PROCESADO'
END CASE

CALL fl_lee_subtipo_entidad(vm_entidad, rm_p24.p24_subtipo) RETURNING r_g12.*
CALL fl_lee_banco_general(rm_p24.p24_banco) 	RETURNING r_g08.*
CALL fl_lee_proveedor(rm_p24.p24_codprov) RETURNING r_p01.*
CALL fl_lee_moneda(rm_p24.p24_moneda) RETURNING r_g13.*

DISPLAY nom_estado        TO n_estado
DISPLAY r_p01.p01_nomprov TO n_proveedor
DISPLAY r_g13.g13_nombre  TO n_moneda
DISPLAY r_g08.g08_nombre  TO n_banco 
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



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM cxpt024
	WHERE p24_compania   = vg_codcia
	  AND p24_localidad  = vg_codloc
	  AND p24_orden_pago = vm_ord_pago
	  AND p24_tipo       = 'A'
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe orden de pago.', 
		'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION ver_estado_cuenta()

DEFINE comando		CHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', 
	vg_separador, 'fuentes', vg_separador, '; fglrun cxpp300 ', vg_base, 
	' ', 'TE', vg_codcia, ' ', vg_codloc, ' ', rm_p24.p24_codprov, 
	' ', rm_p24.p24_moneda
	
RUN comando	

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
