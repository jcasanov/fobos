--------------------------------------------------------------------------------
-- Titulo           : repp322.4gl - Consulta ventas por transacciones
-- Elaboracion      : 09-Jul-2009
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp322 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE rm_orden 	ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_cons_sql	CHAR(400)
DEFINE rm_par 		RECORD 
				g21_cod_tran	LIKE gent021.g21_cod_tran,
				g21_nombre	LIKE gent021.g21_nombre,
				tipo_venta	CHAR(1),
				fecha_ini	DATE,
				fecha_fin	DATE,
				r19_vendedor	LIKE rept019.r19_vendedor,
				nom_vend	LIKE rept001.r01_nombres,
				r19_codcli	LIKE rept019.r19_codcli,
				r19_nomcli	LIKE rept019.r19_nomcli,
				item		LIKE rept010.r10_codigo,
				descripcion	LIKE rept010.r10_nombre,
				bodega		LIKE rept002.r02_codigo,
				nom_bod		LIKE rept002.r02_nombre
			END RECORD
DEFINE rm_detalle	ARRAY [30000] OF RECORD
				r19_cod_tran	LIKE rept019.r19_cod_tran,
				r19_num_tran	LIKE rept019.r19_num_tran,
				r19_tot_bruto	LIKE rept019.r19_tot_bruto,
				r19_tot_dscto	LIKE rept019.r19_tot_dscto,
				subtotal	DECIMAL(12,2),
				val_iva		DECIMAL(11,2),
				r19_flete	LIKE rept019.r19_flete,
				r19_tot_neto	LIKE rept019.r19_tot_neto
			END RECORD
DEFINE rm_adi		ARRAY [30000] OF RECORD
				r19_codcli	LIKE rept019.r19_codcli,
				cliente		LIKE rept019.r19_nomcli,
				fecha		DATE,
				nom_tran	LIKE gent021.g21_nombre
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_r01		RECORD LIKE rept001.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp322.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp322'
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
LET vm_max_det = 30000
LET lin_menu   = 0
LET row_ini    = 3
LET num_rows   = 22
LET num_cols   = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp322 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf322_1 FROM "../forms/repf322_1"
ELSE
	OPEN FORM f_repf322_1 FROM "../forms/repf322_1c"
END IF
DISPLAY FORM f_repf322_1
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()

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
	LET rm_par.r19_vendedor = rm_r01.r01_codigo
	DISPLAY BY NAME rm_par.r19_vendedor, rm_par.nom_vend
END IF
INITIALIZE rm_par.* TO NULL
LET rm_par.fecha_ini  = vg_fecha
LET rm_par.fecha_fin  = vg_fecha
LET rm_par.tipo_venta = 'T'
LET vm_num_det        = 0
WHILE TRUE
	LET vm_cons_sql = NULL
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF rm_par.bodega IS NULL AND rm_par.item IS NULL THEN
		CALL lee_parametros2()
		IF int_flag THEN
			CONTINUE WHILE
		END IF
	END IF
	CALL mostrar_consulta()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE grupo_linea	LIKE rept021.r21_grupo_linea
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

LET grupo_linea = NULL
LET int_flag    = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(g21_cod_tran) THEN
			CALL fl_ayuda_tipo_tran('N')
				RETURNING r_g21.g21_cod_tran, r_g21.g21_nombre
			IF r_g21.g21_cod_tran IS NOT NULL THEN
				LET rm_par.g21_cod_tran = r_g21.g21_cod_tran
				LET rm_par.g21_nombre   = r_g21.g21_nombre
				DISPLAY BY NAME rm_par.g21_cod_tran,
						rm_par.g21_nombre
			END IF 
		END IF
		IF INFIELD(r19_vendedor) AND (rm_g05.g05_tipo <> 'UF' OR
		   rm_r01.r01_tipo = 'J' OR rm_r01.r01_tipo = 'G')
		THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'T', 'F')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_par.r19_vendedor = r_r01.r01_codigo
				LET rm_par.nom_vend     = r_r01.r01_nombres
				DISPLAY BY NAME rm_par.r19_vendedor,
						rm_par.nom_vend
			END IF
		END IF
		IF INFIELD(r19_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par.r19_codcli = r_z01.z01_codcli
				LET rm_par.r19_nomcli = r_z01.z01_nomcli
				DISPLAY BY NAME rm_par.r19_codcli,
						rm_par.r19_nomcli
			END IF
		END IF
		IF INFIELD(item) THEN
			CALL fl_ayuda_maestro_items_stock(vg_codcia,grupo_linea,
							rm_par.bodega)
				RETURNING r_r10.r10_codigo, r_r10.r10_nombre,
					  r_r10.r10_linea, r_r10.r10_precio_mb,
					  rm_par.bodega, stock
			IF r_r10.r10_codigo IS NOT NULL THEN
				LET rm_par.item        = r_r10.r10_codigo
				LET rm_par.descripcion = r_r10.r10_nombre
				CALL fl_lee_bodega_rep(vg_codcia, rm_par.bodega)
					RETURNING r_r02.*
				LET rm_par.bodega  = r_r02.r02_codigo
				LET rm_par.nom_bod = r_r02.r02_nombre
				DISPLAY BY NAME rm_par.item, rm_par.descripcion,
						rm_par.bodega, rm_par.nom_bod
			END IF
		END IF
		IF INFIELD(bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T',
							'2', 'A', 'S', 'V')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_par.bodega  = r_r02.r02_codigo
				LET rm_par.nom_bod = r_r02.r02_nombre
				DISPLAY BY NAME rm_par.bodega, rm_par.nom_bod
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD g21_cod_tran
		IF rm_par.g21_cod_tran IS NOT NULL THEN
			CALL fl_lee_cod_transaccion(rm_par.g21_cod_tran)
				RETURNING r_g21.*
			IF r_g21.g21_cod_tran IS NULL THEN
				CALL fl_mostrar_mensaje('Código de transacción no existe.','exclamation')
				NEXT FIELD g21_cod_tran
			END IF
			LET rm_par.g21_nombre = r_g21.g21_nombre
			DISPLAY BY NAME rm_par.g21_nombre
			IF r_g21.g21_cod_tran <> 'FA' AND
			   r_g21.g21_cod_tran <> 'NV' AND
			   r_g21.g21_cod_tran <> 'DF' AND
			   r_g21.g21_cod_tran <> 'AF'
			THEN
				CALL fl_mostrar_mensaje('El codigo de transaccion debe ser del tipo Venta.', 'exclamation')
				NEXT FIELD g21_cod_tran
			END IF
		ELSE
			LET rm_par.g21_cod_tran = NULL
			LET rm_par.g21_nombre   = NULL
			DISPLAY BY NAME rm_par.g21_cod_tran, rm_par.g21_nombre
		END IF
	AFTER FIELD r19_vendedor
		IF rm_r01.r01_tipo <> 'J' AND rm_r01.r01_tipo <> 'G' THEN
			LET rm_par.r19_vendedor = rm_r01.r01_codigo
			DISPLAY BY NAME rm_par.r19_vendedor
		END IF
		IF rm_r01.r01_tipo = 'J' THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_par.r19_vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_tipo = 'G' THEN
				LET rm_par.r19_vendedor = r_r01.r01_codigo
				LET rm_par.nom_vend     = r_r01.r01_nombres
				DISPLAY BY NAME rm_par.r19_vendedor,
						rm_par.nom_vend
			END IF
		END IF
		IF rm_par.r19_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia,rm_par.r19_vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este vendedor en la compania.','exclamation')
				NEXT FIELD r19_vendedor
			END IF
			LET rm_par.nom_vend = r_r01.r01_nombres
			DISPLAY BY NAME rm_par.nom_vend
		ELSE
			LET rm_par.r19_vendedor = NULL
			LET rm_par.nom_vend     = NULL
			DISPLAY BY NAME rm_par.r19_vendedor, rm_par.nom_vend
		END IF
	AFTER FIELD r19_codcli
		IF rm_par.r19_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.r19_codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Este codigo de cliente no existe.', 'exclamation')
				NEXT FIELD r19_codcli
			END IF
			LET rm_par.r19_nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_par.r19_nomcli
		ELSE
			LET rm_par.r19_codcli = NULL
			LET rm_par.r19_nomcli = NULL
			DISPLAY BY NAME rm_par.r19_codcli, rm_par.r19_nomcli
		END IF
	AFTER FIELD item 
		IF rm_par.item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_par.item)
				RETURNING r_r10.*
			IF r_r10.r10_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('El item no existe en la Compañía.','exclamation')
				NEXT FIELD item
			END IF
			LET rm_par.descripcion = r_r10.r10_nombre
			DISPLAY BY NAME rm_par.descripcion
		ELSE
			LET rm_par.item        = NULL
			LET rm_par.descripcion = NULL
			DISPLAY BY NAME rm_par.item, rm_par.descripcion
		END IF
	AFTER FIELD bodega
		IF rm_par.bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_par.bodega)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('No existe la Bodega en la Compañía.','exclamation')
				NEXT FIELD bodega
			END IF
			LET rm_par.nom_bod = r_r02.r02_nombre
			DISPLAY BY NAME rm_par.nom_bod
			IF r_r02.r02_factura <> 'S' THEN
				CALL fl_mostrar_mensaje('Bodega no es de Facturacion.', 'exclamation')
				NEXT FIELD bodega
			END IF
		ELSE
			LET rm_par.bodega  = NULL
			LET rm_par.nom_bod = NULL
			DISPLAY BY NAME rm_par.bodega, rm_par.nom_bod
		END IF
	AFTER FIELD fecha_ini 
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_ini
			END IF
		ELSE
			LET rm_par.fecha_ini = fec_ini     
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
	AFTER FIELD fecha_fin 
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_fin
			END IF
		ELSE
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
		IF rm_par.bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_par.bodega)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('No existe la Bodega en la Compañía.','exclamation')
				NEXT FIELD bodega
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()

LET vm_cons_sql = NULL
LET int_flag    = 0
CONSTRUCT BY NAME vm_cons_sql ON r19_num_tran, r19_tot_bruto, r19_tot_dscto,
	r19_flete, r19_tot_neto
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
END CONSTRUCT

END FUNCTION



FUNCTION mostrar_consulta()
DEFINE i, j, col, salir	SMALLINT
DEFINE query		CHAR(600)

IF NOT preparar_tabla_temp_consulta() THEN
	RETURN
END IF
LET vm_columna_1           = 13
LET vm_columna_2           = 11
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
	LET query = "SELECT r19_cod_tran, r19_num_tran, tot_bruto, tot_dscto, ",
			"subtotal, tot_iva, flete, tot_neto, r19_codcli, ",
			"r19_nomcli, DATE(fec_tran), g21_nombre ",
			" FROM tmp_vta ",
                   	" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
	PREPARE venta FROM query
	DECLARE q_venta CURSOR FOR venta
	LET i = 1
	FOREACH q_venta INTO rm_detalle[i].*, rm_adi[i].*
		LET i = i + 1
		IF i > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	CALL mostrar_totales()
	LET int_flag = 0
	CALL set_count(vm_num_det)
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET salir    = 1
			EXIT DISPLAY
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
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		ON KEY(F21)
			LET col = 7
			EXIT DISPLAY
		ON KEY(F22)
			LET col = 8
			EXIT DISPLAY
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i)
			DISPLAY rm_adi[i].cliente  TO cliente
			DISPLAY rm_adi[i].fecha    TO fecha
			DISPLAY rm_adi[i].nom_tran TO nom_tran
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 OR salir THEN
		EXIT WHILE
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
DROP TABLE tmp_vta

END FUNCTION



{ XXX
  Esta función arma una consulta SQL de forma dinámica, pero tiene
  algunos problemas que deben revisarse:
  * incluye la tabla rept020, lo que causa que se dupliquen datos [1]
    pero no usa esa tabla nunca. pensé que lo hacía para filtrar 
    por bodega pero aunque entre los parámetros pide la bodega no
    filtra.
  * esta consulta considera NV como comprobante de venta pero al cambiar
    el signo de las DF y AF, sólo pregunta por FA y asume que lo demás
    es negativo. Lo que significa que las NV (si las hubiera) saldrán
    negativas.

[1] por ahora se eliminan los duplicados usando un GROUP BY 
}
FUNCTION preparar_tabla_temp_consulta()
DEFINE fec_ini, fec_fin	LIKE rept019.r19_fecing
DEFINE expr_tip		VARCHAR(100)
DEFINE expr_cont	VARCHAR(100)
DEFINE expr_vend	VARCHAR(100)
DEFINE expr_cli		VARCHAR(100)
DEFINE expr_val		CHAR(800)
DEFINE tabla		VARCHAR(20)
DEFINE expr_join	VARCHAR(200)
DEFINE query		CHAR(4000)

LET fec_ini = EXTEND(rm_par.fecha_ini, YEAR TO SECOND)
LET fec_fin = EXTEND(rm_par.fecha_fin, YEAR TO SECOND)
		+ 23 UNITS HOUR + 59 UNITS MINUTE + 59 UNITS SECOND  
LET expr_tip = '   AND r19_cod_tran  IN ("FA", "NV", "DF", "AF") '
IF rm_par.g21_cod_tran IS NOT NULL THEN
	LET expr_tip = '   AND r19_cod_tran  = "', rm_par.g21_cod_tran, '"'
END IF
LET expr_cont = NULL
IF rm_par.tipo_venta <> 'T' THEN
	LET expr_cont = '   AND r19_cont_cred = "', rm_par.tipo_venta, '"'
END IF
LET expr_vend = NULL
IF rm_par.r19_vendedor IS NOT NULL THEN
	LET expr_vend = '   AND r19_vendedor  = ', rm_par.r19_vendedor
END IF
LET expr_cli = NULL
IF rm_par.r19_codcli IS NOT NULL THEN
	LET expr_cli = '   AND r19_codcli    = ', rm_par.r19_codcli
END IF
LET expr_val = 'CASE WHEN r19_cod_tran = "FA" ',
			'THEN r19_tot_bruto ',
			'ELSE r19_tot_bruto * (-1) ',
		'END tot_bruto, ',
		'CASE WHEN r19_cod_tran = "FA" ',
			'THEN r19_tot_dscto ',
			'ELSE r19_tot_dscto * (-1) ',
		'END tot_dscto, ',
		'CASE WHEN r19_cod_tran = "FA" ',
			'THEN r19_tot_bruto - r19_tot_dscto ',
			'ELSE (r19_tot_bruto - r19_tot_dscto) * (-1) ',
		'END subtotal, ',
		'CASE WHEN r19_cod_tran = "FA" ',
			'THEN (r19_tot_neto - r19_tot_bruto + r19_tot_dscto ',
				'- r19_flete) ',
			'ELSE (r19_tot_neto - r19_tot_bruto + r19_tot_dscto ',
				'- r19_flete) * (-1) ',
		'END tot_iva, ',
		'CASE WHEN r19_cod_tran = "FA" ',
			'THEN r19_flete ',
			'ELSE r19_flete * (-1) ',
		'END flete, ',
		'CASE WHEN r19_cod_tran = "FA" ',
			'THEN r19_tot_neto ',
			'ELSE r19_tot_neto * (-1) ',
		'END tot_neto, '
LET tabla     = NULL
LET expr_join = NULL
IF rm_par.bodega IS NULL AND rm_par.item IS NULL THEN
	LET tabla     = ' rept020, '
	LET expr_join = '   AND r20_compania  = r19_compania ',
			'   AND r20_localidad = r19_localidad ',
			'   AND r20_cod_tran  = r19_cod_tran ',
			'   AND r20_num_tran  = r19_num_tran '
END IF
LET query = 'SELECT r19_cod_tran, r19_num_tran, ',
		expr_val CLIPPED,
		' r19_codcli, r19_nomcli, r19_fecing fec_tran, g21_nombre ',
		' FROM rept019, ', tabla CLIPPED, ' gent021 ',
		' WHERE r19_compania  = ', vg_codcia,
		'   AND r19_localidad = ', vg_codloc,
		expr_tip CLIPPED,
		expr_cont CLIPPED,
		expr_vend CLIPPED,
		expr_cli CLIPPED,
		'   AND ', vm_cons_sql CLIPPED,
		'   AND r19_fecing    BETWEEN "', fec_ini, '"',
					' AND "', fec_fin, '"',
		expr_join CLIPPED,
		'   AND g21_cod_tran  = r19_cod_tran ',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ',
		' INTO TEMP tmp_vta '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
SELECT COUNT(*) INTO vm_num_det FROM tmp_vta
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE tmp_vta
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_par.* TO NULL
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
FOR i = 1 TO fgl_scr_size('rm_detalle')
        INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
        CLEAR rm_detalle[i].*
END FOR
CLEAR tot_bru, tot_dsc, tot_sub, tot_iva, tot_fle, tot_net, fecha, cliente,
	nom_tran, num_row, vm_num_det

END FUNCTION



FUNCTION muestra_contadores_det(num_row)
DEFINE num_row		SMALLINT

DISPLAY BY NAME num_row, vm_num_det

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'TP'			TO tit_col1
--#DISPLAY 'Numero'		TO tit_col2
--#DISPLAY "Tot. Bruto"		TO tit_col3
--#DISPLAY "Tot. Dscto"		TO tit_col4
--#DISPLAY "Subtotal"		TO tit_col5
--#DISPLAY "Total IVA"		TO tit_col6
--#DISPLAY "Tot. Flete"		TO tit_col7
--#DISPLAY "Total Neto"		TO tit_col8

END FUNCTION



FUNCTION mostrar_totales()
DEFINE tot_bru		DECIMAL(12,2)
DEFINE tot_dsc		DECIMAL(12,2)
DEFINE tot_sub		DECIMAL(12,2)
DEFINE tot_iva		DECIMAL(12,2)
DEFINE tot_fle		DECIMAL(12,2)
DEFINE tot_net		DECIMAL(12,2)
DEFINE i		SMALLINT

LET tot_bru = 0
LET tot_dsc = 0
LET tot_sub = 0
LET tot_iva = 0
LET tot_fle = 0
LET tot_net = 0
FOR i = 1 TO vm_num_det
	LET tot_bru = tot_bru + rm_detalle[i].r19_tot_bruto
	LET tot_dsc = tot_dsc + rm_detalle[i].r19_tot_dscto
	LET tot_sub = tot_sub + rm_detalle[i].subtotal
	LET tot_iva = tot_iva + rm_detalle[i].val_iva
	LET tot_fle = tot_fle + rm_detalle[i].r19_flete
	LET tot_net = tot_net + rm_detalle[i].r19_tot_neto
END FOR
DISPLAY BY NAME tot_bru, tot_dsc, tot_sub, tot_iva, tot_fle, tot_net

END FUNCTION
