--------------------------------------------------------------------------------
-- Titulo           : cxpp405.4gl - IMPRESION DE RETENCIONES
-- Elaboracion      : 01-feb-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxpp405 BD MODULO COMPANIA LOCALIDAD RETENCION
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_ret	LIKE cxpt027.p27_num_ret 

DEFINE rm_p27		RECORD LIKE cxpt027.*
DEFINE rm_p01		RECORD LIKE cxpt001.*
DEFINE rm_cia		RECORD LIKE gent001.*

DEFINE vm_lin, vm_skip_lin	SMALLINT

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp405.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 
        'stop')
	EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_num_ret  = arg_val(5)
LET vg_proceso = 'cxpp405'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

INITIALIZE rm_p27.* TO NULL

LET vm_top    = 1
LET vm_left   =	9
LET vm_right  =	132
LET vm_bottom =	2
LET vm_page   = 64

CALL fl_lee_retencion_cxp(vg_codcia, vg_codloc, vm_num_ret) 
	RETURNING rm_p27.*
IF rm_p27.p27_num_ret IS NULL THEN	
	CALL FGL_WINMESSAGE(vg_producto,'Retencion no existe.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_proveedor(rm_p27.p27_codprov) RETURNING rm_p01.*
IF rm_p01.p01_codprov IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'Proveedor no existe.',
		'stop')
	EXIT PROGRAM
END IF

CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()

DEFINE comando		VARCHAR(100)
DEFINE r_p28_i		RECORD LIKE cxpt028.*
DEFINE r_p28_f		RECORD LIKE cxpt028.*

LET vm_skip_lin = 9

WHILE TRUE
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
	DECLARE q_p28_i CURSOR FOR 
		SELECT * FROM cxpt028
			WHERE p28_compania  = vg_codcia
			  AND p28_localidad = vg_codloc
			  AND p28_num_ret   = vm_num_ret
			  AND p28_tipo_ret  = 'F'
			ORDER BY p28_codprov, p28_tipo_doc, p28_num_doc, 
				 p28_dividendo

	DECLARE q_p28_f CURSOR FOR 
		SELECT * FROM cxpt028
			WHERE p28_compania  = vg_codcia
			  AND p28_localidad = vg_codloc
			  AND p28_num_ret   = vm_num_ret
			  AND p28_tipo_ret  = 'I'
			ORDER BY p28_codprov, p28_tipo_doc, p28_num_doc, 
				 p28_dividendo

	LET vm_lin = 1
	INITIALIZE r_p28_i.*, r_p28_f.* TO NULL 
	OPEN q_p28_i
	OPEN q_p28_f
	START REPORT report_factura TO PIPE comando
	WHILE TRUE     	
		FETCH q_p28_i INTO r_p28_i.*	
		FETCH q_p28_f INTO r_p28_f.*	
		IF r_p28_i.p28_num_ret IS NULL AND r_p28_f.p28_num_ret IS NULL THEN
			EXIT WHILE   
		END IF
		OUTPUT TO REPORT report_factura(r_p28_i.*, r_p28_f.*)
		INITIALIZE r_p28_i.*, r_p28_f.* TO NULL 
		LET vm_lin = vm_lin + 1
	END WHILE
	FINISH REPORT report_factura
END WHILE

END FUNCTION



REPORT report_factura(r_iva, r_fuente)
DEFINE r_iva  		RECORD LIKE cxpt028.*          
DEFINE r_fuente		RECORD LIKE cxpt028.*            
DEFINE tipo		CHAR(6)
DEFINE sum_valor_ret	LIKE cxpt028.p28_valor_ret

DEFINE serie		LIKE ordt013.c13_serie_comp
DEFINE str_000		LIKE ordt013.c13_factura
DEFINE factura		LIKE ordt013.c13_factura

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page

FORMAT
PAGE HEADER
--	print 'E';
--	print '&l26A';	-- Indica que voy a trabajar con hojas A4

	SKIP 7 LINES
--	print '&k4S' 		-- Letra condensada (12 cpi)

	SKIP 1 LINES
--	PRINT COLUMN 01, 'COMPROBANTE No. ', fl_justifica_titulo('I', rm_p27.p27_num_ret, 10)
	PRINT COLUMN 10, rm_p01.p01_nomprov,
	      COLUMN 100, DATE(rm_p27.p27_fecing) USING "dd-mm-yyyy" 
	SKIP 1 LINES
	PRINT COLUMN 10, rm_p01.p01_num_doc,
	      COLUMN 100, 'Factura'
	SKIP 1 LINES

-- Obtener la serie de la factura
	INITIALIZE serie, factura TO NULL
	SELECT c13_serie_comp, SUBSTR('0000000', 1, 7-LENGTH(c13_factura)), 
		   c13_factura
	  INTO serie, str_000, factura
	  FROM ordt013
     WHERE c13_compania  = rm_p27.p27_compania
	   AND c13_localidad = rm_p27.p27_localidad
	   AND c13_num_ret   = rm_p27.p27_num_ret  
	   AND c13_estado    = 'A'
	   
	PRINT COLUMN 10, rm_p01.p01_direccion1,
	      COLUMN 100, serie[1,3], '-', serie[4,6], '-', 
					  str_000 CLIPPED, factura CLIPPED

	LET sum_valor_ret = 0
	SKIP 3 LINES
--	print '&k2S' 		-- Letra condensada (16 cpi)

ON EVERY ROW
	IF r_iva.p28_num_ret IS NOT NULL THEN
		LET tipo = 'Fuente'
		IF r_fuente.p28_num_ret IS NULL THEN
	      		PRINT COLUMN 00, YEAR(rm_p27.p27_fecing),
			      COLUMN 19, r_iva.p28_valor_base 
					 	USING "###,###,##&.##",
			      COLUMN 50, tipo,
			      COLUMN 86, r_iva.p28_porcentaje USING "#&.##",
			      COLUMN 94, r_iva.p28_valor_ret  
						USING "###,###,##&.##"
				LET sum_valor_ret = sum_valor_ret + r_iva.p28_valor_ret
				LET vm_skip_lin = vm_skip_lin - 1
		ELSE
	      		PRINT COLUMN 00, YEAR(rm_p27.p27_fecing),
			      COLUMN 19, r_iva.p28_valor_base 
					 	USING "###,###,##&.##",
			      COLUMN 50, tipo,
			      COLUMN 86, r_iva.p28_porcentaje USING "#&.##",
			      COLUMN 94, r_iva.p28_valor_ret  
						USING "###,###,##&.##"
				LET sum_valor_ret = sum_valor_ret + r_iva.p28_valor_ret
				LET vm_skip_lin = vm_skip_lin - 1
		END IF
	END IF
	IF r_fuente.p28_num_ret IS NOT NULL THEN
		LET tipo = 'IVA'
	    PRINT COLUMN 00, YEAR(rm_p27.p27_fecing),
		      COLUMN 19, r_fuente.p28_valor_base USING "###,###,##&.##",
		      COLUMN 50, tipo,
		      COLUMN 86, r_fuente.p28_porcentaje USING "##&.##",
		      COLUMN 94, r_fuente.p28_valor_ret  USING "###,###,##&.##"
		LET sum_valor_ret = sum_valor_ret + r_fuente.p28_valor_ret
		LET vm_skip_lin = vm_skip_lin - 1

	END IF
	
ON LAST ROW
	SKIP vm_skip_lin LINES
	PRINT COLUMN 94, sum_valor_ret USING "###,###,##&.&&"

END REPORT



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_compania <> vg_codcia THEN
	CALL fgl_winmessage(vg_producto, 'Combinación compañía/localidad no ' ||
                            'existe ', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION

