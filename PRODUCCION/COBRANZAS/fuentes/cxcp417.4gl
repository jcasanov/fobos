--------------------------------------------------------------------------------
-- Titulo           : cxcp417.4gl - Listado de Cobranza realizada en un período
-- Elaboracion      : 08-Nov-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp417 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par 		RECORD
				moneda          LIKE gent013.g13_moneda,
				tit_mon         LIKE gent013.g13_nombre,
				fecha_ini	DATE,
				fecha_fin	DATE,
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				area_n          LIKE gent003.g03_areaneg,
				tit_area        LIKE gent003.g03_nombre,
				detallado	CHAR(1),
				tipcli		LIKE gent012.g12_subtipo,
				tit_tipcli	LIKE gent012.g12_nombre,
				tipcar		LIKE gent012.g12_subtipo,
				tit_tipcar	LIKE gent012.g12_nombre,
				--con_saldo	CHAR(1),
				localidad	LIKE gent002.g02_localidad,
				tit_localidad	LIKE gent002.g02_nombre,
				zona_venta	LIKE gent032.g32_zona_venta,
				tit_zona_venta	LIKE gent032.g32_nombre,
				zona_cobro	LIKE cxct006.z06_zona_cobro,
				tit_zona_cobro	LIKE cxct006.z06_nombre,
				vendedor	LIKE rept019.r19_vendedor,
				tit_vendedor	LIKE rept001.r01_nombres,
				cobrador	LIKE cxct005.z05_codigo,
				tit_cobrador	LIKE cxct005.z05_nombres
			END RECORD
DEFINE vm_fecha_ini	DATE
DEFINE vm_fin_mes	DATE
DEFINE rm_z60		RECORD LIKE cxct060.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp417.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp417'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING rm_z60.*
IF rm_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
OPEN WINDOW w_imp AT 3,2 WITH 20 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_par FROM "../forms/cxcf417_1"
DISPLAY FORM f_par
INITIALIZE rm_par.* TO NULL
LET rm_par.moneda    = rg_gen.g00_moneda_base
LET rm_par.fecha_ini = MDY(MONTH(vg_fecha), 01, YEAR(vg_fecha))
LET vm_fin_mes       = rm_par.fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
LET rm_par.fecha_fin = vm_fin_mes
LET rm_par.detallado = 'N'
--LET rm_par.con_saldo = 'N'
LET vm_fecha_ini     = rm_z60.z60_fecha_carga
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
LET rm_par.tit_mon = r_g13.g13_nombre
WHILE TRUE
	CALL lee_parametros() 
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_imprimir()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g11		RECORD LIKE gent011.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g32		RECORD LIKE gent032.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_z05		RECORD LIKE cxct005.*
DEFINE r_z06		RECORD LIKE cxct006.*
DEFINE fec_ini, fec_fin	DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING r_g13.g13_moneda, r_g13.g13_nombre,
					  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_par.moneda  = r_g13.g13_moneda
				LET rm_par.tit_mon = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF INFIELD(codcli) THEN
			IF rm_par.localidad IS NULL THEN
				CALL fl_ayuda_cliente_general()
					RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
			ELSE
				CALL fl_ayuda_cliente_localidad(vg_codcia,
							rm_par.localidad)
					RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
			END IF
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par.codcli = r_z01.z01_codcli
				LET rm_par.nomcli = r_z01.z01_nomcli
				DISPLAY BY NAME rm_par.codcli, rm_par.nomcli
			END IF
		END IF
		IF INFIELD(area_n) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
				RETURNING r_g03.g03_areaneg, r_g03.g03_nombre
			IF r_g03.g03_areaneg IS NOT NULL THEN
				LET rm_par.area_n   = r_g03.g03_areaneg
				LET rm_par.tit_area = r_g03.g03_nombre
 				DISPLAY BY NAME rm_par.area_n, rm_par.tit_area
			END IF
		END IF
		IF INFIELD(tipcli) THEN
			CALL fl_ayuda_subtipo_entidad('CL') 
				RETURNING r_g12.g12_tiporeg, r_g12.g12_subtipo,
					  r_g12.g12_nombre, r_g11.g11_nombre
			IF r_g12.g12_nombre IS NOT NULL THEN
				LET rm_par.tipcli     = r_g12.g12_subtipo
				LET rm_par.tit_tipcli = r_g12.g12_nombre
				DISPLAY BY NAME rm_par.tipcli, rm_par.tit_tipcli
			END IF
		END IF
		IF INFIELD(tipcar) THEN
			CALL fl_ayuda_subtipo_entidad('CR') 
				RETURNING r_g12.g12_tiporeg, r_g12.g12_subtipo,
					  r_g12.g12_nombre, r_g11.g11_nombre
			IF r_g12.g12_nombre IS NOT NULL THEN
				LET rm_par.tipcar     = r_g12.g12_subtipo
				LET rm_par.tit_tipcar = r_g12.g12_nombre
				DISPLAY BY NAME rm_par.tipcar, rm_par.tit_tipcar
			END IF
		END IF
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.localidad     = r_g02.g02_localidad
				LET rm_par.tit_localidad = r_g02.g02_nombre
				DISPLAY BY NAME rm_par.localidad,
						rm_par.tit_localidad
			END IF
		END IF
		IF INFIELD(zona_venta) THEN
			CALL fl_ayuda_zona_venta(vg_codcia)
				RETURNING r_g32.g32_zona_venta, r_g32.g32_nombre
			IF r_g32.g32_zona_venta IS NOT NULL THEN
				LET rm_par.zona_venta     = r_g32.g32_zona_venta
				LET rm_par.tit_zona_venta = r_g32.g32_nombre
				DISPLAY BY NAME rm_par.zona_venta,
						rm_par.tit_zona_venta
			END IF
		END IF
		IF INFIELD(zona_cobro) THEN
			CALL fl_ayuda_zona_cobro('T', 'T')
				RETURNING r_z06.z06_zona_cobro, r_z06.z06_nombre
			IF r_z06.z06_zona_cobro IS NOT NULL THEN
				LET rm_par.zona_cobro     = r_z06.z06_zona_cobro
				LET rm_par.tit_zona_cobro = r_z06.z06_nombre
				DISPLAY BY NAME rm_par.zona_cobro,
						rm_par.tit_zona_cobro
			END IF
		END IF
		IF INFIELD(vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'T', 'F')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_par.vendedor  = r_r01.r01_codigo
				LET rm_par.tit_vendedor = r_r01.r01_nombres
				DISPLAY BY NAME rm_par.vendedor,
						rm_par.tit_vendedor
			END IF
		END IF
		IF INFIELD(cobrador) THEN
			CALL fl_ayuda_cobradores(vg_codcia, 'T', 'T', 'T')
				RETURNING r_z05.z05_codigo, r_z05.z05_nombres
			IF r_z05.z05_codigo IS NOT NULL THEN
				LET rm_par.cobrador     = r_z05.z05_codigo
				LET rm_par.tit_cobrador = r_z05.z05_nombres
				DISPLAY BY NAME rm_par.cobrador,
						rm_par.tit_cobrador
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe moneda.', 'exclamation')
				NEXT FIELD moneda
			END IF
		ELSE
			LET rm_par.moneda = rg_gen.g00_moneda_base
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
		END IF
		LET rm_par.tit_mon = r_g13.g13_nombre 
		DISPLAY BY NAME rm_par.tit_mon
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini <= vm_fecha_ini THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser menor a la Fecha de Inicio de las COBRANZAS en el FOBOS.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
		IF rm_par.fecha_ini > vg_fecha THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la Fecha de Hoy.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin <= vm_fecha_ini THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser menor a la Fecha de Inicio de las COBRANZAS en el FOBOS.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
		IF rm_par.fecha_fin > vm_fin_mes THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor a la Fecha de Fin de Mes.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER FIELD codcli
		IF rm_par.codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD codcli
			END IF
			LET rm_par.nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_par.nomcli
			IF rm_par.localidad IS NULL THEN
				CONTINUE INPUT
			END IF
			CALL fl_lee_cliente_localidad(vg_codcia,
							rm_par.localidad,
							r_z01.z01_codcli)
				RETURNING r_z02.*
			IF r_z02.z02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no está activado para esta Localidad.', 'exclamation')
				NEXT FIELD codcli
			END IF
		ELSE
			LET rm_par.nomcli = NULL
			DISPLAY BY NAME rm_par.nomcli
		END IF
	AFTER FIELD area_n
		IF rm_par.area_n IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area_n)
				RETURNING r_g03.*
			IF r_g03.g03_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe área de negocio.', 'exclamation')
				NEXT FIELD area_n
			END IF
			LET rm_par.tit_area = r_g03.g03_nombre
			DISPLAY BY NAME rm_par.tit_area
		ELSE
			LET rm_par.tit_area = NULL
			DISPLAY BY NAME rm_par.tit_area
		END IF
	AFTER FIELD tipcli
		IF rm_par.tipcli IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CL', rm_par.tipcli)
				RETURNING r_g12.*
			IF r_g12.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo cliente.', 'exclamation')
				NEXT FIELD tipcli
			END IF
			LET rm_par.tit_tipcli = r_g12.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcli
		ELSE
			LET rm_par.tit_tipcli = NULL
			DISPLAY BY NAME rm_par.tit_tipcli
		END IF
	AFTER FIELD tipcar
		IF rm_par.tipcar IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR', rm_par.tipcar)
				RETURNING r_g12.*
			IF r_g12.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo cartera.', 'exclamation')
				NEXT FIELD tipcar
			END IF
			LET rm_par.tit_tipcar = r_g12.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcar
		ELSE
			LET rm_par.tit_tipcar = NULL
			DISPLAY BY NAME rm_par.tit_tipcar
		END IF
	AFTER FIELD localidad
		IF rm_par.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD localidad
			END IF
			LET rm_par.tit_localidad = r_g02.g02_nombre
			DISPLAY BY NAME rm_par.tit_localidad
		ELSE
			LET rm_par.tit_localidad = NULL
			DISPLAY BY NAME rm_par.tit_localidad
		END IF
	AFTER FIELD zona_venta
		IF rm_par.zona_venta IS NOT NULL THEN
			CALL fl_lee_zona_venta(vg_codcia, rm_par.zona_venta)
				RETURNING r_g32.*
			IF r_g32.g32_zona_venta IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Zona de venta no existe.','exclamation')
				NEXT FIELD zona_venta
			END IF
			LET rm_par.tit_zona_venta = r_g32.g32_nombre
			DISPLAY BY NAME rm_par.tit_zona_venta
		ELSE
			LET rm_par.tit_zona_venta = NULL
			DISPLAY BY NAME rm_par.tit_zona_venta
		END IF
	AFTER FIELD zona_cobro
		IF rm_par.zona_cobro IS NOT NULL THEN
			CALL fl_lee_zona_cobro(rm_par.zona_cobro)
				RETURNING r_z06.*
			IF r_z06.z06_zona_cobro IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Zona de cobro no existe.','exclamation')
				NEXT FIELD zona_cobro
			END IF
			LET rm_par.tit_zona_cobro = r_z06.z06_nombre
			DISPLAY BY NAME rm_par.tit_zona_cobro
		ELSE
			LET rm_par.tit_zona_cobro = NULL
			DISPLAY BY NAME rm_par.tit_zona_cobro
		END IF
	AFTER FIELD vendedor
		IF rm_par.vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_par.vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('No existe vendedor.','exclamation')
				NEXT FIELD vendedor
			END IF
			LET rm_par.tit_vendedor = r_r01.r01_nombres
			DISPLAY BY NAME rm_par.tit_vendedor
		ELSE
			LET rm_par.tit_vendedor = NULL
			CLEAR tit_vendedor
		END IF
	AFTER FIELD cobrador
		IF rm_par.cobrador IS NOT NULL THEN
			CALL fl_lee_cobrador_cxc(vg_codcia, rm_par.cobrador)
				RETURNING r_z05.*
			IF r_z05.z05_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe cobrador.', 'exclamation')
				NEXT FIELD cobrador
			END IF
			LET rm_par.tit_cobrador = r_z05.z05_nombres
			DISPLAY BY NAME rm_par.tit_cobrador
		ELSE
			LET rm_par.tit_cobrador = NULL
			DISPLAY BY NAME rm_par.tit_cobrador
		END IF
	AFTER INPUT 
		IF rm_par.codcli IS NOT NULL THEN
			LET rm_par.tipcli     = NULL
			LET rm_par.tit_tipcli = NULL
			DISPLAY BY NAME rm_par.tipcli, rm_par.tit_tipcli
		END IF
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha Final.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION control_imprimir()
DEFINE r_aux		RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				tipo_doc	LIKE cxct020.z20_tipo_doc,
				num_doc		LIKE cxct020.z20_num_doc,
				div_doc		LIKE cxct020.z20_dividendo,
				tipo_trn	LIKE cxct022.z22_tipo_trn,
				num_trn		LIKE cxct022.z22_num_trn,
				localidad	LIKE cxct022.z22_localidad,
				vendedor	LIKE rept001.r01_nombres,
				cobrador	LIKE cxct005.z05_nombres,
				fec_emi		LIKE cxct020.z20_fecha_emi,
				fec_vcto	LIKE cxct020.z20_fecha_vcto,
				fec_cobro	LIKE cxct022.z22_fecha_emi,
				dias_dif	INTEGER,
				val_doc		DECIMAL(12,2),
				val_cob		DECIMAL(12,2)
			END RECORD
DEFINE documento	VARCHAR(15)
DEFINE movimient	VARCHAR(15)
DEFINE comando		VARCHAR(100)
DEFINE query		CHAR(4200)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3, expr4	VARCHAR(100)
DEFINE expr5, expr6	VARCHAR(100)
DEFINE expr7, expr9	VARCHAR(100)
DEFINE expr8		VARCHAR(250)
DEFINE expr10, expr11	VARCHAR(100)
--DEFINE expr12, expr13 	VARCHAR(100)
DEFINE tabl1		VARCHAR(10)
DEFINE base_suc		VARCHAR(10)
DEFINE cuantos		INTEGER
DEFINE fecing		LIKE cxct022.z22_fecing
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE saldo		LIKE cxct020.z20_saldo_cap

ERROR "Procesando documentos deudores . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2, expr3, expr4, expr5, expr6, expr7, expr8, expr9,
		expr10, expr11, tabl1 TO NULL
LET expr1 = '   AND z20_moneda       = "', rm_par.moneda, '"'
LET expr2 = '   AND z22_fecha_emi    BETWEEN "', rm_par.fecha_ini,
				      '" AND "', rm_par.fecha_fin, '"'
IF rm_par.codcli IS NOT NULL THEN
	LET expr3 = '   AND z20_codcli       = ', rm_par.codcli
END IF
IF rm_par.area_n IS NOT NULL THEN
	LET expr4 = '   AND z20_areaneg      = ', rm_par.area_n
END IF
IF rm_par.tipcli IS NOT NULL THEN
	LET expr5 = '   AND z01_tipo_clte    = ', rm_par.tipcli
END IF
IF rm_par.tipcar IS NOT NULL THEN
	LET expr6 = '   AND z20_cartera      = ', rm_par.tipcar
END IF
IF rm_par.localidad IS NOT NULL THEN
	LET expr7 = '   AND z20_localidad    = ', rm_par.localidad
END IF
IF rm_par.zona_venta IS NOT NULL THEN
	LET tabl1 = ', cxct002 '
	LET expr8 = ' WHERE z02_compania     = ', vg_codcia,
			'   AND z02_codcli       = z01_codcli ',
			'   AND z02_zona_venta   = ', rm_par.zona_venta
END IF
IF rm_par.zona_cobro IS NOT NULL THEN
	IF rm_par.zona_venta IS NULL THEN
		LET tabl1 = ', cxct002 '
		LET expr8 = ' WHERE z02_compania     = ', vg_codcia,
				'   AND z02_codcli       = z01_codcli ',
				'   AND z02_zona_cobro   = ', rm_par.zona_cobro
	ELSE
		LET expr8 = expr8 CLIPPED,
				'   AND z02_zona_cobro   = ', rm_par.zona_cobro
	END IF
END IF
LET query = 'SELECT cxct001.* ',
		' FROM cxct001 ', tabl1 CLIPPED,
			expr8 CLIPPED,
		' INTO TEMP tmp_cli '
PREPARE cons_cli FROM query
EXECUTE cons_cli
SELECT COUNT(*) INTO cuantos FROM tmp_cli 
IF cuantos = 0 THEN
	ERROR ' '
	DROP TABLE tmp_cli
	CALL fl_mostrar_mensaje('No existen clientes con este criterio de búsqueda.', 'exclamation')
	RETURN
END IF
IF rm_par.vendedor IS NOT NULL THEN
	LET expr9  = '   AND r19_vendedor     = ', rm_par.vendedor
	LET expr10 = '   AND t61_cod_vendedor = ', rm_par.vendedor
END IF
IF rm_par.cobrador IS NOT NULL THEN
	LET expr11 = '   AND z22_cobrador     = ', rm_par.cobrador
END IF
LET query = 'SELECT * FROM cxct020 ',
		' WHERE z20_compania     = ', vg_codcia,
			expr7  CLIPPED,
			expr3  CLIPPED,
			expr4  CLIPPED,
			expr1  CLIPPED,
			expr6  CLIPPED,
		' INTO TEMP t1 '
PREPARE cons_t1 FROM query
EXECUTE cons_t1
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos = 0 THEN
	ERROR ' '
	DROP TABLE tmp_cli
	DROP TABLE t1
	CALL fl_mostrar_mensaje('No existen documentos con este criterio de búsqueda.', 'exclamation')
	RETURN
END IF
LET base_suc = 'acero_gc'
IF vg_codloc > 2 THEN
	LET base_suc = 'acero_qs'
END IF
LET query = 'SELECT t1.*, r01_nombres ',
		' FROM t1, rept019, rept001 ',
		' WHERE z20_areaneg      = 1 ',
		'   AND r19_compania     = z20_compania ',
		'   AND r19_localidad    = z20_localidad ',
		'   AND r19_cod_tran     = z20_cod_tran ',
		'   AND r19_num_tran     = z20_num_tran ',
		expr9 CLIPPED,
		'   AND r01_compania     = r19_compania ',
		'   AND r01_codigo       = r19_vendedor ',
		' UNION ',
		' SELECT t1.*, r01_nombres ',
		' FROM t1, ', base_suc CLIPPED, ':rept019, ',
			base_suc CLIPPED, ':rept001 ',
		' WHERE z20_areaneg      = 1 ',
		'   AND r19_compania     = z20_compania ',
		'   AND r19_localidad    = z20_localidad ',
		'   AND r19_cod_tran     = z20_cod_tran ',
		'   AND r19_num_tran     = z20_num_tran ',
		expr9 CLIPPED,
		'   AND r01_compania     = r19_compania ',
		'   AND r01_codigo       = r19_vendedor ',
		' UNION ',
		' SELECT t1.*, r01_nombres ',
			' FROM t1, talt061, talt023, rept001 ',
			' WHERE z20_areaneg      = 2 ',
			'   AND t61_compania     = z20_compania ',
			expr10 CLIPPED,
			'   AND t23_compania     = t61_compania ',
			'   AND t23_localidad    = z20_localidad ',
			'   AND t23_num_factura  = z20_num_tran ',
			'   AND t23_cod_asesor   = t61_cod_asesor ',
			'   AND r01_compania     = t61_compania ',
			'   AND r01_codigo       = t61_cod_vendedor ',
		' INTO TEMP t2 '
PREPARE cons_t2 FROM query
EXECUTE cons_t2
--
--DROP TABLE t1
--
SELECT * FROM t2 INTO TEMP tmp_z20
--
INSERT INTO tmp_z20
	SELECT a.*, ""
		FROM t1 a
		WHERE a.z20_tipo_doc <> 'FA'
DROP TABLE t1
DROP TABLE t2
SELECT UNIQUE tmp_z20.* FROM tmp_z20 INTO TEMP t3
DROP TABLE tmp_z20
SELECT * FROM t3 INTO TEMP tmp_z20
DROP TABLE t3
--
SELECT COUNT(*) INTO cuantos FROM tmp_z20 
IF cuantos = 0 THEN
	ERROR ' '
	DROP TABLE tmp_z20
	CALL fl_mostrar_mensaje('No existen documentos con este criterio de búsqueda.', 'exclamation')
	RETURN
END IF
LET query = 'SELECT z20_compania, z20_localidad, z20_codcli, z01_nomcli,',
			' z20_tipo_doc, z20_num_doc, z20_dividendo,',
			' r01_nombres, z20_fecha_emi, z20_fecha_vcto,',
			' (z20_valor_cap + z20_valor_int) valor_doc, ',
			' (z20_saldo_cap + z20_saldo_int) saldo_doc ',
		' FROM tmp_z20, gent002, tmp_cli ',
		' WHERE g02_compania   = z20_compania ',
		'   AND g02_localidad  = z20_localidad ',
		'   AND z01_codcli     = z20_codcli ',
			expr5 CLIPPED,
		' INTO TEMP tmp_doc '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
DROP TABLE tmp_cli
DROP TABLE tmp_z20
SELECT COUNT(*) INTO cuantos FROM tmp_doc 
ERROR ' '
IF cuantos = 0 THEN
	DROP TABLE tmp_doc
	CALL fl_mostrar_mensaje('No existen documentos con saldo para este criterio de búsqueda.', 'exclamation')
	RETURN
END IF
{--
IF rm_par.con_saldo = 'S' THEN
	LET expr12 = '   AND z22_tipo_trn   <> "AJ" '
END IF
--}
LET query = 'SELECT z20_codcli, z01_nomcli, z20_tipo_doc, z20_num_doc,',
			' z20_dividendo, z22_tipo_trn, z22_num_trn,',
			' z22_localidad, r01_nombres,',
			' NVL(z05_nombres, "SIN COBRADOR") cobrador_mov,',
			' z20_fecha_emi, z20_fecha_vcto, z22_fecha_emi,',
			' (z22_fecha_emi - z20_fecha_vcto) fecha, valor_doc,',
			' (z23_valor_cap + z23_valor_int) valor_mov,',
			' z22_fecing, z22_areaneg, saldo_doc ',
		' FROM tmp_doc, cxct023, cxct022, OUTER cxct005 ',
		' WHERE z23_compania     = z20_compania ',
		'   AND z23_localidad    = z20_localidad ',
		'   AND z23_codcli       = z20_codcli ',
		'   AND z23_tipo_doc     = z20_tipo_doc ',
		'   AND z23_num_doc      = z20_num_doc ',
		'   AND z23_div_doc      = z20_dividendo ',
		'   AND z22_compania     = z23_compania ',
		'   AND z22_localidad    = z23_localidad ',
		'   AND z22_codcli       = z23_codcli ',
		'   AND z22_tipo_trn     = z23_tipo_trn ',
		'   AND z22_num_trn      = z23_num_trn ',
			expr11 CLIPPED,
			--expr12 CLIPPED,
			expr2  CLIPPED,
		'   AND z05_compania     = z22_compania ',
		'   AND z05_codigo       = z22_cobrador ',
		' INTO TEMP tmp_mov '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
{--
IF rm_par.con_saldo = 'S' THEN
	SELECT z23_localidad, z23_codcli, z23_tipo_doc, z23_num_doc,
		z23_div_doc,NVL(SUM(z23_valor_cap + z23_valor_int), 0) valor_pag
		FROM cxct022, cxct023
		WHERE z22_compania      = vg_codcia
		  AND z22_localidad     = vg_codloc
		  AND z22_tipo_trn     <> "AJ"
		  AND DATE(z22_fecing) <= rm_par.fecha_fin
		  AND z23_compania      = z22_compania
		  AND z23_localidad     = z22_localidad
		  AND z23_codcli        = z22_codcli
		  AND z23_tipo_trn      = z22_tipo_trn
		  AND z23_num_trn       = z22_num_trn
		GROUP BY 1, 2, 3, 4, 5
		INTO TEMP tmp_ant
	SELECT tmp_mov.*
		FROM tmp_mov, OUTER tmp_ant
		WHERE z23_localidad = z22_localidad
		  AND z23_codcli    = z20_codcli
		  AND z23_tipo_doc  = z20_tipo_doc
		  AND z23_num_doc   = z20_num_doc
		  AND z23_div_doc   = z20_dividendo
		  AND valor_doc - valor_pag = 0
		INTO TEMP tmp_aux
	DROP TABLE tmp_mov
	SELECT * FROM tmp_aux INTO TEMP tmp_mov
	DROP TABLE tmp_aux
END IF
--}
CALL control_generar_archivo()
LET query = 'SELECT * FROM tmp_mov ',
		' ORDER BY z01_nomcli, z22_fecing, z20_tipo_doc, z20_num_doc,',
			' z20_dividendo '
PREPARE cons_report FROM query
DECLARE q_report CURSOR FOR cons_report
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	DROP TABLE tmp_doc
	DROP TABLE tmp_mov
	RETURN
END IF
START REPORT report_list_cobranza TO PIPE comando
LET cuantos = 0
FOREACH q_report INTO r_aux.*, fecing, areaneg, saldo
	LET documento = r_aux.tipo_doc CLIPPED, '-',
			r_aux.num_doc USING "<<<<<&&", '-',
			r_aux.div_doc USING "&&"
	LET movimient = r_aux.tipo_trn CLIPPED, '-',
			r_aux.num_trn USING "<<<<<&&"
	OUTPUT TO REPORT report_list_cobranza(r_aux.codcli, r_aux.nomcli,
						documento, movimient,
						r_aux.localidad, r_aux.vendedor,
						r_aux.cobrador, r_aux.fec_emi,
						r_aux.fec_vcto, r_aux.fec_cobro,
						r_aux.dias_dif,	r_aux.val_doc,
						r_aux.val_cob, areaneg,
						r_aux.tipo_trn, r_aux.num_trn)
	LET cuantos   = 1
END FOREACH
FINISH REPORT report_list_cobranza
DROP TABLE tmp_doc
DROP TABLE tmp_mov
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF

END FUNCTION



REPORT report_list_cobranza(r_rep, r_adi)
DEFINE r_rep		RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				documento	VARCHAR(15),
				movimient	VARCHAR(15),
				localidad	LIKE cxct022.z22_localidad,
				vendedor	LIKE rept001.r01_nombres,
				cobrador	LIKE cxct005.z05_nombres,
				fec_emi		LIKE cxct020.z20_fecha_emi,
				fec_vcto	LIKE cxct020.z20_fecha_vcto,
				fec_cobro	LIKE cxct022.z22_fecha_emi,
				dias_dif	INTEGER,
				val_doc		DECIMAL(12,2),
				val_cob		DECIMAL(12,2)
			END RECORD
DEFINE r_adi		RECORD
				areaneg		LIKE cxct022.z22_areaneg,
				tipo_trn	LIKE cxct022.z22_tipo_trn,
				num_trn		LIKE cxct022.z22_num_trn
			END RECORD
DEFINE r_dp		RECORD LIKE cajt011.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE tipo		LIKE cxct022.z22_tipo_trn
DEFINE tipo_nom		LIKE cxct004.z04_nombre
DEFINE query		CHAR(1200)
DEFINE nombre_bt	VARCHAR(20)
DEFINE total_doc	DECIMAL(14,2)
DEFINE total_mov	DECIMAL(14,2)
DEFINE total_trn	INTEGER
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE entro		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	160
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo  = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi
	PRINT COLUMN 001, r_g01.g01_razonsocial,
  	      COLUMN 150, "PAGINA: ", PAGENO USING '&&&'
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 062, "<< LISTADO DE COBRANZA REALIZADA >>",
	      COLUMN 154, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 015, "** MONEDA            : ", rm_par.moneda,
		" ", rm_par.tit_mon,
	      COLUMN 095, "COBRANZA REALIZADA DEL ",
		rm_par.fecha_ini USING 'dd-mm-yyyy', " AL ",
		rm_par.fecha_fin USING 'dd-mm-yyyy'
	IF rm_par.codcli IS NOT NULL THEN
		PRINT COLUMN 015, "** CLIENTE           : ",
			rm_par.codcli USING '<<<<&&', " ",
			rm_par.nomcli CLIPPED
	END IF
	IF rm_par.area_n IS NOT NULL THEN
		PRINT COLUMN 015, "** AREA DE NEGOCIO   : ",
			 rm_par.area_n USING '<&&', " ", rm_par.tit_area;
		IF rm_par.zona_venta IS NOT NULL THEN
			PRINT COLUMN 095, "ZONA DE VENTA  : ",
				rm_par.zona_venta USING '<<<&&', " ",
				rm_par.tit_zona_venta
		ELSE
			PRINT ' '
		END IF
	END IF
	IF rm_par.tipcli IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO CLIENTE      : ",
			rm_par.tipcli USING '<<&&', " ", rm_par.tit_tipcli;
		IF rm_par.zona_cobro IS NOT NULL THEN
			PRINT COLUMN 095, "ZONA DE COBRO  : ",
				rm_par.zona_cobro USING '<<<&&', " ",
				rm_par.tit_zona_cobro
		ELSE
			PRINT ' '
		END IF
	END IF
	IF rm_par.tipcar IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO CARTERA      : ",
			rm_par.tipcar USING '<<&&', " ", rm_par.tit_tipcar;
		IF rm_par.vendedor IS NOT NULL THEN
			PRINT COLUMN 095, "VENDEDOR       : ",
				rm_par.vendedor USING '<<<&&', " ",
				rm_par.tit_vendedor
		ELSE
			PRINT ' '
		END IF
	END IF
	IF rm_par.localidad IS NOT NULL THEN
		PRINT COLUMN 015, "** LOCALIDAD         : ",
			rm_par.localidad USING '&&', " ", rm_par.tit_localidad;
		IF rm_par.cobrador IS NOT NULL THEN
			PRINT COLUMN 095, "COBRADOR       : ",
				rm_par.cobrador USING '<<<&&', " ",
				rm_par.tit_cobrador
		ELSE
			PRINT ' '
		END IF
	END IF
	IF rm_par.area_n IS NULL THEN
		IF rm_par.zona_venta IS NOT NULL THEN
			PRINT COLUMN 015, "** ZONA DE VENTA     : ",
				rm_par.zona_venta USING '<<<&&', " ",
				rm_par.tit_zona_venta
		END IF
	END IF
	IF rm_par.tipcli IS NULL THEN
		IF rm_par.zona_cobro IS NOT NULL THEN
			PRINT COLUMN 015, "** ZONA DE COBRO     : ",
				rm_par.zona_cobro USING '<<<&&', " ",
				rm_par.tit_zona_cobro
		END IF
	END IF
	IF rm_par.tipcar IS NULL THEN
		IF rm_par.vendedor IS NOT NULL THEN
			PRINT COLUMN 015, "** VENDEDOR          : ",
				rm_par.vendedor USING '<<<&&', " ",
				rm_par.tit_vendedor
		END IF
	END IF
	IF rm_par.localidad IS NULL THEN
		IF rm_par.cobrador IS NOT NULL THEN
			PRINT COLUMN 015, "** COBRADOR          : ",
				rm_par.cobrador USING '<<<&&', " ",
				rm_par.tit_cobrador
		END IF
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 142, usuario
	PRINT "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 014, "C L I E N T E S",
	      COLUMN 037, "DOCUMENTOS",
	      COLUMN 053, "MOVIMIENTOS",
	      COLUMN 069, "LC",
	      COLUMN 072, "  VENDEDOR",
	      COLUMN 086, "  COBRADOR",
	      COLUMN 100, "FECHA EMI.",
	      COLUMN 111, "FEC. VCTO.",
	      COLUMN 122, "FEC. COBRO",
	      COLUMN 133, "DIAS",
	      COLUMN 138, " VALOR DOC.",
	      COLUMN 150, " VALOR COB."
	PRINT "----------------------------------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_rep.codcli		USING "####&&",
	      COLUMN 008, r_rep.nomcli[1, 28]	CLIPPED,
	      COLUMN 037, r_rep.documento	CLIPPED,
	      COLUMN 053, r_rep.movimient	CLIPPED,
	      COLUMN 069, r_rep.localidad	USING "&&",
	      COLUMN 072, r_rep.vendedor[1, 13]	CLIPPED,
	      COLUMN 086, r_rep.cobrador[1, 13]	CLIPPED,
	      COLUMN 100, r_rep.fec_emi		USING "dd-mm-yyyy",
	      COLUMN 111, r_rep.fec_vcto	USING "dd-mm-yyyy",
	      COLUMN 122, r_rep.fec_cobro	USING "dd-mm-yyyy",
	      COLUMN 133, r_rep.dias_dif	USING "---&",
	      COLUMN 138, r_rep.val_doc		USING "----,--&.##",
	      COLUMN 150, r_rep.val_cob		USING "----,--&.##"
	IF rm_par.detallado = 'S' THEN
		LET query = 'SELECT cajt011.* ',
				' FROM cajt010, cajt011 ',
				' WHERE j10_compania     = ? ',
				'   AND j10_localidad    = ? ',
				'   AND j10_areaneg      = ? ',
				'   AND j10_tipo_destino = ? ',
				'   AND j10_num_destino  = ? ',
				'   AND j10_compania     = j11_compania ',
				'   AND j10_localidad    = j11_localidad ',
				'   AND j10_tipo_fuente  = j11_tipo_fuente ',
				'   AND j10_num_fuente   = j11_num_fuente '
		PREPARE dpagc FROM query
		DECLARE q_dpagc CURSOR FOR dpagc
		LET entro = 0
		OPEN q_dpagc USING vg_codcia, r_rep.localidad, r_adi.*
		WHILE TRUE
			FETCH q_dpagc INTO r_dp.*
			IF STATUS = NOTFOUND THEN
				EXIT WHILE
			END IF
			LET nombre_bt = NULL
			IF r_dp.j11_codigo_pago = 'CH' OR
			   r_dp.j11_codigo_pago = 'DP'
			THEN
				SELECT g08_nombre
					INTO nombre_bt
					FROM gent008
					WHERE g08_banco = r_dp.j11_cod_bco_tarj
			END IF
 			IF r_dp.j11_codigo_pago = 'TJ' THEN
				SELECT g10_nombre
					INTO nombre_bt
					FROM gent010
					WHERE g10_tarjeta =r_dp.j11_cod_bco_tarj
			END IF
			PRINT COLUMN 093, r_dp.j11_codigo_pago,
			      COLUMN 097, nombre_bt           CLIPPED,
			      COLUMN 119, r_dp.j11_num_ch_aut CLIPPED,
			      COLUMN 136, r_dp.j11_moneda     CLIPPED,
			      COLUMN 140, r_dp.j11_valor     USING "----,--&.##"
			LET entro = 1
		END WHILE
		CLOSE q_dpagc
		FREE q_dpagc
		IF entro THEN
			SKIP 1 LINES
		END IF
	END IF
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 138, "-----------",
	      COLUMN 150, "-----------"
	PRINT COLUMN 125, "TOTALES ==>  ",
	      COLUMN 138, SUM(r_rep.val_doc)	USING "----,--&.##",
	      COLUMN 150, SUM(r_rep.val_cob)	USING "----,--&.##"
	SKIP 2 LINES
	DECLARE q_totales CURSOR FOR
		SELECT z22_tipo_trn, z04_nombre, NVL(SUM(valor_doc), 0),
			NVL(SUM(valor_mov), 0), COUNT(*)
			FROM tmp_mov, cxct004
			WHERE z04_tipo_doc = z22_tipo_trn
			GROUP BY 1, 2
			ORDER BY 1
	FOREACH q_totales INTO tipo, tipo_nom, total_doc, total_mov, total_trn
		PRINT COLUMN 005, "TOTAL DOCUMENTOS  ==> ",
			total_doc USING "----,--&.##",
		      COLUMN 045, "TOTAL ", tipo CLIPPED, " - ",
			tipo_nom CLIPPED,
		      COLUMN 071, " (", total_trn USING "<<<&&", ") ==> ",
		      COLUMN 083, total_mov USING "----,--&.##"
	END FOREACH
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION control_generar_archivo()
DEFINE mensaje		VARCHAR(200)
DEFINE resp		CHAR(6)

LET int_flag = 0
CALL fl_hacer_pregunta('Desea generar este listado en archivo ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	LET int_flag = 0
	CALL fl_hacer_pregunta('Desea generar el archivo por semanas ?', 'No')
		RETURNING resp
	IF resp = 'Yes' THEN
		CALL control_generar_archivo_ind()
	END IF
	RETURN
END IF
{--
SELECT cajt010.*, cajt011.*, z23_codcli, z23_tipo_doc, z23_num_doc, z23_div_doc
	FROM cajt010, cajt011, cxct023
	WHERE j10_compania         = vg_codcia
	  AND j10_localidad        = vg_codloc
	  AND j10_tipo_fuente      = "SC"
	  AND DATE(j10_fecha_pro) <= rm_par.fecha_fin
	  AND j11_compania         = j10_compania
	  AND j11_localidad        = j10_localidad
	  AND j11_tipo_fuente      = j10_tipo_fuente
	  AND j11_num_fuente       = j10_num_fuente
	  AND z23_compania         = j10_compania
	  AND z23_localidad        = j10_localidad
	  AND z23_codcli           = j10_codcli
	  AND z23_tipo_trn         = j10_tipo_destino
	  AND z23_num_trn          = j10_num_destino
--}
SELECT z23_localidad, z23_codcli, z23_tipo_doc, z23_num_doc, z23_div_doc,
	NVL(SUM(z23_valor_cap + z23_valor_int), 0) valor_pag
	FROM cxct022, cxct023
	WHERE z22_compania      = vg_codcia
	  AND z22_localidad     = vg_codloc
	  AND z22_tipo_trn     <> "AJ"
	  AND DATE(z22_fecing) <= rm_par.fecha_fin
	  AND z23_compania      = z22_compania
	  AND z23_localidad     = z22_localidad
	  AND z23_codcli        = z22_codcli
	  AND z23_tipo_trn      = z22_tipo_trn
	  AND z23_num_trn       = z22_num_trn
	GROUP BY 1, 2, 3, 4, 5
	INTO TEMP t1
UNLOAD TO "../../../tmp/cxcp417.unl"
	SELECT z20_codcli, z01_nomcli, z20_tipo_doc, z20_num_doc, z20_dividendo,
		z22_tipo_trn, z22_num_trn, z22_localidad, r01_nombres,
		cobrador_mov, z20_fecha_emi, z20_fecha_vcto, z22_fecha_emi,
		fecha, valor_doc, valor_mov, z22_areaneg, saldo_doc,
		--NVL(SUM(j11_valor), 0) valor_pag
		NVL(valor_pag, 0) valor_pag
		FROM tmp_mov, OUTER t1
		WHERE z23_localidad = z22_localidad
		  AND z23_codcli    = z20_codcli
		  AND z23_tipo_doc  = z20_tipo_doc
		  AND z23_num_doc   = z20_num_doc
		  AND z23_div_doc   = z20_dividendo
		{--
		WHERE j10_localidad   = z22_localidad
		  AND j10_areaneg     = z22_areaneg
		  AND j10_compania    = j11_compania
		  AND z23_codcli      = z20_codcli
		  AND z23_tipo_doc    = z20_tipo_doc
		  AND z23_num_doc     = z20_num_doc
		  AND z23_div_doc     = z20_dividendo
		  AND j10_localidad   = j11_localidad
		  AND j10_tipo_fuente = j11_tipo_fuente
		  AND j10_num_fuente  = j11_num_fuente
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
			17, 18
		--}
		ORDER BY z01_nomcli, z20_fecha_emi, z20_tipo_doc, z20_num_doc,
			z20_dividendo
RUN "mv ../../../tmp/cxcp417.unl $HOME/tmp/"
LET mensaje = 'Archivo Generado en ', FGL_GETENV("HOME"), '/tmp/cxcp417.unl',
		' OK.'
DROP TABLE t1
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION control_generar_archivo_ind()
DEFINE mensaje		VARCHAR(200)

SELECT g02_nombre, NVL(z06_nombre, "SIN COBRADOR") cobrador,
	YEAR(z22_fecha_emi) anio, fp_numero_semana(z22_fecha_emi) semana,
	--
	z20_codcli, z01_nomcli, z20_tipo_doc, z20_num_doc, z20_dividendo, z22_fecha_emi,
	--
	NVL((valor_mov * (-1)), 0.00) valor_mov
	FROM tmp_mov, gent002, OUTER (cxct002, cxct006)
	WHERE z22_tipo_trn   IN ("PG", "AR")
	  AND g02_compania    = vg_codcia
	  AND g02_localidad   = z22_localidad
	  AND z02_compania    = g02_compania
	  AND z02_localidad   = g02_localidad
	  AND z02_codcli      = z20_codcli
	  AND z06_zona_cobro  = z02_zona_cobro
	--GROUP BY 1, 2, 3, 4, 5
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
	INTO TEMP t1
UNLOAD TO "../../../tmp/cxcp417_ind.unl"
	SELECT g02_nombre, cobrador, anio, semana,
		--
		z20_codcli, z01_nomcli, z20_tipo_doc, z20_num_doc, z20_dividendo, z22_fecha_emi,
		--
		NVL(SUM(valor_mov), 0.00)
		FROM t1
		--GROUP BY 1, 2, 3, 4
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
RUN "mv ../../../tmp/cxcp417_ind.unl $HOME/tmp/"
LET mensaje = 'Archivo Generado en ', FGL_GETENV("HOME"),'/tmp/cxcp417_ind.unl',
		' OK.'
CALL fl_mostrar_mensaje(mensaje, 'info')
DROP TABLE t1

END FUNCTION
