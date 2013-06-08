--------------------------------------------------------------------------------
-- Titulo              : talp216.4gl -- CIERRE MENSUAL DE TALLER
-- Elaboracion         : 16-Mar-2009
-- Autor               : NPC
-- Formato de Ejecucion: fglrun talp216 base modulo compania localidad
-- Ultima Correccion   : 
-- Motivo Correccion   : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_anio		VARCHAR(4)
DEFINE vm_mes		VARCHAR(2)
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_t23		RECORD LIKE talt023.*
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
DEFINE vm_fact_nue	LIKE ordt013.c13_factura
DEFINE vm_cuantos	INTEGER



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp216.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
	CALL fl_mostrar_mensaje('Número de paráametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'talp216'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE resp 		VARCHAR(6)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE mens_mes 	VARCHAR(20)

CALL fl_nivel_isolation()
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
IF rm_t00.t00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuración para esta compania.','stop')
	EXIT PROGRAM
END IF
LET max_row_oc = 300
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 8
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_talf216_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_talf216_1 FROM '../forms/talf216_1'
ELSE
	OPEN FORM f_talf216_1 FROM '../forms/talf216_1c'
END IF
DISPLAY FORM f_talf216_1
LET vm_anio = YEAR(TODAY)
LET vm_mes  = MONTH(TODAY)
IF rm_t00.t00_anopro IS NOT NULL THEN
	LET vm_anio = rm_t00.t00_anopro
	LET vm_mes  = rm_t00.t00_mespro
END IF
DISPLAY BY NAME vm_anio, vm_mes
LET mens_mes = fl_retorna_nombre_mes(vm_mes)
DISPLAY mens_mes TO nom_mes
MENU 'OPCIONES'
	COMMAND KEY('C') 'Cerrar Mes'
		CALL fl_hacer_pregunta('Esta seguro que desea realizar el cierre del mes de TALLER.','No')
			RETURNING resp
		IF resp = 'Yes' THEN
			IF NOT validar_mes(vm_anio, vm_mes) THEN
				RETURN
			END IF
			IF control_cerrar_mes() THEN
				HIDE OPTION 'Cerrar Mes'
			END IF
		END IF 
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION validar_mes(anho, mes)
DEFINE anho		LIKE talt000.t00_anopro
DEFINE mes		LIKE talt000.t00_mespro
DEFINE dia, mes2, anho2	SMALLINT
DEFINE fecha		DATE

IF anho < YEAR(TODAY) THEN
	RETURN 1
ELSE
	IF mes < MONTH(TODAY) THEN
		RETURN 1
	END IF
END IF
IF mes = 12 THEN
	LET mes2  = 1
	LET anho2 = anho + 1
ELSE
	LET mes2  = mes + 1
	LET anho2 = anho
END IF
LET fecha = MDY(mes2, 01, anho2)
LET fecha = fecha - 1
IF TODAY < fecha THEN
	CALL fl_mostrar_mensaje('Aún no se puede cerrar el mes.','exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION control_cerrar_mes()
DEFINE orden_oc		LIKE ordt010.c10_numero_oc

INITIALIZE rm_t00.* TO NULL
SELECT c10_numero_oc num_oc
	FROM ordt010
	WHERE c10_compania = 999
	INTO TEMP tmp_oc
BEGIN WORK
	IF NOT proceso_cierre_mes() THEN
		ROLLBACK WORK
		DROP TABLE tmp_oc
		RETURN 0
	END IF
COMMIT WORK
DECLARE q_oc CURSOR FOR SELECT * FROM tmp_oc ORDER BY 1
FOREACH q_oc INTO orden_oc
	CALL eliminar_diarios_contables_recep_reten_oc_anuladas(orden_oc)
END FOREACH
DROP TABLE tmp_oc
CALL fl_mostrar_mensaje('Cierre Mensual Realizado Ok.', 'info')
RETURN 1

END FUNCTION



FUNCTION proceso_cierre_mes()

WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 5
DECLARE q_talt000 CURSOR FOR
	SELECT * FROM talt000
		WHERE t00_compania = vg_codcia
	FOR UPDATE
OPEN q_talt000
FETCH q_talt000 INTO rm_t00.*
IF STATUS < 0 THEN
	SET LOCK MODE TO NOT WAIT
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT
IF NOT eliminar_presupuestos_activos() THEN
	WHENEVER ERROR STOP
	RETURN 0
END IF
CALL preparar_tabla_de_trabajo()
IF NOT registrar_log_cierre_tal() THEN
	WHENEVER ERROR STOP
	DROP TABLE tmp_det
	RETURN 0
END IF
IF NOT control_eliminacion_ot() THEN
	WHENEVER ERROR STOP
	DROP TABLE tmp_det
	RETURN 0
END IF
IF NOT actualizar_anomes_proceso() THEN
	WHENEVER ERROR STOP
	DROP TABLE tmp_det
	RETURN 0
END IF
DROP TABLE tmp_det
RETURN 1

END FUNCTION



FUNCTION eliminar_presupuestos_activos()
DEFINE fec_eli		DATE

LET fec_eli = (MDY(rm_t00.t00_mespro, 01, rm_t00.t00_anopro)
		+ 1 UNITS MONTH - 1 UNITS DAY)
		- rm_t00.t00_dias_pres UNITS DAY
WHENEVER ERROR CONTINUE
UPDATE talt020
	SET t20_estado     = 'E',
	    t20_usu_elimin = vg_usuario,
	    t20_fec_elimin = CURRENT
	WHERE t20_compania     = vg_codcia
	  AND t20_localidad    = vg_codloc
	  AND t20_estado       = 'A'
	  AND DATE(t20_fecing) < fec_eli
IF STATUS <> 0 THEN
	CALL fl_mostrar_mensaje('ERROR: Registro no se puede ELIMINAR los presupuestos viejos. Llame al ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP
RETURN 1

END FUNCTION



FUNCTION preparar_tabla_de_trabajo()
DEFINE query		CHAR(6000)

SELECT DATE(t23_fecing) fecha_tran, t23_orden ord_t, t23_tot_bruto valor_mo,
	t23_tot_bruto valor_fa, t23_tot_bruto valor_oc, t23_tot_bruto valor_tot,
	t23_estado est, t23_cod_cliente codcli
	FROM talt023
	WHERE t23_compania = 999
	INTO TEMP tmp_det
LET query = "INSERT INTO tmp_det ",
		"SELECT DATE(t23_fecing), t23_orden, t23_val_mo_tal, ",
		" CASE WHEN t23_estado = 'C' THEN ",
			"(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)",
			" * (1 + c10_recargo / 100), 2)), 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'S') + ",
			"(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)",
			" - c11_val_descto) * (1 + c10_recargo / 100), 2))",
			", 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'B') + ",
			" CASE WHEN (SELECT COUNT(*) FROM ordt010 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c10_estado      = 'C') = 0 ",
			" THEN (t23_val_rp_tal + t23_val_rp_ext + ",
			       "t23_val_rp_cti + t23_val_otros2) ",
			" ELSE 0.00 ",
			" END ",
		" ELSE (t23_val_mo_ext + t23_val_mo_cti + ",
			"t23_val_rp_tal + t23_val_rp_ext + ",
			"t23_val_rp_cti + t23_val_otros2) ",
		" END tot_oc, ",
		" (SELECT NVL(SUM(r21_tot_bruto - r21_tot_dscto), 0) ",
			" FROM rept021 ",
			" WHERE r21_compania  = t23_compania ",
			"   AND r21_localidad = t23_localidad ",
			"   AND r21_num_ot    = t23_orden), ",
		" t23_val_mo_tal + ",
		" CASE WHEN t23_estado = 'C' THEN ",
			"(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)",
			" * (1 + c10_recargo / 100), 2)), 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'S') + ",
			"(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)",
			" - c11_val_descto) * (1 + c10_recargo / 100), 2)),0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'B') + ",
			" CASE WHEN (SELECT COUNT(*) FROM ordt010 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c10_estado      = 'C') = 0 ",
			" THEN (t23_val_rp_tal + t23_val_rp_ext + ",
			       "t23_val_rp_cti + t23_val_otros2) ",
			" ELSE 0.00 ",
			" END ",
		" ELSE (t23_val_mo_ext + t23_val_mo_cti + ",
			"t23_val_rp_tal + t23_val_rp_ext + ",
			"t23_val_rp_cti + t23_val_otros2) ",
		" END + ",
		" (SELECT NVL(SUM(r21_tot_bruto - r21_tot_dscto), 0) ",
			" FROM rept021 ",
			" WHERE r21_compania  = t23_compania ",
			"   AND r21_localidad = t23_localidad ",
			"   AND r21_num_ot    = t23_orden), ",
		" t23_estado, t23_cod_cliente ",
		" FROM talt023 ",
		" WHERE t23_compania   = ", vg_codcia,
		"   AND t23_localidad  = ", vg_codloc,
		"   AND t23_estado    IN ('A', 'C') ",
		" GROUP BY 1, 2, 3, 4, 5, 6, 7, 8 "
PREPARE cons_tmp FROM query
EXECUTE cons_tmp

END FUNCTION



FUNCTION registrar_log_cierre_tal()
DEFINE query		CHAR(800)

WHENEVER ERROR CONTINUE
DELETE FROM talt042
	WHERE t42_compania = vg_codcia
	  AND t42_ano      = vm_anio
	  AND t42_mes      = vm_mes
LET query = 'INSERT INTO talt042',
		' SELECT ', vg_codcia, ', ', vg_codloc, ', ', vm_anio, ', ',
			vm_mes, ', ord_t, est, fecha_tran, codcli, valor_mo,',
			' valor_oc, valor_fa, valor_tot, "', vg_usuario CLIPPED,
			'", "', EXTEND(CURRENT, YEAR TO SECOND), '" ',
		' FROM tmp_det '
PREPARE sentencia FROM query
EXECUTE sentencia
IF STATUS < 0 THEN
	CALL fl_mostrar_mensaje('Ha ocurrido un error: Proceso no se realizo. Por favor llame al ADMINISTRADOR.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP
RETURN 1

END FUNCTION



FUNCTION registros_para_eliminar_ot_tmp()
DEFINE fec_eli		DATE

LET fec_eli = MDY(rm_t00.t00_mespro, 01, rm_t00.t00_anopro)
IF rm_t00.t00_elim_mes = 'N' THEN
	LET fec_eli = fec_eli + 1 UNITS MONTH - 1 UNITS DAY
ELSE
	LET fec_eli = fec_eli - 1 UNITS DAY
END IF
LET fec_eli = fec_eli - rm_t00.t00_dias_elim UNITS DAY
SQL
	SELECT ord_t ord_tra
		FROM tmp_det
		WHERE fecha_tran >= $fec_eli
		INTO TEMP t1
END SQL
DELETE FROM tmp_det
	WHERE EXISTS
		(SELECT 1 FROM t1
			WHERE t1.ord_tra = tmp_det.ord_t)
DROP TABLE t1

END FUNCTION



FUNCTION control_eliminacion_ot()
DEFINE elimino, i	SMALLINT
DEFINE cuantos		INTEGER
DEFINE ord_trab		LIKE talt023.t23_orden

CALL registros_para_eliminar_ot_tmp()
SELECT COUNT(*) INTO cuantos FROM tmp_det
IF cuantos = 0 THEN
	RETURN 1
END IF
DECLARE q_tmp CURSOR FOR SELECT ord_t FROM tmp_det ORDER BY ord_t
LET elimino = 0
FOREACH q_tmp INTO ord_trab
	CALL eliminar_orden_trabajo(ord_trab, cuantos) RETURNING elimino
	IF NOT elimino AND cuantos > 1 THEN
		EXIT FOREACH
	END IF
END FOREACH
IF cuantos > 1 AND elimino THEN
	CALL fl_mostrar_mensaje('Ordenes de Trabajo han sido ELIMINADAS.', 'info')
END IF
RETURN elimino

END FUNCTION



FUNCTION eliminar_orden_trabajo(ord_trab, cuantos)
DEFINE ord_trab		LIKE talt023.t23_orden
DEFINE cuantos		INTEGER
DEFINE mensaje		VARCHAR(150)

WHENEVER ERROR CONTINUE
DECLARE q_blo CURSOR FOR
	SELECT * FROM talt023
		WHERE t23_compania  = vg_codcia
		  AND t23_localidad = vg_codloc
		  AND t23_orden     = ord_trab
	      	FOR UPDATE
OPEN q_blo
FETCH q_blo INTO rm_t23.*
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 0
END IF
IF NOT generar_transferencias_retorno(cuantos) THEN
	WHENEVER ERROR STOP
	RETURN 0
END IF
CALL control_anular_ordenes_de_compras()
UPDATE talt023
	SET t23_estado     = 'E',
	    t23_fec_elimin = CURRENT,
	    t23_usu_elimin = vg_usuario
	WHERE CURRENT OF q_blo
WHENEVER ERROR STOP	
IF cuantos = 1 THEN
	LET mensaje = 'Orden de Trabajo ', ord_trab USING "<<<<<&",
			' ha sido ELIMINADA.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
END IF
RETURN 1

END FUNCTION



FUNCTION generar_transferencias_retorno(ctos)
DEFINE ctos		INTEGER
DEFINE r_transf		RECORD LIKE rept019.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE i		LIKE rept020.r20_orden
DEFINE item		LIKE rept011.r11_item
DEFINE cantidad		LIKE rept011.r11_stock_act
DEFINE cuantos		INTEGER
DEFINE resul, resul2	SMALLINT
DEFINE mensaje 		VARCHAR(200)

LET cod_tran = 'TR'
SELECT * FROM rept019 d
	WHERE d.r19_compania    = vg_codcia
	  AND d.r19_localidad   = vg_codloc
	  AND d.r19_cod_tran    = cod_tran
	  AND d.r19_ord_trabajo = rm_t23.t23_orden
	  AND EXISTS
		(SELECT * FROM rept020 a
			WHERE a.r20_compania  = d.r19_compania
			  AND a.r20_localidad = d.r19_localidad
			  AND a.r20_cod_tran  = d.r19_cod_tran
			  AND a.r20_num_tran  = d.r19_num_tran
			  AND a.r20_item     NOT IN
				(SELECT c.r20_item
					FROM rept019 b, rept020 c
					WHERE b.r19_compania  = a.r20_compania
					  AND b.r19_localidad = a.r20_localidad
					  AND b.r19_cod_tran  IN ("FA", "DF",
									"AF")
				        AND b.r19_ord_trabajo =d.r19_ord_trabajo
					  AND c.r20_compania  = b.r19_compania
					  AND c.r20_localidad = b.r19_localidad
					  AND c.r20_cod_tran  = b.r19_cod_tran
					  AND c.r20_num_tran  = b.r19_num_tran))
	INTO TEMP t_r19
SELECT COUNT(*) INTO cuantos FROM t_r19
IF cuantos = 0 THEN
	DROP TABLE t_r19
	IF ctos = 1 THEN
		LET mensaje = 'No hay material que retornar en OT: ',
				rm_t23.t23_orden USING "<<<<<<&"
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
	END IF
	RETURN 1
END IF
LET vm_cuantos = 0
IF NOT generar_tr_ajuste_para_stock_act(ctos) THEN
	DROP TABLE t_r19
	RETURN 0
END IF
DECLARE qu_transf CURSOR FOR SELECT * FROM t_r19 ORDER BY r19_num_tran
LET resul = 1
FOREACH qu_transf INTO r_transf.*
	INITIALIZE r_r19.*, r_r20.* TO NULL
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE', 'AA',
						cod_tran)
		RETURNING num_tran
	IF num_tran <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_r19.r19_compania   = vg_codcia
    	LET r_r19.r19_localidad  = vg_codloc
    	LET r_r19.r19_cod_tran   = cod_tran
    	LET r_r19.r19_num_tran   = num_tran
    	LET r_r19.r19_cont_cred  = 'C'
    	LET r_r19.r19_referencia = 'OT: ', rm_t23.t23_orden USING '<<<<<&',
				' ', r_transf.r19_cod_tran CLIPPED, '-',
				r_transf.r19_num_tran USING '<<<<<&',
				'. POR ELIM. CIERRE TAL.'
    	LET r_r19.r19_codcli 	= rm_t23.t23_cod_cliente
    	LET r_r19.r19_nomcli 	= rm_t23.t23_nom_cliente
    	LET r_r19.r19_dircli 	= rm_t23.t23_dir_cliente
    	LET r_r19.r19_telcli 	= rm_t23.t23_tel_cliente
    	LET r_r19.r19_cedruc 	= rm_t23.t23_cedruc
	DECLARE qu_ven CURSOR FOR
		SELECT r01_codigo FROM rept001
			WHERE r01_compania   = vg_codcia
			  AND r01_estado     = 'A'
			  AND r01_user_owner = vg_usuario
	OPEN qu_ven
	FETCH qu_ven INTO r_r19.r19_vendedor
	CLOSE qu_ven
	FREE qu_ven
	IF r_r19.r19_vendedor IS NULL THEN
		CALL fl_mostrar_mensaje('El Usuario ' || vg_usuario CLIPPED || ' no tiene Código de Vendedor asignado. Por favor consulte con el ADMINISTRADOR.', 'stop')
		LET resul = 0
		EXIT FOREACH
	END IF
    	LET r_r19.r19_ord_trabajo = rm_t23.t23_orden
    	LET r_r19.r19_descuento   = 0
    	LET r_r19.r19_porc_impto  = 0
    	LET r_r19.r19_tipo_dev    = r_transf.r19_cod_tran
    	LET r_r19.r19_num_dev     = r_transf.r19_num_tran
    	LET r_r19.r19_bodega_ori  = r_transf.r19_bodega_dest
    	LET r_r19.r19_bodega_dest = r_transf.r19_bodega_ori
    	LET r_r19.r19_moneda 	  = rm_t23.t23_moneda
	LET r_r19.r19_paridad     = rg_gen.g00_decimal_mb
    	LET r_r19.r19_precision   = rm_t23.t23_precision
    	LET r_r19.r19_tot_costo   = 0
    	LET r_r19.r19_tot_bruto   = 0
    	LET r_r19.r19_tot_dscto   = 0
    	LET r_r19.r19_tot_neto 	  = 0
    	LET r_r19.r19_flete 	  = 0
    	LET r_r19.r19_usuario 	  = vg_usuario
    	LET r_r19.r19_fecing 	  = CURRENT
	INSERT INTO rept019 VALUES (r_r19.*)
	DECLARE qu_dettr CURSOR FOR
		SELECT r20_item, r20_cant_ven, r20_orden
			FROM rept020
			WHERE r20_compania  = r_transf.r19_compania
			  AND r20_localidad = r_transf.r19_localidad
			  AND r20_cod_tran  = r_transf.r19_cod_tran
			  AND r20_num_tran  = r_transf.r19_num_tran
			ORDER BY r20_orden
	LET i = 0
	FOREACH qu_dettr INTO item, cantidad, i
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF
		LET mensaje = 'ITEM: ', item
 		IF r_r11.r11_stock_act <= 0 THEN
			LET mensaje = mensaje CLIPPED,
				' no tiene stock y se nesecita: ',
				cantidad USING '####&', '. No puede eliminar ',
				'esta Orden de Trabajo.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			LET resul = 0
			EXIT FOREACH
		END IF
 		IF r_r11.r11_stock_act < cantidad THEN
			LET mensaje = mensaje CLIPPED, ' solo tiene stock: ',
				r_r11.r11_stock_act USING '####&', 
				' y se nesecita: ', cantidad USING '####&',
				'. No puede eliminar esta Orden de Trabajo.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			LET resul = 0
			EXIT FOREACH
		END IF
    		LET r_r20.r20_compania 	 = r_r19.r19_compania
    		LET r_r20.r20_localidad	 = r_r19.r19_localidad
    		LET r_r20.r20_cod_tran 	 = r_r19.r19_cod_tran
    		LET r_r20.r20_num_tran 	 = r_r19.r19_num_tran
    		LET r_r20.r20_bodega 	 = r_r19.r19_bodega_ori
    		LET r_r20.r20_item 	 = item
    		LET r_r20.r20_orden 	 = i
    		LET r_r20.r20_cant_ped 	 = cantidad
    		LET r_r20.r20_cant_ven   = cantidad
    		LET r_r20.r20_cant_dev 	 = 0
    		LET r_r20.r20_cant_ent   = 0
    		LET r_r20.r20_descuento  = 0
    		LET r_r20.r20_val_descto = 0
		CALL fl_lee_item(r_r19.r19_compania, item) RETURNING r_r10.*
    		LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
    		LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
    		LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
    		LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
		IF r_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
			LET r_r10.r10_precio_mb = r_r10.r10_precio_ma
			LET r_r10.r10_costo_mb  = r_r10.r10_costo_ma
		END IF	
    		LET r_r20.r20_precio 	 = r_r10.r10_precio_mb
    		LET r_r20.r20_val_impto  = 0
    		LET r_r20.r20_costo 	 = r_r10.r10_costo_mb
    		LET r_r20.r20_fob 	 = r_r10.r10_fob
    		LET r_r20.r20_linea 	 = r_r10.r10_linea
    		LET r_r20.r20_rotacion 	 = r_r10.r10_rotacion
    		LET r_r20.r20_ubicacion  = '.'
    		LET r_r20.r20_stock_ant  = r_r11.r11_stock_act
		UPDATE rept011
			SET r11_stock_act = r11_stock_act - cantidad,
		            r11_egr_dia   = r11_egr_dia   + cantidad
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_ori
			  AND r11_item     = item 
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
    			LET r_r11.r11_stock_act = 0
			INSERT INTO rept011
				(r11_compania, r11_bodega, r11_item,
				 r11_ubicacion, r11_stock_ant, r11_stock_act,
				 r11_ing_dia, r11_egr_dia)
				VALUES(vg_codcia, r_r19.r19_bodega_dest,
					item, 'SN', 0, 0, 0, 0) 
		END IF
    		LET r_r20.r20_stock_bd   = r_r11.r11_stock_act
    		LET r_r20.r20_fecing     = CURRENT
		INSERT INTO rept020 VALUES (r_r20.*)
		UPDATE rept011
			SET r11_stock_act = r11_stock_act + cantidad,
			    r11_ing_dia   = r11_ing_dia   + cantidad
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_dest
			  AND r11_item     = item
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
					(cantidad * r_r20.r20_costo)
	END FOREACH
	IF NOT resul THEN
		EXIT FOREACH
	END IF
	IF i = 0 OR i IS NULL THEN
		DELETE FROM rept019
			WHERE r19_compania  = r_r19.r19_compania
			  AND r19_localidad = r_r19.r19_localidad
			  AND r19_cod_tran  = r_r19.r19_cod_tran
			  AND r19_num_tran  = r_r19.r19_num_tran
	ELSE
		UPDATE rept019
			SET r19_tot_costo = r_r19.r19_tot_costo,
			    r19_tot_bruto = r_r19.r19_tot_costo,
			    r19_tot_neto  = r_r19.r19_tot_costo
			WHERE r19_compania  = r_r19.r19_compania
			  AND r19_localidad = r_r19.r19_localidad
			  AND r19_cod_tran  = r_r19.r19_cod_tran
			  AND r19_num_tran  = r_r19.r19_num_tran 
		IF ctos = 1 THEN
			LET mensaje = 'Se genero la transferencia: ',
					r_r19.r19_num_tran USING "<<<<<<&", '.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
		END IF
		CALL imprimir_transferencia(r_r19.r19_cod_tran,
						r_r19.r19_num_tran)
	END IF
END FOREACH
DROP TABLE t_r19
IF vm_cuantos > 0 THEN
	CALL transaccion_aj('A-', ctos) RETURNING resul2
	DROP TABLE tmp_aj
END IF
RETURN resul

END FUNCTION



FUNCTION generar_tr_ajuste_para_stock_act(ctos)
DEFINE ctos		INTEGER
DEFINE r_transf		RECORD
				cia		LIKE rept019.r19_compania,
				loc		LIKE rept019.r19_localidad,
				tp		LIKE rept019.r19_cod_tran,
				num		LIKE rept019.r19_num_tran,
				bd_o		LIKE rept019.r19_bodega_ori,
				bd_d		LIKE rept019.r19_bodega_dest
			END RECORD
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE i		LIKE rept020.r20_orden
DEFINE item		LIKE rept011.r11_item
DEFINE cantidad		LIKE rept011.r11_stock_act
DEFINE cuantos		INTEGER
DEFINE resul		SMALLINT
DEFINE mensaje 		VARCHAR(200)

SELECT r20_item item_t2, NVL(SUM(r20_cant_ven), 0) tot_item
	FROM t_r19, rept020
	WHERE r20_compania  = r19_compania
	  AND r20_localidad = r19_localidad
	  AND r20_cod_tran  = r19_cod_tran
	  AND r20_num_tran  = r19_num_tran
	GROUP BY 1
	INTO TEMP tmp_ite
SELECT r19_compania cia, r19_localidad loc, r19_cod_tran tp, r19_num_tran num_t,
	r19_bodega_ori bd_o, r19_bodega_dest bd_d, r20_item item_t,
	r20_orden orden_t, r20_cant_ven cant_tr
	FROM t_r19, rept020, tmp_ite
	WHERE r20_compania  = r19_compania
	  AND r20_localidad = r19_localidad
	  AND r20_cod_tran  = r19_cod_tran
	  AND r20_num_tran  = r19_num_tran
	  AND item_t2       = r20_item
	  AND tot_item      > (NVL((SELECT r11_stock_act
					FROM rept011
					WHERE r11_compania = r19_compania
					  AND r11_bodega   = r19_bodega_dest
					  AND r11_item     = r20_item), 0))
	INTO TEMP tmp_tr
DROP TABLE tmp_ite
SELECT COUNT(*) INTO cuantos FROM tmp_tr
IF cuantos = 0 THEN
	DROP TABLE tmp_tr
	RETURN 1
END IF
SELECT cia cia2, loc loc2, tp tp2, num_t num2, bd_o, bd_d, item_t item2,
	orden_t ord2,
	(cant_tr - NVL((SELECT r11_stock_act
			FROM rept011
			WHERE r11_compania = cia
			  AND r11_bodega   = bd_o
			  AND r11_item     = item_t), 0)) cant_aj
	FROM tmp_tr
	WHERE cant_tr > (NVL((SELECT r11_stock_act
			FROM rept011
			WHERE r11_compania = cia
			  AND r11_bodega   = bd_o
			  AND r11_item     = item_t), 0))
	INTO TEMP tmp_aj
SELECT COUNT(*) INTO vm_cuantos FROM tmp_aj
IF vm_cuantos = 0 THEN
	DROP TABLE tmp_aj
ELSE
	UPDATE tmp_tr
		SET cant_tr = cant_tr - (NVL((SELECT cant_aj
						FROM tmp_aj
						WHERE cia2  = cia
						  AND loc2  = loc
						  AND tp2   = tp
						  AND num2  = num_t
						  AND item2 = item_t
						  AND ord2  = orden_t), 0))
		WHERE EXISTS (SELECT * FROM tmp_aj
				WHERE cia2 = cia
				  AND loc2 = loc
				  AND tp2  = tp
				  AND num2 = num_t)
	DELETE FROM tmp_tr WHERE (cant_tr <= 0 OR cant_tr IS NULL)
	CALL transaccion_aj('A+', ctos) RETURNING resul
END IF
LET cod_tran = 'TR'
DECLARE qu_transf2 CURSOR FOR
	SELECT UNIQUE cia, loc, tp, num_t, bd_o, bd_d
		FROM tmp_tr
		ORDER BY num_t
LET resul = 1
FOREACH qu_transf2 INTO r_transf.*
	INITIALIZE r_r19.*, r_r20.* TO NULL
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE', 'AA',
						cod_tran)
		RETURNING num_tran
	IF num_tran <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_r19.r19_compania   = vg_codcia
    	LET r_r19.r19_localidad  = vg_codloc
    	LET r_r19.r19_cod_tran   = cod_tran
    	LET r_r19.r19_num_tran   = num_tran
    	LET r_r19.r19_cont_cred  = 'C'
    	LET r_r19.r19_referencia = 'OT: ', rm_t23.t23_orden USING '<<<<<&',
				' ', r_transf.tp CLIPPED, '-',
				r_transf.num USING '<<<<<&',
				'. POR TRASPASO EN OT'
    	LET r_r19.r19_codcli 	= rm_t23.t23_cod_cliente
    	LET r_r19.r19_nomcli 	= rm_t23.t23_nom_cliente
    	LET r_r19.r19_dircli 	= rm_t23.t23_dir_cliente
    	LET r_r19.r19_telcli 	= rm_t23.t23_tel_cliente
    	LET r_r19.r19_cedruc 	= rm_t23.t23_cedruc
	DECLARE qu_ven2 CURSOR FOR
		SELECT r01_codigo
			FROM rept001
			WHERE r01_compania   = vg_codcia
			  AND r01_estado     = 'A'
			  AND r01_user_owner = vg_usuario
	OPEN qu_ven2
	FETCH qu_ven2 INTO r_r19.r19_vendedor
	CLOSE qu_ven2
	FREE qu_ven2
	IF r_r19.r19_vendedor IS NULL THEN
		CALL fl_mostrar_mensaje('El Usuario ' || vg_usuario CLIPPED || ' no tiene Código de Vendedor asignado. Por favor consulte con el ADMINISTRADOR.', 'stop')
		LET resul = 0
		EXIT FOREACH
	END IF
    	LET r_r19.r19_ord_trabajo = rm_t23.t23_orden
    	LET r_r19.r19_descuento   = 0
    	LET r_r19.r19_porc_impto  = 0
    	LET r_r19.r19_tipo_dev    = r_transf.tp
    	LET r_r19.r19_num_dev     = r_transf.num
    	LET r_r19.r19_bodega_ori  = r_transf.bd_o
    	LET r_r19.r19_bodega_dest = r_transf.bd_d
    	LET r_r19.r19_moneda 	  = rm_t23.t23_moneda
	LET r_r19.r19_paridad     = rg_gen.g00_decimal_mb
    	LET r_r19.r19_precision   = rm_t23.t23_precision
    	LET r_r19.r19_tot_costo   = 0
    	LET r_r19.r19_tot_bruto   = 0
    	LET r_r19.r19_tot_dscto   = 0
    	LET r_r19.r19_tot_neto 	  = 0
    	LET r_r19.r19_flete 	  = 0
    	LET r_r19.r19_usuario 	  = vg_usuario
    	LET r_r19.r19_fecing 	  = CURRENT
	INSERT INTO rept019 VALUES (r_r19.*)
	DECLARE qu_dettr2 CURSOR FOR
		SELECT item_t, cant_tr, orden_t
			FROM tmp_tr
			WHERE cia   = r_transf.cia
			  AND loc   = r_transf.loc
			  AND tp    = r_transf.tp
			  AND num_t = r_transf.num
			ORDER BY orden_t
	LET i = 0
	FOREACH qu_dettr2 INTO item, cantidad, i
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF
		LET mensaje = 'ITEM: ', item
 		IF r_r11.r11_stock_act <= 0 THEN
			LET mensaje = mensaje CLIPPED,
				' no tiene stock y se nesecita: ',
				cantidad USING '####&', '. No puede traspasar ',
				'a esta Orden de Trabajo.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			LET resul = 0
			EXIT FOREACH
		END IF
 		IF r_r11.r11_stock_act < cantidad THEN
			LET mensaje = mensaje CLIPPED, ' solo tiene stock: ',
				r_r11.r11_stock_act USING '####&', 
				' y se nesecita: ', cantidad USING '####&',
				'. No puede traspasar a esta Orden de Trabajo.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			LET resul = 0
			EXIT FOREACH
		END IF
    		LET r_r20.r20_compania 	 = r_r19.r19_compania
    		LET r_r20.r20_localidad	 = r_r19.r19_localidad
    		LET r_r20.r20_cod_tran 	 = r_r19.r19_cod_tran
    		LET r_r20.r20_num_tran 	 = r_r19.r19_num_tran
    		LET r_r20.r20_bodega 	 = r_r19.r19_bodega_ori
    		LET r_r20.r20_item 	 = item
    		LET r_r20.r20_orden 	 = i
    		LET r_r20.r20_cant_ped 	 = cantidad
    		LET r_r20.r20_cant_ven   = cantidad
    		LET r_r20.r20_cant_dev 	 = 0
    		LET r_r20.r20_cant_ent   = 0
    		LET r_r20.r20_descuento  = 0
    		LET r_r20.r20_val_descto = 0
		CALL fl_lee_item(r_r19.r19_compania, item) RETURNING r_r10.*
    		LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
    		LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
    		LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
    		LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
		IF r_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
			LET r_r10.r10_precio_mb = r_r10.r10_precio_ma
			LET r_r10.r10_costo_mb  = r_r10.r10_costo_ma
		END IF	
    		LET r_r20.r20_precio 	 = r_r10.r10_precio_mb
    		LET r_r20.r20_val_impto  = 0
    		LET r_r20.r20_costo 	 = r_r10.r10_costo_mb
    		LET r_r20.r20_fob 	 = r_r10.r10_fob
    		LET r_r20.r20_linea 	 = r_r10.r10_linea
    		LET r_r20.r20_rotacion 	 = r_r10.r10_rotacion
    		LET r_r20.r20_ubicacion  = '.'
    		LET r_r20.r20_stock_ant  = r_r11.r11_stock_act
		UPDATE rept011
			SET r11_stock_act = r11_stock_act - cantidad,
		            r11_egr_dia   = r11_egr_dia   + cantidad
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_ori
			  AND r11_item     = item 
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
    			LET r_r11.r11_stock_act = 0
			INSERT INTO rept011
				(r11_compania, r11_bodega, r11_item,
				 r11_ubicacion, r11_stock_ant, r11_stock_act,
				 r11_ing_dia, r11_egr_dia)
				VALUES(vg_codcia, r_r19.r19_bodega_dest,
					item, 'SN', 0, 0, 0, 0) 
		END IF
    		LET r_r20.r20_stock_bd   = r_r11.r11_stock_act
    		LET r_r20.r20_fecing     = CURRENT
		INSERT INTO rept020 VALUES (r_r20.*)
		UPDATE rept011
			SET r11_stock_act = r11_stock_act + cantidad,
			    r11_ing_dia   = r11_ing_dia   + cantidad
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_dest
			  AND r11_item     = item
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
					(cantidad * r_r20.r20_costo)
	END FOREACH
	IF NOT resul THEN
		EXIT FOREACH
	END IF
	IF i = 0 OR i IS NULL THEN
		DELETE FROM rept019
			WHERE r19_compania  = r_r19.r19_compania
			  AND r19_localidad = r_r19.r19_localidad
			  AND r19_cod_tran  = r_r19.r19_cod_tran
			  AND r19_num_tran  = r_r19.r19_num_tran
	ELSE
		UPDATE rept019
			SET r19_tot_costo = r_r19.r19_tot_costo,
			    r19_tot_bruto = r_r19.r19_tot_costo,
			    r19_tot_neto  = r_r19.r19_tot_costo
			WHERE r19_compania  = r_r19.r19_compania
			  AND r19_localidad = r_r19.r19_localidad
			  AND r19_cod_tran  = r_r19.r19_cod_tran
			  AND r19_num_tran  = r_r19.r19_num_tran 
		IF ctos = 1 THEN
			LET mensaje = 'Se genero la transferencia de traspaso',
				': ', r_r19.r19_num_tran USING "<<<<<<&", '.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
		END IF
		CALL imprimir_transferencia(r_r19.r19_cod_tran,
						r_r19.r19_num_tran)
	END IF
END FOREACH
DROP TABLE tmp_tr
RETURN resul

END FUNCTION



FUNCTION transaccion_aj(cod_tran, ctos)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE ctos		INTEGER
DEFINE r_transf		RECORD
				cia		LIKE rept019.r19_compania,
				loc		LIKE rept019.r19_localidad,
				tp		LIKE rept019.r19_cod_tran,
				num		LIKE rept019.r19_num_tran,
				bd_o		LIKE rept019.r19_bodega_ori,
				bd_d		LIKE rept019.r19_bodega_dest
			END RECORD
DEFINE query		CHAR(300)
DEFINE resul		SMALLINT

IF cod_tran = 'A+' THEN
	LET query = 'SELECT UNIQUE cia2, loc2, tp2, num2, bd_o, bd_d ',
			' FROM tmp_aj ',
			' ORDER BY num2 '
ELSE
	LET query = 'SELECT UNIQUE cia2, loc2, tp2, num2, bd_d, bd_o ',
			' FROM tmp_aj ',
			' ORDER BY num2 '
END IF
PREPARE cons_aj FROM query
DECLARE qu_ajuste CURSOR FOR cons_aj
LET resul = 1
FOREACH qu_ajuste INTO r_transf.*
	IF NOT generar_ajuste(r_transf.*, cod_tran, ctos) THEN
		LET resul = 0
		EXIT FOREACH
	END IF
END FOREACH
RETURN resul

END FUNCTION



FUNCTION generar_ajuste(r_transf, cod_tran, ctos)
DEFINE r_transf		RECORD
				cia		LIKE rept019.r19_compania,
				loc		LIKE rept019.r19_localidad,
				tp		LIKE rept019.r19_cod_tran,
				num		LIKE rept019.r19_num_tran,
				bd_o		LIKE rept019.r19_bodega_ori,
				bd_d		LIKE rept019.r19_bodega_dest
			END RECORD
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE ctos		INTEGER
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_aju		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE i		LIKE rept020.r20_orden
DEFINE item		LIKE rept011.r11_item
DEFINE cantidad		LIKE rept011.r11_stock_act
DEFINE mensaje 		VARCHAR(200)

INITIALIZE r_r19.*, r_r20.*, r_aju.* TO NULL
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE', 'AA', cod_tran)
	RETURNING num_tran
IF num_tran <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_r19.r19_compania   = vg_codcia
LET r_r19.r19_localidad  = vg_codloc
LET r_r19.r19_cod_tran   = cod_tran
LET r_r19.r19_num_tran   = num_tran
LET r_r19.r19_cont_cred  = 'C'
LET r_r19.r19_referencia = 'OT: ', rm_t23.t23_orden USING '<<<<<&',
				' ', r_transf.tp CLIPPED, ' ',
				r_transf.num USING '<<<<<&',
				'. POR TRASPASO EN OT'
IF cod_tran = 'A-' THEN
	SELECT r19_cod_tran, r19_num_tran
		INTO r_aju.r19_cod_tran, r_aju.r19_num_tran
		FROM rept019
		WHERE r19_compania    = vg_codcia
		  AND r19_localidad   = vg_codloc
		  AND r19_cod_tran    = 'A+'
		  AND r19_tipo_dev    = r_transf.tp
		  AND r19_num_dev     = r_transf.num
		  AND r19_ord_trabajo = rm_t23.t23_orden
	LET r_r19.r19_referencia = 'OT: ', rm_t23.t23_orden USING '<<<<<&',
				' ', r_aju.r19_cod_tran CLIPPED, ' ',
				r_aju.r19_num_tran USING '<<<<<&',
				'. POR TRASPASO EN OT'
END IF
LET r_r19.r19_codcli 	= rm_t23.t23_cod_cliente
LET r_r19.r19_nomcli 	= rm_t23.t23_nom_cliente
LET r_r19.r19_dircli 	= rm_t23.t23_dir_cliente
LET r_r19.r19_telcli 	= rm_t23.t23_tel_cliente
LET r_r19.r19_cedruc 	= rm_t23.t23_cedruc
DECLARE qu_ven3 CURSOR FOR
	SELECT r01_codigo
		FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_estado     = 'A'
		  AND r01_user_owner = vg_usuario
OPEN qu_ven3
FETCH qu_ven3 INTO r_r19.r19_vendedor
CLOSE qu_ven3
FREE qu_ven3
IF r_r19.r19_vendedor IS NULL THEN
	CALL fl_mostrar_mensaje('El Usuario ' || vg_usuario CLIPPED || ' no tiene Código de Vendedor asignado. Por favor consulte con el ADMINISTRADOR.', 'stop')
	RETURN 0
END IF
LET r_r19.r19_ord_trabajo = rm_t23.t23_orden
LET r_r19.r19_descuento   = 0
LET r_r19.r19_porc_impto  = 0
LET r_r19.r19_bodega_ori  = r_transf.bd_d
LET r_r19.r19_bodega_dest = r_transf.bd_d
LET r_r19.r19_tipo_dev    = r_transf.tp
LET r_r19.r19_num_dev     = r_transf.num
LET r_r19.r19_moneda 	  = rm_t23.t23_moneda
LET r_r19.r19_paridad     = rg_gen.g00_decimal_mb
LET r_r19.r19_precision   = rm_t23.t23_precision
LET r_r19.r19_tot_costo   = 0
LET r_r19.r19_tot_bruto   = 0
LET r_r19.r19_tot_dscto   = 0
LET r_r19.r19_tot_neto 	  = 0
LET r_r19.r19_flete 	  = 0
LET r_r19.r19_usuario 	  = vg_usuario
LET r_r19.r19_fecing 	  = CURRENT
INSERT INTO rept019 VALUES (r_r19.*)
DECLARE qu_dettr3 CURSOR FOR
	SELECT item2, cant_aj, ord2
		FROM tmp_aj
		WHERE cia2  = r_transf.cia
		  AND loc2  = r_transf.loc
		  AND tp2   = r_transf.tp
		  AND num2  = r_transf.num
		ORDER BY ord2
LET i = 0
FOREACH qu_dettr3 INTO item, cantidad, i
	CALL fl_lee_stock_rep(vg_codcia, r_transf.bd_d, item) RETURNING r_r11.*
	IF r_r11.r11_compania IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
    	LET r_r20.r20_compania 	 = r_r19.r19_compania
    	LET r_r20.r20_localidad	 = r_r19.r19_localidad
    	LET r_r20.r20_cod_tran 	 = r_r19.r19_cod_tran
    	LET r_r20.r20_num_tran 	 = r_r19.r19_num_tran
    	LET r_r20.r20_bodega 	 = r_transf.bd_d
    	LET r_r20.r20_item 	 = item
    	LET r_r20.r20_orden 	 = i
    	LET r_r20.r20_cant_ped 	 = cantidad
    	LET r_r20.r20_cant_ven   = cantidad
	LET r_r20.r20_cant_dev 	 = 0
	LET r_r20.r20_cant_ent   = 0
	LET r_r20.r20_descuento  = 0
	LET r_r20.r20_val_descto = 0
	CALL fl_lee_item(r_r19.r19_compania, item) RETURNING r_r10.*
    	LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
    	LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
    	LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
    	LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
	IF r_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
		LET r_r10.r10_precio_mb = r_r10.r10_precio_ma
		LET r_r10.r10_costo_mb  = r_r10.r10_costo_ma
	END IF	
    	LET r_r20.r20_precio 	 = r_r10.r10_precio_mb
    	LET r_r20.r20_val_impto  = 0
    	LET r_r20.r20_costo 	 = r_r10.r10_costo_mb
    	LET r_r20.r20_fob 	 = r_r10.r10_fob
    	LET r_r20.r20_linea 	 = r_r10.r10_linea
    	LET r_r20.r20_rotacion 	 = r_r10.r10_rotacion
    	LET r_r20.r20_ubicacion  = '.'
    	LET r_r20.r20_stock_ant  = r_r11.r11_stock_act
	IF r_r20.r20_stock_ant IS NULL THEN
		LET r_r20.r20_stock_ant = 0
	END IF
	CALL fl_lee_stock_rep(vg_codcia, r_transf.bd_d, item) RETURNING r_r11.*
	IF r_r11.r11_compania IS NULL THEN
    		LET r_r11.r11_stock_act = 0
		IF cod_tran = 'A+' THEN
			INSERT INTO rept011
				(r11_compania, r11_bodega, r11_item,
				 r11_ubicacion, r11_stock_ant, r11_stock_act,
				 r11_ing_dia, r11_egr_dia)
				VALUES(vg_codcia, r_r19.r19_bodega_dest,
					item, 'SN', 0, cantidad, cantidad, 0)
		ELSE
			INSERT INTO rept011
				(r11_compania, r11_bodega, r11_item,
				 r11_ubicacion, r11_stock_ant, r11_stock_act,
				 r11_ing_dia, r11_egr_dia)
				VALUES(vg_codcia, r_r19.r19_bodega_dest,
					item, 'SN', 0, cantidad, 0, cantidad)
		END IF
	ELSE
		IF cod_tran = 'A+' THEN
			UPDATE rept011
				SET r11_stock_act = r11_stock_act + cantidad,
				    r11_ing_dia   = r11_ing_dia   + cantidad
				WHERE r11_compania = vg_codcia
				  AND r11_bodega   = r_transf.bd_d
				  AND r11_item     = item
		ELSE
			CALL fl_lee_stock_rep(vg_codcia, r_transf.bd_d, item)
				RETURNING r_r11.*
			IF r_r11.r11_compania IS NULL THEN
				LET r_r11.r11_stock_act = 0
			END IF
			LET mensaje = 'ITEM: ', item
			IF r_r11.r11_stock_act <= 0 THEN
				LET mensaje = mensaje CLIPPED,
				' no tiene stock y se nesecita: ',
				cantidad USING '####&', '. No puede ajustar ',
				'para esta Orden de Trabajo.'
				CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
				RETURN 0
			END IF
			IF r_r11.r11_stock_act < cantidad THEN
				LET mensaje = mensaje CLIPPED,
				' solo tiene stock: ',
				r_r11.r11_stock_act USING '####&', 
				' y se nesecita: ', cantidad USING '####&',
				'. No puede ajustar para esta Orden de Trabajo.'
				CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
				RETURN 0
			END IF
			UPDATE rept011
				SET r11_stock_act = r11_stock_act - cantidad,
				    r11_egr_dia   = r11_egr_dia   + cantidad
				WHERE r11_compania = vg_codcia
				  AND r11_bodega   = r_transf.bd_d
				  AND r11_item     = item
		END IF
	END IF
	LET r_r20.r20_stock_bd   = r_r11.r11_stock_act
	LET r_r20.r20_fecing     = CURRENT
	INSERT INTO rept020 VALUES (r_r20.*)
	LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
				(cantidad * r_r20.r20_costo)
END FOREACH
IF i = 0 OR i IS NULL THEN
	DELETE FROM rept019
		WHERE r19_compania  = r_r19.r19_compania
		  AND r19_localidad = r_r19.r19_localidad
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran
ELSE
	UPDATE rept019
		SET r19_tot_costo = r_r19.r19_tot_costo,
		    r19_tot_bruto = r_r19.r19_tot_costo,
		    r19_tot_neto  = r_r19.r19_tot_costo
		WHERE r19_compania  = r_r19.r19_compania
		  AND r19_localidad = r_r19.r19_localidad
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran 
	IF ctos = 1 THEN
		LET mensaje = 'Se genero el ajuste para traspaso: ',
				r_r19.r19_cod_tran, ' ',
				r_r19.r19_num_tran USING "<<<<<<&", '.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION control_anular_ordenes_de_compras()
DEFINE r_c00		RECORD LIKE ordt000.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(200)
DEFINE cur_row		SMALLINT
DEFINE i_row, i_col	SMALLINT
DEFINE n_row, n_col	SMALLINT
DEFINE salir, dias	SMALLINT
DEFINE pago, tot_neto	DECIMAL(14,2)

INITIALIZE r_c10.* TO NULL
DECLARE q_c10 CURSOR FOR
	SELECT * FROM ordt010
		WHERE c10_compania    = vg_codcia
		  AND c10_localidad   = vg_codloc
		  AND c10_ord_trabajo = rm_t23.t23_orden
		  AND c10_estado      = 'C'
		ORDER BY c10_numero_oc
OPEN q_c10
FETCH q_c10 INTO r_c10.*
IF r_c10.c10_compania IS NULL THEN
	CLOSE q_c10
	FREE q_c10
	RETURN
END IF
CALL fl_lee_compania_orden_compra(vg_codcia) RETURNING r_c00.*
LET num_row_oc = 0
LET tot_neto   = 0
FOREACH q_c10 INTO r_c10.*
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
	RETURN
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
DISPLAY rm_t23.t23_orden  TO num_ot
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
		ON KEY(F5)
			LET cur_row = arr_curr()
			CALL fl_ver_orden_compra(r_oc[cur_row].numero_oc)
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
	RETURN
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
	ERROR '                                                                            '
	LET cur_row = cur_row + 1
	INSERT INTO tmp_oc VALUES (r_c10.c10_numero_oc)
END FOREACH
CLOSE WINDOW w_talf211_2
LET int_flag = 0
RETURN

END FUNCTION



FUNCTION control_anular_recepcion_orden_compra(oc)
DEFINE oc 		LIKE ordt013.c13_numero_oc
DEFINE num_ret		LIKE cxpt028.p28_num_ret
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE i		SMALLINT
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
	ROLLBACK WORK
	LET mensaje = 'La orden de compra # ',
			rm_c13.c13_numero_oc USING "<<<<<<<&",
		       ' no tiene ninguna recepción para que pueda ser anulada.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
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
			ROLLBACK WORK
			CALL fl_mensaje_arreglo_incompleto()
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
	END FOREACH
	LET vm_ind_arr = i - 1
	IF vm_ind_arr = 0 THEN
		ROLLBACK WORK
		LET mensaje = 'La recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				' no tiene detalle.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
		WHENEVER ERROR STOP
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
		LET mensaje = 'La orden de compra # ',
				r_c10.c10_numero_oc USING "<<<<<<<&",
				' esta bloqueada por otro usuario.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		WHENEVER ERROR STOP
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
			LET mensaje = 'No se pudo actualizar el detalle de la',
					' orden de compra # ',
					r_c10.c10_numero_oc USING "<<<<<<<&",
					'. Ha ocurrido un error de Base de ',
					'Datos, llame al ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			WHENEVER ERROR STOP
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
		LET mensaje = 'No se pudo eliminar la recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				'. Ha ocurrido un error de Base de ',
				'Datos, llame al ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	IF rm_c10.c10_tipo_pago = 'R' THEN
		LET valor_aplicado = control_rebaja_deuda()  
		IF valor_aplicado < 0 THEN
			ROLLBACK WORK
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
	END IF
	IF rm_c13.c13_tot_recep = rm_c10.c10_tot_compra THEN
		UPDATE ordt010 SET c10_estado = 'E' WHERE CURRENT OF q_ordt010
		IF STATUS < 0 THEN
			ROLLBACK WORK 
			LET mensaje = 'No se pudo actualizar el estado de la ',
					'orden de compra # ',
					r_c10.c10_numero_oc USING "<<<<<<<&",
					'. Ha ocurrido un error de Base de ',
					'Datos, llame al ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		UPDATE ordt010 SET c10_ord_trabajo = rm_t23.t23_orden
			WHERE CURRENT OF q_ordt010
		IF STATUS < 0 THEN
			ROLLBACK WORK 
			LET mensaje = 'No se pudo restaurar la OT anterior a ',
					'la orden de compra # ',
					r_c10.c10_numero_oc USING "<<<<<<<&",
					'. Ha ocurrido un error de Base de ',
					'Datos, llame al ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			WHENEVER ERROR STOP
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
		LET mensaje = 'No se pudo eliminar la retención de la ',
				'recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				'. Ha ocurrido un error de Base de ',
				'Datos, llame al ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
END FOREACH

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
	WHENEVER ERROR STOP
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



FUNCTION eliminar_diarios_contables_recep_reten_oc_anuladas(orden_oc)
DEFINE orden_oc		LIKE ordt010.c10_numero_oc
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
		  AND c10_numero_oc   = orden_oc
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



FUNCTION actualizar_anomes_proceso()

IF vm_mes = 12 THEN
	LET vm_mes  = 1
	LET vm_anio = vm_anio + 1
ELSE
	LET vm_mes  = vm_mes + 1
END IF
WHENEVER ERROR CONTINUE
UPDATE talt000
	SET t00_mespro = vm_mes,
	    t00_anopro = vm_anio
	WHERE CURRENT OF q_talt000 
IF STATUS <> 0 THEN
	CALL fl_mostrar_mensaje('Ha ocurrido un error al actualizar la tabla talt000. Por favor llame al ADMINISTRADOR.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP
RETURN 1

END FUNCTION



FUNCTION imprimir_transferencia(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE param		VARCHAR(100)

LET param = '"', cod_tran, '" ', num_tran
CALL fl_ejecuta_comando('REPUESTOS', 'RE', 'repp415', param, 1)

END FUNCTION
