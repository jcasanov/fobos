------------------------------------------------------------------------------
-- Titulo           : repp430.4gl - Listado de Transacciones Repuestos
-- Elaboracion      : 09-ago-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp430 base módulo compañía localidad
--			[moneda] [cod_tran] [fecha_ini] [fecha_fin]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r19		RECORD LIKE rept019.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE vm_moneda_des	LIKE gent013.g13_nombre
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_total_fob_im	DECIMAL(12,2)
DEFINE rm_par		RECORD
				loc1		LIKE gent002.g02_localidad,
				tit_loc1	LIKE gent002.g02_nombre,
				loc2		LIKE gent002.g02_localidad,
				tit_loc2	LIKE gent002.g02_nombre,
				bod1		LIKE rept002.r02_codigo,
				tit_bod1	LIKE rept002.r02_nombre,
				bod2		LIKE rept002.r02_codigo,
				tit_bod2	LIKE rept002.r02_nombre,
				sin_stock	CHAR(1)
			END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp430.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp430'
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
IF num_args() <> 4 THEN
	CALL control_llamada_otro_prog()
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 17
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
	OPEN FORM f_rep FROM "../forms/repf430_1"
ELSE
	OPEN FORM f_rep FROM "../forms/repf430_1c"
END IF
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_llamada_otro_prog()
DEFINE r_g13		RECORD LIKE gent013.*

LET rm_r19.r19_moneda   = arg_val(5)
LET rm_r19.r19_cod_tran = arg_val(6)
LET vm_fecha_ini        = arg_val(7)
LET vm_fecha_fin        = arg_val(8)
CALL fl_lee_moneda(rm_r19.r19_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe moneda base.','stop')
        EXIT PROGRAM
END IF
LET vm_moneda_des = r_g13.g13_nombre
CALL imprimir_listado_trans()

END FUNCTION



FUNCTION control_reporte()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g21		RECORD LIKE gent021.*

INITIALIZE rm_par.* TO NULL
LET rm_r19.r19_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_r19.r19_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY r_g13.g13_nombre TO tit_moneda
LET vm_fecha_ini  = TODAY
LET vm_fecha_fin  = TODAY
LET vm_moneda_des = r_g13.g13_nombre
WHILE TRUE
	CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran) RETURNING r_g21.*
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL imprimir_listado_trans()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE cod_tran      	LIKE gent021.g21_cod_tran
DEFINE nombre      	LIKE gent021.g21_nombre
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

INITIALIZE mone_aux, cod_tran TO NULL
LET int_flag = 0
INPUT BY NAME rm_r19.r19_moneda, rm_r19.r19_cod_tran, vm_fecha_ini,vm_fecha_fin,
	rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r19_moneda) THEN
               		CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
                      	IF mone_aux IS NOT NULL THEN
                              	LET rm_r19.r19_moneda = mone_aux
                               	DISPLAY BY NAME rm_r19.r19_moneda
                               	DISPLAY nomm_aux TO tit_moneda
                       	END IF
                END IF
		IF INFIELD(r19_cod_tran) THEN
			CALL fl_ayuda_tipo_tran('N') RETURNING cod_tran, nombre
			IF cod_tran IS NOT NULL THEN
			    	LET rm_r19.r19_cod_tran = cod_tran
			    	DISPLAY BY NAME rm_r19.r19_cod_tran
			    	DISPLAY nombre TO tit_tipo 
			    	IF rm_r19.r19_cod_tran = 'TR' THEN
					IF rm_par.sin_stock IS NULL THEN
						LET rm_par.sin_stock = 'N'
						DISPLAY BY NAME rm_par.sin_stock
					END IF
				END IF
			END IF
		END IF
		IF INFIELD(loc1) THEN
			IF rm_r19.r19_cod_tran IS NULL OR
			   rm_r19.r19_cod_tran <> 'TR' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.loc1     = r_g02.g02_localidad
				LET rm_par.tit_loc1 = r_g02.g02_nombre
				DISPLAY BY NAME rm_par.loc1, rm_par.tit_loc1
			END IF
		END IF
		IF INFIELD(loc2) THEN
			IF rm_r19.r19_cod_tran IS NULL OR
			   rm_r19.r19_cod_tran <> 'TR' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.loc2     = r_g02.g02_localidad
				LET rm_par.tit_loc2 = r_g02.g02_nombre
				DISPLAY BY NAME rm_par.loc2, rm_par.tit_loc2
			END IF
		END IF
		IF INFIELD(bod1) THEN
			IF rm_r19.r19_cod_tran IS NULL OR
			   rm_r19.r19_cod_tran <> 'TR' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_bodegas_rep(vg_codcia, 'T', 'T', 'T', 'A', 'T')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_par.bod1     = r_r02.r02_codigo
				LET rm_par.tit_bod1 = r_r02.r02_nombre
				DISPLAY BY NAME rm_par.bod1, rm_par.tit_bod1
			END IF
		END IF
		IF INFIELD(bod2) THEN
			IF rm_r19.r19_cod_tran IS NULL OR
			   rm_r19.r19_cod_tran <> 'TR' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_bodegas_rep(vg_codcia, 'T', 'T', 'T', 'A', 'T')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_par.bod2     = r_r02.r02_codigo
				LET rm_par.tit_bod2 = r_r02.r02_nombre
				DISPLAY BY NAME rm_par.bod2, rm_par.tit_bod2
			END IF
		END IF
	    	LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD r19_moneda
               	IF rm_r19.r19_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(rm_r19.r19_moneda)
                               	RETURNING r_g13.*
                       	IF r_g13.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                               	NEXT FIELD r19_moneda
                       	END IF
                       	IF rm_r19.r19_moneda <> rg_gen.g00_moneda_base
                       	AND rm_r19.r19_moneda <> rg_gen.g00_moneda_alt THEN
				CALL fl_mostrar_mensaje('La moneda solo puede ser moneda base o alterna.','exclamation')
                               	NEXT FIELD r19_moneda
			END IF
               	ELSE
                       	LET rm_r19.r19_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(rm_r19.r19_moneda)
				RETURNING r_g13.*
                       	DISPLAY BY NAME rm_r19.r19_moneda
               	END IF
               	DISPLAY r_g13.g13_nombre TO tit_moneda
		LET vm_moneda_des = r_g13.g13_nombre
	AFTER FIELD r19_cod_tran
		IF rm_r19.r19_cod_tran IS NOT NULL THEN
			CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran)
				RETURNING r_g21.*
			IF r_g21.g21_cod_tran IS NULL THEN
				CALL fl_mostrar_mensaje('Tipo de Transacción no existe.','exclamation')
				NEXT FIELD r19_cod_tran
			END IF 
			DISPLAY r_g21.g21_nombre TO tit_tipo
			IF rm_r19.r19_cod_tran IS NULL OR
			   rm_r19.r19_cod_tran <> 'TR'
			THEN
				CALL blanquear_campos_para_tr()
			END IF
			IF rm_r19.r19_cod_tran = 'TR' THEN
				IF rm_par.sin_stock IS NULL THEN
					LET rm_par.sin_stock = 'N'
					DISPLAY BY NAME rm_par.sin_stock
				END IF
			END IF
		ELSE
			CLEAR tit_tipo
		END IF		 
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER FIELD loc1
		IF rm_r19.r19_cod_tran IS NULL OR rm_r19.r19_cod_tran <> 'TR'
		THEN
			LET rm_par.loc1     = NULL
			LET rm_par.tit_loc1 = NULL
			DISPLAY BY NAME rm_par.loc1, rm_par.tit_loc1
			CONTINUE INPUT
		END IF
		IF rm_par.loc1 IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.loc1)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD loc1
			END IF
			LET rm_par.tit_loc1 = r_g02.g02_nombre
			DISPLAY BY NAME rm_par.tit_loc1
		ELSE
			LET rm_par.tit_loc1 = NULL
			CLEAR tit_loc1
		END IF
	AFTER FIELD loc2
		IF rm_r19.r19_cod_tran IS NULL OR rm_r19.r19_cod_tran <> 'TR'
		THEN
			LET rm_par.loc2     = NULL
			LET rm_par.tit_loc2 = NULL
			DISPLAY BY NAME rm_par.loc2, rm_par.tit_loc2
			CONTINUE INPUT
		END IF
		IF rm_par.loc2 IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.loc2)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD loc2
			END IF
			LET rm_par.tit_loc2 = r_g02.g02_nombre
			DISPLAY BY NAME rm_par.tit_loc2
		ELSE
			LET rm_par.tit_loc2 = NULL
			CLEAR tit_loc2
		END IF
	AFTER FIELD bod1
		IF rm_r19.r19_cod_tran IS NULL OR rm_r19.r19_cod_tran <> 'TR'
		THEN
			LET rm_par.bod1     = NULL
			LET rm_par.tit_bod1 = NULL
			DISPLAY BY NAME rm_par.bod1, rm_par.tit_bod1
			CONTINUE INPUT
		END IF
		IF rm_par.bod1 IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_par.bod1)
				RETURNING r_r02.*
			IF r_r02.r02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				NEXT FIELD bod1
			END IF
			LET rm_par.tit_bod1 = r_r02.r02_nombre
			DISPLAY BY NAME rm_par.tit_bod1
		ELSE
			LET rm_par.tit_bod1 = NULL
			CLEAR tit_bod1
		END IF
	AFTER FIELD bod2
		IF rm_r19.r19_cod_tran IS NULL OR rm_r19.r19_cod_tran <> 'TR'
		THEN
			LET rm_par.bod2     = NULL
			LET rm_par.tit_bod2 = NULL
			DISPLAY BY NAME rm_par.bod2, rm_par.tit_bod2
			CONTINUE INPUT
		END IF
		IF rm_par.bod2 IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_par.bod2)
				RETURNING r_r02.*
			IF r_r02.r02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				NEXT FIELD bod2
			END IF
			LET rm_par.tit_bod2 = r_r02.r02_nombre
			DISPLAY BY NAME rm_par.tit_bod2
		ELSE
			LET rm_par.tit_bod2 = NULL
			CLEAR tit_bod2
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
		IF rm_par.loc1 IS NOT NULL OR
		   rm_par.loc2 IS NOT NULL THEN
			IF rm_par.bod1 IS NOT NULL OR
			   rm_par.bod2 IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Debe escojer Lacalidades ó Bodegas, pero no las 2 a la vez.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		IF rm_r19.r19_cod_tran IS NULL OR rm_r19.r19_cod_tran <> 'TR'
		THEN
			CALL blanquear_campos_para_tr()
		END IF
		IF rm_r19.r19_cod_tran = 'TR' THEN
			IF rm_par.sin_stock IS NULL THEN
				LET rm_par.sin_stock = 'N'
				DISPLAY BY NAME rm_par.sin_stock
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION blanquear_campos_para_tr()

INITIALIZE rm_par.* TO NULL
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION imprimir_listado_trans()
DEFINE query		CHAR(1200)
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE valor_iva	DECIMAL(11,2)
DEFINE total_bru	DECIMAL(12,2)
DEFINE total_des	DECIMAL(11,2)
DEFINE total_iva	DECIMAL(11,2)
DEFINE total_fle	DECIMAL(11,2)
DEFINE total_net	DECIMAL(12,2)
DEFINE total_cos	DECIMAL(12,2)
DEFINE flag		VARCHAR(1)
DEFINE comando		VARCHAR(100)
DEFINE imprimio		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
LET total_bru       = 0
LET total_des       = 0
LET total_iva       = 0
LET total_fle       = 0
LET total_net       = 0
LET total_cos       = 0
LET vm_total_fob_im = 0
LET query = 'SELECT *, r19_tot_neto - (r19_tot_bruto - r19_tot_dscto) ',
		' - r19_flete ',
		' FROM rept019 ',
		'WHERE r19_compania  = ', vg_codcia,
		'  AND r19_localidad = ', vg_codloc,
		'  AND r19_cod_tran  = "', rm_r19.r19_cod_tran, '"',
		'  AND r19_moneda    = "', rm_r19.r19_moneda, '"',
		'  AND DATE(r19_fecing) BETWEEN "', vm_fecha_ini,
		'" AND "', vm_fecha_fin, '"',
		' ORDER BY r19_fecing, r19_num_tran'
PREPARE deto FROM query
DECLARE q_deto CURSOR FOR deto
OPEN q_deto
FETCH q_deto
IF STATUS = NOTFOUND THEN
	CLOSE q_deto
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
CLOSE q_deto
IF rm_r19.r19_cod_tran = 'FA' OR rm_r19.r19_cod_tran = 'DF'
  OR rm_r19.r19_cod_tran = 'AF' OR rm_r19.r19_cod_tran = 'RQ'
  OR rm_r19.r19_cod_tran = 'DR' OR rm_r19.r19_cod_tran = 'CL'
  OR rm_r19.r19_cod_tran = 'DC'
THEN
	START REPORT rep_fact_dev TO PIPE comando
END IF
IF rm_r19.r19_cod_tran = 'TR' THEN
	START REPORT rep_transferencia TO PIPE comando
	LET imprimio = 0
END IF
IF rm_r19.r19_cod_tran = 'AC' OR rm_r19.r19_cod_tran = 'A+'
  OR rm_r19.r19_cod_tran = 'A-' THEN
	START REPORT rep_ajustes TO PIPE comando
END IF
IF rm_r19.r19_cod_tran = 'IM' THEN
	START REPORT rep_importaciones TO PIPE comando
END IF
FOREACH q_deto INTO r_rep.*, valor_iva
	IF r_rep.r19_cod_tran = 'DF' AND r_rep.r19_cod_tran = 'AF' THEN
		LET r_rep.r19_tot_bruto = r_rep.r19_tot_bruto * (-1)
		LET r_rep.r19_tot_dscto = r_rep.r19_tot_dscto * (-1)
		LET valor_iva           = valor_iva * (-1)
		LET r_rep.r19_flete     = r_rep.r19_flete * (-1)
		LET r_rep.r19_tot_neto  = r_rep.r19_tot_neto * (-1)
	END IF
	LET total_bru = total_bru + r_rep.r19_tot_bruto
	LET total_des = total_des + r_rep.r19_tot_dscto
	IF rm_r19.r19_cod_tran = 'CL' OR rm_r19.r19_cod_tran = 'DC'
	THEN
		CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc,
							rm_r19.r19_cod_tran,
							r_rep.r19_num_tran)
			RETURNING r_r19.*
		IF rm_r19.r19_cod_tran = 'DC' THEN
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
						vg_codloc,
						r_rep.r19_tipo_dev,
						r_rep.r19_num_dev)
				RETURNING r_r19.*
		END IF
		DECLARE q_comloc CURSOR FOR
			SELECT c13_tot_impto FROM ordt013
				WHERE c13_compania  = vg_codcia
				  AND c13_localidad = vg_codloc
				  AND c13_numero_oc = r_r19.r19_oc_interna
				  AND c13_fecha_recep = r_r19.r19_fecing
		LET valor_iva = 0
		OPEN q_comloc
		FETCH q_comloc INTO valor_iva
		CLOSE q_comloc
		FREE q_comloc
	END IF
	LET total_iva = total_iva + valor_iva
	LET total_fle = total_fle + r_rep.r19_flete
	LET total_net = total_net + r_rep.r19_tot_neto
	IF rm_r19.r19_cod_tran <> 'TR' THEN
		LET total_cos = total_cos + r_rep.r19_tot_costo
	END IF
	IF rm_r19.r19_cod_tran = 'FA' OR rm_r19.r19_cod_tran = 'DF'
	  OR rm_r19.r19_cod_tran = 'AF'
	  OR rm_r19.r19_cod_tran = 'RQ' OR rm_r19.r19_cod_tran = 'DR'
	THEN
		LET flag = 'F'
		OUTPUT TO REPORT rep_fact_dev(r_rep.*, valor_iva,
				total_bru, total_des, total_iva,
				total_fle, total_net, total_cos, flag)
	END IF
	IF rm_r19.r19_cod_tran = 'CL' OR rm_r19.r19_cod_tran = 'DC'
	THEN
		IF r_rep.r19_oc_interna IS NULL THEN
			CONTINUE FOREACH
		END IF
		LET flag = 'D'
		OUTPUT TO REPORT rep_fact_dev(r_rep.*, valor_iva,
				total_bru, total_des, total_iva,
				total_fle, total_net, 0, flag)
	END IF
	IF rm_r19.r19_cod_tran = 'TR' THEN
		IF rm_par.loc1 IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, r_rep.r19_bodega_ori)
				RETURNING r_r02.*
			IF r_r02.r02_localidad <> rm_par.loc1 THEN
				CONTINUE FOREACH
			END IF
			IF bodega_sin_stock(r_rep.r19_bodega_ori) THEN
				CONTINUE FOREACH
			END IF
		END IF
		IF rm_par.loc2 IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, r_rep.r19_bodega_dest)
				RETURNING r_r02.*
			IF r_r02.r02_localidad <> rm_par.loc2 THEN
				CONTINUE FOREACH
			END IF
			IF bodega_sin_stock(r_rep.r19_bodega_dest) THEN
				CONTINUE FOREACH
			END IF
		END IF
		IF rm_par.bod1 IS NOT NULL THEN
			IF rm_par.bod1 <> r_rep.r19_bodega_ori THEN
				CONTINUE FOREACH
			END IF
			IF bodega_sin_stock(r_rep.r19_bodega_ori) THEN
				CONTINUE FOREACH
			END IF
			IF bodega_sin_stock(r_rep.r19_bodega_dest) THEN
				CONTINUE FOREACH
			END IF
		END IF
		IF rm_par.bod2 IS NOT NULL THEN
			IF rm_par.bod2 <> r_rep.r19_bodega_dest THEN
				CONTINUE FOREACH
			END IF
			IF bodega_sin_stock(r_rep.r19_bodega_ori) THEN
				CONTINUE FOREACH
			END IF
			IF bodega_sin_stock(r_rep.r19_bodega_dest) THEN
				CONTINUE FOREACH
			END IF
		END IF
		LET imprimio  = 1
		LET total_cos = total_cos + r_rep.r19_tot_costo
		OUTPUT TO REPORT rep_transferencia (r_rep.*, total_cos)
	END IF
	IF rm_r19.r19_cod_tran = 'AC' OR rm_r19.r19_cod_tran = 'A+'
  	  OR rm_r19.r19_cod_tran = 'A-' THEN
		OUTPUT TO REPORT rep_ajustes (r_rep.*, total_cos)
	END IF
	IF rm_r19.r19_cod_tran = 'IM' THEN
		OUTPUT TO REPORT rep_importaciones (r_rep.*, total_cos)
	END IF
END FOREACH
IF rm_r19.r19_cod_tran = 'FA' OR rm_r19.r19_cod_tran = 'DF'
  OR rm_r19.r19_cod_tran = 'AF' OR rm_r19.r19_cod_tran = 'RQ'
  OR rm_r19.r19_cod_tran = 'DR' OR rm_r19.r19_cod_tran = 'CL'
  OR rm_r19.r19_cod_tran = 'DC'
THEN
	FINISH REPORT rep_fact_dev
END IF
IF rm_r19.r19_cod_tran = 'TR' THEN
	FINISH REPORT rep_transferencia
	IF NOT imprimio THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
END IF
IF rm_r19.r19_cod_tran = 'AC' OR rm_r19.r19_cod_tran = 'A+'
  OR rm_r19.r19_cod_tran = 'A-' THEN
	FINISH REPORT rep_ajustes
END IF
IF rm_r19.r19_cod_tran = 'IM' THEN
	FINISH REPORT rep_importaciones
END IF

END FUNCTION



FUNCTION bodega_sin_stock(bodega)
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE r_r02		RECORD LIKE rept002.*

CALL fl_lee_bodega_rep(vg_codcia, bodega) RETURNING r_r02.*
IF rm_par.sin_stock = 'N' THEN
	IF r_r02.r02_tipo = 'S' THEN
		RETURN 1
	END IF
END IF
RETURN 0

END FUNCTION



REPORT rep_fact_dev (r_rep, valor_iva, total_bru, total_des, total_iva,
			total_fle, total_net, total_cos, flag)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE valor_iva	DECIMAL(11,2)
DEFINE total_bru	DECIMAL(12,2)
DEFINE total_des	DECIMAL(11,2)
DEFINE total_iva	DECIMAL(11,2)
DEFINE total_fle	DECIMAL(11,2)
DEFINE total_net	DECIMAL(12,2)
DEFINE total_cos	DECIMAL(12,2)
DEFINE flag		VARCHAR(1)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE factura		VARCHAR(10)
DEFINE origen		VARCHAR(10)
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
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra (12 cpi)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET modulo  = "MODULO: INVENTARIO"
	LET long    = LENGTH(modulo)
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE TRANSACCIONES', 80)
		RETURNING titulo
	CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran) RETURNING r_g21.*
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
--	LET titulo = modulo, titulo 
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi
	PRINT COLUMN 01,  rm_g01.g01_razonsocial,
  	      COLUMN 138, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 01,  modulo CLIPPED,
	      COLUMN 51,  titulo CLIPPED,
	      COLUMN 142, UPSHIFT(vg_proceso) 
	SKIP 1 LINES
	PRINT COLUMN 47,  "** MONEDA        : ", rm_r19.r19_moneda,
						" ", vm_moneda_des
	PRINT COLUMN 47,  "** TIPO TRANSAC. : ", rm_r19.r19_cod_tran, " ",
						r_g21.g21_nombre
	PRINT COLUMN 47,  "** FECHA INICIAL : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 47,  "** FECHA FINAL   : ", vm_fecha_fin USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 01,  "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 130, usuario
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT "----------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 01,  "FECHA",
	      COLUMN 12,  "TP",
	      COLUMN 15,  "TRAN.",
	      COLUMN 21,  "FACTURA",
	      COLUMN 31,  "CLIENTE",
	      COLUMN 58,  "VALOR BRUTO",
	      COLUMN 72,  "VALOR DSCTO.",
	      COLUMN 90,  "VALOR IVA",
	      COLUMN 103, "VALOR FLETE",
	      COLUMN 121, "VALOR NETO";
	IF flag = 'F' THEN
	      PRINT COLUMN 138, "VALOR COSTO"
	ELSE
	      PRINT COLUMN 138, "No. O.COMP."
	END IF
	PRINT "----------------------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	--OJO
	NEED 3 LINES
	LET fecha   = DATE(r_rep.r19_fecing)
	LET factura = r_rep.r19_num_tran
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	PRINT COLUMN 01,  fecha USING "dd-mm-yyyy",
	      COLUMN 12,  r_rep.r19_cod_tran,
	      COLUMN 15,  factura,
	      COLUMN 21,  r_rep.r19_num_dev USING "<<<<<<<<<",
	      COLUMN 31,  r_rep.r19_nomcli[1,21],
	      COLUMN 55,  r_rep.r19_tot_bruto USING "---,---,--&.##",
	      COLUMN 70,  r_rep.r19_tot_dscto USING "---,---,--&.##",
	      COLUMN 85,  valor_iva           USING "---,---,--&.##",
	      COLUMN 100, r_rep.r19_flete     USING "---,---,--&.##",
	      COLUMN 116, r_rep.r19_tot_neto  USING "-,---,---,--&.##";
	IF flag = 'F' THEN
	      PRINT COLUMN 133, r_rep.r19_tot_costo USING "-,---,---,--&.##"
	ELSE
	      PRINT COLUMN 133, r_rep.r19_oc_interna
	END IF
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 55,  "--------------",
	      COLUMN 70,  "--------------",
	      COLUMN 85,  "--------------",
	      COLUMN 100, "--------------",
	      COLUMN 116, "----------------";
	IF flag = 'F' THEN
	      PRINT COLUMN 133, "----------------"
	ELSE
	      PRINT COLUMN 133, " "
	END IF
	PRINT COLUMN 42, "TOTALES ==>  ", total_bru USING "---,---,--&.##",
	      COLUMN 70,  total_des USING "---,---,--&.##",
	      COLUMN 85,  total_iva USING "---,---,--&.##",
	      COLUMN 100, total_fle USING "---,---,--&.##",
	      COLUMN 116, total_net USING "-,---,---,--&.##";
	IF flag = 'F' THEN
	      PRINT COLUMN 133, total_cos USING "-,---,---,--&.##";
	ELSE
	      PRINT COLUMN 133, " ";
	END IF
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



REPORT rep_transferencia(r_rep, total_cos)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE total_cos	DECIMAL(12,2)
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE factura		VARCHAR(15)
DEFINE origen		VARCHAR(40)
DEFINE destino		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra (12 cpi)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo      = "MODULO: INVENTARIO"
	LET long        = LENGTH(modulo)
	LET usuario     = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE TRANSACCIONES', 80)
		RETURNING titulo
	CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran) RETURNING r_g21.*
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
  	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 055, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 052, "** MONEDA        : ", rm_r19.r19_moneda,
						" ", vm_moneda_des
	PRINT COLUMN 052, "** TIPO TRANSAC. : ", rm_r19.r19_cod_tran, " ",
						r_g21.g21_nombre
	PRINT COLUMN 052, "** FECHA INICIAL : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 052, "** FECHA FINAL   : ", vm_fecha_fin USING "dd-mm-yyyy"
	IF rm_par.loc1 IS NOT NULL THEN
		PRINT COLUMN 052, "** LOCALIDAD ORI.: ", rm_par.loc1 USING "&&",
							" ", rm_par.tit_loc1
	ELSE
		IF rm_par.bod1 IS NOT NULL THEN
			PRINT COLUMN 052, "** BODEGA ORIGEN : ", rm_par.bod1,
							" ", rm_par.tit_bod1
		ELSE
			PRINT 1 SPACES
		END IF
	END IF
	IF rm_par.loc2 IS NOT NULL THEN
		PRINT COLUMN 052, "** LOCALIDAD DES.: ", rm_par.loc2 USING "&&",
							" ", rm_par.tit_loc2
	ELSE
		IF rm_par.bod2 IS NOT NULL THEN
			PRINT COLUMN 052, "** BODEGA DESTINO: ", rm_par.bod2,
							" ", rm_par.tit_bod2
		ELSE
			PRINT 1 SPACES
		END IF
	END IF
	SKIP 1 LINES
	PRINT COLUMN 01,  "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 114, usuario
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "FECHA",
	      COLUMN 012, "TP",
	      COLUMN 015, "No. TRAN.",
	      COLUMN 031, "ORIGEN",
	      COLUMN 062, "ORIGEN TRANSF.",
	      COLUMN 086, "DESTINO",
	      COLUMN 122, "VALOR COSTO"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	LET fecha   = DATE(r_rep.r19_fecing)
	LET factura = r_rep.r19_num_tran
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	CALL fl_lee_bodega_rep(vg_codcia, r_rep.r19_bodega_ori)
		RETURNING r_r02.*
	LET origen = '[', r_r02.r02_codigo, '] ', r_r02.r02_nombre
	CALL fl_lee_bodega_rep(vg_codcia, r_rep.r19_bodega_dest)
		RETURNING r_r02.*
	LET destino = '[', r_r02.r02_codigo, '] ', r_r02.r02_nombre
	CALL fl_justifica_titulo('I', origen, 35) RETURNING origen
	CALL fl_justifica_titulo('I', destino, 35) RETURNING destino
	PRINT COLUMN 001, fecha USING "dd-mm-yyyy",
	      COLUMN 012, r_rep.r19_cod_tran,
	      COLUMN 015, factura,
	      COLUMN 031, origen[1, 30],
	      COLUMN 062, r_rep.r19_nomcli[1, 23],
	      COLUMN 086, destino[1, 30],
	      COLUMN 117, r_rep.r19_tot_costo USING "-,---,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 117, "----------------"
	PRINT COLUMN 106, "TOTAL ==>  ", total_cos USING "-,---,---,--&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



REPORT rep_ajustes (r_rep, total_cos)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE total_cos	DECIMAL(12,2)
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE factura		VARCHAR(15)
DEFINE referen		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "MODULO: INVENTARIO"
	LET long    = LENGTH(modulo)
	LET usuario = 'USUARIO: ', vg_usuario
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE TRANSACCIONES', 80)
		RETURNING titulo
	CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran) RETURNING r_g21.*
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
--	LET titulo = modulo, titulo 
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 01,  rm_g01.g01_razonsocial,
  	      COLUMN 81,  "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 01,  modulo CLIPPED,
	      COLUMN 30,  titulo CLIPPED,
	      COLUMN 85,  UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 27,  "** MONEDA        : ", rm_r19.r19_moneda,
						" ", vm_moneda_des
	PRINT COLUMN 27,  "** TIPO TRANSAC. : ", rm_r19.r19_cod_tran, " ",
						r_g21.g21_nombre
	PRINT COLUMN 27,  "** FECHA INICIAL : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 27,  "** FECHA FINAL   : ", vm_fecha_fin USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 01,  "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 73, usuario
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT "-------------------------------------------------------------------------------------------"
	PRINT COLUMN 01,  "FECHA",
	      COLUMN 13,  "TP",
	      COLUMN 17,  "No. TRAN.",
	      COLUMN 34,  "REFERENCIA",
	      COLUMN 80,  "VALOR AJUSTE"
	PRINT "-------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	LET fecha   = DATE(r_rep.r19_fecing)
	LET factura = r_rep.r19_num_tran
	LET referen = r_rep.r19_referencia
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	CALL fl_justifica_titulo('I', referen, 40) RETURNING referen
	PRINT COLUMN 01,  fecha USING "dd-mm-yyyy",
	      COLUMN 13,  r_rep.r19_cod_tran,
	      COLUMN 17,  factura,
	      COLUMN 34,  referen,
	      COLUMN 76,  r_rep.r19_tot_costo USING "-,---,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 76,  "----------------"
	PRINT COLUMN 65, "TOTAL ==>  ", total_cos USING "-,---,---,--&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



REPORT rep_importaciones (r_rep, total_cos)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE total_cos	DECIMAL(12,2)
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE factura		VARCHAR(15)
DEFINE liquid		VARCHAR(11)
DEFINE total_fob	DECIMAL(12,2)
DEFINE pedido		LIKE rept029.r29_pedido
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "MODULO: INVENTARIO"
	LET long    = LENGTH(modulo)
	LET usuario = 'USUARIO: ', vg_usuario
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE TRANSACCIONES', 80)
		RETURNING titulo
	CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran) RETURNING r_g21.*
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
--	LET titulo = modulo, titulo 
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 01,  rm_g01.g01_razonsocial,
  	      COLUMN 82,  "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 01,  modulo CLIPPED,
	      COLUMN 31,  titulo CLIPPED,
	      COLUMN 86,  UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 27,  "** MONEDA        : ", rm_r19.r19_moneda,
						" ", vm_moneda_des
	PRINT COLUMN 27,  "** TIPO TRANSAC. : ", rm_r19.r19_cod_tran, " ",
						r_g21.g21_nombre
	PRINT COLUMN 27,  "** FECHA INICIAL : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 27,  "** FECHA FINAL   : ", vm_fecha_fin USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 01,  "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 74, usuario
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT "--------------------------------------------------------------------------------------------"
	PRINT COLUMN 01,  "FECHA",
	      COLUMN 13,  "TP",
	      COLUMN 17,  "No. TRAN.",
	      COLUMN 34,  "No. LIQ.",
	      COLUMN 47,  "No. PED.",
	      COLUMN 66,  "TOTAL FOB",
	      COLUMN 82,  "TOTAL COSTO"
	PRINT "--------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	SELECT SUM (r20_cant_ven * r20_fob) INTO total_fob
		FROM rept019, rept020
		WHERE r19_compania  = r_rep.r19_compania
		  AND r19_localidad = r_rep.r19_localidad
		  AND r19_cod_tran  = r_rep.r19_cod_tran 
		  AND r19_num_tran  = r_rep.r19_num_tran 
		  AND r19_compania  = r20_compania
		  AND r19_localidad = r20_localidad
		  AND r19_cod_tran  = r20_cod_tran 
		  AND r19_num_tran  = r20_num_tran 
	DECLARE q_deto2 CURSOR FOR
			SELECT r29_pedido
				FROM rept029
				WHERE r29_compania  = r_rep.r19_compania
				  AND r29_localidad = r_rep.r19_localidad
				  AND r29_numliq    = r_rep.r19_numliq
	OPEN q_deto2
	FETCH q_deto2 INTO pedido
	CLOSE q_deto2
	LET vm_total_fob_im = vm_total_fob_im + total_fob
	LET fecha   = DATE(r_rep.r19_fecing)
	LET factura = r_rep.r19_num_tran
	LET liquid  = r_rep.r19_numliq
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	CALL fl_justifica_titulo('I', liquid, 11) RETURNING liquid
	CALL fl_justifica_titulo('I', pedido, 10) RETURNING pedido
	PRINT COLUMN 01,  fecha USING "dd-mm-yyyy",
	      COLUMN 13,  r_rep.r19_cod_tran,
	      COLUMN 17,  factura,
	      COLUMN 34,  liquid,
	      COLUMN 47,  pedido,
	      COLUMN 59,  total_fob USING "-,---,---,--&.##",
	      COLUMN 77,  r_rep.r19_tot_costo USING "-,---,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 59,  "----------------",
	      COLUMN 77,  "----------------"
	PRINT COLUMN 48, "TOTAL ==>  ",vm_total_fob_im USING "-,---,---,--&.##",
	      COLUMN 77, total_cos USING "-,---,---,--&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION borrar_cabecera()

CLEAR r19_moneda, tit_moneda, tit_tipo, vm_fecha_ini, vm_fecha_fin
INITIALIZE rm_r19.*, vm_fecha_ini, vm_fecha_fin TO NULL

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
