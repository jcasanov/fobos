------------------------------------------------------------------------------
-- Titulo           : ordp401.4gl - Listado detalle de ordenes de compra
-- Elaboracion      : 17-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun ordp401 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE rm_par 		RECORD 
				g13_moneda	LIKE gent013.g13_moneda,
				g13_nombre	LIKE gent013.g13_nombre,
				fecha_ini	DATE,
				fecha_fin	DATE,
				estado		CHAR(1),
				tipo_reporte	CHAR(1),
				c01_aux_cont	LIKE ordt001.c01_aux_cont,
				tipo_oc		LIKE ordt001.c01_tipo_orden,
				n_tipo_oc	LIKE ordt001.c01_nombre,
				dpto		LIKE gent034.g34_cod_depto,
				n_dpto		LIKE gent034.g34_nombre,
				codprov		LIKE cxpt001.p01_codprov,
				nomprov		LIKE cxpt001.p01_nomprov
			END RECORD
DEFINE num_campos	SMALLINT
DEFINE rm_campos 	ARRAY[15] OF RECORD
				nombre		VARCHAR(20),
				posicion	SMALLINT
			END RECORD
DEFINE num_ord		SMALLINT
DEFINE rm_ord		ARRAY[2] OF RECORD
				col		VARCHAR(20),
				chk_asc		CHAR,
				chk_desc	CHAR
			END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp401.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'ordp401'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CREATE TEMP TABLE tmp_detalle_prov(
		codprov		INTEGER,
		nomprov		VARCHAR(40,20),
		cedruc		CHAR(15),
		--tipo_prov	VARCHAR(30,15),
		estado		CHAR(1),
		flete		DECIMAL(11,2),
		otros		DECIMAL(11,2),
		valor_bruto	DECIMAL(12,2),
		valor_dscto	DECIMAL(11,2),
		subtotal	DECIMAL(14,2),
		valor_impto	DECIMAL(11,2),
		valor_neto	DECIMAL(12,2),
		porc_iva	DECIMAL(5,2),
		val_ret_iva	DECIMAL(11,2),
		porc_fte	DECIMAL(5,2),
		val_ret_fte	DECIMAL(11,2)
	)
CALL fl_nivel_isolation()
CALL campos_forma()
CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*
INITIALIZE rm_par.* TO NULL
LET rm_par.g13_moneda   = r_g13.g13_moneda
LET rm_par.g13_nombre   = r_g13.g13_nombre
LET rm_par.estado       = 'T'
LET rm_par.tipo_reporte = 'T'
LET rm_par.fecha_ini    = TODAY
LET rm_par.fecha_fin    = TODAY
LET num_ord             = 2
LET rm_ord[1].col       = rm_campos[5].nombre
LET rm_ord[2].col       = rm_campos[2].nombre
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 16
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/ordf401_1"
ELSE
	OPEN FORM f_rep FROM "../forms/ordf401_1c"
END IF
DISPLAY FORM f_rep
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compania.','stop')
	EXIT PROGRAM
END IF
FOR i = 1 TO num_ord
	LET rm_ord[i].chk_asc  = 'S'
	LET rm_ord[i].chk_desc = 'N'
	DISPLAY rm_ord[i].* TO rm_ord[i].*
END FOR
DISPLAY BY NAME r_g13.g13_nombre
IF vg_gui = 0 THEN
	CALL muestra_estado(rm_par.estado)
	CALL muestra_tipo(rm_par.tipo_reporte)
END IF
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE col		SMALLINT
DEFINE query		CHAR(4000)
DEFINE comando		VARCHAR(100)
DEFINE comando1		VARCHAR(100)
DEFINE resp		CHAR(6)
DEFINE registro		CHAR(700)
DEFINE enter		SMALLINT
DEFINE data_found	SMALLINT
DEFINE r_det		RECORD 
				fecha_ing	DATE,
				estado		CHAR(1),
				tipo_oc		LIKE ordt001.c01_nombre,
				numero_oc	LIKE ordt010.c10_numero_oc,
				nomprov		LIKE cxpt001.p01_nomprov,
				factura		LIKE ordt010.c10_factura,
				fecha_fact	DATE,
				flete		LIKE ordt010.c10_flete,
				otros		LIKE ordt010.c10_otros,
				valor_bruto	LIKE ordt010.c10_tot_compra,
				valor_dscto	LIKE ordt010.c10_tot_dscto,
				subtotal	DECIMAL(14,2),
				valor_impto	LIKE ordt010.c10_tot_impto,
				valor_neto	LIKE ordt010.c10_tot_compra,
				porc_iva	LIKE cxpt028.p28_porcentaje,
				val_ret_iva	LIKE cxpt028.p28_valor_ret,
				porc_fte	LIKE cxpt028.p28_porcentaje,
				val_ret_fte	LIKE cxpt028.p28_valor_ret
			END RECORD
DEFINE r_prov		RECORD 
				codprov		LIKE cxpt001.p01_codprov,
				nomprov		LIKE cxpt001.p01_nomprov,
				cedruc		LIKE cxpt001.p01_num_doc,
				--tipo_prov	LIKE gent012.g12_nombre,
				estado		CHAR(1),
				flete		LIKE ordt010.c10_flete,
				otros		LIKE ordt010.c10_otros,
				valor_bruto	LIKE ordt010.c10_tot_compra,
				valor_dscto	LIKE ordt010.c10_tot_dscto,
				subtotal	DECIMAL(14,2),
				valor_impto	LIKE ordt010.c10_tot_impto,
				valor_neto	LIKE ordt010.c10_tot_compra,
				porc_iva	LIKE cxpt028.p28_porcentaje,
				val_ret_iva	LIKE cxpt028.p28_valor_ret,
				porc_fte	LIKE cxpt028.p28_porcentaje,
				val_ret_fte	LIKE cxpt028.p28_valor_ret
			END RECORD
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_c10		RECORD LIKE ordt010.*
--DEFINE r_g12		RECORD LIKE gent012.*

CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
IF rm_g01.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
LET enter = 13
INITIALIZE r_det.* TO NULL 
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL ordenar_por()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_hacer_pregunta('Desea generar también un archivo de texto ?',
				'No')
		RETURNING resp
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	DELETE FROM tmp_detalle_prov
	LET query = prepare_query()
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0
	IF rm_par.tipo_reporte <> 'R' THEN
		START REPORT rep_orden_compra TO PIPE comando
	END IF
	FOREACH	q_deto INTO r_det.*
		LET data_found = 1
		CALL fl_lee_orden_compra(vg_codcia, vg_codloc, r_det.numero_oc)
			RETURNING r_c10.*
		CALL fl_lee_proveedor(r_c10.c10_codprov) RETURNING r_p01.*
		SELECT * FROM tmp_detalle_prov
			WHERE codprov = r_p01.p01_codprov
		IF STATUS = NOTFOUND THEN
			{--
			CALL fl_lee_subtipo_entidad('TP', r_p01.p01_tipo_prov)
				RETURNING r_g12.*
			--}
			INSERT INTO tmp_detalle_prov
				VALUES(r_p01.p01_codprov, r_p01.p01_nomprov,
					--r_g12.g12_nombre, r_p01.p01_estado,
					r_p01.p01_num_doc, r_p01.p01_estado,
					r_det.flete, r_det.otros,
					r_det.valor_bruto, r_det.valor_dscto,
					r_det.subtotal, r_det.valor_impto,
					r_det.valor_neto, r_det.porc_iva,
					r_det.val_ret_iva, r_det.porc_fte,
					r_det.val_ret_fte)
		ELSE
			UPDATE tmp_detalle_prov
					SET flete       = flete + r_det.flete,
					    otros       = otros + r_det.otros,
					    valor_bruto = valor_bruto +
							  r_det.valor_bruto,
					    valor_dscto = valor_dscto +
							  r_det.valor_dscto,
					    subtotal    = subtotal +
							  r_det.subtotal,
					    valor_impto = valor_impto +
							  r_det.valor_impto,
					    valor_neto  = valor_neto +
							  r_det.valor_neto,
					    val_ret_iva = r_det.val_ret_iva +
							  r_det.val_ret_iva,
					    val_ret_fte = r_det.val_ret_fte +
							  r_det.val_ret_fte
				WHERE codprov = r_p01.p01_codprov
		END IF
		IF rm_par.tipo_reporte <> 'R' THEN
			IF resp = 'Yes' THEN
				LET registro = r_det.fecha_ing
						USING "dd-mm-yyyy", '|',
						UPSHIFT(r_det.estado), '|',
						r_det.tipo_oc, '|',
						r_det.numero_oc USING "<<<<<&",
						'|', r_det.nomprov CLIPPED, '|',
						r_det.factura, '|',
						r_det.fecha_fact
						USING "dd-mm-yyyy", '|',
						r_det.flete USING "#,##&.##",
						'|', r_det.otros
						USING "#,##&.##", '|',
						r_det.valor_bruto
						USING "#,###,##&.##", '|',
						r_det.valor_dscto
						USING "###,##&.##", '|',
						r_det.subtotal
						USING "#,###,##&.##", '|',
						r_det.valor_impto
						USING "###,##&.##", '|',
						r_det.valor_neto
						USING "#,###,##&.##", '|',
						r_det.porc_iva
						USING "##&.##", '|',
						r_det.val_ret_iva
						USING "###,##&.##", '|',
						r_det.porc_fte
						USING "##&.##", '|',
						r_det.val_ret_fte
						USING "###,##&.##"
				IF vg_gui = 1 THEN
					--#DISPLAY registro CLIPPED,ASCII(enter)
				ELSE
					DISPLAY registro CLIPPED
				END IF
			END IF
			OUTPUT TO REPORT rep_orden_compra(r_det.*)
		END IF
	END FOREACH
	IF rm_par.tipo_reporte <> 'R' THEN
		FINISH REPORT rep_orden_compra
		IF resp = 'Yes' THEN
			LET comando1 = 'mv ', vg_proceso CLIPPED,
					'.txt $HOME/tmp/',
					vg_proceso CLIPPED, '_1.txt'
			RUN comando1
			CALL fl_mostrar_mensaje('Se generó el Archivo ' || vg_proceso CLIPPED || '_1.txt', 'info')
		END IF
	END IF
	IF rm_par.tipo_reporte = 'D' THEN
		IF NOT data_found THEN
			CALL fl_mensaje_consulta_sin_registros()
		END IF
		CONTINUE WHILE
	END IF
	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	DECLARE q_pro CURSOR FOR SELECT * FROM tmp_detalle_prov ORDER BY nomprov
	START REPORT rep_tot_prov TO PIPE comando
	FOREACH	q_pro INTO r_prov.*
		IF resp = 'Yes' THEN
			LET registro = r_prov.codprov USING "<<<<&", '|',
					r_prov.nomprov CLIPPED, '|',
					r_prov.cedruc CLIPPED, '|',
					UPSHIFT(r_prov.estado) CLIPPED, '|',
					r_prov.flete USING "#,##&.##", '|',
					r_prov.otros USING "#,##&.##", '|',
					r_prov.valor_bruto USING "#,###,##&.##",
					'|', r_prov.valor_dscto
					USING "###,##&.##", '|', r_prov.subtotal
					USING "#,###,##&.##", '|',
					r_prov.valor_impto USING "###,##&.##",
					'|', r_prov.valor_neto
					USING "#,###,##&.##", '|',
					r_prov.porc_iva USING "##&.##", '|',
					r_prov.val_ret_iva
					USING "###,##&.##", '|',
					r_prov.porc_fte USING "##&.##", '|',
					r_prov.val_ret_fte USING "###,##&.##"
			IF vg_gui = 1 THEN
				--#DISPLAY registro CLIPPED, ASCII(enter)
			ELSE
				DISPLAY registro CLIPPED
			END IF
		END IF
		OUTPUT TO REPORT rep_tot_prov(r_prov.*)
	END FOREACH
	FINISH REPORT rep_tot_prov
	IF resp = 'Yes' THEN
		LET comando1 = 'mv ', vg_proceso CLIPPED, '.txt $HOME/tmp/',
				vg_proceso CLIPPED, '_2.txt'
		RUN comando1
		CALL fl_mostrar_mensaje('Se generó el Archivo ' || vg_proceso CLIPPED || '_2.txt', 'info')
	END IF
END WHILE
DROP TABLE tmp_detalle_prov

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE resul		SMALLINT

LET INT_FLAG   = 0
INPUT BY NAME rm_par.g13_moneda, rm_par.fecha_ini, rm_par.fecha_fin,
	rm_par.tipo_reporte, rm_par.estado, rm_par.c01_aux_cont,
	rm_par.tipo_oc, rm_par.dpto, rm_par.codprov
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET INT_FLAG = 1 
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(g13_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda, 
					  		  r_g13.g13_nombre,
					  		  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_par.g13_moneda = r_g13.g13_moneda
				LET rm_par.g13_nombre = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(c01_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_par.c01_aux_cont = r_b10.b10_cuenta
				DISPLAY BY NAME rm_par.c01_aux_cont
				DISPLAY r_b10.b10_descripcion TO tit_aux_cont
			END IF
		END IF
		IF INFIELD(tipo_oc) THEN
			CALL fl_ayuda_tipos_ordenes_compras('T') 
					RETURNING r_c01.c01_tipo_orden,
						  r_c01.c01_nombre
			IF r_c01.c01_tipo_orden IS NOT NULL THEN
				LET rm_par.tipo_oc    = r_c01.c01_tipo_orden
				LET rm_par.n_tipo_oc  = r_c01.c01_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(dpto) THEN
			CALL fl_ayuda_departamentos(vg_codcia) 
					RETURNING r_g34.g34_cod_depto,
						  r_g34.g34_nombre
			IF r_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_par.dpto   = r_g34.g34_cod_depto
				LET rm_par.n_dpto = r_g34.g34_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(codprov) THEN
			CALL fl_ayuda_proveedores() RETURNING r_p01.p01_codprov,
						  	      r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET rm_par.codprov = r_p01.p01_codprov
				LET rm_par.nomprov = r_p01.p01_nomprov
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD g13_moneda
		IF rm_par.g13_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.g13_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD g13_moneda
			END IF
			LET rm_par.g13_nombre = r_g13.g13_nombre
			DISPLAY BY NAME rm_par.g13_nombre
		ELSE
			LET rm_par.g13_nombre = NULL
			CLEAR g13_nombre
		END IF
	AFTER FIELD estado
		IF vg_gui = 0 THEN
			IF rm_par.estado IS NOT NULL THEN
				CALL muestra_estado(rm_par.estado)
			ELSE
				CLEAR tit_estado
			END IF
		END IF
	AFTER FIELD tipo_reporte
		IF vg_gui = 0 THEN
			IF rm_par.tipo_reporte IS NOT NULL THEN
				CALL muestra_tipo(rm_par.tipo_reporte)
			ELSE
				CLEAR tit_tipo_rep
			END IF
		END IF
	AFTER FIELD c01_aux_cont
                IF rm_par.c01_aux_cont IS NOT NULL THEN
			CALL validar_cuenta(rm_par.c01_aux_cont, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD c01_aux_cont
			END IF
		ELSE
			CLEAR tit_aux_cont
                END IF
	AFTER FIELD tipo_oc
		IF rm_par.tipo_oc IS NOT NULL THEN
			CALL fl_lee_tipo_orden_compra(rm_par.tipo_oc)
				RETURNING r_c01.*
			IF r_c01.c01_tipo_orden IS NULL THEN
				CALL fl_mostrar_mensaje('Tipo orden de compra no existe.','exclamation')
				NEXT FIELD tipo_oc
			END IF
			LET rm_par.n_tipo_oc = r_c01.c01_nombre
			DISPLAY BY NAME rm_par.n_tipo_oc
		ELSE
			LET rm_par.n_tipo_oc = NULL
			CLEAR n_tipo_oc
		END IF
	AFTER FIELD dpto
		IF rm_par.dpto IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia, rm_par.dpto)
				RETURNING r_g34.*
			IF r_g34.g34_cod_depto IS NULL THEN
				CALL fl_mostrar_mensaje('Departamento no existe.','exclamation')
				NEXT FIELD dpto
			END IF
			LET rm_par.n_dpto = r_g34.g34_nombre
			DISPLAY BY NAME rm_par.n_dpto
		ELSE
			LET rm_par.n_dpto = NULL
			CLEAR n_dpto
		END IF
	AFTER FIELD codprov
		IF rm_par.codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_par.codprov) RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('Proveedor no existe.','exclamation')
				NEXT FIELD codprov
			END IF
			LET rm_par.nomprov = r_p01.p01_nomprov
			DISPLAY BY NAME rm_par.nomprov
		ELSE
			LET rm_par.nomprov = NULL
			CLEAR nomprov
		END IF
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_ini
			END IF
			IF rm_par.fecha_ini < '01-01-1990' THEN
				CALL fl_mostrar_mensaje('Debe ingresa fechas mayores a las del año 1989.','exclamation')
				NEXT FIELD fecha_ini
			END IF
				
		ELSE 
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_fin
			END IF
			IF rm_par.fecha_fin < '01-01-1990' THEN
				CALL fl_mostrar_mensaje('Debe ingresa fechas mayores a las del año 1989.','exclamation')
				NEXT FIELD fecha_fin
			END IF
		ELSE
			NEXT FIELD fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini IS NULL OR rm_par.fecha_fin IS NULL THEN
			CONTINUE INPUT 
		END IF
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor a la fecha final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION validar_cuenta(aux_cont, flag)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE flag		SMALLINT
DEFINE r_cta            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_cta.*
IF r_cta.b10_cuenta IS NULL THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
CASE flag
	WHEN 1
		DISPLAY r_cta.b10_descripcion TO tit_aux_cont
END CASE
IF r_cta.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_cta.b10_nivel <> vm_nivel THEN
	CALL fl_mostrar_mensaje('Nivel de cuenta debe ser solo del ultimo.','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION prepare_query()
DEFINE query	 	CHAR(4000)
DEFINE expr_estado	VARCHAR(30)
DEFINE expr_aux_cont	VARCHAR(50)
DEFINE expr_tipo_oc	VARCHAR(30)
DEFINE expr_dpto	VARCHAR(30)
DEFINE expr_codprov	VARCHAR(30)
DEFINE fecha		VARCHAR(20)

LET expr_estado = ' AND c10_estado <> "E" '
IF rm_par.estado <> 'T' THEN
	LET expr_estado = ' AND c10_estado = "', rm_par.estado, '"'
END IF
LET expr_aux_cont = ' '
IF rm_par.c01_aux_cont IS NOT NULL THEN
	LET expr_aux_cont = ' AND c01_aux_cont = "', rm_par.c01_aux_cont, '"'
END IF
LET expr_tipo_oc = ' '
IF rm_par.tipo_oc IS NOT NULL THEN
	LET expr_tipo_oc = ' AND c10_tipo_orden = ', rm_par.tipo_oc
END IF
LET expr_dpto = ' '
IF rm_par.dpto IS NOT NULL THEN
	LET expr_dpto = ' AND c10_cod_depto = ', rm_par.dpto
END IF
LET expr_codprov = ' '
IF rm_par.codprov IS NOT NULL THEN
	LET expr_codprov = ' AND c10_codprov = ', rm_par.codprov
END IF
IF rm_par.estado = "A" OR rm_par.estado = "T" OR rm_par.estado = "E" THEN
	LET fecha = "c10_fecing"
END IF
IF rm_par.estado = "C" THEN
	LET fecha = "c10_fecha_fact"
END IF
IF rm_par.estado = "P" THEN
	LET fecha = "c10_fecha_aprob"
END IF
LET query = 'SELECT DATE(c10_fecing), c10_estado, c01_nombre, c10_numero_oc, ',
	    	  ' p01_nomprov, c10_factura, c10_fecha_fact, c10_flete, ', 
	    	  ' c10_otros, (c10_tot_repto + c10_tot_mano), c10_tot_dscto,', 
 		  ' (c10_tot_repto + c10_tot_mano) - c10_tot_dscto + ',
		  ' c10_dif_cuadre + c10_otros, ',
	    	  ' c10_tot_impto, c10_tot_compra, ',
		  ' (SELECT SUM(p28_porcentaje) ',
			'FROM cxpt028, cxpt027 ',
			'WHERE p28_compania  = c10_compania ',
			'  AND p28_localidad = c10_localidad ',
			'  AND p28_codprov   = c10_codprov ',
			'  AND p28_tipo_doc  = "FA" ',
			'  AND p28_num_doc   = c10_factura ',
			'  AND p28_dividendo = 1 ',
			'  AND p28_tipo_ret  = "I" ',
			'  AND p27_compania  = p28_compania ',
			'  AND p27_localidad = p28_localidad ',
			'  AND p27_num_ret   = p28_num_ret ',
			'  AND p27_estado    = "A") porc_iva, ',
		  ' (SELECT SUM(p28_valor_ret) ',
			'FROM cxpt028, cxpt027 ',
			'WHERE p28_compania  = c10_compania ',
			'  AND p28_localidad = c10_localidad ',
			'  AND p28_codprov   = c10_codprov ',
			'  AND p28_tipo_doc  = "FA" ',
			'  AND p28_num_doc   = c10_factura ',
			'  AND p28_dividendo = 1 ',
			'  AND p28_tipo_ret  = "I" ',
			'  AND p27_compania  = p28_compania ',
			'  AND p27_localidad = p28_localidad ',
			'  AND p27_num_ret   = p28_num_ret ',
			'  AND p27_estado    = "A") val_ret_iva, ',
		  ' (SELECT SUM(p28_porcentaje) ',
			'FROM cxpt028, cxpt027 ',
			'WHERE p28_compania  = c10_compania ',
			'  AND p28_localidad = c10_localidad ',
			'  AND p28_codprov   = c10_codprov ',
			'  AND p28_tipo_doc  = "FA" ',
			'  AND p28_num_doc   = c10_factura ',
			'  AND p28_dividendo = 1 ',
			'  AND p28_tipo_ret  = "F" ',
			'  AND p27_compania  = p28_compania ',
			'  AND p27_localidad = p28_localidad ',
			'  AND p27_num_ret   = p28_num_ret ',
			'  AND p27_estado    = "A") porc_fte, ',
		  ' (SELECT SUM(p28_valor_ret) ',
			'FROM cxpt028, cxpt027 ',
			'WHERE p28_compania  = c10_compania ',
			'  AND p28_localidad = c10_localidad ',
			'  AND p28_codprov   = c10_codprov ',
			'  AND p28_tipo_doc  = "FA" ',
			'  AND p28_num_doc   = c10_factura ',
			'  AND p28_dividendo = 1 ',
			'  AND p28_tipo_ret  = "F" ',
			'  AND p27_compania  = p28_compania ',
			'  AND p27_localidad = p28_localidad ',
			'  AND p27_num_ret   = p28_num_ret ',
			'  AND p27_estado    = "A") val_ret_fte ',
	      ' FROM ordt010, ordt001, gent034, cxpt001 ',
	      ' WHERE c10_compania   = ', vg_codcia, 
	        ' AND c10_localidad  = ', vg_codloc,
	        expr_aux_cont CLIPPED,
	        expr_tipo_oc CLIPPED,
	        expr_dpto    CLIPPED,
	        expr_estado  CLIPPED,
	        expr_codprov CLIPPED,
	        ' AND c10_moneda     = "', rm_par.g13_moneda, '"',
	        ' AND DATE(', fecha, ') BETWEEN "', rm_par.fecha_ini, '"',
	                                 '  AND "', rm_par.fecha_fin, '"',
	        ' AND c01_tipo_orden = c10_tipo_orden ',
	        ' AND g34_compania   = c10_compania ',
	        ' AND g34_cod_depto  = c10_cod_depto ',
	        ' AND p01_codprov    = c10_codprov '
RETURN full_query(query)

END FUNCTION



FUNCTION full_query(query)
DEFINE query		CHAR(4000)
DEFINE order_clause	VARCHAR(150)
DEFINE i, j		SMALLINT

LET order_clause = ' ORDER BY '
FOR i = 1 TO num_ord
	FOR j = 1 TO num_campos
		IF rm_ord[i].col = rm_campos[j].nombre THEN
			LET order_clause = order_clause || rm_campos[j].posicion
			IF rm_ord[i].chk_asc = 'S' THEN
				LET order_clause = order_clause || ' ASC'
			ELSE
				LET order_clause = order_clause || ' DESC'
			END IF
			IF i <> num_ord THEN
				LET order_clause = order_clause || ', '
			END IF
		END IF
	END FOR
END FOR
LET query = query CLIPPED || order_clause CLIPPED
RETURN query

END FUNCTION



REPORT rep_orden_compra(r_det)
DEFINE r_det		RECORD 
 				fecha_ing	DATE,
			 	estado		CHAR(1),
 				tipo_oc		LIKE ordt001.c01_nombre,
 				numero_oc	LIKE ordt010.c10_numero_oc,
 				nomprov		LIKE cxpt001.p01_nomprov,
 				factura		LIKE ordt010.c10_factura,
 				fecha_fact	DATE,
 				flete		LIKE ordt010.c10_flete,
 				otros		LIKE ordt010.c10_otros,
 				valor_bruto	LIKE ordt010.c10_tot_compra,
 				valor_dscto	LIKE ordt010.c10_tot_dscto,
 				subtotal	DECIMAL(14,2),
 				valor_impto	LIKE ordt010.c10_tot_impto,
 				valor_neto	LIKE ordt010.c10_tot_compra,
				porc_iva	LIKE cxpt028.p28_porcentaje,
				val_ret_iva	LIKE cxpt028.p28_valor_ret,
				porc_fte	LIKE cxpt028.p28_porcentaje,
				val_ret_fte	LIKE cxpt028.p28_valor_ret
			END RECORD
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	160
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET modulo  	= "MODULO: COMPRAS"
	LET usuario	= "USUARIO: ", vg_usuario
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', "LISTADO DETALLE ORDENES DE COMPRA", 80)
		RETURNING titulo
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi
	PRINT COLUMN 01,  rm_g01.g01_razonsocial,
	      COLUMN 150, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 01,  modulo CLIPPED,
	      COLUMN 39,  titulo CLIPPED,
	      COLUMN 154, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	IF rm_par.estado = 'T' THEN
		PRINT COLUMN 20, "** ESTADO              : T O D A S"
	ELSE
		IF rm_par.estado = 'A' THEN
			PRINT COLUMN 20, "** ESTADO              : ACTIVAS"
		ELSE
			IF rm_par.estado = 'P' THEN
				PRINT COLUMN 20, "** ESTADO              : APROBADAS"
			ELSE
				--#IF rm_par.estado = 'C' THEN
					PRINT COLUMN 20, "** ESTADO              : CERRADAS"
				--#END IF
			END IF
		END IF
	END IF
	PRINT COLUMN 20, "** MONEDA              : ", rm_par.g13_nombre
	PRINT COLUMN 20, "** FECHA INICIAL       : ", 
			rm_par.fecha_ini USING "dd-mm-yyyy",
	      COLUMN 80, "** FECHA FINAL         : ", 
	      		rm_par.fecha_fin USING "dd-mm-yyyy"
	--#IF rm_par.c01_aux_cont IS NOT NULL THEN
		CALL fl_lee_cuenta(vg_codcia, rm_par.c01_aux_cont)
			RETURNING r_b10.*
		PRINT COLUMN 20, "** AUX. CONTA. PARA IVA: ",
			rm_par.c01_aux_cont, ' ', r_b10.b10_descripcion
	--#END IF
	--#IF rm_par.tipo_oc IS NOT NULL THEN
		PRINT COLUMN 20, "** TIPO ORDEN DE COMPRA: ", rm_par.n_tipo_oc
	--#END IF
	--#IF rm_par.dpto IS NOT NULL THEN
		PRINT COLUMN 20, "** DEPARTAMENTO        : ", rm_par.n_dpto
	--#END IF
	--#IF rm_par.codprov IS NOT NULL THEN
		PRINT COLUMN 20, "** PROVEEDOR           : ", rm_par.nomprov
	--#END IF
	SKIP 1 LINES
	PRINT COLUMN 01, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 142, usuario
	SKIP 1 LINES
	PRINT COLUMN 01,  "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 01,  "FECHA ING.",
	      COLUMN 12,  "E",
	      COLUMN 14,  "TIPO OC",
	      COLUMN 23,  "# O.C.",
	      COLUMN 30,  "PROVEEDOR",
	      COLUMN 56,  "FACTURA",
	      COLUMN 72,  "FECHA FACT",
	      COLUMN 83,  "   FLETE",
	      COLUMN 92,  "   OTROS",
	      COLUMN 101, " VALOR BRUTO",
	      COLUMN 114, "VALOR DSCT",
	      COLUMN 125, "    SUBTOTAL",
	      COLUMN 138, "VALOR IMPT",
	      COLUMN 149, "  VALOR NETO"
	PRINT COLUMN 01,  "----------------------------------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 01,  r_det.fecha_ing USING "dd-mm-yyyy",
	      COLUMN 12,  UPSHIFT(r_det.estado),
	      COLUMN 14,  r_det.tipo_oc[1,8],
	      COLUMN 23,  r_det.numero_oc USING "#####&",
	      COLUMN 30,  r_det.nomprov[1,25] CLIPPED,
	      COLUMN 56,  r_det.factura,
	      COLUMN 72,  r_det.fecha_fact  USING "dd-mm-yyyy",
	      COLUMN 83,  r_det.flete       USING "#,##&.##",
	      COLUMN 92,  r_det.otros       USING "#,##&.##",
	      COLUMN 101, r_det.valor_bruto USING "#,###,##&.##",
	      COLUMN 114, r_det.valor_dscto USING "###,##&.##",
	      COLUMN 125, r_det.subtotal    USING "#,###,##&.##",
	      COLUMN 138, r_det.valor_impto USING "###,##&.##",
	      COLUMN 149, r_det.valor_neto  USING "#,###,##&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 83,  "--------",
	      COLUMN 92,  "--------",
	      COLUMN 101, "------------",
	      COLUMN 114, "----------",
	      COLUMN 125, "------------",
	      COLUMN 138, "----------",
	      COLUMN 149, "------------"	
	PRINT COLUMN 83,  SUM(r_det.flete)       USING "#,##&.##",
	      COLUMN 92,  SUM(r_det.otros)       USING "#,##&.##",
	      COLUMN 101, SUM(r_det.valor_bruto) USING "#,###,##&.##",
	      COLUMN 114, SUM(r_det.valor_dscto) USING "###,##&.##",
	      COLUMN 125, SUM(r_det.subtotal)	 USING "#,###,##&.##",
	      COLUMN 138, SUM(r_det.valor_impto) USING "###,##&.##",
	      COLUMN 149, SUM(r_det.valor_neto)  USING "#,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



REPORT rep_tot_prov(r_prov)
DEFINE r_prov		RECORD 
				codprov		LIKE cxpt001.p01_codprov,
				nomprov		LIKE cxpt001.p01_nomprov,
				cedruc		LIKE cxpt001.p01_num_doc,
				--tipo_prov	LIKE gent012.g12_nombre,
				estado		CHAR(1),
				flete		LIKE ordt010.c10_flete,
				otros		LIKE ordt010.c10_otros,
				valor_bruto	LIKE ordt010.c10_tot_compra,
				valor_dscto	LIKE ordt010.c10_tot_dscto,
				subtotal	DECIMAL(14,2),
				valor_impto	LIKE ordt010.c10_tot_impto,
				valor_neto	LIKE ordt010.c10_tot_compra,
				porc_iva	LIKE cxpt028.p28_porcentaje,
				val_ret_iva	LIKE cxpt028.p28_valor_ret,
				porc_fte	LIKE cxpt028.p28_porcentaje,
				val_ret_fte	LIKE cxpt028.p28_valor_ret
			END RECORD
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	160
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET modulo  	= "MODULO: COMPRAS"
	LET usuario	= "USUARIO: ", vg_usuario
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', "LISTADO RESUMEN POR PROVEEDORES DE O/C",
				80)
		RETURNING titulo
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi
	PRINT COLUMN 01,  rm_g01.g01_razonsocial,
	      COLUMN 150, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 01,  modulo CLIPPED,
	      COLUMN 36,  titulo CLIPPED,
	      COLUMN 154, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	IF rm_par.estado = 'T' THEN
		PRINT COLUMN 20, "** ESTADO ORDEN COMPRA : T O D A S"
	ELSE
		IF rm_par.estado = 'A' THEN
			PRINT COLUMN 20, "** ESTADO ORDEN COMPRA : ACTIVAS"
		ELSE
			IF rm_par.estado = 'P' THEN
				PRINT COLUMN 20, "** ESTADO ORDEN COMPRA : APROBADAS"
			ELSE
				--#IF rm_par.estado = 'C' THEN
					PRINT COLUMN 20, "** ESTADO ORDEN COMPRA : CERRADAS"
				--#END IF
			END IF
		END IF
	END IF
	PRINT COLUMN 20, "** MONEDA              : ", rm_par.g13_nombre
	PRINT COLUMN 20, "** FECHA INICIAL       : ", 
			rm_par.fecha_ini USING "dd-mm-yyyy",
	      COLUMN 80, "** FECHA FINAL         : ", 
	      		rm_par.fecha_fin USING "dd-mm-yyyy"
	--#IF rm_par.c01_aux_cont IS NOT NULL THEN
		CALL fl_lee_cuenta(vg_codcia, rm_par.c01_aux_cont)
			RETURNING r_b10.*
		PRINT COLUMN 20, "** AUX. CONTA. PARA IVA: ",
			rm_par.c01_aux_cont, ' ', r_b10.b10_descripcion
	--#END IF
	--#IF rm_par.dpto IS NOT NULL THEN
		PRINT COLUMN 20, "** DEPARTAMENTO        : ", rm_par.n_dpto
	--#END IF
	SKIP 1 LINES
	PRINT COLUMN 01, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 142, usuario
	SKIP 1 LINES
	PRINT COLUMN 01,  "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 01,  "COD.",
	      COLUMN 07,  "PROVEEDOR",
	      COLUMN 52,  "CEDULA/RUC",
	      COLUMN 74,  "E",
	      COLUMN 77,  "   FLETE",
	      COLUMN 87,  "   OTROS",
	      COLUMN 97,  " VALOR BRUTO",
	      COLUMN 111, "VALOR DSCT",
	      COLUMN 123, "    SUBTOTAL",
	      COLUMN 137, "VALOR IMPT",
	      COLUMN 149, "  VALOR NETO"
	PRINT COLUMN 01,  "----------------------------------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 01,  r_prov.codprov     USING "###&&",
	      COLUMN 07,  r_prov.nomprov[1, 44] CLIPPED,
	      COLUMN 52,  r_prov.cedruc,
	      COLUMN 74,  UPSHIFT(r_prov.estado),
	      COLUMN 77,  r_prov.flete       USING "#,##&.##",
	      COLUMN 87,  r_prov.otros       USING "#,##&.##",
	      COLUMN 97,  r_prov.valor_bruto USING "#,###,##&.##",
	      COLUMN 111, r_prov.valor_dscto USING "###,##&.##",
	      COLUMN 123, r_prov.subtotal    USING "#,###,##&.##",
	      COLUMN 137, r_prov.valor_impto USING "###,##&.##",
	      COLUMN 149, r_prov.valor_neto  USING "#,###,##&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 77,  "--------",
	      COLUMN 87,  "--------",
	      COLUMN 97,  "------------",
	      COLUMN 111, "----------",
	      COLUMN 123, "------------",
	      COLUMN 137, "----------",
	      COLUMN 149, "------------"	
	PRINT COLUMN 77,  SUM(r_prov.flete)       USING "#,##&.##",
	      COLUMN 87,  SUM(r_prov.otros)       USING "#,##&.##",
	      COLUMN 97,  SUM(r_prov.valor_bruto) USING "#,###,##&.##",
	      COLUMN 111, SUM(r_prov.valor_dscto) USING "###,##&.##",
	      COLUMN 123, SUM(r_prov.subtotal)	  USING "#,###,##&.##",
	      COLUMN 137, SUM(r_prov.valor_impto) USING "###,##&.##",
	      COLUMN 149, SUM(r_prov.valor_neto)  USING "#,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION ordenar_por()
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE asc_ant		CHAR
DEFINE desc_ant		CHAR
DEFINE campo		VARCHAR(20)
DEFINE col_ant		VARCHAR(20)

CALL set_count(num_ord)
INPUT ARRAY rm_ord WITHOUT DEFAULTS FROM rm_ord.* 
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2) 
		IF INFIELD(col) THEN
			CALL ayuda_campos() RETURNING campo
			IF campo IS NOT NULL THEN
				LET rm_ord[i].col = campo
				DISPLAY rm_ord[i].col TO rm_ord[i].col
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
		LET i = arr_curr()
	AFTER FIELD col
		IF rm_ord[i].col IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Debe elegir una columna.','exclamation')
			CALL fl_mostrar_mensaje('Debe elegir una columna.','exclamation')
			NEXT FIELD col	
		END IF
		LET campo = rm_ord[i].col
		FOR j = 1 TO num_ord
			IF j <> i AND rm_ord[j].col = campo THEN
				--CALL fgl_winmessage(vg_producto,'No puede ordenar dos veces sobre el mismo campo.','exclamation')
				CALL fl_mostrar_mensaje('No puede ordenar dos veces sobre el mismo campo.','exclamation')
				NEXT FIELD col
			END IF
		END FOR
		INITIALIZE campo TO NULL
		FOR j = 1 TO num_campos
			IF rm_ord[i].col = rm_campos[j].nombre THEN
				LET campo = 'OK'
				EXIT FOR
			END IF
		END FOR
		IF campo IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Campo no existe.','exclamation')
			CALL fl_mostrar_mensaje('Campo no existe.','exclamation')
			NEXT FIELD col
		END IF
		DISPLAY rm_ord[i].col TO rm_ord[i].col
	BEFORE FIELD chk_asc
		LET asc_ant = rm_ord[i].chk_asc
	AFTER FIELD chk_asc
		IF rm_ord[i].chk_asc <> asc_ant THEN
			IF rm_ord[i].chk_asc = 'S' THEN
				LET rm_ord[i].chk_desc = 'N'
			ELSE
				LET rm_ord[i].chk_desc = 'S'
			END IF
			DISPLAY rm_ord[i].* TO rm_ord[i].*
		END IF
	BEFORE FIELD chk_desc
		LET desc_ant = rm_ord[i].chk_desc
	AFTER FIELD chk_desc
		IF rm_ord[i].chk_desc <> desc_ant THEN
			IF rm_ord[i].chk_desc = 'S' THEN
				LET rm_ord[i].chk_asc = 'N'
			ELSE
				LET rm_ord[i].chk_asc = 'S'
			END IF
			DISPLAY rm_ord[i].* TO rm_ord[i].*
		END IF
END INPUT

END FUNCTION



FUNCTION campos_forma()

LET rm_campos[1].nombre = 'NOMBRE PROVEEDOR'
LET rm_campos[1].posicion = 6
LET rm_campos[2].nombre = 'FECHA DE INGRESO'
LET rm_campos[2].posicion = 1
LET rm_campos[3].nombre = 'FECHA DE FACTURA'
LET rm_campos[3].posicion = 8
LET rm_campos[4].nombre = 'NUMERO O.C.'
LET rm_campos[4].posicion = 4
LET rm_campos[5].nombre = 'DEPARTAMENTO'
LET rm_campos[5].posicion = 5
LET num_campos = 5

END FUNCTION



FUNCTION ayuda_campos()
DEFINE rh_campos	ARRAY[11] OF VARCHAR(20)
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j, num_cols	SMALLINT

FOR i = 1 TO num_campos 
	LET rh_campos[i] = rm_campos[i].nombre
END FOR
LET filas_max = 100
LET num_cols  = 24
IF vg_gui =  0 THEN
	LET num_cols = 25
END IF
OPEN WINDOW wh AT 06, 15 WITH 09 ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_rep_2 FROM '../forms/ordf401_2'
ELSE
	OPEN FORM f_rep_2 FROM '../forms/ordf401_2c'
END IF
DISPLAY FORM f_rep_2
--#LET filas_pant = fgl_scr_size("rh_campos")
IF vg_gui = 0 THEN
	LET filas_pant = 5
END IF
CALL set_count(num_campos)
LET int_flag = 0
DISPLAY ARRAY rh_campos TO rh_campos.*
        ON KEY(RETURN)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', num_campos
END DISPLAY
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh_campos[1] TO NULL
        RETURN rh_campos[1]
END IF
LET  i = arr_curr()
RETURN rh_campos[i]

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



FUNCTION muestra_estado(estado)
DEFINE estado		CHAR(1)

CASE estado
	WHEN 'A'
		DISPLAY 'ACTIVA' TO tit_estado
	WHEN 'P'
		DISPLAY 'APROBADA' TO tit_estado
	WHEN 'C'
		DISPLAY 'CERRADA' TO tit_estado
	WHEN 'T'
		DISPLAY 'T O D A S' TO tit_estado
	OTHERWISE
		CLEAR estado, tit_estado
END CASE

END FUNCTION



FUNCTION muestra_tipo(tipo)
DEFINE tipo		CHAR(1)

CASE tipo
	WHEN 'D'
		DISPLAY 'DETALLE O/C'         TO tit_tipo_rep
	WHEN 'R'
		DISPLAY 'RESUMEN PROVEEDORES' TO tit_tipo_rep
	WHEN 'T'
		DISPLAY 'T O D A S'           TO tit_tipo_rep
	OTHERWISE
		CLEAR tipo_reporte, tit_tipo_rep
END CASE

END FUNCTION
