------------------------------------------------------------------------------
-- Titulo           : cxcp414.4gl - Listado de Nota de Crédito
-- Elaboracion      : 27-Dic-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp414 base módulo compañía localidad
-- 			[cliente] [nota crédito] [número]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_r19		RECORD LIKE rept019.*
DEFINE rm_dev		RECORD LIKE rept019.*
DEFINE rm_z21		RECORD LIKE cxct021.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 7 THEN   -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base		= arg_val(1)
LET vg_modulo		= arg_val(2)
LET vg_codcia		= arg_val(3)
LET vg_codloc		= arg_val(4)
LET rm_z21.z21_codcli	= arg_val(5)
LET rm_z21.z21_tipo_doc	= arg_val(6)
LET rm_z21.z21_num_doc	= arg_val(7)
LET vg_proceso 		= 'cxcp414'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
IF rm_z21.z21_tipo_doc <> 'NC' THEN
	CALL fl_mostrar_mensaje('El documento debe ser una Nota de Crédito.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_documento_favor_cxc(vg_codcia, vg_codloc, rm_z21.z21_codcli,
				rm_z21.z21_tipo_doc, rm_z21.z21_num_doc)
	RETURNING rm_z21.*
IF rm_z21.z21_cod_tran = "FA" THEN
	CALL imprimir_nc_taller()
	RETURN
END IF
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE comando		VARCHAR(100)
DEFINE r_rep		RECORD
				r20_item	LIKE rept020.r20_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_dev	LIKE rept020.r20_cant_dev,
				precio		LIKE rept020.r20_precio,
				descuento	LIKE rept020.r20_descuento,
				valor_tot	DECIMAL(14,2)
			END RECORD
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_z01		RECORD LIKE cxct001.*

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_localidad IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe localidad.','stop')
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc,
			rm_z21.z21_cod_tran, rm_z21.z21_num_tran)
	RETURNING rm_r19.*
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc,
			rm_r19.r19_tipo_dev, rm_r19.r19_num_dev)
	RETURNING rm_dev.*
IF rm_z21.z21_cod_tran IS NULL THEN
	CALL fl_lee_cliente_general(rm_z21.z21_codcli)
		RETURNING r_z01.*
	LET rm_r19.r19_codcli = r_z01.z01_codcli
	LET rm_r19.r19_cedruc = r_z01.z01_num_doc_id
	LET rm_r19.r19_nomcli = r_z01.z01_nomcli
	LET rm_r19.r19_dircli = r_z01.z01_direccion1
	LET rm_r19.r19_telcli = r_z01.z01_telefono1
	START REPORT report_nota_cre2 TO PIPE comando
	OUTPUT TO REPORT report_nota_cre2()
	FINISH REPORT report_nota_cre2
	RETURN
END IF
DECLARE q_rept020 CURSOR FOR
	SELECT rept020.* FROM rept020
		WHERE r20_compania  = vg_codcia
		  AND r20_localidad = vg_codloc
		  AND r20_cod_tran  = rm_r19.r19_cod_tran
		  AND r20_num_tran  = rm_r19.r19_num_tran
START REPORT report_nota_cre TO PIPE comando
FOREACH q_rept020 INTO r_r20.*
	CALL fl_lee_item(vg_codcia, r_r20.r20_item)
		RETURNING r_r10.*
	CALL fl_lee_marca_rep(vg_codcia, r_r10.r10_marca)
		RETURNING r_r73.*
	CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
		RETURNING r_r72.*
	LET r_rep.r20_item	= r_r20.r20_item
	LET r_rep.desc_clase	= r_r72.r72_desc_clase
	LET r_rep.desc_marca	= r_r73.r73_desc_marca
	LET r_rep.descripcion	= r_r10.r10_nombre
	LET r_rep.cant_dev	= r_r20.r20_cant_ven
	LET r_rep.precio	= r_r20.r20_precio
	LET r_rep.descuento	= r_r20.r20_descuento
	LET r_rep.valor_tot	= (r_r20.r20_cant_ven *	r_r20.r20_precio) -
					r_r20.r20_val_descto
	OUTPUT TO REPORT report_nota_cre(r_rep.*)
END FOREACH
FINISH REPORT report_nota_cre

END FUNCTION



REPORT report_nota_cre(r_rep)
DEFINE r_rep		RECORD
				r20_item	LIKE rept020.r20_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_dev	LIKE rept020.r20_cant_dev,
				precio		LIKE rept020.r20_precio,
				descuento	LIKE rept020.r20_descuento,
				valor_tot	DECIMAL(14,2)
			END RECORD
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r38		RECORD LIKE rept038.*
DEFINE documento	VARCHAR(60)
DEFINE tipo_docum	VARCHAR(10)
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE factura		VARCHAR(15)
DEFINE num_nc		VARCHAR(10)
DEFINE label_letras	VARCHAR(100)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	3
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra (12 cpi)
	--LET db 	    	= "\033W1"      # Activar doble ancho.
	--LET db_c    	= "\033W0"      # Cancelar doble ancho.
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET tipo_docum  = "DEVOLUCION"
	IF rm_z21.z21_cod_tran = 'AF' THEN
		LET tipo_docum  = "ANULACION"
	END IF
	LET documento   = "COMPROBANTE " || tipo_docum || " FACTURA No. " ||
					rm_z21.z21_num_tran CLIPPED
	LET subtotal  = rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto
	LET impuesto  = rm_z21.z21_val_impto
	LET valor_pag = rm_z21.z21_valor
	CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
		RETURNING r_r01.*
	CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
		RETURNING r_r02.*
	SELECT * INTO r_r38.* FROM rept038
		WHERE r38_compania    = vg_codcia
		  AND r38_localidad   = vg_codloc
		  AND r38_tipo_fuente = 'PR'
		  AND r38_cod_tran    = rm_r19.r19_tipo_dev
		  AND r38_num_tran    = rm_r19.r19_num_dev
	LET factura   = rm_r19.r19_num_dev
	LET num_nc    = rm_z21.z21_num_doc
	SKIP 3 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 117, "No. ", num_nc
	PRINT COLUMN 27,  documento,
	      COLUMN 104, "FECHA EMI. N/C : ", rm_z21.z21_fecha_emi
			 			USING "dd-mm-yyyy"
	PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre
	SKIP 1 LINES
	PRINT COLUMN 06,  "CLIENTE (", rm_r19.r19_codcli USING "&&&&&", ") : ",
						rm_r19.r19_nomcli
	PRINT COLUMN 06,  "CEDULA/RUC      : ", rm_r19.r19_cedruc,
	      COLUMN 72,  "FACTURA SRI   : ", r_r38.r38_num_sri
	PRINT COLUMN 06,  "DIRECCION       : ", rm_r19.r19_dircli,
	      COLUMN 72,  "No. FACTURA   : ", rm_r19.r19_tipo_dev," ", factura
	PRINT COLUMN 06,  "TELEFONO        : ", rm_r19.r19_telcli,
	      COLUMN 72,  "FECHA FACTURA : ", DATE(rm_dev.r19_fecing) 
			 			USING "dd-mm-yyyy"
	PRINT COLUMN 06,  "OBSERVACION     : ", rm_r19.r19_referencia,
	      COLUMN 72,  "VENDEDOR(A)   : ", r_r01.r01_nombres
	SKIP 2 LINES
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 06,  "CODIGO",
	      COLUMN 15,  "DESCRIPCION",
	      COLUMN 67,  "MARCA",
	      COLUMN 84,  "CANTIDAD",
	      COLUMN 96,  "PRECIO VENTA",
	      COLUMN 110, "DSCTO",
	      COLUMN 121, "PRECIO TOTAL"
	SKIP 1 LINES

ON EVERY ROW
	--OJO
	NEED 2 LINES
	PRINT COLUMN 06,  r_rep.r20_item[1,7],
	      COLUMN 15,  r_rep.desc_clase,
	      COLUMN 67,  r_rep.desc_marca
	PRINT COLUMN 17,  r_rep.descripcion[1,65],
	      COLUMN 85,  r_rep.cant_dev	USING '###&.##',
	      COLUMN 94,  r_rep.precio		USING '###,###,##&.##',
	      COLUMN 110, r_rep.descuento	USING '##&.##',
	      COLUMN 118, r_rep.valor_tot	USING '###,###,##&.##'
	
PAGE TRAILER
	--NEED 4 LINES
	LET label_letras = fl_retorna_letras(rm_z21.z21_moneda, valor_pag)
	PRINT COLUMN 96,  "VALOR P.V.P.",
	      COLUMN 116, rm_r19.r19_tot_bruto	USING "#,###,###,##&.##"
	PRINT COLUMN 96,  "DESCUENTOS",
	      COLUMN 118, rm_r19.r19_tot_dscto	USING "###,###,##&.##"
	PRINT COLUMN 96,  "SUBTOTAL",
	      COLUMN 118, subtotal		USING "###,###,##&.##"
	PRINT COLUMN 96,  "I. V. A. (", rm_r19.r19_porc_impto USING "#&", ") %",
	      COLUMN 118, impuesto		USING "###,###,##&.##"
	PRINT COLUMN 06,  "SON: ", label_letras[1,90],
	      COLUMN 96,  "VALOR A PAGAR",
	      COLUMN 116, valor_pag		USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



REPORT report_nota_cre2()
dEFINE valor_pag	DECIMAL(14,2)
DEFINE num_nc		VARCHAR(10)
DEFINE label_letras	VARCHAR(100)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	3
	PAGE LENGTH	44
FORMAT

PAGE HEADER
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra (12 cpi)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	--LET db 	    	= "\033W1"      # Activar doble ancho.
	--LET db_c    	= "\033W0"      # Cancelar doble ancho.
	LET valor_pag = rm_z21.z21_valor
	LET num_nc    = rm_z21.z21_num_doc
	SKIP 3 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 117, "No. ", num_nc
	PRINT COLUMN 104, "FECHA EMI. N/C : ", rm_z21.z21_fecha_emi
			 			USING "dd/mm/yyyy"
	PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre
	SKIP 1 LINES
	PRINT COLUMN 06,  "CLIENTE       : ", rm_r19.r19_nomcli
	PRINT COLUMN 06,  "CEDULA/RUC    : ", rm_r19.r19_cedruc
	PRINT COLUMN 06,  "DIRECCION     : ", rm_r19.r19_dircli
	PRINT COLUMN 06,  "TELEFONO      : ", rm_r19.r19_telcli
	PRINT COLUMN 06,  "OBSERVACION   : ", rm_z21.z21_referencia

	SKIP 2 LINES
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 14,  "DESCRIPCION",
	      COLUMN 121, " VALOR TOTAL"
	SKIP 2 LINES

ON EVERY ROW
	--OJO
	NEED 2 LINES
	PRINT COLUMN 13,  "VALOR BRUTO DE N/C",
	      COLUMN 118, rm_z21.z21_valor - rm_z21.z21_val_impto
				USING '###,###,##&.##'
	PRINT COLUMN 13,  "VALOR IMPUESTO DE N/C",
	      COLUMN 118, rm_z21.z21_val_impto	USING '###,###,##&.##'
	
PAGE TRAILER
	--NEED 4 LINES
	LET label_letras = fl_retorna_letras(rm_z21.z21_moneda, valor_pag)
	SKIP 1 LINES
	PRINT COLUMN 06,  "SON: ", label_letras[1,90],
	      COLUMN 96,  "VALOR A PAGAR",
	      COLUMN 116, valor_pag		USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION imprimir_nc_taller()
DEFINE comando		CHAR(400)
DEFINE run_prog		VARCHAR(20)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, run_prog, 'talp409 ', vg_base,
	' "TA" ', vg_codcia, ' ', vg_codloc, ' ', rm_z21.z21_codcli,
	' "', rm_z21.z21_tipo_doc, '" ', rm_z21.z21_num_doc
RUN comando

END FUNCTION
