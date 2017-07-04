--------------------------------------------------------------------------------
-- Titulo           : repp312.4gl - Consulta de ventas a clientes
-- Elaboracion      : 29-abr-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp312 base módulo compañía localidad
--		             [fec_ini] [fec_fin] [moneda] [tipo_vta] [bodega]
--                           [vendedor] [tipo_consulta]
-- Ultima Correccion:
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_moneda	LIKE gent013.g13_moneda
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_bodega	LIKE rept011.r11_bodega
DEFINE tipo_vta		CHAR(1)
DEFINE tit_tipo_vta	VARCHAR(9)
DEFINE vm_tipcli	CHAR(1)
DEFINE filtro_val	DECIMAL(8,2)
DEFINE vm_first 	SMALLINT
DEFINE vm_cons_sql 	CHAR(500)
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_r19		RECORD LIKE rept019.*
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE r_detalle	ARRAY[15000] OF RECORD
				r01_iniciales	LIKE rept001.r01_iniciales,
				r19_codcli	LIKE rept019.r19_codcli,
				r19_nomcli	LIKE rept019.r19_nomcli,
				r19_tot_neto	LIKE rept019.r19_tot_neto
			END RECORD
DEFINE rm_vend		ARRAY[15000] OF RECORD
				r01_nombres	LIKE rept001.r01_nombres,
				r19_vendedor	LIKE rept019.r19_vendedor
			END RECORD
DEFINE vm_max_rows	SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp312.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 AND num_args() <> 11 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
        EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp312'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
--CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
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
OPEN WINDOW w_repf312_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf312 FROM "../forms/repf312_1"
ELSE
	OPEN FORM f_repf312 FROM "../forms/repf312_1c"
END IF
DISPLAY FORM f_repf312
LET vm_max_rows  = 15000
INITIALIZE rm_r19.*, vm_fecha_ini, vm_fecha_fin, vm_bodega, vm_moneda, tipo_vta,
	tit_tipo_vta TO NULL
LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
LET vm_moneda	 = rg_gen.g00_moneda_base
LET tipo_vta     = 'T'
CALL muestra_tipo_vta()
LET vm_tipcli    = 'C'
IF vg_gui = 0 THEN
	CALL muestra_tipocli(vm_tipcli)
END IF
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
INITIALIZE rm_r01.* TO NULL
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia
	  AND r01_user_owner = vg_usuario
OPEN qu_vd 
FETCH qu_vd INTO rm_r01.*
CLOSE qu_vd 
FREE qu_vd 
IF rm_g05.g05_tipo = 'UF' OR (rm_r01.r01_tipo <> 'J' AND rm_r01.r01_tipo <> 'G')
THEN
	LET rm_r19.r19_vendedor = rm_r01.r01_codigo
	DISPLAY BY NAME rm_r19.r19_vendedor
	DISPLAY rm_r01.r01_nombres TO tit_vendedor
END IF
CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.* 
DISPLAY rm_g13.g13_nombre TO nom_moneda
--#DISPLAY 'Ven'        TO tit_col1
--#DISPLAY 'Codigo'     TO tit_col2
--#DISPLAY 'Nombre' 	TO tit_col3
--#DISPLAY 'Total'	TO tit_col4
--LET filtro_val = 0.01
LET filtro_val = NULL
WHILE TRUE
	IF num_args() = 11 THEN
		CALL llamada_otro_programa()
		EXIT WHILE
	END IF
	CALL funcion_master()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_DISPLAY_array()
END WHILE
CLOSE WINDOW w_repf312_1
EXIT PROGRAM

END MAIN



FUNCTION llamada_otro_programa()
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*

LET vm_fecha_ini = arg_val(5)
LET vm_fecha_fin = arg_val(6)
LET vm_moneda	 = arg_val(7)
LET tipo_vta     = arg_val(8)
LET vm_bodega    = arg_val(9)
IF vm_bodega = 0 THEN
	LET vm_bodega = NULL
END IF
LET rm_r19.r19_vendedor = arg_val(10)
IF rm_r19.r19_vendedor = 0 THEN
	LET rm_r19.r19_vendedor = NULL
END IF
LET vm_tipcli = arg_val(11)
IF vg_gui = 0 THEN
	CALL muestra_tipocli(vm_tipcli)
END IF
CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.* 
CALL fl_lee_bodega_rep(vg_codcia, vm_bodega) RETURNING r_r02.*
CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor) RETURNING r_r01.*
DISPLAY BY NAME vm_fecha_ini, vm_fecha_fin, vm_moneda, tipo_vta, vm_bodega,
		rm_r19.r19_vendedor, vm_tipcli
DISPLAY rm_g13.g13_nombre TO nom_moneda
DISPLAY r_r02.r02_nombre  TO nom_bodega
DISPLAY r_r01.r01_nombres TO tit_vendedor
CALL muestra_tipo_vta()
CALL control_DISPLAY_array()

END FUNCTION



FUNCTION funcion_master()
DEFINE r_r01 		RECORD LIKE rept001.*		--VENDEDORES
DEFINE r_r02 		RECORD LIKE rept002.*		--BODEGAS
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('r_detalle')
	CLEAR r_detalle[i].*
END FOR
CLEAR r01_nombres, total_neto
INITIALIZE r_r02.* TO NULL
LET int_flag = 0
INPUT BY NAME vm_fecha_ini, vm_fecha_fin, vm_moneda, tipo_vta, vm_bodega,
	rm_r19.r19_vendedor, vm_tipcli, filtro_val
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(vm_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		END IF
		IF INFIELD(vm_bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T', '2', 'A', 'S', 'V')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET vm_bodega = r_r02.r02_codigo
				DISPLAY BY NAME vm_bodega
				DISPLAY r_r02.r02_nombre TO nom_bodega
			END IF
		END IF
		IF INFIELD(r19_vendedor) AND (rm_g05.g05_tipo <> 'UF' OR
		   rm_r01.r01_tipo = 'J' OR rm_r01.r01_tipo = 'G')
		THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'T', 'F')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_r19.r19_vendedor = r_r01.r01_codigo
				DISPLAY BY NAME rm_r19.r19_vendedor
				DISPLAY r_r01.r01_nombres TO tit_vendedor
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	AFTER FIELD vm_fecha_ini
		IF vm_fecha_ini IS NULL THEN
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD vm_fecha_fin
		IF vm_fecha_fin IS NULL THEN
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER FIELD vm_moneda
		IF vm_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(vm_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CLEAR nom_moneda 
				CALL fl_mostrar_mensaje('No existe la Moneda en la Compañia.','exclamation')
				NEXT FIELD vm_moneda
			ELSE
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		ELSE
			LET vm_moneda	 = rg_gen.g00_moneda_base
			CALL fl_lee_moneda(vm_moneda)
				RETURNING rm_g13.*
			DISPLAY BY NAME vm_moneda
			DISPLAY rm_g13.g13_nombre TO nom_moneda
		END IF
	AFTER FIELD tipo_vta
		CALL muestra_tipo_vta()
	AFTER FIELD vm_bodega
		IF vm_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, vm_bodega)	
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CLEAR nom_bodega
				CALL fl_mostrar_mensaje('No existe la Bodega en la Compañía.','exclamation')
				NEXT FIELD vm_bodega
			ELSE 
				DISPLAY r_r02.r02_nombre TO nom_bodega
			END IF
		ELSE
			CLEAR nom_bodega
		END IF
	AFTER FIELD r19_vendedor
		IF rm_r01.r01_tipo <> 'J' AND rm_r01.r01_tipo <> 'G' THEN
			LET rm_r19.r19_vendedor = rm_r01.r01_codigo
			DISPLAY BY NAME rm_r19.r19_vendedor
		END IF		
		IF rm_r01.r01_tipo = 'J' THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_tipo = 'G' THEN
				LET rm_r19.r19_vendedor = r_r01.r01_codigo 
				DISPLAY BY NAME rm_r19.r19_vendedor	
			END IF
		END IF
		IF rm_r19.r19_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este vendedor en la compania.','exclamation')
				NEXT FIELD r19_vendedor
			END IF
			{--
			IF r_r01.r01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r19_vendedor
			END IF
			--}
			DISPLAY r_r01.r01_nombres TO tit_vendedor
		ELSE
			CLEAR tit_vendedor
		END IF
	AFTER FIELD vm_tipcli
		IF vg_gui = 0 THEN
			IF vm_tipcli IS NOT NULL THEN
				CALL muestra_tipocli(vm_tipcli)
			ELSE
				CLEAR tit_tipcli
			END IF
		END IF
{
	AFTER FIELD filtro_val
		IF filtro_val IS NULL THEN
			NEXT FIELD filtro_val
		END IF
}
	AFTER INPUT 
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor que la fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION




FUNCTION control_DISPLAY_array()
DEFINE expr_sql 	CHAR(4000)
DEFINE expr_vta_inv	VARCHAR(100)
DEFINE expr_bod 	VARCHAR(50)
DEFINE expr_ven 	VARCHAR(50)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE codcli		LIKE rept019.r19_codcli
DEFINE nomcli		LIKE rept019.r19_nomcli
DEFINE tot_neto		LIKE rept019.r19_tot_neto
DEFINE total_neto	LIKE rept019.r19_tot_neto
DEFINE i, j 		SMALLINT
DEFINE r_orden		ARRAY[10] OF CHAR(4)
DEFINE columna		SMALLINT
DEFINE num_reg		SMALLINT

--#DISPLAY 'Ven'        TO tit_col1
--#DISPLAY 'Código'     TO tit_col2
--#DISPLAY 'Total'	TO tit_col4
IF vm_tipcli = 'C' THEN
	--#DISPLAY 'Nombre'	 	TO tit_col3
ELSE
	--#DISPLAY 'Tipo Cliente' 	TO tit_col3
END IF
LET expr_bod = ' '
IF vm_bodega IS NOT NULL THEN
	LET expr_bod = ' AND r20_bodega = "', vm_bodega, '"'
END IF
LET expr_ven = ' '
IF rm_r19.r19_vendedor IS NOT NULL THEN
	LET expr_ven = ' AND r19_vendedor = ', rm_r19.r19_vendedor
END IF
LET expr_vta_inv = NULL
IF tipo_vta <> 'T' THEN
	LET expr_vta_inv = '   AND r19_cont_cred   = "', tipo_vta, '"'
END IF
LET expr_sql = 'SELECT r19_cod_tran, r01_iniciales, r19_codcli, ',
			' CASE WHEN r19_codcli IS NOT NULL ',
				' THEN r19_nomcli ',
				' ELSE "CONSUMIDOR FINAL" ',
			' END r19_nomcli, ',
			' CASE WHEN r19_cod_tran = "FA" OR r19_cod_tran = "NV"',
				' THEN ',
			' SUM((r20_cant_ven * r20_precio) - r20_val_descto) ',
				' ELSE ',
			' SUM((r20_cant_ven * r20_precio) - r20_val_descto) ',
				' * (-1) ',
			' END totol, ',
			' r01_nombres, r19_vendedor ',
			' FROM rept019, rept020, rept001 ',
			' WHERE r19_compania     =', vg_codcia,
			'   AND r19_localidad    =', vg_codloc,
			'   AND r19_cod_tran     IN ("FA", "NV", "DF", "AF") ',
			expr_vta_inv CLIPPED,
			'   AND DATE(r19_fecing) BETWEEN  "',vm_fecha_ini, '"',
						   '  AND "',vm_fecha_fin, '"',
			expr_ven CLIPPED,
			'   AND r19_compania     = r20_compania ', 
			'   AND r19_localidad    = r20_localidad ', 
			'   AND r19_cod_tran     = r20_cod_tran ', 
			'   AND r19_num_tran     = r20_num_tran  ', 
			expr_bod CLIPPED,
			'   AND r19_compania     = r01_compania ',
			'   AND r19_vendedor     = r01_codigo ',
			' GROUP BY r19_cod_tran, r01_iniciales, r19_codcli, ',
			' r19_nomcli, r01_nombres, r19_vendedor ',
			' INTO TEMP tmp_zorroluis'
PREPARE consulta FROM expr_sql
EXECUTE consulta
--UPDATE tmp_zorroluis SET r19_nomcli = "CONSUMIDOR FINAL"
--	WHERE r19_codcli IS NULL
SELECT r01_iniciales, r19_codcli, r19_nomcli, SUM(totol) total, r01_nombres,
	r19_vendedor
	FROM tmp_zorroluis
	GROUP BY 1, 2, 3, 5, 6
	INTO TEMP tmp_clientes
DROP TABLE tmp_zorroluis
--UPDATE tmp_clientes SET total = total * (-1) WHERE r19_cod_tran IN ('DF','AF')
LET columna    = 4
LET r_orden[1] = 'DESC'
LET r_orden[2] = 'DESC'
LET r_orden[3] = 'DESC'
LET r_orden[4] = 'DESC'
INITIALIZE vm_cons_sql TO NULL
WHILE TRUE
	IF vm_tipcli = 'C' THEN
		LET expr_sql = prepare_query_clientes()
	ELSE
		LET expr_sql = prepare_query_tipo_clientes()
	END IF
	IF int_flag THEN
		DROP TABLE tmp_clientes
		EXIT WHILE
	END IF
	LET vm_first = 0
	LET expr_sql = expr_sql CLIPPED || 
		       ' ORDER BY ',columna, ' ',r_orden[columna]
	PREPARE consulta_2 FROM expr_sql
	DECLARE q_consulta_2 CURSOR FOR consulta_2
	LET total_neto = 0
	LET i = 1
	FOREACH q_consulta_2 INTO r_detalle[i].*, rm_vend[i].*
		LET total_neto = total_neto + r_detalle[i].r19_tot_neto
		{
		IF num_args() = 5 THEN
			CALL imprimir_background(i)
		END IF
		}
		LET i = i + 1
		IF i > vm_max_rows THEN
			CALL fl_mensaje_arreglo_incompleto()
			EXIT PROGRAM
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		DROP TABLE tmp_clientes
		CALL fl_mensaje_consulta_sin_registros()
		LET int_flag = 1
		EXIT WHILE
	END IF
	CALL set_count(i)
	DISPLAY BY NAME total_neto
	DISPLAY ARRAY r_detalle TO r_detalle.*
		ON KEY(INTERRUPT)
			--#DISPLAY '' AT 08,1
			DROP TABLE tmp_clientes
			EXIT DISPLAY
		ON KEY(RETURN)
			LET j = arr_curr()
			DISPLAY rm_vend[j].r01_nombres TO r01_nombres
			LET int_flag = 0
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET j = arr_curr()
			IF r_detalle[j].r19_codcli IS NOT NULL THEN
				CALL control_ver_detalle_ventas(
							r_detalle[j].r19_codcli,
							rm_vend[j].r19_vendedor)
			END IF
		ON KEY(F6)
			LET j = arr_curr()
			IF r_detalle[j].r19_codcli IS NOT NULL THEN
				CALL control_ver_estado_cuentas(
							r_detalle[j].r19_codcli)
			END IF
     		ON KEY(F7)
			LET num_reg = arr_count()
                        CALL imprimir(num_reg)
                        LET int_flag = 0
		ON KEY(F15)
			LET columna = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET columna = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET columna = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET columna = 4
			EXIT DISPLAY
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#IF vm_tipcli = 'C' THEN
				--#IF r_detalle[j].r19_codcli IS NOT NULL THEN
					--#CALL dialog.keysetlabel('F6','Estado Cuenta')
				--#END IF
			--#ELSE
				--#CALL dialog.keysetlabel('F6', '')
			--#END IF
			--#CALL dialog.keysetlabel("F7","Imprimir")
			--#DISPLAY rm_vend[j].r01_nombres TO r01_nombres
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#DISPLAY '' AT 08,1
			--#DISPLAY j, ' de ', i AT 08,60  
			--#IF r_detalle[j].r19_codcli IS NOT NULL THEN
				--#CALL dialog.keysetlabel('F5','Detalle Ventas')
				--#CALL dialog.keysetlabel('F6','Estado Cuenta')
			--#ELSE
				--#CALL dialog.keysetlabel('F5', '')
				--#CALL dialog.keysetlabel('F6', '')
			--#END IF
			--#DISPLAY rm_vend[j].r01_nombres TO r01_nombres
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF r_orden[columna] = 'ASC' THEN
		LET r_orden[columna] = 'DESC'
	ELSE
		LET r_orden[columna] = 'ASC'
	END IF 
END WHILE

END FUNCTION



FUNCTION control_ver_detalle_ventas(cliente, vendedor)
DEFINE cliente		LIKE rept019.r19_codcli
DEFINE vendedor		LIKE rept019.r19_vendedor
DEFINE command_run 	VARCHAR(200)
DEFINE run_prog		CHAR(10)

LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
--LET vendedor = rm_r19.r19_vendedor
IF vendedor IS NULL THEN
	LET vendedor = 0
END IF
LET command_run = run_prog, 'repp309 ', vg_base, ' ', vg_modulo, ' ',
		  vg_codcia, ' ', vg_codloc, ' ', vm_fecha_ini, ' ',
		  vm_fecha_fin, ' ', vm_tipcli, ' ', cliente, ' ',
		  vm_moneda, ' ', vendedor, ' ', tipo_vta
RUN command_run

END FUNCTION



FUNCTION control_ver_estado_cuentas(cliente)
DEFINE cliente		LIKE rept019.r19_codcli
DEFINE command_run 	VARCHAR(200)
DEFINE run_prog		CHAR(10)
DEFINE fecha		DATE

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
IF vg_gui = 0 THEN
	CALL fl_mostrar_mensaje('Este programa no esta para este tipo de terminales.', 'exclamation')
	RETURN
END IF
LET fecha       = TODAY
LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
		vg_separador, 'fuentes', vg_separador, '; fglrun cxcp314 ',
		vg_base, ' "CO" ', vg_codcia, ' ', vg_codloc, ' ',
		vm_moneda, ' ', fecha, ' "T" 0.01 "N" 0 ', cliente
RUN command_run

END FUNCTION



FUNCTION prepare_query_clientes()
DEFINE query		CHAR(1000)
DEFINE codcli		LIKE rept019.r19_codcli
DEFINE nomcli		LIKE rept019.r19_nomcli

IF vm_cons_sql IS NULL AND num_args() = 4 THEN
	INITIALIZE r_detalle[1].* TO NULL
	LET int_flag = 0
	CONSTRUCT BY NAME vm_cons_sql ON r19_codcli, r19_nomcli 
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT CONSTRUCT
		ON KEY(F2)
			IF INFIELD(r19_codcli) THEN
				CALL fl_ayuda_cliente_localidad(vg_codcia, 
 								vg_codloc)
					RETURNING codcli, nomcli
				IF codcli IS NOT NULL THEN
					LET r_detalle[1].r19_codcli = codcli
					LET r_detalle[1].r19_nomcli = nomcli
					DISPLAY r_detalle[1].* TO r_detalle[1].*
				END IF 
			END IF	
			LET int_flag = 0
	END CONSTRUCT
END IF
LET query = 'SELECT r01_iniciales, r19_codcli, r19_nomcli, SUM(total), ',
	    ' r01_nombres, r19_vendedor ', 
	    ' FROM tmp_clientes ',
	    ' WHERE ', vm_cons_sql CLIPPED,
	    ' GROUP BY r01_iniciales, r19_codcli, r19_nomcli, r01_nombres, ',
			' r19_vendedor '
IF filtro_val IS NULL THEN
	LET query = query CLIPPED, ' HAVING SUM(total) <> 0 ' 
ELSE
	IF filtro_val = 0 THEN
		LET query = query CLIPPED, ' HAVING SUM(total) >= ', filtro_val
	ELSE
		LET query = query CLIPPED, ' HAVING SUM(total) <> 0 ',
				' AND SUM(total) >= ', filtro_val
	END IF
END IF
RETURN query CLIPPED

END FUNCTION



FUNCTION prepare_query_tipo_clientes()
DEFINE query		CHAR(1500)

DEFINE rh_subtip RECORD
        g12_tiporeg             LIKE gent012.g12_tiporeg,
        g12_subtipo             LIKE gent012.g12_subtipo,
        g12_nombre              LIKE gent012.g12_nombre
        END RECORD
DEFINE rh_tipo  RECORD
        g11_nombre              LIKE gent011.g11_nombre
        END RECORD

IF vm_cons_sql IS NULL AND num_args() = 4 THEN
	INITIALIZE r_detalle[1].* TO NULL
	CONSTRUCT vm_cons_sql ON z01_tipo_clte, g12_nombre 
			    FROM r19_codcli, r19_nomcli
		ON KEY(F2)
			IF INFIELD(r19_codcli) THEN
				CALL fl_ayuda_subtipo_entidad('CL')
					RETURNING rh_subtip.*, rh_tipo.*
				IF rh_subtip.g12_tiporeg IS NOT NULL THEN
					LET r_detalle[1].r19_codcli = rh_subtip.g12_subtipo
					LET r_detalle[1].r19_nomcli = rh_subtip.g12_nombre
					DISPLAY r_detalle[1].* TO r_detalle[1].*
				END IF 
			END IF	
			LET int_flag = 0
	END CONSTRUCT
END IF

LET query = 'SELECT r01_iniciales, z01_tipo_clte, g12_nombre, SUM(total), ', 
	    ' r01_nombres, r19_vendedor ',
	    ' FROM tmp_clientes, cxct001, gent012 ',
	    ' WHERE z01_codcli   = r19_codcli ',
	    '   AND g12_tiporeg  = "CL" ',
	    '   AND g12_subtipo  = z01_tipo_clte ',
            '   AND ', vm_cons_sql CLIPPED,
	    ' GROUP BY r01_iniciales, z01_tipo_clte, g12_nombre, r01_nombres,',
			' r19_vendedor ',
	    ' HAVING SUM(total) <> 0 ' 
IF filtro_val IS NOT NULL THEN
	LET query = query CLIPPED, ' AND SUM(total) >= ', filtro_val
END IF
LET query = query CLIPPED, 
	    ' UNION ALL ',
            'SELECT r01_iniciales, 99, "OTROS", SUM(total), ', 
	    ' r01_nombres, r19_vendedor ',
	    ' FROM tmp_clientes ',
	    ' WHERE r19_codcli IS NULL ',
	    ' GROUP BY 1,2,3,5,6 ',
	    ' HAVING SUM(total) <> 0 ' 
IF filtro_val IS NOT NULL THEN
	LET query = query CLIPPED, ' AND SUM(total) >= ', filtro_val
END IF
RETURN query CLIPPED

END FUNCTION



FUNCTION muestra_tipo_vta()

CASE tipo_vta
	WHEN 'C' LET tit_tipo_vta = 'CONTADO'
	WHEN 'R' LET tit_tipo_vta = 'CREDITO'
	WHEN 'T' LET tit_tipo_vta = 'T O D O S'
END CASE
DISPLAY BY NAME tit_tipo_vta

END FUNCTION



FUNCTION muestra_tipocli(tipocli)
DEFINE tipocli		CHAR(1)

CASE tipocli
	WHEN 'C'
		DISPLAY 'POR CLIENTE' TO tit_tipcli
	WHEN 'T'
		DISPLAY 'POR TIPO DE CLIENTE' TO tit_tipcli
	OTHERWISE
		CLEAR vm_tipcli, tit_tipcli
END CASE

END FUNCTION



FUNCTION imprimir(numelm)
DEFINE numelm		SMALLINT
DEFINE i		SMALLINT
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN       
END IF

START REPORT rep_cliventas TO PIPE comando
--START REPORT rep_cliventas TO FILE "clientes.jcm"
FOR i = 1 TO numelm
	OUTPUT TO REPORT rep_cliventas(r_detalle[i].*)
END FOR
FINISH REPORT rep_cliventas

END FUNCTION



REPORT rep_cliventas(r_rep)
DEFINE r_rep RECORD
	r01_iniciales	LIKE rept001.r01_iniciales,
	r19_codcli	LIKE rept019.r19_codcli,
	r19_nomcli	LIKE rept019.r19_nomcli,
	r19_tot_neto	LIKE rept019.r19_tot_neto
END RECORD

DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*

DEFINE r_cia		RECORD LIKE gent001.*

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	0
	RIGHT MARGIN	80 
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.

	LET modulo  = "MODULO: INVENTARIO"
	LET long    = LENGTH(modulo)
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DE VENTAS POR CLIENTE', 80)
		RETURNING titulo

	CALL fl_lee_compania(vg_codcia) RETURNING r_cia.*
	CALL fl_lee_bodega_rep(vg_codcia, vm_bodega) RETURNING r_r02.*

	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi
	PRINT COLUMN 01,  r_cia.g01_razonsocial,
  	      COLUMN 69, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 01,  modulo CLIPPED,
	      COLUMN 28,  titulo CLIPPED,
	      COLUMN 73, UPSHIFT(vg_proceso) CLIPPED

	SKIP 1 LINES

	PRINT COLUMN 11,  "** MONEDA        : ", vm_moneda,
						" ", rm_g13.g13_nombre CLIPPED,
	      COLUMN 54, "** TIPO VENTA: ", tipo_vta, " ", tit_tipo_vta CLIPPED
	PRINT COLUMN 11,  "** VENDEDOR      : "; 
	IF rm_r19.r19_vendedor IS NULL THEN
		PRINT "T O D O S"
	ELSE
		CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
				RETURNING r_r01.*
		PRINT rm_r19.r19_vendedor USING "&&&", " ", r_r01.r01_nombres
	END IF
	
	PRINT COLUMN 11,  "** TIPO CONSULTA : ";
	IF vm_tipcli = 'C' THEN
		PRINT vm_tipcli, ' POR CLIENTE'
	ELSE
		PRINT vm_tipcli, ' POR TIPO DE CLIENTE'
	END IF
	PRINT COLUMN 11, "** DESDE         : ", 
			 vm_fecha_ini USING "dd-mm-yyyy",
			 "    HASTA  ", 
			 vm_fecha_fin USING "dd-mm-yyyy"

	SKIP 1 LINES

	PRINT COLUMN 01, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 60, usuario CLIPPED
	SKIP 1 LINES

	PRINT COLUMN 01,  "VEN",
	      COLUMN 06,  "CODIGO",
	      COLUMN 14,  "NOMBRE ",
	      COLUMN 63,  fl_justifica_titulo("D", "TOTAL", 16)

	PRINT COLUMN 01,  "-----",
	      COLUMN 06,  "--------",
	      COLUMN 14,  "-------------------------------------------------",
	      COLUMN 63,  "----------------"

ON EVERY ROW
	PRINT COLUMN 01,  r_rep.r01_iniciales,                
	      COLUMN 06,  r_rep.r19_codcli  USING "&&&&&&",
	      COLUMN 14,  r_rep.r19_nomcli[1, 45] CLIPPED,
	      COLUMN 63,  r_rep.r19_tot_neto  USING "#,###,###,##&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 63,  "----------------"
	PRINT COLUMN 50, "TOTALES ==>  ",
	      COLUMN 63,  SUM(r_rep.r19_tot_neto) USING "#,###,###,##&.##"
END REPORT



FUNCTION imprimir_background(i)
DEFINE i		SMALLINT

DISPLAY r_detalle[i].r01_iniciales, "|", r_detalle[i].r19_codcli USING "<<<<<&",
	"|", r_detalle[i].r19_nomcli, "|", r_detalle[i].r19_tot_neto, "|"

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
DISPLAY '<Enter>   Mostrar Nombre Vendedor'  AT a,2
DISPLAY  'Enter' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F5>      Detalle de Ventas'        AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Estado de Cuentas'        AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Imprimir Consulta'        AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
