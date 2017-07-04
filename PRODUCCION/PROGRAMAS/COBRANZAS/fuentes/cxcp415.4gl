------------------------------------------------------------------------------
-- Titulo           : cxcp415.4gl - Listado de Nota de Debito
-- Elaboracion      : 28-Dic-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp415 base módulo compañía localidad
-- 			[cliente] [nota debito] [número] [dividendo]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_r19		RECORD LIKE rept019.*
DEFINE rm_z20		RECORD LIKE cxct020.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 8 THEN   -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base		= arg_val(1)
LET vg_modulo		= arg_val(2)
LET vg_codcia		= arg_val(3)
LET vg_codloc		= arg_val(4)
LET rm_z20.z20_codcli	= arg_val(5)
LET rm_z20.z20_tipo_doc	= arg_val(6)
LET rm_z20.z20_num_doc	= arg_val(7)
LET rm_z20.z20_dividendo= arg_val(8)
LET vg_proceso 		= 'cxcp415'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
IF rm_z20.z20_tipo_doc <> 'ND' THEN
	CALL fl_mostrar_mensaje('El documento debe ser una Nota de Debito.','stop')
	EXIT PROGRAM
END IF
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE comando		VARCHAR(100)
DEFINE r_z01		RECORD LIKE cxct001.*

--LET rm_z20.z20_dividendo = 1
WHILE TRUE
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
	CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,rm_z20.z20_codcli,
					rm_z20.z20_tipo_doc, rm_z20.z20_num_doc,
					rm_z20.z20_dividendo)
		RETURNING rm_z20.*
	CALL fl_lee_cliente_general(rm_z20.z20_codcli) RETURNING r_z01.*
	IF r_z01.z01_codcli IS NULL THEN
		CALL fl_mostrar_mensaje('No existe el Cliente.','stop')
		EXIT PROGRAM
	END IF 
	LET rm_r19.r19_codcli = r_z01.z01_codcli
	LET rm_r19.r19_cedruc = r_z01.z01_num_doc_id
	LET rm_r19.r19_nomcli = r_z01.z01_nomcli
	LET rm_r19.r19_dircli = r_z01.z01_direccion1
	LET rm_r19.r19_telcli = r_z01.z01_telefono1
	START REPORT report_nota_deb TO PIPE comando
	OUTPUT TO REPORT report_nota_deb()
	FINISH REPORT report_nota_deb
END WHILE

END FUNCTION



REPORT report_nota_deb()
dEFINE valor_pag	DECIMAL(14,2)
DEFINE num_db		VARCHAR(10)
DEFINE label_letras	VARCHAR(100)
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
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra (12 cpi)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	--LET db 	    	= "\033W1"      # Activar doble ancho.
	--LET db_c    	= "\033W0"      # Cancelar doble ancho.
	LET valor_pag = rm_z20.z20_valor_cap + rm_z20.z20_valor_int
	LET num_db    = rm_z20.z20_num_doc
	SKIP 4 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 117, "No. ", num_db
	PRINT COLUMN 104, "FECHA EMI. N/D : ", rm_z20.z20_fecha_emi
			 			USING "dd/mmm/yyyy"
	PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre
	SKIP 1 LINES
	PRINT COLUMN 06,  "CLIENTE (", rm_r19.r19_codcli USING "&&&&&", ") : ",
						rm_r19.r19_nomcli
	PRINT COLUMN 06,  "CEDULA/RUC    : ", rm_r19.r19_cedruc
	PRINT COLUMN 06,  "DIRECCION     : ", rm_r19.r19_dircli
	PRINT COLUMN 06,  "TELEFONO      : ", rm_r19.r19_telcli
	PRINT COLUMN 06,  "OBSERVACION   : ", rm_z20.z20_referencia

	SKIP 2 LINES
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 14,  "DESCRIPCION",
	      COLUMN 121, " VALOR TOTAL"
	SKIP 2 LINES

ON EVERY ROW
	--OJO
	NEED 2 LINES
	PRINT COLUMN 13,  "VALOR BRUTO DE N/D",
	      COLUMN 118, valor_pag - rm_z20.z20_val_impto
				USING '###,###,##&.##'
	IF rm_z20.z20_val_impto > 0 THEN
		PRINT COLUMN 13,  "VALOR IMPUESTO DE N/D",
		      COLUMN 118, rm_z20.z20_val_impto	USING '###,###,##&.##'
	END IF
	
PAGE TRAILER
	--NEED 4 LINES
	LET label_letras = fl_retorna_letras(rm_z20.z20_moneda, valor_pag)
	PRINT COLUMN 06,  "SON: ", label_letras[1,90],
	      COLUMN 96,  "VALOR A PAGAR",
	      COLUMN 116, valor_pag		USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
