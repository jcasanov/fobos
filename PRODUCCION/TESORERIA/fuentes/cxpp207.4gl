--------------------------------------------------------------------------------
-- Titulo           : cxpp207.4gl - Ingreso comprobantes de retención
-- Elaboracion      : 17-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp207 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_p27		RECORD LIKE cxpt027.*
DEFINE rm_p29		RECORD LIKE cxpt029.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_total         DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_num_ret	LIKE cxpt027.p27_num_ret
DEFINE rm_det		ARRAY [1000] OF RECORD
				p20_tipo_doc	LIKE cxpt020.p20_tipo_doc,
				p20_num_doc	LIKE cxpt020.p20_num_doc,
				p20_fecha_emi	LIKE cxpt020.p20_fecha_emi,
				p20_valor_fact	LIKE cxpt020.p20_valor_fact,
				tit_valor_ret	DECIMAL(12,2)
			END RECORD
DEFINE rm_refer		ARRAY [1000] OF LIKE cxpt020.p20_referencia

DEFINE vm_retencion	CHAR(2)
DEFINE ind_max_ret	SMALLINT
DEFINE ind_ret		SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE r_ret 		ARRAY[500] OF RECORD
				check		CHAR(1),
				n_retencion	LIKE ordt002.c02_nombre,
				c_sri		LIKE cxpt005.p05_codigo_sri,
				tipo_ret	LIKE cxpt005.p05_tipo_ret, 
				val_base	LIKE rept019.r19_tot_bruto, 
				porc		LIKE cxpt005.p05_porcentaje, 
				subtotal 	LIKE rept019.r19_tot_neto
			END RECORD
DEFINE fec_ini_porc	ARRAY[500] OF LIKE cxpt005.p05_fecha_ini_porc
DEFINE r_ret_aux	ARRAY[500] OF RECORD
				check		CHAR(1),
				n_retencion	LIKE ordt002.c02_nombre,
				c_sri		LIKE cxpt005.p05_codigo_sri,
				tipo_ret	LIKE cxpt005.p05_tipo_ret, 
				val_base	LIKE rept019.r19_tot_bruto, 
				porc		LIKE cxpt005.p05_porcentaje, 
				subtotal 	LIKE rept019.r19_tot_neto
			END RECORD
DEFINE fec_ini_porc_a	ARRAY[500] OF LIKE cxpt005.p05_fecha_ini_porc
DEFINE iva_bien		DECIMAL(11,2)
DEFINE iva_servi	DECIMAL(11,2)
DEFINE val_bienes	LIKE rept019.r19_tot_bruto
DEFINE val_servi	LIKE rept019.r19_tot_bruto
DEFINE val_impto	LIKE rept019.r19_tot_dscto
DEFINE val_neto		LIKE rept019.r19_tot_neto
DEFINE tot_ret		LIKE rept019.r19_tot_neto
------------------------------------------------------
---- DEFINICION DE LOS CAMPOS DE LA VENTANA DE FORMA DE PAGO ----

DEFINE vm_filas_pant		SMALLINT

DEFINE tot_dias			SMALLINT	
DEFINE pagos			SMALLINT
DEFINE fecha_pago		DATE
DEFINE dias_pagos		SMALLINT
DEFINE c10_interes		LIKE ordt010.c10_interes
DEFINE tot_compra		LIKE ordt010.c10_tot_compra
DEFINE tot_cap			LIKE ordt010.c10_tot_compra
DEFINE tot_int			LIKE ordt010.c10_tot_compra
DEFINE tot_sub			LIKE ordt010.c10_tot_compra
---------------------------------------------------------------
DEFINE rm_retsri	ARRAY[10000] OF RECORD
			c03_codigo_sri		LIKE ordt003.c03_codigo_sri,
			c03_concepto_ret	LIKE ordt003.c03_concepto_ret,
			c03_fecha_ini_porc	LIKE ordt003.c03_fecha_ini_porc,
			c03_fecha_fin_porc	LIKE ordt003.c03_fecha_fin_porc,
			c03_ingresa_proc	LIKE ordt003.c03_ingresa_proc,
			tipo_imp		CHAR(1)
			END RECORD
DEFINE vm_num_det2	INTEGER
DEFINE vm_max_det2	INTEGER
DEFINE rm_c03		RECORD LIKE ordt003.*
---------------------------------------------------------------



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
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
CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_max_det   = 1000
LET vm_max_det2  = 10000
LET vm_retencion = 'RT'
LET ind_max_ret	 = 500
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
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxp FROM "../forms/cxpf207_1"
ELSE
	OPEN FORM f_cxp FROM "../forms/cxpf207_1c"
END IF
DISPLAY FORM f_cxp
CREATE TEMP TABLE tmp_detalle_ret(
		p20_tipo_doc	CHAR(2)		NOT NULL,
		p20_num_doc	CHAR(21)	NOT NULL,
		p20_fecha_emi	DATE,
		p20_valor_fact	DECIMAL(12,2),
		tit_valor_ret	DECIMAL(12,2),
		p20_referencia	VARCHAR(30,20)
	)
CREATE UNIQUE INDEX tmp_pk1
	ON tmp_detalle_ret(p20_tipo_doc, p20_num_doc)
CREATE TEMP TABLE tmp_retenciones(
		tipo_doc	CHAR(2)      NOT NULL,
		num_doc		CHAR(21)     NOT NULL,
		tipo_ret	CHAR(1)      NOT NULL,
		porc		DECIMAL(5,2) NOT NULL,
		val_base	DECIMAL(12,2),
		subtotal 	DECIMAL(12,2),
		codi_sri	VARCHAR(15,6) NOT NULL,
		fec_ini_por	DATE	      NOT NULL
	)
CREATE UNIQUE INDEX tmp_pk2
	ON tmp_retenciones(tipo_doc, num_doc, tipo_ret, porc, codi_sri,
				fec_ini_por)
CREATE TEMP TABLE tmp_tipo_porc(
		tipodoc		CHAR(2)		NOT NULL,
		numdoc		CHAR(21)	NOT NULL,
		tiporet		CHAR(1)		NOT NULL,
		porcen		DECIMAL(5,2)	NOT NULL,
		codigo_sri	VARCHAR(15,6)	NOT NULL,
		fecha_ini_por	DATE		NOT NULL,
		concepto_ret	VARCHAR(200,100) NOT NULL
	)
CREATE UNIQUE INDEX tmp_pk3
	ON tmp_tipo_porc(tipodoc, numdoc, tiporet, porcen, codigo_sri,
			fecha_ini_por)
LET vm_scr_lin = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,k,col,done	SMALLINT
DEFINE query		CHAR(1000)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_cxp_aux	RECORD LIKE cxpt020.*
DEFINE l,retenciones	SMALLINT
DEFINE cont_p		SMALLINT
DEFINE valor_ret	DECIMAL(12,2)
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE tot_reten	LIKE cxpt022.p22_total_cap

LET rm_p27.p27_estado  = 'A'
LET rm_p27.p27_paridad = 1
LET rm_p27.p27_usuario = vg_usuario
LET rm_p27.p27_fecing  = fl_current()
LET rm_p27.p27_moneda  = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_p27.p27_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
       	--CALL fgl_winmessage(vg_producto,'Moneda no existe moneda base.','stop')
	CALL fl_mostrar_mensaje('Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
CALL muestra_estado()
DISPLAY r_mon.g13_nombre TO tit_moneda
DISPLAY BY NAME rm_p27.p27_paridad, rm_p27.p27_usuario, rm_p27.p27_fecing
WHILE TRUE
	LET vm_num_det = 0
	CLEAR p20_referencia
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	DELETE FROM tmp_detalle_ret
	INSERT INTO tmp_detalle_ret
		SELECT p20_tipo_doc, p20_num_doc, MIN(p20_fecha_emi),
			p20_valor_fact, 0, p20_referencia
			FROM cxpt020
			WHERE p20_compania  = vg_codcia
			  AND p20_localidad = vg_codloc
			  AND p20_codprov   = rm_p27.p27_codprov
			  AND p20_dividendo = 1
			  AND p20_moneda    = rm_p27.p27_moneda
			  AND NOT EXISTS
				(SELECT 1 FROM cxpt028, cxpt027
				WHERE p28_compania  = p20_compania
				  AND p28_localidad = p20_localidad
				  AND p28_codprov   = p20_codprov
				  AND p28_tipo_doc  = p20_tipo_doc
			 	  AND p28_num_doc   = p20_num_doc
			  	  AND p27_compania  = p28_compania
			  	  AND p27_localidad = p28_localidad
			 	  AND p27_num_ret   = p28_num_ret
			  	  AND p27_estado    = 'A')
			GROUP BY 1, 2, 4, 5, 6
			HAVING SUM(p20_saldo_cap + p20_saldo_int) > 0
	SELECT COUNT(*) INTO vm_num_det FROM tmp_detalle_ret
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[3]  = 'DESC'
	LET vm_columna_1 = 3
	LET vm_columna_2 = 4
	LET col          = 3
	WHILE TRUE
		LET query = 'SELECT * FROM tmp_detalle_ret ',
				" ORDER BY ", vm_columna_1, ' ',
					rm_orden[vm_columna_1],
			    		', ', vm_columna_2, ' ',
					rm_orden[vm_columna_2]
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET k = 1
		FOREACH q_deto INTO rm_det[k].*, rm_refer[k]
			LET k = k + 1
			IF k > vm_max_det THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET k = k - 1
		CALL sacar_total()
		CALL set_count(k)
		LET int_flag = 0
		DISPLAY ARRAY rm_det TO rm_det.*
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel('ACCEPT','')
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#LET j = scr_line()
				--#LET rm_p27.p27_fecing  = fl_current()
				--#CALL muestra_contadores_det(i)
				--#DISPLAY rm_refer[i] TO p20_referencia
				--#DISPLAY BY NAME rm_p27.p27_fecing
				--#CALL sacar_total()
			--#AFTER DISPLAY 
				--#CONTINUE DISPLAY
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
        		ON KEY(F1,CONTROL-W)
				CALL control_visor_teclas_caracter_1() 
			ON KEY(F5)
				LET i = arr_curr()
				LET j = scr_line()
				CALL cuantas_retenciones(i) RETURNING l
				--#IF l > 0 THEN
					--#CALL fl_mostrar_mensaje('Comprobante ya tiene retención.','exclamation')
					--#CONTINUE DISPLAY
				--#END IF
				CALL fl_lee_proveedor_localidad(vg_codcia,
						vg_codloc, rm_p27.p27_codprov)
					RETURNING r_p02.*
				--#IF r_p02.p02_email IS NULL THEN
					--#CALL fl_mostrar_mensaje('El Proveedor no tiene configurado la cuenta de correo, configuresela en el mantenimiento de proveedores.','exclamation')
					--CONTINUE DISPLAY
				--#END IF
				IF l = 0 THEN
					LET tot_ret = 0
					SELECT COUNT(*) INTO ind_ret
						FROM tmp_retenciones
						WHERE tipo_doc =
							rm_det[i].p20_tipo_doc
						  AND num_doc  =
							rm_det[i].p20_num_doc
					IF ind_ret = 0 THEN
					       CALL fl_lee_documento_deudor_cxp(
							vg_codcia, vg_codloc,
							rm_p27.p27_codprov,
							rm_det[i].p20_tipo_doc,
							rm_det[i].p20_num_doc,1)
							RETURNING r_cxp_aux.*
						CALL retencion_cxp(r_cxp_aux.*)
					END IF
					CALL carga_retenciones(i)
					CALL muestra_retenciones(i)
					IF int_flag THEN
						LET int_flag = 0
						--#CONTINUE DISPLAY
					ELSE
					  LET rm_det[i].tit_valor_ret = tot_ret
					  DISPLAY rm_det[i].tit_valor_ret
						TO rm_det[j].tit_valor_ret
					  UPDATE tmp_detalle_ret
						SET tit_valor_ret =
							rm_det[i].tit_valor_ret 
						WHERE p20_tipo_doc =
							rm_det[i].p20_tipo_doc 
						  AND p20_num_doc  =
							rm_det[i].p20_num_doc 
					  LET int_flag = 0
					SELECT SUM(tit_valor_ret) INTO valor_ret
						FROM tmp_detalle_ret
					SELECT COUNT(*) INTO ind_ret
						FROM tmp_retenciones
						WHERE tipo_doc =
							rm_det[i].p20_tipo_doc
						  AND num_doc  =
							rm_det[i].p20_num_doc
					SELECT COUNT(*) INTO cont_p
						FROM tmp_retenciones
						WHERE porc = 0.00
					IF (cont_p = 0 AND valor_ret = 0) OR
					    ind_ret = 0
					THEN
						CALL fl_mostrar_mensaje('No ha hecho retenciones en nigún comprobante.','exclamation')
						--#CONTINUE DISPLAY
					ELSE
						BEGIN WORK
						LET done = graba_retenciones()
						IF NOT done THEN
							ROLLBACK WORK
							--#CONTINUE DISPLAY
						ELSE
						IF valor_ret > 0 THEN
						  IF NOT numero_sri() THEN
							ROLLBACK WORK
							EXIT PROGRAM
						  END IF
						END IF
						  CALL graba_ajuste_retencion() RETURNING tot_reten
						IF tot_reten > 0 THEN
						  CALL contabilizacion_ret(i)
							RETURNING r_b12.*
						END IF
						  DELETE FROM tmp_retenciones
						  COMMIT WORK
						IF tot_reten > 0 THEN
						  CALL fl_lee_compania_contabilidad(vg_codcia)
							RETURNING r_b00.*
						  IF r_b00.b00_mayo_online = 'S'
						  THEN
							CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp, r_b12.b12_num_comp, 'M')
						  END IF
						END IF
						  CALL fl_lee_retencion_cxp(
							vg_codcia, vg_codloc,
							vm_num_ret)
							RETURNING r_p27.*
						IF tot_reten > 0 THEN
						  CALL imprime_retenciones(
									r_p27.*)
						END IF
						CALL generar_doc_elec(r_p27.p27_num_ret)
						  CALL fl_mensaje_registro_ingresado()
						  LET int_flag = 0
						END IF
					END IF

					END IF
				END IF
			{--
			ON KEY(F6)
				LET i = arr_curr()
				LET j = scr_line()
				CALL cuantas_retenciones(i) RETURNING l
				--#IF l > 0 THEN
					--CALL fgl_winmessage(vg_producto,'Comprobante ya tiene retención.','exclamation')
					--#CALL fl_mostrar_mensaje('Comprobante ya tiene retención.','exclamation')
					--#CONTINUE DISPLAY
				--#END IF
				IF l = 0 THEN
					SELECT SUM(tit_valor_ret) INTO valor_ret
						FROM tmp_detalle_ret
					SELECT COUNT(*) INTO ind_ret
						FROM tmp_retenciones
						WHERE tipo_doc =
							rm_det[i].p20_tipo_doc
						  AND num_doc  =
							rm_det[i].p20_num_doc
					IF valor_ret = 0 OR ind_ret = 0 THEN
						CALL fl_mostrar_mensaje('No ha hecho retenciones en nigún comprobante.','exclamation')
						--#CONTINUE DISPLAY
					ELSE
						BEGIN WORK
						LET done = graba_retenciones()
						IF NOT done THEN
							ROLLBACK WORK
							--#CONTINUE DISPLAY
						ELSE
						  IF NOT numero_sri() THEN
							ROLLBACK WORK
							EXIT PROGRAM
						  END IF
						  CALL graba_ajuste_retencion() RETURNING tot_reten
						  CALL contabilizacion_ret(i)
							RETURNING r_b12.*
						  DELETE FROM tmp_retenciones
						  COMMIT WORK
						  CALL fl_lee_retencion_cxp(
							vg_codcia, vg_codloc,
							vm_num_ret)
							RETURNING r_p27.*
						  CALL imprime_retenciones(
									r_p27.*)
						  CALL fl_mensaje_registro_ingresado()
						  LET int_flag = 0
						END IF
					END IF
				END IF
			--}
			ON KEY(F6)
				LET i = arr_curr()
				LET j = scr_line()
				CALL ver_contabilizacion(i)
				LET int_flag = 0
			ON KEY(F7)
				CALL ver_estado_cuenta()
				LET int_flag = 0
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
		END DISPLAY
		IF int_flag = 1 THEN
			EXIT WHILE
		END IF
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
	END WHILE
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_mon_par	RECORD LIKE gent014.*
DEFINE r_pro		RECORD LIKE cxpt001.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE codprov		LIKE cxpt027.p27_codprov
DEFINE nomprov		LIKE cxpt001.p01_nomprov

INITIALIZE mone_aux, codprov TO NULL
LET int_flag = 0
INPUT BY NAME rm_p27.p27_codprov, rm_p27.p27_moneda
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(p27_codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING codprov, nomprov
                       	IF codprov IS NOT NULL THEN
                             	LET rm_p27.p27_codprov = codprov
                               	DISPLAY BY NAME rm_p27.p27_codprov
                               	DISPLAY nomprov TO tit_nombre_pro
                        END IF
                END IF
		IF INFIELD(p27_moneda) THEN
               		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
       		      	LET int_flag = 0
                      	IF mone_aux IS NOT NULL THEN
                              	LET rm_p27.p27_moneda = mone_aux
                               	DISPLAY BY NAME rm_p27.p27_moneda
                               	DISPLAY nomm_aux TO tit_moneda
                       	END IF
                END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD p27_moneda
               	IF rm_p27.p27_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(rm_p27.p27_moneda)
                               	RETURNING r_mon.*
                       	IF r_mon.g13_moneda IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                               	NEXT FIELD p27_moneda
                       	END IF
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD p20_moneda
			END IF
			IF rm_p27.p27_moneda = rg_gen.g00_moneda_base THEN
				LET r_mon_par.g14_tasa = 1
			ELSE
				CALL fl_lee_factor_moneda(rm_p27.p27_moneda,
							rg_gen.g00_moneda_base)
					RETURNING r_mon_par.*
				IF r_mon_par.g14_serial IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'La paridad para está moneda no existe.','exclamation')
					CALL fl_mostrar_mensaje('La paridad para está moneda no existe.','exclamation')
					NEXT FIELD p27_moneda
				END IF
			END IF
			LET rm_p27.p27_paridad = r_mon_par.g14_tasa
			DISPLAY BY NAME rm_p27.p27_paridad
               	ELSE
                       	LET rm_p27.p27_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(rm_p27.p27_moneda)
				RETURNING r_mon.*
                       	DISPLAY BY NAME rm_p27.p27_moneda
               	END IF
               	DISPLAY r_mon.g13_nombre TO tit_moneda
	AFTER FIELD p27_codprov
               	IF rm_p27.p27_codprov IS NOT NULL THEN
                       	CALL fl_lee_proveedor(rm_p27.p27_codprov)
                     		RETURNING r_pro.*
                        IF r_pro.p01_codprov IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'Proveedor no existe.','exclamation')
				CALL fl_mostrar_mensaje('Proveedor no existe.','exclamation')
                               	NEXT FIELD p27_codprov
                        END IF
			DISPLAY r_pro.p01_nomprov TO tit_nombre_pro
		ELSE
			CLEAR tit_nombre_pro
                END IF
END INPUT

END FUNCTION



FUNCTION retencion_cxp(r_cxp)
DEFINE r_cxp		RECORD LIKE cxpt020.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE r_p05		RECORD LIKE cxpt005.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE i		SMALLINT
DEFINE expr_o		VARCHAR(10)
DEFINE query		CHAR(800)

CALL fl_lee_proveedor(rm_p27.p27_codprov) RETURNING r_p01.*
LET val_servi  = 0
LET val_bienes = r_cxp.p20_valor_fact - r_cxp.p20_valor_impto
LET val_impto  = r_cxp.p20_valor_impto
LET val_neto   = r_cxp.p20_valor_fact
LET ind_ret    = 0
LET tot_ret    = 0

--LET expr_o = 'OUTER'
LET expr_o = NULL
IF r_p01.p01_cont_espe = 'S' AND r_p01.p01_ret_fuente = 'N' THEN
	LET expr_o = NULL
END IF
LET query = 'SELECT * FROM ordt002, ordt003, ', expr_o CLIPPED, ' cxpt005 ',
		' WHERE c02_compania       = ', vg_codcia,
                '   AND c02_estado         = "A" ' ,
		'   AND c03_compania       = c02_compania ',
		'   AND c03_tipo_ret       = c02_tipo_ret ',
		'   AND c03_porcentaje     = c02_porcentaje ',
                '   AND c03_estado         = "A" ',
	  	'   AND p05_compania       = c03_compania ',
	  	'   AND p05_codprov        = ', r_p01.p01_codprov,
	  	'   AND p05_tipo_ret       = c03_tipo_ret ',
	  	'   AND p05_porcentaje     = c03_porcentaje ',
	  	'   AND p05_codigo_sri     = c03_codigo_sri ',
	  	'   AND p05_fecha_ini_porc = c03_fecha_ini_porc ',
		' ORDER BY c03_tipo_ret, c03_porcentaje, c03_codigo_sri, ',
			'c03_fecha_ini_porc '
PREPARE cons_ret FROM query
DECLARE q_ret CURSOR FOR cons_ret
LET i = 1
FOREACH q_ret INTO r_c02.*, r_c03.*, r_p05.*
	IF r_c03.c03_tipo_ret = 'F' AND r_p01.p01_ret_fuente = 'N' THEN
		CONTINUE FOREACH
	END IF
	IF r_c03.c03_tipo_ret = 'I' AND r_p01.p01_ret_impto = 'N' THEN
		CONTINUE FOREACH
	END IF
	LET r_ret[i].n_retencion = r_c02.c02_nombre
	LET r_ret[i].tipo_ret    = r_c03.c03_tipo_ret
	LET r_ret[i].porc        = r_c03.c03_porcentaje
	LET r_ret[i].val_base    = 0
	LET r_ret[i].subtotal    = 0
	LET r_ret[i].check       = 'N'
	LET r_ret[i].c_sri       = r_c03.c03_codigo_sri
	LET fec_ini_porc[i]      = r_c03.c03_fecha_ini_porc
	IF r_p05.p05_tipo_ret IS NOT NULL AND
	   r_p05.p05_codigo_sri IS NOT NULL
	THEN
		LET r_ret[i].check = 'S'
		IF r_p05.p05_tipo_ret = 'I' THEN
			LET r_ret[i].val_base = val_impto
		ELSE
			LET r_ret[i].val_base = val_bienes
		END IF
		LET r_ret[i].subtotal = (r_ret[i].val_base * 
					(r_p05.p05_porcentaje / 100))
		LET tot_ret = tot_ret + r_ret[i].subtotal
	END IF
	LET r_ret_aux[i].* = r_ret[i].*
	LET fec_ini_porc_a[i] = fec_ini_porc[i]
	LET i = i + 1
	IF i > ind_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
LET ind_ret = i

END FUNCTION



FUNCTION muestra_retenciones(l)
DEFINE resp		CHAR(6)
DEFINE c		CHAR(1)
DEFINE salir,i,j,l,k	SMALLINT
DEFINE iva		SMALLINT
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE col_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE tiene_sri	SMALLINT
DEFINE sal_doc, tot_f	DECIMAL(14,2)
DEFINE tot_i		DECIMAL(14,2)
DEFINE cod_sri		LIKE cxpt028.p28_codigo_sri
DEFINE conce_sri	LIKE ordt003.c03_concepto_ret

LET lin_menu = 0
LET row_ini  = 4
LET col_ini  = 8
LET num_rows = 20
LET num_cols = 72
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 5
	LET col_ini  = 4
	LET num_rows = 18
	LET num_cols = 72
END IF
OPEN WINDOW w_for AT row_ini, col_ini WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_207_2 FROM '../forms/cxpf207_2'
ELSE
	OPEN FORM f_207_2 FROM '../forms/cxpf207_2c'
END IF
DISPLAY FORM f_207_2
CALL mostrar_detalle_forma()
CALL fl_lee_proveedor(rm_p27.p27_codprov) RETURNING r_p01.*
DISPLAY rm_det[l].p20_tipo_doc TO tit_tipo
DISPLAY rm_det[l].p20_num_doc TO tit_num
DISPLAY r_p01.p01_nomprov TO n_proveedor
DISPLAY BY NAME val_servi, val_bienes, val_impto, val_neto, tot_ret
OPTIONS INSERT KEY F40,
	DELETE KEY F41
INPUT BY NAME val_bienes, val_servi, val_impto, val_neto 
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(val_bienes, val_servi) THEN
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
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD val_bienes
		IF val_bienes IS NULL THEN
			LET val_bienes = 0
		END IF
		IF val_bienes > val_neto THEN
			--CALL fgl_winmessage(vg_producto,'Debe ingresar un valor menor valor neto.','exclamation')
			CALL fl_mostrar_mensaje('Debe ingresar un valor menor valor neto.','exclamation')
			NEXT FIELD val_bienes
		END IF
		LET val_servi = val_neto - val_impto - val_bienes
		DISPLAY BY NAME val_bienes, val_servi
	AFTER FIELD val_servi
		IF val_servi IS NULL THEN
			LET val_servi = 0
		END IF
		IF val_servi > val_neto THEN
			--CALL fgl_winmessage(vg_producto,'Debe ingresar un valor menor valor neto.','exclamation')
			CALL fl_mostrar_mensaje('Debe ingresar un valor menor valor neto.','exclamation')
			NEXT FIELD val_servi
		END IF			
		LET val_bienes = val_neto - val_impto - val_servi
		DISPLAY BY NAME val_bienes, val_servi
	AFTER INPUT
		IF (val_bienes + val_servi) <> (val_neto - val_impto) THEN
			--CALL fgl_winmessage(vg_producto,'Total neto menos iva debe ser igual al valor bienes mas valor servicios.','exclamation')
			CALL fl_mostrar_mensaje('Total neto menos iva debe ser igual al valor bienes mas valor servicios.','exclamation')
			CONTINUE INPUT
		END IF
--		LET iva_bien  = val_bienes * (r_p20.p20_porc_impto / 100)
--		LET iva_servi = val_servi  * (r_p20.p20_porc_impto / 100)
END INPUT
IF int_flag THEN
	CLOSE WINDOW w_for
	RETURN
END IF

LET tot_ret = 0
FOR i = 1 TO ind_ret
	IF r_ret[i].check = 'S' THEN
		CALL fl_lee_tipo_retencion(vg_codcia, r_ret[i].tipo_ret,
			r_ret[i].porc
		) RETURNING r_c02.*
		IF r_ret[i].tipo_ret = 'I' THEN
			CASE r_c02.c02_tipo_fuente
				WHEN 'B'
					LET r_ret[i].val_base = iva_bien
				WHEN 'S'
					LET r_ret[i].val_base = iva_servi
				WHEN 'T'
					LET r_ret[i].val_base = val_impto
			END CASE
		ELSE
			CASE r_c02.c02_tipo_fuente
				WHEN 'B'
					LET r_ret[i].val_base = val_bienes
				WHEN 'S'
					LET r_ret[i].val_base = val_servi
				WHEN 'T'
					LET r_ret[i].val_base = 
						val_servi + val_bienes
			END CASE
		END IF
		LET r_ret[i].subtotal = (r_ret[i].val_base * 
					(r_ret[i].porc / 100))	
		LET tot_ret = tot_ret + r_ret[i].subtotal
	END IF
END FOR

LET salir = 0
WHILE NOT salir
	IF ind_ret <= 0 THEN
		CALL fl_mostrar_mensaje('No hay datos a mostrar.','exclamation')
		LET int_flag = 1
		RETURN
		--LET ind_ret = 1
	END IF
	CALL set_count(ind_ret)
	INPUT ARRAY r_ret WITHOUT DEFAULTS FROM ra_ret.*
		ON KEY(INTERRUPT)
			FOR k = 1 TO ind_ret
				LET r_ret[k].* = r_ret_aux[k].*
				LET fec_ini_porc[k] = fec_ini_porc_a[k]
			END FOR
			LET int_flag = 1
			EXIT INPUT
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		{--
		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			IF r_ret[i].check = 'S' THEN
				CALL control_codigos_sri(i, l)
					RETURNING tiene_sri
				LET conce_sri = NULL
				SELECT codigo_sri, concepto_ret
					INTO r_ret[i].c_sri, conce_sri
					FROM tmp_tipo_porc
					WHERE tipodoc = rm_det[l].p20_tipo_doc
					  AND numdoc  = rm_det[l].p20_num_doc
					  AND tiporet = r_ret[i].tipo_ret
					  AND porcen  = r_ret[i].porc
				DISPLAY conce_sri TO tit_codigo_sri
				CALL fl_lee_codigos_sri(vg_codcia,
						r_ret[i].tipo_ret,
						r_ret[i].porc, r_ret[i].c_sri)
					RETURNING r_c03.*
				DISPLAY r_c03.c03_concepto_ret TO tit_codigo_sri
			END IF
			LET int_flag = 0
		--}
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT', '')
			--#CALL dialog.keysetlabel('DELETE', '')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F5","Códigos SRI")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			{--
			LET conce_sri = NULL
			SELECT concepto_ret INTO conce_sri
				FROM tmp_tipo_porc
				WHERE tipodoc = rm_det[l].p20_tipo_doc
				  AND numdoc  = rm_det[l].p20_num_doc
				  AND tiporet = r_ret[i].tipo_ret
				  AND porcen  = r_ret[i].porc
			DISPLAY conce_sri TO tit_codigo_sri
			--}
			CALL fl_lee_codigos_sri(vg_codcia, r_ret[i].tipo_ret,
						r_ret[i].porc, r_ret[i].c_sri,
						fec_ini_porc[i])
				RETURNING r_c03.*
			DISPLAY r_c03.c03_concepto_ret TO tit_codigo_sri
			DISPLAY i TO num_rows
			DISPLAY ind_ret TO max_rows
		BEFORE INSERT
			EXIT INPUT
		BEFORE DELETE
			EXIT INPUT
		BEFORE FIELD check
			LET c = r_ret[i].check
		AFTER FIELD check, val_base
			IF r_ret[i].check = 'S' THEN
				IF r_ret[i].val_base IS NULL OR 
				   r_ret[i].val_base = 0 THEN
					--CALL fgl_winmessage(vg_producto,'Digite valor base.', 'exclamation')
					CALL fl_mostrar_mensaje('Digite valor base.', 'exclamation')
					NEXT FIELD val_base
				END IF
				CALL fl_lee_tipo_retencion(vg_codcia, 
					r_ret[i].tipo_ret,
					r_ret[i].porc
				) RETURNING r_c02.*
	 	{
				IF r_ret[i].tipo_ret = 'I' THEN
					CASE r_c02.c02_tipo_fuente
					WHEN 'B'
						LET r_ret[i].val_base =
							iva_bien
					WHEN 'S'
						LET r_ret[i].val_base = 
							iva_servi
					WHEN 'T'
						LET r_ret[i].val_base = 
							val_impto
					END CASE
				ELSE
					CASE r_c02.c02_tipo_fuente
					WHEN 'B'
						LET r_ret[i].val_base = 
							val_bienes
					WHEN 'S'
						LET r_ret[i].val_base = 
							val_servi
					WHEN 'T'
						LET r_ret[i].val_base = 
						val_servi + val_bienes
					END CASE
				END IF
		}
				LET r_ret[i].subtotal = 
					(r_ret[i].val_base * 
					(r_ret[i].porc / 100))	
				LET tot_ret = tot_ret
						+ r_ret[i].subtotal
				DELETE FROM tmp_tipo_porc
					WHERE tipodoc   = rm_det[l].p20_tipo_doc
					  AND numdoc     = rm_det[l].p20_num_doc
					  AND tiporet    = r_ret[i].tipo_ret
					  AND porcen     = r_ret[i].porc
					  AND codigo_sri = r_ret[i].c_sri
					  AND fecha_ini_por = fec_ini_porc[i]
				INSERT INTO tmp_tipo_porc
					VALUES(rm_det[l].p20_tipo_doc,
						rm_det[l].p20_num_doc,
						r_ret[i].tipo_ret,r_ret[i].porc,
						r_ret[i].c_sri, fec_ini_porc[i],
						r_c03.c03_concepto_ret)
			END IF
			IF r_ret[i].check = 'N' THEN
				LET r_ret[i].val_base = 0
				LET r_ret[i].subtotal = 0
			END IF
			DISPLAY r_ret[i].* TO ra_ret[j].*
			LET tot_ret = 0
			FOR k = 1 TO ind_ret
				LET tot_ret = tot_ret + r_ret[k].subtotal
			END FOR
			DISPLAY BY NAME tot_ret
		AFTER INPUT 
			SELECT SUM(p20_saldo_cap + p20_saldo_int) INTO sal_doc
				FROM cxpt020
				WHERE p20_compania  = vg_codcia
				  AND p20_localidad = vg_codloc
				  AND p20_codprov   = rm_p27.p27_codprov
				  AND p20_tipo_doc  = rm_det[l].p20_tipo_doc
				  AND p20_num_doc   = rm_det[l].p20_num_doc
			IF tot_ret > sal_doc THEN
				CALL fl_mostrar_mensaje('El valor de las retenciones no debe ser mayor al saldo del documento.','exclamation')
				CONTINUE INPUT
			END IF
			IF tot_ret > val_neto THEN
				--CALL fgl_winmessage(vg_producto,'El valor de las retenciones no debe ser mayor al valor neto.','exclamation')
				CALL fl_mostrar_mensaje('El valor de las retenciones no debe ser mayor al valor neto.','exclamation')
				CONTINUE INPUT
			END IF
			LET iva   = 0
			LET tot_f = 0
			LET tot_i = 0
			FOR i = 1 TO ind_ret 
				IF r_ret[i].tipo_ret = 'F' THEN
					LET tot_f = tot_f + r_ret[i].val_base
				END IF
				IF r_ret[i].tipo_ret = 'I' THEN
					LET tot_i = tot_i + r_ret[i].val_base
				END IF
				IF r_ret[i].check = 'S'
				AND r_ret[i].tipo_ret = 'I' THEN
					LET iva = iva + r_ret[i].porc
				END IF
			END FOR
			IF iva > 100 THEN
				--CALL fgl_winmessage(vg_producto,'Las retenciones sobre el iva no pueden exceder al 100% del iva.','exclamation')
				CALL fl_mostrar_mensaje('Las retenciones sobre el iva no pueden exceder al 100% del iva.','exclamation')
				CONTINUE INPUT
			END IF
			CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
						rm_p27.p27_codprov,
						rm_det[l].p20_tipo_doc,
						rm_det[l].p20_num_doc, 1)
				RETURNING r_p20.*
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
						r_p20.p20_numero_oc)
				RETURNING r_c10.*
			IF r_c10.c10_valor_ice IS NULL THEN
				LET r_c10.c10_valor_ice = 0
			END IF
			IF tot_f > (val_neto - val_impto - r_c10.c10_valor_ice)
			THEN
				CALL fl_mostrar_mensaje('El total del valor base de retenciones, no puede exceder al valor base del documento.', 'exclamation')
				CONTINUE INPUT
			END IF
			IF tot_i > val_impto THEN
				CALL fl_mostrar_mensaje('El total del valor base de IVA, no puede exceder al valor base del impuesto.', 'exclamation')
				CONTINUE INPUT
			END IF
			{--
			IF NOT tiene_sri THEN
				CALL fl_mostrar_mensaje('Debe por lo menos seleccionar un código del SRI para esta retención.', 'exclamation')
				CONTINUE INPUT
			END IF
			--}
			LET salir = 1
			LET ind_ret = arr_count()
	END INPUT
	IF int_flag THEN
		SELECT SUM(subtotal) INTO tot_ret
			FROM tmp_retenciones
			WHERE tipo_doc = rm_det[l].p20_tipo_doc
	  		  AND num_doc  = rm_det[l].p20_num_doc
		IF tot_ret IS NULL THEN
			LET tot_ret = 0  
		END IF
		CLOSE WINDOW w_for
		RETURN
	END IF
	CALL elimina_retenciones(l)
	FOR j = 1 TO ind_ret
		IF r_ret[j].check = 'S' THEN
			{--
			LET cod_sri = NULL
			SELECT codigo_sri INTO cod_sri
				FROM tmp_tipo_porc
				WHERE tipodoc = rm_det[l].p20_tipo_doc
				  AND numdoc  = rm_det[l].p20_num_doc
				  AND tiporet = r_ret[j].tipo_ret
				  AND porcen  = r_ret[j].porc
			--}
			INSERT INTO tmp_retenciones 
				VALUES(rm_det[l].p20_tipo_doc,
					rm_det[l].p20_num_doc,   
	  	       			r_ret[j].tipo_ret,    
			       	       	r_ret[j].porc,
			       	       	r_ret[j].val_base,    
			       	       	r_ret[j].subtotal, r_ret[j].c_sri,
					fec_ini_porc[j])
		END IF
	END FOR
	IF int_flag THEN
		CLOSE WINDOW w_for
		RETURN
	END IF

END WHILE
CLOSE WINDOW w_for

END FUNCTION



FUNCTION contabilizacion_ret(i)
DEFINE i, j		SMALLINT
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b42		RECORD LIKE ctbt042.*
DEFINE r_p00		RECORD LIKE cxpt000.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE cuenta_cxp	LIKE ctbt010.b10_cuenta
DEFINE valor		DECIMAL(14,2)
DEFINE tot_val		DECIMAL(14,2)

INITIALIZE r_b12.*, cuenta_cxp TO NULL
CALL fl_lee_auxiliares_generales(vg_codcia, vg_codloc) RETURNING r_b42.*
IF r_b42.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado auxiliares contables para Retención.','exclamation')
	RETURN r_b12.*
END IF
CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, rm_p27.p27_codprov)
	RETURNING r_p02.*
IF r_p02.p02_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado auxiliares contables para este proveedor.','exclamation')
	RETURN r_b12.*
END IF
IF rm_p27.p27_moneda = rg_gen.g00_moneda_base THEN
	LET cuenta_cxp = r_p02.p02_aux_prov_mb
ELSE
	LET cuenta_cxp = r_p02.p02_aux_prov_ma
END IF
IF cuenta_cxp IS NULL THEN
	CALL fl_lee_compania_tesoreria(vg_codcia) RETURNING r_p00.*
	IF r_p00.p00_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe una compañía configurada en Tesorería.','exclamation')
		RETURN r_b12.*
	END IF
	IF rm_p27.p27_moneda = rg_gen.g00_moneda_base THEN
		LET cuenta_cxp = r_p00.p00_aux_prov_mb
	ELSE
		LET cuenta_cxp = r_p00.p00_aux_prov_ma
	END IF
END IF
DECLARE q_p28 CURSOR FOR
	SELECT cxpt028.* FROM cxpt028, cxpt027
		WHERE p28_compania  = vg_codcia
		  AND p28_localidad = vg_codloc
		  AND p28_codprov   = rm_p27.p27_codprov
		  AND p28_tipo_doc  = rm_det[i].p20_tipo_doc
		  AND p28_num_doc   = rm_det[i].p20_num_doc
		  AND p27_compania  = p28_compania
		  AND p27_localidad = p28_localidad
		  AND p27_num_ret   = p28_num_ret
		  AND p27_estado    <> 'E'
LET r_b12.b12_compania    = vg_codcia
LET r_b12.b12_tipo_comp   = 'DC'
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
                            	r_b12.b12_tipo_comp, YEAR(vg_fecha), MONTH(vg_fecha))
LET r_b12.b12_estado      = 'A'
LET r_b12.b12_subtipo     = NULL
CALL fl_lee_proveedor(rm_p27.p27_codprov) RETURNING r_p01.*
LET r_b12.b12_glosa       = r_p01.p01_nomprov CLIPPED, ' DOCUMENTO ',
				rm_det[i].p20_tipo_doc, '-',
				rm_det[i].p20_num_doc CLIPPED,
				' RETENCION No. ', vm_num_ret USING "<<<<<&"
				--' RETENCION No. ', rm_p29.p29_num_sri CLIPPED
LET r_b12.b12_benef_che   = NULL
LET r_b12.b12_num_cheque  = NULL
LET r_b12.b12_origen      = 'A'
LET r_b12.b12_moneda      = rm_p27.p27_moneda
LET r_b12.b12_paridad     = rm_p27.p27_paridad
LET r_b12.b12_fec_proceso = vg_fecha
LET r_b12.b12_fec_reversa = NULL
LET r_b12.b12_tip_reversa = NULL
LET r_b12.b12_num_reversa = NULL
LET r_b12.b12_fec_modifi  = NULL
LET r_b12.b12_modulo      = vg_modulo
LET r_b12.b12_usuario     = vg_usuario
LET r_b12.b12_fecing      = fl_current()
INSERT INTO ctbt012 VALUES(r_b12.*)
LET j       = 1
LET tot_val = 0
FOREACH q_p28 INTO r_p28.*
	LET valor = r_p28.p28_valor_ret * (-1)
	CALL grabar_detalle_cont(r_b12.*, r_p28.*, cuenta_cxp, valor, i, j, 1)
	LET j = j + 1
	LET tot_val = tot_val + r_p28.p28_valor_ret
END FOREACH 
CALL grabar_detalle_cont(r_b12.*, r_p28.*, cuenta_cxp, tot_val, i, j, 2)
UPDATE cxpt027 set p27_tip_contable = r_b12.b12_tipo_comp,
		   p27_num_contable = r_b12.b12_num_comp
	WHERE p27_compania  = vg_codcia
	  AND p27_localidad = vg_codloc
	  AND p27_num_ret   = vm_num_ret
RETURN r_b12.*

END FUNCTION



FUNCTION grabar_detalle_cont(r_b12, r_p28, cuenta_cxp, valor, i, j, flag)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE cuenta_cxp	LIKE ctbt010.b10_cuenta
DEFINE valor		DECIMAL(14,2)
DEFINE i, j, flag	SMALLINT
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_p01		RECORD LIKE cxpt001.*

INITIALIZE r_b13.* TO NULL
LET r_b13.b13_compania    = r_b12.b12_compania
LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
LET r_b13.b13_num_comp    = r_b12.b12_num_comp
LET r_b13.b13_secuencia   = j
LET r_b13.b13_tipo_doc    = NULL
CALL fl_lee_proveedor(rm_p27.p27_codprov) RETURNING r_p01.*
CASE flag
	WHEN 1
		CALL fl_lee_tipo_retencion(vg_codcia, r_p28.p28_tipo_ret,
						r_p28.p28_porcentaje)
			RETURNING r_c02.*
		LET r_b13.b13_cuenta = r_c02.c02_aux_cont
		{--
		LET r_b13.b13_glosa  = 'PROV. # ', rm_p27.p27_codprov
					USING "<<<<&", ' RET. # ', vm_num_ret
					USING "<<<<<&" CLIPPED, ' ',
					r_p28.p28_porcentaje USING "###.##"
		--}
		LET r_b13.b13_glosa  = '(', rm_p27.p27_codprov
					USING "<<<<&", ') ',
					r_p01.p01_nomprov[1, 20] CLIPPED, ' ',
					'FACT # ',rm_det[i].p20_num_doc CLIPPED,
					' RET # ',
					rm_p29.p29_num_sri CLIPPED
	WHEN 2
		LET r_b13.b13_cuenta = cuenta_cxp
		LET r_b13.b13_glosa  = 'RETENCION FACT # ',
					rm_det[i].p20_num_doc CLIPPED,
					--' RET # ', vm_num_ret USING "<<<<<&"
					' RET # ', rm_p29.p29_num_sri CLIPPED
		{--
		LET r_b13.b13_glosa  = 'PROV. # ', rm_p27.p27_codprov
					USING "<<<<&", ' DOC. # ',
					rm_det[i].p20_tipo_doc, '-',
					rm_det[i].p20_num_doc CLIPPED
		--}
END CASE
IF r_b13.b13_cuenta IS NULL THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe auxiliar contable para el Proveedor: ' || r_p01.p01_nomprov CLIPPED || '.', 'stop')
	EXIT PROGRAM
END IF
IF rm_p27.p27_moneda = rg_gen.g00_moneda_base THEN
	LET r_b13.b13_valor_base  = valor
	LET r_b13.b13_valor_aux   = 0
ELSE
	LET r_b13.b13_valor_base  = valor * rm_p27.p27_paridad
	LET r_b13.b13_valor_aux   = valor
END IF
LET r_b13.b13_num_concil  = NULL
LET r_b13.b13_filtro      = NULL
LET r_b13.b13_fec_proceso = vg_fecha
LET r_b13.b13_codcli      = NULL
LET r_b13.b13_codprov     = rm_p27.p27_codprov
LET r_b13.b13_pedido      = NULL
INSERT INTO ctbt013 VALUES(r_b13.*)

END FUNCTION



FUNCTION graba_ajuste_retencion()
DEFINE r_cxp,r_cxp2	RECORD LIKE cxpt020.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE i,orden		SMALLINT
DEFINE retencion	DECIMAL(12,2)
DEFINE dividendo	LIKE cxpt020.p20_dividendo

INITIALIZE r_p22.*, r_p23.* TO NULL
-- Graba Cabecera Ajuste Documento
LET r_p22.p22_compania  = vg_codcia
LET r_p22.p22_localidad = vg_codloc
LET r_p22.p22_codprov   = rm_p27.p27_codprov
LET r_p22.p22_tipo_trn  = 'AJ'
LET r_p22.p22_num_trn   = nextValInSequence('TE', r_p22.p22_tipo_trn)
IF r_p22.p22_num_trn = -1 THEN
	LET int_flag = 1
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'No puede generar la retención en este momento.','stop')
	CALL fl_mostrar_mensaje('No puede generar la retención en este momento.','stop')
	EXIT PROGRAM
END IF
LET r_p22.p22_referencia = 'RETENCION # ', vm_num_ret USING "<<<<<&"
LET r_p22.p22_fecha_emi  = vg_fecha
LET r_p22.p22_moneda     = rm_p27.p27_moneda
LET r_p22.p22_paridad    = rm_p27.p27_paridad
LET r_p22.p22_tasa_mora  = 0
SELECT SUM(subtotal) * (-1) INTO r_p22.p22_total_cap FROM tmp_retenciones
LET r_p22.p22_total_int  = 0
LET r_p22.p22_total_mora = 0
LET r_p22.p22_origen     = 'M'
LET r_p22.p22_usuario    = vg_usuario
LET r_p22.p22_fecing     = fl_current() 
INSERT INTO cxpt022 VALUES(r_p22.*)
--------------------------------------------------------------------------

LET r_p23.p23_compania   = r_p22.p22_compania
LET r_p23.p23_localidad  = r_p22.p22_localidad
LET r_p23.p23_codprov    = r_p22.p22_codprov
LET r_p23.p23_tipo_trn   = r_p22.p22_tipo_trn
LET r_p23.p23_num_trn    = r_p22.p22_num_trn
LET r_p23.p23_valor_int  = 0
LET r_p23.p23_valor_mora = 0
LET r_p23.p23_saldo_int  = 0
LET orden = 1

DECLARE q_ret3 CURSOR FOR 
	SELECT * FROM cxpt028
		WHERE p28_compania  = vg_codcia
		  AND p28_localidad = vg_codloc
		  AND p28_num_ret   = vm_num_ret
		ORDER BY p28_secuencia
FOREACH q_ret3 INTO r_p28.*
	LET r_p23.p23_tipo_doc = r_p28.p28_tipo_doc
	LET r_p23.p23_num_doc  = r_p28.p28_num_doc
	WHENEVER ERROR CONTINUE
	SET LOCK MODE TO WAIT 3
	DECLARE q_saldo2 CURSOR FOR
		SELECT p20_saldo_cap FROM cxpt020
			WHERE p20_compania  = vg_codcia
			  AND p20_localidad = vg_codloc
			  AND p20_codprov   = r_p23.p23_codprov
			  AND p20_tipo_doc  = r_p23.p23_tipo_doc
			  AND p20_num_doc   = r_p23.p23_num_doc
			  AND p20_dividendo = r_p28.p28_dividendo
		FOR UPDATE OF p20_saldo_cap
	SET LOCK MODE TO NOT WAIT
	WHENEVER ERROR STOP
	OPEN q_saldo2
	FETCH q_saldo2 INTO r_p23.p23_saldo_cap	
	IF STATUS < 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_p23.p23_orden     = orden
	LET orden = orden + 1
	LET r_p23.p23_div_doc   = r_p28.p28_dividendo
	LET r_p23.p23_valor_cap = r_p28.p28_valor_ret * (-1)
	INSERT INTO cxpt023 VALUES(r_p23.*)
	UPDATE cxpt020 
		SET p20_saldo_cap = p20_saldo_cap - r_p28.p28_valor_ret
		WHERE CURRENT OF q_saldo2
	CLOSE q_saldo2
	FREE  q_saldo2
END FOREACH
CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, rm_p27.p27_codprov)
RETURN r_p22.p22_total_cap

END FUNCTION



FUNCTION graba_retenciones()
DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE i,orden,done	SMALLINT
DEFINE cont		INTEGER
DEFINE r_reten		RECORD
				tipo_doc	CHAR(2),
				num_doc		CHAR(21),
				tipo_ret	CHAR(1), 
				porc		DECIMAL(5,2),
				val_base	DECIMAL(12,2),
				subtotal 	DECIMAL(12,2),
				codi_sri	VARCHAR(15,6),
				fec_ini_por	DATE
			END RECORD
DEFINE dividendo	LIKE cxpt020.p20_dividendo
DEFINE saldo		DECIMAL(12,2)
DEFINE mensaje		VARCHAR(100)

SELECT COUNT(*) INTO cont FROM tmp_retenciones
IF cont = 0 THEN
	RETURN 0
END IF

INITIALIZE r_p27.*, r_p28.* TO NULL
LET r_p27.p27_compania  = vg_codcia
LET r_p27.p27_localidad = vg_codloc
LET r_p27.p27_estado    = 'A'
LET r_p27.p27_codprov   = rm_p27.p27_codprov
LET r_p27.p27_moneda    = rm_p27.p27_moneda
LET r_p27.p27_paridad   = rm_p27.p27_paridad
SELECT SUM(subtotal) INTO r_p27.p27_total_ret FROM tmp_retenciones
LET r_p27.p27_origen    = 'M'
LET r_p27.p27_usuario   = vg_usuario
LET r_p27.p27_fecing    = fl_current()
LET r_p27.p27_num_ret   = nextValInSequence('TE', vm_retencion)
IF r_p27.p27_num_ret = -1 THEN
	LET int_flag = 1
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'No se puede generar la retención en este momento.','stop')
	CALL fl_mostrar_mensaje('No se puede generar la retención en este momento.','stop')
	EXIT PROGRAM
END IF
LET vm_num_ret = r_p27.p27_num_ret
INSERT INTO cxpt027 VALUES(r_p27.*) 

-- Graba Detalle Retencion
LET r_p28.p28_compania   = vg_codcia        
LET r_p28.p28_localidad  = vg_codloc
LET r_p28.p28_num_ret    = r_p27.p27_num_ret
LET r_p28.p28_codprov    = r_p27.p27_codprov

DECLARE q_tmpret2 CURSOR FOR
	SELECT DISTINCT tipo_doc, num_doc FROM tmp_retenciones
		ORDER BY 1, 2
LET i = 1
LET orden = 1
FOREACH q_tmpret2 INTO r_reten.tipo_doc, r_reten.num_doc
	LET r_p28.p28_tipo_doc = r_reten.tipo_doc
	LET r_p28.p28_num_doc  = r_reten.num_doc
	SELECT p20_valor_fact INTO r_p28.p28_valor_fact FROM tmp_detalle_ret
		WHERE p20_tipo_doc = r_reten.tipo_doc
		  AND p20_num_doc  = r_reten.num_doc
	DECLARE q_saldo3 CURSOR FOR
		SELECT p20_dividendo, p20_saldo_cap
			FROM cxpt020
			WHERE p20_compania  = vg_codcia
			  AND p20_localidad = vg_codloc
			  AND p20_codprov   = r_p28.p28_codprov
			  AND p20_tipo_doc  = r_p28.p28_tipo_doc
			  AND p20_num_doc   = r_p28.p28_num_doc
			  AND p20_saldo_cap > 0
			ORDER BY p20_dividendo ASC
	DECLARE q_saldo4 CURSOR FOR SELECT * FROM tmp_retenciones
		WHERE tipo_doc = r_reten.tipo_doc
		  AND num_doc  = r_reten.num_doc
		  AND subtotal >= 0
	OPEN  q_saldo4
	FETCH q_saldo4 INTO r_reten.*
	FOREACH q_saldo3 INTO dividendo, saldo
		LET done  = 0	
		IF saldo < r_reten.subtotal THEN
			CONTINUE FOREACH
		END IF
		WHILE saldo >= r_reten.subtotal
			LET r_p28.p28_secuencia      = orden
			LET orden                    = orden + 1
			LET r_p28.p28_dividendo      = dividendo
			LET r_p28.p28_tipo_ret       = r_reten.tipo_ret
			LET r_p28.p28_porcentaje     = r_reten.porc
			LET r_p28.p28_valor_base     = r_reten.val_base
			LET r_p28.p28_valor_ret      = r_reten.subtotal
			LET r_p28.p28_codigo_sri     = r_reten.codi_sri
			LET r_p28.p28_fecha_ini_porc = r_reten.fec_ini_por
			INSERT INTO cxpt028 VALUES(r_p28.*)
			LET done = 1
			LET saldo = saldo - r_reten.subtotal
			FETCH q_saldo4 INTO r_reten.*
			IF STATUS = NOTFOUND THEN
				EXIT FOREACH
			END IF
		END WHILE
	END FOREACH
	FREE q_saldo3
	CLOSE q_saldo4
	FREE  q_saldo4
	IF NOT done THEN
		LET mensaje = 'No pudo hacerse la retención'
		CASE r_ret[i].tipo_ret
			WHEN 'I'
				LET mensaje = mensaje, ' sobre el IVA (',
					      r_ret[i].porc, '%).'
			WHEN 'F'
				LET mensaje = mensaje, ' en la fuente (',
					      r_ret[i].porc, '%).'
			OTHERWISE
				LET mensaje = mensaje, ' ', r_ret[i].tipo_ret,
						' (', r_ret[i].porc, '%).'
		END CASE
		--CALL fgl_winmessage(vg_producto, mensaje, 'stop')
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
END FOREACH
RETURN done

END FUNCTION



FUNCTION numero_sri()

INITIALIZE rm_p29.* TO NULL
IF validar_num_sri(1) <> 1 THEN
	RETURN 0
END IF
CALL lee_num_ret_sri()
IF int_flag THEN
	RETURN 0
END IF
CALL genera_num_ret_sri()
RETURN 1

END FUNCTION



FUNCTION lee_num_ret_sri()
DEFINE aux_sri		LIKE cxpt029.p29_num_sri
DEFINE resp 		CHAR(6)
DEFINE resul		SMALLINT
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET ini_rows = 06
LET num_rows = 16
LET num_cols = 46
IF vg_gui = 0 THEN
	LET ini_rows = 05
	LET num_rows = 15
	LET num_cols = 47
END IF
OPEN WINDOW w_cxpf207_3 AT ini_rows, 17 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf207_3 FROM "../forms/cxpf207_3"
ELSE
	OPEN FORM f_cxpf207_3 FROM "../forms/cxpf207_3c"
END IF
DISPLAY FORM f_cxpf207_3
LET int_flag = 0
INPUT BY NAME rm_p29.p29_num_sri
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_p29.p29_num_sri) THEN
			LET int_flag = 1
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
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD p29_num_sri
		LET aux_sri = rm_p29.p29_num_sri
		CALL validar_num_sri(0) RETURNING resul
		CASE resul
			WHEN -1
				ROLLBACK WORK
				EXIT PROGRAM
			WHEN 0
				NEXT FIELD p29_num_sri
		END CASE
	AFTER FIELD p29_num_sri
		IF rm_p29.p29_num_sri IS NOT NULL THEN
			CALL validar_num_sri(1) RETURNING resul
			CASE resul
				WHEN -1
					ROLLBACK WORK
					EXIT PROGRAM
				WHEN 0
					NEXT FIELD p29_num_sri
			END CASE
		ELSE
			LET rm_p29.p29_num_sri = aux_sri
			DISPLAY BY NAME rm_p29.p29_num_sri
		END IF
	AFTER INPUT
		IF rm_p29.p29_num_sri IS NOT NULL THEN
			CALL validar_num_sri(1) RETURNING resul
			CASE resul
				WHEN -1
					ROLLBACK WORK
					EXIT PROGRAM
				WHEN 0
					NEXT FIELD p29_num_sri
			END CASE
		ELSE
			LET rm_p29.p29_num_sri = aux_sri
			DISPLAY BY NAME rm_p29.p29_num_sri
		END IF
END INPUT
CLOSE WINDOW w_cxpf207_3
RETURN

END FUNCTION



FUNCTION validar_num_sri(validar)
DEFINE validar		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

CALL fl_validacion_num_sri(vg_codcia, vg_codloc, 'RT', 'N', rm_p29.p29_num_sri)
	RETURNING r_g37.*, rm_p29.p29_num_sri, flag
CASE flag
	WHEN -1
		RETURN -1
	WHEN 0
		RETURN  0
END CASE
IF validar = 1 THEN
	SELECT COUNT(*) INTO cont FROM cxpt029
		WHERE p29_compania  = vg_codcia
		  AND p29_localidad = vg_codloc
  		  AND p29_num_sri   = rm_p29.p29_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_p29.p29_num_sri[9,21] || ' ya existe.','exclamation')
		RETURN 0
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION genera_num_ret_sri()
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE cuantos		SMALLINT

WHENEVER ERROR CONTINUE
DECLARE q_sri CURSOR FOR
	SELECT * FROM gent037
		WHERE g37_compania   = vg_codcia
		  AND g37_localidad  = vg_codloc
		  AND g37_tipo_doc   = 'RT'
		{--
	  	  AND g37_fecha_emi <= DATE(TODAY)
		  AND g37_fecha_exp >= DATE(TODAY)
		--}
		  AND g37_secuencia IN
			(SELECT MAX(g37_secuencia)
				FROM gent037
				WHERE g37_compania  = vg_codcia
				  AND g37_localidad = vg_codloc
				  AND g37_tipo_doc  = 'RT')
		FOR UPDATE
OPEN q_sri
FETCH q_sri INTO r_g37.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, porque ésta secuencia se encuentra bloqueada por otro usuario.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
LET cuantos = 8 + r_g37.g37_num_dig_sri
LET sec_sri = rm_p29.p29_num_sri[9, cuantos] USING "########"
UPDATE gent037
	SET g37_sec_num_sri = sec_sri
	WHERE g37_compania     = r_g37.g37_compania
	  AND g37_localidad    = r_g37.g37_localidad
	  AND g37_tipo_doc     = r_g37.g37_tipo_doc
	  AND g37_secuencia    = r_g37.g37_secuencia
	  AND g37_sec_num_sri <= sec_sri
INSERT INTO cxpt029
	VALUES (vg_codcia, vg_codloc, vm_num_ret, rm_p29.p29_num_sri)
INSERT INTO cxpt032
	VALUES (vg_codcia, vg_codloc, vm_num_ret, r_g37.g37_tipo_doc,
		r_g37.g37_secuencia)

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_det
	LET vm_total = vm_total + rm_det[i].tit_valor_ret
END FOR
DISPLAY vm_total TO tit_total_ret

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR p27_estado, tit_estado_pro, p27_moneda, tit_moneda, p27_codprov,
	tit_nombre_pro, p20_referencia, p27_usuario, p27_fecing
INITIALIZE rm_p27.* TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].*, rm_refer[i] TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR tit_total_ret

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 4, 62
	DISPLAY cor, " de ", vm_num_det AT 4, 66
END IF

END FUNCTION


 
FUNCTION muestra_estado()

DISPLAY BY NAME rm_p27.p27_estado
IF rm_p27.p27_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_pro
END IF
IF rm_p27.p27_estado = 'E' THEN
	DISPLAY 'ELIMINADO' TO tit_estado_pro
END IF

END FUNCTION



FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'TD'              TO tit_col1
--#DISPLAY 'Documento'       TO tit_col2
--#DISPLAY 'Fec. Emi.'       TO tit_col3
--#DISPLAY 'Valor Factura'   TO tit_col4
--#DISPLAY 'Valor Retención' TO tit_col5

END FUNCTION



FUNCTION mostrar_detalle_forma()

--#DISPLAY 'Descripción' TO tit_col6
--#DISPLAY 'SRI'        TO tit_col7
--#DISPLAY 'Tipo'        TO tit_col8
--#DISPLAY 'Valor Base'  TO tit_col9
--#DISPLAY '%'           TO tit_col10
--#DISPLAY 'Subtotal'    TO tit_col11

END FUNCTION



FUNCTION nextValInSequence(modulo, tipo_tran)

DEFINE modulo		LIKE gent050.g50_modulo
DEFINE tipo_tran 	LIKE rept019.r19_cod_tran

DEFINE resp		CHAR(6)
DEFINE retVal 		INTEGER

LET retVal = -1
WHILE retVal = -1

LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, modulo,
		'AA', tipo_tran)
IF retVal = 0 THEN
	EXIT PROGRAM
END IF
IF retVal <> -1 THEN
	 EXIT WHILE
END IF

--CALL fgl_winquestion(vg_producto,'La tabla de secuencias de transacciones está siendo accesada por otro usuario, espere unos segundos y vuelva a intentar','No','Yes|No|Cancel','question',1)
CALL fl_hacer_pregunta('La tabla de secuencias de transacciones está siendo accesada por otro usuario, espere unos segundos y vuelva a intentar','No')
	RETURNING resp 
IF resp <> 'Yes' THEN
	EXIT WHILE	
END IF

END WHILE

RETURN retVal

END FUNCTION



FUNCTION elimina_retenciones(i)
DEFINE i		SMALLINT

DELETE FROM tmp_retenciones
	WHERE tipo_doc  = rm_det[i].p20_tipo_doc
	  AND num_doc   = rm_det[i].p20_num_doc
		  
END FUNCTION



FUNCTION carga_retenciones(i)
DEFINE i,j		SMALLINT
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_reten		RECORD
				tipo_doc	CHAR(2),
				num_doc		CHAR(21),
				tipo_ret	CHAR(1), 
				porc		DECIMAL(5,2),
				val_base	DECIMAL(12,2),
				subtotal 	DECIMAL(12,2)
			END RECORD

SELECT COUNT(*) INTO j FROM tmp_retenciones
	WHERE tipo_doc = rm_det[i].p20_tipo_doc
    	  AND num_doc  = rm_det[i].p20_num_doc
IF j = 0 THEN
	RETURN
END IF

LET tot_ret = 0
CALL fl_lee_proveedor(rm_p27.p27_codprov) RETURNING r_p01.*
DECLARE q_ret2 CURSOR FOR
	--SELECT * FROM ordt002, ordt003, OUTER tmp_retenciones
	SELECT * FROM ordt002, ordt003, tmp_retenciones
		WHERE c02_compania   = vg_codcia
                  AND c02_estado     = 'A' 
		  AND c03_compania   = c02_compania
		  AND c03_tipo_ret   = c02_tipo_ret
		  AND c03_porcentaje = c02_porcentaje
                  AND c03_estado     = 'A' 
    	  	  AND tipo_doc       = rm_det[i].p20_tipo_doc
    		  AND num_doc        = rm_det[i].p20_num_doc
    		  AND tipo_ret       = c03_tipo_ret
    		  AND porc           = c03_porcentaje
    		  AND codi_sri       = c03_codigo_sri
		  AND fecha_ini_por  = c03_fecha_ini_porc
		ORDER BY val_base DESC, c03_tipo_ret, c03_porcentaje,
			c03_codigo_sri
LET filas_pant = fgl_scr_size('ra_ret')
FOR j = 1 TO filas_pant
	CLEAR ra_ret[j].*
END FOR
LET j = 1
FOREACH q_ret2 INTO r_c02.*, r_c03.*, r_reten.*
	IF r_c02.c02_tipo_ret = 'F' AND r_p01.p01_ret_fuente = 'N' THEN
		CONTINUE FOREACH
	END IF
	IF r_c02.c02_tipo_ret = 'I' AND r_p01.p01_ret_impto = 'N' THEN
		CONTINUE FOREACH
	END IF
	LET r_ret[j].check       = 'N'
	LET r_ret[j].n_retencion = r_c02.c02_nombre
	LET r_ret[j].tipo_ret    = r_c02.c02_tipo_ret
	LET r_ret[j].porc        = r_c02.c02_porcentaje
	LET r_ret[j].c_sri       = r_c03.c03_codigo_sri
	LET fec_ini_porc[j]      = r_c03.c03_fecha_ini_porc
	IF r_reten.subtotal IS NOT NULL THEN
		LET r_ret[j].check    = 'S'
		LET r_ret[j].val_base = r_reten.val_base
		LET r_ret[j].subtotal = r_reten.subtotal
		LET tot_ret           = tot_ret + r_reten.subtotal
	ELSE
		LET r_ret[j].subtotal = 0
	END IF
	IF j <= filas_pant THEN
		DISPLAY r_ret[j].* TO ra_ret[j].*
	END IF
	LET r_ret_aux[j].* = r_ret[j].*
	LET fec_ini_porc_a[j] = fec_ini_porc[j]
	LET j = j + 1
	IF j > ind_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET ind_ret = j - 1

END FUNCTION



FUNCTION cuantas_retenciones(i)
DEFINE i,l		SMALLINT

-- Verifica si se han hecho retenciones sobre este documento,
-- y si se han hecho si no se han eliminado
SELECT COUNT(p28_secuencia) INTO l FROM cxpt028, cxpt027
	WHERE p28_compania  = vg_codcia
	  AND p28_localidad = vg_codloc
	  AND p28_codprov   = rm_p27.p27_codprov
	  AND p28_tipo_doc  = rm_det[i].p20_tipo_doc
 	  AND p28_num_doc   = rm_det[i].p20_num_doc
  	  AND p27_compania  = p28_compania
  	  AND p27_localidad = p28_localidad
 	  AND p27_num_ret   = p28_num_ret
  	  AND p27_estado    = 'A'
RETURN l

END FUNCTION



FUNCTION ver_estado_cuenta()
DEFINE param		VARCHAR(100)

LET param = vg_codloc, ' ', rm_p27.p27_moneda, ' ', vg_fecha, ' "T" 0.01 "N" ',
		rm_p27.p27_codprov, ' 0 '
CALL ejecuta_comando('TESORERIA', vg_modulo, 'cxpp314', param)

END FUNCTION



FUNCTION ver_contabilizacion(i)
DEFINE i		SMALLINT
DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE param		VARCHAR(100)

DECLARE q_p28_2 CURSOR FOR
	SELECT * FROM cxpt028
		WHERE p28_compania  = vg_codcia
		  AND p28_localidad = vg_codloc
		  AND p28_codprov   = rm_p27.p27_codprov
		  AND p28_tipo_doc  = rm_det[i].p20_tipo_doc
		  AND p28_num_doc   = rm_det[i].p20_num_doc
OPEN q_p28_2
FETCH q_p28_2 INTO r_p28.*
IF STATUS = NOTFOUND THEN
	CLOSE q_p28_2
	FREE q_p28_2
	CALL fl_mostrar_mensaje('No hay retenciones generadas para este documento.','exclamation')
	RETURN
END IF
CLOSE q_p28_2
FREE q_p28_2
CALL fl_lee_retencion_cxp(vg_codcia, vg_codloc, r_p28.p28_num_ret)
	RETURNING r_p27.*
IF r_p27.p27_tip_contable IS NULL THEN
	CALL fl_mostrar_mensaje('No hay contabilización generada para este documento.','exclamation')
	RETURN
END IF
LET param = r_p27.p27_tip_contable, ' ', r_p27.p27_num_contable
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201', param)

END FUNCTION



FUNCTION imprime_retenciones(r_p27)
DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE retenciones	SMALLINT
DEFINE resp		VARCHAR(6)
DEFINE param		VARCHAR(100)

SELECT COUNT(*) INTO retenciones FROM cxpt028
	WHERE p28_compania  = r_p27.p27_compania
	  AND p28_localidad = r_p27.p27_localidad
	  AND p28_num_ret   = r_p27.p27_num_ret
IF retenciones = 0 THEN
	RETURN
END IF
CALL fl_hacer_pregunta('Desea imprimir comprobante de retencion?','No')
	RETURNING resp
IF resp = 'Yes' THEN
	LET param = vg_codloc, ' ', r_p27.p27_num_ret    
	CALL ejecuta_comando('TESORERIA', vg_modulo, 'cxpp405', param)
END IF

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(20)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(100)
DEFINE comando		VARCHAR(255)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
	vg_separador, 'fuentes', vg_separador, run_prog, prog, ' ', vg_base,
	' ', mod, ' ', vg_codcia, ' ', param CLIPPED
RUN comando

END FUNCTION



FUNCTION control_codigos_sri(ind, ind2)
DEFINE ind, ind2	SMALLINT
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE i, j, salir 	SMALLINT
DEFINE cont, posi	SMALLINT
DEFINE pos_ori		SMALLINT
DEFINE resp		CHAR(6)

LET ini_rows = 04
LET num_rows = 18
LET num_cols = 79
IF vg_gui = 0 THEN
	LET ini_rows = 05
	LET num_rows = 18
	LET num_cols = 78
END IF
OPEN WINDOW w_cxpf204_6 AT ini_rows, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf204_6 FROM "../forms/cxpf204_6"
ELSE
	OPEN FORM f_cxpf204_6 FROM "../forms/cxpf204_6c"
END IF
DISPLAY FORM f_cxpf204_6
--#DISPLAY 'Código'		TO tit_col1 
--#DISPLAY 'Concepto'		TO tit_col2 
--#DISPLAY 'Fecha Ini.'		TO tit_col3 
--#DISPLAY 'Fecha Fin.'		TO tit_col4 
--#DISPLAY 'I'			TO tit_col5 
--#DISPLAY 'E'			TO tit_col6 
OPTIONS INSERT KEY F30,
	DELETE KEY F31
CLEAR c03_tipo_ret, c02_nombre, c03_porcentaje
FOR i = 1 TO fgl_scr_size('rm_retsri')
	CLEAR rm_retsri[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE rm_retsri[i].* TO NULL
END FOR
INITIALIZE rm_c03.* TO NULL
DECLARE q_c03 CURSOR WITH HOLD FOR
	SELECT * FROM ordt003
		WHERE c03_compania   = vg_codcia
		  AND c03_tipo_ret   = r_ret[ind].tipo_ret
		  AND c03_porcentaje = r_ret[ind].porc
		  AND c03_estado     = 'A'
OPEN q_c03
FETCH q_c03 INTO rm_c03.*
IF STATUS = NOTFOUND THEN
	CLOSE q_c03
	FREE q_c03
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_cxpf204_6
	LET int_flag = 0
	RETURN 0
END IF
LET vm_num_det2 = 1
LET pos_ori    = 0
FOREACH q_c03 INTO rm_c03.*
	LET rm_retsri[vm_num_det2].c03_codigo_sri    = rm_c03.c03_codigo_sri
	LET rm_retsri[vm_num_det2].c03_concepto_ret  = rm_c03.c03_concepto_ret
	LET rm_retsri[vm_num_det2].c03_fecha_ini_porc= rm_c03.c03_fecha_ini_porc
	LET rm_retsri[vm_num_det2].c03_fecha_fin_porc= rm_c03.c03_fecha_fin_porc
	LET rm_retsri[vm_num_det2].c03_ingresa_proc  = rm_c03.c03_ingresa_proc
	LET rm_retsri[vm_num_det2].tipo_imp          = 'N'
	SELECT * FROM tmp_tipo_porc
		WHERE tipodoc    = rm_det[ind2].p20_tipo_doc
		  AND numdoc     = rm_det[ind2].p20_num_doc
		  AND tiporet    = r_ret[ind].tipo_ret
		  AND porcen     = r_ret[ind].porc
		  AND codigo_sri = rm_retsri[vm_num_det2].c03_codigo_sri
		  AND fecha_ini_por = rm_retsri[vm_num_det2].c03_fecha_ini_porc
	IF STATUS <> NOTFOUND THEN
		LET rm_retsri[vm_num_det2].tipo_imp = 'S'
		LET pos_ori                         = vm_num_det2
	END IF
	LET vm_num_det2 = vm_num_det2 + 1
	IF vm_num_det2 > vm_max_det2 THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_num_det2 = vm_num_det2 - 1
IF vm_num_det2 = 0 THEN
	LET vm_num_det2 = 1
END IF
DISPLAY BY NAME rm_c03.c03_tipo_ret, rm_c03.c03_porcentaje
DISPLAY r_ret[ind].n_retencion TO c02_nombre
LET salir = 0
WHILE NOT salir
	MESSAGE 'Presione F12 para seleccionar el código del SRI apropiado.'
	CALL set_count(vm_num_det2)
	LET int_flag = 0
	DISPLAY ARRAY rm_retsri TO rm_retsri.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				LET salir    = 1
				EXIT DISPLAY
			END IF
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(RETURN)
			LET i    = arr_curr()
			LET j    = scr_line()
			LET posi = i
			LET rm_retsri[posi].tipo_imp = 'S'
			DISPLAY rm_retsri[i].tipo_imp TO rm_retsri[j].tipo_imp
			LET int_flag = 0
			LET salir    = 1
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("DELETE","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#DISPLAY i           TO num_row
			--#DISPLAY vm_num_det2 TO max_row
		--#AFTER DISPLAY
			--LET cont = 0
			--FOR i = 1 TO vm_num_det2
				--IF rm_retsri[i].tipo_imp = 'S' THEN
					--LET posi = i
					--LET cont = cont + 1
				--END IF
			--END FOR
			--IF cont > 1 THEN
				--CALL fl_mostrar_mensaje('Solo puede marcar un solo código del SRI por cada tipo de impuesto.', 'exclamation')
				--CONTINUE DISPLAY
			--END IF
			--IF cont = 0 THEN
				--CALL fl_mostrar_mensaje('Marque al menos un código del SRI.', 'exclamation')
				--CONTINUE DISPLAY
			--END IF
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#LET posi = i
			--#LET rm_retsri[posi].tipo_imp = 'S'
			--#DISPLAY rm_retsri[i].tipo_imp TO rm_retsri[j].tipo_imp
			--#LET salir = 1
	END DISPLAY
END WHILE
IF int_flag THEN
	CLOSE WINDOW w_cxpf204_6
	LET int_flag = 0
	RETURN 0
END IF
IF pos_ori > 0 THEN
	DELETE FROM tmp_tipo_porc
		WHERE tipodoc    = rm_det[ind2].p20_tipo_doc
		  AND numdoc     = rm_det[ind2].p20_num_doc
		  AND tiporet    = r_ret[ind].tipo_ret
		  AND porcen     = r_ret[ind].porc
		  AND codigo_sri = rm_retsri[pos_ori].c03_codigo_sri
		  AND fecha_ini_por = rm_retsri[pos_ori].c03_fecha_ini_porc
END IF
INSERT INTO tmp_tipo_porc
	VALUES(rm_det[ind2].p20_tipo_doc, rm_det[ind2].p20_num_doc,
		r_ret[ind].tipo_ret, r_ret[ind].porc,
		rm_retsri[posi].c03_codigo_sri,
		rm_retsri[posi].c03_fecha_ini_porc,
		rm_retsri[posi].c03_concepto_ret)
CALL fl_mostrar_mensaje('Procesados Códigos del SRI.', 'info')
CLOSE WINDOW w_cxpf204_6
LET int_flag = 0
RETURN 1

END FUNCTION



FUNCTION generar_doc_elec(num_ret)
DEFINE num_ret		LIKE cxpt027.p27_num_ret
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
		vg_codcia, " ", vg_codloc, " CR ", num_ret, " RTP"
RUN comando
LET mensaje = FGL_GETENV("HOME"), '/tmp/RT_ELEC/'
CALL fl_mostrar_mensaje('Archivo XML de RETENCIONES Generado en: ' || mensaje, 'info')

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
DISPLAY '<F5>      Retenciones'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Contabilización'          AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Estado Cuenta'            AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Códigos SRI'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
