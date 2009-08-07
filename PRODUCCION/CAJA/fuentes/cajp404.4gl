--------------------------------------------------------------------------------
-- Titulo           : cajp404.4gl - IMPRESION EGRESOS DE CAJA                   
-- Elaboracion      : 24-abr-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cajp404 BD MODULO COMPANIA LOCALIDAD num_egreso
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE vm_num_fuente	LIKE cajt010.j10_num_fuente

DEFINE rm_j10		RECORD LIKE cajt010.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_g08		RECORD LIKE gent008.*

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp404.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 
        'stop')
	EXIT PROGRAM
END IF

LET vg_base       = arg_val(1)
LET vg_modulo     = arg_val(2)
LET vg_codcia     = arg_val(3)
LET vg_codloc     = arg_val(4)
LET vm_num_fuente = arg_val(5)
LET vg_proceso = 'cajp404'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

LET vm_tipo_fuente = 'EC'
INITIALIZE rm_j10.* TO NULL

LET vm_top    = 0
LET vm_left   =	2
LET vm_right  =	132
LET vm_bottom =	0
LET vm_page   = 30

CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, vm_tipo_fuente, vm_num_fuente) 
	RETURNING rm_j10.*
IF rm_j10.j10_num_fuente IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe comprobante de egresos de caja.',
		'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_moneda(rm_j10.j10_moneda) RETURNING rm_g13.*
IF rm_g13.g13_moneda IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'Moneda no existe.',
		'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_banco_general(rm_j10.j10_banco) RETURNING rm_g08.*
{
IF rm_g08.g08_banco IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'Banco no existe.',
		'stop')
	EXIT PROGRAM
END IF
}

CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE comando		VARCHAR(100)
DEFINE moneda    	LIKE cajt011.j11_moneda      
DEFINE cod_bco_tarj	LIKE cajt011.j11_cod_bco_tarj
DEFINE num_ch_aut	LIKE cajt011.j11_num_ch_aut
DEFINE num_cta_tarj	LIKE cajt011.j11_num_cta_tarj
DEFINE valor     	LIKE cajt011.j11_valor       
DEFINE i		SMALLINT

WHILE TRUE
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*

	DECLARE q_fp CURSOR FOR
		SELECT j11_moneda, j11_cod_bco_tarj,
		       j11_num_ch_aut,  j11_num_cta_tarj, j11_valor
		FROM cajt011
		WHERE j11_compania     = rm_j10.j10_compania
		  AND j11_localidad    = rm_j10.j10_localidad
		  AND j11_num_egreso   = vm_num_fuente
	START REPORT report_comprobante TO PIPE comando
	LET i = 0
	FOREACH q_fp INTO moneda, cod_bco_tarj, num_ch_aut, num_cta_tarj, valor 
		LET i = i + 1
		OUTPUT TO REPORT report_comprobante(moneda,
						    cod_bco_tarj,
						    num_ch_aut, 
						    num_cta_tarj, valor,i)
	END FOREACH
	IF i = 0 THEN
		OUTPUT TO REPORT report_comprobante(NULL, NULL, NULL, NULL,NULL,
						    i)
	END IF
	FINISH REPORT report_comprobante
	FREE q_fp  
END WHILE

END FUNCTION



REPORT report_comprobante(moneda, cod_bco_tarj, num_ch_aut, num_cta_tarj, valor,
			  num_rec)

DEFINE bco_tarj			SMALLINT
DEFINE n_bco_tarj		VARCHAR(20)

DEFINE moneda		LIKE cajt011.j11_moneda
DEFINE cod_bco_tarj	LIKE cajt011.j11_cod_bco_tarj
DEFINE num_ch_aut	LIKE cajt011.j11_num_ch_aut
DEFINE num_cta_tarj     LIKE cajt011.j11_num_cta_tarj
DEFINE valor		LIKE cajt011.j11_valor
DEFINE num_rec		SMALLINT

DEFINE i		SMALLINT
DEFINE paridad		LIKE gent014.g14_tasa

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g10		RECORD LIKE gent010.*

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
	PRINT COLUMN 50, 'COMPROBANTE DE EGRESOS DE CAJA No. ',
		fl_justifica_titulo('I', vm_num_fuente CLIPPED, 10)
	SKIP 1 LINES
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Banco', 15), ': ',
		         rm_g08.g08_nombre CLIPPED,
	      COLUMN 84, fl_justifica_titulo('I', 'Fecha', 15), ': ', 
			 DATE(rm_j10.j10_fecha_pro) USING 'dd-mm-yyyy' 
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Cuenta', 15), ': ',
	                 rm_j10.j10_numero_cta CLIPPED
	IF LENGTH(rm_j10.j10_referencia) > 60 THEN
		LET i = 60
		WHILE (rm_j10.j10_referencia[i] <> ' ') 
			LET i = i - 1
		END WHILE
		PRINT COLUMN 10, fl_justifica_titulo('I', 'Referencia ', 15),
		                 ': ', rm_j10.j10_referencia[1, i]
		LET i = i + 1
                PRINT COLUMN 27, fl_justifica_titulo('I', 
				 rm_j10.j10_referencia[i, 120] CLIPPED, 70) 
	ELSE
		PRINT COLUMN 10, fl_justifica_titulo('I', 'Referencia ', 15),
		                 ': ', rm_j10.j10_referencia CLIPPED
		PRINT COLUMN 25, '   '
	END IF
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Moneda', 15), ': ', 
			 rm_g13.g13_nombre,
	      COLUMN 84, fl_justifica_titulo('I', 'Valor Efectivo',  15), ': ',
			 rm_j10.j10_valor USING '#,###,###,##&.##'

	SKIP 1 LINES
	PRINT COLUMN 54,  '<< Cheques Egresados >>'
	PRINT COLUMN 10,  'Bco/Tarj',
	      COLUMN 37,  'Num. Ch/Aut',
	      COLUMN 54,  'Num. Cta/Tarj',
	      COLUMN 79,  'Moneda',
	      COLUMN 83,  fl_justifica_titulo('D', 'Valor', 16),
	      COLUMN 101, fl_justifica_titulo('D', 
				'Valor ' || rm_j10.j10_moneda, 16)
	PRINT COLUMN 05,     '------------------------------------',
      	      COLUMN 41, '----------------------------------------',
              COLUMN 81, '-----------------------------------'

ON EVERY ROW
	IF moneda IS NULL THEN
		RETURN
	END IF
	LET paridad = calcula_paridad(moneda, rm_j10.j10_moneda)
	CALL fl_lee_banco_general(cod_bco_tarj) RETURNING r_g08.*
	LET n_bco_tarj = r_g08.g08_nombre

	PRINT COLUMN 10,  n_bco_tarj   CLIPPED,
	      COLUMN 37,  num_ch_aut   CLIPPED,  
	      COLUMN 54,  num_cta_tarj CLIPPED,
	      COLUMN 79,  moneda       CLIPPED,
	      COLUMN 83,  valor USING '#,###,###,##&.##',       
	      COLUMN 101, (valor * paridad) USING '#,###,###,##&.##'    

ON LAST ROW
	IF num_rec > 0 THEN
		PRINT COLUMN 100, '-----------------'
		PRINT COLUMN 101, SUM(valor * paridad) USING '#,###,###,##&.##'    
	END IF
	
END REPORT



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE gent013.g13_moneda
DEFINE moneda_dest	LIKE gent013.g13_moneda
DEFINE paridad		LIKE gent014.g14_tasa       

DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto, 
				    'No existe factor de conversión ' ||
				    'para esta moneda',
				    'exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

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

