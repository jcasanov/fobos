------------------------------------------------------------------------------
-- Titulo           : ctbp201.4gl - Mantenimiento de transacciones contables
-- Elaboracion      : 30-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun ctbp201 base modulo compania [tipo_comp num_comp]
--			Si tipo_comp y num_comp son nulos el programa
--			se esta ejecutando en forma independiente
--			Si tipo_comp y num_comp no son nulos el programa
--			se esta ejecutando en modo de solo consulta
-- Ultima Correccion: 27-05-2002
-- Motivo Correccion: ## linea 2013 LET r_p20.p20_cod_dpto    = 1 
                      ## Se le agrega este LET se estaba cayendo al
		      ## insertar nulo en un campo not null (RCA)
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE vm_num_comp	LIKE ctbt012.b12_num_comp

DEFINE vm_nota_debito	LIKE cxpt020.p20_tipo_doc 
DEFINE vm_ajuste	LIKE cxpt022.p22_tipo_trn 
DEFINE vm_egreso	LIKE ctbt012.b12_tipo_comp
DEFINE vm_nivel_cta	LIKE ctbt001.b01_nivel
DEFINE vm_filas_pant	SMALLINT

DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows		ARRAY[1000] OF INTEGER	-- ARREGLO DE ROWID FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_b12		RECORD LIKE ctbt012.*
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE vm_max_cta	SMALLINT
DEFINE vm_ind_cta	SMALLINT
DEFINE rm_cuenta	ARRAY[2000] OF RECORD
				cuenta		LIKE ctbt013.b13_cuenta,
				tipo_doc	LIKE ctbt013.b13_tipo_doc,
				glosa		LIKE ctbt013.b13_glosa,
				valor_debito	LIKE ctbt013.b13_valor_base,
				valor_credito	LIKE ctbt013.b13_valor_base
			END RECORD
DEFINE rm_otros		ARRAY[2000] OF RECORD
				b13_codcli	LIKE ctbt013.b13_codcli,
				b13_codprov	LIKE ctbt013.b13_codprov,
				b13_pedido	LIKE ctbt013.b13_pedido
			END RECORD
DEFINE rm_secuencia	ARRAY[2000] OF SMALLINT
DEFINE rm_g05		RECORD LIKE gent005.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp201.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 5 THEN -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'ctbp201'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc

INITIALIZE vm_tipo_comp, vm_num_comp TO NULL
IF num_args() = 5 THEN
	LET vm_tipo_comp = arg_val(4)
	LET vm_num_comp  = arg_val(5)
END IF

--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_201 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_201 FROM '../forms/ctbf201_1'
ELSE
	OPEN FORM f_201 FROM '../forms/ctbf201_1c'
END IF
DISPLAY FORM f_201

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_b12.* TO NULL
CALL muestra_contadores()

CALL setea_nombre_botones_f1()

LET vm_max_rows = 1000
LET vm_max_cta  = 2000

CALL fl_lee_compania_contabilidad(vg_codcia) 	RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuración para esta compañía en el módulo.','stop')
	LET int_flag = 0
	CLOSE WINDOW w_201
	EXIT PROGRAM
END IF

SELECT MAX(b01_nivel) INTO vm_nivel_cta FROM ctbt001
IF vm_nivel_cta IS NULL THEN
	CALL fl_mostrar_mensaje('No se ha configurado el plan de cuentas.','stop')
	LET int_flag = 0
	CLOSE WINDOW w_201
	EXIT PROGRAM
END IF

FOR i = 1 TO 10
       	LET rm_orden[i] = 'ASC'
END FOR

CREATE TEMP TABLE tmp_detalle(
	secuencia	SMALLINT,
	cuenta		CHAR(12),
	tipo_doc	CHAR(3),
	--glosa		VARCHAR(35),
	glosa		VARCHAR(90),
	valor_debito	DECIMAL(14,2),
	valor_credito	DECIMAL(14,2),
	num_concil	INTEGER,
	b13_codcli	INTEGER,
	b13_codprov	INTEGER,
	b13_pedido	char(10)
);
-- CREATE UNIQUE INDEX tmp_pk   ON tmp_detalle(secuencia);

IF vm_tipo_comp IS NOT NULL THEN
	CALL execute_query()
	LET int_flag = 0
	CLOSE WINDOW w_201
	DROP TABLE tmp_detalle
	EXIT PROGRAM
END IF
LET vm_egreso      = 'EG'
LET vm_nota_debito = 'ND'
LET vm_ajuste      = 'AJ' 
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Origen'
		IF vm_tipo_comp IS NOT NULL THEN -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'   -- consulta
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Origen'
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Detalle'
		ELSE
			HIDE OPTION 'Imprimir'
			HIDE OPTION 'Detalle'
		END IF
		CALL setea_nombre_botones_f1()
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
		CALL setea_nombre_botones_f1()
	COMMAND KEY('E') 'Eliminar'		'Elimina registro corriente.'
		CALL control_eliminacion()
		CALL setea_nombre_botones_f1()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Detalle'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			IF rm_g05.g05_tipo <> 'UF' OR rm_b12.b12_origen = 'M'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Eliminar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			IF rm_g05.g05_tipo <> 'UF' OR rm_b12.b12_origen = 'M'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
			END IF
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Origen'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Detalle'
		ELSE
			HIDE OPTION 'Detalle'
			HIDE OPTION 'Imprimir'
		END IF
		CALL setea_nombre_botones_f1()
	COMMAND KEY('O') 'Origen'		'Ver transacción origen.'
		IF rm_b12.b12_modulo IS NOT NULL AND rm_b12.b12_origen = 'A' 
			THEN
			CALL control_origen_comprobante()
		END IF
	COMMAND KEY('D') 'Detalle'		'Ver detalle del comprobante.'
		CALL control_detalle()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Detalle'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		SHOW OPTION 'Detalle'
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Detalle'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		SHOW OPTION 'Detalle'
	COMMAND KEY('P') 'Imprimir'
		CALL control_impresion_comprobantes()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU
LET int_flag = 0
CLOSE WINDOW w_201
--DROP TABLE tmp_detalle
EXIT PROGRAM

END FUNCTION



FUNCTION control_ingreso()

DEFINE rowid		INTEGER
DEFINE done 		SMALLINT
DEFINE j		SMALLINT

CLEAR FORM
INITIALIZE rm_b12.* TO NULL

LET rm_b12.b12_fecing   = CURRENT
LET rm_b12.b12_usuario  = vg_usuario
LET rm_b12.b12_compania = vg_codcia
LET rm_b12.b12_moneda   = rm_b00.b00_moneda_base
LET rm_b12.b12_estado   = 'A'
LET rm_b12.b12_origen   = 'M'
LET rm_b12.b12_fec_proceso = TODAY
CALL muestra_etiquetas()

CALL lee_datos('I')
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

DELETE FROM tmp_detalle

FOR j = 1 TO vm_max_cta
	INITIALIZE rm_cuenta[j].* TO NULL	
	INITIALIZE rm_otros[j].* TO NULL	
END FOR
FOR j = 1 TO vm_ind_cta
	INITIALIZE rm_cuenta[j].* TO NULL	
	INITIALIZE rm_otros[j].* TO NULL	
	IF j <= fgl_scr_size('ra_cuenta') THEN
		CLEAR ra_cuenta[j].*
	END IF
END FOR


LET vm_ind_cta = 0
CALL ingresa_detalle()
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

LET rm_b12.b12_num_comp = fl_numera_comprobante_contable(vg_codcia, 
			rm_b12.b12_tipo_comp, 
			YEAR(rm_b12.b12_fec_proceso), 
			MONTH(rm_b12.b12_fec_proceso))

INSERT INTO ctbt012 VALUES (rm_b12.*)

LET rowid = SQLCA.SQLERRD[6] 		-- Rowid de la ultima fila
	                        	-- procesada
LET done = grabar_detalle()
IF NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

COMMIT WORK

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = rowid

CALL fl_mayoriza_comprobante(vg_codcia, rm_b12.b12_tipo_comp, 
			     rm_b12.b12_num_comp, 'M')
IF vg_codcia <> 3 THEN
	--CALL mayoriza_cta_balance_sin_cierre(rm_b12.b12_tipo_comp, rm_b12.b12_num_comp, 'M')
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()
DEFINE j		SMALLINT
DEFINE done 		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
FOR j = 1 TO vm_max_cta
	INITIALIZE rm_cuenta[j].* TO NULL	
	INITIALIZE rm_otros[j].* TO NULL	
END FOR

IF rm_b12.b12_estado = 'E' THEN
	--CALL fgl_winmessage(vg_producto,'El registro fue eliminado y no se puede modificar.','exclamation')
	CALL fl_mostrar_mensaje('El registro fue eliminado y no se puede modificar.','exclamation')
	RETURN
END IF

IF rm_b12.b12_origen = 'M' THEN
	IF rm_b00.b00_modi_compma = 'N' THEN
		--CALL fgl_winmessage(vg_producto,'Debido a la configuración general del módulo, no se pueden modificar los comprobantes generados manualmente.','exclamation')
		CALL fl_mostrar_mensaje('Debido a la configuración general del módulo, no se pueden modificar los comprobantes generados manualmente.','exclamation')
		RETURN
	END IF
END IF
IF rm_b12.b12_origen = 'A' THEN
	IF rm_b00.b00_modi_compau = 'N' THEN
		--CALL fgl_winmessage(vg_producto,'Debido a la configuración general del módulo, no se pueden modificar los comprobantes generados automaticamente.','exclamation')
		CALL fl_mostrar_mensaje('Debido a la configuración general del módulo, no se pueden modificar los comprobantes generados automaticamente.','exclamation')
		RETURN
	END IF
END IF
IF rm_b12.b12_fec_proceso <= rm_b00.b00_fecha_cm THEN
	--CALL fgl_winmessage(vg_producto,'No puede corregir un comprobante de un mes cerrado.','exclamation')
	CALL fl_mostrar_mensaje('No puede corregir un comprobante de un mes cerrado.','exclamation')
	RETURN
END IF
IF fecha_bloqueada(vg_codcia, MONTH(rm_b12.b12_fec_proceso),
	   YEAR(rm_b12.b12_fec_proceso)) THEN
	--CALL fgl_winmessage(vg_producto,'No puede corregir un comprobante de una fecha bloqueada.','exclamation')
	CALL fl_mostrar_mensaje('No puede corregir un comprobante de una fecha bloqueada.','exclamation')
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR 
	SELECT * FROM ctbt012 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_b12.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF  

WHENEVER ERROR STOP
CALL lee_datos('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

CALL ingresa_detalle()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

COMMIT WORK

IF rm_b12.b12_estado = 'M' THEN
	CALL fl_mayoriza_comprobante(vg_codcia, rm_b12.b12_tipo_comp, 
				     rm_b12.b12_num_comp, 'D')
	IF vg_codcia <> 3 THEN
		--CALL mayoriza_cta_balance_sin_cierre(rm_b12.b12_tipo_comp, rm_b12.b12_num_comp, 'D')
	END IF
END IF

BEGIN WORK

SET LOCK MODE TO WAIT 5

WHENEVER ERROR CONTINUE
DECLARE q_upd2 CURSOR FOR 
	SELECT * FROM ctbt012 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd2
FETCH q_upd2
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF  

WHENEVER ERROR STOP

SET LOCK MODE TO NOT WAIT

LET rm_b12.b12_fec_modifi = CURRENT

UPDATE ctbt012 SET * = rm_b12.* WHERE CURRENT OF q_upd2

LET done = grabar_detalle()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF

COMMIT WORK

CALL fl_mayoriza_comprobante(vg_codcia, rm_b12.b12_tipo_comp, 
			     rm_b12.b12_num_comp, 'M')
IF vg_codcia <> 3 THEN
	--CALL mayoriza_cta_balance_sin_cierre(rm_b12.b12_tipo_comp, rm_b12.b12_num_comp, 'M')
END IF

DISPLAY BY NAME rm_b12.b12_fec_modifi
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r_b03		RECORD LIKE ctbt003.*
DEFINE r_b04		RECORD LIKE ctbt004.*
DEFINE r_b06		RECORD LIKE ctbt006.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE tipo_ori		LIKE ctbt012.b12_tipo_comp

LET tipo_ori = rm_b12.b12_tipo_comp
LET int_flag = 0
INPUT BY NAME rm_b12.b12_tipo_comp,  rm_b12.b12_num_comp,    rm_b12.b12_estado,
	      rm_b12.b12_subtipo,    rm_b12.b12_glosa,       rm_b12.b12_moneda,
	      rm_b12.b12_paridad,    rm_b12.b12_fec_proceso, 
	      rm_b12.b12_num_cheque, rm_b12.b12_benef_che,
	      rm_b12.b12_fec_modifi, rm_b12.b12_origen,
              rm_b12.b12_usuario,    rm_b12.b12_fecing WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(b12_tipo_comp, b12_subtipo, b12_glosa,
				     b12_benef_che, b12_num_cheque,
				     b12_moneda, b12_fec_proceso
                                    ) THEN
			EXIT INPUT
		END IF

		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(b12_tipo_comp) THEN
			CALL fl_ayuda_tipos_comprobantes(vg_codcia)
				RETURNING r_b03.b03_tipo_comp,
					  r_b03.b03_nombre
			IF r_b03.b03_tipo_comp IS NOT NULL THEN
				LET rm_b12.b12_tipo_comp = r_b03.b03_tipo_comp
				DISPLAY BY NAME rm_b12.b12_tipo_comp
			END IF
		END IF
		IF INFIELD(b12_subtipo) THEN
			CALL fl_ayuda_subtipos_comprobantes(vg_codcia)
				RETURNING r_b04.b04_subtipo,
					  r_b04.b04_nombre
			IF r_b04.b04_subtipo IS NOT NULL THEN
				LET rm_b12.b12_subtipo = r_b04.b04_subtipo
				DISPLAY BY NAME rm_b12.b12_subtipo
				DISPLAY r_b04.b04_nombre TO n_subtipo
			END IF
		END IF
		IF INFIELD(b12_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda,
							  r_g13.g13_nombre,
							  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_b12.b12_moneda = r_g13.g13_moneda
				DISPLAY BY NAME rm_b12.b12_moneda
				DISPLAY r_g13.g13_nombre TO n_moneda
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		CALL setea_nombre_botones_f1()
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD b12_tipo_comp
		IF flag = 'M' THEN
			LET rm_b12.b12_tipo_comp = tipo_ori
			DISPLAY BY NAME rm_b12.b12_tipo_comp
		END IF
		IF rm_b12.b12_tipo_comp IS NULL THEN
			CONTINUE INPUT
		END IF
		CALL fl_lee_tipo_comprobante_contable(vg_codcia, 
			rm_b12.b12_tipo_comp) RETURNING r_b03.*
		IF r_b03.b03_tipo_comp IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Este tipo de comprobante no existe.','exclamation')
			CALL fl_mostrar_mensaje('Este tipo de comprobante no existe.','exclamation')
			NEXT FIELD b12_tipo_comp
		END IF
		IF r_b03.b03_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD b12_tipo_comp
		END IF
	AFTER FIELD b12_subtipo
		IF rm_b12.b12_subtipo IS NULL THEN
			CLEAR n_subtipo
			CONTINUE INPUT
		END IF
		CALL fl_lee_subtipo_comprob_contable(vg_codcia, 
			rm_b12.b12_subtipo) RETURNING r_b04.*
		IF r_b04.b04_subtipo IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Este subtipo de comprobante no existe.','exclamation')
			CALL fl_mostrar_mensaje('Este subtipo de comprobante no existe.','exclamation')
			NEXT FIELD b12_subtipo
		END IF
		IF r_b04.b04_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD b12_subtipo
		END IF
		DISPLAY r_b04.b04_nombre TO n_subtipo
	AFTER FIELD b12_num_cheque
		IF rm_b12.b12_num_cheque IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_b12.b12_tipo_comp <> vm_egreso AND 
			rm_b12.b12_tipo_comp <> 'DC' THEN
			INITIALIZE rm_b12.b12_num_cheque TO NULL
			DISPLAY BY NAME rm_b12.b12_num_cheque
		END IF
	AFTER FIELD b12_benef_che
		IF rm_b12.b12_benef_che IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_b12.b12_tipo_comp <> vm_egreso AND
			rm_b12.b12_tipo_comp <> 'DC' THEN
			INITIALIZE rm_b12.b12_benef_che TO NULL
			DISPLAY BY NAME rm_b12.b12_benef_che
		END IF
	AFTER FIELD b12_moneda
		IF rm_b12.b12_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_b12.b12_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN	
				--CALL FGL_WINMESSAGE(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				CLEAR n_moneda
				NEXT FIELD b12_moneda
			ELSE
				IF  r_g13.g13_moneda <> rm_b00.b00_moneda_base
				AND r_g13.g13_moneda <> rm_b00.b00_moneda_aux
				THEN
					--CALL fgl_winmessage(vg_producto,'La moneda debe ser la moneda base o la moneda alterna.','exclamation')
					CALL fl_mostrar_mensaje('La moneda debe ser la moneda base o la moneda alterna.','exclamation')
					CLEAR n_moneda
					LET rm_b12.b12_moneda = 
						rm_b00.b00_moneda_base
					DISPLAY BY NAME rm_b12.b12_moneda
					NEXT FIELD b12_moneda
				END IF
				IF r_g13.g13_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					CLEAR n_moneda
					NEXT FIELD b12_moneda
				ELSE
					DISPLAY r_g13.g13_nombre TO n_moneda
					CALL muestra_paridad_moneda_actual()
				END IF
			END IF 
		END IF
	BEFORE FIELD b12_fec_proceso
		IF flag = 'M' THEN
			NEXT FIELD b12_num_cheque
		END IF
	AFTER FIELD b12_fec_proceso
		IF rm_b12.b12_fec_proceso IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_b12.b12_fec_proceso > TODAY THEN
			--CALL fgl_winmessage(vg_producto,'La fecha de proceso no puede ser mayor a la fecha actual.','exclamation')
			CALL fl_mostrar_mensaje('La fecha de proceso no puede ser mayor a la fecha actual.','exclamation')
			NEXT FIELD b12_fec_proceso
		END IF
		IF YEAR(rm_b12.b12_fec_proceso) < rm_b00.b00_anopro THEN
			--CALL fgl_winmessage(vg_producto,'Año de proceso contable está incorrecto.','exclamation')
			CALL fl_mostrar_mensaje('Año de proceso contable está incorrecto.','exclamation')
			NEXT FIELD b12_fec_proceso
		END IF
		IF YEAR(rm_b12.b12_fec_proceso) <= YEAR(rm_b00.b00_fecha_ca)
		THEN
			--CALL fgl_winmessage(vg_producto,'Año contable está cerrado.','exclamation')
			CALL fl_mostrar_mensaje('Año contable está cerrado.','exclamation')
			NEXT FIELD b12_fec_proceso
		END IF
		IF YEAR(rm_b12.b12_fec_proceso) < YEAR(rm_b00.b00_fecha_cm)
		THEN
			--CALL fgl_winmessage(vg_producto,'Mes contable está cerrado.','exclamation')
			CALL fl_mostrar_mensaje('Mes contable está cerrado.','exclamation')
			NEXT FIELD b12_fec_proceso
		END IF
		IF YEAR(rm_b12.b12_fec_proceso) = YEAR(rm_b00.b00_fecha_cm)
		THEN
			IF MONTH(rm_b12.b12_fec_proceso) <= 
				MONTH(rm_b00.b00_fecha_cm)
			THEN
				--CALL fgl_winmessage(vg_producto,'Mes contable está cerrado.','exclamation')
				CALL fl_mostrar_mensaje('Mes contable está cerrado.','exclamation')
				NEXT FIELD b12_fec_proceso
			END IF
		END IF
		IF fecha_bloqueada(vg_codcia, MONTH(rm_b12.b12_fec_proceso),
				   YEAR(rm_b12.b12_fec_proceso)) THEN
			NEXT FIELD b12_fec_proceso
		END IF
	AFTER INPUT
		CALL muestra_paridad_moneda_actual()
		IF rm_b12.b12_tipo_comp = 'EG' THEN
			IF rm_b12.b12_num_cheque IS NULL THEN
				CALL fl_mostrar_mensaje('Se necesita que ingrese el número del cheque de este Egreso.','exclamation')
				NEXT FIELD b12_num_cheque
			END IF
			IF rm_b12.b12_benef_che IS NULL THEN
				CALL fl_mostrar_mensaje('Se necesita que ingrese el beneficiario del cheque para este Egreso.','exclamation')
				NEXT FIELD b12_benef_che
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_paridad_moneda_actual()

LET rm_b12.b12_paridad = 
	calcula_paridad(rm_b12.b12_moneda, rm_b00.b00_moneda_base)
IF rm_b12.b12_paridad IS NULL THEN
	LET rm_b12.b12_moneda = rm_b00.b00_moneda_base
	DISPLAY BY NAME rm_b12.b12_moneda
	LET rm_b12.b12_paridad = 
		calcula_paridad(rm_b12.b12_moneda, rm_b00.b00_moneda_base)
END IF
DISPLAY BY NAME rm_b12.b12_paridad
		
END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(500)
DEFINE query		CHAR(800)

DEFINE r_b03		RECORD LIKE ctbt003.*
DEFINE r_b04		RECORD LIKE ctbt004.*
DEFINE r_g13		RECORD LIKE gent013.*

CLEAR FORM

LET int_flag = 0
CONSTRUCT BY NAME expr_sql 
	ON b12_tipo_comp,  b12_num_comp,   b12_estado,    b12_subtipo,  
	   b12_glosa,      b12_moneda,     b12_paridad,   b12_fec_proceso, 
	   b12_origen,     b12_num_cheque, b12_benef_che, b12_usuario, 
	   b12_fecing,     b12_fec_modifi
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(b12_tipo_comp) THEN
			CALL fl_ayuda_tipos_comprobantes(vg_codcia)
				RETURNING r_b03.b03_tipo_comp,
					  r_b03.b03_nombre
			IF r_b03.b03_tipo_comp IS NOT NULL THEN
				LET rm_b12.b12_tipo_comp = r_b03.b03_tipo_comp
				DISPLAY BY NAME rm_b12.b12_tipo_comp
			END IF
		END IF
		IF INFIELD(b12_subtipo) THEN
			CALL fl_ayuda_subtipos_comprobantes(vg_codcia)
				RETURNING r_b04.b04_subtipo,
					  r_b04.b04_nombre
			IF r_b04.b04_subtipo IS NOT NULL THEN
				LET rm_b12.b12_subtipo = r_b04.b04_subtipo
				DISPLAY BY NAME rm_b12.b12_subtipo
				DISPLAY r_b04.b04_nombre TO n_subtipo
			END IF
		END IF
		IF INFIELD(b12_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda,
							  r_g13.g13_nombre,
							  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_b12.b12_moneda = r_g13.g13_moneda
				DISPLAY BY NAME rm_b12.b12_moneda
				DISPLAY r_g13.g13_nombre TO n_moneda
			END IF
		END IF
		LET int_flag = 0
	BEFORE CONSTRUCT
		CALL setea_nombre_botones_f1()
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT

IF int_flag THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM ctbt012 ',
	    '	WHERE b12_compania  = ', vg_codcia,
	    '     AND ', expr_sql CLIPPED
IF rm_g05.g05_tipo = 'UF' THEN
	LET query = query CLIPPED,
			'   AND b12_usuario = "', rm_g05.g05_usuario CLIPPED,'"'
END IF
LET query = query CLIPPED, 
	    '	ORDER BY 1, 2, 3, 4'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_b12.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
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

SELECT * INTO rm_b12.* FROM ctbt012 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_b12.b12_tipo_comp, 
		rm_b12.b12_num_comp, 
		rm_b12.b12_estado,
	      	rm_b12.b12_subtipo,   
	      	rm_b12.b12_glosa,    
	      	rm_b12.b12_benef_che,
              	rm_b12.b12_num_cheque, 
              	rm_b12.b12_moneda,  
              	rm_b12.b12_paridad,
 	      	rm_b12.b12_fec_proceso, 
		rm_b12.b12_origen,
	      	rm_b12.b12_fec_modifi,
              	rm_b12.b12_usuario, 
              	rm_b12.b12_fecing
CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()


END FUNCTION



FUNCTION setea_nombre_botones_f1()

--#DISPLAY 'Cuenta'	TO 	bt_cuenta
--#DISPLAY 'Doc'	TO 	bt_tipo_doc
--#DISPLAY 'Glosa' 	TO 	bt_glosa
--#DISPLAY 'Crédito'	TO 	bt_credito
--#DISPLAY 'Débito'	TO 	bt_debito

END FUNCTION



FUNCTION muestra_contadores()

IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67
END IF

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

DEFINE nom_estado	CHAR(10)
DEFINE nom_origen	CHAR(11)

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_b04		RECORD LIKE ctbt004.*

CALL fl_lee_moneda(rm_b12.b12_moneda)		RETURNING r_g13.*
CALL fl_lee_subtipo_comprob_contable(vg_codcia, rm_b12.b12_subtipo)
	RETURNING r_b04.*

CASE rm_b12.b12_estado 
	WHEN 'A'
		LET nom_estado = 'ACTIVO'
	WHEN 'M'
		LET nom_estado = 'MAYORIZADO'
	WHEN 'E'
		LET nom_estado = 'ELIMINADO'
END CASE

CASE rm_b12.b12_origen
	WHEN 'A'
		LET nom_origen = 'AUTOMATICO'
	WHEN 'M'
		LET nom_origen = 'MANUAL'
END CASE

DISPLAY nom_estado   		TO n_estado
DISPLAY nom_origen 		TO n_origen
DISPLAY r_g13.g13_nombre	TO n_moneda
DISPLAY r_b04.b04_nombre	TO n_subtipo

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE gent013.g13_moneda
DEFINE moneda_dest	LIKE gent013.g13_moneda
DEFINE paridad		LIKE gent014.g14_tasa

DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		--CALL fgl_winmessage(vg_producto,'No existe factor de conversión para esta moneda.','exclamation')
		CALL fl_mostrar_mensaje('No existe factor de conversión para esta moneda.','exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION ingresa_detalle()
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b07		RECORD LIKE ctbt007.*
DEFINE num_concil	LIKE ctbt013.b13_num_concil
DEFINE codt_aux		LIKE ctbt007.b07_tipo_doc
DEFINE nomt_aux		LIKE ctbt007.b07_nombre
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE val_deb, val_cre	LIKE ctbt013.b13_valor_base
DEFINE resp		CHAR(6)
DEFINE i, j, col, salir	SMALLINT
DEFINE query		CHAR(255)
DEFINE tot_deb_cre	DECIMAL(12,2)
DEFINE max_row		INTEGER

LET vm_columna_1 = 1
LET vm_columna_2 = 6
LET rm_orden[vm_columna_1]  = 'ASC'
LET rm_orden[vm_columna_2]  = 'DESC'
INITIALIZE col TO NULL

SELECT SUM(valor_credito), SUM(valor_debito) INTO credito, debito 
	FROM tmp_detalle
IF credito IS NULL THEN
	LET credito = 0
END IF
IF debito IS NULL THEN
	LET debito  = 0 
END IF
LET tot_deb_cre = debito - credito
DISPLAY debito, credito TO tot_debito, tot_credito
DISPLAY BY NAME tot_deb_cre

LET salir  = 0
OPTIONS
	INSERT KEY F30
WHILE NOT salir
        LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE deto FROM query
        DECLARE q_deto CURSOR FOR deto 
        LET i = 1
        FOREACH q_deto INTO rm_secuencia[i], rm_cuenta[i].*, num_concil, 
			    rm_otros[i].*
                LET i = i + 1
                IF i > vm_max_cta THEN
                	CALL fl_mensaje_arreglo_incompleto()
                	LET int_flag = 1
                        RETURN
                END IF
        END FOREACH
        LET vm_ind_cta = i - 1

        LET i = 1
        LET j = 1
        LET int_flag = 0
{
	IF vm_ind_cta > 0 THEN
		CALL set_count(vm_ind_cta)
	END IF
}
	CALL set_count(vm_ind_cta)
	--#CALL fgl_keysetlabel('F5', 'Otros Datos')
	INPUT ARRAY rm_cuenta WITHOUT DEFAULTS FROM ra_cuenta.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F2)	
			IF INFIELD(b13_cuenta) THEN
				CALL fl_ayuda_cuenta_contable(vg_codcia, 
					vm_nivel_cta) 
					RETURNING r_b10.b10_cuenta, 
        					  r_b10.b10_descripcion 
				IF r_b10.b10_cuenta IS NOT NULL THEN
					LET rm_cuenta[i].cuenta = 
						r_b10.b10_cuenta
					DISPLAY rm_cuenta[i].cuenta
						TO ra_cuenta[j].b13_cuenta
					DISPLAY r_b10.b10_descripcion 
						TO n_cuenta
					DISPLAY rm_cuenta[i].glosa TO n_glosa
				END IF	
			END IF
			IF INFIELD(b13_tipo_doc) THEN
				CALL fl_ayuda_tipos_documentos_fuentes()
					RETURNING codt_aux, nomt_aux
				LET int_flag = 0
				IF codt_aux IS NOT NULL THEN
               	              		LET rm_cuenta[i].tipo_doc = codt_aux
					DISPLAY rm_cuenta[i].tipo_doc TO 
						ra_cuenta[j].b13_tipo_doc
				END IF 
			END IF
			LET int_flag = 0	
		ON KEY(F5)
			CALL lee_otros_datos(i, 1)
			IF rm_secuencia[i] IS NOT NULL THEN
				LET rm_secuencia[i] = 
				graba_valores(i,rm_secuencia[i])
				CALL obtener_secuencia()
			END IF
			LET int_flag = 0
		ON KEY(F15)
			LET col = 2
			EXIT INPUT
		ON KEY(F16)
			LET col = 3
			EXIT INPUT
		ON KEY(F17)
			LET col = 4
			EXIT INPUT
		ON KEY(F18)
			LET col = 5
			EXIT INPUT
		ON KEY(F19)
			LET col = 6
			EXIT INPUT
		BEFORE INPUT 
			--#CALL dialog.keysetlabel('INSERT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			LET vm_filas_pant = fgl_scr_size('ra_cuenta')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			LET max_row = arr_count()
			IF i > max_row THEN
				LET max_row = max_row + 1
			END IF
			CALL muestra_contadores_det(i, max_row)
			CALL fl_lee_cuenta(vg_codcia, rm_cuenta[i].cuenta)
				RETURNING r_b10.*
			DISPLAY r_b10.b10_descripcion TO n_cuenta
			DISPLAY rm_cuenta[i].glosa    TO n_glosa
			LET val_deb = rm_cuenta[i].valor_debito
			LET val_cre = rm_cuenta[i].valor_credito
			IF val_deb IS NULL THEN
				LET val_deb = 0
			END IF
			IF val_cre IS NULL THEN
				LET val_cre = 0
			END IF
		BEFORE DELETE
			LET i = arr_curr()
			CALL sincroniza_arrreglo_otros(i, arr_count())
			CALL deleteRow(i, rm_secuencia[i])
			CALL obtener_secuencia()
			{--
			WHILE (i < arr_count())
				LET rm_secuencia[i] = rm_secuencia[i + 1]
				LET i = i + 1
			END WHILE
			INITIALIZE rm_secuencia[i] TO NULL
			--}
			LET i = arr_curr()
			IF vm_ind_cta > 0 THEN
				LET vm_ind_cta = vm_ind_cta - 1
			END IF
		BEFORE FIELD valor_credito
			LET credito = rm_cuenta[i].valor_credito
		BEFORE FIELD valor_debito
			LET debito = rm_cuenta[i].valor_debito
		AFTER DELETE
			CALL calcula_totales()
		AFTER ROW
			LET i = arr_curr()
			IF FIELD_TOUCHED(valor_debito, valor_credito) THEN
				IF val_deb <> rm_cuenta[i].valor_debito OR
				   val_cre <> rm_cuenta[i].valor_credito
				THEN
					IF rm_secuencia[i] IS NOT NULL THEN
						LET rm_secuencia[i] = 
						graba_valores(i,rm_secuencia[i])
						CALL obtener_secuencia()
					END IF
					CALL calcula_totales()
				END IF
			END IF
		AFTER INSERT
			CALL calcula_totales()
		AFTER FIELD b13_cuenta
			IF rm_cuenta[i].cuenta IS NOT NULL THEN
				CALL fl_lee_cuenta(vg_codcia, 
						   rm_cuenta[i].cuenta) 
					RETURNING r_b10.*
				IF r_b10.b10_cuenta IS NULL THEN
					CALL fl_mostrar_mensaje('No existe cuenta contable.','exclamation')
					NEXT FIELD b13_cuenta
				END IF
				IF r_b10.b10_permite_mov = 'N' THEN
					CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
					NEXT FIELD b13_cuenta
				END IF
				IF r_b10.b10_estado = 'B' THEN
					CALL fl_mostrar_mensaje('Esta cuenta esta bloqueada y no puede ser utilizada para ningun ingreso/modificacion de diarios contables.', 'exclamation')
					NEXT FIELD b13_cuenta
				END IF
				DISPLAY r_b10.b10_descripcion TO n_cuenta
				DISPLAY rm_cuenta[i].glosa TO n_glosa
				CALL actualiza_reg_cont(i, rm_secuencia[i])
			END IF	
		AFTER FIELD b13_tipo_doc
			IF rm_cuenta[i].tipo_doc IS NOT NULL THEN
		       		CALL fl_lee_tipo_documento_fuente(rm_cuenta[i].tipo_doc)
					RETURNING r_b07.*
				IF r_b07.b07_tipo_doc IS NULL THEN
					CALL fl_mostrar_mensaje('No existe ese Tipo de Documento.','exclamation')
					NEXT FIELD b13_tipo_doc
				END IF
				IF r_b07.b07_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD b13_tipo_doc
				END IF
				CALL actualiza_reg_cont(i, rm_secuencia[i])
			END IF
		AFTER FIELD b13_glosa
			IF rm_cuenta[i].glosa IS NOT NULL THEN
				CALL actualiza_reg_cont(i, rm_secuencia[i])
			END IF
		AFTER FIELD valor_credito
			IF rm_cuenta[i].valor_credito IS NULL THEN
				LET rm_cuenta[i].valor_credito = 0
				DISPLAY rm_cuenta[i].valor_credito
					TO ra_cuenta[j].valor_credito
			END IF
			IF rm_cuenta[i].valor_credito > 0 THEN
				LET rm_cuenta[i].valor_debito = 0
				DISPLAY rm_cuenta[i].valor_debito
					TO ra_cuenta[j].valor_debito
			END IF
			IF  rm_cuenta[i].valor_debito = 0 
				AND rm_cuenta[i].valor_credito = 0 THEN
				NEXT FIELD valor_debito
			END IF
			IF FIELD_TOUCHED(valor_credito) AND
			  (credito <> rm_cuenta[i].valor_credito OR
			   credito IS NULL)
			THEN
				LET rm_secuencia[i] = 
					graba_valores(i, rm_secuencia[i])
				CALL obtener_secuencia()
				CALL calcula_totales()
				IF cuenta_distribucion(vg_codcia, 
						       rm_cuenta[i].cuenta) 
				AND rm_cuenta[i].valor_credito > 0
				THEN
					CALL muestra_distribucion(vg_codcia,
						rm_cuenta[i].cuenta,
						rm_cuenta[i].valor_credito)
					LET int_flag = 0
				END IF
			END IF
			CALL calcula_totales()
		AFTER FIELD valor_debito
			IF rm_cuenta[i].valor_debito IS NULL THEN
				LET rm_cuenta[i].valor_debito = 0
				DISPLAY rm_cuenta[i].valor_debito
					TO ra_cuenta[j].valor_debito
			END IF
			IF rm_cuenta[i].valor_debito > 0 THEN
				LET rm_cuenta[i].valor_credito = 0
				DISPLAY rm_cuenta[i].valor_credito
					TO ra_cuenta[j].valor_credito
			END IF
			IF FIELD_TOUCHED(valor_debito) AND
			  (debito <> rm_cuenta[i].valor_debito OR
			   debito IS NULL)
			THEN
				LET rm_secuencia[i] = 
					graba_valores(i, rm_secuencia[i])
				CALL obtener_secuencia()
				CALL calcula_totales()
				IF cuenta_distribucion(vg_codcia, 
						      	rm_cuenta[i].cuenta) 
				AND rm_cuenta[i].valor_debito > 0
				THEN
					CALL muestra_distribucion(vg_codcia,
						rm_cuenta[i].cuenta,
						rm_cuenta[i].valor_debito)
					LET int_flag = 0
				END IF
			END IF
			CALL calcula_totales()
		AFTER INPUT
			SELECT SUM(valor_credito), SUM(valor_debito)
				INTO credito, debito
				FROM tmp_detalle
			IF credito <> debito THEN
				--CALL fgl_winmessage(vg_producto,'No cuadran los valores del crédito con el débito.','exclamation')
				CALL fl_mostrar_mensaje('No cuadran los valores del crédito con el débito.','exclamation')
				CONTINUE INPUT
			END IF
			LET vm_ind_cta = arr_count()
			IF vm_ind_cta = 0 THEN
				--CALL fgl_winquestion(vg_producto,'El comprobante no tiene detalles, y no podrá ser grabado. ¿Desea ingresar detalles?','No','Yes|No','question',1)
				CALL fl_hacer_pregunta('El comprobante no tiene detalles, y no podrá ser grabado. ¿Desea ingresar detalles?','No')
					RETURNING resp
				IF resp = 'Yes' THEN
					CONTINUE INPUT  
				ELSE
					LET int_flag = 1
				END IF
			END IF
			LET salir = 1
			CALL calcula_totales()
	END INPUT
	IF int_flag THEN
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



FUNCTION graba_valores(i, sec)
DEFINE i		SMALLINT
DEFINE sec		SMALLINT

IF i > vm_ind_cta THEN
	DELETE FROM tmp_detalle WHERE cuenta IS NULL
	SELECT NVL(MAX(secuencia) + 1, 1) INTO sec FROM tmp_detalle
	IF NOT rm_cuenta[i].cuenta        IS NULL AND
	   NOT rm_cuenta[i].valor_debito  IS NULL AND
	   NOT rm_cuenta[i].valor_credito IS NULL
	THEN
		DECLARE q_tmp CURSOR FOR
			SELECT * FROM tmp_detalle
				WHERE cuenta    = rm_cuenta[i].cuenta
				  AND secuencia = i
		OPEN q_tmp
		FETCH q_tmp
		IF STATUS = NOTFOUND THEN
			INSERT INTO tmp_detalle
				VALUES(sec, rm_cuenta[i].*, 0, rm_otros[i].*)
			LET vm_ind_cta = vm_ind_cta + 1
		END IF
	END IF
ELSE
	UPDATE tmp_detalle SET
		cuenta          = rm_cuenta[i].cuenta,
		tipo_doc        = rm_cuenta[i].tipo_doc,
		glosa           = rm_cuenta[i].glosa,
		valor_credito   = rm_cuenta[i].valor_credito,
		valor_debito    = rm_cuenta[i].valor_debito,
                b13_codcli      = rm_otros[i].b13_codcli,
                b13_codprov     = rm_otros[i].b13_codprov,
                b13_pedido      = rm_otros[i].b13_pedido
		WHERE secuencia = sec
END IF
RETURN sec

END FUNCTION



FUNCTION actualiza_reg_cont(i, sec)
DEFINE i, sec		SMALLINT

IF rm_cuenta[i].valor_credito IS NULL THEN
	RETURN
END IF
IF rm_cuenta[i].valor_debito IS NULL THEN
	RETURN
END IF
UPDATE tmp_detalle
	SET cuenta      = rm_cuenta[i].cuenta,
	    tipo_doc    = rm_cuenta[i].tipo_doc,
	    glosa       = rm_cuenta[i].glosa,
	    b13_codcli  = rm_otros[i].b13_codcli,
	    b13_codprov = rm_otros[i].b13_codprov,
	    b13_pedido  = rm_otros[i].b13_pedido
	WHERE secuencia = sec

END FUNCTION



FUNCTION calcula_totales()
DEFINE tot_credito	LIKE ctbt013.b13_valor_base
DEFINE tot_debito 	LIKE ctbt013.b13_valor_base
DEFINE tot_deb_cre	DECIMAL(12,2)

SELECT SUM(valor_credito), SUM(valor_debito)
	INTO tot_credito, tot_debito
	FROM tmp_detalle
LET tot_deb_cre = tot_debito - tot_credito
DISPLAY BY NAME tot_credito, tot_debito, tot_deb_cre
	
END FUNCTION



FUNCTION lee_detalle()
DEFINE query		CHAR(400)
DEFINE expr_valor	VARCHAR(120)
DEFINE i		SMALLINT

IF rm_b12.b12_moneda = rm_b00.b00_moneda_base THEN
	LET expr_valor = ' b13_valor_base '
ELSE
	LET expr_valor = ' b13_valor_aux '
END IF

DELETE FROM tmp_detalle

LET query = 'INSERT INTO tmp_detalle ',
	    '	SELECT b13_secuencia, b13_cuenta, b13_tipo_doc, b13_glosa, ',
	    	       expr_valor CLIPPED, ', 0, b13_num_concil, ',
	    	     ' b13_codcli, b13_codprov, b13_pedido ',        
	    '	FROM ctbt013 ',
	    '	WHERE b13_compania   = ', vg_codcia CLIPPED,
	    '	  AND b13_tipo_comp  = "', rm_b12.b12_tipo_comp CLIPPED, '"',
	    '	  AND b13_num_comp   = "', rm_b12.b12_num_comp  CLIPPED, '"',
	    '     AND b13_valor_base > 0 '
PREPARE statement3 FROM query
EXECUTE statement3
	  
LET query = 'INSERT INTO tmp_detalle ',
	    '	SELECT b13_secuencia, b13_cuenta, b13_tipo_doc, b13_glosa, ',
	    '	       0, (', expr_valor CLIPPED, ' * (-1)), b13_num_concil, ',
	    	     ' b13_codcli, b13_codprov, b13_pedido ',        
	    '	FROM ctbt013 ',
	    '	WHERE b13_compania   = ', vg_codcia CLIPPED,
	    '	  AND b13_tipo_comp  = "', rm_b12.b12_tipo_comp CLIPPED, '"',
	    '	  AND b13_num_comp   = "', rm_b12.b12_num_comp  CLIPPED, '"',
	    '     AND b13_valor_base < 0 '
PREPARE statement4 FROM query
EXECUTE statement4

SELECT COUNT(*) INTO i FROM tmp_detalle
	  
RETURN i
	
END FUNCTION



FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT

DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE secuencia_2	LIKE ctbt013.b13_secuencia

LET filas_pant = fgl_scr_size('ra_cuenta')
LET vm_filas_pant = filas_pant
FOR i = 1 TO filas_pant
	CLEAR ra_cuenta[i].*
END FOR

LET vm_ind_cta = lee_detalle()
IF vm_ind_cta = -1 THEN
	RETURN
END IF

IF vm_ind_cta < filas_pant THEN
	LET filas_pant = vm_ind_cta
END IF

DECLARE q_tmp1 CURSOR FOR
	SELECT secuencia, cuenta, tipo_doc, glosa, valor_debito, valor_credito 
		FROM tmp_detalle
		ORDER BY 1		

LET i = 1
FOREACH q_tmp1 INTO secuencia_2, rm_cuenta[i].*
	DISPLAY rm_cuenta[i].* TO ra_cuenta[i].*
	LET i = i + 1
	IF i > filas_pant THEN
		EXIT FOREACH
	END IF
END FOREACH

CALL calcula_totales()

CLEAR n_cuenta, n_glosa
CALL muestra_contadores_det(0, vm_ind_cta)
CALL fl_lee_cuenta(vg_codcia, rm_cuenta[1].cuenta) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO n_cuenta
DISPLAY rm_cuenta[1].glosa TO n_glosa

END FUNCTION



FUNCTION grabar_detalle()
DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE query		CHAR(1000)
DEFINE expr_valor	VARCHAR(100)

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_b13.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_b13 CURSOR FOR
			SELECT * FROM ctbt013
				WHERE b13_compania  = vg_codcia         
				  AND b13_tipo_comp = rm_b12.b12_tipo_comp
				  AND b13_num_comp  = rm_b12.b12_num_comp
			FOR UPDATE
	OPEN  q_b13
	FETCH q_b13 INTO r_b13.*
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

WHILE (STATUS <> NOTFOUND)
	DELETE FROM ctbt013 WHERE CURRENT OF q_b13

	INITIALIZE r_b13.* TO NULL
	FETCH q_b13 INTO r_b13.*
END WHILE
CLOSE q_b13
FREE  q_b13

-- Inserta las cuentas distribuidas en la tabla temporal
-- para que se graben en las siguientes sentencias
CALL distribuye_cuentas()

--
IF rm_b12.b12_moneda = rm_b00.b00_moneda_base THEN
	LET expr_valor = ' (valor_credito * (-1)), 0 '
ELSE
	LET expr_valor = ' (valor_credito * (-1) * ', rm_b12.b12_paridad, 
			 '), (valor_credito * (-1))'
END IF
--

LET query = 'INSERT INTO ctbt013 (b13_compania, b13_tipo_comp, b13_num_comp, ',
	    '			  b13_secuencia, b13_cuenta, b13_tipo_doc, ',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_fec_proceso, b13_num_concil, ',
	    '			  b13_codcli, b13_codprov, b13_pedido) ', 
	    '	SELECT ', vg_codcia, ', "', rm_b12.b12_tipo_comp , '", "',
	    		rm_b12.b12_num_comp CLIPPED, '", secuencia, cuenta, ',
	    '		tipo_doc, ',
	    '		glosa, ', expr_valor CLIPPED, ', ', 
	    ' 		DATE("', rm_b12.b12_fec_proceso, '"), num_concil, ',
	    '		b13_codcli, b13_codprov, b13_pedido ', 
	    '		FROM tmp_detalle ', 
	    '		WHERE valor_credito > 0 '
PREPARE statement1 FROM query
EXECUTE statement1

--
IF rm_b12.b12_moneda = rm_b00.b00_moneda_base THEN
	LET expr_valor = ' valor_debito, 0 '
ELSE
	LET expr_valor = ' (valor_debito * ', rm_b12.b12_paridad, 
			 '), valor_debito'
END IF
--
LET query = 'INSERT INTO ctbt013 (b13_compania, b13_tipo_comp, b13_num_comp, ',
	    '			  b13_secuencia, b13_cuenta, b13_tipo_doc, ',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_fec_proceso, b13_num_concil, ', 
	    '			  b13_codcli, b13_codprov, b13_pedido) ', 
	    '	SELECT ', vg_codcia, ', "', rm_b12.b12_tipo_comp , '", "',
	    		rm_b12.b12_num_comp CLIPPED, '", secuencia, cuenta, ',
	    '		tipo_doc, ',
	    '		glosa, ', expr_valor, ', ', 
	    ' 		DATE("', rm_b12.b12_fec_proceso, '"), num_concil,',
	    '		b13_codcli, b13_codprov, b13_pedido ', 
	    '		FROM tmp_detalle ', 
	    '		WHERE valor_debito > 0 '
PREPARE statement2 FROM query
EXECUTE statement2

RETURN done

END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
--CALL fgl_winquestion(vg_producto,'Registro bloqueado por otro usuario, desea intentarlo nuevamente','No','Yes|No','question',1)
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



FUNCTION control_detalle()
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE query		CHAR(255)
DEFINE num_concil	LIKE ctbt013.b13_num_concil

DEFINE r_b10		RECORD LIKE ctbt010.*

LET vm_columna_1 = 5
LET vm_columna_2 = 6
LET rm_orden[vm_columna_1]  = 'DESC'
LET rm_orden[vm_columna_2]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir

        LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]

--        LET query = 'SELECT * FROM tmp_detalle ',
--                    'ORDER BY secuencia'
        PREPARE deto2 FROM query
        DECLARE q_deto2 CURSOR FOR deto2 
        LET i = 1
        FOREACH q_deto2 INTO j, rm_cuenta[i].*, num_concil, rm_otros[i].*
                LET i = i + 1
                IF i > vm_max_cta THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_ind_cta = i - 1
        
        LET i = 1
        LET j = 1
	CALL muestra_contadores_det(1, vm_ind_cta)
	--#CALL fgl_keysetlabel('F6', 'Otros Datos')
	--#CALL fgl_keysetlabel('F7', 'Imprimir')
	CALL set_count(vm_ind_cta)
	--LET int_flag = 0
	DISPLAY ARRAY rm_cuenta TO ra_cuenta.*
		ON KEY(INTERRUPT)
			--LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F5)
			IF rm_b12.b12_modulo IS NOT NULL 
			AND rm_b12.b12_origen = 'A' 
			THEN
				CALL control_origen_comprobante()
			END IF
		ON KEY(F6)	
			LET i = arr_curr()
			CALL lee_otros_datos(i, 0)
		ON KEY(F7)	
			CALL control_impresion_comprobantes()
			LET int_flag = 0
		ON KEY(F15)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 6
			EXIT DISPLAY
		ON KEY(RETURN)
			LET i = arr_curr()
			CALL muestra_contadores_det(i, vm_ind_cta)
			CALL fl_lee_cuenta(vg_codcia, rm_cuenta[i].cuenta)
				RETURNING r_b10.*
			DISPLAY r_b10.b10_descripcion TO n_cuenta
			DISPLAY rm_cuenta[i].glosa TO n_glosa
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_det(i, vm_ind_cta)
			--#CALL fl_lee_cuenta(vg_codcia, rm_cuenta[i].cuenta)
				--#RETURNING r_b10.*
			--#DISPLAY r_b10.b10_descripcion TO n_cuenta
			--#DISPLAY rm_cuenta[i].glosa TO n_glosa
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT', '')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#IF rm_b12.b12_modulo IS NOT NULL 
			--#AND rm_b12.b12_origen = 'A' 
			--#THEN
				--#CALL dialog.keysetlabel('F5', 'Origen')
			--#ELSE
				--#CALL dialog.keysetlabel('F5', '')
			--#END IF
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag THEN
		LET salir = 1
		--LET int_flag = 0
		CONTINUE WHILE
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
CALL muestra_contadores_det(0, vm_ind_cta)

END FUNCTION



FUNCTION deleteRow(i, sec)
DEFINE i		SMALLINT
DEFINE sec		SMALLINT

DELETE FROM tmp_detalle
	WHERE secuencia = sec
UPDATE tmp_detalle
	SET secuencia = secuencia - 1
	WHERE secuencia > sec

END FUNCTION



FUNCTION obtener_secuencia()
DEFINE l		SMALLINT

FOR l = 1 TO vm_max_cta
	INITIALIZE rm_secuencia[l] TO NULL
END FOR
DECLARE q_sec CURSOR FOR SELECT secuencia FROM tmp_detalle ORDER BY 1
LET l = 1
FOREACH q_sec INTO rm_secuencia[l]
	LET l = l + 1
	IF l > vm_max_cta THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM ctbt012
	WHERE b12_compania  = vg_codcia
	  AND b12_tipo_comp = vm_tipo_comp
	  AND b12_num_comp  = vm_num_comp
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe comprobante contable.','exclamation')
	LET int_flag = 0
	CLOSE WINDOW w_201
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CALL control_detalle()	
END IF

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resp		CHAR(6)
DEFINE done		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_b12.b12_estado = 'E' THEN
	CALL fl_mostrar_mensaje('El registro ya está eliminado.','exclamation')
	RETURN
END IF
IF rm_b12.b12_origen = 'M' THEN
	IF rm_b00.b00_modi_compma = 'N' THEN
		CALL fl_mostrar_mensaje('Debido a la configuración general del módulo, no se pueden eliminar los comprobantes generados manualmente.','exclamation')
		RETURN
	END IF
END IF
IF rm_b12.b12_origen = 'A' THEN
	IF rm_b00.b00_modi_compau = 'N' THEN
		CALL fl_mostrar_mensaje('Debido a la configuración general del módulo, no se pueden eliminar los comprobantes generados automáticamente.','exclamation')
		RETURN
	END IF
END IF
IF rm_b12.b12_fec_proceso <= rm_b00.b00_fecha_cm THEN
	CALL fl_mostrar_mensaje('No puede eliminar un comprobante de un mes cerrado.','exclamation')
	RETURN
END IF
IF fecha_bloqueada(vg_codcia, MONTH(rm_b12.b12_fec_proceso),
			YEAR(rm_b12.b12_fec_proceso))
THEN
	CALL fl_mostrar_mensaje('No puede eliminar un comprobante de una fecha bloqueada.','exclamation')
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
IF rm_b12.b12_estado = 'M' THEN
	CALL fl_mayoriza_comprobante(vg_codcia, rm_b12.b12_tipo_comp, 
				     rm_b12.b12_num_comp, 'D')
	IF vg_codcia <> 3 THEN
		--CALL mayoriza_cta_balance_sin_cierre(rm_b12.b12_tipo_comp, rm_b12.b12_num_comp, 'D')
	END IF
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_del CURSOR FOR 
	SELECT * FROM ctbt012 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_del
FETCH q_del INTO rm_b12.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  
WHENEVER ERROR STOP
UPDATE ctbt012
	SET b12_estado     = 'E',
	    b12_fec_modifi = CURRENT
	WHERE CURRENT OF q_del
LET done = elimina_origen()
IF NOT done THEN
	CALL fl_mostrar_mensaje('No se pudo eliminar la transaccion origen del comprobante.','exclamation')
	ROLLBACK WORK
	RETURN
END IF
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('Registro Eliminado Ok.', 'info')

END FUNCTION



FUNCTION elimina_origen()
DEFINE done		SMALLINT
DEFINE r_p24		RECORD LIKE cxpt024.* 

LET done = 0
INITIALIZE r_p24.* TO NULL
SELECT * INTO r_p24.* FROM cxpt024 
	WHERE p24_compania     = vg_codcia
	  AND p24_tip_contable = rm_b12.b12_tipo_comp
	  AND p24_num_contable = rm_b12.b12_num_comp
--IF rm_b12.b12_tipo_comp = vm_egreso AND rm_b12.b12_origen = 'A' THEN
IF (r_p24.p24_tip_contable = vm_egreso OR
    r_p24.p24_tip_contable = 'DC' OR
    r_p24.p24_tip_contable = 'DP') AND
    rm_b12.b12_origen      = 'A'
THEN
	-- Si el comprobante se origino en una orden de pago deben restaurarse 
	-- los saldos de los documentos envueltos y deben eliminarse las 
	-- retenciones.
	IF r_p24.p24_orden_pago IS NOT NULL THEN
		IF r_p24.p24_tipo = 'P' THEN
			LET done = proceso_elim_pago_factura(r_p24.*)
		ELSE
			LET done = proceso_elim_pago_anticipo(r_p24.*)
		END IF
		CALL fl_genera_saldos_proveedor(r_p24.p24_compania,
			  		        r_p24.p24_localidad,
					        r_p24.p24_codprov)
		RETURN done
	END IF
	-- Si el select no regresa registros este comprobante no esta asociado
	-- a una orden de pago, aqui deben manejarse las otras opciones.
ELSE
	LET done = 1
END IF
RETURN done

END FUNCTION



FUNCTION proceso_elim_pago_factura(r_p24)
DEFINE r_p24		RECORD LIKE cxpt024.*
DEFINE done 		SMALLINT
DEFINE orden   		SMALLINT
DEFINE tipo_doc		LIKE cxpt020.p20_tipo_doc
DEFINE num_doc		LIKE cxpt020.p20_num_doc
DEFINE div_doc		LIKE cxpt020.p20_dividendo
DEFINE val_cap		LIKE cxpt020.p20_saldo_cap
DEFINE val_int		LIKE cxpt020.p20_saldo_int
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_doc		RECORD LIKE cxpt020.*
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE r_p27		RECORD LIKE cxpt027.*

LET done     = 0
INITIALIZE r_p27.* TO NULL
SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
DECLARE q_rt1 CURSOR FOR 
	SELECT * FROM cxpt027 
		WHERE p27_compania     = vg_codcia
		  AND p27_tip_contable = rm_b12.b12_tipo_comp
		  AND p27_num_contable = rm_b12.b12_num_comp    	
	FOR UPDATE
OPEN  q_rt1
FETCH q_rt1 INTO r_p27.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mostrar_mensaje('No se pudo eliminar las retenciones asociadas a este comprobante.','exclamation')
ELSE
	LET done = 1
END IF
IF NOT done THEN
	SET LOCK MODE TO NOT WAIT
	RETURN done
END IF
IF STATUS <> NOTFOUND THEN
	UPDATE cxpt027 SET p27_estado = 'E',
			   p27_fecha_eli = CURRENT
		 WHERE CURRENT OF q_rt1
END IF
CLOSE q_rt1
FREE  q_rt1
SET LOCK MODE TO NOT WAIT
INITIALIZE r_p22.* TO NULL
LET r_p22.p22_compania   = r_p24.p24_compania 
LET r_p22.p22_localidad  = r_p24.p24_localidad
LET r_p22.p22_codprov    = r_p24.p24_codprov
LET r_p22.p22_tipo_trn   = vm_ajuste    
LET r_p22.p22_num_trn    = fl_actualiza_control_secuencias(r_p24.p24_compania,
				r_p24.p24_localidad, 'TE', 'AA', vm_ajuste)
LET r_p22.p22_referencia = 'ELIM. COMPROBANTE: ', rm_b12.b12_tipo_comp,
			   '-', rm_b12.b12_num_comp  
LET r_p22.p22_fecha_emi  = TODAY
LET r_p22.p22_moneda     = r_p24.p24_moneda 
LET r_p22.p22_paridad    = r_p24.p24_paridad
LET r_p22.p22_tasa_mora  = 0
LET r_p22.p22_total_cap  = 0    
LET r_p22.p22_total_int  = 0  
LET r_p22.p22_total_mora = 0 
LET r_p22.p22_origen     = 'A' 
LET r_p22.p22_usuario    = vg_usuario    
LET r_p22.p22_fecing     = CURRENT
INSERT INTO cxpt022 VALUES(r_p22.*)
{--
SELECT p23_codprov codprov, p23_tipo_doc td, p23_num_doc num, p23_div_doc div_d
	FROM cxpt022, cxpt023
	WHERE p22_compania   = r_p24.p24_compania
	  AND p22_localidad  = r_p24.p24_localidad
	  AND p22_orden_pago = r_p24.p24_orden_pago
	  AND p23_compania   = p22_compania
	  AND p23_localidad  = p22_localidad
	  AND p23_codprov    = p22_codprov
	  AND p23_tipo_trn   = p22_tipo_trn
	  AND p23_num_trn    = p22_num_trn
	GROUP BY p23_codprov, p23_tipo_doc, p23_num_doc, p23_div_doc
	INTO TEMP t1
--}
DECLARE q_aj1 CURSOR FOR 
	SELECT p23_tipo_doc, p23_num_doc, p23_div_doc,
               SUM(p23_valor_cap), SUM(p23_valor_int)
		{--
                FROM cxpt023, t1
                WHERE p23_compania  = r_p24.p24_compania
                  AND p23_localidad = r_p24.p24_localidad
                  AND p23_codprov   = codprov
		  AND p23_tipo_doc  = td
                  AND p23_num_doc   = num
		  AND p23_div_doc   = div_d
		--}
		FROM cxpt022, cxpt023
		WHERE p22_compania   = r_p24.p24_compania
		  AND p22_localidad  = r_p24.p24_localidad
		  AND p22_orden_pago = r_p24.p24_orden_pago
		  AND p23_compania   = p22_compania
		  AND p23_localidad  = p22_localidad
		  AND p23_codprov    = p22_codprov
		  AND p23_tipo_trn   = p22_tipo_trn
		  AND p23_num_trn    = p22_num_trn
                GROUP BY p23_tipo_doc, p23_num_doc, p23_div_doc
LET orden = 1
FOREACH q_aj1 INTO tipo_doc, num_doc, div_doc, val_cap, val_int 
	LET val_cap = val_cap * (-1)
	LET val_int = val_int * (-1)
	LET r_p22.p22_total_cap = r_p22.p22_total_cap + val_cap
	LET r_p22.p22_total_int = r_p22.p22_total_int + val_int
	CALL fl_lee_documento_deudor_cxp(r_p24.p24_compania, 
					 r_p24.p24_localidad,
					 r_p24.p24_codprov,
					 tipo_doc, num_doc,
					 div_doc) RETURNING r_p20.*
	INITIALIZE r_p23.* TO NULL
	LET r_p23.p23_compania   = r_p22.p22_compania  
	LET r_p23.p23_localidad  = r_p22.p22_localidad     
	LET r_p23.p23_codprov    = r_p22.p22_codprov     
	LET r_p23.p23_tipo_trn   = r_p22.p22_tipo_trn    
	LET r_p23.p23_num_trn    = r_p22.p22_num_trn   
	LET r_p23.p23_orden      = orden
	LET orden = orden + 1  
	LET r_p23.p23_tipo_doc   = tipo_doc 
	LET r_p23.p23_num_doc    = num_doc
	LET r_p23.p23_div_doc    = div_doc
	LET r_p23.p23_valor_cap  = val_cap   
	LET r_p23.p23_valor_int  = val_int  
	LET r_p23.p23_valor_mora = 0 
	LET r_p23.p23_saldo_cap  = r_p20.p20_saldo_cap 
	LET r_p23.p23_saldo_int  = r_p20.p20_saldo_int
	INSERT INTO cxpt023 VALUES (r_p23.*)
	INITIALIZE r_doc.* TO NULL
	SET LOCK MODE TO WAIT 5
	WHENEVER ERROR CONTINUE
	DECLARE q_p20 CURSOR FOR
		SELECT * FROM cxpt020
			WHERE p20_compania  = r_p24.p24_compania
			  AND p20_localidad = r_p24.p24_localidad
			  AND p20_codprov   = r_p24.p24_codprov
			  AND p20_tipo_doc  = tipo_doc
			  AND p20_num_doc   = num_doc
			  AND p20_dividendo = div_doc
		FOR UPDATE
	OPEN q_p20
	FETCH q_p20 INTO r_doc.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		CALL fl_mostrar_mensaje('No se pudo actualizar los documentos.','exclamation')
		LET done = 0
		SET LOCK MODE TO NOT WAIT
		--DROP TABLE t1
		EXIT FOREACH
	END IF
	UPDATE cxpt020 SET p20_saldo_cap = p20_saldo_cap + val_cap,
			   p20_saldo_int = p20_saldo_int + val_int
		WHERE CURRENT OF q_p20
	CLOSE q_p20
	FREE  q_p20
	SET LOCK MODE TO NOT WAIT
END FOREACH
FREE q_aj1
UPDATE cxpt022 SET * = r_p22.* 
	WHERE p22_compania  = r_p22.p22_compania
	  AND p22_localidad = r_p22.p22_localidad
	  AND p22_codprov   = r_p22.p22_codprov
	  AND p22_tipo_trn  = r_p22.p22_tipo_trn
	  AND p22_num_trn   = r_p22.p22_num_trn
--DROP TABLE t1
RETURN done

END FUNCTION



FUNCTION proceso_elim_pago_anticipo(r_p24)
DEFINE r_p24		RECORD LIKE cxpt024.*
DEFINE done 		SMALLINT
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p21		RECORD LIKE cxpt021.*
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*

LET done = 0
SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
	DECLARE q_pa1 CURSOR FOR
		SELECT * FROM cxpt021
			WHERE p21_compania   = r_p24.p24_compania 
			  AND p21_localidad  = r_p24.p24_localidad
			  AND p21_orden_pago = r_p24.p24_orden_pago
		FOR UPDATE
	OPEN  q_pa1
	FETCH q_pa1 INTO r_p21.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	SET LOCK MODE TO NOT WAIT
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN done
END IF
IF STATUS = NOTFOUND THEN
	SET LOCK MODE TO NOT WAIT
	CALL fl_mostrar_mensaje('No se encontró el pago anticipado asociado a la orden de pago.','exclamation')
	RETURN done
END IF
SET LOCK MODE TO NOT WAIT
IF r_p21.p21_saldo <> r_p21.p21_valor THEN
	CALL fl_mostrar_mensaje('El pago anticipado ya fue aplicado.','exclamation')
	RETURN done
END IF
INITIALIZE r_p20.* TO NULL
LET r_p20.p20_compania    = r_p24.p24_compania     
LET r_p20.p20_localidad   = r_p24.p24_localidad
LET r_p20.p20_codprov     = r_p24.p24_codprov
LET r_p20.p20_tipo_doc    = vm_nota_debito
LET r_p20.p20_num_doc     = fl_actualiza_control_secuencias(r_p24.p24_compania,
							    r_p24.p24_localidad,
							    'TE', 'AA', 
							    vm_nota_debito)    
LET r_p20.p20_dividendo   = 1 
LET r_p20.p20_referencia  = 'ELIM. COMPROBANTE: ', rm_b12.b12_tipo_comp,
			    '-', rm_b12.b12_num_comp
LET r_p20.p20_fecha_emi   = TODAY
LET r_p20.p20_fecha_vcto  = TODAY
LET r_p20.p20_tasa_int    = 0   
LET r_p20.p20_tasa_mora   = 0  
LET r_p20.p20_moneda      = r_p24.p24_moneda 
LET r_p20.p20_paridad     = r_p24.p24_paridad
LET r_p20.p20_valor_cap   = r_p21.p21_valor
LET r_p20.p20_valor_int   = 0 
LET r_p20.p20_saldo_cap   = 0
LET r_p20.p20_saldo_int   = 0
LET r_p20.p20_valor_fact  = r_p21.p21_valor  
LET r_p20.p20_porc_impto  = 0 
LET r_p20.p20_valor_impto = 0
LET r_p20.p20_cartera     = 6
LET r_p20.p20_cod_depto   = 1  ## Se le agrega este LET se estaba cayendo al
                               ## insertar nulo en un campo not null (RCA)
LET r_p20.p20_origen      = 'A'
LET r_p20.p20_usuario     = vg_usuario
LET r_p20.p20_fecing      = CURRENT
INSERT INTO cxpt020 VALUES (r_p20.*)
INITIALIZE r_p22.* TO NULL
LET r_p22.p22_compania   = r_p24.p24_compania 
LET r_p22.p22_localidad  = r_p24.p24_localidad
LET r_p22.p22_codprov    = r_p24.p24_codprov
LET r_p22.p22_tipo_trn   = vm_ajuste    
LET r_p22.p22_num_trn    = fl_actualiza_control_secuencias(r_p24.p24_compania,
				r_p24.p24_localidad, 'TE', 'AA', vm_ajuste)
LET r_p22.p22_referencia = 'APLICACION NOTA DEBITO # ', r_p20.p20_num_doc
LET r_p22.p22_fecha_emi  = TODAY
LET r_p22.p22_moneda     = r_p24.p24_moneda 
LET r_p22.p22_paridad    = r_p24.p24_paridad
LET r_p22.p22_tasa_mora  = 0
LET r_p22.p22_total_cap  = r_p21.p21_valor * (-1) 
LET r_p22.p22_total_int  = 0  
LET r_p22.p22_total_mora = 0 
LET r_p22.p22_origen     = 'A' 
LET r_p22.p22_usuario    = vg_usuario    
LET r_p22.p22_fecing     = CURRENT
INSERT INTO cxpt022 VALUES(r_p22.*)
INITIALIZE r_p23.* TO NULL
LET r_p23.p23_compania   = r_p22.p22_compania  
LET r_p23.p23_localidad  = r_p22.p22_localidad     
LET r_p23.p23_codprov    = r_p22.p22_codprov     
LET r_p23.p23_tipo_trn   = r_p22.p22_tipo_trn    
LET r_p23.p23_num_trn    = r_p22.p22_num_trn   
LET r_p23.p23_orden      = 1
LET r_p23.p23_tipo_doc   = r_p20.p20_tipo_doc
LET r_p23.p23_num_doc    = r_p20.p20_num_doc
LET r_p23.p23_div_doc    = r_p20.p20_dividendo
LET r_p23.p23_tipo_favor = r_p21.p21_tipo_doc  
LET r_p23.p23_doc_favor  = r_p21.p21_num_doc
LET r_p23.p23_valor_cap  = r_p20.p20_valor_cap * (-1)   
LET r_p23.p23_valor_int  = 0  
LET r_p23.p23_valor_mora = 0 
LET r_p23.p23_saldo_cap  = r_p20.p20_valor_cap 
LET r_p23.p23_saldo_int  = 0
INSERT INTO cxpt023 VALUES (r_p23.*)
UPDATE cxpt021 SET p21_saldo = 0 WHERE CURRENT OF q_pa1
RETURN 1

END FUNCTION



FUNCTION cuenta_distribucion(codcia, cta_master)

DEFINE codcia		LIKE ctbt016.b16_compania
DEFINE cta_master	LIKE ctbt016.b16_cta_master
DEFINE num_ctas_detail	SMALLINT

SELECT COUNT(*) INTO num_ctas_detail FROM ctbt016
	WHERE b16_compania   = codcia
	  AND b16_cta_master = cta_master

RETURN num_ctas_detail

END FUNCTION



FUNCTION muestra_distribucion(codcia, cta_master, valor_tot)

DEFINE codcia		LIKE ctbt016.b16_compania
DEFINE cta_master	LIKE ctbt016.b16_cta_master
DEFINE valor_tot	LIKE ctbt013.b13_valor_base

DEFINE r_b10		RECORD LIKE ctbt010.*

DEFINE max_rows		SMALLINT
DEFINE i  		SMALLINT
DEFINE r_cd ARRAY[100] OF RECORD
	cta_detail	LIKE ctbt016.b16_cta_detail,
	nombre_cta	LIKE ctbt010.b10_descripcion,
	porcentaje 	LIKE ctbt016.b16_porcentaje,
	valor		LIKE ctbt013.b13_valor_base
END RECORD

LET max_rows = 100

OPEN WINDOW w_201_2 AT 7,7 WITH 12 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_201_2 FROM '../forms/ctbf201_2'
ELSE
	OPEN FORM f_201_2 FROM '../forms/ctbf201_2c'
END IF
DISPLAY FORM f_201_2

CLEAR FORM

--#DISPLAY 'Cuentas'     TO tit_col1
--#DISPLAY 'Descripción' TO tit_col2
--#DISPLAY '%'           TO tit_col3
--#DISPLAY 'Valor'       TO tit_col4

DECLARE q_cd1 CURSOR FOR
	SELECT b16_cta_detail, b10_descripcion, b16_porcentaje, 0
		FROM ctbt016, ctbt010
		WHERE b16_compania   = codcia
		  AND b16_cta_master = cta_master
		  AND b10_compania   = b16_compania
		  AND b10_cuenta     = b16_cta_detail

LET i = 1
FOREACH q_cd1 INTO r_cd[i].*
	LET r_cd[i].valor = valor_tot * (r_cd[i].porcentaje / 100)
	LET i = i + 1
	IF i > max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF

CALL fl_lee_cuenta(codcia, cta_master) RETURNING r_b10.*
DISPLAY cta_master TO b16_cta_master
DISPLAY r_b10.b10_descripcion TO tit_master 
DISPLAY BY NAME valor_tot

CALL set_count(i)
--LET int_flag = 0
DISPLAY ARRAY r_cd TO r_cd.*
	ON KEY(INTERRUPT)
		--LET int_flag = 1
		EXIT DISPLAY
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY

LET int_flag = 0
CLOSE WINDOW w_201_2
RETURN

END FUNCTION



FUNCTION distribuye_cuentas()

DEFINE i		SMALLINT
DEFINE r_b16		RECORD LIKE ctbt016.*
DEFINE num_ctas_detail	SMALLINT
DEFINE r_tmp RECORD 
	secuencia	SMALLINT,
	cuenta		CHAR(12),
	tipo_doc	CHAR(3),
	--glosa		VARCHAR(35),
	glosa		VARCHAR(90),
	valor_debito	DECIMAL(14,2),
	valor_credito	DECIMAL(14,2),
	b13_codcli	INTEGER,
	b13_codprov	INTEGER,
	b13_pedido	char(10)
END RECORD
DEFINE r_cta RECORD 
	secuencia	SMALLINT,
	cuenta		CHAR(12),
	tipo_doc	CHAR(3),
	--glosa		VARCHAR(35),
	glosa		VARCHAR(90),
	valor_debito	DECIMAL(14,2),
	valor_credito	DECIMAL(14,2),
	b13_codcli	INTEGER,
	b13_codprov	INTEGER,
	b13_pedido	char(10)
END RECORD

DECLARE q_cta_master CURSOR FOR
	SELECT * FROM tmp_detalle
		WHERE EXISTS (SELECT b16_cta_master FROM ctbt016
				WHERE b16_compania   = vg_codcia
				  AND b16_cta_master = cuenta)
	ORDER BY secuencia DESC

FOREACH q_cta_master INTO r_tmp.*
	LET num_ctas_detail = cuenta_distribucion(vg_codcia, r_tmp.cuenta)	
	UPDATE tmp_detalle SET secuencia = secuencia + (num_ctas_detail - 1)
		WHERE secuencia > r_tmp.secuencia
	DELETE FROM tmp_detalle WHERE secuencia = r_tmp.secuencia

	DECLARE q_cd2 CURSOR FOR
		SELECT * FROM ctbt016
			WHERE b16_compania   = vg_codcia
			  AND b16_cta_master = r_tmp.cuenta
	
	LET i = 0
	FOREACH q_cd2 INTO r_b16.*
		INITIALIZE r_cta.* TO NULL
		LET r_cta.secuencia = r_tmp.secuencia + i
		LET r_cta.cuenta    = r_b16.b16_cta_detail
		LET r_cta.tipo_doc  = r_tmp.tipo_doc
		LET r_cta.glosa     = r_tmp.glosa
		LET r_cta.valor_debito = 
			r_tmp.valor_debito * (r_b16.b16_porcentaje / 100)
		LET r_cta.valor_credito = 
			r_tmp.valor_credito * (r_b16.b16_porcentaje / 100)
		LET r_cta.b13_codcli	= r_tmp.b13_codcli
		LET r_cta.b13_codprov	= r_tmp.b13_codprov
		LET r_cta.b13_pedido	= r_tmp.b13_pedido
		INSERT INTO tmp_detalle VALUES (r_cta.*)	
		LET i = i + 1
	END FOREACH
	FREE q_cd2
END FOREACH

END FUNCTION



FUNCTION ver_orden_pago()

DEFINE r_p24		RECORD LIKE cxpt024.*
DEFINE comando		CHAR(500)
DEFINE run_prog		CHAR(10)

SELECT * INTO r_p24.* FROM cxpt024 
	WHERE p24_compania     = vg_codcia
	  AND p24_tip_contable = rm_b12.b12_tipo_comp
	  AND p24_num_contable = rm_b12.b12_num_comp

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'TESORERIA', vg_separador, 'fuentes', 
	      vg_separador, run_prog, 'cxpp204 ', vg_base, ' ',
	      'TE ', r_p24.p24_compania, ' ',r_p24.p24_localidad, ' ',
	      r_p24.p24_orden_pago

RUN comando

END FUNCTION



FUNCTION control_origen_comprobante()
DEFINE r		RECORD LIKE rept040.*
DEFINE rc		RECORD LIKE cxct040.*
DEFINE r_v50		RECORD LIKE veht050.*
DEFINE r_t28		RECORD LIKE talt028.*
DEFINE r_t50		RECORD LIKE talt050.*
DEFINE r_c40		RECORD LIKE ordt040.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_p24		RECORD LIKE cxpt024.*
DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE r_n53		RECORD LIKE rolt053.*
DEFINE r_z41		RECORD LIKE cxct041.*
DEFINE r_z23		RECORD LIKE cxct023.*
DEFINE rt		RECORD LIKE cxct004.*
DEFINE num_concil	LIKE ctbt013.b13_num_concil
DEFINE comando		CHAR(500)
DEFINE programa		CHAR(7)
DEFINE run_prog, prog	CHAR(10)
DEFINE para		CHAR(4)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
IF rm_b12.b12_modulo = 'VE' THEN
	INITIALIZE r_v50.* TO NULL
	DECLARE q_oriv CURSOR FOR
		SELECT * FROM veht050
			WHERE v50_compania  = rm_b12.b12_compania
			  AND v50_tipo_comp = rm_b12.b12_tipo_comp 	
			  AND v50_num_comp  = rm_b12.b12_num_comp
	OPEN q_oriv
	FETCH q_oriv INTO r_v50.*
	CLOSE q_oriv
	FREE  q_oriv
	IF r_v50.v50_compania IS NULL THEN
		RETURN
	END IF
	CALL fl_ver_transaccion_veh(vg_codcia, vg_codloc, r_v50.v50_cod_tran,
				    r_v50.v50_num_tran)
END IF
IF rm_b12.b12_modulo = 'CG' THEN
	INITIALIZE r_j10.* TO NULL
	DECLARE q_orie CURSOR FOR
		SELECT * FROM cajt010
			WHERE j10_compania     = rm_b12.b12_compania
			  AND j10_tip_contable = rm_b12.b12_tipo_comp 	
			  AND j10_num_contable = rm_b12.b12_num_comp
	OPEN q_orie
	FETCH q_orie INTO r_j10.*
	CLOSE q_orie
	FREE  q_orie
	IF r_j10.j10_compania IS NULL THEN
		RETURN
	END IF
	IF r_j10.j10_tipo_fuente = 'OI' THEN
		LET comando = 'cd ..' || vg_separador || '..', vg_separador ||
			      'CAJA' || vg_separador || 'fuentes' ||
			      vg_separador || run_prog || 'cajp206 ' ||
			      vg_base || ' CG ' || 
			      rm_b12.b12_compania || ' ' || 
			      r_j10.j10_localidad || ' ' ||
			      r_j10.j10_tipo_fuente || ' ' ||
		       	      r_j10.j10_num_fuente
			      RUN comando
	END IF
	IF r_j10.j10_tipo_fuente = 'EC' THEN
		LET comando = 'cd ..' || vg_separador || '..', vg_separador ||
			      'CAJA' || vg_separador || 'fuentes' ||
			      vg_separador || run_prog || 'cajp207 ' ||
			      vg_base || ' CG ' || 
			      rm_b12.b12_compania || ' ' || 
			      r_j10.j10_localidad || ' ' ||
			      r_j10.j10_tipo_fuente || ' ' ||
		       	      r_j10.j10_num_fuente
			      RUN comando
	END IF
END IF
IF rm_b12.b12_modulo = 'TA' THEN
	INITIALIZE r_t50.* TO NULL
	DECLARE q_orit CURSOR FOR
		SELECT * FROM talt050
			WHERE t50_compania  = rm_b12.b12_compania
			  AND t50_tipo_comp = rm_b12.b12_tipo_comp 	
			  AND t50_num_comp  = rm_b12.b12_num_comp
	OPEN q_orit
	FETCH q_orit INTO r_t50.*
	CLOSE q_orit
	FREE  q_orit
	IF r_t50.t50_compania IS NULL THEN
		RETURN
	END IF
	INITIALIZE r_t28.* TO NULL
	SELECT * INTO r_t28.*
		FROM talt028
		WHERE t28_compania  = r_t50.t50_compania
		  AND t28_localidad = r_t50.t50_localidad
		  AND t28_factura   = r_t50.t50_factura
	LET prog = 'talp308 '
	IF r_t28.t28_compania IS NOT NULL THEN
		IF rm_b12.b12_subtipo = 10 THEN
			LET prog              = 'talp211 '
			LET r_t50.t50_factura = r_t28.t28_num_dev
		END IF
	END IF
	LET comando = 'cd ..' || vg_separador || '..', vg_separador ||
		      'TALLER' || vg_separador || 'fuentes' || vg_separador ||
		      run_prog || prog || vg_base || ' TA ' || 
		      rm_b12.b12_compania || ' ' || 
		      r_t50.t50_localidad || ' ' ||
		      r_t50.t50_factura
		      RUN comando
END IF
IF rm_b12.b12_modulo = 'RE' THEN
	INITIALIZE r.* TO NULL
	DECLARE q_ori CURSOR FOR
		SELECT * FROM rept040 
			WHERE r40_compania  = rm_b12.b12_compania AND 
			      r40_tipo_comp = rm_b12.b12_tipo_comp AND  
			      r40_num_comp  = rm_b12.b12_num_comp
	OPEN q_ori
	FETCH q_ori INTO r.*
	CLOSE q_ori
	FREE  q_ori
	IF r.r40_compania IS NULL THEN
		RETURN
	END IF
	CALL fl_ver_transaccion_rep(vg_codcia, r.r40_localidad, r.r40_cod_tran, 
				    r.r40_num_tran)
END IF
IF rm_b12.b12_modulo = 'CO' THEN
	INITIALIZE rc.* TO NULL
	DECLARE q_oric CURSOR FOR
		SELECT * FROM cxct040 
			WHERE z40_compania  = rm_b12.b12_compania AND 
			      z40_tipo_comp = rm_b12.b12_tipo_comp AND  
			      z40_num_comp  = rm_b12.b12_num_comp
	OPEN  q_oric
	FETCH q_oric INTO rc.*
	CLOSE q_oric
	FREE  q_oric
	IF rc.z40_compania IS NULL THEN
		SELECT * INTO r_z41.* FROM cxct041 
			WHERE z41_compania  = rm_b12.b12_compania AND 
			      z41_tipo_comp = rm_b12.b12_tipo_comp AND  
			      z41_num_comp  = rm_b12.b12_num_comp
		IF status = NOTFOUND THEN
			RETURN
		END IF
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'COBRANZAS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'cxcp200 ', vg_base, ' ',
			      'CO ', r_z41.z41_compania, ' ',
			      r_z41.z41_localidad, ' ',
			      r_z41.z41_codcli, ' ', r_z41.z41_tipo_doc, ' ', 
			      r_z41.z41_num_doc, ' ', 
			      r_z41.z41_dividendo, ' ', rm_b12.b12_fec_proceso
        	RUN comando
		RETURN
	END IF
	CALL fl_lee_tipo_doc(rc.z40_tipo_doc)
		RETURNING rt.*
	IF rt.z04_tipo = 'F' THEN
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'COBRANZAS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'cxcp201 ', vg_base, ' ',
			      'CO ', rc.z40_compania, ' ',rc.z40_localidad, ' ',
			      rc.z40_codcli, ' ', rc.z40_tipo_doc, ' ', 
			      rc.z40_num_doc, ' ', rm_b12.b12_fec_proceso
	ELSE
		INITIALIZE r_z23.* TO NULL
		DECLARE q_z23 CURSOR FOR
			SELECT * FROM cxct023
				WHERE z23_compania   = rc.z40_compania
				  AND z23_localidad  = rc.z40_localidad
				  AND z23_codcli     = rc.z40_codcli
				  AND z23_tipo_trn   = rc.z40_tipo_doc
				  AND z23_num_trn    = rc.z40_num_doc
				  AND z23_tipo_favor IS NOT NULL
		OPEN q_z23
		FETCH q_z23 INTO r_z23.*
		CLOSE q_z23
		FREE q_z23
		LET prog = 'cxcp202 '
		IF r_z23.z23_compania IS NOT NULL THEN
			LET prog = 'cxcp203 '
		END IF
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'COBRANZAS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, prog CLIPPED, ' ',
			      vg_base, ' CO ', rc.z40_compania, ' ',
			      rc.z40_localidad, ' ', rc.z40_codcli, ' ',
			      rc.z40_tipo_doc, ' ', rc.z40_num_doc
	END IF
        RUN comando
END IF
IF rm_b12.b12_modulo = 'OC' THEN
	INITIALIZE r_c40.* TO NULL
	DECLARE q_orioc CURSOR FOR
		SELECT * FROM ordt040 
			WHERE c40_compania  = rm_b12.b12_compania AND 
			      c40_tipo_comp = rm_b12.b12_tipo_comp AND  
			      c40_num_comp  = rm_b12.b12_num_comp
	OPEN  q_orioc
	FETCH q_orioc INTO r_c40.*
	CLOSE q_orioc
	FREE  q_orioc
	IF r_c40.c40_compania IS NULL THEN
		RETURN
	END IF
	LET comando = 'cd ..', vg_separador, '..', vg_separador,
		      'COMPRAS', vg_separador, 'fuentes', 
		      vg_separador, run_prog, 'ordp202 ', vg_base, ' ',
		      'OC ', r_c40.c40_compania, ' ',r_c40.c40_localidad, ' ',
		      r_c40.c40_numero_oc, ' ', r_c40.c40_num_recep 
        RUN comando
END IF
IF rm_b12.b12_modulo = 'CB' THEN
	DECLARE q_caca CURSOR FOR
		SELECT UNIQUE (b13_num_concil) FROM ctbt013 
			WHERE b13_compania  = rm_b12.b12_compania AND 
			      b13_tipo_comp = rm_b12.b12_tipo_comp AND  
			      b13_num_comp  = rm_b12.b12_num_comp AND
			      b13_num_concil IS NOT NULL 
	OPEN  q_caca
	FETCH q_caca INTO num_concil
	CLOSE q_caca
	FREE  q_caca
	IF num_concil IS NULL THEN
		RETURN
	END IF
	LET comando = 'cd ..', vg_separador, '..', vg_separador,
		      'CONTABILIDAD', vg_separador, 'fuentes', 
		      vg_separador, run_prog, 'ctbp203 ', vg_base, ' ',
		      'CB ', vg_codcia, ' ', num_concil
        RUN comando
END IF
IF rm_b12.b12_modulo = 'TE' THEN
	SELECT * INTO r_p27.* FROM cxpt027
		WHERE p27_compania     = rm_b12.b12_compania  AND 
		      p27_tip_contable = rm_b12.b12_tipo_comp AND 
		      p27_num_contable = rm_b12.b12_num_comp
	IF STATUS <> NOTFOUND THEN
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'TESORERIA', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'cxpp304 ', vg_base, ' ',
			      'TE ', r_p27.p27_compania, ' ',
				r_p27.p27_localidad, ' ', r_p27.p27_codprov,
				' ', r_p27.p27_num_ret
	       	RUN comando
		RETURN
	END IF
	SELECT * INTO r_p24.* FROM cxpt024
		WHERE p24_compania     = rm_b12.b12_compania  AND 
		      p24_tip_contable = rm_b12.b12_tipo_comp AND 
		      p24_num_contable = rm_b12.b12_num_comp
	IF STATUS = NOTFOUND THEN
		RETURN
	END IF
	IF r_p24.p24_tipo = 'P' THEN
		LET programa = 'cxpp204'
	ELSE
		LET programa = 'cxpp205'
	END IF
	LET comando = 'cd ..', vg_separador, '..', vg_separador,
		      'TESORERIA', vg_separador, 'fuentes', 
		      vg_separador, run_prog, programa, ' ', vg_base, ' ',
		      'TE ', r_p24.p24_compania, ' ',r_p24.p24_localidad, ' ',
		      r_p24.p24_orden_pago 
       	RUN comando
END IF
IF rm_b12.b12_modulo = 'RO' THEN
	INITIALIZE r_n53.* TO NULL
	DECLARE q_orirol CURSOR FOR
		SELECT * FROM rolt053 
			WHERE n53_compania  = rm_b12.b12_compania AND 
			      n53_tipo_comp = rm_b12.b12_tipo_comp AND  
			      n53_num_comp  = rm_b12.b12_num_comp
	OPEN  q_orirol
	FETCH q_orirol INTO r_n53.*
	CLOSE q_orirol
	FREE  q_orirol
	IF r_n53.n53_compania IS NULL THEN
		RETURN
	END IF
	CASE r_n53.n53_cod_liqrol
		WHEN 'Q1'
			LET prog = 'rolp303 '
			LET para = ' N'
		WHEN 'Q2'
			LET prog = 'rolp303 '
			LET para = ' N'
		WHEN 'DT'
			LET prog = 'rolp207 '
			LET para = ' X'
		WHEN 'DC'
			LET prog = 'rolp221 '
			LET para = ' X'
		WHEN 'FR'
			LET prog = 'rolp210 '
			LET para = NULL
		WHEN 'UT'
			LET prog = 'rolp222 '
			LET para = ' 0 C'
	END CASE
	LET comando = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA',
			vg_separador, 'fuentes', vg_separador, run_prog,
			prog CLIPPED, ' ', vg_base, ' RO ', r_n53.n53_compania
	IF r_n53.n53_cod_liqrol <> 'UT' THEN
		LET comando = comando CLIPPED,
			' ', r_n53.n53_cod_liqrol, ' ', r_n53.n53_fecha_ini,
			' ', r_n53.n53_fecha_fin, para CLIPPED
	ELSE
		LET comando = comando CLIPPED, ' ', YEAR(r_n53.n53_fecha_fin),
				para CLIPPED
	END IF
        RUN comando
END IF

END FUNCTION



FUNCTION fecha_bloqueada(codcia, mes, ano)
DEFINE codcia 		LIKE ctbt006.b06_compania
DEFINE mes, ano		SMALLINT
DEFINE r_b06		RECORD LIKE ctbt006.*

INITIALIZE r_b06.* TO NULL 
SELECT * INTO r_b06.*
	FROM ctbt006
	WHERE b06_compania = codcia
	  AND b06_ano      = ano
	  AND b06_mes      = mes
IF r_b06.b06_mes IS NOT NULL THEN
	--CALL fgl_winmessage(vg_producto,'Mes contable está bloqueado.','exclamation')
	CALL fl_mostrar_mensaje('Mes contable está bloqueado.','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION control_impresion_comprobantes()
DEFINE cocoliso		CHAR(300)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
--IF rm_b12.b12_tipo_comp = vm_egreso THEN
	LET cocoliso = 'cd ..', vg_separador, '..', vg_separador,
	      	      'TESORERIA', vg_separador, 'fuentes', 
	               vg_separador, run_prog, 'cxpp403 ', vg_base, ' ',
	      	       'TE', vg_codcia, ' ', vg_codloc, ' ', 
			rm_b12.b12_tipo_comp,' ', rm_b12.b12_num_comp
	RUN cocoliso
--END IF

END FUNCTION



FUNCTION lee_otros_datos(i, modo)
DEFINE i		SMALLINT
DEFINE modo		SMALLINT
DEFINE r_z01        	RECORD LIKE cxct001.*
DEFINE r_p01        	RECORD LIKE cxpt001.*
DEFINE r_r16        	RECORD LIKE rept016.*
DEFINE r_otros		RECORD 
		b13_codcli	LIKE ctbt013.b13_codcli,
		b13_codprov	LIKE ctbt013.b13_codprov,
		b13_pedido	LIKE ctbt013.b13_pedido
	END RECORD
DEFINE codprov          LIKE cxpt001.p01_codprov
DEFINE nom_cli          LIKE cxct001.z01_nomcli
DEFINE nom_prov         LIKE cxpt001.p01_nomprov
DEFINE pedido           LIKE rept016.r16_pedido
DEFINE resp             CHAR(6)
DEFINE vm_flag_mant        CHAR(1)

OPEN WINDOW w_201_3 AT 7,7 WITH 07 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_201_3 FROM '../forms/ctbf201_3'
ELSE
	OPEN FORM f_201_3 FROM '../forms/ctbf201_3c'
END IF
DISPLAY FORM f_201_3

LET r_otros.* = rm_otros[i].*

      IF r_otros.b13_codprov IS NOT NULL THEN
            CALL fl_lee_proveedor(r_otros.b13_codprov)
                         RETURNING r_p01.*
	    LET nom_prov = r_p01.p01_nomprov 
            DISPLAY BY NAME r_otros.b13_codprov, nom_prov
      END IF
      IF r_otros.b13_codcli IS NOT NULL THEN
             CALL fl_lee_cliente_general(r_otros.b13_codcli)
                        RETURNING r_z01.*
	     LET nom_cli = r_z01.z01_nomcli
             DISPLAY BY NAME r_otros.b13_codcli, nom_cli
      END IF

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME r_otros.b13_codcli, r_otros.b13_codprov, r_otros.b13_pedido
		WITHOUT DEFAULTS

	ON KEY(INTERRUPT)
	IF FIELD_TOUCHED(b13_codcli, b13_codprov, b13_pedido) THEN
                 LET int_flag = 0
                 CALL fl_mensaje_abandonar_proceso()
                           RETURNING resp
                 IF resp = 'Yes' THEN
                     LET int_flag = 1
                     IF vm_flag_mant = 'I' THEN
                            CLEAR FORM
                      END IF
		      EXIT INPUT
                  END IF
         ELSE
                  IF vm_flag_mant = 'I' THEN
                        CLEAR FORM
                  END IF
		  EXIT INPUT
         END IF
       	 ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
         ON KEY(F2)
                IF INFIELD(b13_codcli) THEN
                        CALL fl_ayuda_cliente_general()
                                RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
                        IF r_z01.z01_codcli IS NOT NULL THEN
                                LET r_otros.b13_codcli = r_z01.z01_codcli
                                DISPLAY BY NAME r_otros.b13_codcli
                                DISPLAY r_z01.z01_nomcli TO nom_cli
                        END IF
                END IF
                IF INFIELD(b13_codprov) THEN
                       CALL fl_ayuda_proveedores_localidad(vg_codcia, vg_codloc)
                                        RETURNING codprov, nom_prov
                        IF codprov IS NOT NULL THEN
                                LET r_otros.b13_codprov = codprov
                                DISPLAY BY NAME r_otros.b13_codprov, nom_prov
                        END IF
                END IF
                IF INFIELD(b13_pedido) THEN
                        CALL fl_ayuda_pedidos_rep(vg_codcia, vg_codloc, 'T',
                                'T') RETURNING pedido
                        IF pedido IS NOT NULL THEN
                                LET r_otros.b13_pedido = pedido
                                DISPLAY BY NAME r_otros.b13_pedido
                        END IF
                END IF
		LET int_flag = 0	
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
        AFTER FIELD b13_codcli
		IF modo = 0 THEN
                	LET r_otros.b13_codcli = rm_otros[i].b13_codcli 
			DISPLAY BY NAME	r_otros.b13_codcli
		END IF
                IF r_otros.b13_codcli IS NOT NULL THEN
                        CALL fl_lee_cliente_general(r_otros.b13_codcli)
                                RETURNING r_z01.*
                        IF r_z01.z01_codcli IS NULL THEN
                               --CALL fgl_winmessage(vg_producto,'El cliente no existe en la Compañía.','exclamation')
			CALL fl_mostrar_mensaje('El cliente no existe en la Compañía.','exclamation')
                        CLEAR nom_cli
                                NEXT FIELD b13_codcli
                        END IF
                        DISPLAY r_z01.z01_nomcli TO nom_cli
                ELSE
                        CLEAR nom_cli
                END IF
	AFTER FIELD b13_codprov
		IF modo = 0 THEN
                	LET r_otros.b13_codprov = rm_otros[i].b13_codprov 
			DISPLAY BY NAME	r_otros.b13_codprov
		END IF
		IF r_otros.b13_codprov IS NOT NULL THEN
                        CALL fl_lee_proveedor(r_otros.b13_codprov) 
						RETURNING r_p01.*
                        IF r_p01.p01_codprov IS NULL THEN
                                --CALL fgl_winmessage(vg_producto,'Proveedor no existe.', 'exclamation')
				CALL fl_mostrar_mensaje('Proveedor no existe.', 'exclamation')
				CLEAR nom_prov
                                NEXT FIELD b13_codprov
                        END IF
                        DISPLAY r_p01.p01_nomprov TO nom_prov
		ELSE
			CLEAR nom_prov
		END IF
	AFTER FIELD b13_pedido
		IF modo = 0 THEN
                	LET r_otros.b13_pedido = rm_otros[i].b13_pedido 
			DISPLAY BY NAME	r_otros.b13_pedido
		END IF
		IF r_otros.b13_pedido IS NOT NULL THEN
               	 	CALL fl_lee_pedido_rep(vg_codcia, vg_codloc,
                        		r_otros.b13_pedido) RETURNING r_r16.*
                	IF r_r16.r16_pedido IS NULL THEN
                        	--CALL fgl_winmessage(vg_producto,'El pedido no existe.','exclamation')
				CALL fl_mostrar_mensaje('El pedido no existe.','exclamation')
                        	NEXT FIELD b13_pedido
                	END IF
                END IF
	AFTER INPUT
		LET rm_otros[i].* = r_otros.*
		IF r_otros.b13_codcli  IS NOT NULL AND 
		   r_otros.b13_codprov IS NOT NULL AND
	           r_otros.b13_pedido  IS NOT  NULL THEN
        		--CALL fgl_winmessage(vg_producto,'Sólo puede enlazar el diario contable a uno de estos filtros.', 'exclamation')
			CALL fl_mostrar_mensaje('Sólo puede enlazar el diario contable a uno de estos filtros.', 'exclamation')
                        NEXT FIELD b13_codprov
		END IF
		IF r_otros.b13_codcli  IS NOT NULL AND
	       	   r_otros.b13_pedido  IS NOT  NULL THEN
	  	     	--CALL fgl_winmessage(vg_producto,'Sólo puede enlazar el diario contable a uno de estos filtros.', 'exclamation')
			CALL fl_mostrar_mensaje('Sólo puede enlazar el diario contable a uno de estos filtros.', 'exclamation')
                       	NEXT FIELD b13_pedido
		END IF	
		IF r_otros.b13_codcli  IS NOT NULL AND
	       	   r_otros.b13_codprov IS NOT  NULL THEN
	  	     	--CALL fgl_winmessage(vg_producto,'Sólo puede enlazar el diario contable a uno de estos filtros.', 'exclamation')
			CALL fl_mostrar_mensaje('Sólo puede enlazar el diario contable a uno de estos filtros.', 'exclamation')
                       	NEXT FIELD b13_codprov
		END IF	
		IF r_otros.b13_codprov IS NOT NULL AND
	       	   r_otros.b13_pedido  IS NOT  NULL THEN
	  	     	--CALL fgl_winmessage(vg_producto,'Sólo puede enlazar el diario contable a uno de estos filtros.', 'exclamation')
			CALL fl_mostrar_mensaje('Sólo puede enlazar el diario contable a uno de estos filtros.', 'exclamation')
                       	NEXT FIELD b13_pedido
		END IF	
		
END INPUT

LET int_flag = 0
CLOSE WINDOW w_201_3
RETURN

END FUNCTION



FUNCTION sincroniza_arrreglo_otros(i, num_ele)
DEFINE i, k, num_ele	SMALLINT

FOR k = i + 1 TO num_ele
	LET rm_otros[k - 1].* = rm_otros[k].*
END FOR

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION mayoriza_cta_balance_sin_cierre(tip_comp, num_comp, flag_m)
DEFINE tip_comp		LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE flag_m		CHAR(1)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE query		CHAR(1500)
DEFINE signo		CHAR(1)

CALL fl_lee_comprobante_contable(vg_codcia, tip_comp, num_comp)
	RETURNING r_b12.*
IF YEAR(r_b12.b12_fec_proceso) < 2011 THEN
	RETURN
END IF
LET query = 'SELECT b13_cuenta cta, (YEAR(b13_fec_proceso) + 1) anio, ',
			'CASE WHEN b13_valor_base >= 0 ',
				'THEN b13_valor_base ',
				'ELSE 0.00 ',
			'END val_db, ',
			'CASE WHEN b13_valor_base < 0 ',
				'THEN b13_valor_base * (-1) ',
				'ELSE 0.00 ',
			'END val_cr ',
		' FROM ctbt013 ',
		' WHERE b13_compania      = ', r_b12.b12_compania,
		'   AND b13_tipo_comp     = "', r_b12.b12_tipo_comp, '"',
		'   AND b13_num_comp      = "', r_b12.b12_num_comp, '"',
		'   AND b13_cuenta[1, 1] IN ("1", "2", "3") ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
CASE flag_m
	WHEN 'M' LET signo = '+'
	WHEN 'D' LET signo = '-'
END CASE
LET query = 'UPDATE t_bal_gen ',
		' SET b11_db_ano_ant = b11_db_ano_ant ', signo,
				' NVL((SELECT val_db ',
					'FROM t1 ',
					'WHERE cta  = b11_cuenta ',
					'  AND anio = b11_ano), 0.00), ',
		'     b11_cr_ano_ant = b11_cr_ano_ant ', signo,
				' NVL((SELECT val_cr ',
					'FROM t1 ',
					'WHERE cta  = b11_cuenta ',
					'  AND anio = b11_ano), 0.00) ',
	' WHERE b11_compania  = ', r_b12.b12_compania,
	'   AND EXISTS ',
		'(SELECT 1 FROM t1 ',
			'WHERE cta  = b11_cuenta ',
			'  AND anio = b11_ano) '
BEGIN WORK
	WHENEVER ERROR CONTINUE
	SET LOCK MODE TO WAIT 20
	PREPARE exec_bal_gen FROM query
	EXECUTE exec_bal_gen
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Error al actualizar tabla temporal de saldos de balance. Por Favor Llame al Administrador. ', 'exclamation')
		RETURN
	END IF
	WHENEVER ERROR STOP
COMMIT WORK
DROP TABLE t1

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Otros Datos'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Origen de Comprobante'    AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Otros Datos'              AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Imprimir Comprobante'     AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
