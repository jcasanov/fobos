--------------------------------------------------------------------------------
-- Titulo           : cxcp418.4gl - Listado de Cobranza realizada en un período
-- Elaboracion      : 15-Nov-2010
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp418 base modulo compañía localidad
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
				con_retencion	CHAR(1),
				tipcli		LIKE gent012.g12_subtipo,
				tit_tipcli	LIKE gent012.g12_nombre,
				tipcar		LIKE gent012.g12_subtipo,
				tit_tipcar	LIKE gent012.g12_nombre,
				con_saldo	CHAR(1),
				localidad	LIKE gent002.g02_localidad,
				tit_localidad	LIKE gent002.g02_nombre,
				zona_venta	LIKE gent032.g32_zona_venta,
				tit_zona_venta	LIKE gent032.g32_nombre,
				zona_cobro	LIKE cxct006.z06_zona_cobro,
				tit_zona_cobro	LIKE cxct006.z06_nombre,
				vendedor	LIKE rept019.r19_vendedor,
				tit_vendedor	LIKE rept001.r01_nombres,
				cobrador	LIKE cxct005.z05_codigo,
				tit_cobrador	LIKE cxct005.z05_nombres,
				comision	CHAR(2)
			END RECORD
DEFINE vm_fecha_ini	DATE
DEFINE vm_fin_mes	DATE
DEFINE rm_z60		RECORD LIKE cxct060.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp418.err')
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
LET vg_proceso = 'cxcp418'
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
OPEN WINDOW w_cxcf418_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_par FROM "../forms/cxcf418_1"
DISPLAY FORM f_par
INITIALIZE rm_par.* TO NULL
LET rm_par.moneda    = rg_gen.g00_moneda_base
LET rm_par.fecha_ini = MDY(MONTH(TODAY), 01, YEAR(TODAY))
LET vm_fin_mes       = rm_par.fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
LET rm_par.fecha_fin = vm_fin_mes
LET rm_par.con_retencion = 'N'
LET rm_par.con_saldo = 'N'
LET rm_par.comision  = 'S'
LET vm_fecha_ini     = rm_z60.z60_fecha_carga
CALL control_reporte()
CLOSE WINDOW w_cxcf418_1
EXIT PROGRAM

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
			CALL fl_ayuda_zona_cobro()
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
		IF rm_par.fecha_ini > TODAY THEN
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
				localidad	LIKE cxct022.z22_localidad,
				vendedor	LIKE rept001.r01_nombres,
				cobrador	LIKE cxct005.z05_nombres,
				fec_emi		LIKE cxct020.z20_fecha_emi,
				fec_vcto	LIKE cxct020.z20_fecha_vcto,
				val_doc		DECIMAL(12,2),
				val_cob		DECIMAL(12,2)
			END RECORD
DEFINE documento	VARCHAR(15)
DEFINE comando		VARCHAR(100)
DEFINE query		CHAR(5000)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3, expr4	VARCHAR(100)
DEFINE expr5, expr6	VARCHAR(100)
DEFINE expr7, expr9	VARCHAR(100)
DEFINE expr8		VARCHAR(250)
DEFINE expr10, expr11	VARCHAR(100)
DEFINE expr12		VARCHAR(100)
DEFINE expr14		CHAR(400)
DEFINE expr15		CHAR(100)
DEFINE tabl1		VARCHAR(10)
DEFINE cuantos		INTEGER
DEFINE fecing		LIKE cxct022.z22_fecing
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE saldo		LIKE cxct020.z20_saldo_cap

ERROR "Procesando documentos deudores . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2, expr3, expr4, expr5, expr6, expr7, expr8, expr9,
		expr10, expr11, expr12, expr14, expr15, tabl1 TO NULL
LET expr1 = '   AND z20_moneda       = "', rm_par.moneda, '"'
LET expr2 = '   AND DATE(r19_fecing) BETWEEN "', rm_par.fecha_ini,
				      '" AND "', rm_par.fecha_fin, '"'
LET expr15 = '   AND DATE(t23_num_factura) BETWEEN "', rm_par.fecha_ini,
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
IF rm_par.comision <> 'T' THEN
	LET expr12 = '   AND z05_comision     = "', rm_par.comision, '"'
--ELSE
--	LET expr12 = ')'
END IF
LET query = 'SELECT z20_compania, z20_localidad, z20_codcli, z20_tipo_doc, ',
			'z20_num_doc, z20_areaneg, MIN(z20_fecha_emi) fec_emi,',
			' MAX(z20_fecha_vcto) fec_vcto, ',
			'NVL(SUM(z20_valor_cap + z20_valor_int), 0) valor_doc,',
			'NVL(SUM(z20_saldo_cap + z20_saldo_int), 0) saldo_doc,',
			' z20_cod_tran, z20_num_tran ',
		' FROM cxct020 ',
		' WHERE z20_compania     = ', vg_codcia,
		'   AND z20_tipo_doc     = "FA" ',
			expr7  CLIPPED,
			expr3  CLIPPED,
			expr4  CLIPPED,
			expr1  CLIPPED,
			expr6  CLIPPED,
		' GROUP BY 1, 2, 3, 4, 5, 6, 11, 12 '
IF rm_par.con_saldo = 'S' THEN
	LET query = query CLIPPED,
			' UNION ',
			' SELECT z20_compania, z20_localidad, z20_codcli, ',
				'z20_tipo_doc, z20_num_doc, z20_areaneg, ',
				'MIN(z20_fecha_emi) fec_emi, ',
				'MAX(z20_fecha_vcto) fec_vcto, ',
				'NVL(SUM(z20_valor_cap + z20_valor_int), 0) ',
					'valor_doc, ',
				'0.00 saldo_doc, z20_cod_tran, z20_num_tran ',
				' FROM cxct020 ',
				' WHERE z20_compania     = ', vg_codcia,
				'   AND z20_tipo_doc     = "FA" ',
					expr7  CLIPPED,
					expr3  CLIPPED,
					expr4  CLIPPED,
					expr1  CLIPPED,
					expr6  CLIPPED,
				'   AND z20_saldo_cap + z20_saldo_int = 0 ',
				' GROUP BY 1, 2, 3, 4, 5, 6, 10, 11, 12 '
END IF
LET query = query CLIPPED, ' INTO TEMP t1 '
PREPARE cons_t1 FROM query
EXECUTE cons_t1
LET query = 'SELECT * FROM t1 ',
		'WHERE fec_emi BETWEEN "', rm_par.fecha_ini,
				'" AND "', rm_par.fecha_fin, '"',
		'INTO TEMP tmp_aux '
PREPARE cons_tmp_aux FROM query
EXECUTE cons_tmp_aux
DROP TABLE t1
SELECT * FROM tmp_aux INTO TEMP t1
DROP TABLE tmp_aux
IF rm_par.con_retencion = 'N' THEN
	LET query = 'SELECT * FROM cajt014 ',
			' WHERE j14_compania      = ', vg_codcia,
			'   AND j14_tipo_fuente   = "SC" ',
			' INTO TEMP tmp_j14 '
	PREPARE cons_tmp_j14 FROM query
	EXECUTE cons_tmp_j14
	CREATE INDEX tmp_pk 
		ON tmp_j14 (j14_compania, j14_localidad, j14_tipo_fue,
				j14_cod_tran, j14_num_tran)
	LET query = 'SELECT * FROM t1 ',
			' WHERE z20_areaneg = 1 ',
			'   AND NOT EXISTS ',
				'(SELECT 1 FROM tmp_j14 ',
				' WHERE j14_compania    = z20_compania ',
				'   AND j14_localidad   = z20_localidad ',
				'   AND j14_tipo_fue    = "PR" ',
				'   AND j14_cod_tran    = z20_cod_tran ',
				'   AND j14_num_tran    = z20_num_tran) ',
			' UNION ',
			' SELECT * FROM t1 ',
			' WHERE z20_areaneg = 2 ',
			'   AND NOT EXISTS ',
				'(SELECT 1 FROM tmp_j14 ',
				' WHERE j14_compania    = z20_compania ',
				'   AND j14_localidad   = z20_localidad ',
				'   AND j14_tipo_fue    = "OT" ',
				'   AND j14_cod_tran    = z20_cod_tran ',
				'   AND j14_num_tran    = z20_num_tran) ',
		' INTO TEMP tmp_t1 '
	PREPARE cons_tmp_t1 FROM query
	EXECUTE cons_tmp_t1
	DROP TABLE t1
	DROP TABLE tmp_j14
	SELECT * FROM tmp_t1 INTO TEMP t1
	DROP TABLE tmp_t1
END IF
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos = 0 THEN
	ERROR ' '
	DROP TABLE tmp_cli
	DROP TABLE t1
	CALL fl_mostrar_mensaje('No existen documentos con este criterio de búsqueda.', 'exclamation')
	RETURN
END IF
LET query = 'SELECT t1.*, r01_nombres ',
		' FROM t1, rept019, rept001 ',
		' WHERE z20_areaneg      = 1 ',
		'   AND r19_compania     = z20_compania ',
		'   AND r19_localidad    = z20_localidad ',
		'   AND r19_cod_tran     = z20_cod_tran ',
		'   AND r19_num_tran     = z20_num_tran ',
		expr9 CLIPPED,
		expr2 CLIPPED,
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
			expr15 CLIPPED,
			'   AND r01_compania     = t61_compania ',
			'   AND r01_codigo       = t61_cod_vendedor ',
		' INTO TEMP t2 '
PREPARE cons_t2 FROM query
EXECUTE cons_t2
SELECT * FROM t2 INTO TEMP tmp_z20
DROP TABLE t1
DROP TABLE t2
SELECT COUNT(*) INTO cuantos FROM tmp_z20 
IF cuantos = 0 THEN
	ERROR ' '
	DROP TABLE tmp_z20
	CALL fl_mostrar_mensaje('No existen documentos con este criterio de búsqueda.', 'exclamation')
	RETURN
END IF
LET query = 'SELECT z20_compania, z20_localidad, z20_codcli, z01_nomcli,',
			' z20_tipo_doc, z20_num_doc, r01_nombres, fec_emi,',
			' fec_vcto, valor_doc, saldo_doc, z20_areaneg ',
		' FROM tmp_z20, gent002, tmp_cli ',
		' WHERE g02_compania   = z20_compania ',
		'   AND g02_localidad  = z20_localidad ',
		'   AND z01_codcli     = z20_codcli ',
			expr5 CLIPPED,
		' INTO TEMP tmp_doc '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
CREATE INDEX tmp_pk2
	ON tmp_doc (z20_compania, z20_localidad, z20_codcli, z01_nomcli,
			z20_tipo_doc, z20_num_doc, r01_nombres, fec_emi,
			fec_vcto, valor_doc, saldo_doc, z20_areaneg)
DROP TABLE tmp_cli
DROP TABLE tmp_z20
SELECT COUNT(*) INTO cuantos FROM tmp_doc 
ERROR ' '
IF cuantos = 0 THEN
	DROP TABLE tmp_doc
	CALL fl_mostrar_mensaje('No existen documentos con saldo para este criterio de búsqueda.', 'exclamation')
	RETURN
END IF
LET query = 'SELECT UNIQUE z23_compania, z23_localidad, z23_codcli, ',
			'z23_tipo_doc, z23_num_doc, z05_nombres ',
		' FROM cxct023, cxct022, cxct005 ',
		' WHERE z22_compania     = z23_compania ',
		'   AND z22_localidad    = z23_localidad ',
		'   AND z22_codcli       = z23_codcli ',
		'   AND z22_tipo_trn     = z23_tipo_trn ',
		'   AND z22_num_trn      = z23_num_trn ',
		'   AND DATE(z22_fecing) BETWEEN "', rm_par.fecha_ini,
					  '" AND "', rm_par.fecha_fin, '"',
		expr11 CLIPPED,
		'   AND z05_compania     = z22_compania ',
		'   AND z05_codigo       = z22_cobrador ',
			expr12 CLIPPED,
		'INTO TEMP t_c '
PREPARE exec_cob FROM query
EXECUTE exec_cob
CREATE INDEX tmp_pk3
	ON t_c (z23_compania, z23_localidad, z23_codcli, z23_tipo_doc,
		z23_num_doc)
SELECT z23_compania cia, z23_localidad loc, z23_codcli cli, z23_tipo_doc td,
	z23_num_doc nd, COUNT(*) tot_reg
	FROM t_c
	GROUP BY 1, 2, 3, 4, 5
	HAVING COUNT(*) > 1
	INTO TEMP t_c2
SELECT UNIQUE z23_compania, z23_localidad, z23_codcli, z23_tipo_doc,
	z23_num_doc, "COB. DUPLI." z05_nombres
	FROM t_c, t_c2
	WHERE z23_compania  = cia
	  AND z23_localidad = loc
	  AND z23_codcli    = cli
	  AND z23_tipo_doc  = td
	  AND z23_num_doc   = nd
UNION
SELECT z23_compania, z23_localidad, z23_codcli, z23_tipo_doc, z23_num_doc,
	z05_nombres
	FROM t_c
	WHERE NOT EXISTS
		(SELECT 1 FROM t_c2
			WHERE z23_compania  = cia
			  AND z23_localidad = loc
			  AND z23_codcli    = cli
			  AND z23_tipo_doc  = td
			  AND z23_num_doc   = nd)
	INTO TEMP temp_cob
CREATE INDEX tmp_pk4
	ON temp_cob (z23_compania, z23_localidad, z23_codcli, z23_tipo_doc,
		z23_num_doc)
DROP TABLE t_c
DROP TABLE t_c2
LET query = 'SELECT z20_codcli, z01_nomcli, z20_tipo_doc, z20_num_doc,',
			' z20_localidad, r01_nombres,',
			' NVL((SELECT UNIQUE z05_nombres ',
				' FROM temp_cob ',
				' WHERE z23_compania     = z20_compania ',
				'   AND z23_localidad    = z20_localidad ',
				'   AND z23_codcli       = z20_codcli ',
				'   AND z23_tipo_doc     = z20_tipo_doc ',
				'   AND z23_num_doc      = z20_num_doc), ',
			'"SIN COBRADOR") cobrador_mov,',
			' fec_emi, fec_vcto, valor_doc,',
			' NVL(SUM((SELECT SUM(z23_valor_cap + z23_valor_int)',
				' FROM cxct023, cxct022 ',
				' WHERE z23_compania     = z20_compania ',
				'   AND z23_localidad    = z20_localidad ',
				'   AND z23_codcli       = z20_codcli ',
				'   AND z23_tipo_doc     = z20_tipo_doc ',
				'   AND z23_num_doc      = z20_num_doc ',
				'   AND z22_compania     = z23_compania ',
				'   AND z22_localidad    = z23_localidad ',
				'   AND z22_codcli       = z23_codcli ',
				'   AND z22_tipo_trn     = z23_tipo_trn ',
				'   AND z22_num_trn      = z23_num_trn)) ',
			',0) valor_mov,',
			' z20_areaneg, saldo_doc ',
		' FROM tmp_doc ',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13 ',
		' INTO TEMP tmp_mov '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
DROP TABLE temp_cob
CALL control_generar_archivo()
LET query = 'SELECT * FROM tmp_mov ',
		' ORDER BY z01_nomcli, fec_emi, z20_tipo_doc,',
			' z20_num_doc '
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
FOREACH q_report INTO r_aux.*, areaneg, saldo
	LET documento = r_aux.tipo_doc CLIPPED, '-',
			r_aux.num_doc USING "<<<<<&&"
	OUTPUT TO REPORT report_list_cobranza(r_aux.codcli, r_aux.nomcli,
						documento, r_aux.localidad,
						r_aux.vendedor,
						r_aux.cobrador, r_aux.fec_emi,
						r_aux.fec_vcto, r_aux.val_doc,
						r_aux.val_cob, areaneg)
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
				localidad	LIKE cxct022.z22_localidad,
				vendedor	LIKE rept001.r01_nombres,
				cobrador	LIKE cxct005.z05_nombres,
				fec_emi		LIKE cxct020.z20_fecha_emi,
				fec_vcto	LIKE cxct020.z20_fecha_vcto,
				val_doc		DECIMAL(12,2),
				val_cob		DECIMAL(12,2)
			END RECORD
DEFINE r_adi		RECORD
				areaneg		LIKE cxct022.z22_areaneg
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
	      COLUMN 062, "<< LISTADO DE FACTURAS A CREDITO >>",
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
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 142, usuario
	PRINT "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 029, "C L I E N T E S",
	      COLUMN 065, "DOCUMENTOS",
	      COLUMN 081, "LC",
	      COLUMN 084, "VENDEDOR",
	      COLUMN 100, "COBRADOR",
	      COLUMN 116, "FECHA EMI.",
	      COLUMN 127, "FEC. VCTO.",
	      COLUMN 138, " VALOR DOC.",
	      COLUMN 150, " VALOR COB."
	PRINT "----------------------------------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_rep.codcli		USING "####&&",
	      COLUMN 008, r_rep.nomcli[1, 56]	CLIPPED,
	      COLUMN 065, r_rep.documento	CLIPPED,
	      COLUMN 081, r_rep.localidad	USING "&&",
	      COLUMN 084, r_rep.vendedor[1, 15]	CLIPPED,
	      COLUMN 100, r_rep.cobrador[1, 15]	CLIPPED,
	      COLUMN 116, r_rep.fec_emi		USING "dd-mm-yyyy",
	      COLUMN 127, r_rep.fec_vcto	USING "dd-mm-yyyy",
	      COLUMN 138, r_rep.val_doc		USING "----,--&.##",
	      COLUMN 150, r_rep.val_cob		USING "----,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 138, "-----------",
	      COLUMN 150, "-----------"
	PRINT COLUMN 125, "TOTALES ==>  ",
	      COLUMN 138, SUM(r_rep.val_doc)	USING "----,--&.##",
	      COLUMN 150, SUM(r_rep.val_cob)	USING "----,--&.##"
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
	RETURN
END IF
UNLOAD TO "../../../tmp/cxcp418.unl"
	SELECT z20_codcli, z01_nomcli, z20_tipo_doc, z20_num_doc,
		z20_localidad, r01_nombres, cobrador_mov, fec_emi, fec_vcto,
		valor_doc, valor_mov, z20_areaneg, saldo_doc
		FROM tmp_mov
		ORDER BY z01_nomcli, fec_emi, z20_tipo_doc, z20_num_doc
RUN "mv ../../../tmp/cxcp418.unl $HOME/tmp/"
LET mensaje = 'Archivo Generado en ', FGL_GETENV("HOME"), '/tmp/cxcp418.unl',
		' OK.'
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION
