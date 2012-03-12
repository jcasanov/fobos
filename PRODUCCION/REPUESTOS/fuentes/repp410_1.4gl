--------------------------------------------------------------------------------
-- Titulo           : repp410.4gl - REPORTE DE FACTURA 
-- Elaboracion      : 28-dic-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp410 BD MODULO COMPANIA LOCALIDAD FACTURA
-- Ultima Correccion: 28-dic-2001 
-- Motivo Correccion: 1
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_cod_tran 	LIKE rept019.r19_cod_tran
DEFINE vm_factura	LIKE rept019.r19_num_tran

DEFINE rm_r19		RECORD LIKE rept019.*
DEFINE rm_r20		RECORD LIKE rept020.*
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_cia		RECORD LIKE gent001.*

DEFINE vm_lin, vm_skip_lin	SMALLINT
DEFINE vm_vendedor		LIKE rept001.r01_nombres

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp410.error')
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
LET vg_proceso = 'repp410'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE num_lineas	SMALLINT
DEFINE r_r01		RECORD LIKE rept001.*

CALL fl_nivel_isolation()

LET vm_cod_tran = 'FA'
INITIALIZE rm_r19.* TO NULL

-- Para probar en una impresora matricial
LET vm_top    = 0
LET vm_left   =	2
LET vm_right  =	132
LET vm_bottom =	0
LET vm_page   = 66

CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, 
				     vm_cod_tran, vm_factura) 
	RETURNING rm_r19.*

IF rm_r19.r19_num_tran IS NULL THEN	
	CALL FGL_WINMESSAGE(vg_producto,'No existe factura.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_compania_repuestos(vg_codcia)  
        RETURNING rm_r00.*                

SELECT COUNT(*) INTO num_lineas FROM rept020 
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = vm_cod_tran
	  AND r20_num_tran  = rm_r19.r19_num_tran

IF num_lineas > rm_r00.r00_numlin_fact THEN
	CALL fgl_winmessage(vg_producto,
		'La factura tiene demasiadas lineas.',
		'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor) RETURNING r_r01.*
IF r_r01.r01_codigo IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'Vendedor no existe.',
		'stop')
	EXIT PROGRAM
END IF

LET vm_vendedor = r_r01.r01_nombres

CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE i 		SMALLINT
DEFINE comando		VARCHAR(100)
DEFINE r_r20		RECORD LIKE rept020.*

DEFINE nom_item		LIKE rept010.r10_nombre
DEFINE acumulado	LIKE rept019.r19_tot_neto



WHILE TRUE

	LET vm_skip_lin = 35
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
	DECLARE q_rept020 CURSOR FOR 
		SELECT rept020.*, r10_nombre
			 FROM rept020, rept010
			WHERE r20_compania  = vg_codcia
			  AND r20_localidad = vg_codloc
			  AND r20_cod_tran  = vm_cod_tran
			  AND r20_num_tran  = rm_r19.r19_num_tran
			  AND r10_compania  = r20_compania
			  AND r10_codigo    = r20_item  
			ORDER BY r20_orden

	LET acumulado = 0
	START REPORT report_factura TO PIPE comando
	LET vm_lin = 1
	FOREACH q_rept020 INTO r_r20.*, nom_item
		LET acumulado = acumulado + (r_r20.r20_precio * r_r20.r20_cant_ven)
		OUTPUT TO REPORT report_factura(r_r20.r20_item, nom_item,
						r_r20.r20_ubicacion, 
						r_r20.r20_cant_ven, 
						r_r20.r20_descuento,
						r_r20.r20_precio,	
						r_r20.r20_cant_ven *
						r_r20.r20_precio, 
						acumulado)
		LET vm_lin = vm_lin + 1
	END FOREACH
	FINISH REPORT report_factura
END WHILE

END FUNCTION



REPORT report_factura(cod, descrip, ubic, cant, dscto, precio, subtotal, acumulado)
DEFINE cod		LIKE rept020.r20_item
DEFINE descrip		LIKE rept010.r10_nombre
DEFINE ubic		LIKE rept020.r20_ubicacion
DEFINE cant		LIKE rept020.r20_cant_ped
DEFINE dscto		LIKE rept020.r20_descuento
DEFINE precio		LIKE rept020.r20_precio
DEFINE subtotal		LIKE rept020.r20_precio

DEFINE acumulado	LIKE rept019.r19_tot_neto

DEFINE impuesto		LIKE rept019.r19_tot_dscto

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

	IF rm_r19.r19_cont_cred = 'C' THEN
		LET forma_pago = 'CONTADO'
	ELSE
		LET forma_pago = 'CREDITO'
	END IF
	LET impuesto = rm_r19.r19_tot_neto   -  rm_r19.r19_flete  -
		(rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto)

	SKIP 12 LINES
--	print '&k2S' 		-- Letra condensada

	PRINT COLUMN 22, fl_justifica_titulo('I', rm_r19.r19_num_tran CLIPPED, 15)
	PRINT COLUMN 22, rm_r19.r19_nomcli CLIPPED,
		  COLUMN 99, DATE(rm_r19.r19_fecing) USING 'dd-mm-yyyy', 1 SPACES, TIME 
	PRINT COLUMN 22, rm_r19.r19_dircli CLIPPED,
		  COLUMN 99, rm_r19.r19_cedruc 
	PRINT COLUMN 22, rm_r19.r19_telcli CLIPPED
	PRINT COLUMN 22, forma_pago CLIPPED,
	      COLUMN 78, rm_r19.r19_vendedor
	PRINT COLUMN 22, rm_r19.r19_oc_externa CLIPPED

	SKIP 6 LINES

ON EVERY ROW

	PRINT COLUMN 5,   cod CLIPPED, 
	      COLUMN 23,  descrip[1, 30] CLIPPED,
	      COLUMN 56,  ubic		CLIPPED,
	      COLUMN 86,  cant     USING '####',
	      COLUMN 99,  precio   USING "###,###,##&.##",
	      COLUMN 117, subtotal USING "###,###,##&.##"
	
ON LAST ROW
	NEED 5 LINES

	LET vm_skip_lin = vm_skip_lin - vm_lin 
	IF vm_skip_lin = 0 THEN
		SKIP 1 LINES
	ELSE
		SKIP vm_skip_lin LINES
	END IF

	IF rm_r19.r19_porc_impto = 0 THEN
		PRINT COLUMN 117, 0                    USING '###,###,##&.##'
		PRINT COLUMN 117, rm_r19.r19_tot_bruto USING '###,###,##&.##'
	ELSE
		PRINT COLUMN 117, rm_r19.r19_tot_bruto USING '###,###,##&.##'
		PRINT COLUMN 117, 0                    USING '###,###,##&.##'
	END IF
	PRINT COLUMN 117, rm_r19.r19_tot_dscto USING '###,###,##&.##'
	PRINT COLUMN 117, rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto
				USING '###,###,##&.&&'
	PRINT COLUMN 50,  vm_vendedor CLIPPED,
	      COLUMN 117, impuesto             USING '###,###,##&.##'
	IF rm_r19.r19_ped_cliente IS NOT NULL THEN
		PRINT COLUMN 10,  'Nota: ', fl_justifica_titulo('I', rm_r19.r19_ped_cliente, 10) CLIPPED,
		      COLUMN 117, rm_r19.r19_flete     USING '###,###,##&.##'
	ELSE
		PRINT COLUMN 117, rm_r19.r19_flete     USING '###,###,##&.##'
	END IF
	PRINT COLUMN 117, rm_r19.r19_tot_neto  USING '###,###,##&.##'--, 'E'

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

