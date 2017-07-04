--------------------------------------------------------------------------------
-- Titulo           : cxcp400.4gl - Listado de cartera por cobrar
-- Elaboracion      : 14-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxcp400 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_par		RECORD 
				anho		SMALLINT,
				mes		SMALLINT,
				g13_moneda	LIKE gent013.g13_moneda,
				g13_nombre	LIKE gent013.g13_nombre,
				areaneg		LIKE gent003.g03_areaneg,
				n_areaneg	LIKE gent003.g03_nombre,
				zona_cobro	LIKE cxct006.z06_zona_cobro,
				n_zona_cobro	LIKE cxct006.z06_nombre,
				tipocli		LIKE gent012.g12_subtipo,
				n_tipocli	LIKE gent012.g12_nombre,
				tipocartera	LIKE gent012.g12_subtipo,
				n_tipocartera	LIKE gent012.g12_nombre,
				r01_codigo	LIKE rept001.r01_codigo,
				r01_nombres	LIKE rept001.r01_nombres,
				tipo_vcto	CHAR,
				dias_ini	SMALLINT,
				dias_fin	INTEGER,
				localidad	LIKE gent002.g02_localidad,
				tit_localidad	LIKE gent002.g02_nombre
			END RECORD
DEFINE num_campos	SMALLINT
DEFINE rm_campos	ARRAY[15] OF RECORD
				nombre		VARCHAR(20),
				posicion	SMALLINT
			END RECORD
DEFINE rm_ord		ARRAY[3] OF RECORD
				col		VARCHAR(20),
				chk_asc		CHAR,
				chk_desc	CHAR
			END RECORD
DEFINE num_ord		SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp400.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp400'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE i		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 16
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/cxcf400_1"
ELSE
	OPEN FORM f_rep FROM "../forms/cxcf400_1c"
END IF
DISPLAY FORM f_rep
CALL campos_forma()
CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*
INITIALIZE rm_par.* TO NULL
LET rm_par.anho       = YEAR(TODAY)
LET rm_par.mes        = MONTH(TODAY)
LET rm_par.g13_moneda = r_g13.g13_moneda
LET rm_par.g13_nombre = r_g13.g13_nombre
LET rm_par.tipo_vcto  = 'T'
LET num_ord           = 3
LET rm_ord[1].col     = rm_campos[1].nombre
LET rm_ord[2].col     = rm_campos[2].nombre
LET rm_ord[3].col     = rm_campos[5].nombre
FOR i = 1 TO num_ord
	LET rm_ord[i].chk_asc  = 'S'
	LET rm_ord[i].chk_desc = 'N'
	
	DISPLAY rm_ord[i].* TO rm_ord[i].*
END FOR
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		CHAR(1200)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT
DEFINE enter		SMALLINT
DEFINE resp		CHAR(6)
DEFINE registro		CHAR(400)
DEFINE r_det		RECORD 
				areaneg		LIKE gent003.g03_areaneg,
				zona_cobro	LIKE cxct002.z02_zona_cobro,
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				tipo_doc	LIKE cxct020.z20_tipo_doc,
				num_doc		LIKE cxct020.z20_num_doc,
				dividendo	LIKE cxct020.z20_dividendo,
				num_sri		LIKE cxct020.z20_num_sri,
				fecha_emi	LIKE cxct020.z20_fecha_emi,
				fecha_vcto	LIKE cxct020.z20_fecha_vcto,
				antiguedad	INTEGER,
				saldo		LIKE cxct020.z20_saldo_cap
			END RECORD
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE z_cobro		LIKE cxct002.z02_zona_cobro

LET enter = 13
INITIALIZE r_det.* TO NULL 
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL ordenar_por()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_hacer_pregunta('Desea generar también un archivo de texto ?',
				'No')
		RETURNING resp
	LET int_flag = 0
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
	IF YEAR(TODAY) <> rm_par.anho OR MONTH(TODAY) <> rm_par.mes THEN
		LET query = prepare_query_cxct050()
	ELSE
		LET query = prepare_query_cxct020()
	END IF
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0
	START REPORT rep_cartera TO PIPE comando
	FOREACH	q_deto INTO r_det.*, r_r19.r19_compania, r_r19.r19_localidad,
				r_r19.r19_cod_tran, r_r19.r19_num_tran
		IF r_det.num_sri IS NULL THEN
			CALL obtener_num_sri(r_det.areaneg, r_r19.r19_localidad,
						r_r19.r19_cod_tran,
						r_r19.r19_num_tran)
				RETURNING r_det.num_sri
		END IF
		IF rm_par.r01_codigo IS NOT NULL THEN
			IF r_r19.r19_cod_tran IS NULL THEN
				CONTINUE FOREACH
			END IF
			CALL lee_factura_inv(r_r19.r19_compania,
						r_r19.r19_localidad,
						r_r19.r19_cod_tran,
						r_r19.r19_num_tran)
				RETURNING r_r19.*
			IF r_r19.r19_compania IS NULL THEN
				CONTINUE FOREACH
			END IF
			IF rm_par.r01_codigo <> r_r19.r19_vendedor THEN
				CONTINUE FOREACH
			END IF
		END IF
		LET data_found = 1
		IF resp = 'Yes' THEN
			IF r_det.zona_cobro IS NULL THEN
				LET z_cobro = '  '
			END IF
			IF r_r19.r19_cod_tran IS NOT NULL THEN
				CALL lee_factura_inv(r_r19.r19_compania,
							r_r19.r19_localidad,
							r_r19.r19_cod_tran,
							r_r19.r19_num_tran)
					RETURNING r_r19.*
				IF r_r19.r19_localidad <> 2 AND
				   r_r19.r19_localidad <> 4
				THEN
					CALL fl_lee_vendedor_rep(
							r_r19.r19_compania,
							r_r19.r19_vendedor)
						RETURNING r_r01.*
				ELSE
					CALL lee_vendedor_loc(
							r_r19.r19_compania,
							r_r19.r19_vendedor)
						RETURNING r_r01.*
				END IF
			ELSE
				INITIALIZE r_r01.*, r_r19.* TO NULL
			END IF
			LET registro = fl_justifica_titulo('D',r_det.areaneg,3),
				'|', fl_justifica_titulo('D', r_det.zona_cobro, 5)
				CLIPPED, '|',
				fl_justifica_titulo('D', r_det.codcli, 6)
				CLIPPED, '|', r_det.nomcli CLIPPED, '|',
				r_det.tipo_doc, '-',
				fl_justifica_titulo('I', r_det.num_doc, 15)
				CLIPPED, '-', fl_justifica_titulo('I',
				r_det.dividendo, 3) USING "&&&", '|',
				r_det.num_sri CLIPPED, '|',
				r_det.fecha_emi USING "dd-mm-yyyy", '|',
				r_det.fecha_vcto USING "dd-mm-yyyy", '|',
				r_det.antiguedad USING "---,--&", '|',
				r_det.saldo USING "#,###,###,##&.##", '|',
				r_r19.r19_vendedor USING "<<<&&", '|',
				r_r01.r01_nombres CLIPPED
			IF vg_gui = 1 THEN
				--#DISPLAY registro CLIPPED, ASCII(enter)
			ELSE
				DISPLAY registro CLIPPED
			END IF
		END IF
		OUTPUT TO REPORT rep_cartera(r_det.*)
	END FOREACH
	FINISH REPORT rep_cartera
	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
	IF resp = 'Yes' THEN
		--RUN 'mv cxcp400.txt /acero/fobos/tmp'
		RUN 'mv cxcp400.txt $HOME/tmp'
		CALL fl_mostrar_mensaje('Se generó el Archivo cxcp400.txt', 'info')
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE i, j, l		SMALLINT
DEFINE dummy		LIKE gent011.g11_tiporeg
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z06		RECORD LIKE cxct006.*
DEFINE r_r01		RECORD LIKE rept001.*

IF vg_gui = 0 THEN
	CALL muestra_tipovcto(rm_par.tipo_vcto)
END IF
DISPLAY BY NAME rm_par.g13_nombre
LET INT_FLAG = 0
INPUT BY NAME rm_par.anho, rm_par.mes, rm_par.g13_moneda, rm_par.areaneg,
	rm_par.zona_cobro, rm_par.tipocli, rm_par.tipocartera,rm_par.r01_codigo,
	rm_par.tipo_vcto, rm_par.dias_ini, rm_par.dias_fin, rm_par.localidad
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET INT_FLAG = 1 
		--#RETURN
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(g13_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda, 
					  		  r_g13.g13_nombre,
					  		  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_par.g13_moneda = r_g13.g13_moneda
				LET rm_par.g13_nombre = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
					RETURNING r_g03.g03_areaneg,
					  	  r_g03.g03_nombre
			IF r_g03.g03_areaneg IS NOT NULL THEN
				LET rm_par.areaneg   = r_g03.g03_areaneg
				LET rm_par.n_areaneg = r_g03.g03_nombre
				DISPLAY BY NAME rm_par.*
			END IF 
		END IF
		IF INFIELD(zona_cobro) THEN
			CALL fl_ayuda_zona_cobro('T', 'T') 
					RETURNING r_z06.z06_zona_cobro,
						  r_z06.z06_nombre
			IF r_z06.z06_zona_cobro IS NOT NULL THEN
				LET rm_par.zona_cobro   = r_z06.z06_zona_cobro
				LET rm_par.n_zona_cobro = r_z06.z06_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(tipocli) THEN
			CALL fl_ayuda_subtipo_entidad('CL') 
					RETURNING r_g12.g12_tiporeg,
						  r_g12.g12_subtipo,
						  r_g12.g12_nombre,
						  dummy
			IF r_g12.g12_subtipo IS NOT NULL THEN
				LET rm_par.tipocli   = r_g12.g12_subtipo
				LET rm_par.n_tipocli = r_g12.g12_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(tipocartera) THEN
			CALL fl_ayuda_subtipo_entidad('CR') 
					RETURNING r_g12.g12_tiporeg,
						  r_g12.g12_subtipo,
						  r_g12.g12_nombre,
						  dummy
			IF r_g12.g12_subtipo IS NOT NULL THEN
				LET rm_par.tipocartera   = r_g12.g12_subtipo
				LET rm_par.n_tipocartera = r_g12.g12_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(r01_codigo) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'T', 'T')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_par.r01_codigo  = r_r01.r01_codigo
				LET rm_par.r01_nombres = r_r01.r01_nombres
				DISPLAY BY NAME rm_par.r01_codigo,
						r_r01.r01_nombres
			END IF
		END IF
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.localidad     = r_g02.g02_localidad
				LET rm_par.tit_localidad = r_g02.g02_nombre
				DISPLAY BY NAME rm_par.localidad
				DISPLAY r_g02.g02_nombre TO tit_localidad
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD g13_moneda
		IF rm_par.g13_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.g13_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD g13_moneda
			END IF
			LET rm_par.g13_nombre = r_g13.g13_nombre
			DISPLAY BY NAME rm_par.g13_nombre
		ELSE
			LET rm_par.g13_nombre = NULL
			CLEAR g13_nombre
		END IF
	AFTER FIELD areaneg
		IF rm_par.areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.areaneg) 
				RETURNING r_g03.*
			IF r_g03.g03_areaneg IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Area de negocio no existe.','exclamation')
				CALL fl_mostrar_mensaje('Area de negocio no existe.','exclamation')
				NEXT FIELD areaneg
			END IF
			LET rm_par.n_areaneg = r_g03.g03_nombre
			DISPLAY BY NAME rm_par.n_areaneg
		ELSE
			LET rm_par.n_areaneg = NULL
			CLEAR n_areaneg
		END IF
	AFTER FIELD zona_cobro
		IF rm_par.zona_cobro IS NOT NULL THEN
			CALL fl_lee_zona_cobro(rm_par.zona_cobro)
				RETURNING r_z06.*
			IF r_z06.z06_zona_cobro IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Zona de cobro no existe.','exclamation')
				CALL fl_mostrar_mensaje('Zona de cobro no existe.','exclamation')
				NEXT FIELD zona_cobro
			END IF
			LET rm_par.n_zona_cobro = r_z06.z06_nombre
			DISPLAY BY NAME rm_par.n_zona_cobro
		ELSE
			LET rm_par.n_zona_cobro = NULL
			CLEAR n_zona_cobro
		END IF
	AFTER FIELD tipocli
		IF rm_par.tipocli IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CL', rm_par.tipocli)
				RETURNING r_g12.*
			IF r_g12.g12_subtipo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Tipo cliente no existe.','exclamation')
				CALL fl_mostrar_mensaje('Tipo cliente no existe.','exclamation')
				NEXT FIELD tipocli
			END IF
			LET rm_par.n_tipocli = r_g12.g12_nombre
			DISPLAY BY NAME rm_par.n_tipocli
		ELSE
			LET rm_par.n_tipocli = NULL
			CLEAR n_tipocli
		END IF
	AFTER FIELD tipocartera
		IF rm_par.tipocartera IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR', rm_par.tipocartera)
				RETURNING r_g12.*
			IF r_g12.g12_subtipo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Tipo cartera no existe.','exclamation')
				CALL fl_mostrar_mensaje('Tipo cartera no existe.','exclamation')
				NEXT FIELD tipocartera
			END IF
			LET rm_par.n_tipocartera = r_g12.g12_nombre
			DISPLAY BY NAME rm_par.n_tipocartera
		ELSE
			LET rm_par.n_tipocartera = NULL
			CLEAR n_tipocartera
		END IF
	AFTER FIELD r01_codigo
		IF rm_par.r01_codigo IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_par.r01_codigo)
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('No existe vendedor.','exclamation')
				NEXT FIELD r01_codigo
			END IF
			LET rm_par.r01_nombres = r_r01.r01_nombres
			DISPLAY BY NAME r_r01.r01_nombres
		ELSE
			CLEAR r01_nombres
		END IF
	BEFORE FIELD dias_ini
		IF rm_par.tipo_vcto = 'T' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD dias_fin
		IF rm_par.tipo_vcto = 'T' THEN
			IF fgl_lastkey() = fgl_keyval('up') THEN
				NEXT FIELD tipo_vcto
			ELSE
				NEXT FIELD NEXT
			END IF
		END IF
	AFTER FIELD tipo_vcto
		IF vg_gui = 0 THEN
			IF rm_par.tipo_vcto IS NOT NULL THEN
				CALL muestra_tipovcto(rm_par.tipo_vcto)
			ELSE
				CLEAR tit_tipo_vcto
			END IF
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
			DISPLAY r_g02.g02_nombre TO tit_localidad
		ELSE
			LET rm_par.tit_localidad = NULL
			CLEAR tit_localidad
		END IF
	AFTER INPUT
		IF rm_par.dias_ini IS NOT NULL AND rm_par.dias_fin IS NULL THEN
			CALL fl_mostrar_mensaje('Si ingresa un rango de días debe ingresar ambos valores.','exclamation')
			CONTINUE INPUT
		END IF
		IF rm_par.dias_fin IS NOT NULL AND rm_par.dias_ini IS NULL THEN
			CALL fl_mostrar_mensaje('Si ingresa un rango de días debe ingresar ambos valores.','exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION prepare_query_cxct050()
DEFINE query	 	CHAR(1500)
DEFINE expr_area	VARCHAR(30)
DEFINE expr_zona	VARCHAR(30)
DEFINE expr_tipocli	VARCHAR(30)
DEFINE expr_tipocartera VARCHAR(30)
DEFINE expr_vcto	VARCHAR(30)
DEFINE expr_dias	VARCHAR(60)
DEFINE expr_loc		VARCHAR(100)

LET expr_area = ' '
IF rm_par.areaneg IS NOT NULL THEN
	LET expr_area = ' AND z50_areaneg = ', rm_par.areaneg
END IF

LET expr_zona = ' '
IF rm_par.zona_cobro IS NOT NULL THEN
	LET expr_zona = ' AND z02_zona_cobro = ', rm_par.zona_cobro
END IF

LET expr_tipocli = ' '
IF rm_par.tipocli IS NOT NULL THEN
	LET expr_tipocli = ' AND z01_tipo_clte = ', rm_par.tipocli
END IF

LET expr_tipocartera = ' '
IF rm_par.tipocartera IS NOT NULL THEN
	LET expr_tipocartera = ' AND z50_cartera = ', rm_par.tipocartera
END IF

CASE rm_par.tipo_vcto 
	WHEN 'P'
		LET expr_vcto = ' AND z50_fecha_vcto >= TODAY '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias =' AND (z50_fecha_vcto - TODAY) BETWEEN ',
					rm_par.dias_ini, ' AND ',rm_par.dias_fin
		END IF
	WHEN 'V'
		LET expr_vcto = ' AND z50_fecha_vcto < TODAY '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias =' AND (TODAY - z50_fecha_vcto) BETWEEN ',
					rm_par.dias_ini, ' AND ',rm_par.dias_fin
		END IF
	OTHERWISE
		LET expr_vcto = ' '
		LET expr_dias = ' '
END CASE

LET expr_loc = NULL
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loc = '  AND z50_localidad = ', rm_par.localidad
END IF

LET query = 'SELECT z50_areaneg, z02_zona_cobro, z50_codcli, z01_nomcli, ',
	          ' z50_tipo_doc, z50_num_doc, z50_dividendo, z50_num_sri, ',
		  ' z50_fecha_emi, z50_fecha_vcto, (z50_fecha_vcto - TODAY), ',
	          ' (z50_saldo_cap + z50_saldo_int), z50_compania, ',
		  ' z50_localidad, z50_cod_tran, z50_num_tran ',
	    	' FROM cxct050, cxct001, cxct002 ', 
	    	' WHERE z50_ano       = ', rm_par.anho,
	    	  ' AND z50_mes       = ', rm_par.mes,
	    	  ' AND z50_compania  = ', vg_codcia,
	    	  --' AND z50_localidad = ', vg_codloc,
		  expr_loc CLIPPED,
	    	  ' AND z50_moneda    = "', rm_par.g13_moneda, '"', 
	    	  expr_area CLIPPED, 
	    	  expr_tipocartera CLIPPED,
	    	  expr_vcto CLIPPED,
	    	  expr_dias CLIPPED,
		  ' AND (z50_saldo_cap + z50_saldo_int) > 0 ', 
	    	  ' AND z01_codcli    = z50_codcli ',
	    	  expr_tipocli CLIPPED,
	    	  ' AND z02_compania  = z50_compania ',
	    	  ' AND z02_localidad = z50_localidad ', 
	    	  ' AND z02_codcli    = z50_codcli ',
	    	  expr_zona CLIPPED
	    	  
RETURN full_query(query)

END FUNCTION



FUNCTION prepare_query_cxct020()
DEFINE query	 	CHAR(1500)
DEFINE expr_area	VARCHAR(30)
DEFINE expr_zona	VARCHAR(30)
DEFINE expr_tipocli	VARCHAR(30)
DEFINE expr_tipocartera VARCHAR(30)
DEFINE expr_vcto	VARCHAR(30)
DEFINE expr_dias	VARCHAR(60)
DEFINE expr_loc		VARCHAR(100)

LET expr_area = ' '
IF rm_par.areaneg IS NOT NULL THEN
	LET expr_area = ' AND z20_areaneg = ', rm_par.areaneg
END IF

LET expr_zona = ' '
IF rm_par.zona_cobro IS NOT NULL THEN
	LET expr_zona = ' AND z02_zona_cobro = ', rm_par.zona_cobro
END IF

LET expr_tipocli = ' '
IF rm_par.tipocli IS NOT NULL THEN
	LET expr_tipocli = ' AND z01_tipo_clte = ', rm_par.tipocli
END IF

LET expr_tipocartera = ' '
IF rm_par.tipocartera IS NOT NULL THEN
	LET expr_tipocartera = ' AND z20_cartera = ', rm_par.tipocartera
END IF

CASE rm_par.tipo_vcto 
	WHEN 'P'
		LET expr_vcto = ' AND z20_fecha_vcto >= TODAY '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias =' AND (z20_fecha_vcto - TODAY) BETWEEN ',
					rm_par.dias_ini, ' AND ',rm_par.dias_fin
		END IF
	WHEN 'V'
		LET expr_vcto = ' AND z20_fecha_vcto < TODAY '
		IF rm_par.dias_ini IS NOT NULL THEN
			LET expr_dias =' AND (TODAY - z20_fecha_vcto) BETWEEN ',
					rm_par.dias_ini, ' AND ',rm_par.dias_fin
		END IF
	OTHERWISE
		LET expr_vcto = ' '
		LET expr_dias = ' '
END CASE

LET expr_loc = NULL
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loc = '  AND z20_localidad = ', rm_par.localidad
END IF

LET query = 'SELECT z20_areaneg, z02_zona_cobro, z20_codcli, z01_nomcli, ',
	          ' z20_tipo_doc, z20_num_doc, z20_dividendo, z20_num_sri, ',
		  ' z20_fecha_emi, z20_fecha_vcto, ',
		  ' (z20_fecha_vcto - TODAY) antiguedad, ',
	          ' (z20_saldo_cap + z20_saldo_int) saldo, ',
		  ' z20_compania, z20_localidad, z20_cod_tran, z20_num_tran ',
	    	' FROM cxct020, cxct001, cxct002 ', 
	    	' WHERE z20_compania  = ', vg_codcia,
	    	  --' AND z20_localidad = ', vg_codloc,
	    	  expr_loc CLIPPED, 
	    	  ' AND z20_moneda    = "', rm_par.g13_moneda, '"', 
	    	  expr_area CLIPPED, 
	    	  expr_tipocartera CLIPPED,
	    	  expr_vcto CLIPPED,
	    	  expr_dias CLIPPED,
		  ' AND (z20_saldo_cap + z20_saldo_int) > 0 ', 
	    	  ' AND z01_codcli    = z20_codcli ',
	    	  expr_tipocli CLIPPED,
	    	  ' AND z02_compania  = z20_compania ',
	    	  ' AND z02_localidad = z20_localidad ', 
	    	  ' AND z02_codcli    = z20_codcli ',
	    	  expr_zona CLIPPED
	    	  
RETURN full_query(query)

END FUNCTION



FUNCTION full_query(query)
DEFINE query		CHAR(1000)
DEFINE order_clause	VARCHAR(150)

DEFINE i		SMALLINT
DEFINE j		SMALLINT

LET order_clause = ' ORDER BY '

FOR i = 1 TO num_ord
	FOR j = 1 TO num_campos
		IF rm_ord[i].col = rm_campos[j].nombre THEN
			LET order_clause = order_clause || rm_campos[j].posicion
			IF rm_ord[i].chk_asc = 'S' THEN
				LET order_clause = order_clause || ' ASC'
			ELSE
				LET order_clause = order_clause || ' DESC'
			END IF
			IF i <> num_ord THEN
				LET order_clause = order_clause || ', '
			END IF
		END IF
	END FOR
END FOR

LET query = query CLIPPED || order_clause CLIPPED

RETURN query

END FUNCTION



REPORT rep_cartera(areaneg, zona_cobro, codcli, nomcli, tipo_doc, num_doc,
		   dividendo, num_sri, fecha_emi, fecha_vcto, antiguedad, saldo)
DEFINE areaneg		LIKE gent003.g03_areaneg
DEFINE zona_cobro	VARCHAR(10)
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE num_sri		LIKE cxct020.z20_num_sri
DEFINE fecha_emi	LIKE cxct020.z20_fecha_emi
DEFINE fecha_vcto	LIKE cxct020.z20_fecha_vcto
DEFINE antiguedad	INTEGER
DEFINE saldo		LIKE cxct020.z20_saldo_cap
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	0
	RIGHT  MARGIN	132
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT
PAGE HEADER
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra (12 cpi)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo      = "MODULO: COBRANZAS"
	LET long        = LENGTH(modulo)
	LET usuario     = 'USUARIO: ', UPSHIFT(vg_usuario)
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C','LISTADO DETALLE DE CARTERA POR COBRAR',80)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 036, titulo,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 042, "** ANIO           : ", rm_par.anho USING "<<<<",
	      COLUMN 080, "** MES: ", fl_justifica_titulo('I',
				UPSHIFT(fl_retorna_nombre_mes(rm_par.mes)), 10)
	PRINT COLUMN 042, "** MONEDA         : ", rm_par.g13_nombre
	IF rm_par.tipo_vcto = 'P' THEN
		PRINT COLUMN 042, "** TIPO VCTO.     : POR VENCER"
	ELSE 
		IF rm_par.tipo_vcto = 'V' THEN
			PRINT COLUMN 042, "** TIPO VCTO.     : VENCIDO"
		ELSE
			PRINT COLUMN 042, "** TIPO VCTO.     : TODOS"
		END IF
	END IF
	--#IF rm_par.areaneg IS NOT NULL THEN
		PRINT COLUMN 042, "** AREA DE NEGOCIO: ", rm_par.n_areaneg
	--#END IF
	--#IF rm_par.zona_cobro IS NOT NULL THEN
		PRINT COLUMN 042, "** ZONA DE COBRO  : ", rm_par.n_zona_cobro
	--#END IF
	--#IF rm_par.tipocli IS NOT NULL THEN
		PRINT COLUMN 042, "** TIPO DE CLIENTE: ", rm_par.n_tipocli
	--#END IF
	--#IF rm_par.tipocartera IS NOT NULL THEN
		PRINT COLUMN 042, "** TIPO DE CARTERA: ", rm_par.n_tipocartera
	--#END IF
	--#IF rm_par.r01_codigo IS NOT NULL THEN
		PRINT COLUMN 042, "** VENDEDOR       : ", rm_par.r01_nombres
	--#END IF
	--#IF rm_par.localidad IS NOT NULL THEN
		PRINT COLUMN 042, "** LOCALIDAD      : ",
			rm_par.localidad USING '&&', " ", rm_par.tit_localidad
	--#END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 114, usuario
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "AREA",
	      COLUMN 007, "ZONA",
	      COLUMN 013, "CLIENTE",
	      COLUMN 052, "DOCUMENTO",
	      COLUMN 071, "NUMERO SRI",
	      COLUMN 087, "FECHA EMI.",
	      COLUMN 098, "FECHA VCTO.",
	      COLUMN 109, fl_justifica_titulo('D', "DIAS", 7),
	      COLUMN 117, fl_justifica_titulo('D', "SALDO", 16)
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	IF zona_cobro IS NULL THEN
		LET zona_cobro = '  '
	END IF
	NEED 3 LINES
	PRINT COLUMN 001, fl_justifica_titulo('D', areaneg, 3),
	      COLUMN 007, fl_justifica_titulo('D', zona_cobro, 5) CLIPPED,
	      COLUMN 014, fl_justifica_titulo('D', codcli, 6) CLIPPED, 
	      COLUMN 021, nomcli[1,29] CLIPPED,
	      COLUMN 052, tipo_doc, '-', 
	      		  fl_justifica_titulo('I', num_doc, 11) CLIPPED, '-', 
	      		  fl_justifica_titulo('I', dividendo, 3) USING "&&&",
	      COLUMN 071, num_sri CLIPPED,
	      COLUMN 087, fecha_emi USING "dd-mm-yyyy",
	      COLUMN 098, fecha_vcto USING "dd-mm-yyyy",
	      COLUMN 109, antiguedad USING "---,--&",
	      COLUMN 117, saldo USING "#,###,###,##&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 117, "------------------"
	PRINT COLUMN 117, SUM(saldo) USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp
	--, 'E' 

END REPORT



FUNCTION ordenar_por()
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE asc_ant		CHAR
DEFINE desc_ant		CHAR
DEFINE campo		VARCHAR(20)
DEFINE col_ant		VARCHAR(20)

CALL set_count(num_ord)
LET int_flag = 0
INPUT ARRAY rm_ord WITHOUT DEFAULTS FROM rm_ord.* 
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2) 
		IF INFIELD(col) THEN
			CALL ayuda_campos() RETURNING campo
			IF campo IS NOT NULL THEN
				LET rm_ord[i].col = campo
				DISPLAY rm_ord[i].col TO rm_ord[i].col
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
		LET i = arr_curr()
	AFTER FIELD col
		IF rm_ord[i].col IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Debe elegir una columna.','exclamation')
			CALL fl_mostrar_mensaje('Debe elegir una columna.','exclamation')
			NEXT FIELD col	
		END IF
		INITIALIZE campo TO NULL
		FOR j = 1 TO num_campos
			IF rm_ord[i].col = rm_campos[j].nombre THEN
				LET campo = 'OK'
				EXIT FOR
			END IF
		END FOR
		IF campo IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Campo no existe.','exclamation')
			CALL fl_mostrar_mensaje('Campo no existe.','exclamation')
			NEXT FIELD col
		END IF
		DISPLAY rm_ord[i].col TO rm_ord[i].col
	BEFORE FIELD chk_asc
		LET asc_ant = rm_ord[i].chk_asc
	AFTER FIELD chk_asc
		IF rm_ord[i].chk_asc <> asc_ant THEN
			IF rm_ord[i].chk_asc = 'S' THEN
				LET rm_ord[i].chk_desc = 'N'
			ELSE
				LET rm_ord[i].chk_desc = 'S'
			END IF
			DISPLAY rm_ord[i].* TO rm_ord[i].*
		END IF
	BEFORE FIELD chk_desc
		LET desc_ant = rm_ord[i].chk_desc
	AFTER FIELD chk_desc
		IF rm_ord[i].chk_desc <> desc_ant THEN
			IF rm_ord[i].chk_desc = 'S' THEN
				LET rm_ord[i].chk_asc = 'N'
			ELSE
				LET rm_ord[i].chk_asc = 'S'
			END IF
			DISPLAY rm_ord[i].* TO rm_ord[i].*
		END IF
	AFTER INPUT
		FOR i = 1 TO num_ord 
			FOR j = 1 TO num_ord  
				IF j <> i AND rm_ord[j].col = rm_ord[i].col THEN
					--CALL fgl_winmessage(vg_producto,'No puede ordenar dos veces sobre el mismo campo.','exclamation')
					CALL fl_mostrar_mensaje('No puede ordenar dos veces sobre el mismo campo.','exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
END INPUT

END FUNCTION



FUNCTION campos_forma()

LET rm_campos[1].nombre = 'AREA DE NEGOCIO'
LET rm_campos[1].posicion = 1
LET rm_campos[2].nombre = 'NOMBRE CLIENTE'
LET rm_campos[2].posicion = 4
LET rm_campos[3].nombre = 'ZONA DE COBRO'
LET rm_campos[3].posicion = 2
LET rm_campos[4].nombre = 'FECHA DE EMISIÓN'
LET rm_campos[4].posicion = 8
LET rm_campos[5].nombre = 'FECHA DE VENCIMIENTO'
LET rm_campos[5].posicion = 9

LET num_campos = 5

END FUNCTION



FUNCTION ayuda_campos()
DEFINE rh_campos	ARRAY[11] OF VARCHAR(20)
DEFINE i, j             SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla

FOR i = 1 TO num_campos 
	LET rh_campos[i] = rm_campos[i].nombre
END FOR
LET filas_max = 100
OPEN WINDOW wh AT 06, 15 WITH 08 ROWS, 25 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
			BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_400_2 FROM '../forms/cxcf400_2'
ELSE
	OPEN FORM f_400_2 FROM '../forms/cxcf400_2c'
END IF
DISPLAY FORM f_400_2
LET filas_pant = fgl_scr_size("rh_campos")

CALL set_count(num_campos)
LET int_flag = 0
DISPLAY ARRAY rh_campos TO rh_campos.*
        ON KEY(RETURN)
		LET int_flag = 1
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', num_campos
END DISPLAY
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh_campos[1] TO NULL
        RETURN rh_campos[1]
END IF
LET  i = arr_curr()
RETURN rh_campos[i]

END FUNCTION



FUNCTION obtener_num_sri(areaneg, cod_loc, cod_tran, num_tran)
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE cod_loc		LIKE rept038.r38_localidad
DEFINE cod_tran		LIKE rept038.r38_cod_tran
DEFINE num_tran		LIKE rept038.r38_num_tran
DEFINE tipo_fuente	LIKE rept038.r38_tipo_fuente
DEFINE num_sri		LIKE rept038.r38_num_sri
DEFINE query		CHAR(400)

LET num_sri = NULL
IF cod_tran IS NULL THEN
	RETURN num_sri
END IF
CASE areaneg
	WHEN 1
		LET tipo_fuente = 'PR'
	WHEN 2
		LET tipo_fuente = 'OT'
END CASE
LET query = 'SELECT UNIQUE r38_num_sri ',
		' FROM ', retorna_base_loc(cod_loc) CLIPPED, 'rept038',
		' WHERE r38_compania     = ', vg_codcia,
		'   AND r38_localidad    = ', cod_loc,
		'   AND r38_tipo_doc    IN ("FA", "NV")',
		'   AND r38_tipo_fuente  = "', tipo_fuente, '"',
		'   AND r38_cod_tran     = "', cod_tran, '"',
		'   AND r38_num_tran     = ', num_tran
PREPARE cons_r38 FROM query
DECLARE q_cons_r38 CURSOR FOR cons_r38
OPEN q_cons_r38
FETCH q_cons_r38 INTO num_sri
CLOSE q_cons_r38
FREE q_cons_r38
RETURN num_sri

END FUNCTION



FUNCTION muestra_tipovcto(tipovcto)
DEFINE tipovcto		CHAR(1)

CASE tipovcto
	WHEN 'P'
		DISPLAY 'POR VENCER' TO tit_tipo_vcto
	WHEN 'V'
		DISPLAY 'VENCIDOS' TO tit_tipo_vcto
	WHEN 'T'
		DISPLAY 'T O D O S' TO tit_tipo_vcto
	OTHERWISE
		CLEAR tipo_vcto, tit_tipo_vcto
END CASE

END FUNCTION



FUNCTION lee_factura_inv(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r19		RECORD LIKE rept019.*

CALL fl_lee_cabecera_transaccion_rep(codcia, codloc, cod_tran, num_tran)
	RETURNING r_r19.*
IF r_r19.r19_compania IS NULL THEN
	CALL lee_cabecera_transaccion_loc(codcia, codloc, cod_tran, num_tran)
		RETURNING r_r19.*
END IF
RETURN r_r19.*

END FUNCTION



FUNCTION lee_cabecera_transaccion_loc(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE query		CHAR(400)

INITIALIZE r_r19.* TO NULL
IF NOT (codloc = 2 OR codloc = 4) THEN
	RETURN r_r19.*
END IF
LET query = 'SELECT * FROM ', retorna_base_loc(codloc) CLIPPED, 'rept019 ',
		' WHERE r19_compania  = ', codcia,
		'   AND r19_localidad = ', codloc,
		'   AND r19_cod_tran  = "', cod_tran, '"',
		'   AND r19_num_tran  = ', num_tran
PREPARE cons_f_loc FROM query
DECLARE q_cons_f_loc CURSOR FOR cons_f_loc
OPEN q_cons_f_loc
FETCH q_cons_f_loc INTO r_r19.*
CLOSE q_cons_f_loc
FREE q_cons_f_loc
RETURN r_r19.*

END FUNCTION



FUNCTION lee_vendedor_loc(codcia, vendedor)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE vendedor		LIKE rept019.r19_vendedor
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE query		CHAR(400)

INITIALIZE r_r01.* TO NULL
IF NOT (vg_codloc = 2 OR vg_codloc = 4) THEN
	RETURN r_r01.*
END IF
LET query = 'SELECT * FROM ', retorna_base_loc(vg_codloc) CLIPPED, 'rept001 ',
		' WHERE r01_compania = ', codcia,
		'   AND r01_codigo   = ', vendedor
PREPARE cons_v_loc FROM query
DECLARE q_cons_v_loc CURSOR FOR cons_v_loc
OPEN q_cons_v_loc
FETCH q_cons_v_loc INTO r_r01.*
CLOSE q_cons_v_loc
FREE q_cons_v_loc
RETURN r_r01.*

END FUNCTION



FUNCTION retorna_base_loc(codloc)
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE base_loc		VARCHAR(10)

LET base_loc = NULL
IF NOT (codloc = 2 OR codloc = 4) THEN
	RETURN base_loc CLIPPED
END IF
SELECT g56_base_datos INTO base_loc
	FROM gent056
	WHERE g56_compania  = vg_codcia
	  AND g56_localidad = vg_codloc
IF base_loc IS NOT NULL THEN
	LET base_loc = base_loc CLIPPED, ':'
END IF
RETURN base_loc CLIPPED

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
