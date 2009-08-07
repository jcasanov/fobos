--------------------------------------------------------------------------------
-- Titulo           : repp419.4gl - REPORTE DE PROFORMA 
-- Elaboracion      : 28-dic-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp419 BD MODULO COMPANIA LOCALIDAD PROFORMA
-- Ultima Correccion: 06-Feb-2002 
-- Motivo Correccion: Arregado para que calcule el peso de la proforma 
-- 		      multiplicando la cantidad por el peso
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE vm_proforma	LIKE rept021.r21_numprof
DEFINE vm_last_item_ant	LIKE rept022.r22_item_ant

DEFINE rm_r21		RECORD LIKE rept021.*
DEFINE rm_r22		RECORD LIKE rept022.*
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_g30  		RECORD LIKE gent030.*
DEFINE rm_g31	  	RECORD LIKE gent031.*
DEFINE rm_z01	  	RECORD LIKE cxct001.*

DEFINE vm_lin		SMALLINT

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parametros correcto
	CALL fgl_winmessage(vg_producto, 'Numero de parametros incorrecto.', 
        'stop')
	EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_proforma = arg_val(5)
LET vg_proceso = 'repp419'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

INITIALIZE rm_r21.*, rm_g30.*, rm_g31.*, rm_z01.*, rm_r01.* TO NULL

LET vm_top    = 1
LET vm_left   =	6
LET vm_right  =	132
LET vm_bottom =	2
LET vm_page   = 66

CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, vm_proforma) 
	RETURNING rm_r21.*

IF rm_r21.r21_numprof IS NULL THEN	
	CALL FGL_WINMESSAGE(vg_producto,'No existe Proforma.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_vendedor_rep(vg_codcia, rm_r21.r21_vendedor)
	RETURNING rm_r01.*
CALL fl_lee_cliente_general(rm_r21.r21_codcli)
	RETURNING rm_z01.*
CALL fl_lee_ciudad(rm_z01.z01_ciudad) RETURNING rm_g31.*
CALL fl_lee_pais(rm_g31.g31_pais)     RETURNING rm_g30.*

CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE i 		SMALLINT
DEFINE comando		VARCHAR(100)
DEFINE r_r22		RECORD LIKE rept022.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE nom_item		LIKE rept010.r10_nombre
DEFINE peso_item	LIKE rept010.r10_peso
DEFINE ubicacion_item	LIKE rept011.r11_ubicacion
DEFINE acumulado	LIKE rept021.r21_tot_neto
DEFINE acumula_peso	DECIMAL(9,3)
DEFINE resp		VARCHAR(3)

WHILE TRUE
	INITIALIZE vm_last_item_ant TO NULL
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT WHILE
	END IF


	LET resp = 'Yes'

	CALL fgl_winquestion(vg_producto, 'Mostrar codigo del item?', 
		'Yes', 'Yes|No', 'question', 1) RETURNING resp

	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
	DECLARE q_rept022 CURSOR FOR 
		SELECT rept022.*, r10_nombre, r10_peso
			 FROM rept022, rept010
			WHERE r22_compania  = vg_codcia
			  AND r22_localidad = vg_codloc
			  AND r22_numprof   = vm_proforma
			  AND r10_compania  = r22_compania
			  AND r10_codigo    = r22_item
			ORDER BY r22_orden

	LET vm_lin = 0
	LET acumulado = 0
	LET acumula_peso = 0
	START REPORT report_proforma TO PIPE comando
	FOREACH q_rept022 INTO r_r22.*, nom_item, peso_item
		LET acumulado = acumulado + (r_r22.r22_precio * r_r22.r22_cantidad)
		CALL fl_lee_stock_rep(vg_codcia, rm_r21.r21_bodega, r_r22.r22_item)
			RETURNING r_r11.*
		LET ubicacion_item = r_r11.r11_ubicacion
		-- Si no quiere ver los codigos de los items
		IF resp = 'No' THEN
			INITIALIZE r_r22.r22_item TO NULL
		END IF
## CALCULAR EL PESO
		LET acumula_peso = acumula_peso + (peso_item * r_r22.r22_cantidad)
		OUTPUT TO REPORT report_proforma(r_r22.r22_item, nom_item,
						 r_r22.r22_item_ant,
						 ubicacion_item, 
						 r_r22.r22_cantidad, 
						 peso_item, 
						 r_r22.r22_porc_descto,
						 r_r22.r22_precio,	
						 r_r22.r22_cantidad *
						 r_r22.r22_precio,
						 acumulado, acumula_peso)
	END FOREACH
	FINISH REPORT report_proforma

END WHILE

END FUNCTION



REPORT report_proforma(cod, descrip, item_ant, ubic, cant, peso, dscto, precio,
		       subtotal, acumulado, acumula_peso)
DEFINE cod		LIKE rept022.r22_item
DEFINE descrip		LIKE rept010.r10_nombre
DEFINE item_ant		LIKE rept022.r22_item_ant
DEFINE ubic		LIKE rept011.r11_ubicacion
DEFINE cant		LIKE rept022.r22_cantidad
DEFINE peso		LIKE rept010.r10_peso
DEFINE dscto		LIKE rept022.r22_porc_descto
DEFINE precio		LIKE rept022.r22_precio
DEFINE subtotal		LIKE rept022.r22_precio

DEFINE impuesto		LIKE rept021.r21_tot_dscto
DEFINE mensaje		VARCHAR(80)
DEFINE last_row 	SMALLINT
DEFINE acumulado	LIKE rept021.r21_tot_neto
DEFINE acumula_peso	DECIMAL(9,3)

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE i,long		SMALLINT

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page

FORMAT
PAGE HEADER
	print 'E';
	print '&l26A';	-- Indica que voy a trabajar con hojas A4

	LET last_row  = 0

	LET impuesto = rm_r21.r21_tot_neto -
	       (rm_r21.r21_tot_bruto - rm_r21.r21_tot_dscto)

	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19)      RETURNING usuario
	LET titulo = 'COTIZACION'
	
	PRINT COLUMN 1, '&k0S' 
	print column (34 - ((length(titulo CLIPPED) / 2) - 1)), titulo CLIPPED
	--  column , titulo CLIPPED 

	print '&k2S' 		-- Letra condensada
	LET mensaje = 'RUC: ' || rg_loc.g02_numruc CLIPPED
	print column (60 - ((length(mensaje CLIPPED) / 2) - 1)), mensaje CLIPPED

	LET mensaje = 'Contribuyente Especial Segun Resolucion No 198'
	print column (60 - ((length(mensaje CLIPPED) / 2) - 1)), mensaje CLIPPED 

	LET mensaje = 'de Dic. 10 de 1999'
	print column (60 - ((length(mensaje CLIPPED) / 2) - 1)), mensaje CLIPPED 

	SKIP 1 LINES
	PRINT COLUMN 01,  'No Cotizacion: ', 
			  fl_justifica_titulo('I', rm_r21.r21_numprof, 7),
	      COLUMN 75, '         Pagina: ', PAGENO USING '&&&'

	PRINT COLUMN 01, '   Atencion a: ', rm_r21.r21_atencion CLIPPED,
	      COLUMN 75, '          Fecha: ', DATE(rm_r21.r21_fecing) 
						USING 'dd-mm-yyyy', 
					      1 SPACES, TIME 

	PRINT COLUMN 01, '      Cliente: ', rm_r21.r21_nomcli CLIPPED,
	      COLUMN 75, '       Vendedor: ',  rm_r01.r01_nombres CLIPPED 

	PRINT COLUMN 01, '    Direccion: ', rm_r21.r21_dircli CLIPPED,
	      COLUMN 77, '       Modelo: ', rm_r21.r21_modelo 

	PRINT COLUMN 01, '       Ciudad: ', rm_g31.g31_nombre CLIPPED,
	      COLUMN 75, 'Dias de Validez: ', 
			  fl_justifica_titulo('I', rm_r21.r21_dias_prof, 4) 
	
	PRINT COLUMN 01, '         Pais: ', rm_g30.g30_nombre CLIPPED,
	      COLUMN 83, 'Usuario: ',vg_usuario 

	PRINT COLUMN 01, '     Telefono: ', rm_r21.r21_telcli CLIPPED,
	      COLUMN 77, 'Forma de Pago: ',rm_r21.r21_forma_pago[1,28]

	PRINT COLUMN 01, 'Observaciones: ', rm_r21.r21_referencia CLIPPED,
	      COLUMN 92, rm_r21.r21_forma_pago[29,40]

	SKIP 1 LINES

	PRINT "================================================================================================================"
	PRINT COLUMN 01, 'No',
	      COLUMN 05, 'Item',
	      COLUMN 22, 'Descripción',
	      COLUMN 54, 'Ubic',
	      COLUMN 66, 'Cant',
	      COLUMN 71, 'Peso Unit',
	      COLUMN 82, 'Precio Unit',
	      COLUMN 101,'Subtotal'
	PRINT "================================================================================================================"

PAGE TRAILER
	NEED 3 LINES
	IF NOT last_row THEN
		PRINT COLUMN 102, '================'
		PRINT COLUMN 90, '  Subtotal: ', 
		      COLUMN 102, acumulado USING '#,###,###,##&.##'
		SKIP 1 LINES
	ELSE
		LET mensaje = 'UTILICE SIEMPRE REPUESTOS ORIGINALES'
		PRINT COLUMN 1, '&k0S', 
		      column (40 - ((length(mensaje CLIPPED) / 2) - 1)), mensaje CLIPPED 
		LET mensaje = 'KOMATSU'
		PRINT COLUMN 1, '&k0S', 
		      column (40 - ((length(mensaje CLIPPED) / 2) - 1)), mensaje CLIPPED 
		LET mensaje = 'ATENCION LOS SABADOS 09:00 A 13:00'
		PRINT COLUMN 1, '&k0S', 
		      column (40 - ((length(mensaje CLIPPED) / 2) - 1)), mensaje CLIPPED 
	END IF

ON EVERY ROW
	IF item_ant IS NOT NULL THEN
		IF item_ant <> vm_last_item_ant OR vm_last_item_ant IS NULL THEN
			LET vm_last_item_ant = item_ant
			IF cod IS NULL THEN
				LET item_ant = 5 SPACES
			END IF
			LET vm_lin = vm_lin + 1
			IF vm_lin > 1 THEN
				PRINT "---------------------------------------",
                                      "---------------------------------------",
                                      "----------------------------------"
			END IF
			PRINT COLUMN 01, vm_lin USING '###',
			      COLUMN 05, item_ant, 
	      		      COLUMN 22, 'sustituido por: ',
	      		      COLUMN 54, '***',
	      		      COLUMN 66, '****',
	      		      COLUMN 71, '     ****',
	      		      COLUMN 82, '          ****',
	      		      COLUMN 98, '          ****' 
		END IF
	ELSE
		INITIALIZE vm_last_item_ant TO NULL
		LET vm_lin = vm_lin + 1
		IF vm_lin > 1 THEN
			PRINT "---------------------------------------",
                              "---------------------------------------",
                              "----------------------------------"
		END IF
	END IF

	IF cod IS NULL THEN
		LET cod = 5 SPACES
	END IF

	PRINT COLUMN 01, vm_lin USING '###',
	      COLUMN 05, cod,
	      COLUMN 22, descrip[1,30],
	      COLUMN 54, ubic,
	      COLUMN 66, cant      USING '####',
	      COLUMN 71, peso      USING '#,##&.###',
	      COLUMN 82, precio    USING "###,###,##&.##",
	      COLUMN 98, subtotal  USING "###,###,##&.##"
	
ON LAST ROW
	NEED 7 LINES

	LET last_row = 1

	PRINT COLUMN 96, '================'

	PRINT COLUMN 83, 'Total Bruto: ', 
	      COLUMN 96, rm_r21.r21_tot_bruto  USING '#,###,###,##&.##'
	
	PRINT COLUMN 83, 'Total Dscto: ', 
	      COLUMN 96, rm_r21.r21_tot_dscto USING '#,###,###,##&.##'

	PRINT COLUMN 96, '================'

	PRINT COLUMN 83, '   Subtotal: ',
	      COLUMN 96, (rm_r21.r21_tot_bruto - rm_r21.r21_tot_dscto) 
				USING '#,###,###,##&.##'

	PRINT COLUMN 83, fl_justifica_titulo('D', rg_gen.g00_label_impto CLIPPED, 11), ': ', 
	      COLUMN 96, impuesto USING '#,###,###,##&.##'

	PRINT COLUMN 59, 'Peso: ', acumula_peso USING '###,##&.###', ' Kg.',
	      COLUMN 84, 'Total Neto: ', 
	      COLUMN 96, rm_r21.r21_tot_neto USING '#,###,###,##&.##'
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

