------------------------------------------------------------------------------
-- Titulo           : talp211.4gl - Anulación de Facturas
-- Elaboracion      : 12-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp211 base módulo compañía localidad [num_dev]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_ord		RECORD LIKE talt023.*
DEFINE rm_tal		RECORD LIKE talt028.*
DEFINE vm_nue_orden	LIKE talt023.t23_orden
DEFINE vm_num_rows      SMALLINT
DEFINE vm_row_current   SMALLINT
DEFINE vm_max_rows      SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp211.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'talp211'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_mas AT 3,2 WITH 20 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_tal FROM "../forms/talf211_1"
DISPLAY FORM f_tal
INITIALIZE rm_ord.*, rm_tal.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Orden Devuelta'
		HIDE OPTION 'Imprimir'
		IF num_args() = 5 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
                	CALL control_consulta()
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresa una devolución. '
                CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Orden Devuelta'
		   IF fl_control_permiso_opcion('Imprimir') THEN
		        SHOW OPTION 'Imprimir'
		   END IF
			
		END IF
		IF vm_num_rows > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
		   IF fl_control_permiso_opcion('Imprimir') THEN
		        SHOW OPTION 'Imprimir'
		   END IF
			
			SHOW OPTION 'Orden Devuelta'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
				HIDE OPTION 'Orden Devuelta'
				HIDE OPTION 'Imprimir'
                        END IF
                ELSE
		   IF fl_control_permiso_opcion('Imprimir') THEN
		        SHOW OPTION 'Imprimir'
		   END IF
			
                        SHOW OPTION 'Avanzar'
			SHOW OPTION 'Orden Devuelta'		
                END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	 COMMAND KEY('O') 'Orden Devuelta' 'Muestra la orden actual. '
		CALL ver_orden()
	 COMMAND KEY('P') 'Imprimir' 'Imprime la devolucion actual. '
		CALL imprimir()
	 COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
                CALL muestra_siguiente_registro()
                IF vm_row_current = vm_num_rows THEN
                        HIDE OPTION 'Avanzar'
                        SHOW OPTION 'Retroceder'
                        NEXT OPTION 'Retroceder'
                ELSE
                        SHOW OPTION 'Avanzar'
                        SHOW OPTION 'Retroceder'
                END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
                CALL muestra_anterior_registro()
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



FUNCTION control_ingreso()
DEFINE r		RECORD LIKE talt024.*

CALL fl_retorna_usuario()
INITIALIZE rm_ord.*, rm_tal.*, vm_nue_orden TO NULL
CLEAR FORM
CALL leer_factura()
IF NOT int_flag THEN
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_up CURSOR FOR SELECT * FROM talt023
		WHERE t23_compania  = vg_codcia
		  AND t23_localidad = vg_codloc
		  AND t23_orden	    = rm_ord.t23_orden
		FOR UPDATE
	OPEN q_up
	FETCH q_up INTO rm_ord.*
	IF STATUS < 0 THEN
		COMMIT WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	LET rm_tal.t28_compania    = rm_ord.t23_compania
	LET rm_tal.t28_localidad   = rm_ord.t23_localidad
	LET rm_tal.t28_factura     = rm_ord.t23_num_factura
	LET rm_tal.t28_fec_anula   = CURRENT
	LET rm_tal.t28_fec_factura = rm_ord.t23_fec_factura
	LET rm_tal.t28_ot_ant      = rm_ord.t23_orden
	LET rm_tal.t28_usuario     = vg_usuario
	LET rm_tal.t28_fecing      = CURRENT
	CALL leer_orden()
	IF NOT int_flag THEN
		CALL fl_actualiza_control_secuencias(vg_codcia,vg_codloc,
							vg_modulo,'AA','DF')
			RETURNING rm_tal.t28_num_dev
		IF rm_tal.t28_num_dev <= 0 THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
		LET rm_ord.t23_estado = 'D'
		UPDATE talt023 SET t23_estado = rm_ord.t23_estado
			WHERE CURRENT OF q_up
		CALL muestra_estado()
		LET rm_ord.t23_estado      = 'A'
		LET rm_ord.t23_fec_cierre  = NULL
		LET rm_ord.t23_num_factura = NULL
		LET rm_ord.t23_fec_factura = NULL
		LET rm_ord.t23_orden       = vm_nue_orden
		LET rm_ord.t23_fecing      = CURRENT
		LET rm_ord.t23_usuario     = vg_usuario
		LET rm_tal.t28_ot_nue      = vm_nue_orden
		INSERT INTO talt023 VALUES(rm_ord.*)
		INSERT INTO talt028 VALUES(rm_tal.*)
		DECLARE q_mano CURSOR FOR SELECT * FROM talt024
			WHERE t24_compania  = vg_codcia AND 
			      t24_localidad = vg_codloc AND 
			      t24_orden     = rm_tal.t28_ot_ant
		FOREACH q_mano INTO r.*
			LET r.t24_orden   = rm_tal.t28_ot_nue
			LET r.t24_fecing  = CURRENT
			LET r.t24_usuario = vg_usuario
			INSERT INTO talt024 VALUES (r.*)
		END FOREACH
		CALL crea_nota_credito()
		CALL fl_actualiza_estadisticas_taller(vg_codcia, vg_codloc, rm_tal.t28_ot_ant, 'R')  
		CALL fl_actualiza_estadisticas_mecanicos(vg_codcia, vg_codloc, rm_tal.t28_ot_ant, 'R')  
		UPDATE rept019 SET r19_ord_trabajo = vm_nue_orden
			WHERE r19_compania    = vg_codcia AND 
			      r19_localidad   = vg_codloc AND 
			      r19_ord_trabajo = rm_tal.t28_ot_ant
		UPDATE ordt010 SET c10_ord_trabajo = rm_tal.t28_ot_nue
			WHERE c10_compania    = vg_codcia AND 
			      c10_localidad   = vg_codloc AND 
			      c10_ord_trabajo = rm_tal.t28_ot_ant
		COMMIT WORK
		CALL fl_control_master_contab_taller(vg_codcia, vg_codloc, 
			rm_tal.t28_ot_ant, 'D')
		CALL fgl_winmessage(vg_producto,'Factura ha sido anulada.','info')
	ELSE
		COMMIT WORK
        END IF
END IF
IF int_flag THEN
	CLEAR FORM
        IF vm_row_current > 0 THEN
                CALL mostrar_registro(vm_r_rows[vm_row_current])
        END IF
END IF
WHENEVER ERROR STOP

END FUNCTION



FUNCTION control_consulta()
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER
DEFINE ot_nue		LIKE talt028.t28_ot_nue
DEFINE codf_aux		LIKE talt023.t23_num_factura
DEFINE codo_aux		LIKE talt023.t23_orden
DEFINE nom_aux		LIKE talt023.t23_nom_cliente

CLEAR FORM
INITIALIZE codf_aux, codo_aux TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON t28_num_dev, t23_num_factura, t23_orden
		ON KEY(F2)
		IF infield(t23_num_factura) THEN
			CALL fl_ayuda_facturas_tal(vg_codcia,vg_codloc,'D')
				RETURNING codf_aux, nom_aux
			LET int_flag = 0
			IF codf_aux IS NOT NULL THEN
				DISPLAY codf_aux TO t23_num_factura
				DISPLAY nom_aux TO t23_nom_cliente
			END IF
		END IF
		IF infield(t23_orden) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia,vg_codloc,'D')
				RETURNING codo_aux, nom_aux
			LET int_flag = 0
			IF codo_aux IS NOT NULL THEN
				DISPLAY codo_aux TO t23_orden
				DISPLAY nom_aux TO t23_nom_cliente
			END IF
		END IF
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 't28_num_dev = ', arg_val(5)
END IF
LET query = 'SELECT talt023.*, talt023.ROWID ' ||
		' FROM talt023, talt028 ' ||
		' WHERE t23_compania  = ' || vg_codcia ||
		'   AND t23_localidad = ' || vg_codloc ||
		'   AND ' || expr_sql ||
		'   AND t23_estado    = "D" ' ||
		'   AND t28_compania  = t23_compania ' ||
		'   AND t28_localidad = t23_localidad ' ||
		'   AND t28_factura   = t23_num_factura'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_ord.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION leer_factura()
DEFINE resp		CHAR(6)
DEFINE r_fac		RECORD LIKE talt023.*
DEFINE r_lin		RECORD LIKE talt004.*
DEFINE r_ltl		RECORD LIKE talt001.*
DEFINE r_cia		RECORD LIKE talt000.*
DEFINE codf_aux		LIKE talt023.t23_num_factura
DEFINE nom_aux		LIKE talt023.t23_nom_cliente

OPTIONS INPUT NO WRAP
INITIALIZE codf_aux TO NULL
LET int_flag = 0
INPUT BY NAME rm_ord.t23_num_factura
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_ord.t23_num_factura) THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
                	END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
		IF infield(t23_num_factura) THEN
			CALL fl_ayuda_facturas_tal(vg_codcia,vg_codloc,'F')
				RETURNING codf_aux, nom_aux
			LET int_flag = 0
			IF codf_aux IS NOT NULL THEN
				LET rm_ord.t23_num_factura = codf_aux
				DISPLAY BY NAME rm_ord.t23_num_factura
				DISPLAY nom_aux TO t23_nom_cliente
			END IF
			OPTIONS INPUT NO WRAP
		END IF
	AFTER FIELD t23_num_factura
		IF rm_ord.t23_num_factura IS NOT NULL THEN
			CALL fl_lee_factura_taller(vg_codcia,vg_codloc,
						rm_ord.t23_num_factura)
				RETURNING r_fac.*
			IF r_fac.t23_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'La factura no existe.','exclamation')
				NEXT FIELD t23_num_factura
			END IF
			LET rm_ord.* = r_fac.*
			DISPLAY BY NAME	rm_ord.t23_nom_cliente,
					rm_ord.t23_fec_factura,
					rm_ord.t23_orden,
					rm_ord.t23_modelo,
					rm_ord.t23_chasis, rm_ord.t23_color
			CALL fl_lee_tipo_vehiculo(vg_codcia,rm_ord.t23_modelo)
				RETURNING r_lin.*
			CALL fl_lee_linea_taller(vg_codcia, r_lin.t04_linea)
				RETURNING r_ltl.*
			DISPLAY r_lin.t04_linea TO tit_linea
			DISPLAY r_ltl.t01_nombre TO tit_linea_des
			CALL muestra_estado()
			IF r_fac.t23_estado <> 'F' THEN
				CALL fgl_winmessage(vg_producto,'Factura no puede ser devuelta.','exclamation')
				NEXT FIELD t23_num_factura
			END IF
			CALL fl_lee_configuracion_taller(vg_codcia)
				RETURNING r_cia.*
			IF TODAY > date(r_fac.t23_fec_factura)
			+ r_cia.t00_dias_dev THEN
                        	CALL fgl_winmessage(vg_producto,'Factura ha excedido el límite de tiempo permitido para realizar devoluciones.','exclamation')
                        	INITIALIZE r_fac.* TO NULL
	                        NEXT FIELD t23_num_factura
        	        END IF
	                IF r_cia.t00_dev_mes = 'S' THEN
        	                IF month(r_fac.t23_fec_factura) <> month(TODAY)
				THEN
                        	        CALL fgl_winmessage(vg_producto,'Devolución debe realizarse en el mismo mes en que se realizó la venta.','exclamation')
            	         		INITIALIZE r_fac.* TO NULL
                	                NEXT FIELD t23_num_factura
                        	END IF
                	END IF
		ELSE
			CLEAR FORM
			NEXT FIELD t23_num_factura
		END IF
END INPUT

END FUNCTION



FUNCTION leer_orden()
DEFINE resp		CHAR(6)
DEFINE r_ord		RECORD LIKE talt023.*

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_tal.t28_motivo_dev, vm_nue_orden
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(vm_nue_orden) THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
                	END IF
		ELSE
			RETURN
		END IF
	AFTER FIELD vm_nue_orden
		IF vm_nue_orden IS NOT NULL THEN
			CALL fl_lee_orden_trabajo(vg_codcia,vg_codloc,
						vm_nue_orden)
				RETURNING r_ord.*
			IF r_ord.t23_compania IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto,'Orden ya existe.','exclamation')
				NEXT FIELD vm_nue_orden
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_siguiente_registro()
                                                                                
IF vm_row_current < vm_num_rows THEN
        LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
                                                                                
END FUNCTION



FUNCTION muestra_anterior_registro()
                                                                                
IF vm_row_current > 1 THEN
        LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
                                                                                
END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current      SMALLINT
DEFINE num_rows         SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_reg)
DEFINE num_reg		INTEGER
DEFINE r_lin		RECORD LIKE talt004.*
DEFINE r_ltl		RECORD LIKE talt001.*

IF vm_num_rows > 0 THEN
        SELECT talt023.*, talt028.* INTO rm_ord.*, rm_tal.*
		FROM talt023, talt028
		WHERE talt023.ROWID     = num_reg
		    AND t23_compania    = t28_compania 
		    AND t23_localidad   = t28_localidad
		    AND t23_num_factura = t28_factura
        IF STATUS = NOTFOUND THEN
        	CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
                RETURN
        END IF	
	DISPLAY BY NAME rm_tal.t28_num_dev, rm_tal.t28_fec_anula,
			rm_ord.t23_num_factura, rm_ord.t23_nom_cliente,
			rm_ord.t23_fec_factura, rm_ord.t23_orden,
			rm_ord.t23_modelo, rm_ord.t23_chasis, rm_ord.t23_color,
                        rm_tal.t28_motivo_dev
	CALL fl_lee_tipo_vehiculo(vg_codcia, rm_ord.t23_modelo)
		RETURNING r_lin.*
	DISPLAY r_lin.t04_linea TO tit_linea
	CALL fl_lee_linea_taller(vg_codcia, r_lin.t04_linea) RETURNING r_ltl.*
	DISPLAY r_ltl.t01_nombre TO tit_linea_des
	DISPLAY rm_tal.t28_ot_nue TO vm_nue_orden
	CALL muestra_estado()
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION muestra_estado()
                                                                                
IF rm_ord.t23_estado = 'A' THEN
        DISPLAY 'ACTIVA' TO tit_estado_tal
END IF
IF rm_ord.t23_estado = 'C' THEN
        DISPLAY 'CERRADA' TO tit_estado_tal
END IF
IF rm_ord.t23_estado = 'F' THEN
        DISPLAY 'FACTURADA' TO tit_estado_tal
END IF
IF rm_ord.t23_estado = 'E' THEN
        DISPLAY 'ELIMINADA' TO tit_estado_tal
END IF
IF rm_ord.t23_estado = 'D' THEN
        DISPLAY 'DEVUELTA' TO tit_estado_tal
END IF
DISPLAY BY NAME rm_ord.t23_estado
                                                                                
END FUNCTION



FUNCTION ver_orden()

DEFINE nuevoprog     VARCHAR(400)

IF rm_ord.t23_orden IS NULL THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, '; fglrun talp204 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_ord.t23_orden,
	' ', 'O'
RUN nuevoprog

END FUNCTION



FUNCTION imprimir()

DEFINE nuevoprog     VARCHAR(400)

IF rm_tal.t28_num_dev IS NULL THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, '; fglrun talp402 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_tal.t28_num_dev

RUN nuevoprog

END FUNCTION



FUNCTION crea_nota_credito()
DEFINE r_nc		RECORD LIKE cxct021.*
DEFINE r		RECORD LIKE gent014.*
DEFINE r_ccred		RECORD LIKE talt025.*
DEFINE num_nc		INTEGER
DEFINE num_row		INTEGER
DEFINE valor_credito	DECIMAL(14,2)	
DEFINE valor_aplicado	DECIMAL(14,2)	
DEFINE r_mol            RECORD LIKE talt004.*
DEFINE r_lin            RECORD LIKE talt001.*
DEFINE r_grp            RECORD LIKE gent020.*

CALL fl_lee_tipo_vehiculo(vg_codcia,rm_ord.t23_modelo) RETURNING r_mol.*
CALL fl_lee_linea_taller(vg_codcia,r_mol.t04_linea) RETURNING r_lin.*
CALL fl_lee_grupo_linea(vg_codcia,r_lin.t01_grupo_linea) RETURNING r_grp.*
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'CO', 'AA', 'NC')
	RETURNING num_nc
IF num_nc <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
INITIALIZE r_nc.* TO NULL
LET r_nc.z21_compania 	= vg_codcia
LET r_nc.z21_localidad 	= vg_codloc
LET r_nc.z21_codcli 	= rm_ord.t23_cod_cliente
LET r_nc.z21_tipo_doc 	= 'NC'
LET r_nc.z21_num_doc 	= num_nc 
LET r_nc.z21_areaneg 	= r_grp.g20_areaneg
LET r_nc.z21_linea 	= r_grp.g20_grupo_linea
LET r_nc.z21_referencia = 'DEV. FACTURA: ', rm_tal.t28_factura  
LET r_nc.z21_fecha_emi 	= TODAY
LET r_nc.z21_moneda 	= rm_ord.t23_moneda
LET r_nc.z21_paridad 	= 1
IF r_nc.z21_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(r_nc.z21_moneda, rg_gen.g00_moneda_base)
		RETURNING r.*
	IF r.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto, 'No hay factor de conversión','stop')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_nc.z21_paridad 	= r.g14_tasa
END IF	
LET valor_credito = rm_ord.t23_tot_neto
INITIALIZE r_ccred.* TO NULL
IF rm_ord.t23_cont_cred = 'R' THEN
	SELECT * INTO r_ccred.* FROM talt025
		WHERE t25_compania  = vg_codcia AND 
	              t25_localidad = vg_codloc AND 
	              t25_orden     = rm_tal.t28_ot_ant
        IF STATUS <> NOTFOUND THEN
	        SELECT SUM(t26_valor_cap + t26_valor_int) INTO valor_credito
		        FROM talt026
	        WHERE t26_compania  = vg_codcia AND 
	              t26_localidad = vg_codloc AND 
	              t26_orden     = rm_tal.t28_ot_ant
	        IF valor_credito = 0 OR valor_credito IS NULL THEN
		        CALL fgl_winmessage(vg_producto, 'Valor del crédito 0 en talt026','stop')
		        ROLLBACK WORK
		        EXIT PROGRAM
	        END IF
        END IF
END IF
LET r_nc.z21_valor 	= valor_credito
LET r_nc.z21_saldo 	= valor_credito
LET r_nc.z21_subtipo 	= 1
LET r_nc.z21_origen 	= 'A'
LET r_nc.z21_usuario 	= vg_usuario
LET r_nc.z21_fecing 	= CURRENT
INSERT INTO cxct021 VALUES (r_nc.*)
LET num_row = SQLCA.SQLERRD[6]
CALL fl_aplica_documento_favor(vg_codcia, vg_codloc, r_nc.z21_codcli, 
			    r_nc.z21_tipo_doc, r_nc.z21_num_doc, valor_credito,
			    r_nc.z21_moneda, r_nc.z21_areaneg,
			    'FA', rm_tal.t28_factura)
	RETURNING valor_aplicado
UPDATE cxct021 SET z21_saldo = z21_saldo - valor_aplicado
	WHERE ROWID = num_row
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_nc.z21_codcli)

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
