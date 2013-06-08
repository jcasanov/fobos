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
DEFINE tot_valor	DECIMAL(14,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF

LET vg_base       = arg_val(1)
LET vg_modulo     = arg_val(2)
LET vg_codcia     = arg_val(3)
LET vg_codloc     = arg_val(4)
LET vm_num_fuente = arg_val(5)
LET vg_proceso    = 'cajp404'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()

--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

LET vm_tipo_fuente = 'EC'
INITIALIZE rm_j10.* TO NULL

CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, vm_tipo_fuente, vm_num_fuente) 
	RETURNING rm_j10.*
IF rm_j10.j10_num_fuente IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe comprobante de egresos de caja.','stop')
	CALL fl_mostrar_mensaje('No existe comprobante de egresos de caja.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_moneda(rm_j10.j10_moneda) RETURNING rm_g13.*
IF rm_g13.g13_moneda IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Moneda no existe.','stop')
	CALL fl_mostrar_mensaje('Moneda no existe.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_banco_general(rm_j10.j10_banco) RETURNING rm_g08.*
{
IF rm_g08.g08_banco IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Banco no existe.','stop')
	CALL fl_mostrar_mensaje('Banco no existe.','stop')
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
DEFINE moneda2		LIKE cajt011.j11_moneda
DEFINE cod_bco_tarj2	LIKE cajt011.j11_cod_bco_tarj
DEFINE num_ch_aut2	LIKE cajt011.j11_num_ch_aut
DEFINE num_cta_tarj2     LIKE cajt011.j11_num_cta_tarj
DEFINE valor2		LIKE cajt011.j11_valor
DEFINE num_rec2		SMALLINT

LET moneda2 = NULL
LET cod_bco_tarj2 = NULL
LET num_ch_aut2 = NULL
LET num_cta_tarj2 = NULL
LET valor2 = NULL
LET num_rec2 = NULL
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
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
LET tot_valor = 0
FOREACH q_fp INTO moneda, cod_bco_tarj, num_ch_aut, num_cta_tarj, valor 
	LET i = i + 1
	OUTPUT TO REPORT report_comprobante(moneda, cod_bco_tarj, num_ch_aut, 
					    num_cta_tarj, valor, i)
END FOREACH
IF i = 0 THEN
	LET tot_valor = 0
	OUTPUT TO REPORT report_comprobante(moneda2, cod_bco_tarj2,
				num_ch_aut2, num_cta_tarj2, valor2, i)
END IF
FINISH REPORT report_comprobante
FREE q_fp  

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
	--print '@';
	--print 'EACEROS - KOMATSUF'
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 50, 'COMPROBANTE DE EGRESOS DE CAJA No. ',
		fl_justifica_titulo('I', vm_num_fuente CLIPPED, 10)
	SKIP 1 LINES
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Banco', 15), ': ',
		         rm_g08.g08_nombre CLIPPED,
	      COLUMN 84, fl_justifica_titulo('I', 'Fecha', 15), ': ', 
			 DATE(rm_j10.j10_fecha_pro) USING 'dd-mm-yyyy' 
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Cuenta', 15), ': ',
	                 rm_j10.j10_numero_cta CLIPPED;
	IF rm_j10.j10_estado = 'E' THEN
		PRINT COLUMN 84, '*** ELIMINADO ***'
	ELSE
		PRINT COLUMN 84, 1 SPACES
	END IF
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
              COLUMN 81, '------------------------------------'

ON EVERY ROW
	IF moneda IS NOT NULL THEN
		LET paridad = calcula_paridad(moneda, rm_j10.j10_moneda)
		CALL fl_lee_banco_general(cod_bco_tarj) RETURNING r_g08.*
		LET n_bco_tarj = r_g08.g08_nombre
		PRINT COLUMN 10,  n_bco_tarj   CLIPPED,
		      COLUMN 37,  num_ch_aut   CLIPPED,  
		      COLUMN 54,  num_cta_tarj CLIPPED,
		      COLUMN 79,  moneda       CLIPPED,
		      COLUMN 83,  valor USING '#,###,###,##&.##',       
		      COLUMN 101, (valor * paridad) USING '#,###,###,##&.##'    
		LET tot_valor = tot_valor + (valor * paridad)
	END IF

ON LAST ROW
	IF num_rec > 0 THEN
		PRINT COLUMN 100, '-----------------'
		PRINT COLUMN 101, tot_valor USING '#,###,###,##&.##' 
	END IF
	print ASCII escape;
	print ASCII desact_comp
	
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
		--CALL fgl_winmessage(vg_producto,'No existe factor de conversión para esta moneda.','exclamation')
		CALL fl_mostrar_mensaje('No existe factor de conversión para esta moneda.','exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION
