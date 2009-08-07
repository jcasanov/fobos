{*
 * Titulo           : cxcp404.4gl - IMPRESION SOLICITUD DE COBRO
 * Elaboracion      : 29-ago-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun cxcp404 BD MODULO COMPANIA LOCALIDAD SOL_COBRO
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_sol_cobro 	LIKE cxct024.z24_numero_sol

DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_z24		RECORD LIKE cxct024.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_g03		RECORD LIKE gent003.*
DEFINE rm_g13		RECORD LIKE gent013.*

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp404.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 
        'stop')
	EXIT PROGRAM
END IF

LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vm_sol_cobro = arg_val(5)
LET vg_proceso = 'cxcp404'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

-- Para probar en una impresora matricial
LET vm_top    = 0
LET vm_left   =	2
LET vm_right  =	132
LET vm_bottom =	0
LET vm_page   = 30

CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc, vm_sol_cobro)
	RETURNING rm_z24.*
IF rm_z24.z24_numero_sol IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe solicitud de cobro.',
		'stop')
	EXIT PROGRAM
END IF
IF rm_z24.z24_tipo = 'A' THEN
	CALL fgl_winmessage(vg_producto,
		'La solicitud de cobro es por pago anticipado.',
		'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_area_negocio(vg_codcia, rm_z24.z24_areaneg) RETURNING rm_g03.*
IF rm_g03.g03_areaneg IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe area de negocio.',
		'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_cliente_general(rm_z24.z24_codcli) RETURNING rm_z01.*

CALL fl_lee_moneda(rm_z24.z24_moneda) RETURNING rm_g13.*
IF rm_g13.g13_moneda IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'Moneda no existe.',
		'stop')
	EXIT PROGRAM
END IF

CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE comando		VARCHAR(100)

WHILE TRUE
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*

	START REPORT report_solicitud TO PIPE comando
		OUTPUT TO REPORT report_solicitud('D') -- Documentos
		OUTPUT TO REPORT report_solicitud('F') -- Forma de Pago
	FINISH REPORT report_solicitud
END WHILE

END FUNCTION



REPORT report_solicitud(flag)

DEFINE flag		CHAR(1)

DEFINE tipo_doc		LIKE cxct025.z25_tipo_doc
DEFINE num_doc		LIKE cxct025.z25_num_doc
DEFINE div_doc		LIKE cxct025.z25_dividendo
DEFINE valor_ori	LIKE cxct020.z20_valor_cap
DEFINE valor_pago	LIKE cxct025.z25_valor_cap
DEFINE valor_act	LIKE cxct020.z20_saldo_cap

DEFINE bco_tarj			SMALLINT
DEFINE n_bco_tarj		VARCHAR(20)

DEFINE forma_pago	LIKE cxct101.z101_codigo_pago
DEFINE moneda		LIKE cxct101.z101_moneda
DEFINE cod_bco_tarj	LIKE cxct101.z101_cod_bco_tarj
DEFINE num_ch_aut	LIKE cxct101.z101_num_ch_aut
DEFINE num_cta_tarj     LIKE cxct101.z101_num_cta_tarj
DEFINE valor		LIKE cxct101.z101_valor

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g10		RECORD LIKE gent010.*

DEFINE num_docs		SMALLINT
DEFINE skip_lin		SMALLINT

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page

FORMAT
PAGE HEADER
	print '@';
	print 'EDITECA - KOMATSUF'
--	SKIP 1 LINES
	PRINT COLUMN 50, 'SOLICITUD DE COBRO No. ',
		fl_justifica_titulo('I', vm_sol_cobro CLIPPED, 10)
	SKIP 1 LINES
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Cliente', 15), ': ',
		         rm_z01.z01_nomcli CLIPPED,
	      COLUMN 86, fl_justifica_titulo('I', 'Fecha', 6), ': ', 
			 DATE(rm_z24.z24_fecing) USING 'dd-mm-yyyy', 
                         1 SPACES, TIME 
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Area de Negocio', 15), ': ',
		         fl_justifica_titulo('I', rm_z24.z24_areaneg, 5),
			 rm_g03.g03_nombre,
	      COLUMN 86, fl_justifica_titulo('I', 'Moneda', 6), ': ', 
			 rm_g13.g13_nombre
	PRINT COLUMN 10, 'POR PAGO DE FACTURA',
	      COLUMN 86, fl_justifica_titulo('I', 'Valor',  6), ': ',
			 rm_z24.z24_total_cap + rm_z24.z24_total_int 
					USING '#,###,###,##&.##'
ON EVERY ROW
	SKIP 1 LINES
	IF flag = 'D' THEN
		PRINT COLUMN 50, '<< Documentos a Cancelar >>'
		PRINT COLUMN 15, 'Documento',
		      COLUMN 44, fl_justifica_titulo('D', 'Valor Original', 16),
		      COLUMN 67, fl_justifica_titulo('D', 'Valor Pagado',   16),
		      COLUMN 90, fl_justifica_titulo('D', 'Valor Actual',   16)
		PRINT COLUMN 05,     '------------------------------------',
	      	      COLUMN 41, '----------------------------------------',
	              COLUMN 81, '-----------------------------------'
	
		DECLARE q_docs CURSOR FOR
			SELECT z25_tipo_doc, z25_num_doc, z25_dividendo,
			       (z20_saldo_cap + z20_saldo_int), -- + 
		--	       (z25_valor_cap + z25_valor_int)),
			       (z25_valor_cap + z25_valor_int),
			       ((z20_saldo_cap + z20_saldo_int) - 
		  	       (z25_valor_cap + z25_valor_int))
			FROM cxct025, cxct020
			WHERE z25_compania   = vg_codcia
			  AND z25_localidad  = vg_codloc
			  AND z25_numero_sol = vm_sol_cobro
			  AND z20_compania   = z25_compania
			  AND z20_localidad  = z25_localidad
			  AND z20_codcli     = z25_codcli
			  AND z20_tipo_doc   = z25_tipo_doc
			  AND z20_num_doc    = z25_num_doc
			  AND z20_dividendo  = z25_dividendo

		LET num_docs = 0
		FOREACH q_docs INTO tipo_doc,   num_doc,  div_doc, valor_ori,
				    valor_pago, valor_act
			PRINT COLUMN 15, tipo_doc   CLIPPED || '-',
					 num_doc    CLIPPED || '-',
					 div_doc    USING '&&&',
			      COLUMN 44, valor_ori  USING '#,###,###,##&.##',
		      	      COLUMN 67, valor_pago USING '#,###,###,##&.##',
		              COLUMN 90, valor_act  USING '#,###,###,##&.##'
			LET num_docs = num_docs + 1
		END FOREACH
		FREE q_docs
		IF num_docs < 10 THEN
			LET skip_lin = 10 - num_docs
			SKIP skip_lin LINES
		END IF
	END IF
	IF flag = 'F' THEN
		PRINT COLUMN 54, '<< Forma de Pago >>'
		PRINT COLUMN 10, 'Forma Pago',
		      COLUMN 22, 'Moneda',
		      COLUMN 30, 'Bco/Tarj',
		      COLUMN 52, 'Num. Ch/Aut',
		      COLUMN 69, 'Num. Cta/Tarj',
		      COLUMN 94, fl_justifica_titulo('D', 'Valor', 16)
		PRINT COLUMN 05,     '------------------------------------',
	      	      COLUMN 41, '----------------------------------------',
	              COLUMN 81, '-----------------------------------'

		DECLARE q_fp CURSOR FOR
			SELECT z101_codigo_pago, z101_moneda, z101_cod_bco_tarj,
			       z101_num_ch_aut,  z101_num_cta_tarj, z101_valor
			FROM cxct101
			WHERE z101_compania    = rm_z24.z24_compania
			  AND z101_localidad   = rm_z24.z24_localidad
			  AND z101_numero_sol  = vm_sol_cobro

		FOREACH q_fp INTO forma_pago, moneda, cod_bco_tarj, num_ch_aut,
				    num_cta_tarj, valor 
			LET bco_tarj = banco_tarjeta(forma_pago)
			IF bco_tarj = 1 THEN
				CALL fl_lee_banco_general(cod_bco_tarj) 
					RETURNING r_g08.*
				LET n_bco_tarj = r_g08.g08_nombre
			ELSE
				IF bco_tarj = 2 THEN
					CALL fl_lee_tarjeta_credito(
						cod_bco_tarj) 
						RETURNING r_g10.*
					LET n_bco_tarj = r_g10.g10_nombre
				ELSE
					LET n_bco_tarj = ' '
				END IF
			END IF

			PRINT COLUMN 10, forma_pago   CLIPPED,
			      COLUMN 22, moneda       CLIPPED,
		      	      COLUMN 30, n_bco_tarj   CLIPPED,
		              COLUMN 52, num_ch_aut   CLIPPED,  
		              COLUMN 69, num_cta_tarj CLIPPED,
			      COLUMN 94, valor USING '#,###,###,##&.##'       
		END FOREACH
		FREE q_fp  
	END IF

END REPORT



FUNCTION banco_tarjeta(forma_pago)

DEFINE forma_pago	LIKE cxct101.z101_codigo_pago
DEFINE ret_val		SMALLINT

-- En el CASE se le asignara:

-- 1 (UNO) a la variable ret_val si el codigo está relacionado a un
-- banco 
-- 2 (DOS) a la variable ret_val si el codigo está relacionado a una
-- tarjeta de crédito 
-- 3 (TRES) a la variable ret_val si el codigo requiere que se ingrese 
-- un numero pero no un banco ni tarjeta

CASE forma_pago
	WHEN 'CH' LET ret_val = 1 
	WHEN 'DP' LET ret_val = 1 
	WHEN 'CD' LET ret_val = 1 
	WHEN 'DA' LET ret_val = 1 
	
	WHEN 'TJ' LET ret_val = 2

	WHEN 'RT' LET ret_val = 3
	
	OTHERWISE  
		-- Estas formas de pago no necesitan informacion del
		-- banco o tarjeta de crédito:
		-- 'EF', 'OC', 'OT', 'RT'
		INITIALIZE ret_val TO NULL
END CASE 

RETURN ret_val

END FUNCTION



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

