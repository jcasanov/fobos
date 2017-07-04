--------------------------------------------------------------------------------
-- Titulo           : cajp400.4gl - IMPRESION INGRESO A CAJA POR PAGO FACTURAS
-- Elaboracion      : 13-feb-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cajp400 BD MODULO COMPANIA LOCALIDAD SOL_COBRO
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE vm_sol_cobro 	LIKE cajt010.j10_num_fuente

DEFINE rm_j10		RECORD LIKE cajt010.*
DEFINE rm_z24		RECORD LIKE cxct024.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_g03		RECORD LIKE gent003.*
DEFINE rm_g13		RECORD LIKE gent013.*

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN
DEFINE vm_lineas_impr	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp400.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF

LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vm_sol_cobro = arg_val(5)
LET vg_proceso   = 'cajp400'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()

--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

LET vm_tipo_fuente = 'SC'
INITIALIZE rm_j10.* TO NULL

-- Para probar en una impresora matricial
LET vm_top    = 0
LET vm_left   =	2
LET vm_right  =	132
LET vm_bottom =	0
LET vm_page   = 30

CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, vm_tipo_fuente, vm_sol_cobro) 
	RETURNING rm_j10.*
IF rm_j10.j10_num_fuente IS NULL THEN
	CALL fl_mostrar_mensaje('No existe solicitud de cobro.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_area_negocio(vg_codcia, rm_j10.j10_areaneg) RETURNING rm_g03.*
IF rm_g03.g03_areaneg IS NULL THEN
	CALL fl_mostrar_mensaje('No existe area de negocio.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc, vm_sol_cobro)
	RETURNING rm_z24.*
IF rm_z24.z24_numero_sol IS NULL THEN
	CALL fl_mostrar_mensaje('No existe solicitud de cobro.','stop')
	EXIT PROGRAM
END IF
IF rm_z24.z24_tipo = 'A' THEN
	CALL fl_mostrar_mensaje('La solicitud de cobro es por pago anticipado.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_moneda(rm_j10.j10_moneda) RETURNING rm_g13.*
IF rm_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('Moneda no existe.','stop')
	EXIT PROGRAM
END IF

LET vm_lineas_impr = 44
IF rm_j10.j10_localidad >= 3 AND rm_j10.j10_localidad <= 5 THEN
	LET vm_lineas_impr = 33
END IF
CALL control_main_reporte()
EXIT PROGRAM

END FUNCTION



FUNCTION control_main_reporte()
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
START REPORT report_solicitud TO PIPE comando
OUTPUT TO REPORT report_solicitud('D') -- Documentos
OUTPUT TO REPORT report_solicitud('F') -- Forma de Pago
FINISH REPORT report_solicitud

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

DEFINE forma_pago	LIKE cajt011.j11_codigo_pago
DEFINE moneda		LIKE cajt011.j11_moneda
DEFINE cod_bco_tarj	LIKE cajt011.j11_cod_bco_tarj
DEFINE num_ch_aut	LIKE cajt011.j11_num_ch_aut
DEFINE num_cta_tarj     LIKE cajt011.j11_num_cta_tarj
DEFINE valor		LIKE cajt011.j11_valor
DEFINE cont_cred	LIKE cajt001.j01_cont_cred

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g10		RECORD LIKE gent010.*

DEFINE num_docs		SMALLINT
DEFINE skip_lin		SMALLINT
DEFINE linea_1		CHAR(100)
DEFINE linea_2		CHAR(100)
DEFINE linea_3		CHAR(100)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
--	TOP    MARGIN	vm_top
--	LEFT   MARGIN	vm_left
--	RIGHT  MARGIN	vm_right
--	BOTTOM MARGIN	vm_bottom
  	--#PAGE   LENGTH	vm_lineas_impr
	TOP    MARGIN	1	## 0
	LEFT   MARGIN	0	## 2
	RIGHT  MARGIN	132
	BOTTOM MARGIN	4	## 5

FORMAT
PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*

	SKIP 1 LINES
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 03, r_g01.g01_razonsocial
	PRINT COLUMN 50, 'COMPROBANTE DE INGRESO No. ',
		rm_j10.j10_tipo_destino, '-',
		fl_justifica_titulo('I', rm_j10.j10_num_destino CLIPPED, 10);
	IF rm_j10.j10_estado = 'E' THEN
		PRINT 10 SPACES, '** ELIMINADO **'
	ELSE
		PRINT
	END IF
	SKIP 1 LINES
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Cliente', 15), ': ',
		         rm_j10.j10_nomcli CLIPPED,
	      COLUMN 86, fl_justifica_titulo('I', 'Fecha', 6), ': ', 
			 DATE(rm_j10.j10_fecha_pro) USING 'dd-mm-yyyy', 
                         1 SPACES, TIME 
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Area de Negocio', 15), ': ',
		         fl_justifica_titulo('I', rm_j10.j10_areaneg, 5),
			 rm_g03.g03_nombre,
	      COLUMN 86, fl_justifica_titulo('I', 'Moneda', 6), ': ', 
			 rm_g13.g13_nombre
	PRINT COLUMN 10, 'POR PAGO DE FACTURA',
	      COLUMN 86, fl_justifica_titulo('I', 'Valor',  6), ': ',
			 rm_j10.j10_valor USING '#,###,###,##&.##'

ON EVERY ROW
	SKIP 1 LINES
	IF flag = 'D' THEN
		PRINT COLUMN 50, '<< Documentos Cancelados >>'
		PRINT COLUMN 15, 'Documento',
		      COLUMN 44, fl_justifica_titulo('D', 'Valor Original', 16),
		      COLUMN 67, fl_justifica_titulo('D', 'Valor Pagado',   16),
		      COLUMN 90, fl_justifica_titulo('D', 'Valor Actual',   16)
		PRINT COLUMN 05,     '------------------------------------',
	      	      COLUMN 41, '----------------------------------------',
	              COLUMN 81, '-----------------------------------'
	
		DECLARE q_docs CURSOR FOR
			SELECT z25_tipo_doc, z25_num_doc, z25_dividendo,
			       ((z20_saldo_cap + z20_saldo_int) + 
			       (z25_valor_cap + z25_valor_int)),
			       (z25_valor_cap + z25_valor_int),
			       (z20_saldo_cap + z20_saldo_int) 
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
			--#SKIP skip_lin LINES
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
			SELECT j11_codigo_pago, j11_moneda, j11_cod_bco_tarj,
			       j11_num_ch_aut,  j11_num_cta_tarj, j11_valor
			FROM cajt011
			WHERE j11_compania    = rm_j10.j10_compania
			  AND j11_localidad   = rm_j10.j10_localidad
			  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
			  AND j11_num_fuente  = rm_j10.j10_num_fuente

		FOREACH q_fp INTO forma_pago, moneda, cod_bco_tarj, num_ch_aut,
				    num_cta_tarj, valor 
			LET bco_tarj = banco_tarjeta(forma_pago)
			IF bco_tarj = 1 THEN
				CALL fl_lee_banco_general(cod_bco_tarj) 
					RETURNING r_g08.*
				LET n_bco_tarj = r_g08.g08_nombre
			ELSE
				IF bco_tarj = 2 THEN
					LET cont_cred = 'C'
					IF rm_j10.j10_tipo_fuente = 'SC' THEN
						LET cont_cred = 'R'
					END IF
					CALL fl_lee_tarjeta_credito(vg_codcia,
								cod_bco_tarj,
								forma_pago,
								cont_cred)
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
		print ASCII escape;
		print ASCII desact_comp 
	END IF

END REPORT



FUNCTION banco_tarjeta(forma_pago)

DEFINE forma_pago	LIKE cajt011.j11_codigo_pago
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
