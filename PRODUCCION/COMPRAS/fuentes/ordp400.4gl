
------------------------------------------------------------------------------
-- Titulo           : ordp400.4gl - LISTADO DE ORDEN DE COMPRA
-- Elaboracion      : 12-MAR-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun ordp400 base módulo compañía localidad [orden]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_com		RECORD LIKE ordt010.*
DEFINE rm_dcom		RECORD LIKE ordt011.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_prov		RECORD LIKE cxpt001.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp400.error')
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
LET vg_proceso = 'ordp400'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 09 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/ordf400_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(600)
DEFINE comando		VARCHAR(100)

DEFINE r_report 	RECORD
	cant 		LIKE ordt011.c11_cant_ped,
	codigo 		LIKE ordt011.c11_codigo,
	descripcion	LIKE ordt011.c11_descrip,
	dscto		LIKE ordt011.c11_descuento,
	precio		LIKE ordt011.c11_precio
	END RECORD

LET rm_com.c10_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_com.c10_moneda) RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO tit_estado

WHILE TRUE

	IF num_args() = 4 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE
	    LET rm_com.c10_numero_oc = arg_val(5)
	    CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_com.c10_numero_oc)
		RETURNING rm_com.*
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		IF num_args() = 4 THEN
			CONTINUE WHILE
		ELSE
			EXIT WHILE
		END IF
	END IF

	LET query = 'SELECT c11_cant_ped, c11_codigo, c11_descrip, ',
			'c11_descuento, c11_precio ',
			'FROM ordt010, ordt011 ',
			'WHERE c10_compania  = ', vg_codcia,
			'  AND c10_localidad = ', vg_codloc,
			'  AND c10_numero_oc = ', rm_com.c10_numero_oc,
			'  AND c10_moneda    = "', rm_com.c10_moneda ,'"',
			'  AND c10_compania  = c11_compania',
			'  AND c10_localidad = c11_localidad',
			'  AND c10_numero_oc = c11_numero_oc'

	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	OPEN q_deto
	FETCH q_deto
	IF STATUS = NOTFOUND THEN
		CLOSE q_deto
		CALL fl_mensaje_consulta_sin_registros()
		IF num_args() = 4 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	CLOSE q_deto
	START REPORT report_orden_compra TO PIPE comando
	FOREACH q_deto INTO r_report.*
		OUTPUT TO REPORT report_orden_compra(r_report.*)
	END FOREACH
	FINISH REPORT report_orden_compra
	--IF num_args() = 5 THEN
	--	EXIT WHILE
	--END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_com		RECORD LIKE ordt010.*
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE r_mon		RECORD LIKE gent013.*

OPTIONS INPUT NO WRAP

INITIALIZE r_mon.*, r_prov.*, r_com.* TO NULL

LET int_flag = 0
INPUT BY NAME rm_com.c10_numero_oc, rm_com.c10_moneda
		WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(c10_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_com.c10_moneda = r_mon.g13_moneda
				DISPLAY BY NAME rm_com.c10_moneda
				DISPLAY r_mon.g13_nombre TO tit_estado
				LET rm_g13.* = r_mon.* 
			END IF
		END IF
		IF INFIELD(c10_numero_oc) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc, 0,
						     0, 'T', '00', 'T')
				RETURNING r_com.c10_numero_oc
			IF r_com.c10_numero_oc IS NOT NULL THEN
				CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
							 r_com.c10_numero_oc)
					RETURNING r_com.*
				LET rm_com.* = r_com.*
				DISPLAY BY NAME rm_com.c10_numero_oc,
						rm_com.c10_moneda,
						rm_com.c10_solicitado,
						rm_com.c10_codprov
				CALL fl_lee_moneda(rm_com.c10_moneda)
					RETURNING rm_g13.*
				DISPLAY rm_g13.g13_nombre TO tit_estado
				CALL fl_lee_proveedor(rm_com.c10_codprov)
					RETURNING rm_prov.*
				DISPLAY rm_prov.p01_nomprov TO nom_prov
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD c10_numero_oc
		IF rm_com.c10_numero_oc IS NOT NULL THEN
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
						 rm_com.c10_numero_oc)
				RETURNING r_com.*
			IF r_com.c10_numero_oc IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la Orden de Compra en la Companía.','exclamation')
				NEXT FIELD c10_numero_oc
			ELSE
				LET rm_com.* = r_com.*
				DISPLAY BY NAME rm_com.c10_numero_oc,
						rm_com.c10_moneda,
						rm_com.c10_solicitado,
						rm_com.c10_codprov
				CALL fl_lee_moneda(rm_com.c10_moneda)
					RETURNING rm_g13.*
				DISPLAY rm_g13.g13_nombre TO tit_estado
				CALL fl_lee_proveedor(rm_com.c10_codprov)
					RETURNING rm_prov.*
				DISPLAY rm_prov.p01_nomprov TO nom_prov
			END IF
		END IF
	AFTER FIELD c10_moneda
		IF rm_com.c10_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_com.c10_moneda)
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la moneda en la Compañía.','exclamation')
				NEXT FIELD c10_moneda
			ELSE
				LET rm_g13.* = r_mon.*
				LET rm_com.c10_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME rm_com.c10_moneda
				DISPLAY rm_g13.g13_nombre TO tit_estado
			END IF
		END IF
	AFTER INPUT 
		IF rm_com.c10_numero_oc IS NULL THEN
			NEXT FIELD c10_numero_oc
		END IF
END INPUT

END FUNCTION



REPORT report_orden_compra(cant, codigo, descripcion, dscto, precio)
DEFINE cant		LIKE ordt011.c11_cant_ped
DEFINE codigo		LIKE ordt011.c11_codigo
DEFINE descripcion	LIKE ordt011.c11_descrip
DEFINE dscto		LIKE ordt011.c11_descuento
DEFINE precio		LIKE ordt011.c11_precio
DEFINE r_tip_oc		RECORD LIKE ordt001.*
DEFINE nom_estado 	CHAR(10)
DEFINE forma_pago 	CHAR(10)
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE r_depto		RECORD LIKE gent034.*
DEFINE r_ord_trab	RECORD LIKE talt023.*
DEFINE fecha_aux 	DATE

DEFINE titulo		VARCHAR(80)

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	10
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER
	print 'E'; print '&l26A';  -- Indica que voy a trabajar con hojas A4
	print '&k2S'	                -- Letra condensada (16 cpi)
	CALL fl_justifica_titulo('C',
	     'ORDEN DE COMPRA No  ' || rm_com.c10_numero_oc , 80)
		RETURNING titulo
	PRINT COLUMN 1, rg_cia.g01_razonsocial
	PRINT COLUMN 1, titulo CLIPPED
	PRINT COLUMN 1, 'Fecha: ', TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME,
		COLUMN 65, 'Página: ', PAGENO USING '&&&'

	SKIP 1 LINES


	LET fecha_aux = DATE(rm_com.c10_fecing) USING 'dd-mm-yyyy'

	PRINT COLUMN 1, 'No Orden: ', 
	      COLUMN 20, fl_justifica_titulo('I',rm_com.c10_numero_oc,6),
	      COLUMN 27, 'Moneda:  ', rm_g13.g13_nombre,
	      COLUMN 70, 'Fecha de Orden: ',
	      COLUMN 88, fl_justifica_titulo('D',fecha_aux,18)
	CALL fl_lee_tipo_orden_compra(rm_com.c10_tipo_orden)
		RETURNING r_tip_oc.*
	
	CASE rm_com.c10_estado 
		WHEN 'A'
			LET nom_estado = 'ACTIVA'
		WHEN 'P'
			LET nom_estado = 'APROBADA'
		WHEN 'C'
			LET nom_estado = 'CERRADA'
	END CASE  

	PRINT COLUMN 1, 'Tipo: ', 
	      COLUMN 20, fl_justifica_titulo('I', rm_com.c10_tipo_orden,4),
			 '   ',	r_tip_oc.c01_nombre,
		COLUMN 70, 'Estado: ',
		COLUMN 88, fl_justifica_titulo('D',nom_estado,18)  

	CALL fl_lee_departamento(vg_codcia, rm_com.c10_cod_depto)
		RETURNING r_depto.*
	PRINT COLUMN 1, 'Departamento: ', 
	      COLUMN 20, fl_justifica_titulo('I',rm_com.c10_cod_depto,4),'   ',
		r_depto.g34_nombre,
	      COLUMN 70, 'Impuesto: ', 
	      COLUMN 88, fl_justifica_titulo('D',rm_com.c10_porc_impto,18)  

	PRINT COLUMN 1, 'Proveedor: ', 
	      COLUMN 20, fl_justifica_titulo('I',rm_com.c10_codprov,5), '  ',
		 rm_prov.p01_nomprov,
	      COLUMN 70, 'Descuento: ', 
	      COLUMN 88, fl_justifica_titulo('D',rm_com.c10_porc_descto,18)  

	CASE rm_com.c10_tipo_pago 
		WHEN 'C'
			LET forma_pago = 'CONTADO'
		WHEN 'R'
			LET forma_pago = 'CREDITO'
	END CASE  

	PRINT COLUMN 1, 'Referencia: ', 
	      COLUMN 20, rm_com.c10_referencia,
              COLUMN 70, 'Forma de Pago: ', 
	      COLUMN 88, fl_justifica_titulo('D',forma_pago,18) 

	CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_com.c10_ord_trabajo)
		RETURNING r_ord_trab.*
	PRINT COLUMN 1, 'Orden de Trabajo: ', 
	      COLUMN 20, fl_justifica_titulo('I',rm_com.c10_ord_trabajo,6),
			 ' ', r_ord_trab.t23_nom_cliente,
	      COLUMN 70, 'Solicitado Por: ', 
	      COLUMN 88, fl_justifica_titulo('D',rm_com.c10_solicitado,18)

	PRINT "========================================================================================================="
	PRINT COLUMN 1,  "Cant.",
	      COLUMN 08, "Código",
	      COLUMN 28, "Descripción",
	      COLUMN 72, "Dscto. %",
	      COLUMN 100, "Precio"
	PRINT "========================================================================================================="

ON EVERY ROW
	PRINT COLUMN 2, fl_justifica_titulo('I',cant,4),
	      COLUMN 08, fl_justifica_titulo('I',codigo,15),
	      COLUMN 28, descripcion[1,40],
	      COLUMN 72, fl_justifica_titulo('D',dscto,5) USING '#&.##',
	      COLUMN 90, fl_justifica_titulo('D',precio,16) 
						USING '#,###,###,##&.##'

ON LAST ROW

	NEED 6 LINES
	SKIP 2 LINES
	PRINT COLUMN 20, 'SUBTOTAL ',
		COLUMN 45, fl_justifica_titulo('D',rm_com.c10_tot_repto + 
						   rm_com.c10_tot_mano,16)
						USING '#,###,###,##&.##'
	PRINT COLUMN 20, 'TOTAL DSCTO. ',
		COLUMN 45, fl_justifica_titulo('D',rm_com.c10_tot_dscto,16) 
						USING '#,###,###,##&.##'

	PRINT COLUMN 20, 'TOTAL IMPTO. ',
		COLUMN 45, fl_justifica_titulo('D',rm_com.c10_tot_impto,16) 
				USING '#,###,###,##&.##'
	PRINT COLUMN 20, 'TOTAL ',
		COLUMN 45, fl_justifica_titulo('D',rm_com.c10_tot_compra,16) 

END REPORT



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_com.* TO NULL

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
