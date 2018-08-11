------------------------------------------------------------------------------
-- Titulo           : repp433 - Reporte de Nota de pedido
-- Elaboracion      : 23-Abr-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp433 base modulo compania localidad nota_ped
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_notaped	LIKE rept081.r81_pedido
DEFINE rm_r81		RECORD LIKE rept081.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE vm_tot_part	DECIMAL(22,10)
DEFINE vm_tot_cant	DECIMAL(22,10)
DEFINE vm_tot_pesgen	DECIMAL(22,10)
DEFINE vm_tot_fobgen	DECIMAL(22,10)
DEFINE vm_tot_part_g	DECIMAL(22,10)
DEFINE vm_tot_cant_g	DECIMAL(22,10)
DEFINE vm_tot_pesgen_g	DECIMAL(22,10)
DEFINE vm_tot_fobgen_g	DECIMAL(22,10)
DEFINE vm_flag		SMALLINT
DEFINE vm_imprimir	CHAR(1)
DEFINE vm_num_copia	SMALLINT
DEFINE vm_cabecera	SMALLINT
DEFINE cont		SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp433.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)		
LET vm_notaped = arg_val(5)
LET vg_proceso = 'repp433'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE comando		VARCHAR(100)

CALL fl_nivel_isolation()
CALL fl_lee_nota_pedido_rep(vg_codcia, vg_codloc, vm_notaped) RETURNING rm_r81.*
IF rm_r81.r81_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Nota de Pedido no existe.','stop')
	EXIT PROGRAM                                                      
END IF                                                                    
CALL fl_lee_compania(rm_r81.r81_compania) RETURNING rm_cia.*    
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(rm_r81.r81_compania, rm_r81.r81_localidad)
	RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
LET vm_imprimir  = 'B'
LET vm_num_copia = 1
WHILE TRUE
	CALL leer_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando 
	IF int_flag THEN                             
		CONTINUE WHILE
	END IF                                       
	CALL control_reporte(comando)
END WHILE

END FUNCTION



FUNCTION leer_parametros()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 14
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf433_1 FROM '../forms/repf433_1'
ELSE
	OPEN FORM f_repf433_1 FROM '../forms/repf433_1c'
END IF
DISPLAY FORM f_repf433_1
LET int_flag = 0
INPUT BY NAME rm_r81.r81_pedido, vm_imprimir, vm_num_copia
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
END INPUT

END FUNCTION



FUNCTION control_reporte(comando)
DEFINE comando		VARCHAR(100)
DEFINE cuantas_copias	SMALLINT
DEFINE r_r82		RECORD LIKE rept082.*
DEFINE cod_desc_item	LIKE rept083.r83_cod_desc_item

DECLARE q_r82 CURSOR FOR
	SELECT rept082.*, r83_cod_desc_item FROM rept082, OUTER rept083
		WHERE r82_compania  = rm_r81.r81_compania
		  AND r82_localidad = rm_r81.r81_localidad
		  AND r82_pedido    = rm_r81.r81_pedido
		  AND r82_compania  = r83_compania
		  AND r82_item      = r83_item
		ORDER BY r82_sec_partida, r83_cod_desc_item, r82_sec_item
LET cont = 0
FOR cuantas_copias = 1 TO vm_num_copia
	LET vm_flag         = 1
	LET vm_tot_part_g   = 0
	LET vm_tot_cant_g   = 0
	LET vm_tot_pesgen_g = 0
	LET vm_tot_fobgen_g = 0
	CASE vm_imprimir
		WHEN 'I'
			START REPORT rep_nota_pedido TO PIPE comando
			--START REPORT rep_nota_pedido TO FILE "notaped.txt"
			FOREACH q_r82 INTO r_r82.*, cod_desc_item
				OUTPUT TO REPORT rep_nota_pedido(r_r82.*,
								cod_desc_item)
			END FOREACH
			FINISH REPORT rep_nota_pedido
		WHEN 'B'
			START REPORT rep_nota_pedido2 TO PIPE comando
			--START REPORT rep_nota_pedido2 TO FILE "notaped2.txt"
			FOREACH q_r82 INTO r_r82.*, cod_desc_item
				OUTPUT TO REPORT rep_nota_pedido2(r_r82.*,
								cod_desc_item)
			END FOREACH
			FINISH REPORT rep_nota_pedido2
	END CASE
END FOR

END FUNCTION



REPORT rep_nota_pedido(r_r82, cod_desc_item)
DEFINE cod_desc_item		LIKE rept083.r83_cod_desc_item
DEFINE r_r82			RECORD LIKE rept082.*
DEFINE r_r84			RECORD LIKE rept084.*
DEFINE r_g13			RECORD LIKE gent013.*
DEFINE r_g13p			RECORD LIKE gent013.*
DEFINE r_g13b			RECORD LIKE gent013.*
DEFINE r_g16, r1_g16, r2_g16, r3_g16, r4_g16	RECORD LIKE gent016.*
DEFINE r_g30			RECORD LIKE gent030.*
DEFINE r_g31			RECORD LIKE gent031.*
DEFINE r_r16			RECORD LIKE rept016.*
DEFINE r_nivel			RECORD LIKE gent016.*
DEFINE r_r05			RECORD LIKE rept005.*
DEFINE r_r10			RECORD LIKE rept010.*
DEFINE total_peso		DECIMAL(13,4)
DEFINE total_fob_mp		DECIMAL(14,4)
DEFINE telefono			VARCHAR(50)
DEFINE fax			VARCHAR(50)
DEFINE col, c1, c2		SMALLINT
DEFINE escape			SMALLINT
DEFINE act_neg, des_neg		SMALLINT
DEFINE act_comp, act_dob1	SMALLINT
DEFINE desact_comp, des_dob	SMALLINT
DEFINE act_dob2			SMALLINT
DEFINE act_10cpi		SMALLINT
DEFINE act_12cpi		SMALLINT
DEFINE partida			VARCHAR(21)
DEFINE fob_uni_mb		DECIMAL(14,4)
DEFINE total_fob_uni_mb		DECIMAL(14,4)
DEFINE lineas			SMALLINT
DEFINE desc_cap			CHAR(120)
DEFINE desc_cap6		CHAR(120)
DEFINE desc_cap8		CHAR(120)
DEFINE desc_cap10		CHAR(120)

OUTPUT                       
	TOP MARGIN	1    
	LEFT MARGIN	2    
	RIGHT MARGIN	160  
	BOTTOM MARGIN	2
	PAGE LENGTH	66

FORMAT                       

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	CALL fl_lee_pedido_rep(rm_r81.r81_compania, rm_r81.r81_localidad,
				rm_r81.r81_pedido)
		RETURNING r_r16.*
	LET telefono = "TELEFONO: ", rm_loc.g02_telefono1
	IF rm_loc.g02_telefono2 IS NOT NULL THEN
		LET telefono = "TELEFONOS: ", rm_loc.g02_telefono1, " / ",
					rm_loc.g02_telefono2
	END IF
	LET fax = "FAX: ", rm_loc.g02_fax1
	IF rm_loc.g02_fax2 IS NOT NULL THEN
		LET fax = "FAXES: ", rm_loc.g02_fax1, " / ", rm_loc.g02_fax2
	END IF
        CALL fl_lee_moneda(rm_r81.r81_moneda_base) RETURNING r_g13.*
        CALL fl_lee_moneda(r_r16.r16_moneda) RETURNING r_g13p.*
        CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13b.*
	CALL fl_lee_ciudad(rm_loc.g02_ciudad) RETURNING r_g31.*
	CALL fl_lee_pais(r_g31.g31_pais) RETURNING r_g30.*
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 003, rm_cia.g01_razonsocial; 
	PRINT COLUMN 059, ASCII escape, ASCII desact_comp, ASCII escape,
		ASCII act_10cpi, ASCII escape, ASCII act_dob1, ASCII act_dob2,
		"PEDIDO No. ", rm_r81.r81_pedido CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_comp, ASCII escape, ASCII act_12cpi;
	PRINT COLUMN 145, "PAGINA No. ", PAGENO USING "&&&"
	SKIP 1 LINES
	IF vm_flag THEN		-- OJO NPC
		PRINT COLUMN 001, rm_loc.g02_direccion,
		      COLUMN 067, "TO BE DELIVERED BY AND SUBJECT TO THE ACCEPTANCE OF:"
		IF rm_loc.g02_correo IS NOT NULL THEN
			PRINT COLUMN 001, rm_loc.g02_correo,
			      COLUMN 067, "A SER DESPACHADO EN CASO DE ACCEPTACION DEL PEDIDO POR:"
		ELSE
			PRINT COLUMN 067, "A SER DESPACHADO EN CASO DE ACCEPTACION DEL PEDIDO POR:"
		END IF
		PRINT COLUMN 001, telefono
		PRINT COLUMN 001, fax
		{--
		      COLUMN 067, "REMITENTE Y/O",
		      COLUMN 093, rm_r81.r81_nom_prov[01,60] CLIPPED
		PRINT COLUMN 001, r_g31.g31_nombre, " - ", r_g30.g30_nombre,
		      COLUMN 067, "  EMBARCADOR:",
		      COLUMN 093, rm_r81.r81_dir_prov[01,60]
		PRINT COLUMN 093, rm_r81.r81_dir_prov[61,120]
		PRINT COLUMN 093, rm_r81.r81_ciu_prov
		--}
		PRINT COLUMN 001, "FECHA: ", r_g31.g31_nombre, ", ",
				rm_r81.r81_fecha
		PRINT COLUMN 001, "--------------------------------------------------------------------------------------------------------------------------------------------------------------"
		PRINT COLUMN 001, "DETAIL OF CUSTOM DECLARATION "
		SKIP 1 LINES
		PRINT COLUMN 001, "DETALLE DE DECLARCION ADUANERA:"
		SKIP 1 LINES
	END IF
	LET vm_cabecera = 1

BEFORE GROUP OF r_r82.r82_partida
	IF vm_flag THEN		-- UNA SOLA VEZ
		LET vm_flag = 0
		PRINT --COLUMN 001, fax,
		      COLUMN 067, "REMITENTE Y/O",
		      COLUMN 093, rm_r81.r81_nom_prov[01,60] CLIPPED
		PRINT --COLUMN 001, r_g31.g31_nombre, " - ", r_g30.g30_nombre,
		      COLUMN 067, "  EMBARCADOR:",
		      COLUMN 093, rm_r81.r81_dir_prov[01,60]
		PRINT COLUMN 093, rm_r81.r81_dir_prov[61,120]
		PRINT COLUMN 093, rm_r81.r81_ciu_prov
		PRINT --COLUMN 001, "FECHA: ", r_g31.g31_nombre, ", ",
			--			rm_r81.r81_fecha,
		      COLUMN 093, rm_r81.r81_est_prov
		PRINT COLUMN 093, rm_r81.r81_pai_prov
		PRINT COLUMN 067, "    TELEFONO:",
		      COLUMN 093, rm_r81.r81_tel_prov
		PRINT COLUMN 001, "          MARKS  ",
		      COLUMN 067, "         FAX:",
		      COLUMN 093, rm_r81.r81_fax_prov
		PRINT COLUMN 001, "         MARCAS: ", rm_r81.r81_marcas,
		      COLUMN 067, "      E-MAIL:",
		      COLUMN 093, rm_r81.r81_email_prov
		SKIP 1 LINES
		PRINT COLUMN 001, "       SHIPMENT  ",
		      COLUMN 067, "COLLECTIONS THROUGH  "
		PRINT COLUMN 001, "   DESPACHO VIA: ", rm_r81.r81_tipo_trans,
		      COLUMN 067, "       COBRANZA VIA: ",
		      COLUMN 093, rm_r81.r81_pagador
		SKIP 1 LINES
		PRINT COLUMN 001, "        PACKING  ",
		      COLUMN 067, "      PAYMENT TERMS  "
		PRINT COLUMN 001, "       EMBALAJE: ", rm_r81.r81_tipo_embal,
		      COLUMN 067, "      FORMA DE PAGO: ",
		      COLUMN 093, rm_r81.r81_forma_pago
		SKIP 1 LINES
		PRINT COLUMN 001, "      INSURANCE  ",
		      COLUMN 067, "  COUNTRY OF ORIGIN  "
		PRINT COLUMN 001, "         SEGURO: ", rm_r81.r81_tipo_seguro,
		      COLUMN 067, "     PAIS DE ORIGEN: ",
		      COLUMN 093, rm_r81.r81_pais_origen
		SKIP 1 LINES
		PRINT COLUMN 001, "TYPE OF PRICING  ",
		      COLUMN 067, "      SHIPPING PORT  "
		PRINT COLUMN 001, "TIPO DE PRECIOS: ", rm_r81.r81_tipo_fact_pre,
		      COLUMN 067, "    PUERTO EMBARQUE: ",
		      COLUMN 093, rm_r81.r81_puerto_ori
		SKIP 1 LINES
		PRINT COLUMN 001, "          MONEY  ",
		      COLUMN 030, " EXCHANGE RATE  ",
		      COLUMN 067, "       DESTINY PORT  "
		PRINT COLUMN 001, "         DIVISA: ", rm_r81.r81_moneda_base,
						" ", r_g13.g13_nombre[1,8],
		      COLUMN 030, "TIPO CAMBIO: ", rm_r81.r81_paridad_div
			USING "###,##&.###############",
		      COLUMN 067, "     PUERTO DESTINO: ",
		      COLUMN 093, rm_r81.r81_puerto_dest
		PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
		SKIP 1 LINES
		PRINT COLUMN 001, "  TOTAL INVOICE EX-WORKS  ",
		      COLUMN 067, "   TOTAL INVOICE FOB DIV  "
		PRINT COLUMN 001, "TOTAL FACTURA EX-FABRICA: ",
		      COLUMN 027, rm_r81.r81_moneda_base, " ", r_g13.g13_nombre,
		      COLUMN 046, r_g13.g13_simbolo, " ",
		      COLUMN 051, rm_r81.r81_tot_exfab USING "--,---,--&.####",
		      COLUMN 067, "   TOTAL FACTURA FOB DIV: ",
		      COLUMN 093, r_r16.r16_moneda, " ", r_g13p.g13_nombre,
		      COLUMN 113, r_g13p.g13_simbolo, " ",
		      COLUMN 118, rm_r81.r81_tot_fob_mi USING "--,---,--&.####"
		SKIP 1 LINES
		PRINT COLUMN 001, "       HANDLING EXPENSES  ",
		      COLUMN 067, "       TOTAL INVOICE FOB  "
		PRINT COLUMN 001, "      GASTOS DE EMBARQUE: ",
		      COLUMN 027, r_r16.r16_moneda, " ", r_g13p.g13_nombre,
		      COLUMN 046, r_g13p.g13_simbolo, " ",
		      COLUMN 051,rm_r81.r81_tot_desp_mi USING "--,---,--&.####",
		      COLUMN 067, "       TOTAL FACTURA FOB: ",
		      COLUMN 093, rg_gen.g00_moneda_base," ", r_g13b.g13_nombre,
		      COLUMN 113, r_g13b.g13_simbolo, " ",
		      COLUMN 118, rm_r81.r81_tot_fob_mb USING "--,---,--&.####"
		SKIP 1 LINES
		PRINT COLUMN 001, "       SHIPPING EXPENSES  ",
		      COLUMN 067, "         TOTAL VALUE C&F  "
		PRINT COLUMN 001, "         TOTAL DEL FLETE: ",
		      --COLUMN 027, rm_r81.r81_moneda_base," ",r_g13.g13_nombre,
		      COLUMN 027, rg_gen.g00_moneda_base," ", r_g13b.g13_nombre,
		      COLUMN 046, r_g13b.g13_simbolo, " ",
		      COLUMN 051, rm_r81.r81_tot_flete USING "--,---,--&.####",
		      COLUMN 067, "         TOTAL VALOR C&F: ",
		      --COLUMN 093, rm_r81.r81_moneda_base," ",r_g13.g13_nombre,
		      COLUMN 093, rg_gen.g00_moneda_base," ", r_g13b.g13_nombre,
		      COLUMN 113, r_g13b.g13_simbolo, " ",
		      COLUMN 118, rm_r81.r81_tot_car_fle USING "--,---,--&.####"
		SKIP 1 LINES
		PRINT COLUMN 001, "   INSURANCE (NET VALUE)  ",
		      COLUMN 067, "         TOTAL VALUE CIF  "
		PRINT COLUMN 001, "SEGURO (VALOR DE PRIMAS): ",
		      --COLUMN 027, rm_r81.r81_moneda_base," ",r_g13.g13_nombre,
		      COLUMN 027, rg_gen.g00_moneda_base," ", r_g13b.g13_nombre,
		      COLUMN 046, r_g13b.g13_simbolo, " ",
		      COLUMN 051, rm_r81.r81_tot_seguro USING "--,---,--&.####",
		      COLUMN 067, "         TOTAL VALOR CIF: ",
		      --COLUMN 093, rm_r81.r81_moneda_base," ",r_g13.g13_nombre,
		      COLUMN 093, rg_gen.g00_moneda_base," ", r_g13b.g13_nombre,
		      COLUMN 113, r_g13b.g13_simbolo, " ",
		      COLUMN 118, rm_r81.r81_tot_cargos_mb
					USING "--,---,--&.####"
		SKIP 1 LINES
		PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
		LET lineas = 66 - LINENO
		SKIP lineas LINES
	ELSE
		{--
		IF cod_desc_item IS NOT NULL THEN
			NEED 15 LINES
		ELSE
			NEED 12 LINES
		END IF
		--}
		NEED 21 LINES
	END IF		-- FIN
	LET vm_tot_part   = 0
	LET vm_tot_cant   = 0
	LET vm_tot_pesgen = 0
	LET vm_tot_fobgen = 0
	CALL fl_lee_partida(r_r82.r82_partida) RETURNING r_g16.*
--	NOTA DE PEDIDO (INTERNA)
--	OJO SE LE AGREGA LA PARTIDA NACIONAL Y DIGITO VERIFICADOR (RCA)
	IF r_g16.g16_partida[12,13] IS NULL OR r_g16.g16_partida[12,13] = '00'
		THEN
        	LET partida  = 	r_g16.g16_partida[1,10] CLIPPED,  '.', 
				r_g16.g16_nacional CLIPPED, '-',
				r_g16.g16_verifcador
	ELSE
        	LET partida  = 	r_g16.g16_partida CLIPPED,  
				'-', r_g16.g16_verifcador 
	END IF

	IF r_g16.g16_partida IS NOT NULL THEN
		CALL retorna_desc_nivel_part(r_g16.g16_partida)
			RETURNING r_nivel.*
  	END IF
	LET col = 21  - LENGTH(partida)
	LET c1  = 127 + col - 1
	LET c2  = c1  + 1
--	SELECT g38_desc_cap INTO desc_cap FROM gent038
--		WHERE g38_capitulo = r_g16.g16_capitulo

	CALL fl_lee_partida(r_g16.g16_partida[1,4])  RETURNING r1_g16.*
	CALL fl_lee_partida(r_g16.g16_partida[1,7])  RETURNING r2_g16.*
	CALL fl_lee_partida(r_g16.g16_partida[1,10]) RETURNING r3_g16.*
	CALL fl_lee_partida(r_g16.g16_partida[1,13]) RETURNING r4_g16.*

	LET desc_cap   = r1_g16.g16_desc_par CLIPPED
	LET desc_cap6  = r2_g16.g16_desc_par CLIPPED
	LET desc_cap8  = r3_g16.g16_desc_par CLIPPED
	LET desc_cap10 = r4_g16.g16_desc_par CLIPPED
 
-- ROD
--	IF partida[6,10] IS NULL  OR partida[6,10] <> '00.00' THEN
	PRINT COLUMN 027, desc_cap CLIPPED, ' ....'
	PRINT COLUMN 027, desc_cap6 CLIPPED
	IF partida[9,13] <> '00.00' THEN
--		IF r3_g16.g16_niv_par = 8 THEN
		IF desc_cap8 <> desc_cap10 THEN
			PRINT COLUMN 027, desc_cap8 CLIPPED
		ELSE
			PRINT COLUMN 027, ' '
		END IF
	END IF

	IF desc_cap10 IS NOT NULL THEN
		PRINT COLUMN 001, "PARTIDA: ", partida," ",
						r_g16.g16_desc_par[001,c1]
	ELSE
		PRINT COLUMN 001, ' '
	END IF
--	PRINT COLUMN 027,  			    r_g16.g16_desc_par[c2,225]
	SKIP 1 LINES
	PRINT COLUMN 099, "|       PRECIOS DIVISA        |",
	      COLUMN 129, "|        PRECIOS BASE       |"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 008, "COD. ITEM PROV.",
	      COLUMN 024, "DESCRIPCION ITEM PROVEEDOR",
	      COLUMN 084, "UNI",
	      COLUMN 088, "   CANTIDAD",
	      COLUMN 100, "        FOB",
	      COLUMN 115, "     FOB TOTAL",
	      COLUMN 130, "        FOB",
	      COLUMN 145, "     FOB TOTAL"
	PRINT COLUMN 001, "--------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 103, r_g13p.g13_simbolo CLIPPED,
	      COLUMN 120, r_g13p.g13_simbolo CLIPPED,
	      COLUMN 133, r_g13b.g13_simbolo CLIPPED,
	      COLUMN 150, r_g13b.g13_simbolo CLIPPED

BEFORE GROUP OF cod_desc_item
	CALL fl_lee_desc_subtitulo(vg_codcia, cod_desc_item) RETURNING r_r84.*
	NEED 1 LINES
--	IF NOT vm_cabecera OR PAGENO > 1 THEN
-- 		SKIP 1 LINES
--	END IF
	PRINT COLUMN 001, ASCII escape, ASCII act_neg,
			r_r84.r84_descripcion, ASCII escape, ASCII des_neg 
	LET vm_cabecera = 0

ON EVERY ROW
	NEED 10 LINES
	LET total_peso      = r_r82.r82_cantidad * r_r82.r82_peso_item
	LET total_fob_mp    = r_r82.r82_cantidad * r_r82.r82_prec_exfab
	LET vm_tot_part     = vm_tot_part        + 1
	LET vm_tot_cant     = vm_tot_cant        + r_r82.r82_cantidad
	LET vm_tot_pesgen   = vm_tot_pesgen      + total_peso
	LET vm_tot_fobgen   = vm_tot_fobgen      + total_fob_mp
	--LET fob_uni_mb      = r_r82.r82_prec_exfab / rm_r81.r81_paridad_div
	LET fob_uni_mb      = r_r82.r82_prec_exfab * rm_r81.r81_paridad_div
	LET total_fob_uni_mb= r_r82.r82_cantidad * 
			      (r_r82.r82_prec_exfab * rm_r81.r81_paridad_div)
			      --(r_r82.r82_prec_exfab / rm_r81.r81_paridad_div)
	CALL fl_lee_unidad_medida(r_r82.r82_cod_unid) RETURNING r_r05.*
	CALL fl_lee_item(vg_codcia, r_r82.r82_item) RETURNING r_r10.*
	PRINT COLUMN 001, r_r82.r82_item[1, 6],
	      COLUMN 008, r_r82.r82_cod_item_prov,
	      COLUMN 024, r_r82.r82_descripcion[1, 58],
	      COLUMN 084, UPSHIFT(r_r05.r05_siglas),
	      COLUMN 088, r_r82.r82_cantidad		USING "-----&.####",
	      COLUMN 100, r_r82.r82_prec_exfab		USING "---,---,--&.##",
	      COLUMN 115, total_fob_mp			USING "---,---,--&.##",
	      COLUMN 130, fob_uni_mb                    USING "---,---,--&.##",
	      COLUMN 145, total_fob_uni_mb              USING "---,---,--&.##" 

AFTER GROUP OF r_r82.r82_partida
	NEED 4 LINES
	LET vm_tot_part_g   = vm_tot_part_g   + vm_tot_part
	LET vm_tot_cant_g   = vm_tot_cant_g   + vm_tot_cant
	LET vm_tot_pesgen_g = vm_tot_pesgen_g + vm_tot_pesgen
	LET vm_tot_fobgen_g = vm_tot_fobgen_g + vm_tot_fobgen
	PRINT COLUMN 088, "-----------",
	      COLUMN 115, "--------------",
	      COLUMN 145, "--------------"
	PRINT COLUMN 030, "TOTALES DE LA PARTIDA: ",
	      COLUMN 052, vm_tot_part		USING "---,--&.##",
	      COLUMN 072, "TOTAL CANTIDAD: ",
	      COLUMN 088, vm_tot_cant		USING "-----&.####",
	      COLUMN 104, "TOTAL FOB: ",
	      COLUMN 115, vm_tot_fobgen		USING "---,---,--&.##",
	      COLUMN 134, "TOTAL FOB: ",
	      --COLUMN 145, vm_tot_fobgen / rm_r81.r81_paridad_div 
	      COLUMN 145, vm_tot_fobgen * rm_r81.r81_paridad_div 
						USING "---,---,--&.##"
	PRINT COLUMN 072, "TOTAL PESO    : ",
	      COLUMN 088, vm_tot_pesgen		USING "---,---,--&.##" 
	SKIP 1 LINES

ON LAST ROW
	NEED 6 LINES
	SKIP 1 LINES
	PRINT COLUMN 028, "TOTAL GENERAL PARTIDA: ",
	      COLUMN 052, vm_tot_part_g		USING "---,--&.##",
	      COLUMN 064, "TOTAL GENERAL CANTIDAD: ",
	      COLUMN 088, vm_tot_cant_g		USING "-----&.####"
	PRINT COLUMN 064, "TOTAL GENERAL PESO    : ",
	      COLUMN 088, vm_tot_pesgen_g	USING "---,---,--&.##" 
	SKIP 1 LINES
	PRINT COLUMN 058, "TOTAL GENERAL FOB ",
				UPSHIFT(r_g13.g13_nombre[1,10]),
	      COLUMN 086, ": ",
	      COLUMN 088, vm_tot_fobgen_g	USING "---,---,--&.##"
	PRINT COLUMN 058, "TOTAL GENERAL FOB ",
				UPSHIFT(r_g13b.g13_nombre[1,10]),
	      COLUMN 086, ": ",
	      --COLUMN 088, vm_tot_fobgen_g / rm_r81.r81_paridad_div
	      COLUMN 088, vm_tot_fobgen_g * rm_r81.r81_paridad_div
						USING "---,---,--&.##";
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

PAGE TRAILER
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 072, "-------------------------"
	PRINT COLUMN 068, "      EL IMPORTADOR      ";
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi
	      
END REPORT



REPORT rep_nota_pedido2(r_r82, cod_desc_item)
DEFINE cod_desc_item		LIKE rept083.r83_cod_desc_item
DEFINE r_r82			RECORD LIKE rept082.*
DEFINE r_r84			RECORD LIKE rept084.*
DEFINE r_g13			RECORD LIKE gent013.*
DEFINE r_g13p			RECORD LIKE gent013.*
DEFINE r_g13b			RECORD LIKE gent013.*
DEFINE r_g30			RECORD LIKE gent030.*
DEFINE r_g31			RECORD LIKE gent031.*
DEFINE r_r16			RECORD LIKE rept016.*
DEFINE r_g16, r1_g16, r2_g16, r3_g16, r4_g16	RECORD LIKE gent016.*
DEFINE r_nivel			RECORD LIKE gent016.*
DEFINE r_r05			RECORD LIKE rept005.*
DEFINE r_r10			RECORD LIKE rept010.*
DEFINE total_peso		DECIMAL(13,4)
DEFINE total_fob_mp		DECIMAL(14,4)
DEFINE telefono			VARCHAR(50)
DEFINE fax			VARCHAR(50)
DEFINE col, c1, c2		SMALLINT
DEFINE escape			SMALLINT
DEFINE act_neg, des_neg		SMALLINT
DEFINE act_comp, act_dob1	SMALLINT
DEFINE desact_comp, des_dob	SMALLINT
DEFINE act_dob2			SMALLINT
DEFINE act_10cpi		SMALLINT
DEFINE act_12cpi		SMALLINT
DEFINE partida			VARCHAR(21)
DEFINE fob_uni_mb		DECIMAL(14,4)
DEFINE total_fob_uni_mb		DECIMAL(14,4)
DEFINE lineas			SMALLINT
DEFINE desc_cap			CHAR(120)
DEFINE desc_cap6		CHAR(120)
DEFINE desc_cap8		CHAR(120)
DEFINE desc_cap10		CHAR(120)
DEFINE fechaimpre		DATETIME YEAR TO SECOND

OUTPUT                       
	TOP MARGIN	1    
	LEFT MARGIN	0    
	RIGHT MARGIN	160  
	BOTTOM MARGIN	2
	PAGE LENGTH	66   

FORMAT                       

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET fechaimpre  = fl_current()
	CALL fl_lee_pedido_rep(rm_r81.r81_compania, rm_r81.r81_localidad,
				rm_r81.r81_pedido)
		RETURNING r_r16.*
	LET telefono = "TELEFONO: ", rm_loc.g02_telefono1
	IF rm_loc.g02_telefono2 IS NOT NULL THEN
		LET telefono = "TELEFONOS: ", rm_loc.g02_telefono1, " / ",
					rm_loc.g02_telefono2
	END IF
	LET fax = "FAX: ", rm_loc.g02_fax1
	IF rm_loc.g02_fax2 IS NOT NULL THEN
		LET fax = "FAXES: ", rm_loc.g02_fax1, " / ", rm_loc.g02_fax2
	END IF
        CALL fl_lee_moneda(rm_r81.r81_moneda_base) RETURNING r_g13.*
        CALL fl_lee_moneda(r_r16.r16_moneda) RETURNING r_g13p.*
        CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13b.*
	CALL fl_lee_ciudad(rm_loc.g02_ciudad) RETURNING r_g31.*
	CALL fl_lee_pais(r_g31.g31_pais) RETURNING r_g30.*
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 003, rm_cia.g01_razonsocial; 
	PRINT COLUMN 059, ASCII escape, ASCII desact_comp, ASCII escape,
		ASCII act_10cpi, ASCII escape, ASCII act_dob1, ASCII act_dob2,
		"PEDIDO No. ", rm_r81.r81_pedido CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_comp, ASCII escape, ASCII act_12cpi;
	PRINT COLUMN 145, "PAGINA No. ", PAGENO USING "&&&"
	SKIP 1 LINES
	IF vm_flag THEN		-- OJO NPC
		PRINT COLUMN 001, rm_loc.g02_direccion
		IF rm_loc.g02_correo IS NOT NULL THEN
			PRINT COLUMN 001, rm_loc.g02_correo
		ELSE
			PRINT 1 SPACES
		END IF
		PRINT COLUMN 001, telefono
		PRINT COLUMN 001, fax
		PRINT COLUMN 001, r_g31.g31_nombre, " - ", r_g30.g30_nombre
		PRINT COLUMN 001, "FECHA: ", r_g31.g31_nombre, ", ",
				rm_r81.r81_fecha --,
--		      COLUMN 067, "Fecha Impresion: ", fechaimpre
		PRINT COLUMN 001, "--------------------------------------------------------------------------------------------------------------------------------------------------------------"
		PRINT COLUMN 001, "DETAIL OF CUSTOM DECLARATION ",
		      COLUMN 067, "TO BE DELIVERED BY AND SUBJECT TO THE ACCEPTANCE OF:"
		PRINT COLUMN 067, "A SER DESPACHADO EN CASO DE ACCEPTACION DEL PEDIDO POR:"
		PRINT COLUMN 001, "DETALLE DE DECLARCION ADUANERA:"
		SKIP 1 LINES
	END IF
	LET vm_cabecera = 1

BEFORE GROUP OF r_r82.r82_partida
	IF vm_flag THEN		-- UNA SOLA VEZ
		LET vm_flag = 0
		PRINT COLUMN 067, "REMITENTE Y/O",
		      COLUMN 093, rm_r81.r81_nom_prov[01,60] CLIPPED
		PRINT COLUMN 067, "  EMBARCADOR:",
		      COLUMN 093, rm_r81.r81_dir_prov[01,60]
		PRINT COLUMN 093, rm_r81.r81_dir_prov[61,120]
		PRINT COLUMN 093, rm_r81.r81_ciu_prov
		PRINT COLUMN 093, rm_r81.r81_est_prov
		PRINT COLUMN 001, "DUI No. _________",
		      COLUMN 093, rm_r81.r81_pai_prov
		PRINT COLUMN 067, "    TELEFONO:",
		      COLUMN 093, rm_r81.r81_tel_prov
		PRINT COLUMN 001, "          MARKS  ",
		      COLUMN 067, "         FAX:",
		      COLUMN 093, rm_r81.r81_fax_prov
		PRINT COLUMN 001, "         MARCAS: ", rm_r81.r81_marcas,
		      COLUMN 067, "      E-MAIL:",
		      COLUMN 093, rm_r81.r81_email_prov
		SKIP 1 LINES
		PRINT COLUMN 001, "       SHIPMENT  ",
		      COLUMN 067, "COLLECTIONS THROUGH  "
		PRINT COLUMN 001, "   DESPACHO VIA: ", rm_r81.r81_tipo_trans,
		      COLUMN 067, "       COBRANZA VIA: ",
		      COLUMN 093, rm_r81.r81_pagador
		SKIP 1 LINES
		PRINT COLUMN 001, "        PACKING  ",
		      COLUMN 067, "      PAYMENT TERMS  "
		PRINT COLUMN 001, "       EMBALAJE: ", rm_r81.r81_tipo_embal,
		      COLUMN 067, "      FORMA DE PAGO: ",
		      COLUMN 093, rm_r81.r81_forma_pago
		SKIP 1 LINES
		PRINT COLUMN 001, "      INSURANCE  ",
		      COLUMN 067, "  COUNTRY OF ORIGIN  "
		PRINT COLUMN 001, "         SEGURO: ", rm_r81.r81_tipo_seguro,
		      COLUMN 067, "     PAIS DE ORIGEN: ",
		      COLUMN 093, rm_r81.r81_pais_origen
		SKIP 1 LINES
		PRINT COLUMN 001, "TYPE OF PRICING  ",
		      COLUMN 067, "      SHIPPING PORT  "
		PRINT COLUMN 001, "TIPO DE PRECIOS: ", rm_r81.r81_tipo_fact_pre,
		      COLUMN 067, "    PUERTO EMBARQUE: ",
		      COLUMN 093, rm_r81.r81_puerto_ori
		SKIP 1 LINES
		PRINT COLUMN 001, "          MONEY  ",
		      COLUMN 030, " EXCHANGE RATE  ",
		      COLUMN 067, "       DESTINY PORT  "
		PRINT COLUMN 001, "         DIVISA: ", rm_r81.r81_moneda_base,
						" ", r_g13.g13_nombre[1,8],
		      COLUMN 030, "TIPO CAMBIO: ", rm_r81.r81_paridad_div
						USING "###,##&.###############",
		      COLUMN 067, "     PUERTO DESTINO: ",
		      COLUMN 093, rm_r81.r81_puerto_dest
		PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
		SKIP 1 LINES
		PRINT COLUMN 001, "  TOTAL INVOICE EX-WORKS  ",
		      COLUMN 067, "   TOTAL INVOICE FOB DIV  "
		PRINT COLUMN 001, "TOTAL FACTURA EX-FABRICA: ",
		      COLUMN 027, rm_r81.r81_moneda_base, " ",
				r_g13.g13_nombre[1, 14],
		      COLUMN 045, r_g13.g13_simbolo, " ",
		      COLUMN 050, rm_r81.r81_tot_exfab USING "---,---,--&.####",
		      COLUMN 067, "   TOTAL FACTURA FOB DIV: ",
		      COLUMN 093, r_r16.r16_moneda, " ",
				r_g13p.g13_nombre[1, 13],
		      COLUMN 110, r_g13p.g13_simbolo, " ",
		      COLUMN 115, rm_r81.r81_tot_fob_mi
						USING "-,---,---,--&.####"
		SKIP 1 LINES
		PRINT COLUMN 001, "       HANDLING EXPENSES  ",
		      COLUMN 067, "       TOTAL INVOICE FOB  "
		PRINT COLUMN 001, "      GASTOS DE EMBARQUE: ",
		      COLUMN 027, r_r16.r16_moneda, " ",
				r_g13p.g13_nombre[1, 14],
		      COLUMN 045, r_g13p.g13_simbolo, " ",
		      COLUMN 050, rm_r81.r81_tot_desp_mi
						USING "---,---,--&.####",
		      COLUMN 067, "       TOTAL FACTURA FOB: ",
		      COLUMN 093, r_r16.r16_moneda, " ",
				r_g13p.g13_nombre[1, 13],
		      COLUMN 110, r_g13p.g13_simbolo, " ",
		      COLUMN 115, rm_r81.r81_tot_fob_mi
						USING "-,---,---,--&.####"
		SKIP 1 LINES
		PRINT COLUMN 001, "       SHIPPING EXPENSES  ",
		      COLUMN 067, "         TOTAL VALUE C&F  "
		PRINT COLUMN 001, "         TOTAL DEL FLETE: ",
		      COLUMN 027, r_r16.r16_moneda, " ",
				r_g13p.g13_nombre[1, 14],
		      COLUMN 045, r_g13p.g13_simbolo, " ",
		      --COLUMN 050, rm_r81.r81_tot_flete * rm_r81.r81_paridad_div
		      COLUMN 050, rm_r81.r81_tot_flete / rm_r81.r81_paridad_div
				USING "---,---,--&.####",
		      COLUMN 067, "         TOTAL VALOR C&F: ",
		      COLUMN 093, r_r16.r16_moneda, " ",
				r_g13p.g13_nombre[1, 13],
		      COLUMN 110, r_g13p.g13_simbolo, " ",
		     --COLUMN 115, rm_r81.r81_tot_car_fle * rm_r81.r81_paridad_div
		     COLUMN 115, rm_r81.r81_tot_car_fle / rm_r81.r81_paridad_div
				USING "-,---,---,--&.####"
		SKIP 1 LINES
		PRINT COLUMN 001, "   INSURANCE (NET VALUE)  ",
		      COLUMN 067, "         TOTAL VALUE CIF  "
		PRINT COLUMN 001, "SEGURO (VALOR DE PRIMAS): ",
		      COLUMN 027, r_r16.r16_moneda, " ",
				r_g13p.g13_nombre[1, 14],
		      COLUMN 045, r_g13p.g13_simbolo, " ",
		      --COLUMN 050, rm_r81.r81_tot_seguro * rm_r81.r81_paridad_div
		      COLUMN 050, rm_r81.r81_tot_seguro / rm_r81.r81_paridad_div
				USING "---,---,--&.####",
		      COLUMN 067, "         TOTAL VALOR CIF: ",
		      COLUMN 093, r_r16.r16_moneda, " ",
				r_g13p.g13_nombre[1, 13],
		      COLUMN 110, r_g13p.g13_simbolo, " ",
		   --COLUMN 115, rm_r81.r81_tot_cargos_mb * rm_r81.r81_paridad_div
		   COLUMN 115, rm_r81.r81_tot_cargos_mb / rm_r81.r81_paridad_div
				USING "-,---,---,--&.####"
		SKIP 1 LINES
		PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
		LET lineas = 66 - LINENO
		SKIP lineas LINES
	ELSE
		{--
		IF cod_desc_item IS NOT NULL THEN
			NEED 14 LINES
		ELSE
			NEED 11 LINES
		END IF
		--}
		--NEED 21 LINES
		NEED 20 LINES
	END IF		-- FIN
	LET vm_tot_part   = 0
	LET vm_tot_cant   = 0
	LET vm_tot_pesgen = 0
	LET vm_tot_fobgen = 0
	CALL fl_lee_partida(r_r82.r82_partida) RETURNING r_g16.*
--	NOTA DE PEDIDO (BANCO)
--	OJO SE LE AGREGA LA PARTIDA NACIONAL Y DIGITO VERIFICADOR (RCA)
        IF r_g16.g16_partida[12,13] IS NULL OR r_g16.g16_partida[12,13] = '00'
	THEN
                LET partida  =  r_g16.g16_partida[1,10] CLIPPED,  '.',
                                r_g16.g16_nacional CLIPPED, '-',
                                r_g16.g16_verifcador
        ELSE
                LET partida  =  r_g16.g16_partida CLIPPED,
                                '-', r_g16.g16_verifcador
        END IF

	IF r_g16.g16_partida IS NOT NULL THEN
		CALL retorna_desc_nivel_part(r_g16.g16_partida)
			RETURNING r_nivel.*
  	END IF
	LET col = 21  - LENGTH(partida)
	LET c1  = 127 + col - 1
	LET c2  = c1  + 1
--	SELECT g38_desc_cap INTO desc_cap FROM gent038
--		WHERE g38_capitulo = r_g16.g16_capitulo

	CALL fl_lee_partida(r_g16.g16_partida[1,4])  RETURNING r1_g16.*
	CALL fl_lee_partida(r_g16.g16_partida[1,7])  RETURNING r2_g16.*
	CALL fl_lee_partida(r_g16.g16_partida[1,10]) RETURNING r3_g16.*
	CALL fl_lee_partida(r_g16.g16_partida[1,13]) RETURNING r4_g16.*

	LET desc_cap   = r1_g16.g16_desc_par CLIPPED
	LET desc_cap6  = r2_g16.g16_desc_par CLIPPED
	LET desc_cap8  = r3_g16.g16_desc_par CLIPPED
	LET desc_cap10 = r4_g16.g16_desc_par CLIPPED
 
--      IF partida[6,10] IS NULL  OR partida[6,10] <> '00.00' THEN
        PRINT COLUMN 027, desc_cap CLIPPED, ' ....'
        PRINT COLUMN 027, desc_cap6 CLIPPED
        IF partida[9,13] <> '00.00' THEN
--              IF r3_g16.g16_niv_par = 8 THEN
                IF desc_cap8 <> desc_cap10 THEN
			PRINT COLUMN 027, desc_cap8 CLIPPED
		ELSE
			PRINT COLUMN 027, ' '
                END IF
        END IF
	IF desc_cap10 IS NOT NULL THEN
		PRINT COLUMN 001, "PARTIDA: ", partida," ",
					r_g16.g16_desc_par[001,c1]
	ELSE
		PRINT COLUMN 001, ' '
	END IF
--	PRINT COLUMN 027, 			    r_g16.g16_desc_par[c2,225]
	SKIP 1 LINES
	PRINT COLUMN 123, "|          PRECIOS DIVISA            |"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 008, "COD. ITEM PROV.",
	      COLUMN 024, "DESCRIPCION ITEM PROVEEDOR",
	      COLUMN 084, "UNI",
	      COLUMN 100, "      CANTIDAD",
	      COLUMN 123, "               FOB",
	      COLUMN 143, "         FOB TOTAL"
	PRINT COLUMN 001, "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 130, r_g13p.g13_simbolo CLIPPED,
	      COLUMN 150, r_g13p.g13_simbolo CLIPPED

BEFORE GROUP OF cod_desc_item
	CALL fl_lee_desc_subtitulo(vg_codcia, cod_desc_item) RETURNING r_r84.*
	NEED 11 LINES
--	IF NOT vm_cabecera OR PAGENO > 2 THEN
--		SKIP 1 LINES
--	END IF
	PRINT COLUMN 001, ASCII escape, ASCII act_neg,
			r_r84.r84_descripcion, ASCII escape, ASCII des_neg
	LET vm_cabecera = 0

ON EVERY ROW
	LET cont = cont + 1
	--NEED 10 LINES
	--
	IF cont > 9 THEN
		NEED 10 LINES	-- OJO ARREGLAR PROXIMA IMPORTACION (10 o 12)
				-- HUBO UN CASO ESPECIAL QUE FUNCIONÓ CON 14
				-- ES EL DE LA IMPORTACIÓN A-6202 - REVISAR
				-- PARA UNIFICAR Y CORREGIR DEFINITIVAMENTE
				-- ESTE ERROR EN EL REPORTE
	ELSE
		NEED 13 LINES	-- OJO NUEVO
		--NEED 10 LINES -- HUBO EL CASO DE LA IMPORTACION A-6634
				-- QUE FUNCIONO cont = 9 y NEED 10 LINES
	END IF
	--
	LET total_peso      = r_r82.r82_cantidad * r_r82.r82_peso_item
	LET total_fob_mp    = r_r82.r82_cantidad * r_r82.r82_prec_exfab
	LET vm_tot_part     = vm_tot_part        + 1
	LET vm_tot_cant     = vm_tot_cant        + r_r82.r82_cantidad
	LET vm_tot_pesgen   = vm_tot_pesgen      + total_peso
	LET vm_tot_fobgen   = vm_tot_fobgen      + total_fob_mp
	CALL fl_lee_unidad_medida(r_r82.r82_cod_unid) RETURNING r_r05.*
	CALL fl_lee_item(vg_codcia, r_r82.r82_item) RETURNING r_r10.*
	PRINT COLUMN 001, r_r82.r82_item[1, 6],
	      COLUMN 008, r_r82.r82_cod_item_prov,
	      COLUMN 024, r_r82.r82_descripcion[1, 58],
	      COLUMN 084, UPSHIFT(r_r05.r05_siglas),
	      COLUMN 100, r_r82.r82_cantidad	USING "-,---,--&.####",
	      COLUMN 123, r_r82.r82_prec_exfab
                        USING "---,---,---,--&.##",
	      COLUMN 143, total_fob_mp		USING "---,---,---,--&.##"

AFTER GROUP OF r_r82.r82_partida
	NEED 9 LINES
	LET vm_tot_part_g   = vm_tot_part_g   + vm_tot_part
	LET vm_tot_cant_g   = vm_tot_cant_g   + vm_tot_cant
	LET vm_tot_pesgen_g = vm_tot_pesgen_g + vm_tot_pesgen
	LET vm_tot_fobgen_g = vm_tot_fobgen_g + vm_tot_fobgen
	PRINT COLUMN 100, "--------------",
	      COLUMN 143, "------------------"
	PRINT COLUMN 030, "TOTALES DE LA PARTIDA: ",
	      COLUMN 052, vm_tot_part		USING "---,--&.##",
	      COLUMN 084, "TOTAL CANTIDAD: ",
	      COLUMN 100, vm_tot_cant		USING "-,---,--&.####",
	      COLUMN 132, "TOTAL FOB: ",
	      COLUMN 143, vm_tot_fobgen		USING "---,---,---,--&.##"
	PRINT COLUMN 084, "TOTAL PESO    : ",
	      COLUMN 100, vm_tot_pesgen		USING "---,---,--&.##" 
	SKIP 1 LINES

ON LAST ROW
	NEED 5 LINES
	SKIP 1 LINES
	PRINT COLUMN 028, "TOTAL GENERAL PARTIDA: ",
	      COLUMN 052, vm_tot_part_g		USING "---,--&.##",
	      COLUMN 076, "TOTAL GENERAL CANTIDAD: ",
	      COLUMN 104, vm_tot_cant_g		USING "-,---,--&.####"
	PRINT COLUMN 076, "TOTAL GENERAL PESO    : ",
	      COLUMN 100, vm_tot_pesgen_g	USING "---,---,---,--&.##" 
	SKIP 1 LINES
	PRINT COLUMN 070, "TOTAL GENERAL FOB ",
				UPSHIFT(r_g13.g13_nombre[1,10]),
	      COLUMN 098, ": ",
	      COLUMN 100, vm_tot_fobgen_g	USING "---,---,---,--&.##";
	{--
	PRINT COLUMN 070, "TOTAL GENERAL FOB ",
				UPSHIFT(r_g13b.g13_nombre[1,10]),
	      COLUMN 098, ": ",
	      COLUMN 100, vm_tot_fobgen_g * rm_r81.r81_paridad_div
                    USING "---,---,---,--&.##";
	--}
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi
	      
PAGE TRAILER
{
	print ASCII escape;
	print ASCII 13
	print ASCII escape;
	print ASCII 13
}
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 072, "-------------------------"
	PRINT COLUMN 068, "      EL IMPORTADOR      ";
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION retorna_desc_nivel_part(partida)
DEFINE partida		LIKE gent016.g16_partida
DEFINE part		LIKE gent016.g16_partida
DEFINE r		RECORD LIKE gent016.*
DEFINE i, j, k, l, ini	INTEGER
                                                                                
INITIALIZE part TO NULL
SELECT MIN(g16_niv_par) INTO ini FROM gent016
	WHERE g16_niv_par        <> 0
--	  AND LENGTH(g16_niv_par) = 1
LET j = 1
FOR i = 1 TO LENGTH(partida)
	IF partida[i, i] <> '.' THEN
		LET part[j, j] = partida[i, i]
		LET j = j + 1
	END IF
END FOR
LET l = LENGTH(partida) - 1
{--
FOR i = l TO 1 STEP -1
	LET l = l - 1
	IF partida[i, i] = '.' THEN
		EXIT FOR
	END IF
END FOR
--}
LET i = LENGTH(part) - 1
LET j = j - 1
WHILE (i >= ini)
	WHILE (j >= ini)
		INITIALIZE r.* TO NULL
		SELECT * INTO r.* FROM gent016
			WHERE g16_partida = SUBSTR(partida,1,l)
	  		  AND g16_niv_par = j
		LET j = j - 1	
		IF r.g16_partida IS NOT NULL THEN
			EXIT WHILE
		END IF
	END WHILE
	IF r.g16_partida IS NOT NULL THEN
		EXIT WHILE
	END IF
	FOR k = l TO 1 STEP -1
		LET l = l - 1
		IF (i MOD 2) <> 0 THEN
			EXIT FOR
		END IF
 		IF partida[k, k] = '.' THEN
			EXIT FOR
		END IF
	END FOR
	LET j = i
	LET i = i - 1
END WHILE
IF (i < ini) AND r.g16_partida IS NULL THEN
	SELECT * INTO r.* FROM gent016
		WHERE g16_partida = SUBSTR(partida,1,ini)
  		  AND g16_niv_par = ini
END IF
RETURN r.*

END FUNCTION
