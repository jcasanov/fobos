--------------------------------------------------------------------------------
-- Titulo           : talp403.4gl - REPORTE DE FACTURA 
-- Elaboracion      : 01-feb-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun talp403 BD MODULO COMPANIA LOCALIDAD FACTURA
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_factura	LIKE talt023.t23_num_factura      
DEFINE vm_num_lineas	SMALLINT

DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t03		RECORD LIKE talt003.*
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_z01		RECORD LIKE cxct001.*
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
CALL startlog('../logs/talp403.error')
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
LET vm_factura  = arg_val(5)
LET vg_proceso = 'talp403'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE num_lineas		SMALLINT

CALL fl_nivel_isolation()

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	132
LET vm_bottom =	2
LET vm_page   = 64

INITIALIZE rm_t23.* TO NULL
SELECT * INTO rm_t23.* FROM talt023
	WHERE t23_compania    = vg_codcia
          AND t23_localidad   = vg_codloc
	  AND t23_num_factura = vm_factura

IF rm_t23.t23_orden IS NULL THEN	
	CALL FGL_WINMESSAGE(vg_producto, 'No existe orden.', 'stop')
	EXIT PROGRAM
END IF
IF rm_t23.t23_num_factura IS NULL THEN	
	CALL FGL_WINMESSAGE(vg_producto, 'Orden no ha sido facturada.', 'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_cliente_general(rm_t23.t23_cod_cliente) RETURNING rm_z01.*

CALL fl_lee_mecanico(vg_codcia, rm_t23.t23_cod_asesor) RETURNING rm_t03.*
IF rm_t23.t23_cod_asesor IS NULL THEN	
	CALL FGL_WINMESSAGE(vg_producto, 'No existe codigo de asesor.', 'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_configuracion_taller(vg_codcia)  
        RETURNING rm_t00.*                

SELECT COUNT(*) INTO vm_num_lineas FROM talt024 
	WHERE t24_compania  = vg_codcia
	  AND t24_localidad = vg_codloc
	  AND t24_orden     = rm_t23.t23_orden   

CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE i 		SMALLINT
DEFINE comando		VARCHAR(100)
DEFINE r_t24		RECORD LIKE talt024.*
DEFINE nom_tarea	LIKE talt007.t07_nombre

WHILE TRUE

	LET vm_skip_lin = 32
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*

	DECLARE q_t24 CURSOR FOR 
		SELECT talt024.* --, t24_descripcion
			 FROM talt024 --, talt007
			WHERE t24_compania    = vg_codcia
			  AND t24_localidad   = vg_codloc
			  AND t24_orden       = rm_t23.t23_orden
			  AND t24_valor_tarea > 0
--			  AND t07_compania    = t24_compania
--			  AND t07_modelo      = t24_modelo
--			  AND t07_codtarea    = t24_codtarea 

	START REPORT report_factura TO PIPE comando
	LET vm_lin = 1
	FOREACH q_t24 INTO r_t24.* --, nom_tarea
--		OUTPUT TO REPORT report_factura(nom_tarea, 1, r_t24.t24_valor_tarea, vm_lin)
		OUTPUT TO REPORT report_factura(r_t24.t24_descripcion, 1, r_t24.t24_valor_tarea, vm_lin)
		LET vm_lin = vm_lin + 1
	END FOREACH
	FINISH REPORT report_factura
END WHILE

END FUNCTION



REPORT report_factura(nom_tarea, cant, precio, lineas)

DEFINE cant		SMALLINT                   
DEFINE nom_tarea	LIKE talt007.t07_nombre
DEFINE precio		LIKE talt024.t24_valor_tarea
DEFINE lineas 		SMALLINT

DEFINE forma_pago	CHAR(10)

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

	IF rm_t23.t23_cont_cred = 'C' THEN
		LET forma_pago = 'CONTADO'
	ELSE
		LET forma_pago = 'CREDITO'
	END IF

	SKIP 2 LINES
	SKIP 7 LINES
--	print '&k2S' 		-- Letra condensada

	PRINT COLUMN 20, fl_justifica_titulo('I', rm_t23.t23_num_factura CLIPPED, 15),
	      COLUMN 92, DATE(rm_t23.t23_fec_factura) USING 'dd-mm-yyyy', 1 SPACES, TIME 
	IF rm_z01.z01_codcli IS NOT NULL THEN
		PRINT COLUMN 20, rm_t23.t23_nom_cliente CLIPPED,
		      COLUMN 92, rm_z01.z01_num_doc_id
		PRINT COLUMN 20, rm_z01.z01_direccion1 CLIPPED
	ELSE
		PRINT COLUMN 20, rm_t23.t23_nom_cliente CLIPPED
		SKIP 1 LINES                                    
	END IF
	PRINT COLUMN 20, rm_t23.t23_tel_cliente CLIPPED,
	      COLUMN 78, rm_t23.t23_cod_asesor
	PRINT COLUMN 20, forma_pago CLIPPED

	SKIP 7 LINES

ON EVERY ROW
	IF vm_num_lineas <= 29 THEN
		PRINT COLUMN 20,  nom_tarea CLIPPED,
		      COLUMN 86,  cant     USING '####',
		      COLUMN 99,  precio   USING "###,###,##&.##",
		      COLUMN 117, precio   USING "###,###,##&.##"
	ELSE
		IF lineas = vm_num_lineas THEN
			PRINT COLUMN 20,  'Mano de Obra: ',
			      COLUMN 86,  cant     USING '####',
			      COLUMN 99,  SUM(precio) USING "###,###,##&.##",
			      COLUMN 117, SUM(precio) USING "###,###,##&.##"
			LET vm_lin = 1
		END IF
	END IF
	
ON LAST ROW
  	IF rm_t23.t23_val_otros1 > 0 THEN
		PRINT COLUMN 20,  'VIATICOS:',
		      COLUMN 86,   '   1',
		      COLUMN 99, rm_t23.t23_val_otros1 USING "###,###,##&.##",
		      COLUMN 117, rm_t23.t23_val_otros1 USING "###,###,##&.##"
	END IF
  	IF rm_t23.t23_val_otros2 > 0 THEN
		PRINT COLUMN 20,  'SUMINISTROS:',
		      COLUMN 86,   '   1',
		      COLUMN 99, rm_t23.t23_val_otros2 USING "###,###,##&.##",
		      COLUMN 117, rm_t23.t23_val_otros2 USING "###,###,##&.##"
	END IF
	
	NEED 5 LINES

	LET vm_lin = vm_lin + 1
	LET vm_skip_lin = vm_skip_lin - vm_lin 
	IF vm_skip_lin = 0 THEN
		SKIP 1 LINES
	ELSE
		SKIP vm_skip_lin LINES
	END IF

	IF rm_t23.t23_porc_impto = 0 THEN
		PRINT COLUMN 117, 0                    USING '###,###,##&.##'
		PRINT COLUMN 117, rm_t23.t23_tot_bruto USING '###,###,##&.##'
	ELSE
		PRINT COLUMN 117, rm_t23.t23_tot_bruto USING '###,###,##&.##'
		PRINT COLUMN 117, 0                    USING '###,###,##&.##'
	END IF
	PRINT COLUMN 117, rm_t23.t23_tot_dscto USING '###,###,##&.##'
	PRINT COLUMN 117, rm_t23.t23_tot_bruto - rm_t23.t23_tot_dscto
				USING '###,###,##&.&&'
	PRINT COLUMN 50,  rm_t03.t03_nombres CLIPPED,
	      COLUMN 117, rm_t23.t23_val_impto USING '###,###,##&.##'
	PRINT COLUMN 117, '          ---'
	PRINT COLUMN 117, rm_t23.t23_tot_neto  USING '###,###,##&.##' --, 'E'

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

