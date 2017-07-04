--------------------------------------------------------------------------------
-- Titulo           : talp211.4gl - Anulación Facturas de Orden de Trabajo
-- Elaboracion      : 12-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp211 base módulo compañía localidad
--			[num_dev]
--			[num_fact] [A]
--			[num_dev] [F]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     CHAR(400)
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t28		RECORD LIKE talt028.*
DEFINE vm_nue_orden	LIKE talt023.t23_orden
DEFINE vm_num_rows      SMALLINT
DEFINE vm_row_current   SMALLINT
DEFINE vm_max_rows      SMALLINT
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE rm_c10		RECORD LIKE ordt010.*
DEFINE rm_c13		RECORD LIKE ordt013.*
DEFINE r_detalle	ARRAY[250] OF RECORD
				c14_cantidad	LIKE ordt014.c14_cantidad,
				c14_codigo	LIKE ordt014.c14_codigo,
				c14_descrip	LIKE ordt014.c14_descrip,
				c14_descuento	LIKE ordt014.c14_descuento,
				c14_precio	LIKE ordt014.c14_precio
			END RECORD
DEFINE r_oc		ARRAY[300] OF RECORD
				estado		LIKE ordt010.c10_estado,
				numero_oc	LIKE ordt010.c10_numero_oc,
				fecha		DATE,
				descripcion	LIKE ordt010.c10_referencia,
				total		LIKE ordt010.c10_tot_compra,
				marcar_ot	CHAR(1)
			END RECORD
DEFINE vm_ind_arr	SMALLINT
DEFINE vm_max_detalle	SMALLINT
DEFINE vm_act_cli	SMALLINT
DEFINE num_row_oc	SMALLINT
DEFINE max_row_oc	SMALLINT
DEFINE vm_nota_credito  LIKE cxct021.z21_tipo_doc
DEFINE vm_cliente_nc	LIKE cxct021.z21_codcli
DEFINE vm_fact_nue	LIKE ordt013.c13_factura
DEFINE vm_elim_ot	CHAR(6)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp211.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'talp211'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
IF num_args() = 4 OR (num_args() = 6 AND arg_val(6) = 'A') THEN
	CALL fl_chequeo_mes_proceso_tal(vg_codcia) RETURNING int_flag
	IF int_flag THEN
		RETURN
	END IF
END IF
LET vm_max_rows    = 1000
LET max_row_oc     = 300
LET vm_num_rows    = 0
LET vm_row_current = 0
IF num_args() = 6 AND arg_val(6) = 'A' THEN
	CALL ejecutar_devolucion_anulacion_automatica()
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 18
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_tal FROM "../forms/talf211_1"
ELSE
	OPEN FORM f_tal FROM "../forms/talf211_1c"
END IF
DISPLAY FORM f_tal
INITIALIZE rm_t23.*, rm_t28.* TO NULL
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Orden Devuelta'
		HIDE OPTION 'Orden Nueva'
		HIDE OPTION 'Factura'
		HIDE OPTION 'Imprimir'
		IF num_args() <> 4 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Orden Devuelta'
			SHOW OPTION 'Orden Nueva'
			SHOW OPTION 'Factura'
			IF num_args() = 6 AND arg_val(6) = 'F' THEN
				HIDE OPTION 'Factura'
			END IF
			SHOW OPTION 'Imprimir'
                	CALL control_consulta()
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresa una devolución. '
                CALL control_ingreso()
                IF vm_num_rows > 0 THEN
			SHOW OPTION 'Orden Devuelta'
			SHOW OPTION 'Orden Nueva'
			SHOW OPTION 'Factura'
			SHOW OPTION 'Imprimir'
		END IF
                IF vm_row_current > 1 THEN                                      
                        SHOW OPTION 'Retroceder'                              
                END IF                                                          
                IF vm_row_current = vm_num_rows THEN                            
                        HIDE OPTION 'Avanzar'                                   
                END IF                                                          
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Orden Devuelta'
			SHOW OPTION 'Orden Nueva'
			SHOW OPTION 'Factura'
			SHOW OPTION 'Imprimir'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
				HIDE OPTION 'Orden Devuelta'
				HIDE OPTION 'Orden Nueva'
				HIDE OPTION 'Factura'
				HIDE OPTION 'Imprimir'
                        END IF
                ELSE
                        SHOW OPTION 'Avanzar'
			SHOW OPTION 'Orden Devuelta'
			SHOW OPTION 'Orden Nueva'
			SHOW OPTION 'Factura'
			SHOW OPTION 'Imprimir'
                END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
                IF vm_row_current = vm_num_rows THEN
                        HIDE OPTION 'Avanzar'
                END IF
	 COMMAND KEY('O') 'Orden Devuelta' 'Muestra la orden devuelta. '
		CALL ver_orden(1)
	 COMMAND KEY('N') 'Orden Nueva' 'Muestra la nueva orden. '
		CALL ver_orden(2)
	 COMMAND KEY('F') 'Factura' 'Muestra la factura devuelta. '
		CALL ver_factura()
	 COMMAND KEY('P') 'Imprimir' 'Imprime comprobante devolución.'
		CALL control_imprimir()
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



FUNCTION ejecutar_devolucion_anulacion_automatica()
DEFINE num_aux		INTEGER
DEFINE resp		CHAR(6)
DEFINE anulo_oc		SMALLINT
DEFINE mens_anul	VARCHAR(10)
DEFINE mensaje		VARCHAR(200)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_t00		RECORD LIKE talt000.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t60		RECORD LIKE talt060.*

CALL fl_retorna_usuario()
INITIALIZE rm_t23.*, rm_t28.*, vm_nue_orden TO NULL
LET rm_t23.t23_num_factura = arg_val(5)
CALL fl_lee_factura_taller(vg_codcia, vg_codloc, rm_t23.t23_num_factura)
	RETURNING r_t23.*
IF r_t23.t23_compania IS NULL THEN
	CALL fl_mostrar_mensaje('La factura de esta orden de trabajo no existe.','stop')
	EXIT PROGRAM
END IF
LET rm_t23.* = r_t23.*
IF r_t23.t23_estado <> 'F' THEN
	CALL fl_mostrar_mensaje('Factura no puede ser devuelta.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING r_t00.*
IF TODAY > date(r_t23.t23_fec_factura) + r_t00.t00_dias_dev THEN
	CALL fl_mostrar_mensaje('Factura ha excedido el límite de tiempo permitido para realizar devoluciones.','stop')
	EXIT PROGRAM
END IF
IF r_t00.t00_dev_mes = 'S' THEN
	IF month(r_t23.t23_fec_factura) <> month(TODAY) THEN
		CALL fl_mostrar_mensaje('Devolución debe realizarse en el mismo mes en que se realizó la venta.','stop')
		EXIT PROGRAM
	END IF
END IF
INITIALIZE r_t60.* TO NULL
SELECT * INTO r_t60.* FROM talt060
	WHERE t60_compania  = vg_codcia
	  AND t60_localidad = vg_codloc
	  AND t60_ot_ant    = rm_t23.t23_orden
	  AND t60_fac_ant   = rm_t23.t23_num_factura
LET rm_t23.t23_descripcion = rm_t23.t23_descripcion CLIPPED,
				'POR REFACTURACION. TRABAJO YA REALIZADO'
BEGIN WORK
	IF NOT carga_datos_inicio_dev_tal() THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		RETURN
	END IF
	LET vm_cliente_nc = rm_t23.t23_cod_cliente
	IF r_t60.t60_codcli_nue IS NOT NULL THEN
		LET rm_t23.t23_cod_cliente = r_t60.t60_codcli_nue
		LET rm_t23.t23_nom_cliente = r_t60.t60_nomcli_nue
		CALL fl_lee_cliente_general(rm_t23.t23_cod_cliente)
			RETURNING r_z01.*
		LET rm_t23.t23_dir_cliente = r_z01.z01_direccion1
		LET rm_t23.t23_tel_cliente = r_z01.z01_telefono1
		LET rm_t23.t23_cedruc      = r_z01.z01_num_doc_id
	END IF
	CALL preceso_anulacion_devolucion_factura_taller() RETURNING num_aux
	UPDATE talt060
		SET t60_num_dev = rm_t28.t28_num_dev,
		    t60_ot_nue  = vm_nue_orden
		WHERE t60_compania  = vg_codcia
		  AND t60_localidad = vg_codloc
		  AND t60_ot_ant    = r_t60.t60_ot_ant
	IF STATUS < 0 THEN
		ROLLBACK WORK              
		CALL fl_mostrar_mensaje('Ha ocurrido un error al Actualizar la Devolución/Anulación en la tabla rept088.', 'stop')
		EXIT PROGRAM
	END IF
COMMIT WORK
LET rm_t23.t23_orden = rm_t28.t28_ot_ant
CALL fl_control_master_contab_taller(vg_codcia, vg_codloc,rm_t28.t28_ot_ant,'D')
BEGIN WORK
	--CALL actualiza_ot_x_oc(rm_t28.t28_ot_ant)
	CALL actualiza_ot_x_oc(rm_t28.t28_ot_nue)
COMMIT WORK
CALL generar_doc_elec()
CALL control_imprimir()
LET mens_anul = 'Devuelta'
IF DATE(rm_t28.t28_fec_factura) = TODAY THEN
	LET mens_anul = 'Anulada'
END IF
--CALL fl_mostrar_mensaje('Factura ha sido ' || mens_anul CLIPPED || '.','info')
INITIALIZE r_z21.* TO NULL
SELECT * INTO r_z21.*
	FROM cxct021
	WHERE z21_compania  = vg_codcia
	  AND z21_localidad = vg_codloc
	  AND z21_codcli    = rm_t23.t23_cod_cliente
	  AND z21_cod_tran  = 'FA'
	  AND z21_num_tran  = rm_t23.t23_num_factura
IF r_z21.z21_compania IS NOT NULL THEN
	IF r_z21.z21_tipo_doc = 'NC' THEN
		LET mensaje = 'Nota de Crédito ',
				r_z21.z21_num_doc USING "<<<<<<&", ' Ok.'
		CALL fl_mostrar_mensaje(mensaje, 'info')
	END IF
END IF

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux, cur_row	INTEGER
DEFINE resp		CHAR(6)
DEFINE anulo_oc		SMALLINT
DEFINE mens_anul	VARCHAR(10)

CALL fl_retorna_usuario()
INITIALIZE rm_r00.*, rm_t23.*, rm_t28.*, vm_nue_orden TO NULL
CLEAR FORM
LET rm_t28.t28_usuario = vg_usuario
LET rm_t28.t28_fecing  = CURRENT
DISPLAY BY NAME rm_t28.t28_usuario, rm_t28.t28_fecing
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*                
LET vm_act_cli = 0
CALL leer_factura()
IF int_flag THEN
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
	END IF
	RETURN
END IF
BEGIN WORK
	IF NOT carga_datos_inicio_dev_tal() THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		RETURN
	END IF
	LET mens_anul = 'devolver'
	IF DATE(rm_t28.t28_fec_factura) = TODAY THEN
		LET mens_anul = 'anular'
	END IF
	LET int_flag = 0
	CALL fl_hacer_pregunta('Esta seguro de ' || mens_anul CLIPPED || ' esta Factura ?.', 'No')
		RETURNING resp
	IF resp <> 'Yes' THEN
		LET int_flag = 1
		ROLLBACK WORK
		CLEAR FORM
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
		END IF
		IF vm_act_cli THEN
			CALL actualizar_codigo_cliente(rm_r00.r00_codcli_tal)
				RETURNING vm_act_cli
		END IF
		RETURN
	END IF
	LET int_flag = 0
	CALL fl_hacer_pregunta('Se va a generar una nueva OT. Desea reutilizarla ?.', 'No')
		RETURNING vm_elim_ot
	IF vm_elim_ot <> 'Yes' THEN
		LET int_flag = 0
	END IF
	CALL preceso_anulacion_devolucion_factura_taller() RETURNING num_aux
	CALL control_anular_ordenes_de_compras() RETURNING anulo_oc
	IF vm_elim_ot <> 'Yes' THEN
		IF NOT eliminar_ot_nueva() THEN
			ROLLBACK WORK
			WHENEVER ERROR STOP
			RETURN
		END IF
	END IF
COMMIT WORK
IF anulo_oc THEN
	CALL eliminar_diarios_contables_recep_reten_oc_anuladas()
END IF
DISPLAY BY NAME rm_t28.t28_num_dev, rm_t28.t28_fec_anula, vm_nue_orden
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_r_rows[vm_num_rows] = num_aux
LET vm_row_current         = vm_num_rows
CALL muestra_contadores(vm_row_current, vm_num_rows)
LET rm_t23.t23_orden       = rm_t28.t28_ot_ant
CALL fl_control_master_contab_taller(vg_codcia, vg_codloc,rm_t28.t28_ot_ant,'D')
CALL control_devolucion_inv()
BEGIN WORK
	--CALL actualiza_ot_x_oc(rm_t28.t28_ot_ant)
	CALL actualiza_ot_x_oc(rm_t28.t28_ot_nue)
COMMIT WORK
CALL generar_doc_elec()
CALL control_imprimir()
LET mens_anul = 'Devuelta'
IF DATE(rm_t28.t28_fec_factura) = TODAY THEN
	LET mens_anul = 'Anulada'
END IF
IF anulo_oc THEN
	FOR cur_row = 1 TO num_row_oc
		IF r_oc[cur_row].marcar_ot = 'N' THEN
			CONTINUE FOR
		END IF
		CALL cambiar_numero_fact_oc(r_oc[cur_row].numero_oc)
	END FOR
END IF
CALL fl_mostrar_mensaje('Factura ha sido ' || mens_anul CLIPPED || '.','info')
CALL mostrar_registro(vm_r_rows[vm_row_current], 2)

END FUNCTION



FUNCTION carga_datos_inicio_dev_tal()

WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM talt023
	WHERE t23_compania  = vg_codcia
	  AND t23_localidad = vg_codloc
	  AND t23_orden	    = rm_t23.t23_orden
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_t23.*
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN 0
END IF
WHENEVER ERROR STOP
LET rm_t28.t28_compania    = rm_t23.t23_compania
LET rm_t28.t28_localidad   = rm_t23.t23_localidad
LET rm_t28.t28_factura     = rm_t23.t23_num_factura
LET rm_t28.t28_fec_anula   = CURRENT
LET rm_t28.t28_fec_factura = rm_t23.t23_fec_factura
LET rm_t28.t28_ot_ant      = rm_t23.t23_orden
LET rm_t28.t28_usuario     = vg_usuario
LET rm_t28.t28_fecing      = CURRENT
RETURN 1

END FUNCTION



FUNCTION preceso_anulacion_devolucion_factura_taller()
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_t24		RECORD LIKE talt024.*
DEFINE cod_pago		LIKE cajt011.j11_codigo_pago
DEFINE valor		DECIMAL(12,2)
DEFINE num_aux		INTEGER

CALL obtener_num_orden_trabajo_nueva()
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,'AA', 'DF')
	RETURNING rm_t28.t28_num_dev
IF rm_t28.t28_num_dev <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET rm_t23.t23_estado      = 'D'
UPDATE talt023 SET t23_estado = rm_t23.t23_estado WHERE CURRENT OF q_up
IF num_args() <> 6 OR arg_val(6) = 'F' THEN
	CALL muestra_estado()
END IF
LET rm_t23.t23_estado      = 'A'
LET rm_t23.t23_fec_cierre  = NULL
LET rm_t23.t23_num_factura = NULL
LET rm_t23.t23_fec_factura = NULL
LET rm_t23.t23_orden       = vm_nue_orden
LET rm_t23.t23_fecing      = CURRENT
LET rm_t23.t23_usuario     = vg_usuario
LET rm_t28.t28_ot_nue      = vm_nue_orden
LET rm_t28.t28_fec_anula   = CURRENT
LET rm_t28.t28_fecing      = CURRENT
INSERT INTO talt023 VALUES(rm_t23.*)
INSERT INTO talt028 VALUES(rm_t28.*)
LET num_aux = SQLCA.SQLERRD[6] 
DECLARE q_mano CURSOR FOR
	SELECT * FROM talt024
	WHERE t24_compania  = vg_codcia
	  AND t24_localidad = vg_codloc
	  AND t24_orden     = rm_t28.t28_ot_ant
FOREACH q_mano INTO r_t24.*
	LET r_t24.t24_orden   = rm_t28.t28_ot_nue
	LET r_t24.t24_fecing  = CURRENT
	LET r_t24.t24_usuario = vg_usuario
	INSERT INTO talt024 VALUES (r_t24.*)
END FOREACH
IF rm_t23.t23_cont_cred = 'R' OR
   DATE(rm_t28.t28_fec_anula) > DATE(rm_t28.t28_fec_factura)
THEN
	CALL crea_nota_credito()
END IF
UPDATE ordt010 SET c10_ord_trabajo = rm_t28.t28_ot_nue
	WHERE c10_compania    = vg_codcia
	  AND c10_localidad   = vg_codloc
	  AND c10_ord_trabajo = rm_t28.t28_ot_ant
IF DATE(rm_t28.t28_fec_factura) = TODAY THEN
	SELECT * INTO r_j10.* FROM cajt010 
		WHERE j10_compania     = vg_codcia 
  		  AND j10_localidad    = vg_codloc 	
  		  AND j10_tipo_fuente  = 'OT'
  		  AND j10_tipo_destino = 'FA'  
  		  AND j10_num_destino  = rm_t28.t28_factura
	IF STATUS = NOTFOUND THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No existe registro en cajt010','stop')
		EXIT PROGRAM
	END IF
 	UPDATE cajt010 SET j10_estado = 'E'
		WHERE j10_compania  =  vg_codcia
          	AND j10_localidad   =  vg_codloc
          	AND j10_tipo_fuente =  'OT'
          	AND j10_num_fuente  =  rm_t28.t28_ot_ant
	DELETE FROM cajt014
		WHERE j14_compania    = vg_codcia
		  AND j14_localidad   = vg_codloc
		  AND j14_tipo_fuente = 'OT'
		  AND j14_num_fuente  = rm_t28.t28_ot_ant
	DECLARE q_lazo CURSOR FOR
		SELECT j11_codigo_pago, SUM(j11_valor) FROM cajt011
			WHERE j11_compania    =  vg_codcia 
  		    	  AND j11_localidad   =  vg_codloc 	
  		  	  AND j11_tipo_fuente =  'OT'
  		  	  AND j11_num_fuente  =  rm_t28.t28_ot_ant
		  	  AND j11_codigo_pago IN ('EF','CH')
			GROUP BY 1
	FOREACH q_lazo INTO cod_pago, valor
		IF cod_pago = 'EF' THEN
			UPDATE cajt005
				SET j05_ef_ing_dia = j05_ef_ing_dia - valor
				WHERE j05_compania   = vg_codcia 
			  	  AND j05_localidad  = vg_codloc 
			  	  AND j05_codigo_caja= r_j10.j10_codigo_caja 
		  		  AND j05_fecha_aper = DATE(r_j10.j10_fecha_pro)
		ELSE
			UPDATE cajt005
				SET j05_ch_ing_dia = j05_ch_ing_dia - valor
				WHERE j05_compania   = vg_codcia 
			  	  AND j05_localidad  = vg_codloc 
			  	  AND j05_codigo_caja= r_j10.j10_codigo_caja 
			  	  AND j05_fecha_aper = DATE(r_j10.j10_fecha_pro)
		END IF
	END FOREACH
END IF
CALL fl_actualiza_estadisticas_taller(vg_codcia,vg_codloc,rm_t28.t28_ot_ant,'R')
CALL fl_actualiza_estadisticas_mecanicos(vg_codcia,vg_codloc,rm_t28.t28_ot_ant,
					'R')  
RETURN num_aux

END FUNCTION



FUNCTION control_consulta()
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(400)
DEFINE num_reg		INTEGER
DEFINE codf_aux		LIKE talt023.t23_num_factura
DEFINE codo_aux		LIKE talt023.t23_orden
DEFINE nom_aux		LIKE talt023.t23_nom_cliente
DEFINE ot_nue		LIKE talt028.t28_ot_nue
DEFINE num_dev		LIKE talt028.t28_num_dev

CLEAR FORM
INITIALIZE codf_aux, codo_aux TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON t28_num_dev, t23_num_factura, t23_orden
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
		IF INFIELD(t23_num_factura) THEN
			CALL fl_ayuda_facturas_tal(vg_codcia,vg_codloc,'D')
				RETURNING codf_aux, nom_aux
			LET int_flag = 0
			IF codf_aux IS NOT NULL THEN
				DISPLAY codf_aux TO t23_num_factura
				DISPLAY nom_aux TO t23_nom_cliente
			END IF
		END IF
		IF INFIELD(t23_orden) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia,vg_codloc,'D')
				RETURNING codo_aux, nom_aux
			LET int_flag = 0
			IF codo_aux IS NOT NULL THEN
				DISPLAY codo_aux TO t23_orden
				DISPLAY nom_aux TO t23_nom_cliente
			END IF
		END IF
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 't28_num_dev = ', arg_val(5)
END IF
LET query = 'SELECT talt023.*, talt023.ROWID, t28_num_dev ',
		' FROM talt023, talt028 ',
		' WHERE t23_compania  = ', vg_codcia,
		'   AND t23_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		'   AND t23_estado    = "D" ',
		'   AND t28_compania  = t23_compania ',
		'   AND t28_localidad = t23_localidad ',
		'   AND t28_factura   = t23_num_factura ',
		' ORDER BY t28_num_dev '
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_t23.*, num_reg, num_dev
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
	CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
END IF

END FUNCTION



FUNCTION leer_factura()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE cambiar_cli	SMALLINT
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_lin		RECORD LIKE talt004.*
DEFINE r_ltl		RECORD LIKE talt001.*
DEFINE r_cia		RECORD LIKE talt000.*
DEFINE codf_aux		LIKE talt023.t23_num_factura
DEFINE codcli		LIKE talt023.t23_cod_cliente
DEFINE nom_aux		LIKE talt023.t23_nom_cliente

OPTIONS INPUT NO WRAP
INITIALIZE codf_aux, codcli TO NULL
LET cambiar_cli = 0
LET int_flag    = 0
INPUT BY NAME rm_t23.t23_num_factura, rm_t23.t23_cod_cliente
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_t23.t23_num_factura) THEN
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
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t23_num_factura) THEN
			CALL fl_ayuda_facturas_tal(vg_codcia, vg_codloc, 'F')
				RETURNING codf_aux, nom_aux
			IF codf_aux IS NOT NULL THEN
				LET rm_t23.t23_num_factura = codf_aux
				DISPLAY BY NAME rm_t23.t23_num_factura
				DISPLAY nom_aux TO t23_nom_cliente
			END IF
		END IF
                IF INFIELD(t23_cod_cliente) THEN
			IF rm_t23.t23_cod_cliente <> rm_r00.r00_codcli_tal THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_t23.t23_cod_cliente = r_z01.z01_codcli
				DISPLAY BY NAME rm_t23.t23_cod_cliente
				DISPLAY r_z01.z01_nomcli TO t23_nom_cliente
			END IF
                END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
        BEFORE FIELD t23_cod_cliente
		IF NOT cambiar_cli THEN
			LET codcli = rm_t23.t23_cod_cliente
		END IF
	BEFORE FIELD t23_num_factura
		LET codf_aux = rm_t23.t23_num_factura
	AFTER FIELD t23_num_factura
		IF rm_t23.t23_num_factura IS NOT NULL THEN
			CALL fl_lee_factura_taller(vg_codcia,vg_codloc,
						rm_t23.t23_num_factura)
				RETURNING r_t23.*
			IF r_t23.t23_compania IS NULL THEN
				CALL fl_mostrar_mensaje('La factura no existe.','exclamation')
				NEXT FIELD t23_num_factura
			END IF
			IF codf_aux <> rm_t23.t23_num_factura THEN
				LET cambiar_cli = 0
			END IF
			LET rm_t23.* = r_t23.*
			DISPLAY BY NAME	rm_t23.t23_nom_cliente,
					rm_t23.t23_fec_factura,
					rm_t23.t23_orden,
					rm_t23.t23_modelo
			CALL fl_lee_tipo_vehiculo(vg_codcia,rm_t23.t23_modelo)
				RETURNING r_lin.*
			CALL fl_lee_linea_taller(vg_codcia, r_lin.t04_linea)
				RETURNING r_ltl.*
			DISPLAY r_lin.t04_linea TO tit_linea
			DISPLAY r_ltl.t01_nombre TO tit_linea_des
			CALL muestra_estado()
			IF r_t23.t23_estado <> 'F' THEN
				CALL fl_mostrar_mensaje('Factura no puede ser devuelta.','exclamation')
				NEXT FIELD t23_num_factura
			END IF
			CALL fl_lee_configuracion_taller(vg_codcia)
				RETURNING r_cia.*
			IF TODAY > date(r_t23.t23_fec_factura)
			+ r_cia.t00_dias_dev THEN
				CALL fl_mostrar_mensaje('Factura ha excedido el límite de tiempo permitido para realizar devoluciones.','exclamation')
                        	INITIALIZE r_t23.* TO NULL
	                        NEXT FIELD t23_num_factura
        	        END IF
	                IF r_cia.t00_dev_mes = 'S' THEN
        	                IF month(r_t23.t23_fec_factura) <> month(TODAY)
				THEN
					CALL fl_mostrar_mensaje('Devolución debe realizarse en el mismo mes en que se realizó la venta.','exclamation')
            	         		INITIALIZE r_t23.* TO NULL
                	                NEXT FIELD t23_num_factura
                        	END IF
                	END IF
			IF TODAY > DATE(rm_t23.t23_fec_factura) AND
			   rm_t23.t23_cod_cliente = rm_r00.r00_codcli_tal AND
			   NOT cambiar_cli
			THEN
				CALL fl_mostrar_mensaje('Se va a generar NC, y el cliente es CONSUMIDOR FINAL, debe indicar un código de cliente valido.','exclamation')
				LET cambiar_cli = 1
				NEXT FIELD t23_cod_cliente
			END IF
			IF cambiar_cli THEN
				IF codcli IS NOT NULL THEN
					LET rm_t23.t23_cod_cliente = codcli
                			DISPLAY r_z01.z01_nomcli TO
						t23_nom_cliente
				END IF
			END IF
		ELSE
			CLEAR FORM
			NEXT FIELD t23_num_factura
		END IF
        AFTER FIELD t23_cod_cliente
		IF NOT cambiar_cli THEN
			LET rm_t23.t23_cod_cliente = codcli
			DISPLAY BY NAME rm_t23.t23_cod_cliente
			CONTINUE INPUT
		END IF
		CALL fl_lee_cliente_general(rm_t23.t23_cod_cliente)
			RETURNING r_z01.*
		IF r_z01.z01_codcli IS NULL THEN
			CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
			NEXT FIELD t23_cod_cliente
		END IF
		IF r_z01.z01_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD t23_cod_cliente
		END IF
		LET rm_t23.t23_cod_cliente = r_z01.z01_codcli
		DISPLAY BY NAME rm_t23.t23_cod_cliente
                DISPLAY r_z01.z01_nomcli TO t23_nom_cliente
		IF rm_t23.t23_cod_cliente = rm_r00.r00_codcli_tal THEN
			CALL fl_mostrar_mensaje('El codigo del cliente no puede ser el del consumidor final.','exclamation')
			NEXT FIELD t23_cod_cliente
		END IF
		CALL validar_cedruc(r_z01.z01_codcli, r_z01.z01_num_doc_id,
					r_z01.z01_tipo_doc_id)
			RETURNING resul
		IF NOT resul THEN
			NEXT FIELD t23_cod_cliente
		END IF
		IF r_z01.z01_tipo_doc_id = 'C' OR r_z01.z01_tipo_doc_id = 'R'
		THEN
			CALL fl_validar_cedruc_dig_ver(r_z01.z01_num_doc_id)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD t23_cod_cliente
			END IF
		END IF
		LET codcli      = rm_t23.t23_cod_cliente
		LET cambiar_cli = 1
	AFTER INPUT
		IF TODAY > DATE(rm_t23.t23_fec_factura) AND
		   rm_t23.t23_cod_cliente = rm_r00.r00_codcli_tal THEN
			CALL fl_mostrar_mensaje('Se va a generar NC, y el cliente es CONSUMIDOR FINAL, debe indicar un código de cliente valido.','exclamation')
			NEXT FIELD t23_cod_cliente
		END IF
END INPUT
IF NOT cambiar_cli THEN
	RETURN
END IF
CALL actualizar_codigo_cliente(rm_t23.t23_cod_cliente) RETURNING vm_act_cli

END FUNCTION



FUNCTION actualizar_codigo_cliente(cod_cliente)
DEFINE cod_cliente	LIKE talt023.t23_cod_cliente
DEFINE r_t23		RECORD LIKE talt023.*

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_cli CURSOR FOR
	SELECT * FROM talt023
	WHERE t23_compania    = rm_t23.t23_compania
	  AND t23_localidad   = rm_t23.t23_localidad
	  AND t23_num_factura = rm_t23.t23_num_factura
	FOR UPDATE
OPEN q_cli
FETCH q_cli INTO r_t23.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	LET int_flag = 1
	RETURN 0
END IF
UPDATE talt023 SET t23_cod_cliente = cod_cliente WHERE CURRENT OF q_cli
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error al intentar actualizar el código del cliente. Llame al ADMINISTRADOR.', 'exclamation')
	WHENEVER ERROR STOP
	LET int_flag = 1
	RETURN 0
END IF
WHENEVER ERROR STOP
COMMIT WORK
RETURN 1

END FUNCTION



FUNCTION validar_cedruc(codcli, cedruc, tipo_doc_id)
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE cedruc		LIKE cxct001.z01_num_doc_id
DEFINE tipo_doc_id	LIKE cxct001.z01_tipo_doc_id
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE cont		INTEGER
DEFINE resul		SMALLINT

SELECT COUNT(*) INTO cont
	FROM cxct001
	WHERE z01_num_doc_id = cedruc
	  AND z01_estado     = 'A'
CASE cont
	WHEN 0
		LET resul = 1
	WHEN 1
		INITIALIZE r_z01.* TO NULL
		DECLARE q_cedruc CURSOR FOR
			SELECT * FROM cxct001
				WHERE z01_num_doc_id = cedruc
				  AND z01_estado     = 'A'
		OPEN q_cedruc
		FETCH q_cedruc INTO r_z01.*
		CLOSE q_cedruc
		FREE q_cedruc
		LET resul = 1
		IF r_z01.z01_codcli <> codcli OR codcli IS NULL THEN
			CALL fl_mostrar_mensaje('Este número de identificación ya existe.','exclamation')
			LET resul = 0
		END IF
	OTHERWISE
		CALL fl_mostrar_mensaje('Este número de identificación ya existe varias veces.','exclamation')
		LET resul = 0
END CASE
IF cont <= 1 THEN
	IF tipo_doc_id = 'C' OR tipo_doc_id = 'R' THEN
		CALL fl_validar_cedruc_dig_ver(cedruc) RETURNING resul
	END IF
END IF
RETURN resul

END FUNCTION



FUNCTION obtener_num_orden_trabajo_nueva()

SELECT NVL(MAX(t23_orden), 0) + 1 INTO vm_nue_orden
	FROM talt023
	WHERE t23_compania  = vg_codcia
	  AND t23_localidad = vg_codloc

END FUNCTION



FUNCTION muestra_siguiente_registro()
                                                                                
IF vm_row_current < vm_num_rows THEN
        LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
CALL muestra_contadores(vm_row_current, vm_num_rows)
                                                                                
END FUNCTION



FUNCTION muestra_anterior_registro()
                                                                                
IF vm_row_current > 1 THEN
        LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
CALL muestra_contadores(vm_row_current, vm_num_rows)
                                                                                
END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current      SMALLINT
DEFINE num_rows         SMALLINT
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 19
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

END FUNCTION



FUNCTION mostrar_registro(num_reg, flag)
DEFINE num_reg		INTEGER
DEFINE flag		SMALLINT
DEFINE r_tal		RECORD LIKE talt028.*
DEFINE r_lin		RECORD LIKE talt004.*
DEFINE r_ltl		RECORD LIKE talt001.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
INITIALIZE rm_t23.*, r_tal.* TO NULL
CASE flag
	WHEN 1
		SELECT * INTO rm_t23.* FROM talt023 WHERE ROWID = num_reg
		IF rm_t23.t23_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe registro (orden de trabajo) con índice: ' || vm_row_current, 'exclamation')
			RETURN
		END IF
		SELECT * INTO r_tal.* FROM talt028
			WHERE t28_compania  = rm_t23.t23_compania 
			  AND t28_localidad = rm_t23.t23_localidad
			  AND t28_factura   = rm_t23.t23_num_factura
	WHEN 2
		SELECT * INTO r_tal.* FROM talt028 WHERE ROWID = num_reg
		IF r_tal.t28_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe registro (devolución) con índice: ' || vm_row_current, 'exclamation')
			RETURN
		END IF
		SELECT * INTO rm_t23.* FROM talt023
			WHERE t23_compania  = r_tal.t28_compania 
			  AND t23_localidad = r_tal.t28_localidad
			  AND t23_orden     = r_tal.t28_ot_ant
END CASE
DISPLAY BY NAME r_tal.t28_num_dev, r_tal.t28_fec_anula, r_tal.t28_usuario,
		r_tal.t28_fecing, rm_t23.t23_num_factura,rm_t23.t23_cod_cliente,
		rm_t23.t23_nom_cliente, rm_t23.t23_fec_factura,rm_t23.t23_orden,
		rm_t23.t23_modelo
CALL fl_lee_tipo_vehiculo(vg_codcia,rm_t23.t23_modelo) RETURNING r_lin.*
DISPLAY r_lin.t04_linea TO tit_linea
CALL fl_lee_linea_taller(vg_codcia, r_lin.t04_linea) RETURNING r_ltl.*
DISPLAY r_ltl.t01_nombre TO tit_linea_des
DISPLAY r_tal.t28_ot_nue TO vm_nue_orden
CALL muestra_estado()

END FUNCTION



FUNCTION muestra_estado()
DEFINE r_t28		RECORD LIKE talt028.*

IF rm_t23.t23_estado = 'A' THEN
        DISPLAY 'ACTIVA' TO tit_estado_tal
END IF
IF rm_t23.t23_estado = 'C' THEN
        DISPLAY 'CERRADA' TO tit_estado_tal
END IF
IF rm_t23.t23_estado = 'F' THEN
        DISPLAY 'FACTURADA' TO tit_estado_tal
END IF
IF rm_t23.t23_estado = 'E' THEN
        DISPLAY 'ELIMINADA' TO tit_estado_tal
END IF
IF rm_t23.t23_estado = 'D' THEN
        DISPLAY 'DEVUELTA' TO tit_estado_tal
END IF
DISPLAY BY NAME rm_t23.t23_estado
INITIALIZE r_t28.* TO NULL
SELECT * INTO r_t28.*
	FROM talt028
	WHERE t28_compania  = rm_t23.t23_compania 
	  AND t28_localidad = rm_t23.t23_localidad
	  AND t28_factura   = rm_t23.t23_num_factura
IF DATE(r_t28.t28_fec_anula) = DATE(rm_t23.t23_fec_factura) THEN
	SELECT * FROM cxct021
		WHERE z21_compania  = r_t28.t28_compania 
		  AND z21_localidad = r_t28.t28_localidad
		  AND z21_codcli    = rm_t23.t23_cod_cliente
		  AND z21_tipo_doc  = 'NC'
		  AND z21_areaneg   = 2
		  AND z21_cod_tran  = 'FA'
		  AND z21_num_tran  = r_t28.t28_factura
	IF STATUS = NOTFOUND THEN
		DISPLAY 'A'       TO t23_estado
        	DISPLAY 'ANULADA' TO tit_estado_tal
	END IF
END IF
                                                                                
END FUNCTION



FUNCTION ver_orden(flag)
DEFINE flag		SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE r_t28		RECORD LIKE talt028.*
DEFINE orden		LIKE talt023.t23_orden

IF rm_t23.t23_orden IS NULL THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CASE flag
	WHEN 1
		LET orden = rm_t23.t23_orden
	WHEN 2
		INITIALIZE r_t28.* TO NULL
		SELECT * INTO r_t28.* FROM talt028
			WHERE t28_compania  = vg_codcia
			  AND t28_localidad = vg_codloc
			  AND t28_ot_ant    = rm_t23.t23_orden
		LET orden = r_t28.t28_ot_nue
END CASE
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, run_prog, 'talp204 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', orden, ' ', 'O'
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_factura()
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
			vg_separador, 'fuentes', vg_separador, run_prog,
			'talp308 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
			' ', vg_codloc, ' ', rm_t23.t23_num_factura, ' "D" '
RUN vm_nuevoprog

END FUNCTION



FUNCTION crea_nota_credito()
DEFINE r_nc		RECORD LIKE cxct021.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_ccred		RECORD LIKE talt025.*
DEFINE num_nc		INTEGER
DEFINE num_row		INTEGER
DEFINE valor_credito	DECIMAL(14,2)	
DEFINE tot_saldo_doc	DECIMAL(14,2)	
DEFINE valor_aplicado	DECIMAL(14,2)	
DEFINE inserta_nc	SMALLINT
DEFINE r_mol            RECORD LIKE talt004.*
DEFINE r_lin            RECORD LIKE talt001.*
DEFINE r_grp            RECORD LIKE gent020.*

CALL fl_lee_tipo_vehiculo(vg_codcia,rm_t23.t23_modelo) RETURNING r_mol.*
CALL fl_lee_linea_taller(vg_codcia,r_mol.t04_linea) RETURNING r_lin.*
CALL fl_lee_grupo_linea(vg_codcia,r_lin.t01_grupo_linea) RETURNING r_grp.*
INITIALIZE r_nc.* TO NULL
LET r_nc.z21_compania 	= vg_codcia
LET r_nc.z21_localidad 	= vg_codloc
LET r_nc.z21_codcli 	= rm_t23.t23_cod_cliente
IF num_args() = 6 THEN
	LET r_nc.z21_codcli = vm_cliente_nc
END IF
LET r_nc.z21_tipo_doc 	= 'NC'
LET r_nc.z21_areaneg 	= r_grp.g20_areaneg
LET r_nc.z21_linea 	= r_grp.g20_grupo_linea
LET r_nc.z21_referencia = 'DEV. FACTURA: FA-', rm_t28.t28_factura
						USING "<<<<<<<<<&"
LET r_nc.z21_fecha_emi 	= TODAY
LET r_nc.z21_moneda 	= rm_t23.t23_moneda
LET r_nc.z21_paridad 	= 1
IF r_nc.z21_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(r_nc.z21_moneda, rg_gen.g00_moneda_base)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No hay factor de conversión.','stop')
		EXIT PROGRAM
	END IF
	LET r_nc.z21_paridad 	= r_g14.g14_tasa
END IF	
LET valor_credito = rm_t23.t23_tot_neto
INITIALIZE r_ccred.* TO NULL
IF rm_t23.t23_cont_cred = 'R' THEN
	SELECT * INTO r_ccred.* FROM talt025
		WHERE t25_compania  = vg_codcia
		  AND t25_localidad = vg_codloc
		  AND t25_orden     = rm_t28.t28_ot_ant
        IF STATUS <> NOTFOUND THEN
	        SELECT SUM(t26_valor_cap + t26_valor_int) INTO valor_credito
			FROM talt026
			WHERE t26_compania  = vg_codcia
			  AND t26_localidad = vg_codloc
			  AND t26_orden     = rm_t28.t28_ot_ant
	        IF valor_credito = 0 OR valor_credito IS NULL THEN
		        ROLLBACK WORK
			CALL fl_mostrar_mensaje('Valor del crédito 0 en talt026.','stop')
		        EXIT PROGRAM
	        END IF
        END IF
END IF
LET r_nc.z21_val_impto 	= rm_t23.t23_val_impto
LET r_nc.z21_valor 	= valor_credito
LET r_nc.z21_saldo 	= valor_credito
CALL generar_num_sri() RETURNING r_nc.z21_num_sri
LET r_nc.z21_subtipo 	= 1
LET r_nc.z21_origen 	= 'A'
LET r_nc.z21_usuario 	= vg_usuario
LET r_nc.z21_cod_tran 	= 'FA'
LET r_nc.z21_num_tran 	= rm_t28.t28_factura
LET r_nc.z21_fecing 	= CURRENT
LET inserta_nc = 1
IF TODAY = DATE(rm_t28.t28_fec_factura) THEN
	SELECT SUM(z20_saldo_cap + z20_saldo_int) INTO tot_saldo_doc 
		FROM cxct020 
		WHERE z20_compania  = vg_codcia
		  AND z20_localidad = vg_codloc
		  AND z20_areaneg   = r_grp.g20_areaneg
		  AND z20_cod_tran  = 'FA'
		  AND z20_num_tran  = rm_t28.t28_factura
	IF valor_credito <= tot_saldo_doc THEN 
		LET inserta_nc 		= 0
		LET r_nc.z21_tipo_doc 	= NULL
		LET r_nc.z21_num_doc 	= NULL
	END IF
END IF
LET num_row = 0
IF inserta_nc THEN
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'CO', 'AA',
						'NC')
		RETURNING num_nc
	IF num_nc <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_nc.z21_num_doc = num_nc 
	LET r_nc.z21_fecing  = CURRENT
	INSERT INTO cxct021 VALUES (r_nc.*)
	LET num_row = SQLCA.SQLERRD[6]
END IF
CALL fl_aplica_documento_favor(vg_codcia, vg_codloc, r_nc.z21_codcli, 
			    r_nc.z21_tipo_doc, r_nc.z21_num_doc, valor_credito,
			    r_nc.z21_moneda, r_nc.z21_areaneg,
			    'FA', rm_t28.t28_factura)
	RETURNING valor_aplicado
IF inserta_nc THEN
	UPDATE cxct021 SET z21_saldo = z21_saldo - valor_aplicado
		WHERE ROWID = num_row
END IF
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_nc.z21_codcli)

END FUNCTION



FUNCTION control_devolucion_inv()
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE resp		CHAR(6)
DEFINE param		VARCHAR(60)
DEFINE mensaje		VARCHAR(200)
DEFINE mens_anul	VARCHAR(10)

INITIALIZE r_r19.* TO NULL
DECLARE q_r19 CURSOR FOR
	SELECT * FROM rept019
		WHERE r19_compania    = vg_codcia
		  AND r19_localidad   = vg_codloc
		  AND r19_cod_tran    = 'FA'
		  AND r19_tipo_dev    IS NULL
		  AND r19_ord_trabajo = rm_t28.t28_ot_ant
		ORDER BY r19_num_tran
OPEN q_r19
FETCH q_r19 INTO r_r19.*
IF r_r19.r19_compania IS NULL THEN
	CLOSE q_r19
	FREE q_r19
	RETURN
END IF
LET mens_anul = 'devolver'
IF DATE(rm_t28.t28_fec_factura) = TODAY THEN
	LET mens_anul = 'anular'
END IF
LET int_flag = 0
CALL fl_hacer_pregunta('Desea ' || mens_anul CLIPPED || ' también las Facturas de materiales ?.', 'Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	CALL fl_mostrar_mensaje('Las Facturas de materiales se devuelven/anulan por el módulo de INVENTARIO.', 'info')
	LET int_flag = 0
	RETURN
END IF
FOREACH q_r19 INTO r_r19.*
	LET param = '"', r_r19.r19_cod_tran, '" ', r_r19.r19_num_tran CLIPPED,
			' "A" '
	LET mensaje = "Generando Devolución/Anulación de ", r_r19.r19_cod_tran,
			"-", r_r19.r19_num_tran USING '<<<<<<<<<&',
			". Por favor espere ..."
	ERROR mensaje
	CALL ejecuta_comando('REPUESTOS', 'RE', 'repp217 ', param)
	ERROR '                                                                     '
END FOREACH

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', vg_codloc, ' ', param
RUN comando

END FUNCTION



FUNCTION control_anular_ordenes_de_compras()
DEFINE r_c00		RECORD LIKE ordt000.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE resp		CHAR(6)
DEFINE anulo_rp		SMALLINT
DEFINE mensaje		VARCHAR(200)
DEFINE cur_row		SMALLINT
DEFINE i_row, i_col	SMALLINT
DEFINE n_row, n_col	SMALLINT
DEFINE salir, dias	SMALLINT
DEFINE pago, tot_neto	DECIMAL(14,2)

LET anulo_rp = 0
INITIALIZE r_c10.* TO NULL
DECLARE q_c10 CURSOR FOR
	SELECT * FROM ordt010
		WHERE c10_compania    = vg_codcia
		  AND c10_localidad   = vg_codloc
		  AND c10_ord_trabajo = rm_t28.t28_ot_nue
		  AND c10_estado      = 'C'
		ORDER BY c10_numero_oc
OPEN q_c10
FETCH q_c10 INTO r_c10.*
IF r_c10.c10_compania IS NULL THEN
	CLOSE q_c10
	FREE q_c10
	RETURN anulo_rp
END IF
CALL fl_lee_compania_orden_compra(vg_codcia) RETURNING r_c00.*
LET num_row_oc = 0
LET tot_neto   = 0
FOREACH q_c10 INTO r_c10.*
	IF vm_elim_ot <> 'Yes' THEN
		CONTINUE FOREACH
	END IF
	LET dias = TODAY - r_c10.c10_fecha_fact
	IF (r_c00.c00_react_mes = 'S' AND
	   (YEAR(TODAY) <> YEAR(r_c10.c10_fecha_fact) OR
	    MONTH(TODAY) <> MONTH(r_c10.c10_fecha_fact))) OR
	   (r_c00.c00_react_mes = 'N' AND dias > r_c00.c00_dias_react)
	THEN
		CONTINUE FOREACH
	END IF
	SELECT NVL(SUM((p20_valor_cap + p20_valor_int) -
		(p20_saldo_cap + p20_saldo_int)), 0)
		INTO pago
		FROM ordt013, cxpt020
		WHERE c13_compania  = r_c10.c10_compania
		  AND c13_localidad = r_c10.c10_localidad
		  AND c13_numero_oc = r_c10.c10_numero_oc
		  AND c13_estado    = 'A'
		  AND p20_compania  = c13_compania
		  AND p20_localidad = c13_localidad
		  AND p20_codprov   = r_c10.c10_codprov
		  AND p20_num_doc   = c13_factura
		  AND p20_numero_oc = c13_numero_oc
	IF pago <> 0 THEN
		CONTINUE FOREACH
	END IF
	LET num_row_oc                   = num_row_oc + 1
	LET r_oc[num_row_oc].estado      = r_c10.c10_estado
	LET r_oc[num_row_oc].numero_oc   = r_c10.c10_numero_oc
	LET r_oc[num_row_oc].fecha       = DATE(r_c10.c10_fecing)
	LET r_oc[num_row_oc].descripcion = r_c10.c10_referencia
	LET r_oc[num_row_oc].total       = r_c10.c10_tot_compra
	LET r_oc[num_row_oc].marcar_ot   = 'S'
	LET tot_neto                     = tot_neto + r_c10.c10_tot_compra
	IF num_row_oc > max_row_oc THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pueden mostrar todas las Ordenes de Compra de esta Orden de Trabajo. Por favor llame al ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
END FOREACH
IF num_row_oc = 0 THEN
	RETURN anulo_rp
END IF
LET i_row = 04
LET n_row = 14
LET i_col = 07
LET n_col = 69
IF vg_gui = 0 THEN
	LET i_row = 05
	LET n_row = 14
	LET i_col = 06
	LET n_col = 70
END IF
OPEN WINDOW w_talf211_2 AT i_row, i_col WITH n_row ROWS, n_col COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_talf211_2 FROM "../forms/talf211_2"
ELSE
	OPEN FORM f_talf211_2 FROM "../forms/talf211_2c"
END IF
DISPLAY FORM f_talf211_2
MESSAGE "Seleccionando datos . . . espere por favor" ATTRIBUTE(NORMAL)
--#DISPLAY 'E'           TO tit_col1
--#DISPLAY 'O.C.'        TO tit_col2
--#DISPLAY 'Fecha'       TO tit_col3
--#DISPLAY 'Referencia'	 TO tit_col4
--#DISPLAY 'Total OC'    TO tit_col5
--#DISPLAY 'C'           TO tit_col6
DISPLAY rm_t28.t28_ot_nue  TO num_ot
DISPLAY rm_t28.t28_factura TO num_fac
DISPLAY BY NAME tot_neto
OPTIONS INSERT KEY F30,
	DELETE KEY F31
LET salir = 0
WHILE NOT salir
	CALL set_count(num_row_oc)
	LET int_flag = 0
	INPUT ARRAY r_oc WITHOUT DEFAULTS FROM r_oc.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				CALL fl_mostrar_mensaje('Las Recepciones por Ordenes de Compra se anulan por el módulo de COMPRAS.', 'info')
	                	LET int_flag = 1
				LET salir    = 1
				EXIT INPUT
			END IF
		ON KEY(F1, CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET cur_row = arr_curr()
			CALL ver_orden_compra(r_oc[cur_row].numero_oc)
			LET int_flag = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("DELETE","")
		BEFORE ROW
			LET cur_row = arr_curr()
			DISPLAY BY NAME cur_row
			DISPLAY num_row_oc TO num_row
		BEFORE INSERT
			EXIT INPUT
		BEFORE DELETE
			EXIT INPUT
		AFTER INPUT
			LET salir = 1
	END INPUT
END WHILE
IF int_flag THEN
	CLOSE WINDOW w_talf211_2
	LET int_flag = 0
	RETURN anulo_rp
END IF
LET cur_row = 1
FOREACH q_c10 INTO r_c10.*
	IF r_oc[cur_row].numero_oc = r_c10.c10_numero_oc AND
	   r_oc[cur_row].marcar_ot = 'N'
	THEN
		CONTINUE FOREACH
	END IF
	LET mensaje = "Generando Anulación Recepción Orden de Compra ",
			r_c10.c10_numero_oc USING '<<<<<<<&',
			". Por favor espere ..."
	ERROR mensaje
	CALL control_anular_recepcion_orden_compra(r_c10.c10_numero_oc)
		RETURNING anulo_rp
	ERROR '                                                                            '
	LET cur_row = cur_row + 1
END FOREACH
CLOSE WINDOW w_talf211_2
LET int_flag = 0
RETURN anulo_rp

END FUNCTION



FUNCTION control_anular_recepcion_orden_compra(oc)
DEFINE oc 		LIKE ordt013.c13_numero_oc
DEFINE num_ret		LIKE cxpt028.p28_num_ret
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE anulo_rp, i	SMALLINT
DEFINE mensaje		VARCHAR(250)

LET vm_max_detalle  = 250
LET vm_nota_credito = 'NC'
INITIALIZE rm_c10.*, rm_c13.* TO NULL
WHENEVER ERROR CONTINUE
DECLARE q_ordt013 CURSOR FOR
        SELECT * FROM ordt013
               WHERE c13_compania  = vg_codcia
                 AND c13_localidad = vg_codloc
                 AND c13_numero_oc = oc
                 AND c13_estado    = 'A'
	FOR UPDATE
OPEN q_ordt013
FETCH q_ordt013 INTO rm_c13.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	LET mensaje = 'La recepción # ', rm_c13.c13_num_recep USING "<<<<&&",
			' por orden de compra # ',
			rm_c13.c13_numero_oc USING "<<<<<<<&",
			' esta bloqueada por otro usuario.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
IF rm_c13.c13_compania IS NULL THEN
	CLOSE q_ordt013
	FREE q_ordt013
	ROLLBACK WORK
	LET mensaje = 'La orden de compra # ',
			rm_c13.c13_numero_oc USING "<<<<<<<&",
		       ' no tiene ninguna recepción para que pueda ser anulada.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP
LET anulo_rp = 0
FOREACH q_ordt013 INTO rm_c13.*
	DECLARE q_ordt014 CURSOR FOR
		SELECT c14_cantidad, c14_codigo, c14_descrip, c14_descuento,
			c14_precio
			FROM ordt014
			WHERE c14_compania  = rm_c13.c13_compania
			  AND c14_localidad = rm_c13.c13_localidad
			  AND c14_numero_oc = rm_c13.c13_numero_oc
			  AND c14_num_recep = rm_c13.c13_num_recep
	LET i = 1
	FOREACH q_ordt014 INTO r_detalle[i].*
		LET i = i + 1
		IF i > vm_max_detalle THEN
			CALL fl_mensaje_arreglo_incompleto()
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
	END FOREACH
	LET vm_ind_arr = i - 1
	IF vm_ind_arr = 0 THEN
		LET mensaje = 'La recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				' no tiene detalle.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
		EXIT FOREACH
	END IF
	IF NOT validar_recep_oc() THEN
		EXIT FOREACH
	END IF
	WHENEVER ERROR CONTINUE 
	DECLARE q_ordt010 CURSOR FOR 
		SELECT * FROM ordt010
			WHERE c10_compania  = rm_c13.c13_compania
			  AND c10_localidad = rm_c13.c13_localidad
			  AND c10_numero_oc = rm_c13.c13_numero_oc
		FOR UPDATE
	OPEN q_ordt010 
	FETCH q_ordt010 INTO r_c10.*
	IF STATUS < 0 THEN
		ROLLBACK WORK 
		WHENEVER ERROR STOP
		LET mensaje = 'La orden de compra # ',
				r_c10.c10_numero_oc USING "<<<<<<<&",
				' esta bloqueada por otro usuario.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	FOR i = 1 TO vm_ind_arr
		UPDATE ordt011
			SET c11_cant_rec = c11_cant_rec -
						r_detalle[i].c14_cantidad
			WHERE c11_compania  = r_c10.c10_compania
			  AND c11_localidad = r_c10.c10_localidad
			  AND c11_numero_oc = r_c10.c10_numero_oc
			  AND c11_codigo    = r_detalle[i].c14_codigo
		IF STATUS < 0 THEN
			ROLLBACK WORK 
			WHENEVER ERROR STOP
			LET mensaje = 'No se pudo actualizar el detalle de la',
					' orden de compra # ',
					r_c10.c10_numero_oc USING "<<<<<<<&",
					'. Ha ocurrido un error de Base de ',
					'Datos, llame al ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			EXIT PROGRAM
		END IF
	END FOR 
	LET i = 0
	UPDATE ordt013 SET c13_estado    = 'E',
			   c13_fecha_eli = CURRENT
		WHERE c13_compania  = rm_c13.c13_compania
		  AND c13_localidad = rm_c13.c13_localidad
		  AND c13_numero_oc = rm_c13.c13_numero_oc
		  AND c13_num_recep = rm_c13.c13_num_recep
	IF STATUS < 0 THEN
		ROLLBACK WORK 
		WHENEVER ERROR STOP
		LET mensaje = 'No se pudo eliminar la recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				'. Ha ocurrido un error de Base de ',
				'Datos, llame al ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		EXIT PROGRAM
	END IF
	IF rm_c10.c10_tipo_pago = 'R' THEN
		LET valor_aplicado = control_rebaja_deuda()  
		IF valor_aplicado < 0 THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
	END IF
	IF rm_c13.c13_tot_recep = rm_c10.c10_tot_compra THEN
		UPDATE ordt010 SET c10_estado = 'E' WHERE CURRENT OF q_ordt010
		IF STATUS < 0 THEN
			ROLLBACK WORK 
			WHENEVER ERROR STOP
			LET mensaje = 'No se pudo actualizar el estado de la ',
					'orden de compra # ',
					r_c10.c10_numero_oc USING "<<<<<<<&",
					'. Ha ocurrido un error de Base de ',
					'Datos, llame al ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			EXIT PROGRAM
		END IF
		UPDATE ordt010 SET c10_ord_trabajo = rm_t28.t28_ot_ant
			WHERE CURRENT OF q_ordt010
		IF STATUS < 0 THEN
			ROLLBACK WORK 
			WHENEVER ERROR STOP
			LET mensaje = 'No se pudo restaurar la OT anterior a ',
					'la orden de compra # ',
					r_c10.c10_numero_oc USING "<<<<<<<&",
					'. Ha ocurrido un error de Base de ',
					'Datos, llame al ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			EXIT PROGRAM
		END IF
	END IF		
	DECLARE q_cxpt028 CURSOR FOR 
		SELECT UNIQUE p28_num_ret
			FROM cxpt028
			WHERE p28_compania  = rm_c10.c10_compania
			  AND p28_localidad = rm_c10.c10_localidad
			  AND p28_codprov   = rm_c10.c10_codprov
			  AND p28_tipo_doc  = 'FA'
			  AND p28_num_doc   = rm_c13.c13_factura
	OPEN  q_cxpt028
	FETCH q_cxpt028 INTO num_ret
	CLOSE q_cxpt028
	FREE  q_cxpt028
	UPDATE cxpt027 SET p27_estado    = 'E',
			   p27_fecha_eli = CURRENT
		WHERE p27_compania  = rm_c10.c10_compania
		  AND p27_localidad = rm_c10.c10_localidad
		  AND p27_num_ret   = num_ret
	IF STATUS < 0 THEN
		ROLLBACK WORK 
		WHENEVER ERROR STOP
		LET mensaje = 'No se pudo eliminar la retención de la ',
				'recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				'. Ha ocurrido un error de Base de ',
				'Datos, llame al ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		EXIT PROGRAM
	END IF
	LET anulo_rp = 1
END FOREACH
RETURN anulo_rp

END FUNCTION



FUNCTION validar_recep_oc()
DEFINE r_p01	 	RECORD LIKE cxpt001.*
DEFINE r_c00	 	RECORD LIKE ordt000.*
DEFINE r_c01	 	RECORD LIKE ordt001.*
DEFINE r_t23	 	RECORD LIKE talt023.*
DEFINE dias		SMALLINT
DEFINE mensaje		VARCHAR(250)

CALL fl_lee_compania_orden_compra(vg_codcia) RETURNING r_c00.*
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc)
	RETURNING rm_c10.*
IF rm_c10.c10_numero_oc IS NULL THEN
	LET mensaje = 'No existe la orden de compra # ',
			rm_c13.c13_numero_oc USING "<<<<<<<&",
			' en la Compañía.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
IF rm_c10.c10_estado <> 'C' THEN
	LET mensaje = 'No se puede anular la recepción # ',
			rm_c13.c13_num_recep USING "<<<<&&",
			' por orden de compra # ',
			rm_c10.c10_numero_oc USING "<<<<<<<&",
			'. Tiene la OC estado = ', rm_c10.c10_estado, '.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
CALL fl_lee_proveedor(rm_c10.c10_codprov) RETURNING r_p01.*
IF r_p01.p01_codprov IS NULL THEN
	ROLLBACK WORK
	LET mensaje = 'No existe Proveedor ',
			rm_c10.c10_codprov USING "<<<<<<<&",
			' en la Compañía.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING r_c01.*
IF r_c01.c01_ing_bodega = 'S' AND r_c01.c01_modulo = 'RE' THEN
	LET mensaje = 'La orden de compra # ',
			rm_c10.c10_numero_oc USING "<<<<<<<&",
			' pertenece a Inventario y debe ser anulada por ',
			'Devolución de Compra Local.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF 
LET rm_c13.c13_interes = rm_c10.c10_interes
IF rm_c10.c10_ord_trabajo IS NOT NULL THEN
	CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_c10.c10_ord_trabajo)
		RETURNING r_t23.*
	IF r_t23.t23_estado <> 'A' THEN
		LET mensaje = 'La orden de trabajo # ',
				rm_c10.c10_ord_trabajo USING "<<<<<<<&",
				' asociada a la orden de compra # ',
				rm_c10.c10_numero_oc USING "<<<<<<<&",
				' tiene estado = ', r_t23.t23_estado, '.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
		RETURN 0
	END IF
END IF
LET dias = TODAY - rm_c10.c10_fecha_fact
IF (r_c00.c00_react_mes = 'S' AND (YEAR(TODAY) <> YEAR(rm_c10.c10_fecha_fact) OR
    MONTH(TODAY) <> MONTH(rm_c10.c10_fecha_fact))) OR
   (r_c00.c00_react_mes = 'N' AND dias > r_c00.c00_dias_react)
THEN
	LET mensaje = 'No se puede anular la recepción # ',
			rm_c13.c13_num_recep USING "<<<<&&",
			' por orden de compra # ',
			rm_c10.c10_numero_oc USING "<<<<<<<&",
			'. Revise la configuración de Compañías en el módulo',
			' de COMPRAS.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION control_rebaja_deuda()
DEFINE num_row		INTEGER
DEFINE i		SMALLINT
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE aplicado_cap	DECIMAL(14,2)
DEFINE aplicado_int	DECIMAL(14,2)
DEFINE valor_aplicar	DECIMAL(14,2)
DEFINE valor_favor	LIKE cxpt021.p21_valor
DEFINE tot_ret		DECIMAL(14,2)
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p21		RECORD LIKE cxpt021.*
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*

LET tot_ret = 0
SELECT p27_total_ret INTO tot_ret
	FROM cxpt027
	WHERE p27_compania  = rm_c13.c13_compania
	  AND p27_localidad = rm_c13.c13_localidad
	  AND p27_num_ret   = rm_c13.c13_num_ret 
INITIALIZE r_p21.* TO NULL
LET r_p21.p21_compania   = vg_codcia
LET r_p21.p21_localidad  = vg_codloc
LET r_p21.p21_codprov    = rm_c10.c10_codprov
LET r_p21.p21_tipo_doc   = vm_nota_credito
LET r_p21.p21_num_doc    = nextValInSequence('TE', vm_nota_credito)
LET r_p21.p21_referencia = 'ANULACION RECEPCION # ',
				rm_c13.c13_num_recep USING "<&", ' OC # ',
				rm_c13.c13_numero_oc USING "<<<<&"
LET r_p21.p21_fecha_emi  = TODAY
LET r_p21.p21_moneda     = rm_c10.c10_moneda
LET r_p21.p21_paridad    = rm_c10.c10_paridad
LET r_p21.p21_valor      = rm_c13.c13_tot_recep - tot_ret
LET r_p21.p21_saldo      = rm_c13.c13_tot_recep - tot_ret
LET r_p21.p21_subtipo    = 1
LET r_p21.p21_origen     = 'A'
LET r_p21.p21_usuario    = vg_usuario
LET r_p21.p21_fecing     = CURRENT
INSERT INTO cxpt021 VALUES(r_p21.*)
-- Para aplicar la nota de credito
DECLARE q_ddev CURSOR FOR 
	SELECT * FROM cxpt020
		WHERE p20_compania                  = vg_codcia
	          AND p20_localidad                 = vg_codloc
	          AND p20_codprov                   = rm_c10.c10_codprov
	          AND p20_tipo_doc                  = 'FA'
	          AND p20_num_doc                   = rm_c13.c13_factura
		  AND p20_saldo_cap + p20_saldo_int > 0
		FOR UPDATE
INITIALIZE r_p22.* TO NULL
LET r_p22.p22_compania  = vg_codcia
LET r_p22.p22_localidad = vg_codloc
LET r_p22.p22_codprov	= rm_c10.c10_codprov
LET r_p22.p22_tipo_trn  = 'AJ'
LET r_p22.p22_num_trn 	= fl_actualiza_control_secuencias(vg_codcia, vg_codloc,
				'TE', 'AA', r_p22.p22_tipo_trn)
IF r_p22.p22_num_trn <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_p22.p22_referencia  = r_p21.p21_referencia CLIPPED
LET r_p22.p22_fecha_emi   = TODAY
LET r_p22.p22_moneda 	  = rm_c10.c10_moneda
LET r_p22.p22_paridad 	  = rm_c10.c10_paridad
LET r_p22.p22_tasa_mora   = 0
LET r_p22.p22_total_cap   = 0
LET r_p22.p22_total_int   = 0
LET r_p22.p22_total_mora  = 0
LET r_p22.p22_subtipo 	  = 1
LET r_p22.p22_origen 	  = 'A'
LET r_p22.p22_fecha_elim  = NULL
LET r_p22.p22_tiptrn_elim = NULL
LET r_p22.p22_numtrn_elim = NULL
LET r_p22.p22_usuario 	  = vg_usuario
LET r_p22.p22_fecing 	  = CURRENT
INSERT INTO cxpt022 VALUES (r_p22.*)
LET num_row        = SQLCA.SQLERRD[6]
LET valor_favor    = r_p21.p21_valor 
LET i              = 0
LET valor_aplicado = 0
FOREACH q_ddev INTO r_p20.*
	LET valor_aplicar = valor_favor - valor_aplicado
	IF valor_aplicar = 0 THEN
		EXIT FOREACH
	END IF
	LET i            = i + 1
	LET aplicado_cap = 0
	LET aplicado_int = 0
	IF r_p20.p20_saldo_int <= valor_aplicar THEN
		LET aplicado_int = r_p20.p20_saldo_int 
	ELSE
		LET aplicado_int = valor_aplicar
	END IF
	LET valor_aplicar = valor_aplicar - aplicado_int
	IF r_p20.p20_saldo_cap <= valor_aplicar THEN
		LET aplicado_cap = r_p20.p20_saldo_cap 
	ELSE
		LET aplicado_cap = valor_aplicar
	END IF
	LET valor_aplicado       = valor_aplicado + aplicado_cap + aplicado_int
	LET r_p22.p22_total_cap  = r_p22.p22_total_cap + (aplicado_cap * -1)
	LET r_p22.p22_total_int  = r_p22.p22_total_int + (aplicado_int * -1)
    	LET r_p23.p23_compania   = vg_codcia
    	LET r_p23.p23_localidad  = vg_codloc
    	LET r_p23.p23_codprov	 = r_p22.p22_codprov
    	LET r_p23.p23_tipo_trn   = r_p22.p22_tipo_trn
    	LET r_p23.p23_num_trn    = r_p22.p22_num_trn
    	LET r_p23.p23_orden 	 = i
    	LET r_p23.p23_tipo_doc   = r_p20.p20_tipo_doc
    	LET r_p23.p23_num_doc 	 = r_p20.p20_num_doc
    	LET r_p23.p23_div_doc 	 = r_p20.p20_dividendo
    	LET r_p23.p23_tipo_favor = r_p21.p21_tipo_doc
    	LET r_p23.p23_doc_favor  = r_p21.p21_num_doc
    	LET r_p23.p23_valor_cap  = aplicado_cap * -1
    	LET r_p23.p23_valor_int  = aplicado_int * -1
    	LET r_p23.p23_valor_mora = 0
    	LET r_p23.p23_saldo_cap  = r_p20.p20_saldo_cap
    	LET r_p23.p23_saldo_int  = r_p20.p20_saldo_int
	INSERT INTO cxpt023 VALUES (r_p23.*)
	UPDATE cxpt020 SET p20_saldo_cap = p20_saldo_cap - aplicado_cap,
	                   p20_saldo_int = p20_saldo_int - aplicado_int
		WHERE CURRENT OF q_ddev
END FOREACH
UPDATE cxpt021 SET p21_saldo = p21_saldo - valor_aplicado
	WHERE p21_compania  = r_p21.p21_compania
	  AND p21_localidad = r_p21.p21_localidad
	  AND p21_codprov   = r_p21.p21_codprov
	  AND p21_tipo_doc  = r_p21.p21_tipo_doc
	  AND p21_num_doc   = r_p21.p21_num_doc
IF i = 0 THEN
	DELETE FROM cxpt022 WHERE ROWID = num_row
ELSE
	UPDATE cxpt022 SET p22_total_cap = r_p22.p22_total_cap,
	                   p22_total_int = r_p22.p22_total_int
		WHERE ROWID = num_row
END IF
RETURN valor_aplicado

END FUNCTION



FUNCTION nextValInSequence(modulo, tipo_tran)
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE tipo_tran 	LIKE rept019.r19_cod_tran
DEFINE retVal 		SMALLINT

SET LOCK MODE TO WAIT 
LET retVal   = -1
WHILE retVal = -1
	LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc,
							modulo, 'AA', tipo_tran)
	IF retVal = 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	IF retVal <> -1 THEN
		EXIT WHILE
	END IF
END WHILE
SET LOCK MODE TO NOT WAIT
RETURN retVal

END FUNCTION



FUNCTION actualiza_ot_x_oc(orden)
DEFINE orden		LIKE talt023.t23_orden
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE bien_serv	LIKE ordt001.c01_bien_serv
DEFINE tipo		LIKE ordt011.c11_tipo
DEFINE tot_rep, valor	DECIMAL(12,2)
DEFINE tot_mo		DECIMAL(12,2)

WHENEVER ERROR CONTINUE
DECLARE q_t23 CURSOR FOR
	SELECT * FROM talt023
		WHERE t23_compania  = vg_codcia
		  AND t23_localidad = vg_codloc
		  AND t23_orden	    = orden
	FOR UPDATE
OPEN q_t23
FETCH q_t23 INTO r_t23.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo actualizar los totales por mano de obra externa de la orden de trabajo. Registro bloqueado por otro usuario.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_ord CURSOR FOR
	SELECT ordt010.*, c01_bien_serv
		FROM ordt010, ordt001
		WHERE c10_compania    = r_t23.t23_compania
		  AND c10_localidad   = r_t23.t23_localidad
		  AND c10_ord_trabajo = r_t23.t23_orden
		  AND c10_estado      = 'C'
		  AND c01_tipo_orden  = c10_tipo_orden
		ORDER BY c10_numero_oc
LET r_t23.t23_val_rp_tal = 0
LET r_t23.t23_val_otros2 = 0
LET r_t23.t23_val_mo_cti = 0
LET r_t23.t23_val_rp_cti = 0
LET r_t23.t23_val_mo_ext = 0
LET r_t23.t23_val_rp_ext = 0
FOREACH q_ord INTO r_c10.*, bien_serv
	DECLARE q_detoc CURSOR FOR 
		SELECT c11_tipo, (c11_cant_ped * c11_precio) - c11_val_descto
			FROM ordt011
			WHERE c11_compania  = r_c10.c10_compania
			  AND c11_localidad = r_c10.c10_localidad
			  AND c11_numero_oc = r_c10.c10_numero_oc
			ORDER BY c11_secuencia
	LET tot_rep = 0
	LET tot_mo  = 0
	FOREACH q_detoc INTO tipo, valor
		LET valor = valor + (valor * r_c10.c10_recargo / 100)
		LET valor = fl_retorna_precision_valor(r_c10.c10_moneda, valor)
		IF tipo = 'B' THEN
			LET tot_rep = tot_rep + valor
		ELSE
			LET tot_mo  = tot_mo  + valor
		END IF
	END FOREACH
	IF bien_serv = 'B' THEN
		LET r_t23.t23_val_rp_tal = r_t23.t23_val_rp_tal + tot_rep
	ELSE
		IF bien_serv = 'I' THEN     -- Son Suministros
			LET r_t23.t23_val_otros2 = tot_rep + tot_mo
		ELSE
			CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc,
							r_c10.c10_codprov)
				RETURNING r_p02.*
			IF r_p02.p02_int_ext = 'I' THEN
				LET r_t23.t23_val_mo_cti = r_t23.t23_val_mo_cti
								+ tot_mo
				LET r_t23.t23_val_rp_cti = r_t23.t23_val_rp_cti
								+tot_rep
			ELSE
				LET r_t23.t23_val_mo_ext = r_t23.t23_val_mo_ext
								+ tot_mo
				LET r_t23.t23_val_rp_ext = r_t23.t23_val_rp_ext
								+ tot_rep
			END IF
		END IF
	END IF
END FOREACH
WHENEVER ERROR STOP
CALL fl_totaliza_orden_taller(r_t23.*) RETURNING r_t23.*
UPDATE talt023 SET * = r_t23.* WHERE CURRENT OF q_t23

END FUNCTION



FUNCTION eliminar_ot_nueva()

WHENEVER ERROR CONTINUE
UPDATE talt023
	SET t23_estado     = 'E',
	    t23_fec_elimin = CURRENT,
	    t23_usu_elimin = vg_usuario
	WHERE t23_compania  = rm_t23.t23_compania
	  AND t23_localidad = rm_t23.t23_localidad
	  AND t23_orden     = vm_nue_orden
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se pudo ELIMINAR Orden de Trabajo nueva. Llame al ADMINISTRADOR.', 'stop')
	RETURN 0
END IF
WHENEVER ERROR STOP
RETURN 1

END FUNCTION



FUNCTION eliminar_diarios_contables_recep_reten_oc_anuladas()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_c40		RECORD LIKE ordt040.*
DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE num_ret		LIKE cxpt027.p27_num_ret

DECLARE q_eli_cont CURSOR WITH HOLD FOR
	SELECT ordt010.*, ordt013.*
		FROM ordt010, ordt013
		WHERE c10_compania    = vg_codcia
		  AND c10_localidad   = vg_codloc
		  AND c10_ord_trabajo = rm_t28.t28_ot_ant
		  AND c10_estado      = 'E'
		  AND c13_compania    = c10_compania
		  AND c13_localidad   = c10_localidad
		  AND c13_numero_oc   = c10_numero_oc
		  AND c13_estado      = c10_estado
		ORDER BY c10_numero_oc
FOREACH q_eli_cont INTO r_c10.*, r_c13.*
	INITIALIZE r_c40.*, num_ret TO NULL
	SELECT * INTO r_c40.* FROM ordt040
		WHERE c40_compania  = r_c13.c13_compania
		  AND c40_localidad = r_c13.c13_localidad
		  AND c40_numero_oc = r_c13.c13_numero_oc
		  AND c40_num_recep = r_c13.c13_num_recep
	IF r_c40.c40_compania IS NOT NULL THEN
		CALL eliminar_diario_contable(r_c40.c40_compania,
						r_c40.c40_tipo_comp,
						r_c40.c40_num_comp,
						r_c13.*, 1)
	END IF
	DECLARE q_obtret CURSOR FOR 
		SELECT UNIQUE p28_num_ret
			FROM cxpt028
			WHERE p28_compania  = r_c10.c10_compania
			  AND p28_localidad = r_c10.c10_localidad
			  AND p28_codprov   = r_c10.c10_codprov
			  AND p28_tipo_doc  = 'FA'
			  AND p28_num_doc   = r_c13.c13_factura
	OPEN  q_obtret
	FETCH q_obtret INTO num_ret
	CLOSE q_obtret
	FREE  q_obtret
	IF num_ret IS NOT NULL THEN
		CALL fl_lee_retencion_cxp(r_c13.c13_compania,
						r_c13.c13_localidad, num_ret)
			RETURNING r_p27.*
		IF r_p27.p27_tip_contable IS NOT NULL THEN
			IF r_p27.p27_estado = 'E' THEN
			       CALL eliminar_diario_contable(r_p27.p27_compania,
							r_p27.p27_tip_contable,
							r_p27.p27_num_contable,
							r_c13.*, 2)
			END IF
		END IF
	END IF
	CALL fl_genera_saldos_proveedor(r_c13.c13_compania, r_c13.c13_localidad,
					r_c10.c10_codprov)
END FOREACH

END FUNCTION



FUNCTION eliminar_diario_contable(codcia, tipo_comp, num_comp, r_c13, flag)
DEFINE codcia		LIKE ctbt012.b12_compania
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE flag		SMALLINT
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE mensaje		VARCHAR(250)
DEFINE mens_com		VARCHAR(100)

CALL fl_lee_comprobante_contable(codcia, tipo_comp, num_comp) RETURNING r_b12.*
IF r_b12.b12_compania IS NULL THEN
	CASE flag
		WHEN 1
			LET mens_com = 'contable para la recepción # ',
					r_c13.c13_num_recep USING "<<<<&&"
		WHEN 2
			LET mens_com = 'contable para la retención # ',
					r_c13.c13_num_ret USING "<<<<&&",
					'de la recepción # ',
					r_c13.c13_num_recep USING "<<<<&&"
	END CASE
	LET mensaje = 'No existe en la ctbt012 comprobante',
			mens_com CLIPPED,
			' por orden de compra # ',
			r_c13.c13_numero_oc USING "<<<<<<<&",
			' para el comprobante contable ',
			tipo_comp, '-', num_comp, '.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	RETURN
END IF
IF r_b12.b12_estado = 'E' THEN
	RETURN
END IF
CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
				r_b12.b12_num_comp, 'D')
SET LOCK MODE TO WAIT 5
UPDATE ctbt012 SET b12_estado     = 'E',
		   b12_fec_modifi = CURRENT 
	WHERE b12_compania  = r_b12.b12_compania
	  AND b12_tipo_comp = r_b12.b12_tipo_comp
	  AND b12_num_comp  = r_b12.b12_num_comp

END FUNCTION



FUNCTION cambiar_numero_fact_oc(orden_oc)
DEFINE orden_oc		LIKE ordt010.c10_numero_oc
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE i, lim		INTEGER
DEFINE query		CHAR(800)

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, orden_oc) RETURNING r_c10.*
INITIALIZE r_c13.* TO NULL
DECLARE q_recep CURSOR FOR
	SELECT * FROM ordt013
		WHERE c13_compania  = r_c10.c10_compania
		  AND c13_localidad = r_c10.c10_localidad
		  AND c13_numero_oc = orden_oc
		  AND c13_estado    = 'E'
OPEN q_recep
FETCH q_recep INTO r_c13.*
CLOSE q_recep
FREE q_recep
LET i   = 1
LET lim = LENGTH(r_c13.c13_factura)
CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, r_c10.c10_codprov, 'FA',
				r_c13.c13_factura, 1)
	RETURNING r_p20.*
WHILE TRUE
	LET vm_fact_nue = r_p20.p20_num_doc[1, 3],
				r_p20.p20_num_doc[5, lim] CLIPPED,
				i USING "<<<<<<&"
	CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
					r_c10.c10_codprov, 'FA',
					vm_fact_nue, 1)
		RETURNING r_p20.*
	IF r_p20.p20_compania IS NULL THEN
		EXIT WHILE
	END IF
	LET lim = LENGTH(vm_fact_nue)
	LET i   = i + 1
END WHILE
BEGIN WORK
WHENEVER ERROR STOP 
LET query = 'UPDATE ordt010 ',
		' SET c10_factura = "', vm_fact_nue CLIPPED, '"',
		' WHERE c10_compania  = ', vg_codcia,
		'   AND c10_localidad = ', vg_codloc,
		'   AND c10_numero_oc = ', r_c10.c10_numero_oc
PREPARE exec_up01 FROM query
EXECUTE exec_up01
LET query = 'UPDATE ordt013 ',
		' SET c13_factura  = "', vm_fact_nue CLIPPED, '", ',
		'     c13_num_guia = "', vm_fact_nue CLIPPED, '"',
		' WHERE c13_compania  = ', vg_codcia,
		'   AND c13_localidad = ', vg_codloc,
		'   AND c13_numero_oc = ', r_c10.c10_numero_oc,
		'   AND c13_estado    = "E" ',
		'   AND c13_num_recep = ', r_c13.c13_num_recep
PREPARE exec_up02 FROM query
EXECUTE exec_up02
DECLARE q_p23 CURSOR FOR
	SELECT * FROM cxpt023
		WHERE p23_compania  = vg_codcia
	          AND p23_localidad = vg_codloc
	          AND p23_codprov   = r_c10.c10_codprov
	          AND p23_tipo_doc  = 'FA'
	          AND p23_num_doc   = r_c13.c13_factura
OPEN q_p23
FETCH q_p23 INTO r_p23.*
IF STATUS = NOTFOUND THEN
	LET query = 'UPDATE cxpt020 ',
			' SET p20_num_doc = "', vm_fact_nue CLIPPED, '"',
			' WHERE p20_compania  = ', vg_codcia,
			'   AND p20_localidad = ', vg_codloc,
			'   AND p20_codprov   = ', r_c10.c10_codprov,
			'   AND p20_tipo_doc  = "FA" ',
			'   AND p20_num_doc   = "', r_c13.c13_factura, '"'
	PREPARE exec_up03 FROM query
	EXECUTE exec_up03
	COMMIT WORK
	RETURN
END IF
SELECT * FROM cxpt020
	WHERE p20_compania  = vg_codcia
          AND p20_localidad = vg_codloc
          AND p20_codprov   = r_c10.c10_codprov
          AND p20_tipo_doc  = 'FA'
          AND p20_num_doc   = r_c13.c13_factura
	INTO TEMP tmp_p20
LET query = 'UPDATE tmp_p20 ',
		' SET p20_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p20_compania  = ', vg_codcia,
		'   AND p20_localidad = ', vg_codloc,
		'   AND p20_codprov   = ', r_c10.c10_codprov,
		'   AND p20_tipo_doc  = "FA" ',
		'   AND p20_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up04 FROM query
EXECUTE exec_up04
INSERT INTO cxpt020 SELECT * FROM tmp_p20
LET query = 'UPDATE cxpt023 ',
		' SET p23_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p23_compania  = ', vg_codcia,
		'   AND p23_localidad = ', vg_codloc,
		'   AND p23_codprov   = ', r_c10.c10_codprov,
		'   AND p23_tipo_doc  = "FA" ',
		'   AND p23_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up05 FROM query
EXECUTE exec_up05
LET query = 'UPDATE cxpt025 ',
		' SET p25_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p25_compania  = ', vg_codcia,
		'   AND p25_localidad = ', vg_codloc,
		'   AND p25_codprov   = ', r_c10.c10_codprov,
		'   AND p25_tipo_doc  = "FA" ',
		'   AND p25_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up06 FROM query
EXECUTE exec_up06
LET query = 'UPDATE cxpt028 ',
		' SET p28_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p28_compania  = ', vg_codcia,
		'   AND p28_localidad = ', vg_codloc,
		'   AND p28_codprov   = ', r_c10.c10_codprov,
		'   AND p28_tipo_doc  = "FA" ',
		'   AND p28_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up07 FROM query
EXECUTE exec_up07
LET query = 'UPDATE cxpt041 ',
		' SET p41_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p41_compania  = ', vg_codcia,
		'   AND p41_localidad = ', vg_codloc,
		'   AND p41_codprov   = ', r_c10.c10_codprov,
		'   AND p41_tipo_doc  = "FA" ',
		'   AND p41_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up08 FROM query
EXECUTE exec_up08
LET query = 'DELETE FROM cxpt020 ',
		' WHERE p20_compania  = ', vg_codcia,
		'   AND p20_localidad = ', vg_codloc,
		'   AND p20_codprov   = ', r_c10.c10_codprov,
		'   AND p20_tipo_doc  = "FA" ',
		'   AND p20_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_del01 FROM query
EXECUTE exec_del01
WHENEVER ERROR STOP 
COMMIT WORK
DROP TABLE tmp_p20

END FUNCTION



FUNCTION generar_num_sri()
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE num_sri		LIKE cxct021.z21_num_sri
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE cuantos		SMALLINT

WHENEVER ERROR CONTINUE
DECLARE q_sri CURSOR FOR
	SELECT * FROM gent037
		WHERE g37_compania   = vg_codcia
		  AND g37_localidad  = vg_codloc
		  AND g37_tipo_doc   = "NC"
  		  AND g37_cont_cred  = "N"
		  AND g37_secuencia IN
		(SELECT MAX(g37_secuencia)
			FROM gent037
			WHERE g37_compania  = vg_codcia
			  AND g37_localidad = vg_codloc
			  AND g37_tipo_doc  = "NC")
	FOR UPDATE
OPEN q_sri
FETCH q_sri INTO r_g37.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, porque ésta secuencia se encuentra bloqueada por otro usuario.','stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
LET num_sri = r_g37.g37_pref_sucurs, '-', r_g37.g37_pref_pto_vta, '-',
			r_g37.g37_sec_num_sri + 1 USING "&&&&&&&&&"
LET cuantos = 8 + r_g37.g37_num_dig_sri
LET sec_sri = num_sri[9, cuantos] USING "########"
WHENEVER ERROR CONTINUE
UPDATE gent037
	SET g37_sec_num_sri = sec_sri
	WHERE g37_compania     = r_g37.g37_compania
	  AND g37_localidad    = r_g37.g37_localidad
	  AND g37_tipo_doc     = r_g37.g37_tipo_doc
	  AND g37_secuencia    = r_g37.g37_secuencia
	  AND g37_sec_num_sri <= sec_sri
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo actualizar el No. del SRI en el control de secuencias SRI. Por favor llame al administrador.','stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
RETURN num_sri

END FUNCTION



FUNCTION control_imprimir()
DEFINE r_t28		RECORD LIKE talt028.*
DEFINE param		VARCHAR(60)

INITIALIZE r_t28.* TO NULL
SELECT * INTO r_t28.*
	FROM talt028
	WHERE t28_compania  = rm_t23.t23_compania
	  AND t28_localidad = rm_t23.t23_localidad
	  AND t28_ot_ant    = rm_t23.t23_orden
LET param = ' ', r_t28.t28_num_dev
CALL ejecuta_comando('TALLER', vg_modulo, 'talp413 ', param)

END FUNCTION



FUNCTION ver_orden_compra(numero_oc)
DEFINE numero_oc	LIKE ordt010.c10_numero_oc
DEFINE param		VARCHAR(100)

LET param = numero_oc
CALL ejecuta_comando('COMPRAS', 'OC', 'ordp200 ', param)

END FUNCTION



FUNCTION generar_doc_elec()
DEFINE comando		VARCHAR(250)
DEFINE servid		VARCHAR(10)
DEFINE mensaje		VARCHAR(250)

LET servid  = FGL_GETENV("INFORMIXSERVER")
CASE servid
	WHEN "ACGYE01"
		LET servid = "idsgye01"
	WHEN "ACUIO01"
		LET servid = "idsuio01"
	WHEN "ACUIO02"
		LET servid = "idsuio02"
END CASE
LET comando = "fglgo gen_tra_ele ", vg_base CLIPPED, " ", servid CLIPPED, " ",
		vg_codcia, " ", vg_codloc, " D ", rm_t28.t28_num_dev, " NCT "
RUN comando
LET mensaje = FGL_GETENV("HOME"), '/tmp/NC_ELEC/'
CALL fl_mostrar_mensaje('Archivo XML de DEVOLUCION Generado en: ' || mensaje, 'info')

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



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Orden Compra'             AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
