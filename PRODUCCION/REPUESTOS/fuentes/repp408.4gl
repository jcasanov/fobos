------------------------------------------------------------------------------
-- Titulo           : repp4084gl - Reporte de liquidación de pedidos      
-- Elaboracion      : 14-abr-2003
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp408 base modulo compania localidad numliq
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_numliq	LIKE rept028.r28_numliq
DEFINE rm_r28		RECORD LIKE rept028.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_flag		SMALLINT
DEFINE una_sola_pag	CHAR(6)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp408.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN	-- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vm_numliq  = arg_val(5)
LET vg_proceso = 'repp408'
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
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE comando		CHAR(80)

CALL fl_nivel_isolation()
CALL fl_lee_liquidacion_rep(vg_codcia, vg_codloc, vm_numliq)
	RETURNING rm_r28.*
IF rm_r28.r28_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Liquidación no existe.','stop')
	EXIT PROGRAM                                                      
END IF
LET int_flag = 0
CALL fl_hacer_pregunta('Desea imprimir solo la primera pagina ?', 'No')
	RETURNING una_sola_pag
CALL fl_control_reportes() RETURNING comando 
IF int_flag THEN                             
	RETURN
END IF                                       
CALL fl_lee_compania(rm_r28.r28_compania) RETURNING rm_cia.*    
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
LET vm_flag = 1
START REPORT rep_liquidacion TO PIPE comando                     
--START REPORT rep_liquidacion TO FILE "liquidac.txt"
OUTPUT TO REPORT rep_liquidacion()
FINISH REPORT rep_liquidacion

END FUNCTION



REPORT rep_liquidacion()
DEFINE label_pedido		CHAR(80)
DEFINE pedido			LIKE rept029.r29_pedido
DEFINE r_p01			RECORD LIKE cxpt001.*
DEFINE r_r16			RECORD LIKE rept016.*
DEFINE r_r17			RECORD LIKE rept017.*
DEFINE r_r19			RECORD LIKE rept019.*
DEFINE r_g13			RECORD LIKE gent013.*
DEFINE r_r10			RECORD LIKE rept010.*
DEFINE r_r72			RECORD LIKE rept072.*
DEFINE descri			CHAR(40)
DEFINE valor			DECIMAL(12,2)
DEFINE tot_exfab_mb  		DECIMAL(22,10)
DEFINE tot_desp_mb    		DECIMAL(22,10)
DEFINE tot_fob_mb 		DECIMAL(22,10)
DEFINE tot_flete      		DECIMAL(22,10)
DEFINE tot_seguro     		DECIMAL(22,10)
DEFINE tot_cif        		DECIMAL(22,10)
DEFINE tot_arancel    		DECIMAL(22,10)
DEFINE tot_salvagu    		DECIMAL(22,10)
DEFINE tot_cargos     		DECIMAL(22,10)
DEFINE tot_costo		DECIMAL(22,10)
DEFINE saltos			SMALLINT
DEFINE escape			SMALLINT
DEFINE act_comp 		SMALLINT
DEFINE desact_comp		SMALLINT
DEFINE act_10cpi		SMALLINT
DEFINE act_12cpi		SMALLINT

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
	CALL fl_lee_proveedor(rm_r28.r28_codprov) RETURNING r_p01.*
	LET label_pedido = NULL
	DECLARE q_pedliq CURSOR FOR
		SELECT r29_pedido FROM rept029
			WHERE r29_compania  = rm_r28.r28_compania  AND 
			      r29_localidad = rm_r28.r28_localidad AND
			      r29_numliq    = rm_r28.r28_numliq
	FOREACH q_pedliq INTO pedido
		LET label_pedido = label_pedido CLIPPED, ' ', pedido
	END FOREACH
	CALL fl_lee_pedido_rep(rm_r28.r28_compania,rm_r28.r28_localidad, pedido)
		RETURNING r_r16.*			     
	--SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 005, rm_cia.g01_razonsocial, 
	      COLUMN 154, 'PAGINA: ', PAGENO USING '&&&'
	PRINT COLUMN 063, 'LIQUIDACION DE IMPORTACION No. ', 
			   rm_r28.r28_numliq USING '<<<<&'   
	SKIP 1 LINES
	PRINT COLUMN 001, 'IMPRESION: ', fl_current(),
	      COLUMN 154, UPSHIFT(vg_proceso) CLIPPED
	IF NOT vm_flag THEN
	PRINT COLUMN 061, 'DETALLE LIQUIDACION IMPORTACION POR ITEM'	      
	SKIP 1 LINES
	PRINT COLUMN 001, 'ITEM', 
	      COLUMN 008, 'CANTI.',
	      COLUMN 017, '  FOB EX-FAB', 
	      COLUMN 030, ' GTOS.ADIC.',
	      COLUMN 042, '   FOB UNIT.',
	      COLUMN 055, '      FLETE',
	      COLUMN 067, '     SEGURO', 
	      COLUMN 079, '       C I F', 
	      COLUMN 092, '    %',
	      COLUMN 098, '    ARANCEL',
	      COLUMN 110, '    %',
	      COLUMN 116, '  SALVAGUAR', 
	      COLUMN 128, ' GTOS. LOC.',
	      COLUMN 140, 'COSTO UNIT',
	      COLUMN 151, 'COST TOTAL'  
	PRINT '----------------------------------------------------------------------------------------------------------------------------------------------------------------'
	ELSE
		PRINT ' '
		SKIP 1 LINES
		PRINT ' '
		PRINT ' '
	END IF

ON EVERY ROW
	LET saltos = 30

-- UNA SOLA VEZ
	IF vm_flag THEN
	LET vm_flag = 0
	PRINT COLUMN 001, 'ESTADO        : ';
	CASE rm_r28.r28_estado 
		WHEN 'A'
			PRINT 'EN PROCESO'
		WHEN 'P'                  	
			LET saltos = saltos - 1
			PRINT 'PROCESADA';
			INITIALIZE r_r19.* TO NULL
			SELECT * INTO r_r19.*
				FROM rept019
				WHERE r19_compania  = rm_r28.r28_compania
				  AND r19_localidad = rm_r28.r28_localidad
				  AND r19_numliq    = rm_r28.r28_numliq
				  AND r19_cod_tran  = 'IM'
			PRINT 5 SPACES, 'COMPROBANTE INGRESO:', 
			      r_r19.r19_cod_tran, '-', 
			      r_r19.r19_num_tran USING '<<<<<&',
			      5 SPACES, 
			      'FECHA INGRESO INVENTARIO: ', r_r19.r19_fecing
		WHEN 'E'                  	
			PRINT 'ELIMINADA'
	END CASE
	PRINT COLUMN 001, 'FECHA         : ', DATE(rm_r28.r28_fecing) USING 'dd-mm-yyyy'		
	PRINT COLUMN 001, 'PEDIDO(S)     : ', label_pedido
        PRINT COLUMN 001, 'PROVEEDOR     : ', r_p01.p01_nomprov
        PRINT COLUMN 001, 'BODEGA INGRESO: ', rm_r28.r28_bodega
        CALL fl_lee_moneda(r_r16.r16_moneda) RETURNING r_g13.*
        PRINT COLUMN 001, 'MONEDA PEDIDO : ', r_g13.g13_nombre                         
        CALL fl_lee_moneda(rm_r28.r28_moneda) RETURNING r_g13.*
	PRINT COLUMN 001, 'MONEDA COSTEO : ', r_g13.g13_nombre                         
	SKIP 1 LINES
	PRINT COLUMN 001, 'DESCRIPCION', 
	      COLUMN 044, 'MONEDA PEDIDO',
	      COLUMN 064, 'MONEDA COSTEO'
	PRINT COLUMN 001, '-----------------------------------------------------------------------------'
	PRINT COLUMN 001, 'TOTAL EX-FABRICA',
	      COLUMN 045, rm_r28.r28_tot_exfab_mi USING '#,###,##&.##',  
	      COLUMN 065, rm_r28.r28_tot_exfab_mb USING '#,###,##&.##'  
	PRINT COLUMN 001, 'GASTOS ADICIONALES PROVEEDOR',
	      COLUMN 045, rm_r28.r28_tot_desp_mi  USING '#,###,##&.##',  
	      COLUMN 065, rm_r28.r28_tot_desp_mb  USING '#,###,##&.##'  
	PRINT COLUMN 045, '------------',
	      COLUMN 065, '------------'
	PRINT COLUMN 001, 'TOTAL FOB',
	      COLUMN 045, rm_r28.r28_tot_fob_mi   USING '#,###,##&.##',  
	      COLUMN 065, rm_r28.r28_tot_fob_mb   USING '#,###,##&.##'
	SKIP 1 LINES  
	PRINT COLUMN 001, 'FLETE REAL                  ',
	      COLUMN 065, rm_r28.r28_tot_flete    USING '#,###,##&.##'  
	PRINT COLUMN 001, 'FLETE CAE                   ',
	      COLUMN 065, rm_r28.r28_tot_flet_cae USING '#,###,##&.##'  
	PRINT COLUMN 001, 'SEGURO PRIMA NETA (sin tasas, sin iva)',
	      COLUMN 065, rm_r28.r28_tot_seguro   USING '#,###,##&.##'        
	PRINT COLUMN 001, 'SEGURO TOTAL (con tasas, sin iva)',
	      COLUMN 065, rm_r28.r28_tot_seg_neto USING '#,###,##&.##'  
	PRINT COLUMN 065, '------------'
	PRINT COLUMN 001, 'TOTAL CIF',
	      COLUMN 065, rm_r28.r28_tot_cif      USING '#,###,##&.##'  
	SKIP 1 LINES
	PRINT COLUMN 001, 'ARANCELES',
	      COLUMN 065, rm_r28.r28_tot_arancel  USING '#,###,##&.##'   
	PRINT COLUMN 001, 'SALVAGUARDIA',
	      COLUMN 065, rm_r28.r28_tot_salvagu  USING '#,###,##&.##'  
	DECLARE qu_cargos CURSOR FOR 
		SELECT g17_nombre, r30_valor * r30_paridad
			FROM rept030, gent017
			WHERE r30_compania  = rm_r28.r28_compania  AND 
			      r30_localidad = rm_r28.r28_localidad AND 
			      r30_numliq    = rm_r28.r28_numliq    AND 
			      r30_codrubro  = g17_codrubro
	FOREACH qu_cargos INTO descri, valor
		LET saltos = saltos - 1
		PRINT COLUMN 001, descri, 
		      COLUMN 065, valor USING '#,###,##&.##'  	
	END FOREACH
	PRINT COLUMN 065, '------------'
	PRINT COLUMN 001, 'TOYAL CARGOS LOCALES',                        
	      COLUMN 065, rm_r28.r28_tot_cargos   USING '#,###,##&.##'        
	SKIP 1 LINES
	PRINT COLUMN 001, 'TOTAL IVA : ',                        
	      COLUMN 065, rm_r28.r28_tot_iva      USING '#,###,##&.##'        
	SKIP 1 LINES      
	PRINT COLUMN 001, 'TOTAL COSTO DE IMPORTACION  ',  
	      COLUMN 065, rm_r28.r28_tot_costimp  USING '#,###,##&.##'        
	IF vg_gui = 0 THEN
		SKIP 30 LINES
	ELSE
		--#SKIP saltos LINES
	END IF
	END IF
-- FIN
	--#IF una_sola_pag = 'Yes' THEN
		--#RETURN
	--#END IF

	DECLARE qu_list CURSOR FOR                                      
		SELECT rept017.* FROM rept017, rept029                  
			WHERE r29_compania  = rm_r28.r28_compania  AND  
			      r29_localidad = rm_r28.r28_localidad AND  
			      r29_numliq    = rm_r28.r28_numliq    AND  
			      r29_compania  = r17_compania         AND  
			      r29_localidad = r17_localidad        AND  
			      r29_pedido    = r17_pedido           AND  
			      r17_cantrec > 0                           
			--ORDER BY r17_pedido, r17_orden                  
			ORDER BY r17_arancel, r17_orden
	LET tot_exfab_mb   = 0
	LET tot_desp_mb    = 0
	LET tot_fob_mb 	   = 0
	LET tot_flete      = 0
	LET tot_seguro     = 0
	LET tot_cif        = 0
	LET tot_arancel    = 0
	LET tot_salvagu    = 0
	LET tot_cargos     = 0
	LET tot_costo	   = 0
	FOREACH qu_list INTO r_r17.*
		LET tot_exfab_mb   = tot_exfab_mb + 
				     (r_r17.r17_exfab_mb * r_r17.r17_cantrec)
		LET tot_desp_mb    = tot_desp_mb  +
				     (r_r17.r17_desp_mb * r_r17.r17_cantrec)	
		LET tot_fob_mb 	   = tot_fob_mb   +
		                     (r_r17.r17_tot_fob_mb * r_r17.r17_cantrec)
		LET tot_flete      = tot_flete    +
				     (r_r17.r17_exfab_mb * r_r17.r17_cantrec)
		LET tot_seguro     = tot_seguro   +
		                     (r_r17.r17_seguro * r_r17.r17_cantrec)
		LET tot_cif        = tot_cif      +
		                     (r_r17.r17_cif * r_r17.r17_cantrec)
		LET tot_arancel    = tot_arancel  +
		                     (r_r17.r17_arancel * r_r17.r17_cantrec)
		LET tot_salvagu    = tot_salvagu  +
				     (r_r17.r17_salvagu * r_r17.r17_cantrec)
		LET tot_cargos     = tot_cargos   +
				     (r_r17.r17_cargos * r_r17.r17_cantrec)
		LET tot_costo	   = tot_costo    + 
				     (r_r17.r17_costuni_ing * r_r17.r17_cantrec) 
		CALL fl_lee_item(rm_r28.r28_compania, r_r17.r17_item)
			RETURNING r_r10.*
		CALL fl_lee_clase_rep(r_r17.r17_compania, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo, 
			r_r10.r10_cod_clase)
			RETURNING r_r72.*
		NEED 3 LINES
		PRINT COLUMN 01, r_r72.r72_desc_clase CLIPPED, '- ',
		                 r_r10.r10_nombre
		PRINT COLUMN 001, r_r17.r17_item[1,6],
	      	      COLUMN 008, r_r17.r17_cantrec    USING '####&.##',
	              COLUMN 017, r_r17.r17_exfab_mb   USING '###,##&.####',
	              COLUMN 030, r_r17.r17_desp_mb    USING '##,##&.####',
	              COLUMN 042, r_r17.r17_tot_fob_mb USING '###,##&.####',
	              COLUMN 055, r_r17.r17_flete      USING '##,##&.####', 
	              COLUMN 067, r_r17.r17_seguro     USING '##,##&.####', 
	              COLUMN 079, r_r17.r17_cif        USING '###,##&.####',
	              COLUMN 092, r_r17.r17_porc_part  USING '#&.##',
	              COLUMN 098, r_r17.r17_arancel    USING '##,##&.####', 
	              COLUMN 110, r_r17.r17_porc_salva USING '#&.##',
	              COLUMN 116, r_r17.r17_salvagu    USING '##,##&.####', 
	              COLUMN 128, r_r17.r17_cargos     USING '##,##&.####', 
	              COLUMN 140, r_r17.r17_costuni_ing USING '###,##&.##',
	              COLUMN 151, r_r17.r17_costuni_ing * r_r17.r17_cantrec
	              		  USING '###,##&.##'
		SKIP 1 LINES
	END FOREACH

ON LAST ROW
	--#IF una_sola_pag = 'Yes' THEN
		--#RETURN
	--#END IF
	NEED 2 LINES
	PRINT COLUMN 001, 'TOTALES --> ', 
	      COLUMN 017, tot_exfab_mb   USING '###,##&.####', 
	      COLUMN 030, tot_desp_mb    USING '##,##&.####',  
	      COLUMN 042, tot_fob_mb USING '###,##&.####', 
	      COLUMN 055, tot_flete      USING '##,##&.####',  
	      COLUMN 067, tot_seguro     USING '##,##&.####',  
	      COLUMN 079, tot_cif        USING '###,##&.####', 
	      COLUMN 098, tot_arancel    USING '##,##&.####',  
	      COLUMN 116, tot_salvagu    USING '##,##&.####',  
	      COLUMN 128, tot_cargos     USING '##,##&.####',  
	      COLUMN 151, tot_costo      USING '###,##&.##';

	      --- DESACTIVAR COMPRIMIDO
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi
	      
END REPORT
