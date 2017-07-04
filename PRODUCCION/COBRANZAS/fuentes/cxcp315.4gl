--------------------------------------------------------------------------------
-- Titulo           : cxcp315.4gl - Consulta Análisis Detalle Cartera por Fecha
-- Elaboracion      : 18-Oct-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp315 base modulo compañía localidad
--			[moneda] [tipo_venc] [tipo_doc] [incluir_nc]
--			[incluir_sal] [fecha_cart] [area o 0] [tipcli o 0]
--			[tipcar o 0] [localidad o 0] [cliente o 0]
--			[[fecha_emi o vendedor]] [[flag = F o V]]
--			F = fecha_emi,		V = vendedor
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE rm_z60		RECORD LIKE cxct060.*
DEFINE rm_par 		RECORD
				moneda          LIKE gent013.g13_moneda,
				tit_mon         LIKE gent013.g13_nombre,
				ind_venc        CHAR(1),
				area_n          LIKE gent003.g03_areaneg,
				tit_area        LIKE gent003.g03_nombre,
				tipcli		LIKE gent012.g12_subtipo,
				tit_tipcli	LIKE gent012.g12_nombre,
				tipcar		LIKE gent012.g12_subtipo,
				tit_tipcar	LIKE gent012.g12_nombre,
				ind_doc		CHAR(1),
				localidad	LIKE gent002.g02_localidad,
				tit_localidad	LIKE gent002.g02_nombre,
				codcli		LIKE cxct001.z01_codcli,
				incluir_nc	CHAR(1),
				incluir_sal	CHAR(1),
				fecha_emi	DATE,
				fecha_cart	DATE
			END RECORD
DEFINE rm_par2 		RECORD
				fec_emi_ini	DATE,
				fec_emi_fin	DATE,
				fec_vcto_ini	DATE,
				fec_vcto_fin	DATE,
				incluir_tj	CHAR(1),
				origen		CHAR(1)
			END RECORD
DEFINE rm_doc		ARRAY[32766] OF RECORD
				cladoc		LIKE cxct020.z20_tipo_doc,
				numdoc		VARCHAR(16),
				locali		LIKE gent002.g02_localidad,
				nomcli		LIKE cxct001.z01_nomcli,
				fecha		DATE,
				valor		DECIMAL(12,2),
				saldo		DECIMAL(12,2)
			END RECORD
DEFINE num_doc, num_fav	INTEGER
DEFINE num_max_doc	INTEGER
DEFINE tot_val		DECIMAL(14,2)
DEFINE tot_sal		DECIMAL(14,2)
DEFINE vm_saldo_ant	DECIMAL(14,2)
DEFINE vm_fecha_ini	DATE
DEFINE vm_contab	CHAR(1)
DEFINE rm_cont		ARRAY[32766] OF RECORD
				b13_tipo_comp	LIKE ctbt013.b13_tipo_comp,
				b13_num_comp	LIKE ctbt013.b13_num_comp,
				b13_fec_proceso	LIKE ctbt013.b13_fec_proceso,
				b13_glosa	LIKE ctbt013.b13_glosa,
				val_db		LIKE ctbt013.b13_valor_base,
				val_cr		LIKE ctbt013.b13_valor_base,
				val_db_cr	DECIMAL(14,2)
			END RECORD
DEFINE rm_cob		ARRAY[32766] OF RECORD
				z23_tipo_trn	LIKE cxct023.z23_tipo_trn,
				z23_num_trn	LIKE cxct023.z23_num_trn,
				z22_fecha_emi	LIKE cxct022.z22_fecha_emi,
				z22_referencia	LIKE cxct022.z22_referencia,
				val_deu		DECIMAL(14,2),
				val_fav		DECIMAL(14,2),
				val_d_f		DECIMAL(14,2)
			END RECORD
DEFINE rm_aux		ARRAY[32766] OF RECORD
				loc		LIKE gent002.g02_localidad,
				tipo		LIKE cxct023.z23_tipo_favor,
				codcli		LIKE cxct023.z23_codcli
			END RECORD
DEFINE vm_num_cob	INTEGER
DEFINE vm_num_con	INTEGER
DEFINE vm_vendedor	LIKE rept001.r01_codigo



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp315.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 15 AND num_args() <> 17 AND
   num_args() <> 22
THEN
	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp315'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING rm_z60.*
IF rm_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
CREATE TEMP TABLE tempo_doc 
	(area_n		SMALLINT,
	 cladoc		CHAR(2),
	 numdoc		VARCHAR(16),
	 secuencia	SMALLINT,
	 codcli		INTEGER,
	 nomcli		VARCHAR(100),
	 fecha_emi	DATE,
	 fecha		DATE,
	 valor_doc	DECIMAL(12,2),
	 saldo_doc	DECIMAL(12,2),
	 cod_tran	CHAR(2),
	 num_tran	INTEGER,
	 localidad	SMALLINT,
	 tipo_doc	CHAR(1),
	 grupo_lin	CHAR(5))
LET num_max_doc = 32766
OPEN WINDOW w_cxcf315_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_par FROM "../forms/cxcf315_1"
DISPLAY FORM f_par
INITIALIZE rm_par.*, rm_par2.*, vm_fecha_ini, vm_vendedor TO NULL
LET rm_par.moneda      = rg_gen.g00_moneda_base
LET rm_par.ind_venc    = 'T'
LET rm_par.incluir_nc  = 'N'
LET rm_par.incluir_sal = 'N'
LET rm_par.ind_doc     = 'D'
LET rm_par.fecha_cart  = TODAY
LET vm_fecha_ini       = rm_z60.z60_fecha_carga
LET vm_contab          = 'C'
LET rm_par2.incluir_tj = 'S'
LET rm_par2.origen     = 'T'
IF num_args() >= 5 THEN
	CALL llamada_de_otro_programa()
END IF
CALL control_consulta()
DROP TABLE tempo_doc
CLOSE WINDOW w_cxcf315_1
EXIT PROGRAM

END FUNCTION



FUNCTION llamada_de_otro_programa()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE r_z01		RECORD LIKE cxct001.*

LET rm_par.moneda      = arg_val(5)
LET rm_par.ind_venc    = arg_val(6)
LET rm_par.ind_doc     = arg_val(7)
LET rm_par.incluir_nc  = arg_val(8)
LET rm_par.incluir_sal = arg_val(9)
LET rm_par.fecha_cart  = arg_val(10)
LET rm_par.area_n      = arg_val(11)
LET rm_par.tipcli      = arg_val(12)
LET rm_par.tipcar      = arg_val(13)
LET rm_par.localidad   = arg_val(14)
LET rm_par.codcli      = arg_val(15)
IF num_args() > 15 AND num_args() < 18 THEN
	CASE arg_val(17)
		WHEN 'F'
			LET rm_par.fecha_emi = arg_val(16)
		WHEN 'V'
			LET vm_vendedor      = arg_val(16)
	END CASE
END IF
IF num_args() >= 18 THEN
	LET rm_par2.incluir_tj = arg_val(18)
	IF arg_val(19) = 0 THEN
		LET rm_par2.fec_emi_ini  = NULL
		LET rm_par2.fec_emi_fin  = NULL
		LET rm_par2.fec_vcto_ini = arg_val(21)
		LET rm_par2.fec_vcto_fin = arg_val(22)
	END IF
	IF arg_val(21) = 0 THEN
		LET rm_par2.fec_emi_ini  = arg_val(19)
		LET rm_par2.fec_emi_fin  = arg_val(20)
		LET rm_par2.fec_vcto_ini = NULL
		LET rm_par2.fec_vcto_fin = NULL
	END IF
END IF
IF rm_par.ind_doc <> 'D' THEN
	LET rm_par.incluir_nc = 'N'
END IF
IF rm_par.ind_doc = 'F' THEN
	LET rm_par.tipcar = NULL
END IF
IF rm_par.area_n = 0 THEN
	LET rm_par.area_n = NULL
END IF
IF rm_par.tipcli = 0 THEN
	LET rm_par.tipcli = NULL
END IF
IF rm_par.tipcar = 0 THEN
	LET rm_par.tipcar = NULL
END IF
IF rm_par.localidad = 0 THEN
	LET rm_par.localidad = NULL
END IF
IF rm_par.codcli = 0 THEN
	LET rm_par.codcli = NULL
END IF
IF rm_par.area_n IS NOT NULL THEN
	CALL fl_lee_area_negocio(vg_codcia, rm_par.area_n) RETURNING r_g03.*
	IF r_g03.g03_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe area de negocio.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_area = r_g03.g03_nombre 
END IF
IF rm_par.tipcli IS NOT NULL THEN
	CALL fl_lee_subtipo_entidad('CL', rm_par.tipcli) RETURNING r_g12.*
	IF r_g12.g12_tiporeg IS NULL THEN
		CALL fl_mostrar_mensaje('No existe tipo de cliente.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_tipcli = r_g12.g12_nombre 
END IF
IF rm_par.tipcar IS NOT NULL THEN
	CALL fl_lee_subtipo_entidad('CR', rm_par.tipcar) RETURNING r_g12.*
	IF r_g12.g12_tiporeg IS NULL THEN
		CALL fl_mostrar_mensaje('No existe tipo de cartera.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_tipcar = r_g12.g12_nombre 
END IF
IF rm_par.localidad IS NOT NULL THEN
	CALL fl_lee_localidad(vg_codcia, rm_par.localidad) RETURNING r_g02.*
	IF r_g02.g02_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe localidad.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_localidad = r_g02.g02_nombre
END IF
IF rm_par.codcli IS NOT NULL THEN
	CALL fl_lee_cliente_general(rm_par.codcli) RETURNING r_z01.*
	IF r_z01.z01_codcli IS NULL THEN
		CALL fl_mostrar_mensaje('No existe codigo de cliente.', 'stop')
		EXIT PROGRAM
	END IF
END IF
DISPLAY BY NAME rm_par.*
IF rm_par.fecha_emi IS NOT NULL THEN
	IF rm_par.fecha_emi >= rm_par.fecha_cart THEN
		CALL fl_mostrar_mensaje('La fecha de emision debe ser menor que la fecha de cartera.', 'stop')
		EXIT PROGRAM
	END IF
END IF

END FUNCTION



FUNCTION control_consulta()
DEFINE i		SMALLINT

CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon = rm_mon.g13_nombre
DISPLAY BY NAME rm_par.tit_mon
DISPLAY 'TP'            TO tit_col1
DISPLAY 'Documento'     TO tit_col2
DISPLAY 'LC'		TO tit_col3
DISPLAY 'C l i e n t e' TO tit_col4
DISPLAY 'Fec. Vcto.'    TO tit_col5
DISPLAY 'Valor Doc.'	TO tit_col6
DISPLAY 'S a l d o'	TO tit_col7
WHILE TRUE
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	IF num_args() = 4 THEN
		CALL lee_parametros() 
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	CASE rm_par.ind_doc
		WHEN 'D'
			LET rm_orden[7]  = 'DESC'
			LET rm_orden[6]  = 'DESC'
			LET vm_columna_1 = 7
			LET vm_columna_2 = 6
		WHEN 'F'
			LET rm_orden[7]  = 'ASC'
			LET rm_orden[6]  = 'ASC'
			LET vm_columna_1 = 7
			LET vm_columna_2 = 6
		WHEN 'T'
			LET rm_orden[4]  = 'ASC'
			LET rm_orden[2]  = 'ASC'
			LET vm_columna_1 = 4
			LET vm_columna_2 = 2
	END CASE
	CALL genera_tabla_trabajo_detalle()
	IF num_doc > 0 THEN
		CALL muestra_detalle_documentos()
	END IF
	IF rm_par.fecha_emi IS NOT NULL THEN
		DROP TABLE tmp_sal_ini
	END IF
	DELETE FROM tempo_doc
	IF num_args() >= 5 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_mo		RECORD LIKE gent013.*
DEFINE r_se		RECORD LIKE gent012.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_mon		LIKE gent013.g13_nombre
DEFINE area_aux		LIKE gent003.g03_areaneg
DEFINE tit_area		LIKE gent003.g03_nombre
DEFINE tiporeg		LIKE gent012.g12_tiporeg
DEFINE subtipo		LIKE gent012.g12_subtipo
DEFINE nomtipo		LIKE gent012.g12_nombre
DEFINE nombre		LIKE gent011.g11_nombre
DEFINE fec		DATE
DEFINE num		SMALLINT
DEFINE resp		CHAR(6)

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(area_n) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
				RETURNING area_aux, tit_area
			IF area_aux IS NOT NULL THEN
				LET rm_par.area_n   = area_aux
				LET rm_par.tit_area = tit_area
 				DISPLAY BY NAME rm_par.area_n, rm_par.tit_area
			END IF
		END IF
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux, tit_mon, num
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda  = mon_aux
				LET rm_par.tit_mon = tit_mon
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF INFIELD(tipcli) THEN
			CALL fl_ayuda_subtipo_entidad('CL') 
				RETURNING tiporeg, subtipo, nomtipo, nombre
			IF nomtipo IS NOT NULL THEN
				LET rm_par.tipcli     = subtipo
				LET rm_par.tit_tipcli = nomtipo
				DISPLAY BY NAME rm_par.tipcli, rm_par.tit_tipcli
			END IF
		END IF
		IF INFIELD(tipcar) THEN
			CALL fl_ayuda_subtipo_entidad('CR') 
				RETURNING tiporeg, subtipo, nomtipo, nombre
			IF nomtipo IS NOT NULL THEN
				LET rm_par.tipcar     = subtipo
				LET rm_par.tit_tipcar = nomtipo
				DISPLAY BY NAME rm_par.tipcar, rm_par.tit_tipcar
			END IF
		END IF
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.localidad     = r_g02.g02_localidad
				LET rm_par.tit_localidad = r_g02.g02_nombre
				DISPLAY BY NAME rm_par.localidad,
						rm_par.tit_localidad
			END IF
		END IF
		IF INFIELD(codcli) THEN
			IF rm_par.localidad IS NULL THEN
				CALL fl_ayuda_cliente_general()
					RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
			ELSE
				CALL fl_ayuda_cliente_localidad(vg_codcia,
							rm_par.localidad)
					RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
			END IF
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par.codcli = r_z01.z01_codcli
				DISPLAY BY NAME rm_par.codcli
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_cart
		LET fec = rm_par.fecha_cart
	AFTER FIELD area_n
		IF rm_par.area_n IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area_n)
				RETURNING r_an.*
			IF r_an.g03_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe área de negocio', 'exclamation')
				NEXT FIELD area_n
			END IF
			LET rm_par.tit_area = r_an.g03_nombre
			DISPLAY BY NAME rm_par.tit_area
		ELSE
			LET rm_par.tit_area = NULL
			DISPLAY BY NAME rm_par.tit_area
		END IF
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_mo.*
			IF r_mo.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe moneda', 'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = r_mo.g13_nombre 
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			DISPLAY BY NAME rm_par.tit_mon
		END IF
	AFTER FIELD tipcli
		IF rm_par.tipcli IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CL', rm_par.tipcli)
				RETURNING r_se.*
			IF r_se.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo cliente', 'exclamation')
				NEXT FIELD tipcli
			END IF
			LET rm_par.tit_tipcli = r_se.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcli
		ELSE
			LET rm_par.tit_tipcli = NULL
			DISPLAY BY NAME rm_par.tit_tipcli
		END IF
	AFTER FIELD tipcar
		IF rm_par.tipcar IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR', rm_par.tipcar)
				RETURNING r_se.*
			IF r_se.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo cartera', 'exclamation')
				NEXT FIELD tipcar
			END IF
			LET rm_par.tit_tipcar = r_se.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcar
		ELSE
			LET rm_par.tit_tipcar = NULL
			DISPLAY BY NAME rm_par.tit_tipcar
		END IF
	AFTER FIELD localidad
		IF rm_par.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD localidad
			END IF
			LET rm_par.tit_localidad = r_g02.g02_nombre
			DISPLAY BY NAME rm_par.tit_localidad
		ELSE
			LET rm_par.tit_localidad = NULL
			DISPLAY BY NAME rm_par.tit_localidad
		END IF
	AFTER FIELD codcli
		IF rm_par.codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD codcli
			END IF
			IF rm_par.localidad IS NULL THEN
				CONTINUE INPUT
			END IF
			CALL fl_lee_cliente_localidad(vg_codcia,
							rm_par.localidad,
							r_z01.z01_codcli)
				RETURNING r_z02.*
			IF r_z02.z02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no está activado para la Localidad.', 'exclamation')
				NEXT FIELD codcli
			END IF
		END IF
	AFTER FIELD fecha_cart
		IF rm_par.fecha_cart IS NULL THEN
			LET rm_par.fecha_cart = fec
			DISPLAY BY NAME rm_par.fecha_cart
		END IF
	AFTER FIELD fecha_emi
		IF rm_par.fecha_emi IS NOT NULL THEN
			IF rm_par.fecha_emi <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser menor a la Fecha de Inicio de las COBRANZAS en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_emi
			END IF
		END IF
	AFTER INPUT 
		IF rm_par.codcli IS NOT NULL THEN
			LET rm_par.tipcli     = NULL
			LET rm_par.tit_tipcli = NULL
			DISPLAY BY NAME rm_par.tipcli, rm_par.tit_tipcli
		END IF
		IF rm_par.fecha_emi IS NOT NULL THEN
			IF rm_par.fecha_emi > rm_par.fecha_cart THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha Final.', 'exclamation')
				NEXT FIELD fecha_emi
			END IF
		END IF
		IF rm_par.ind_doc <> 'D' THEN
			LET rm_par.incluir_nc = 'N'
			DISPLAY BY NAME rm_par.incluir_nc
		END IF
		IF rm_par.ind_doc = 'F' THEN
			LET rm_par.tipcar     = NULL
			LET rm_par.tit_tipcar = NULL
			DISPLAY BY NAME rm_par.tipcar, rm_par.tit_tipcar
		END IF
END INPUT
IF NOT int_flag THEN
	CALL fl_hacer_pregunta('Desea filtros adicionales ?', 'No')
		RETURNING resp
	IF resp = 'Yes' THEN
		CALL lee_parametros2()
	END IF
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION lee_parametros2()

OPEN WINDOW w_cxcf315_6 AT 06, 12 WITH FORM "../forms/cxcf315_6" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET int_flag = 0
INPUT BY NAME rm_par2.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	AFTER FIELD fec_emi_ini
		IF rm_par2.fec_emi_ini IS NOT NULL THEN
			IF rm_par2.fec_emi_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de emisión inicial no puede ser mayor a la fecha de hoy.', 'exclamation')
				NEXT FIELD fec_emi_ini
			END IF
		END IF
	AFTER FIELD fec_emi_fin
		IF rm_par2.fec_emi_fin IS NOT NULL THEN
			IF rm_par2.fec_emi_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de emisión final no puede ser mayor a la fecha de hoy.', 'exclamation')
				NEXT FIELD fec_emi_fin
			END IF
		END IF
	AFTER INPUT
		IF rm_par2.fec_emi_ini IS NOT NULL THEN
			IF rm_par2.fec_emi_fin IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la fecha de emisión final.', 'exclamation')
				NEXT FIELD fec_emi_fin
			END IF
		END IF
		IF rm_par2.fec_emi_fin IS NOT NULL THEN
			IF rm_par2.fec_emi_ini IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la fecha de emisión inicial.', 'exclamation')
				NEXT FIELD fec_emi_fin
			END IF
		END IF
		IF rm_par2.fec_emi_ini > rm_par2.fec_emi_fin THEN
			CALL fl_mostrar_mensaje('La fecha de emisión inicial no puede ser mayor a la fecha de emisión final.', 'exclamation')
			NEXT FIELD fec_emi_ini
		END IF
		IF rm_par2.fec_vcto_ini IS NOT NULL THEN
			IF rm_par2.fec_vcto_fin IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la fecha de vencimiento final.', 'exclamation')
				NEXT FIELD fec_vcto_fin
			END IF
		END IF
		IF rm_par2.fec_vcto_fin IS NOT NULL THEN
			IF rm_par2.fec_vcto_ini IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la fecha de vencimiento inicial.', 'exclamation')
				NEXT FIELD fec_vcto_fin
			END IF
		END IF
		IF rm_par2.fec_vcto_ini IS NOT NULL AND
		   rm_par2.fec_vcto_fin IS NOT NULL
		THEN
			IF rm_par2.fec_vcto_ini > rm_par2.fec_vcto_fin THEN
				CALL fl_mostrar_mensaje('La fecha de vencimiento inicial no puede ser mayor a la fecha de vencimiento final.', 'exclamation')
				NEXT FIELD fec_vcto_ini
			END IF
		END IF
END INPUT
CLOSE WINDOW w_cxcf315_6
RETURN

END FUNCTION



FUNCTION genera_tabla_trabajo_detalle()

LET vm_saldo_ant = 0
LET num_doc      = 0
LET num_fav      = 0
IF rm_par.fecha_emi IS NOT NULL THEN
	SELECT z20_codcli cod_cli_s, z20_saldo_cap saldo_ini_cob,
		z20_origen tipo_s
		FROM cxct020
		WHERE z20_compania = 17
		INTO TEMP tmp_sal_ini2
END IF
CASE rm_par.ind_doc
	WHEN 'D'
		CALL obtener_documentos_deudores()
		IF num_doc = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
		END IF
	WHEN 'F'
		CALL obtener_documentos_a_favor()
		IF num_fav = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
		END IF
		LET num_doc = num_fav
	WHEN 'T'
		CALL obtener_documentos_deudores()
		IF num_doc = 0 THEN
			CALL fl_mostrar_mensaje('No se ha encontrado documentos deudores con saldo.', 'info')
		END IF
		CALL obtener_documentos_a_favor()
		IF num_fav = 0 THEN
			CALL fl_mostrar_mensaje('No se ha encontrado documentos a favor con saldo.', 'info')
		END IF
		LET num_doc = num_doc + num_fav
END CASE
IF rm_par.fecha_emi IS NOT NULL THEN
	SELECT cod_cli_s, NVL(SUM(saldo_ini_cob), 0) saldo_ini_cob
		FROM tmp_sal_ini2
		GROUP BY 1
		INTO TEMP tmp_sal_ini
	DROP TABLE tmp_sal_ini2
END IF

END FUNCTION



FUNCTION obtener_documentos_deudores()
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(4500)
DEFINE subquery1	CHAR(1500)
DEFINE subquery2	CHAR(500)
DEFINE subquery_nc	CHAR(1000)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3, expr4	VARCHAR(100)
DEFINE expr5, expr6	VARCHAR(100)
DEFINE expr7		VARCHAR(200)
DEFINE expr8, expr9	CHAR(400)
DEFINE expr10, expr11	CHAR(100)
DEFINE expr12		CHAR(200)
DEFINE expr13		CHAR(100)
DEFINE tabl1		VARCHAR(10)
DEFINE expr_int, tabl2	VARCHAR(20)
DEFINE signo		CHAR(2)

ERROR "Procesando documentos deudores con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2, expr3, expr4, expr5, expr6, expr7, expr8, expr9, tabl1,
		tabl2 TO NULL
IF rm_par.moneda IS NOT NULL THEN
	LET expr1 = '   AND z20_moneda     = "', rm_par.moneda, '"'
END IF
IF rm_par.area_n IS NOT NULL THEN
	LET expr2 = '   AND z20_areaneg    = ', rm_par.area_n
END IF
IF rm_par.tipcli IS NOT NULL THEN
	LET expr3 = '   AND z01_tipo_clte  = ', rm_par.tipcli
END IF
IF rm_par.tipcar IS NOT NULL THEN
	LET expr4 = '   AND z20_cartera    = ', rm_par.tipcar
END IF
IF rm_par.localidad IS NOT NULL THEN
	LET expr5 = '   AND z20_localidad  = ', rm_par.localidad
END IF
IF rm_par.codcli IS NOT NULL THEN
	LET expr6 = '   AND z20_codcli     = ', rm_par.codcli
END IF
CASE rm_par.ind_venc
	WHEN 'V'
		LET expr7 = '   AND z20_fecha_emi  <= "', rm_par.fecha_cart,'"',
			    '   AND z20_fecha_vcto  < "', rm_par.fecha_cart, '"'
	WHEN 'P'
		LET expr7 = '   AND z20_fecha_emi  <= "', rm_par.fecha_cart,'"',
			    '   AND z20_fecha_vcto >= "', rm_par.fecha_cart, '"'
	WHEN 'T'
		LET expr7 = '   AND z20_fecha_emi  <= "', rm_par.fecha_cart, '"'
END CASE
LET expr_int = ' INTO TEMP tmp_z20 '
IF vm_vendedor IS NOT NULL THEN
	LET tabl1 = ', rept019 '
	LET expr8 = '   AND r19_compania    = z20_compania ',
			'   AND r19_localidad   = z20_localidad ',
			'   AND r19_cod_tran    = z20_cod_tran ',
			'   AND r19_num_tran    = z20_num_tran ',
			'   AND r19_vendedor    = ', vm_vendedor
	LET tabl2 = ', talt061, talt023 '
	LET expr9 = '   AND t61_compania     = z20_compania ',
			'   AND t61_cod_vendedor = ', vm_vendedor,
			'   AND t23_compania     = t61_compania ',
			'   AND t23_localidad    = z20_localidad ',
			'   AND t23_num_factura  = z20_num_tran ',
			'   AND t23_cod_asesor   = t61_cod_asesor '
	LET expr_int = ' INTO TEMP t1 '
END IF
LET query = 'SELECT cxct020.*, z04_tipo ',
		' FROM cxct020, cxct004 ',
		' WHERE z20_compania   = ', vg_codcia,
			expr5 CLIPPED,
			expr6 CLIPPED,
			expr2 CLIPPED,
			expr1 CLIPPED,
			expr4 CLIPPED,
			expr7 CLIPPED,
		'   AND z04_tipo_doc   = z20_tipo_doc ',
		expr_int CLIPPED
PREPARE cons_z20 FROM query
EXECUTE cons_z20
IF vm_vendedor IS NOT NULL THEN
	LET query = 'SELECT t1.* FROM t1 ', tabl1 CLIPPED,
			' WHERE z20_areaneg     = 1 ',
			expr8 CLIPPED,
			' UNION ',
			'SELECT t1.* FROM t1 ', tabl2 CLIPPED,
			' WHERE z20_areaneg     = 2 ',
			expr9 CLIPPED,
			' INTO TEMP t2 '
	PREPARE cons_t2 FROM query
	EXECUTE cons_t2
	SELECT * FROM t2 INTO TEMP tmp_z20
	DROP TABLE t1
	DROP TABLE t2
END IF
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET subquery1 = '(SELECT z23_valor_cap + z23_valor_int + z23_saldo_cap + ',
			'z23_saldo_int ',
		' FROM cxct023, cxct022 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo ',
		'   AND z22_compania  = z23_compania ',
		'   AND z22_localidad = z23_localidad ',
		'   AND z22_codcli    = z23_codcli ',
		'   AND z22_tipo_trn  = z23_tipo_trn ',
		'   AND z22_num_trn   = z23_num_trn ',
		'   AND z22_fecing    = (SELECT MAX(z22_fecing) ',
					' FROM cxct023, cxct022 ',
					' WHERE z23_compania  = z20_compania ',
					'   AND z23_localidad = z20_localidad ',
					'   AND z23_codcli    = z20_codcli ',
					'   AND z23_tipo_doc  = z20_tipo_doc ',
					'   AND z23_num_doc   = z20_num_doc ',
					'   AND z23_div_doc   = z20_dividendo ',
					'   AND z22_compania  = z23_compania ',
					'   AND z22_localidad = z23_localidad ',
					'   AND z22_codcli    = z23_codcli ',
					'   AND z22_tipo_trn  = z23_tipo_trn ',
					'   AND z22_num_trn   = z23_num_trn ',
					'   AND z22_fecing   <= "', fecha, '"))'
LET subquery2 = ' (SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM cxct023 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo) '
LET subquery_nc = NULL
IF rm_par.incluir_nc = 'S' THEN
	LET subquery_nc = ' - CASE WHEN z20_tipo_doc = "FA" THEN ',
			' CASE WHEN z20_areaneg = 1 THEN ',
			' (SELECT NVL(SUM(z21_valor), 0) ',
				' FROM rept019, cxct021 ',
				' WHERE r19_compania   = z20_compania ',
				'   AND r19_localidad  = z20_localidad ',
				'   AND r19_tipo_dev   = z20_cod_tran ',
				'   AND r19_num_dev    = z20_num_tran ',
				'   AND z21_compania   = r19_compania ',
				'   AND z21_localidad  = r19_localidad ',
				'   AND z21_codcli     = z20_codcli ',
				'   AND z21_tipo_doc   = "NC" ',
				'   AND z21_fecha_emi <= z20_fecha_emi ',
				'   AND z21_cod_tran   = r19_cod_tran ',
				'   AND z21_num_tran   = r19_num_tran) ',
			' WHEN z20_areaneg = 2 THEN ',
			' (SELECT NVL(SUM(z21_valor), 0) ',
				' FROM cxct021 ',
				' WHERE z21_compania   = z20_compania ',
				'   AND z21_localidad  = z20_localidad ',
				'   AND z21_codcli     = z20_codcli ',
				'   AND z21_tipo_doc   = "NC" ',
				'   AND z21_fecha_emi <= z20_fecha_emi ',
				'   AND z21_areaneg    = z20_areaneg ',
				'   AND z21_cod_tran   = z20_cod_tran ',
				'   AND z21_num_tran   = z20_num_tran) ',
			' END ',
			' ELSE 0 ',
			' END '
END IF
LET expr10 = NULL
IF rm_par2.fec_emi_ini IS NOT NULL THEN
	LET expr10 = '   AND z20_fecha_emi  BETWEEN "', rm_par2.fec_emi_ini,
					'" AND "', rm_par2.fec_emi_fin, '"'
END IF
LET expr11 = NULL
IF rm_par2.fec_vcto_ini IS NOT NULL THEN
	LET expr11 = '   AND z20_fecha_vcto BETWEEN "', rm_par2.fec_vcto_ini,
					'" AND "', rm_par2.fec_vcto_fin, '"'
END IF
LET expr12 = NULL
IF rm_par2.incluir_tj = 'N' THEN
	LET expr12 = '   AND NOT EXISTS (SELECT g10_codcobr FROM gent010 ',
					' WHERE g10_codcobr = z01_codcli) '
END IF
LET expr13 = NULL
IF rm_par2.origen <> 'T' THEN
	LET expr13 = '   AND z20_origen = "', rm_par2.origen, '"'
END IF
LET query = 'INSERT INTO tempo_doc ',
		'SELECT z20_areaneg, z20_tipo_doc, z20_num_doc, z20_dividendo,',
			' z20_codcli, z01_nomcli, z20_fecha_emi,',
			' z20_fecha_vcto, z20_valor_cap + z20_valor_int, ',
			' NVL(', subquery1 CLIPPED, ', ',
			' CASE WHEN z20_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN z20_saldo_cap + z20_saldo_int - ',
					subquery2 CLIPPED,
				' ELSE z20_valor_cap + z20_valor_int',
			' END) ', subquery_nc CLIPPED, ' saldo_mov, ',
			' z20_cod_tran, z20_num_tran, z20_localidad, z04_tipo,',
			' z20_linea ',
		' FROM tmp_z20, gent002, cxct001 ',
		' WHERE g02_compania   = z20_compania ',
		'   AND g02_localidad  = z20_localidad ',
		'   AND z01_codcli     = z20_codcli ',
			expr3 CLIPPED,
			expr10 CLIPPED,
			expr11 CLIPPED,
			expr12 CLIPPED,
			expr13 CLIPPED
PREPARE stmnt1 FROM query
EXECUTE stmnt1
DROP TABLE tmp_z20
IF rm_par.incluir_nc = 'N' THEN
	LET signo = '='
ELSE
	LET signo = '<='
	IF rm_par.incluir_sal = 'S' THEN
		LET signo = '<'
	END IF
END IF
LET expr1 = NULL
IF rm_par.incluir_sal = 'N' OR signo = '<' THEN
	LET expr1 = ' WHERE saldo_doc ', signo CLIPPED, ' 0 '
END IF
LET expr2 = NULL
IF rm_par.fecha_emi IS NOT NULL THEN
	LET expr2 = ' WHERE'
	IF expr1 IS NOT NULL THEN
		LET expr2 = '    OR'
	END IF
	LET expr2 = expr2 CLIPPED, ' fecha_emi  < "', rm_par.fecha_emi, '"'
	INSERT INTO tmp_sal_ini2
		SELECT codcli, NVL(SUM(saldo_doc), 0), 'D'
			FROM tempo_doc
			WHERE fecha_emi < rm_par.fecha_emi
			GROUP BY 1
	SELECT NVL(SUM(saldo_ini_cob), 0) INTO vm_saldo_ant FROM tmp_sal_ini2
END IF
IF expr1 IS NOT NULL OR expr2 IS NOT NULL THEN
	LET query = 'DELETE FROM tempo_doc ',
			expr1 CLIPPED,
			expr2 CLIPPED
	PREPARE borrar FROM query
	EXECUTE borrar
END IF
SELECT COUNT(*) INTO num_doc FROM tempo_doc 
ERROR ' '

END FUNCTION



FUNCTION obtener_documentos_a_favor()
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(1000)
DEFINE subquery2	CHAR(400)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3, expr4	VARCHAR(100)
DEFINE expr5		VARCHAR(100)
DEFINE expr6, expr7	VARCHAR(100)
DEFINE sal_ant		DECIMAL(14,2)

ERROR "Procesando documentos a favor con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2, expr3, expr4, expr5 TO NULL
IF rm_par.moneda IS NOT NULL THEN
	LET expr1 = '   AND z21_moneda     = "', rm_par.moneda, '"'
END IF
IF rm_par.area_n IS NOT NULL THEN
	LET expr2 = '   AND z21_areaneg    = ', rm_par.area_n
END IF
IF rm_par.tipcli IS NOT NULL THEN
	LET expr3 = '   AND z01_tipo_clte  = ', rm_par.tipcli
END IF
IF rm_par.localidad IS NOT NULL THEN
	LET expr4 = '   AND z21_localidad  = ', rm_par.localidad
END IF
IF rm_par.codcli IS NOT NULL THEN
	LET expr5 = '   AND z21_codcli     = ', rm_par.codcli
END IF
LET query = 'SELECT cxct021.*, z04_tipo ',
		' FROM cxct021, cxct004 ',
		' WHERE z21_compania   = ', vg_codcia,
			expr4 CLIPPED,
			expr5 CLIPPED,
			expr2 CLIPPED,
			expr1 CLIPPED,
		'   AND z21_fecha_emi <= "', rm_par.fecha_cart, '"',
		'   AND z04_tipo_doc   = z21_tipo_doc ',
		' INTO TEMP tmp_z21 '
PREPARE cons_z21 FROM query
EXECUTE cons_z21
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET subquery1 = '(SELECT SUM(z23_valor_cap + z23_valor_int) ',
		' FROM cxct023, cxct022 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc ',
		'   AND z22_compania   = z23_compania ',
		'   AND z22_localidad  = z23_localidad ',
		'   AND z22_codcli     = z23_codcli ',
		'   AND z22_tipo_trn   = z23_tipo_trn ',
		'   AND z22_num_trn    = z23_num_trn ',
		'   AND z22_fecing     BETWEEN EXTEND(z21_fecha_emi, ',
						'YEAR TO SECOND)',
					 ' AND "', fecha, '")'
LET subquery2 = '(SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM cxct023 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc) '
LET expr6 = NULL
IF rm_par2.fec_emi_ini IS NOT NULL THEN
	LET expr6 = '   AND z21_fecha_emi  BETWEEN "', rm_par2.fec_emi_ini,
					'" AND "', rm_par2.fec_emi_fin, '"'
END IF
LET expr7 = NULL
IF rm_par2.incluir_tj = 'N' THEN
	LET expr7 = '   AND NOT EXISTS (SELECT g10_codcobr FROM gent010 ',
					' WHERE g10_codcobr = z01_codcli) '
END IF
LET query = 'INSERT INTO tempo_doc ',
		'SELECT z21_areaneg, z21_tipo_doc, z21_num_doc, 0,',
			' z21_codcli, z01_nomcli, DATE(z21_fecing),',
			' z21_fecha_emi, z21_valor * (-1), ',
			' NVL(CASE WHEN z21_fecha_emi > "', vm_fecha_ini, '"',
				' THEN z21_valor + ', subquery1 CLIPPED,
				' ELSE ', subquery2 CLIPPED, ' + z21_saldo - ',
					  subquery1 CLIPPED,
			' END, ',
			' CASE WHEN z21_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN z21_saldo - ', subquery2 CLIPPED,
				' ELSE z21_valor',
			' END) * (-1) saldo_mov, ',
			' z21_cod_tran, z21_num_tran, z21_localidad, z04_tipo,',
			' z21_linea ',
		' FROM tmp_z21, gent002, cxct001 ',
		' WHERE g02_compania   = z21_compania ',
		'   AND g02_localidad  = z21_localidad ',
		'   AND z01_codcli     = z21_codcli ',
			expr3 CLIPPED,
			expr6 CLIPPED,
			expr7 CLIPPED
PREPARE stmnt2 FROM query
EXECUTE stmnt2
DROP TABLE tmp_z21
LET expr1 = NULL
IF rm_par.incluir_sal = 'N' THEN
	LET expr1 = '   AND saldo_doc = 0 '
END IF
LET expr2 = NULL
IF rm_par.fecha_emi IS NOT NULL THEN
	LET expr2 = '    OR'
	IF expr1 IS NULL THEN
		LET expr2 = '   AND'
	END IF
	LET expr2 = expr2 CLIPPED, ' fecha_emi < "', rm_par.fecha_emi, '"'
	INSERT INTO tmp_sal_ini2
		SELECT codcli, NVL(SUM(saldo_doc), 0) sal_f, 'F'
			FROM tempo_doc
			WHERE tipo_doc  = "F"
			  AND fecha_emi < rm_par.fecha_emi
			GROUP BY 1
	SELECT NVL(SUM(saldo_ini_cob), 0) INTO sal_ant
		FROM tmp_sal_ini2
		WHERE tipo_s = 'F'
	LET vm_saldo_ant = vm_saldo_ant + sal_ant
END IF
IF expr1 IS NOT NULL OR expr2 IS NOT NULL THEN
	LET query = 'DELETE FROM tempo_doc ',
			' WHERE tipo_doc   = "F" ',
			expr1 CLIPPED,
			expr2 CLIPPED
	PREPARE borrar2 FROM query
	EXECUTE borrar2
END IF
SELECT COUNT(*) INTO num_fav FROM tempo_doc WHERE tipo_doc = 'F'
ERROR ' '

END FUNCTION



FUNCTION muestra_detalle_documentos()
DEFINE tit_venc		CHAR(20)
DEFINE query		CHAR(300)
DEFINE i, col		INTEGER
DEFINE dias		SMALLINT
DEFINE r_aux		ARRAY[32766] OF RECORD
				area_n		LIKE cxct020.z20_areaneg,
				codcli		LIKE cxct001.z01_codcli,
				numdoc		LIKE cxct020.z20_num_doc,
				dividendo	LIKE cxct020.z20_dividendo,
				cod_tran	LIKE cxct020.z20_cod_tran,
				num_tran	LIKE cxct020.z20_num_tran,
				tipo		LIKE cxct004.z04_tipo,
				grupo_lin	LIKE cxct020.z20_linea
			END RECORD

WHILE TRUE
	LET query = 'SELECT cladoc, numdoc, localidad, nomcli, fecha, ',
			'valor_doc, saldo_doc, area_n, codcli, numdoc, ',
			'secuencia, cod_tran, num_tran, tipo_doc, grupo_lin ',
			' FROM tempo_doc ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cond FROM query
	DECLARE q_cond CURSOR FOR cond
	LET i       = 1
	LET tot_val = 0
	LET tot_sal = 0
	FOREACH q_cond INTO rm_doc[i].*, r_aux[i].* 
		IF r_aux[i].tipo = 'D' THEN
			LET rm_doc[i].numdoc = rm_doc[i].numdoc CLIPPED, '-',
						r_aux[i].dividendo USING '<<&&'
		END IF
		LET tot_val = tot_val + rm_doc[i].valor
		LET tot_sal = tot_sal + rm_doc[i].saldo
		LET i       = i + 1
		IF i > num_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i       = i - 1
	LET tot_sal = tot_sal + vm_saldo_ant
	DISPLAY BY NAME vm_saldo_ant, tot_val, tot_sal
	CALL mostrar_contadores_det(0, num_doc)
	CALL set_count(num_doc)
	LET int_flag = 0
	DISPLAY ARRAY rm_doc TO rm_doc.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			IF r_aux[i].cod_tran IS NULL THEN
				CONTINUE DISPLAY
			END IF	
			CALL ver_factura_devolucion(i, r_aux[i].area_n,
							r_aux[i].cod_tran,
							r_aux[i].num_tran,
							r_aux[i].tipo)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL muestra_movimientos_documento_cxc(vg_codcia,
					rm_doc[i].locali, r_aux[i].codcli,
					rm_doc[i].cladoc, r_aux[i].numdoc,
					r_aux[i].dividendo, r_aux[i].area_n)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_estado_cuenta(r_aux[i].codcli)
			LET int_flag = 0
		ON KEY(F8)
			LET i = arr_curr()
			CALL ver_documento(r_aux[i].codcli, r_aux[i].numdoc,
					r_aux[i].dividendo, r_aux[i].tipo, i)
			LET int_flag = 0
		ON KEY(F9)
			IF rm_par.ind_doc <> 'T' THEN
				CONTINUE DISPLAY
			END IF
			LET i = arr_curr()
			CALL control_contabilizacion(rm_doc[i].locali,
						r_aux[i].codcli,r_aux[i].area_n,
						r_aux[i].grupo_lin)
			LET int_flag = 0
		ON KEY(F10)
			CALL control_imprimir()
			LET int_flag = 0
		ON KEY(F11)
			CALL control_archivo()
			LET int_flag = 0
		ON KEY(CONTROL-W)
			CALL control_archivo_indicador()
			LET int_flag = 0
		ON KEY(CONTROL-X)
			CALL control_archivo_crediticio()
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
			IF rm_par.ind_doc = 'T' THEN
				CALL dialog.keysetlabel("F9","Contabilización")
			ELSE
				CALL dialog.keysetlabel("F9", "")
			END IF
			--#CALL dialog.keysetlabel("CONTROL-W","Arch. Indicador")
			--#CALL dialog.keysetlabel("CONTROL-X","Arch. Crediticio")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			IF rm_doc[i].fecha < rm_par.fecha_cart THEN
				LET dias = rm_par.fecha_cart - rm_doc[i].fecha
				LET tit_venc = 'VENCIDO ', dias USING "<<<<&",
					       ' DIAS'
			ELSE
				LET dias = rm_doc[i].fecha - rm_par.fecha_cart
				LET tit_venc = 'HOY SE VENCE'
				IF dias > 0 THEN
					LET tit_venc = 'POR VENCER ',
							dias USING "<<<&",
							' DIAS'
				END IF
			END IF
			IF r_aux[i].tipo = 'D' AND rm_doc[i].saldo = 0 THEN
				LET dias = rm_doc[i].fecha - rm_par.fecha_cart
				LET tit_venc = 'CANCELADO ', dias USING "<<<<&",
					       ' DIAS'
			END IF
			IF r_aux[i].tipo = 'F' THEN
				LET dias = rm_par.fecha_cart - rm_doc[i].fecha
				LET tit_venc = 'EMITIDO ', dias USING "<<<<&",
					       ' DIAS'
				DISPLAY 'Fecha Emi.' TO tit_col5
				IF rm_doc[i].cladoc = 'NC' THEN
					CALL dialog.keysetlabel("F5",
							"Ver Devolución")
				ELSE
					CALL dialog.keysetlabel("F5", "")
				END IF
			ELSE
				DISPLAY 'Fec. Vcto.' TO tit_col5
				IF rm_doc[i].cladoc = 'FA' THEN
					CALL dialog.keysetlabel("F5",
							"Ver Factura")
				ELSE
					CALL dialog.keysetlabel("F5", "")
				END IF
			END IF
			DISPLAY BY NAME tit_venc
			CALL mostrar_contadores_det(i, num_doc)
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
CALL mostrar_contadores_det(0, num_doc)
	
END FUNCTION



FUNCTION mostrar_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_movimientos_documento_cxc(codcia, codloc, codcli, tipo_doc,
						num_doc, dividendo, areaneg)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE max_rows, i, col	SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_sql		VARCHAR(400)
DEFINE r_aux		ARRAY[100] OF RECORD
				loc		LIKE gent002.g02_localidad,
				tipo		LIKE cxct023.z23_tipo_favor
			END RECORD
DEFINE r_pdoc		ARRAY[100] OF RECORD
				z23_tipo_trn	LIKE cxct023.z23_tipo_trn,
				z23_num_trn	LIKE cxct023.z23_num_trn,
				z22_fecha_emi	LIKE cxct022.z22_fecha_emi,
				z22_referencia	LIKE cxct022.z22_referencia,
				val_pago	DECIMAL(14,2)
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE expr_loc		VARCHAR(50)
DEFINE expr_fec		VARCHAR(100)
DEFINE fecha1, fecha2	LIKE cxct022.z22_fecing

LET max_rows  = 100
LET num_rows2 = 16
LET num_cols  = 76
IF vg_gui = 0 THEN
	LET num_rows2 = 15
	LET num_cols  = 77
END IF
OPEN WINDOW w_mdoc AT 06, 03 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf315_2 FROM "../forms/cxcf315_2"
ELSE
	OPEN FORM f_cxcf315_2 FROM "../forms/cxcf315_2c"
END IF
DISPLAY FORM f_cxcf315_2
--#DISPLAY 'TP'                  TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'Fecha Pago'          TO tit_col3
--#DISPLAY 'R e f e r e n c i a' TO tit_col4 
--#DISPLAY 'V a l o r'           TO tit_col5
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli, 'exclamation')
	CLOSE WINDOW w_mdoc
	RETURN
END IF
DISPLAY BY NAME r_cli.z01_codcli, r_cli.z01_nomcli
CLEAR z23_tipo_doc, z23_num_doc, z23_div_doc
IF dividendo <> 0 THEN
	DISPLAY tipo_doc, num_doc, dividendo
	     TO z23_tipo_doc, z23_num_doc, z23_div_doc
ELSE
	DISPLAY tipo_doc, num_doc TO z23_tipo_doc, z23_num_doc
END IF
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'ASC'
LET columna_1  = 3
LET columna_2  = 1
LET expr_loc   = ' '
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND z23_localidad = ', codloc
END IF
LET fecha2   = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr_fec = '   AND z22_fecing    <= "', fecha2, '"'
IF rm_par.fecha_emi IS NOT NULL THEN
	LET fecha1   = EXTEND(rm_par.fecha_emi, YEAR TO SECOND)
	LET expr_fec = '   AND z22_fecing    BETWEEN "', fecha1,
					      '" AND "', fecha2, '"'
END IF
LET expr_sql = '   AND z23_tipo_doc   = ? ',
		'   AND z23_num_doc    = ? ',
		'   AND z23_div_doc    = ? '
IF dividendo = 0 THEN
	LET expr_sql = '   AND z23_tipo_favor = ? ',
			'   AND z23_doc_favor  = ? '
END IF
WHILE TRUE
	LET query = 'SELECT z23_tipo_trn, z23_num_trn, z22_fecha_emi, ',
			'   z22_referencia, z23_valor_cap + z23_valor_int, ',
			'   z23_localidad, z23_tipo_favor ',
	        	' FROM cxct023, cxct022 ',
			' WHERE z23_compania   = ? ', 
			expr_loc CLIPPED,
		        '   AND z23_codcli     = ? ',
			expr_sql CLIPPED,
			'   AND z22_compania   = z23_compania ',
			'   AND z22_localidad  = z23_localidad ',
			'   AND z22_codcli     = z23_codcli ',
			'   AND z22_tipo_trn   = z23_tipo_trn  ',
			'   AND z22_num_trn    = z23_num_trn ',
			expr_fec CLIPPED,
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE dpgc FROM query
	DECLARE q_dpgc CURSOR FOR dpgc
	LET i        = 1
	LET tot_pago = 0
	IF dividendo <> 0 THEN
		OPEN q_dpgc USING codcia, codcli, tipo_doc, num_doc, dividendo
	ELSE
		OPEN q_dpgc USING codcia, codcli, tipo_doc, num_doc
	END IF
	WHILE TRUE
		FETCH q_dpgc INTO r_pdoc[i].*, r_aux[i].*
		IF STATUS = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_pago = tot_pago + r_pdoc[i].val_pago 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dpgc
	FREE q_dpgc
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Documento no tiene movimientos.','exclamation')
		CLOSE WINDOW w_mdoc
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_pago
	DISPLAY ARRAY r_pdoc TO r_pdoc.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_muestra_forma_pago_caja(codcia, r_aux[i].loc,
							areaneg, codcli,
							r_pdoc[i].z23_tipo_trn,
							r_pdoc[i].z23_num_trn) 
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento_tran(codcia, codcli,
				r_pdoc[i].z23_tipo_trn, r_pdoc[i].z23_num_trn,
				r_aux[i].*)
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_det(i, num_rows)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> columna_1 THEN
		LET columna_2          = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1          = col 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_mdoc

END FUNCTION



FUNCTION control_contabilizacion(localidad, cod_cli, areaneg, grupo)
DEFINE localidad	LIKE gent002.g02_localidad
DEFINE cod_cli		LIKE cxct001.z01_codcli
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE grupo		LIKE cxct020.z20_linea

OPEN WINDOW w_ran AT 07, 20 WITH FORM "../forms/cxcf315_3" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET int_flag = 0
INPUT BY NAME vm_contab
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	AFTER INPUT
		IF vm_contab = 'M' THEN
			IF rm_par.codcli IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Solo puede escojer esta opcion si es que se han seleccionado todos los documentos.', 'info')
				LET vm_contab = 'C'
				DISPLAY BY NAME vm_contab
				NEXT FIELD vm_contab
			END IF
		END IF
END INPUT
CLOSE WINDOW w_ran
IF int_flag THEN
	RETURN
END IF
CASE vm_contab
	WHEN 'B'
		CALL ver_contabilizacion(localidad, cod_cli, areaneg, grupo)
	OTHERWISE
		CALL cobranzas_vs_contabilidad(localidad, cod_cli, areaneg,
						grupo)
END CASE

END FUNCTION



FUNCTION ver_contabilizacion(localidad, cod_cli, areaneg, grupo)
DEFINE localidad	LIKE gent002.g02_localidad
DEFINE cod_cli		LIKE cxct001.z01_codcli
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE grupo		LIKE cxct020.z20_linea
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_b41		RECORD LIKE ctbt041.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_cont		ARRAY[32766] OF RECORD
				b13_tipo_comp	LIKE ctbt013.b13_tipo_comp,
				b13_num_comp	LIKE ctbt013.b13_num_comp,
				b13_fec_proceso	LIKE ctbt013.b13_fec_proceso,
				b13_glosa	LIKE ctbt013.b13_glosa,
				val_db		LIKE ctbt013.b13_valor_base,
				val_cr		LIKE ctbt013.b13_valor_base
			END RECORD
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE max_rows, i, col	INTEGER
DEFINE num_rows		INTEGER
DEFINE tot_val_db	DECIMAL(14,2)
DEFINE tot_val_cr	DECIMAL(14,2)
DEFINE sal_ini_cob	DECIMAL(14,2)
DEFINE sal_ini_con	DECIMAL(14,2)
DEFINE saldo_cont	DECIMAL(14,2)
DEFINE saldo_cob	DECIMAL(14,2)
DEFINE v_saldo_cont	DECIMAL(14,2)
DEFINE v_saldo_cob	DECIMAL(14,2)
DEFINE val_des		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fecha_antes	DATE

LET max_rows  = num_max_doc
LET num_rows2 = 21
LET num_cols  = 80
IF vg_gui = 0 THEN
	LET num_rows2 = 20
	LET num_cols  = 77
END IF
OPEN WINDOW w_cont AT 03, 02 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf315_4 FROM "../forms/cxcf315_4"
ELSE
	OPEN FORM f_cxcf315_4 FROM "../forms/cxcf315_4c"
END IF
DISPLAY FORM f_cxcf315_4
--#DISPLAY 'TP'		TO tit_col1 
--#DISPLAY 'Número'	TO tit_col2 
--#DISPLAY 'Fecha'	TO tit_col3
--#DISPLAY 'G l o s a'	TO tit_col4 
--#DISPLAY 'Débito'	TO tit_col5
--#DISPLAY 'Crédito'	TO tit_col6
CALL fl_lee_cliente_general(cod_cli) RETURNING r_z01.*
IF r_z01.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || cod_cli, 'exclamation')
	CLOSE WINDOW w_cont
	RETURN
END IF
CALL fl_lee_area_negocio(vg_codcia, areaneg) RETURNING r_g03.*
INITIALIZE r_b41.* TO NULL
SELECT * INTO r_b41.* FROM ctbt041
	WHERE b41_compania    = vg_codcia
	  AND b41_localidad   = localidad
	  AND b41_modulo      = r_g03.g03_modulo
	  AND b41_grupo_linea = grupo
IF r_b41.b41_cxc_mb IS NULL THEN
	CALL fl_mostrar_mensaje('No existe auxiliar contable para el módulo de Cobranzas.', 'exclamation')
	CLOSE WINDOW w_cont
	RETURN
END IF
LET fecha_ini = rm_par.fecha_emi
LET fecha_fin = rm_par.fecha_cart
IF fecha_ini IS NULL THEN
	LET fecha_ini = vm_fecha_ini + 1 UNITS DAY
END IF
LET fecha_antes = fecha_ini - 1 UNITS DAY
DISPLAY BY NAME r_z01.z01_codcli, r_z01.z01_nomcli, fecha_ini, fecha_fin,
		rm_par.moneda, rm_par.tit_mon
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'ASC'
LET columna_1  = 3
LET columna_2  = 4
ERROR "Procesando Movimientos en Contabilidad . . . espere por favor." ATTRIBUTE(NORMAL)
SELECT UNIQUE z02_aux_clte_mb cuenta FROM cxct002 INTO TEMP tmp_cta
SELECT * FROM tmp_cta WHERE cuenta = r_b41.b41_cxc_mb
IF STATUS = NOTFOUND THEN
	INSERT INTO tmp_cta VALUES (r_b41.b41_cxc_mb)
END IF
LET query = 'SELECT * FROM ctbt013 ',
		' WHERE b13_compania    = ', vg_codcia,
		'   AND b13_cuenta     IN (SELECT UNIQUE cuenta FROM tmp_cta) ',
		'   AND b13_fec_proceso BETWEEN "', vm_fecha_ini,
					 '" AND "', fecha_fin, '"',
		'   AND b13_codcli      = ', r_z01.z01_codcli,
		' INTO TEMP tmp_b13'
PREPARE exec_b13_2 FROM query
EXECUTE exec_b13_2
DROP TABLE tmp_cta
LET query = 'SELECT NVL(SUM(b13_valor_base), 0) saldo_ini ',
		' FROM ctbt012, tmp_b13 ',
		' WHERE b12_compania    = ', vg_codcia,
		'   AND b12_estado      = "M" ',
		'   AND b12_moneda      = "', rm_par.moneda, '"',
		'   AND b13_compania    = b12_compania ',
		'   AND b13_tipo_comp   = b12_tipo_comp ',
		'   AND b13_num_comp    = b12_num_comp ',
		'   AND b13_fec_proceso <= "', fecha_antes, '"',
		' INTO TEMP t_sum'
PREPARE cons_sum FROM query
EXECUTE cons_sum
SELECT * INTO sal_ini_con FROM t_sum
DROP TABLE t_sum
LET sal_ini_cob = 0
IF rm_par.fecha_emi IS NOT NULL THEN
	SELECT NVL(saldo_ini_cob, 0) INTO sal_ini_cob
		FROM tmp_sal_ini
		WHERE cod_cli_s = r_z01.z01_codcli
END IF
DISPLAY BY NAME sal_ini_cob, sal_ini_con
WHILE TRUE
	LET query = 'SELECT b13_tipo_comp, b13_num_comp, b13_fec_proceso, ',
			' b13_glosa, NVL(CASE WHEN b13_valor_base >= 0 THEN ',
			' b13_valor_base END, 0), ',
			' NVL(CASE WHEN b13_valor_base < 0 THEN ',
			' b13_valor_base END, 0) ',
			' FROM ctbt012, tmp_b13 ',
			' WHERE b12_compania    = ', vg_codcia,
			'   AND b12_estado      = "M" ',
			'   AND b12_moneda      = "', rm_par.moneda, '"',
			'   AND b13_compania    = b12_compania ',
			'   AND b13_tipo_comp   = b12_tipo_comp ',
			'   AND b13_num_comp    = b12_num_comp ',
			'   AND b13_fec_proceso > "', fecha_antes, '"',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE mov_con FROM query
	DECLARE q_mov_con CURSOR FOR mov_con
	ERROR ' '
	LET i          = 1
	LET tot_val_db = 0
	LET tot_val_cr = 0
	FOREACH q_mov_con INTO r_cont[i].*
		LET tot_val_db = tot_val_db + r_cont[i].val_db 
		LET tot_val_cr = tot_val_cr + r_cont[i].val_cr 
		LET i          = i + 1
		IF i > max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	IF i = max_rows THEN
		CALL fl_mostrar_mensaje('Solo se mostraran un maximo de ' || i || ' líneas de detalle ya que la aplicación solo soporta esta cantidad.', 'info')
		LET query = 'SELECT b13_glosa, NVL(CASE WHEN b13_valor_base ',
				'>= 0 THEN ',
				' b13_valor_base END, 0), ',
				' NVL(CASE WHEN b13_valor_base < 0 THEN ',
				' b13_valor_base END, 0) ',
				' INTO tot_val_db, tot_val_cr ',
				' FROM ctbt012, tmp_b13 ',
				' WHERE b12_compania    = ', vg_codcia,
				'   AND b12_estado      = "M" ',
				'   AND b12_moneda      = "', rm_par.moneda,'"',
				'   AND b13_compania    = b12_compania ',
				'   AND b13_tipo_comp   = b12_tipo_comp ',
				'   AND b13_num_comp    = b12_num_comp ',
				'   AND b13_fec_proceso > "', fecha_antes, '"'
		PREPARE cons_sum_tot FROM query
		EXECUTE cons_sum_tot
	END IF
	LET saldo_cont = sal_ini_con + tot_val_db + tot_val_cr
	LET num_rows   = i - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Cliente no tiene movimientos en contabiliadad.','exclamation')
		CLOSE WINDOW w_cont
		RETURN
	END IF
	LET saldo_cob = tot_sal
	IF rm_par.codcli IS NULL THEN
		SELECT NVL(SUM(saldo_doc), 0) INTO saldo_cob
			FROM tempo_doc
			WHERE codcli = r_z01.z01_codcli
		LET saldo_cob = saldo_cob + sal_ini_cob
	END IF
	LET v_saldo_cont = saldo_cont
	IF v_saldo_cont < 0 THEN
		LET v_saldo_cont = v_saldo_cont * (-1)
	END IF
	LET v_saldo_cob = saldo_cob
	IF v_saldo_cob < 0 THEN
		LET v_saldo_cob = v_saldo_cob * (-1)
	END IF
	IF saldo_cont > saldo_cob THEN
		LET val_des = v_saldo_cont - v_saldo_cob
	ELSE
		LET val_des = v_saldo_cob - v_saldo_cont
	END IF
	DISPLAY BY NAME tot_val_db, tot_val_cr, saldo_cont, saldo_cob, val_des
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY ARRAY r_cont TO r_cont.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_diario_contable(r_cont[i].b13_tipo_comp,
						r_cont[i].b13_num_comp)
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_det(i, num_rows)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> columna_1 THEN
		LET columna_2          = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1          = col 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
DROP TABLE tmp_b13
CLOSE WINDOW w_cont

END FUNCTION



FUNCTION cobranzas_vs_contabilidad(localidad, cod_cli, areaneg, grupo)
DEFINE localidad	LIKE gent002.g02_localidad
DEFINE cod_cli		LIKE cxct001.z01_codcli
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE grupo		LIKE cxct020.z20_linea
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_b41		RECORD LIKE ctbt041.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE fecha1, fecha2	LIKE cxct022.z22_fecing
DEFINE max_rows, i, col	INTEGER
DEFINE lim		INTEGER
DEFINE tot_val_deu	DECIMAL(14,2)
DEFINE tot_val_fav	DECIMAL(14,2)
DEFINE tot_val_db	DECIMAL(14,2)
DEFINE tot_val_cr	DECIMAL(14,2)
DEFINE sal_ini_cob	DECIMAL(14,2)
DEFINE sal_ini_con	DECIMAL(14,2)
DEFINE saldo_cont	DECIMAL(14,2)
DEFINE saldo_cob	DECIMAL(14,2)
DEFINE v_saldo_cont	DECIMAL(14,2)
DEFINE v_saldo_cob	DECIMAL(14,2)
DEFINE val_des		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_fec		VARCHAR(200)
DEFINE expr_cli1	VARCHAR(100)
DEFINE expr_cli2	VARCHAR(100)
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fecha_antes	DATE
DEFINE sig_cob, sig_con	SMALLINT
DEFINE p1, p2, p3, p4	INTEGER

LET num_rows2 = 22
LET num_cols  = 80
IF vg_gui = 0 THEN
	LET num_rows2 = 20
	LET num_cols  = 77
END IF
OPEN WINDOW w_cob_cont AT 03, 02 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf315_5 FROM "../forms/cxcf315_5"
ELSE
	OPEN FORM f_cxcf315_5 FROM "../forms/cxcf315_5c"
END IF
DISPLAY FORM f_cxcf315_5
--#DISPLAY 'TP'		TO tit_col1 
--#DISPLAY 'Número'	TO tit_col2 
--#DISPLAY 'Fecha Pago'	TO tit_col3
--#DISPLAY 'Referencia'	TO tit_col4
--#DISPLAY 'Deudor'	TO tit_col5
--#DISPLAY 'Acreedor'	TO tit_col6
--#DISPLAY 'Saldo Cob.'	TO tit_col7
--#DISPLAY 'TP'		TO tit_col8 
--#DISPLAY 'Número'	TO tit_col9 
--#DISPLAY 'Fecha'	TO tit_col10
--#DISPLAY 'G l o s a'	TO tit_col11 
--#DISPLAY 'Débito'	TO tit_col12
--#DISPLAY 'Crédito'	TO tit_col13
--#DISPLAY 'Saldo Con.'	TO tit_col14
CALL fl_lee_cliente_general(cod_cli) RETURNING r_z01.*
IF r_z01.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || cod_cli, 'exclamation')
	CLOSE WINDOW w_cob_cont
	RETURN
END IF
CALL fl_lee_area_negocio(vg_codcia, areaneg) RETURNING r_g03.*
INITIALIZE r_b41.* TO NULL
SELECT * INTO r_b41.* FROM ctbt041
	WHERE b41_compania    = vg_codcia
	  AND b41_localidad   = localidad
	  AND b41_modulo      = r_g03.g03_modulo
	  AND b41_grupo_linea = grupo
IF r_b41.b41_cxc_mb IS NULL THEN
	CALL fl_mostrar_mensaje('No existe auxiliar contable para el módulo de Cobranzas.', 'exclamation')
	CLOSE WINDOW w_cob_cont
	RETURN
END IF
LET fecha_ini = rm_par.fecha_emi
LET fecha_fin = rm_par.fecha_cart
IF fecha_ini IS NULL THEN
	LET fecha_ini = vm_fecha_ini + 1 UNITS DAY
END IF
LET fecha_antes = fecha_ini - 1 UNITS DAY
SELECT UNIQUE z02_aux_clte_mb cuenta FROM cxct002 INTO TEMP tmp_cta
SELECT * FROM tmp_cta WHERE cuenta = r_b41.b41_cxc_mb
IF STATUS = NOTFOUND THEN
	INSERT INTO tmp_cta VALUES (r_b41.b41_cxc_mb)
END IF
IF vm_contab <> 'M' THEN
	DISPLAY BY NAME r_z01.z01_codcli, r_z01.z01_nomcli
	LET expr_cli1 = '   AND z23_codcli     = ', r_z01.z01_codcli
	LET expr_cli2 = '   AND b13_codcli      = ', r_z01.z01_codcli
ELSE
	DISPLAY "*** TODOS LOS CLIENTES ***" TO z01_nomcli
	LET expr_cli1 = NULL
	LET expr_cli2 = NULL
END IF
DISPLAY BY NAME fecha_ini, fecha_fin, rm_par.moneda, rm_par.tit_mon
LET fecha2   = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr_fec = '   AND z22_fecing    <= "', fecha2, '"'
IF rm_par.fecha_emi IS NOT NULL THEN
	LET fecha1   = EXTEND(rm_par.fecha_emi, YEAR TO SECOND)
	LET expr_fec = '   AND z22_fecing    BETWEEN "', fecha1,
					      '" AND "', fecha2, '"'
END IF
ERROR "Procesando Movimientos en Cobranzas . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT z23_tipo_trn, z23_num_trn, z22_fecha_emi, z22_referencia, ',
			' CASE WHEN z23_valor_cap + z23_valor_int > 0 ',
				' THEN z23_valor_cap + z23_valor_int ',
				' ELSE 0 ',
			' END valor_d, ',
			' CASE WHEN z23_valor_cap + z23_valor_int < 0 ',
				' THEN z23_valor_cap + z23_valor_int ',
				' ELSE 0 ',
			' END valor_f, ',
			' z23_valor_cap + z23_valor_int valor_m, ',
			' z23_localidad, z23_tipo_favor, z23_codcli ',
	       	' FROM cxct023, cxct022 ',
		' WHERE z23_compania   = ', vg_codcia,
		expr_cli1 CLIPPED,
		'   AND z22_compania   = z23_compania ',
		'   AND z22_localidad  = z23_localidad ',
		'   AND z22_codcli     = z23_codcli ',
		'   AND z22_tipo_trn   = z23_tipo_trn  ',
		'   AND z22_num_trn    = z23_num_trn ',
		expr_fec CLIPPED,
		' INTO TEMP tmp_mov_cob '
PREPARE exec_z23 FROM query
EXECUTE exec_z23
SELECT COUNT(*) INTO vm_num_cob FROM tmp_mov_cob
LET sal_ini_cob = 0
LET saldo_cob   = tot_sal
IF rm_par.fecha_emi IS NOT NULL THEN
	IF vm_contab <> 'M' THEN
		SELECT NVL(saldo_ini_cob, 0) INTO sal_ini_cob
			FROM tmp_sal_ini
			WHERE cod_cli_s = r_z01.z01_codcli
	END IF
END IF
IF rm_par.codcli IS NULL THEN
	IF vm_contab <> 'M' THEN
		SELECT NVL(SUM(saldo_doc), 0) INTO saldo_cob
			FROM tempo_doc
			WHERE codcli = r_z01.z01_codcli
		LET saldo_cob = saldo_cob + sal_ini_cob
	END IF
END IF
LET sig_cob = 0
IF vm_num_cob > 0 THEN
	DISPLAY BY NAME saldo_cob, sal_ini_cob
	LET query = 'SELECT * FROM tmp_mov_cob ORDER BY 3 DESC, 1'
	PREPARE mov_cob2 FROM query
	DECLARE q_mov_cob2 CURSOR FOR mov_cob2
	LET i           = 1
	LET tot_val_deu = 0
	LET tot_val_fav = 0
	FOREACH q_mov_cob2 INTO rm_cob[i].*, rm_aux[i].*
		LET tot_val_deu = tot_val_deu + rm_cob[i].val_deu 
		LET tot_val_fav = tot_val_fav + rm_cob[i].val_fav 
		LET i           = i + 1
		IF i > num_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	IF vm_contab <> 'B' THEN
		LET sal_ini_cob = (saldo_cob * (-1) + tot_val_deu +
					tot_val_fav) * (-1)
	END IF
	DISPLAY BY NAME sal_ini_cob, tot_val_deu, tot_val_fav
	LET lim = vm_num_cob
	IF lim > fgl_scr_size('rm_cob') THEN
		LET lim = fgl_scr_size('rm_cob')
	END IF
	FOR i = 1 TO lim
		DISPLAY rm_cob[i].* TO rm_cob[i].*
	END FOR
	DISPLAY rm_cob[1].z22_referencia TO tit_referencia
	LET sig_cob = 1
END IF
ERROR "Procesando Movimientos en Contabilidad . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT * FROM ctbt013 ',
		' WHERE b13_compania    = ', vg_codcia,
		'   AND b13_fec_proceso BETWEEN "', vm_fecha_ini,
					 '" AND "', fecha_fin, '"',
		'   AND b13_cuenta     IN (SELECT UNIQUE cuenta FROM tmp_cta) ',
		expr_cli2 CLIPPED,
		' INTO TEMP tmp_b13'
PREPARE exec_b13 FROM query
EXECUTE exec_b13
DROP TABLE tmp_cta
LET query = 'SELECT NVL(SUM(b13_valor_base), 0) saldo_ini ',
		' FROM ctbt012, tmp_b13 ',
		' WHERE b12_compania    = ', vg_codcia,
		'   AND b12_estado      = "M" ',
		'   AND b12_moneda      = "', rm_par.moneda, '"',
		'   AND b13_compania    = b12_compania ',
		'   AND b13_tipo_comp   = b12_tipo_comp ',
		'   AND b13_num_comp    = b12_num_comp ',
		'   AND b13_fec_proceso <= "', fecha_antes, '"',
		' INTO TEMP t_sum'
PREPARE cons_sum2 FROM query
EXECUTE cons_sum2
SELECT * INTO sal_ini_con FROM t_sum
DISPLAY BY NAME sal_ini_con
DROP TABLE t_sum
LET query = 'SELECT b13_tipo_comp, b13_num_comp, b13_fec_proceso, ',
			' b13_glosa, NVL(CASE WHEN b13_valor_base >= 0 THEN ',
			' b13_valor_base END, 0) val_db, ',
			' NVL(CASE WHEN b13_valor_base < 0 THEN ',
			' b13_valor_base END, 0)  val_cr, ',
			' b13_valor_base val_db_cr ',
		' FROM ctbt012, tmp_b13 ',
		' WHERE b12_compania    = ', vg_codcia,
		'   AND b12_estado      = "M" ',
		'   AND b12_moneda      = "', rm_par.moneda, '"',
		'   AND b13_compania    = b12_compania ',
		'   AND b13_tipo_comp   = b12_tipo_comp ',
		'   AND b13_num_comp    = b12_num_comp ',
		'   AND b13_fec_proceso > "', fecha_antes, '"',
		' INTO TEMP tmp_mov_con '
PREPARE exec_b13_1 FROM query
EXECUTE exec_b13_1
SELECT COUNT(*) INTO vm_num_con FROM tmp_mov_con
DROP TABLE tmp_b13
IF vm_num_cob = 0 AND vm_num_con = 0 THEN
	DROP TABLE tmp_mov_cob
	DROP TABLE tmp_mov_con
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_cob_cont
	RETURN
END IF
IF vm_num_cob > num_max_doc THEN
	LET vm_num_cob = num_max_doc
END IF
IF vm_num_con > num_max_doc THEN
	LET vm_num_con = num_max_doc
END IF
IF vm_num_cob = num_max_doc OR vm_num_con > num_max_doc THEN
	CALL fl_mostrar_mensaje('Solo se mostraran un maximo de ' || num_max_doc || ' líneas de detalle ya que la aplicación solo soporta esta cantidad.', 'info')
END IF
LET sig_con = 0
IF vm_num_con > 0 THEN
	LET query = 'SELECT * FROM tmp_mov_con ORDER BY 3 DESC, 4'
	PREPARE mov_con2 FROM query
	DECLARE q_mov_con2 CURSOR FOR mov_con2
	LET i          = 1
	LET tot_val_db = 0
	LET tot_val_cr = 0
	FOREACH q_mov_con2 INTO rm_cont[i].*
		LET tot_val_db = tot_val_db + rm_cont[i].val_db 
		LET tot_val_cr = tot_val_cr + rm_cont[i].val_cr 
		LET i          = i + 1
		IF i > num_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	IF vm_num_con = num_max_doc THEN
		SELECT NVL(SUM(val_db), 1), NVL(SUM(val_cr), 0)
			INTO tot_val_db, tot_val_cr
			FROM tmp_mov_con
			WHERE b13_fec_proceso > fecha_antes
	END IF
	LET saldo_cont   = sal_ini_con + tot_val_db + tot_val_cr
	LET v_saldo_cont = saldo_cont
	IF v_saldo_cont < 0 THEN
		LET v_saldo_cont = v_saldo_cont * (-1)
	END IF
	LET v_saldo_cob = saldo_cob
	IF v_saldo_cob < 0 THEN
		LET v_saldo_cob = v_saldo_cob * (-1)
	END IF
	IF saldo_cont > saldo_cob THEN
		LET val_des = v_saldo_cont - v_saldo_cob
	ELSE
		LET val_des = v_saldo_cob - v_saldo_cont
	END IF
	DISPLAY BY NAME tot_val_db, tot_val_cr, saldo_cont, val_des
	LET lim = vm_num_con
	IF lim > fgl_scr_size('rm_cont') THEN
		LET lim = fgl_scr_size('rm_cont')
	END IF
	FOR i = 1 TO lim
		DISPLAY rm_cont[i].* TO rm_cont[i].*
	END FOR
	IF sig_cob = 0 THEN
		LET sig_con = 1
	END IF
	DISPLAY rm_cont[1].b13_glosa TO tit_glosa
END IF
ERROR ' '
CALL mostrar_contadores_cob_con(0, vm_num_cob, 0, vm_num_con)
LET p1 = 1
LET p2 = 1
LET p3 = 1
LET p4 = 1
WHILE TRUE
	IF sig_cob = 1 THEN
		CALL detalle_cobranzas(areaneg, p1,p2) RETURNING sig_con, p1, p2
	END IF
	IF sig_con = 1 THEN
		CALL detalle_contabilidad(p3, p4) RETURNING sig_cob, p3, p4
	END IF
	IF sig_cob = 0 THEN
		EXIT WHILE
	END IF
	IF sig_con = 0 THEN
		EXIT WHILE
	END IF
END WHILE
DROP TABLE tmp_mov_cob
DROP TABLE tmp_mov_con
CLOSE WINDOW w_cob_cont

END FUNCTION



FUNCTION detalle_cobranzas(areaneg, pos_pan, pos_arr)
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE pos_pan, pos_arr	INTEGER
DEFINE query		VARCHAR(200)
DEFINE i, col		INTEGER
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE sig_cob		SMALLINT

FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 1
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_cob)
	DISPLAY ARRAY rm_cob TO rm_cob.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET sig_cob  = 0
			EXIT DISPLAY
		ON KEY(F5)
			IF vm_num_con = 0 THEN
				CONTINUE DISPLAY
			END IF
			LET int_flag = 1
			LET sig_cob  = 1
			LET pos_pan  = scr_line()
			LET pos_arr  = arr_curr()
			EXIT DISPLAY
		ON KEY(F6)
			LET i = arr_curr()
			CALL fl_muestra_forma_pago_caja(vg_codcia,rm_aux[i].loc,
						areaneg,rm_aux[i].codcli,
						rm_cob[i].z23_tipo_trn,
						rm_cob[i].z23_num_trn) 
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_documento_tran(vg_codcia, rm_aux[i].codcli,
				rm_cob[i].z23_tipo_trn, rm_cob[i].z23_num_trn,
				rm_aux[i].loc, rm_aux[i].tipo)
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_cob_con(i, vm_num_cob,
							--#0, vm_num_con)
			--#DISPLAY rm_cob[i].z22_referencia TO tit_referencia
		--#BEFORE DISPLAY
			--#CALL dialog.setcurrline(pos_pan, pos_arr)
			--#CALL mostrar_contadores_cob_con(pos_arr, vm_num_cob,
							--#0, vm_num_con)
			--#DISPLAY rm_cob[pos_arr].z22_referencia TO
				--#tit_referencia
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F5","Detalle Contabi.")
			--#IF vm_num_con = 0 THEN
				--#CALL dialog.keysetlabel("F5","")
			--#END IF
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> columna_1 THEN
		LET columna_2          = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1          = col 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
	LET query = 'SELECT * FROM tmp_mov_cob ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE mov_cob3 FROM query
	DECLARE q_mov_cob3 CURSOR FOR mov_cob3
	LET i = 1
	FOREACH q_mov_cob3 INTO rm_cob[i].*, rm_aux[i].*
		LET i = i + 1
		IF i > num_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
END WHILE
CALL mostrar_contadores_cob_con(0, vm_num_cob, 0, vm_num_con)
RETURN sig_cob, pos_pan, pos_arr

END FUNCTION



FUNCTION detalle_contabilidad(pos_pan, pos_arr)
DEFINE pos_pan, pos_arr	INTEGER
DEFINE query		VARCHAR(200)
DEFINE i, col		INTEGER
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE sig_con		SMALLINT

FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 4
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_con)
	DISPLAY ARRAY rm_cont TO rm_cont.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET sig_con  = 0
			EXIT DISPLAY
		ON KEY(F5)
			IF vm_num_cob = 0 THEN
				CONTINUE DISPLAY
			END IF
			LET int_flag = 1
			LET sig_con  = 1
			LET pos_pan  = scr_line()
			LET pos_arr  = arr_curr()
			EXIT DISPLAY
		ON KEY(F8)
			LET i = arr_curr()
			CALL ver_diario_contable(rm_cont[i].b13_tipo_comp,
						rm_cont[i].b13_num_comp)
			LET int_flag = 0
		ON KEY(F22)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F23)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F24)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F25)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F26)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F27)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F28)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_cob_con(0, vm_num_cob,
							--#i, vm_num_con)
			--#DISPLAY rm_cont[i].b13_glosa TO tit_glosa
		--#BEFORE DISPLAY
			--#CALL dialog.setcurrline(pos_pan, pos_arr)
			--#CALL mostrar_contadores_cob_con(0, vm_num_cob,
							--#pos_arr, vm_num_con)
			--#DISPLAY rm_cont[pos_arr].b13_glosa TO tit_glosa
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F5","Detalle Cobranza")
			--#IF vm_num_cob = 0 THEN
				--#CALL dialog.keysetlabel("F5","")
			--#END IF
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> columna_1 THEN
		LET columna_2          = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1          = col 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
	LET query = 'SELECT * FROM tmp_mov_con ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE mov_con3 FROM query
	DECLARE q_mov_con3 CURSOR FOR mov_con3
	LET i = 1
	FOREACH q_mov_con3 INTO rm_cont[i].*
		LET i = i + 1
		IF i > num_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
END WHILE
CALL mostrar_contadores_cob_con(0, vm_num_cob, 0, vm_num_con)
RETURN sig_con, pos_pan, pos_arr

END FUNCTION



FUNCTION mostrar_contadores_cob_con(num_row_cob, max_row_cob, num_row_con,
					max_row_con)
DEFINE num_row_cob	INTEGER
DEFINE max_row_cob	INTEGER
DEFINE num_row_con	INTEGER
DEFINE max_row_con	INTEGER

DISPLAY BY NAME num_row_cob, max_row_cob, num_row_con, max_row_con

END FUNCTION



FUNCTION ver_factura_devolucion(i, area_n, cod_tran, num_tran, tipo)
DEFINE i		INTEGER
DEFINE area_n		LIKE cxct020.z20_areaneg
DEFINE cod_tran		LIKE cxct020.z20_cod_tran
DEFINE num_tran		LIKE cxct020.z20_num_tran
DEFINE tipo		LIKE cxct004.z04_tipo
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_t28		RECORD LIKE talt028.*
DEFINE prog		VARCHAR(10)
DEFINE expr		VARCHAR(40)
DEFINE comando          VARCHAR(200)

CALL fl_lee_area_negocio(vg_codcia, area_n) RETURNING r_g03.*
CASE r_g03.g03_modulo
	WHEN 'RE'
		CALL fl_ver_transaccion_rep(vg_codcia, rm_doc[i].locali,
						cod_tran, num_tran)
	WHEN 'TA'
		LET prog = 'talp308 '
		LET expr = num_tran
		IF tipo = 'F' THEN
			SELECT * INTO r_t28.*
				FROM talt028
				WHERE t28_compania  = vg_codcia
				  AND t28_localidad = rm_doc[i].locali
				  AND t28_factura   = num_tran
			LET prog = 'talp211 '
			LET expr = r_t28.t28_num_dev
		END IF
		LET comando = 'cd ..', vg_separador, '..', vg_separador, '..',
				vg_separador, 'PRODUCCION', vg_separador,
				'TALLER', vg_separador, 'fuentes; ', 'fglrun ',
				prog CLIPPED, ' ', vg_base, ' TA ', vg_codcia,
				' ', rm_doc[i].locali, ' ', expr CLIPPED
		RUN comando
	WHEN 'VE'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
				'VEHICULOS', vg_separador, 'fuentes; ',
				'fglrun vehp304 ', vg_base, ' VE ', vg_codcia,
				' ', rm_doc[i].locali, ' ', cod_tran, ' ',
				num_tran
		RUN comando
END CASE

END FUNCTION



FUNCTION ver_estado_cuenta(codcli)
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE comando          VARCHAR(200)

LET codloc = 0
IF rm_par.localidad IS NOT NULL THEN
	LET codloc = rm_par.localidad
END IF
LET comando = 'fglrun cxcp314 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', ' ', rm_par.moneda, ' ', rm_par.fecha_cart, ' ',
		rm_par.ind_venc, ' ', 0.01, ' ', rm_par.incluir_sal, ' ',
		codloc, ' ', codcli, ' ', rm_par.fecha_emi
RUN comando

END FUNCTION



FUNCTION ver_documento(codcli, numdoc, dividendo, tipo, i)
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE numdoc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE tipo		LIKE cxct004.z04_tipo
DEFINE i		INTEGER
DEFINE prog		VARCHAR(10)
DEFINE expr		VARCHAR(40)
DEFINE comando          VARCHAR(200)

LET prog = 'cxcp200 '
LET expr = dividendo, ' ', rm_par.fecha_cart
IF tipo = 'F' THEN
	LET prog = 'cxcp201 '
	LET expr = ' ', rm_par.fecha_cart
END IF
LET comando = 'fglrun ', prog CLIPPED, ' ', vg_base, ' ', vg_modulo, ' ',
		vg_codcia, ' ',	rm_doc[i].locali, ' ', codcli, ' ',
		rm_doc[i].cladoc, ' ', numdoc, ' ', expr CLIPPED
RUN comando

END FUNCTION



FUNCTION ver_documento_tran(codcia, codcli, tipo_trn, num_trn, loc, tipo)
DEFINE codcia		LIKE cxct022.z22_compania
DEFINE codcli		LIKE cxct022.z22_codcli
DEFINE tipo_trn		LIKE cxct022.z22_tipo_trn
DEFINE num_trn		LIKE cxct022.z22_num_trn
DEFINE loc		LIKE cxct022.z22_localidad
DEFINE tipo		LIKE cxct023.z23_tipo_favor
DEFINE comando		VARCHAR(200)
DEFINE run_prog		CHAR(10)
DEFINE prog		CHAR(10)

LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
LET prog = 'cxcp202 '
IF tipo IS NOT NULL THEN
	LET prog = 'cxcp203 '
END IF
LET comando = run_prog, prog, vg_base, ' ', vg_modulo, ' ', codcia, ' ', loc,
		' ', codcli, ' ', tipo_trn, ' ', num_trn
RUN comando

END FUNCTION



FUNCTION ver_diario_contable(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt013.b13_tipo_comp
DEFINE num_comp		LIKE ctbt013.b13_num_comp
DEFINE comando		VARCHAR(200)
DEFINE run_prog		CHAR(10)

LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
		vg_separador, 'fuentes', vg_separador, '; ', run_prog,
		'ctbp201 ', vg_base, ' "CB" ', vg_codcia, ' ', tipo_comp, ' ',
		num_comp
RUN comando

END FUNCTION



FUNCTION control_archivo()
DEFINE query		CHAR(5500)
DEFINE mensaje		VARCHAR(100)

ERROR 'Generando Archivo cxcp315.unl ... por favor espere'
LET query = 'SELECT cladoc, numdoc, localidad, codcli, nomcli, ',
			'fecha_emi, fecha, valor_doc, saldo_doc, ',
			' CASE WHEN area_n = 1 THEN ',
				'CASE WHEN (localidad <> 2 AND localidad <> 4)',
				' THEN ',
				' (SELECT r01_nombres FROM rept019, rept001 ',
					' WHERE r19_compania  = ', vg_codcia,
					'   AND r19_localidad = localidad ',
					'   AND r19_cod_tran  = cod_tran ',
					'   AND r19_num_tran  = num_tran ',
					'   AND r01_compania  = r19_compania ',
					'   AND r01_codigo    = r19_vendedor) ',
				' WHEN NOT (localidad <> 2 AND localidad <> 4)',
				' THEN ',
				' (SELECT r01_nombres FROM ',
					retorna_base_loc() CLIPPED, 'rept019, ',
					retorna_base_loc() CLIPPED, 'rept001 ',
					' WHERE r19_compania  = ', vg_codcia,
					'   AND r19_localidad = localidad ',
					'   AND r19_cod_tran  = cod_tran ',
					'   AND r19_num_tran  = num_tran ',
					'   AND r01_compania  = r19_compania ',
					'   AND r01_codigo    = r19_vendedor) ',
				' END ',
			' WHEN area_n = 2 THEN ',
				' (SELECT r01_nombres ',
					' FROM talt023, talt061, rept001 ',
					' WHERE t23_compania    = ', vg_codcia,
					'   AND t23_localidad   = localidad ',
					'   AND t23_num_factura = num_tran ',
					'   AND t61_compania    = t23_compania',
					'   AND t61_cod_asesor=t23_cod_asesor ',
					'   AND r01_compania  = t61_compania ',
					'   AND r01_codigo = t61_cod_vendedor)',
			' END vendedor, area_n, ',
			{--
			' CASE WHEN area_n = 1 AND cod_tran IS NULL ',
				'AND fecha_emi >= MDY(01, 01, 2003) THEN ',
				'CASE WHEN (localidad <> 2 AND localidad <> 4)',
				' THEN ',
				' (SELECT r19_cod_tran FROM rept019 ',
					' WHERE r19_compania  = ', vg_codcia,
					'   AND r19_localidad = localidad ',
					'   AND r19_cod_tran  = cladoc ',
					'   AND r19_num_tran  = numdoc) ',
				' WHEN NOT (localidad <> 2 AND localidad <> 4)',
				' THEN ',
				' (SELECT r19_cod_tran FROM ',
					retorna_base_loc() CLIPPED, 'rept019 ',
					' WHERE r19_compania  = ', vg_codcia,
					'   AND r19_localidad = localidad ',
					'   AND r19_cod_tran  = cladoc ',
					'   AND r19_num_tran  = numdoc) ',
				' END ',
			' WHEN area_n = 2 AND cod_tran IS NULL ',
				'AND fecha_emi >= MDY(01, 01, 2003) THEN ',
				' (SELECT "FA" ',
					' FROM talt023 ',
					' WHERE t23_compania    = ', vg_codcia,
					'   AND t23_localidad   = localidad ',
					'   AND t23_num_factura = numdoc) ',
			' END cod_tran, ',
			' CASE WHEN area_n = 1 AND cod_tran IS NULL ',
				'AND fecha_emi >= MDY(01, 01, 2003) THEN ',
				'CASE WHEN (localidad <> 2 AND localidad <> 4)',
				' THEN ',
				' (SELECT r19_num_tran FROM rept019 ',
					' WHERE r19_compania  = ', vg_codcia,
					'   AND r19_localidad = localidad ',
					'   AND r19_cod_tran  = cladoc ',
					'   AND r19_num_tran  = numdoc) ',
				' WHEN NOT (localidad <> 2 AND localidad <> 4)',
				' THEN ',
				' (SELECT r19_num_tran FROM ',
					retorna_base_loc() CLIPPED, 'rept019 ',
					' WHERE r19_compania  = ', vg_codcia,
					'   AND r19_localidad = localidad ',
					'   AND r19_cod_tran  = cladoc ',
					'   AND r19_num_tran  = numdoc) ',
				' END ',
			' WHEN area_n = 2 AND cod_tran IS NULL ',
				'AND fecha_emi >= MDY(01, 01, 2003) THEN ',
				' (SELECT t23_num_factura ',
					' FROM talt023 ',
					' WHERE t23_compania    = ', vg_codcia,
					'   AND t23_localidad   = localidad ',
					'   AND t23_num_factura = numdoc) ',
			' END num_tran, secuencia ',
			--}
			' cod_tran, num_tran, secuencia ',
		' FROM tempo_doc ',
		' INTO TEMP t1 '
PREPARE exec_arch FROM query
EXECUTE exec_arch
LET query = 'SELECT r38_num_sri, cladoc, numdoc, localidad, codcli, nomcli, ',
			'fecha_emi, fecha, valor_doc, saldo_doc, vendedor ',
		' FROM t1, OUTER rept038 ',
		' WHERE area_n           = 1 ',
		'   AND cladoc          NOT IN ("ND", "NC") ',
		'   AND localidad       NOT IN (2, 4) ',
		'   AND r38_compania     = ', vg_codcia,
		'   AND r38_localidad    = localidad ',
		'   AND r38_tipo_doc    IN ("FA", "NV") ',
		'   AND r38_tipo_fuente  = "PR" ',
		'   AND r38_cod_tran     = cod_tran ',
		'   AND r38_num_tran     = num_tran ',
		' UNION ',
		' SELECT r38_num_sri, cladoc, numdoc, localidad, codcli, ',
			'nomcli, fecha_emi, fecha, valor_doc, saldo_doc, ',
			'vendedor ',
		' FROM t1, OUTER ', retorna_base_loc() CLIPPED, 'rept038 ',
		' WHERE area_n           = 1 ',
		'   AND cladoc          NOT IN ("ND", "NC") ',
		'   AND localidad       IN (2, 4) ',
		'   AND r38_compania     = ', vg_codcia,
		'   AND r38_localidad    = localidad ',
		'   AND r38_tipo_doc    IN ("FA", "NV") ',
		'   AND r38_tipo_fuente  = "PR" ',
		'   AND r38_cod_tran     = cod_tran ',
		'   AND r38_num_tran     = num_tran ',
		' UNION ',
		' SELECT r38_num_sri, cladoc, numdoc, localidad, codcli, ',
			'nomcli, fecha_emi, fecha, valor_doc, saldo_doc, ',
			'vendedor ',
		' FROM t1, OUTER rept038 ',
		' WHERE area_n           = 2 ',
		'   AND cladoc          NOT IN ("ND", "NC") ',
		'   AND localidad       NOT IN (2, 4) ',
		'   AND r38_compania     = ', vg_codcia,
		'   AND r38_localidad    = localidad ',
		'   AND r38_tipo_doc    IN ("FA", "NV") ',
		'   AND r38_tipo_fuente  = "OT" ',
		'   AND r38_cod_tran     = cod_tran ',
		'   AND r38_num_tran     = num_tran ',
		' UNION ',
		' SELECT z20_num_sri, cladoc, numdoc, localidad, codcli, ',
			'nomcli, fecha_emi, fecha, valor_doc, saldo_doc, ',
			'vendedor ',
		' FROM t1, cxct020 ',
		' WHERE cladoc        = "ND" ',
		'   AND z20_compania  = ', vg_codcia,
		'   AND z20_localidad = localidad ',
		'   AND z20_codcli    = codcli ',
		'   AND z20_tipo_doc  = cladoc ',
		'   AND z20_num_doc   = numdoc ',
		'   AND z20_dividendo = secuencia ',
		' UNION ',
		' SELECT z21_num_sri, cladoc, numdoc, localidad, codcli, ',
			'nomcli, fecha_emi, fecha, valor_doc, saldo_doc, ',
			'vendedor ',
		' FROM t1, cxct021 ',
		' WHERE cladoc        = "NC" ',
		'   AND z21_compania  = ', vg_codcia,
		'   AND z21_localidad = localidad ',
		'   AND z21_codcli    = codcli ',
		'   AND z21_tipo_doc  = cladoc ',
		'   AND z21_num_doc   = numdoc ',
		' UNION ',
		' SELECT z21_num_sri, cladoc, numdoc, localidad, codcli, ',
			'nomcli, fecha_emi, fecha, valor_doc, saldo_doc, ',
			'vendedor ',
		' FROM t1, ', retorna_base_loc() CLIPPED, 'cxct021 ',
		' WHERE cladoc         = "NC" ',
		'   AND localidad     IN (2, 4) ',
		'   AND z21_compania   = ', vg_codcia,
		'   AND z21_localidad  = localidad ',
		'   AND z21_codcli     = codcli ',
		'   AND z21_tipo_doc   = cladoc ',
		'   AND z21_num_doc    = numdoc ',
		'   AND z21_num_sri   IS NOT NULL ',
		'   AND NOT EXISTS ',
			'(SELECT 1 FROM cxct021 a ',
			' WHERE a.z21_localidad  = z21_localidad ',
			'   AND a.z21_codcli     = z21_codcli ',
			'   AND a.z21_tipo_doc   = z21_tipo_doc ',
			'   AND a.z21_num_doc    = z21_num_doc ',
			'   AND a.z21_num_sri    = z21_num_sri) ',
		' INTO TEMP t2 '
PREPARE exec_arch2 FROM query
EXECUTE exec_arch2
DROP TABLE t1
{
SELECT "CODCLI" codcli, "CLIENTES" nomcli, "LOCALIDAD" localidad, "TP" cladoc,
	"NUMERO" numdoc, "NUMERO_SRI" r38_num_sri, "FECHA EMI."	fecha_emi,
	"AÑO" anio, "FECHA VCTO." fecha, "DIAS" dias, "VALOR DOC." valor_doc,
	"SALDO DOC." saldo_doc, "VENDEDOR" vendedor
	FROM dual
	INTO TEMP t3
INSERT INTO t3
	SELECT UNIQUE LPAD(codcli, 6, 0), nomcli, LPAD(localidad, 2, 0), cladoc,
		numdoc, r38_num_sri, fecha_emi,LPAD(YEAR(fecha_emi), 4, 0) anio,
		fecha, LPAD(fecha - fecha_emi, 5, 0) dias,
		valor_doc, saldo_doc, vendedor
		FROM t2
DROP TABLE t2
}
UNLOAD TO "../../../tmp/cxcp315.unl"
	{
	SELECT UNIQUE r38_num_sri, cladoc, numdoc, localidad, codcli,
		nomcli, fecha_emi, fecha, valor_doc, saldo_doc, vendedor
	}
	SELECT UNIQUE codcli, nomcli, localidad, cladoc, numdoc, r38_num_sri,
		fecha_emi, YEAR(fecha_emi) anio, fecha,(fecha - fecha_emi) dias,
		valor_doc, saldo_doc, g31_nombre, vendedor,
		NVL((SELECT z06_nombre
			FROM cxct002, cxct006
			WHERE z02_compania   = vg_codcia
			  AND z02_localidad  = localidad
			  AND z02_codcli     = codcli
			  AND z06_zona_cobro = z02_zona_cobro), "SIN COBRADOR")
		FROM t2, cxct001, gent031
		WHERE z01_codcli = codcli
		  AND g31_ciudad = z01_ciudad
		--ORDER BY 5 ASC, 2 ASC
		ORDER BY 2 ASC, 7 ASC
--DROP TABLE t3
DROP TABLE t2
RUN "mv ../../../tmp/cxcp315.unl $HOME/tmp/"
LET mensaje = FGL_GETENV("HOME"), '/tmp/cxcp315.unl'
CALL fl_mostrar_mensaje('Archivo Generado en: ' || mensaje, 'info')
ERROR ' '

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		INTEGER

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_list_cliente TO PIPE comando
FOR i = 1 TO num_doc
	OUTPUT TO REPORT report_list_cliente(i)
END FOR
FINISH REPORT report_list_cliente

END FUNCTION



REPORT report_list_cliente(i)
DEFINE i		INTEGER
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_z01		RECORD LIKE cxct001.*

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo  = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	PRINT COLUMN 001, r_g01.g01_razonsocial,
  	      COLUMN 070, "PAGINA: ", PAGENO USING '&&&'
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 024, "ANALISIS CARTERA DETALLE POR FECHA",
	      COLUMN 074, UPSHIFT(vg_proceso) 
	SKIP 1 LINES
	PRINT COLUMN 015, "** MONEDA            : ", rm_par.moneda,
		" ", rm_par.tit_mon
	IF rm_par.area_n IS NOT NULL THEN
		PRINT COLUMN 015, "** AREA DE NEGOCIO   : ",
			 rm_par.area_n USING '<<&', " ", rm_par.tit_area
	END IF
	IF rm_par.tipcli IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO CLIENTE      : ",
			rm_par.tipcli USING '<<<&', " ", rm_par.tit_tipcli
	END IF
	IF rm_par.tipcar IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO CARTERA      : ",
			rm_par.tipcar USING '<<<&', " ", rm_par.tit_tipcar
	END IF
	IF rm_par.localidad IS NOT NULL THEN
		PRINT COLUMN 015, "** LOCALIDAD         : ",
			rm_par.localidad USING '&&', " ", rm_par.tit_localidad
	END IF
	IF rm_par.codcli IS NOT NULL THEN
		CALL fl_lee_cliente_general(rm_par.codcli) RETURNING r_z01.*
		PRINT COLUMN 015, "** CLIENTE           : ",
			rm_par.codcli USING '<<<<<&', " ",
			r_z01.z01_nomcli[1, 40] CLIPPED
	END IF
	IF rm_par.ind_doc <> 'F' THEN
		PRINT COLUMN 015, "** TIPO DE VENCTO.   : ", rm_par.ind_venc,
			" ", retorna_tipo_vencto(rm_par.ind_venc)
	END IF
	PRINT COLUMN 015, "** TIPO DE DOCUMENTO : ", rm_par.ind_doc, " ",
		retorna_tipo_doc(rm_par.ind_doc)
	PRINT COLUMN 015, "** CARTERA DETALLE AL: ",
		rm_par.fecha_cart USING 'dd-mm-yyyy';
	IF rm_par.incluir_nc = 'S' THEN
		PRINT COLUMN 052, "SE RESTARON NC POR DEVOLUCION"
	ELSE
		PRINT COLUMN 052, " "
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "TP",
	      COLUMN 004, " DOCUMENTOS",
	      COLUMN 017, "LC",
	      COLUMN 023, "C L I E N T E S",
	      COLUMN 043, "FEC. VCTO.",
	      COLUMN 054, "VALOR DOCUME.",
	      COLUMN 068, "SALDO DOCUME."
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_doc[i].cladoc,
	      COLUMN 004, rm_doc[i].numdoc		CLIPPED,
	      COLUMN 017, rm_doc[i].locali		USING "&&",
	      COLUMN 020, rm_doc[i].nomcli[1, 22]	CLIPPED,
	      COLUMN 043, rm_doc[i].fecha		USING "dd-mm-yyyy",
	      COLUMN 054, rm_doc[i].valor		USING "--,---,--&.##",
	      COLUMN 068, rm_doc[i].saldo		USING "--,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 054, "-------------",
	      COLUMN 068, "-------------"
	PRINT COLUMN 041, "TOTALES ==>  ",
	      COLUMN 054, tot_val			USING "--,---,--&.##",
	      COLUMN 068, tot_sal			USING "--,---,--&.##"

END REPORT



FUNCTION retorna_tipo_vencto(tipo)
DEFINE tipo		CHAR(1)
DEFINE tipo_nom		VARCHAR(10)

CASE tipo
	WHEN 'P'
		LET tipo_nom = 'POR VENCER'
	WHEN 'V'
		LET tipo_nom = 'VENCIDOS'
	WHEN 'T'
		LET tipo_nom = 'T O D O S'
END CASE
RETURN tipo_nom

END FUNCTION



FUNCTION retorna_tipo_doc(tipo)
DEFINE tipo		CHAR(1)
DEFINE tipo_nom		VARCHAR(10)

CASE tipo
	WHEN 'D'
		LET tipo_nom = 'DEUDOR'
	WHEN 'F'
		LET tipo_nom = 'A FAVOR'
	WHEN 'T'
		LET tipo_nom = 'T O D O S'
END CASE
RETURN tipo_nom

END FUNCTION



FUNCTION retorna_base_loc()
DEFINE base_loc		VARCHAR(10)
DEFINE codloc		LIKE gent002.g02_localidad

LET base_loc = NULL
IF vg_codloc = 6 OR vg_codloc = 7 THEN
	RETURN base_loc CLIPPED
END IF
LET codloc = vg_codloc
CASE vg_codloc
	WHEN 1 LET codloc = 2
	WHEN 3 LET codloc = 4
END CASE
SELECT g56_base_datos INTO base_loc
	FROM gent056
	WHERE g56_compania  = vg_codcia
	  AND g56_localidad = codloc
IF base_loc IS NOT NULL THEN
	LET base_loc = base_loc CLIPPED, ':'
END IF
RETURN base_loc CLIPPED

END FUNCTION



FUNCTION control_archivo_indicador()
DEFINE query		CHAR(5500)
DEFINE mensaje		VARCHAR(100)
DEFINE resp		CHAR(6)

ERROR 'Generando Archivo cxcp315_ind.unl ... por favor espere'
LET query = 'SELECT g02_nombre loc, NVL(z06_nombre, "SIN COBRADOR") cobra, ',
		'fp_numero_semana("', rm_par.fecha_cart, '") num_sem, ',
		'YEAR(DATE("', rm_par.fecha_cart, '")) anio, ',
		'cladoc, numdoc, secuencia, '
		--'fecha, cladoc, numdoc, secuencia, '
		{--
		'ROUND((DATE(fecha) - MDY(1, 3, YEAR(DATE(fecha) ',
		'- WEEKDAY(DATE(fecha) - 1 UNITS DAY) + 4 UNITS DAY)) ',
		'+ WEEKDAY(MDY(1, 3, YEAR(DATE(fecha) ',
		'- WEEKDAY(DATE(fecha) - 1 UNITS DAY) + 4 UNITS DAY))) ',
		'+ 5) / 7, 0) num_sem, '
		--}
LET int_flag = 0
CALL fl_hacer_pregunta('Desea generar el archivo por antiguedad de cartera ?', 'nO')
	RETURNING resp
IF resp = 'Yes' THEN
	LET query = query CLIPPED,
			'(TODAY - fecha) dias, ',
			'SUM((saldo_doc * (TODAY - fecha))) tot_t, ',
			'SUM(saldo_doc) tot_d '
ELSE
	LET query = query CLIPPED, 
			'SUM(saldo_doc) tot_cart '
END IF
LET query = query CLIPPED, 
		' FROM tempo_doc, gent002, cxct002, OUTER cxct006 ',
		' WHERE g02_compania   = ', vg_codcia,
		'   AND g02_localidad  = localidad ',
		'   AND z02_compania   = g02_compania ',
		'   AND z02_localidad  = g02_localidad ',
		'   AND z02_codcli     = codcli ',
		'   AND z02_zona_cobro = z06_zona_cobro '
		--' GROUP BY 1, 2, 3 ',
IF resp = 'Yes' THEN
	LET query = query CLIPPED,
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8 '
ELSE
	LET query = query CLIPPED,
		' GROUP BY 1, 2, 3, 4, 5, 6, 7 '--, 8 '
END IF
LET query = query CLIPPED,
	' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
IF resp = 'Yes' THEN
	{--
	SELECT loc, cobra, anio, num_sem, SUM(tot_t) tot_t, SUM(tot_d) tot_d
		FROM t1
		GROUP BY 1, 2, 3, 4
		INTO TEMP t2
	DROP TABLE t1
	SELECT loc, cobra, anio, num_sem, (tot_t / tot_d) tot_cart
		FROM t2
		INTO TEMP t1
	DROP TABLE t2
	--}
	UNLOAD TO "../../../tmp/cxcp315_ind.unl"
		SELECT * FROM t1
			ORDER BY 4 ASC, 2 ASC
ELSE
	UNLOAD TO "../../../tmp/cxcp315_ind.unl"
		SELECT loc, cobra, anio, num_sem, SUM(tot_cart) tot_cart
			FROM t1
			GROUP BY 1, 2, 3, 4
			ORDER BY 4 ASC, 2 ASC
		{--
		SELECT loc, cobra, anio, num_sem, cladoc, numdoc, fecha,
			SUM(tot_cart) tot_cart
			FROM t1
			GROUP BY 1, 2, 3, 4, 5, 6, 7
			ORDER BY 4 ASC, 2 ASC
		--}
END IF
DROP TABLE t1
RUN "mv ../../../tmp/cxcp315_ind.unl $HOME/tmp/"
LET mensaje = FGL_GETENV("HOME"), '/tmp/cxcp315_ind.unl'
CALL fl_mostrar_mensaje('Archivo de Indicadores Generado en: ' || mensaje, 'info')
ERROR ' '

END FUNCTION



FUNCTION control_archivo_crediticio()
DEFINE query		CHAR(10000)
DEFINE mensaje		VARCHAR(200)

IF rm_par2.fec_emi_ini IS NULL THEN
	CALL fl_mostrar_mensaje('No se ha seleccionado un periodo de emisión en los filtros adicionales para generar este tipo de archivo.', 'exclamation')
	RETURN
END IF
ERROR 'Generando Archivo Crediticio. Por favor espere ... '
LET query = "SELECT 'SR01609' AS cod_ent, ",
		"DATE('", rm_par2.fec_emi_fin, "') AS fec_corte, ",
		"CASE WHEN z01_tipo_doc_id = 'P' ",
			"THEN 'E' ",
			"ELSE z01_tipo_doc_id ",
		"END AS tipo_id, ",
		"z01_num_doc_id AS cedruc, ",
		"nomcli AS cliente, ",
		"z01_personeria AS cla_suj, ",
		"(SELECT codigo ",
			"FROM gent031, gent025, provincia ",
			"WHERE g31_ciudad    = z01_ciudad ",
			"  AND g31_pais      = z01_pais ",
			"  AND g25_pais      = g31_pais ",
			"  AND g25_divi_poli = g31_divi_poli ",
			"  AND pais          = g25_pais ",
			"  AND cod_phobos    = g25_divi_poli) AS cod_prov, ",
		"(SELECT b.codigo ",
			"FROM gent031, gent025, canton b ",
			"WHERE g31_ciudad    = z01_ciudad ",
			"  AND g31_pais      = z01_pais ",
			"  AND g25_pais      = g31_pais ",
			"  AND g25_divi_poli = g31_divi_poli ",
			"  AND b.pais        = g25_pais ",
			"  AND b.divi_poli   = g25_divi_poli ",
			"  AND b.cod_phobos  = g31_ciudad) AS cod_cant, ",
		"'' AS cod_parroq, ",
		"'' AS sexo, ",
		"'' AS est_civ, ",
		"'' AS ori_ing, ",
		"(SELECT r38_num_sri ",
			" FROM rept038 ",
			" WHERE r38_compania     = ", vg_codcia,
			"   AND r38_localidad    = localidad ",
			"   AND r38_tipo_doc    IN ('FA', 'NV') ",
			"   AND r38_tipo_fuente  = 'PR' ",
			"   AND r38_cod_tran     = cod_tran ",
			"   AND r38_num_tran     = num_tran) AS num_ope, ",
		"valor_doc AS val_ope, ",
		"saldo_doc AS sal_ope, ",
		"fecha_emi AS fecha_conc, ",
		"fecha AS fec_vcto, ",
		"fecha AS fec_exi, ",
		"(fecha - fecha_emi) AS plazo_op, ",
		"'' AS perioc_pag, ",
		"'' AS dias_mor, ",
		"saldo_doc AS monto_mor, ",
		"0.00 AS int_mor, ",
		"0.00 AS por_venc_30, ",
		"0.00 AS por_venc_90, ",
		"0.00 AS por_venc_180, ",
		"0.00 AS por_venc_360, ",
		"0.00 AS por_venc_m_360, ",
		"0.00 AS venc_30, ",
		"0.00 AS venc_90, ",
		"0.00 AS venc_180, ",
		"0.00 AS venc_360, ",
		"0.00 AS venc_m_360, ",
		"0.00 AS val_dem_jud, ",
		"0.00 AS cart_cast, ",
		"0.00 AS cuot_cred, ",
		"'' AS fec_canc, ",
		"'' AS for_canc ",
		"FROM tempo_doc, cxct001 ",
		"WHERE z01_codcli    = codcli ",
		"INTO TEMP t1 "
PREPARE exec_arch_cred FROM query
EXECUTE exec_arch_cred
UNLOAD TO "/tmp/cxcp315_cre.txt"
	SELECT * FROM t1
		ORDER BY 5
RUN "mv /tmp/cxcp315_cre.txt $HOME/tmp/cxcp315_cre.txt"
LET mensaje = FGL_GETENV("HOME"), '/tmp/cxcp315_cre.txt'
DROP TABLE t1
CALL fl_mostrar_mensaje('Archivo Crediticio Generado en: ' || mensaje, 'info')
ERROR ' '

END FUNCTION
