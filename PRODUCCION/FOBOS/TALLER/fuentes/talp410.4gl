--------------------------------------------------------------------------------
-- Titulo           : talp410.4gl - REPORTE DE PROFORMA DE TALLER
-- Elaboracion      : 06-Mar-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp410 base modulo compañia localidad proforma
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_proforma	LIKE rept021.r21_numprof
DEFINE rm_r21		RECORD LIKE rept021.*
DEFINE rm_r22		RECORD LIKE rept022.*
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_z01	  	RECORD LIKE cxct001.*
DEFINE vm_num_item	INTEGER
DEFINE vm_num_lineas	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp410.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_proforma = arg_val(5)
LET vg_proceso  = 'talp410'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
EXIT PROGRAM

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
INITIALIZE rm_r21.*, rm_z01.*, rm_r01.* TO NULL
CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, vm_proforma) RETURNING rm_r21.*
IF rm_r21.r21_numprof IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe Proforma.','stop')
	EXIT PROGRAM
END IF
SELECT COUNT(*)
	INTO vm_num_item
	FROM rept022
	WHERE r22_compania  = vg_codcia
	  AND r22_localidad = vg_codloc
	  AND r22_numprof   = rm_r21.r21_numprof
CALL fl_lee_vendedor_rep(vg_codcia, rm_r21.r21_vendedor) RETURNING rm_r01.*
CALL fl_lee_cliente_general(rm_r21.r21_codcli) RETURNING rm_z01.*
CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE r_rep		RECORD
				r22_item	LIKE rept022.r22_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				unidades	LIKE rept010.r10_uni_med,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cantidad	LIKE rept022.r22_cantidad,
				precio		LIKE rept022.r22_precio,
				porc_descto	LIKE rept022.r22_porc_descto,
				valor_tot	DECIMAL(14,2)
			END RECORD
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_r22		RECORD LIKE rept022.*
DEFINE comando		CHAR(100)

LET int_flag = 0
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
DECLARE q_rept022 CURSOR FOR 
	SELECT * FROM rept022
		WHERE r22_compania  = vg_codcia
		  AND r22_localidad = vg_codloc
		  AND r22_numprof   = vm_proforma
		ORDER BY r22_orden
START REPORT report_proforma TO PIPE comando
LET vm_num_lineas = 0
FOREACH q_rept022 INTO r_r22.*
	CALL fl_lee_item(vg_codcia, r_r22.r22_item) RETURNING r_r10.*
	CALL fl_lee_marca_rep(vg_codcia, r_r10.r10_marca)
		RETURNING r_r73.*
	CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
		RETURNING r_r72.*
	LET r_rep.r22_item	= r_r22.r22_item
	LET r_rep.desc_clase	= r_r72.r72_desc_clase
	LET r_rep.unidades	= UPSHIFT(r_r10.r10_uni_med)
	LET r_rep.desc_marca	= r_r73.r73_desc_marca
	LET r_rep.descripcion	= r_r10.r10_nombre
	LET r_rep.cantidad	= r_r22.r22_cantidad
	LET r_rep.precio	= r_r22.r22_precio
	LET r_rep.porc_descto	= r_r22.r22_porc_descto
	LET r_rep.valor_tot	= (r_r22.r22_cantidad * r_r22.r22_precio) -
					r_r22.r22_val_descto
	OUTPUT TO REPORT report_proforma(r_rep.*)
END FOREACH
FINISH REPORT report_proforma
FREE q_rept022

END FUNCTION



REPORT report_proforma(r_rep)
DEFINE r_rep		RECORD
				r22_item	LIKE rept022.r22_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				unidades	LIKE rept010.r10_uni_med,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cantidad	LIKE rept022.r22_cantidad,
				precio		LIKE rept022.r22_precio,
				porc_descto	LIKE rept022.r22_porc_descto,
				valor_tot	DECIMAL(14,2)
			END RECORD
DEFINE mensaje		VARCHAR(80)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE long		SMALLINT
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE presupuesto	VARCHAR(10)
DEFINE orden_trab	VARCHAR(10)
DEFINE proforma		VARCHAR(10)
DEFINE label_letras	VARCHAR(130)
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
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET subtotal  = rm_r21.r21_tot_bruto - rm_r21.r21_tot_dscto
	LET impuesto  = rm_r21.r21_tot_neto - rm_r21.r21_tot_bruto +
			rm_r21.r21_tot_dscto - rm_r21.r21_flete
	LET valor_pag = rm_r21.r21_tot_neto
	CALL fl_justifica_titulo('I', vg_usuario, 10) RETURNING usuario
--	print '&k2S' 		-- Letra condensada
	LET presupuesto = rm_r21.r21_num_presup
	LET orden_trab  = rm_r21.r21_num_ot
	LET proforma    = rm_r21.r21_numprof
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 109, "PAG. ", PAGENO USING "&&&"
	PRINT COLUMN 01,  "No. PRESUPUESTO : ", presupuesto,
	      COLUMN 69,  "No. PROFORMA   : ", proforma
	PRINT COLUMN 01,  "ORDEN DE TRABAJO: ", orden_trab,
	      COLUMN 69,  "FECHA PROFORMA : ", DATE(rm_r21.r21_fecing) 
			 			USING "dd-mm-yyyy"
	PRINT COLUMN 01,  "CLIENTE (", rm_r21.r21_codcli USING "&&&&&", ") : ",
					rm_r21.r21_nomcli[1, 49] CLIPPED,
	      COLUMN 69,  "ALMACEN        : ", rm_loc.g02_nombre
	PRINT COLUMN 01,  "CEDULA/RUC      : ", rm_r21.r21_cedruc,
	      COLUMN 69,  "RUC            : ", rm_loc.g02_numruc
	PRINT COLUMN 01,  "DIRECCION       : ", rm_r21.r21_dircli,
	      COLUMN 69,  "DIRECCION      : ", rm_loc.g02_direccion
	PRINT COLUMN 01,  "TELEFONO        : ", rm_r21.r21_telcli,
	      COLUMN 69,  "TELEFONO       : ", rm_loc.g02_telefono1, " ",
						rm_loc.g02_telefono2
	PRINT COLUMN 01,  "FAX             : ", rm_z01.z01_fax1, " ",
						rm_z01.z01_fax2,
	      COLUMN 69,  "FAX            : ", rm_loc.g02_fax1, " ",
						rm_loc.g02_fax2
	PRINT COLUMN 01,  "FECHA IMPRESION : ", DATE(TODAY) USING 'dd-mm-yyyy',
		1 SPACES, TIME,
	      COLUMN 69,  "VENDEDOR(A)    : ", rm_r01.r01_nombres
	SKIP 1 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 02,  "CODIGO",
	      COLUMN 11,  "DESCRIPCION",
	      COLUMN 56,  "MEDIDA",
	      COLUMN 64,  "MARCA",
	      COLUMN 84,  "CANTIDAD",
	      COLUMN 96,  "PRECIO VENTA",
	      COLUMN 110, "%DSCTO",
	      COLUMN 121, "VALOR TOTAL"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 02,  r_rep.r22_item[1,7],
	      COLUMN 11,  r_rep.desc_clase,
	      COLUMN 56,  r_rep.unidades,
	      COLUMN 64,  r_rep.desc_marca
	PRINT COLUMN 13,  r_rep.descripcion,
	      COLUMN 85,  r_rep.cantidad	USING '###&.##',
	      COLUMN 94,  r_rep.precio		USING '###,###,##&.##',
	      COLUMN 110, r_rep.porc_descto	USING '##&.##',
	      COLUMN 118, r_rep.valor_tot	USING '###,###,##&.##'
	LET vm_num_lineas = vm_num_lineas + 1
	
PAGE TRAILER
	LET label_letras = fl_retorna_letras(rm_r21.r21_moneda, valor_pag)
	SKIP 2 LINES
	IF vm_num_lineas = vm_num_item THEN
		PRINT COLUMN 02,  "SOMOS CONTRIBUYENTES ESPECIALES D.G.R. #39",
		      COLUMN 95,  "TOTAL BRUTO",
		      COLUMN 116, rm_r21.r21_tot_bruto	USING "#,###,###,##&.##"
		PRINT COLUMN 02,  "PRECIOS SUJETOS A CAMBIO SIN PREVIO AVISO",
		      COLUMN 95,  "DESCUENTOS",
		      COLUMN 118, rm_r21.r21_tot_dscto	USING "###,###,##&.##"
		PRINT COLUMN 95,  "SUBTOTAL",
		      COLUMN 118, subtotal		USING "###,###,##&.##"
		PRINT COLUMN 95,  "I. V. A. (", rm_r21.r21_porc_impto
							USING "#&", ") %",
		      COLUMN 118, impuesto		USING "###,###,##&.##"
		PRINT COLUMN 95,  "TRANSPORTE",
	      	      COLUMN 118, rm_r21.r21_flete	USING "###,###,##&.##"
		PRINT COLUMN 02,  "SON: ", label_letras[1,87],
		      COLUMN 95,  "VALOR A PAGAR",
		      COLUMN 116, valor_pag	USING "#,###,###,##&.##";
	ELSE
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES;
	END IF
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
