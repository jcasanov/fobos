------------------------------------------------------------------------------
-- Titulo           : repp306.4gl - Consulta de proformas
-- Elaboracion      : 11-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp306 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE rm_prof		ARRAY[32767] OF RECORD
				fecha_ini	DATE,
				r21_numprof	LIKE rept021.r21_numprof,
				r21_nomcli	LIKE rept021.r21_nomcli,
				siglas_vend	LIKE rept001.r01_iniciales,
				fecha_max	DATE,
				r21_tot_neto	LIKE rept021.r21_tot_neto,
				ind_fact	CHAR(1)
			END RECORD
DEFINE rm_par		RECORD
				r21_moneda	LIKE gent013.g13_moneda,
				tit_moneda	CHAR(20),
				fecha_ini	DATE,
				fecha_fin	DATE,
				r21_vendedor	LIKE rept001.r01_codigo,
				tit_vend	LIKE rept001.r01_nombres,
				flag_fact	CHAR(1)
			END RECORD
DEFINE vm_max_rows	INTEGER
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_vend		RECORD LIKE rept001.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp306.err')
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
LET vg_proceso = 'repp306'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_rep		RECORD LIKE rept000.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

INITIALIZE rm_par.* TO NULL
LET rm_par.r21_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.r21_moneda) RETURNING r_mon.* 
LET rm_par.tit_moneda = r_mon.g13_nombre
LET rm_par.fecha_fin = vg_fecha
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_imp AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_cons FROM '../forms/repf306_1'
ELSE
	OPEN FORM f_cons FROM '../forms/repf306_1c'
END IF
DISPLAY FORM f_cons
LET vm_max_rows = 32767
--#DISPLAY 'Fecha Ini.'     TO tit_col1
--#DISPLAY '#'		    TO tit_col2
--#DISPLAY 'Cliente'        TO tit_col3
--#DISPLAY 'Ven'            TO tit_col4
--#DISPLAY 'Validéz'        TO tit_col5
--#DISPLAY 'Valor Neto'     TO tit_col6
--#DISPLAY 'F'              TO tit_col7
--#LET vm_size_arr = fgl_scr_size('rm_prof')
IF vg_gui = 0 THEN
	LET vm_size_arr = 12
END IF
INITIALIZE rm_par.* TO NULL
LET rm_par.flag_fact = 'T'
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
DECLARE qu_vd CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia AND
	      r01_user_owner = vg_usuario
OPEN qu_vd 
INITIALIZE rm_vend.* TO NULL
FETCH qu_vd INTO rm_vend.*
IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G' THEN
	LET rm_par.r21_vendedor = rm_vend.r01_codigo
	LET rm_par.tit_vend     = rm_vend.r01_nombres
END IF
LET rm_par.r21_moneda   = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.r21_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('Moneda no existe.','stop')
	EXIT PROGRAM
END IF
LET rm_par.tit_moneda = r_mon.g13_nombre
WHILE TRUE
	FOR i = 1 TO vm_size_arr 
		CLEAR rm_prof[i].*
	END FOR
	CALL lee_parametros1()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL lee_parametros2()
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL muestra_consulta()
END WHILE
LET int_flag = 0
CLOSE WINDOW w_imp
EXIT PROGRAM

END FUNCTION



FUNCTION lee_parametros1()
DEFINE resp		CHAR(3)
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_aux		VARCHAR(30)
DEFINE num_dec		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_r01		RECORD LIKE rept001.*

DISPLAY BY NAME rm_par.*
LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)          
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r21_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux, tit_aux,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.r21_moneda     = mon_aux
				LET rm_par.tit_moneda = tit_aux
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(r21_vendedor) AND (rm_g05.g05_tipo <> 'UF' OR
		   rm_vend.r01_tipo = 'J' OR rm_vend.r01_tipo = 'G' OR
		   rm_g04.g04_grupo = 'SI')
		THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'F') 
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN                
				LET rm_par.r21_vendedor = r_r01.r01_codigo
				LET rm_par.tit_vend     = r_r01.r01_nombres
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r21_moneda
		IF rm_par.r21_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.r21_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD r21_moneda
			END IF
			LET rm_par.tit_moneda = r_mon.g13_nombre
			DISPLAY BY NAME rm_par.tit_moneda
		ELSE
			LET rm_par.tit_moneda = NULL
			CLEAR tit_moneda
		END IF
	AFTER FIELD r21_vendedor
		IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G' AND
		   rm_g04.g04_grupo <> 'SI'
		THEN
			LET rm_par.r21_vendedor = rm_vend.r01_codigo 
			DISPLAY BY NAME rm_par.*
		END IF		
		IF rm_par.r21_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_par.r21_vendedor) 
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Vendedor no existe.','exclamation')
				CALL fl_mostrar_mensaje('Vendedor no existe.','exclamation')
				NEXT FIELD r21_vendedor
			END IF
			LET rm_par.tit_vend = r_r01.r01_nombres
			DISPLAY BY NAME rm_par.tit_vend
		ELSE
			LET rm_par.tit_vend = NULL
			CLEAR tit_vend
		END IF
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_fin IS NULL THEN
				LET rm_par.fecha_fin = vg_fecha
				DISPLAY BY NAME rm_par.fecha_fin
			END IF
		END IF
	AFTER INPUT
		IF int_flag THEN
			EXIT INPUT
		END IF
		IF rm_par.fecha_ini IS NOT NULL AND rm_par.fecha_fin IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Si ingresa fecha inicial debe ingresar fecha final tambien.','exclamation')
			CALL fl_mostrar_mensaje('Si ingresa fecha inicial debe ingresar fecha final tambien.','exclamation')
			CONTINUE INPUT
		END IF
		IF rm_par.fecha_fin IS NOT NULL AND rm_par.fecha_ini IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Si ingresa fecha final debe ingresar fecha inicial tambien.','exclamation')
			CALL fl_mostrar_mensaje('Si ingresa fecha final debe ingresar fecha inicial tambien.','exclamation')
			CONTINUE INPUT
		END IF
		IF  rm_par.fecha_fin IS NOT NULL 
		AND rm_par.fecha_ini IS NOT NULL 
		THEN
			IF rm_par.fecha_fin < rm_par.fecha_ini THEN
				--CALL fgl_winmessage(vg_producto,'La fecha final debe ser mayor a la fecha inicial.','exclamation')
				CALL fl_mostrar_mensaje('La fecha final debe ser mayor a la fecha inicial.','exclamation')
				CONTINUE INPUT
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()
DEFINE i		INTEGER
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(400)
DEFINE expr_fecha	VARCHAR(200)
DEFINE expr_vend	VARCHAR(100)
DEFINE expr_fact	VARCHAR(100)
DEFINE tot_prof		LIKE rept021.r21_tot_neto

LET int_flag = 0
CONSTRUCT expr_sql ON   r21_numprof, r21_nomcli, r21_tot_neto
		   FROM r21_numprof, r21_nomcli, r21_tot_neto
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	RETURN
END IF
ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)

LET expr_fecha = ' 1 = 1 '
IF rm_par.fecha_ini IS NOT NULL THEN
	LET expr_fecha = ' DATE(r21_fecing) BETWEEN "', rm_par.fecha_ini, '"',
					  ' AND "', rm_par.fecha_fin, '"'
END IF

LET expr_vend = ' 1 = 1 '
IF rm_par.r21_vendedor IS NOT NULL THEN
	LET expr_vend = ' r21_vendedor = ', rm_par.r21_vendedor
END IF

LET expr_fact = ' 1 = 1 '
IF rm_par.flag_fact = 'F' OR rm_par.flag_fact = 'X' THEN
	LET expr_fact = ' r21_cod_tran IS NOT NULL '
END IF
IF rm_par.flag_fact = 'N' THEN
	LET expr_fact = ' r21_cod_tran IS NULL '
END IF	

LET query = 'SELECT DATE(r21_fecing) fecha_ini, r21_numprof, r21_nomcli, ',
		'r01_iniciales, (DATE(r21_fecing) + r21_dias_prof) fecha_max, ',
		--'r21_tot_neto, r21_cod_tran, r21_num_tran, r21_compania, ',
		'(r21_tot_bruto - r21_tot_dscto) r21_tot_neto, r21_cod_tran, ',
		'r21_num_tran, r21_compania, r21_localidad, r01_nombres, ',
		'r21_codcli ',
		' FROM rept021, rept001 ',
		' WHERE r21_compania  = ', vg_codcia,
		'   AND r21_localidad = ', vg_codloc,
		'   AND r21_moneda    = "', rm_par.r21_moneda, '"',
		'   AND ', expr_fecha CLIPPED,
		'   AND ', expr_vend  CLIPPED,
		'   AND ', expr_sql   CLIPPED,
		'   AND ', expr_fact  CLIPPED,
		'   AND r01_compania  = r21_compania ',
		'   AND r01_codigo    = r21_vendedor ', 
		' INTO TEMP temp_prof'
PREPARE q_cit FROM query
EXECUTE q_cit
SELECT COUNT(*) INTO i FROM temp_prof
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE temp_prof
	LET int_flag = 1
	RETURN
END IF

IF rm_par.flag_fact = 'X' THEN
	DELETE FROM temp_prof
		WHERE r21_cod_tran = 'FA'
		  AND r21_num_tran IN
			(SELECT r19_num_tran FROM rept019
				WHERE r19_compania  = vg_codcia
				  AND r19_localidad = vg_codloc
				  AND r19_cod_tran  = r21_cod_tran
				  AND r19_num_tran  = r21_num_tran
				  AND r19_tipo_dev  IN ("DF", "AF"))
END IF

SELECT SUM(r21_tot_neto) INTO tot_prof FROM temp_prof
DISPLAY BY NAME tot_prof

ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION



FUNCTION muestra_consulta()
DEFINE i		INTEGER
DEFINE query		CHAR(400)
DEFINE num_rows		INTEGER
DEFINE comando		VARCHAR(100)
DEFINE r_r21		RECORD LIKE rept021.*

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT fecha_ini, r21_numprof, r21_nomcli, r01_iniciales,',
			' fecha_max, r21_tot_neto, r21_cod_tran ',
			' FROM temp_prof ',
			' ORDER BY ',
			vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
			vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i = 1
	FOREACH q_crep INTO rm_prof[i].*
		LET i = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_crep
	LET num_rows = i - 1
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY ARRAY rm_prof TO rm_prof.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_proforma(rm_prof[i].r21_numprof)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			IF rm_prof[i].ind_fact IS NOT NULL THEN
				CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, 
					rm_prof[i].r21_numprof)
					RETURNING r_r21.*
				CALL ver_factura(r_r21.r21_cod_tran,
					         r_r21.r21_num_tran)
				LET int_flag = 0
			END IF	
		ON KEY(F7)
			CALL imprimir(arr_count())
			LET int_flag = 0
		ON KEY(F8)
			CALL generar_archivo()
			LET int_flag = 0
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET i = 6
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#IF rm_prof[i].ind_fact IS NOT NULL THEN
				--#CALL dialog.keysetlabel("F6","Factura")
			--#ELSE
				--#CALL dialog.keysetlabel("F6","")
			--#END IF
			--#MESSAGE i, ' de ', num_rows
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F7","Imprimir")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF int_flag = 0 THEN
		CONTINUE WHILE
	END IF
	IF i <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1 = i 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
DROP TABLE temp_prof

END FUNCTION



FUNCTION ver_factura(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE param		VARCHAR(60)

LET param  = ' ', vg_codloc, ' "', cod_tran, '" ', num_tran  
CALL ejecuta_comando('REPUESTOS', vg_modulo, 'repp308 ', param)

END FUNCTION

                                                                                
                                                                                
FUNCTION ver_proforma(numprof)
DEFINE numprof		LIKE rept021.r21_numprof
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)

CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, numprof) RETURNING r_r21.*
LET param  = ' ', vg_codloc, ' ', r_r21.r21_numprof
LET modulo = 'REPUESTOS'
LET mod    = vg_modulo
LET prog   = 'repp220 '
IF r_r21.r21_num_ot IS NOT NULL OR r_r21.r21_num_presup IS NOT NULL THEN
	LET modulo = 'TALLER'
	LET mod    = 'TA'
	LET prog   = 'talp213 '
END IF
CALL ejecuta_comando(modulo, mod, prog, param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION generar_archivo()

ERROR 'Generando Archivo repp306.unl ... por favor espere'
SELECT fecha_ini, fecha_max, r01_nombres, r21_numprof, r21_codcli,
	r21_nomcli, r21_cod_tran, r22_item, r22_cantidad, r22_porc_descto,
	r22_val_descto, r22_precio, r21_num_tran, r21_compania
	FROM temp_prof, rept022
	WHERE r22_compania  = r21_compania
	  AND r22_localidad = r21_localidad
	  AND r22_numprof   = r21_numprof
	INTO TEMP t1
SELECT r10_compania, r10_codigo, r10_cod_clase, r72_desc_clase, r10_nombre,
	r10_filtro
	FROM rept010, rept072
	WHERE r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	INTO TEMP t2
UNLOAD TO "repp306.unl"
	SELECT fecha_ini, fecha_max, r01_nombres, r21_numprof, r21_codcli,
		r21_nomcli, r21_cod_tran, r22_item, r10_cod_clase,
		r72_desc_clase, r10_nombre, r22_cantidad, r22_val_descto,
		r22_precio, r10_filtro, r21_num_tran
		FROM t1, t2
		WHERE r10_compania = r21_compania
		  AND r10_codigo   = r22_item
DROP TABLE t1
DROP TABLE t2
--RUN 'mv repp306.unl /acero/fobos/tmp/repp306.unl'
RUN 'mv -f repp306.unl $HOME/tmp/repp306.unl'
CALL fl_mostrar_mensaje('Archivo Generado repp306.unl.', 'info')
ERROR ' '

END FUNCTION



FUNCTION imprimir(numelm)
DEFINE numelm		INTEGER
DEFINE i		INTEGER
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN       
END IF

START REPORT rep_proforma TO PIPE comando
--START REPORT rep_proforma TO FILE "prof.jcm"
	FOR i = 1 TO numelm
		OUTPUT TO REPORT rep_proforma(rm_prof[i].*)
	END FOR
FINISH REPORT rep_proforma

END FUNCTION



REPORT rep_proforma(r_rep)
DEFINE r_rep RECORD
	fecha_ini	DATE,
	r21_numprof	LIKE rept021.r21_numprof,
	r21_nomcli	LIKE rept021.r21_nomcli,
	siglas_vend	LIKE rept001.r01_iniciales,
	fecha_max	DATE,
	r21_tot_neto	LIKE rept021.r21_tot_neto,
	ind_fact	CHAR(1)
END RECORD

DEFINE r_cia		RECORD LIKE gent001.*

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	0
	RIGHT MARGIN	96 
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.

	LET modulo  = "MODULO: INVENTARIO"
	LET long    = LENGTH(modulo)
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE PROFORMA', 80)
		RETURNING titulo

	CALL fl_lee_compania(vg_codcia) RETURNING r_cia.*

	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_12cpi
	PRINT COLUMN 01,  r_cia.g01_razonsocial,
  	      COLUMN 85, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 01,  modulo CLIPPED,
	      COLUMN 33,  titulo CLIPPED,
	      COLUMN 89, UPSHIFT(vg_proceso)

	PRINT COLUMN 33,  "** MONEDA        : ", rm_par.r21_moneda,
						" ", rm_par.tit_moneda
	PRINT COLUMN 33,  "** VENDEDOR      : "; 
	IF rm_par.r21_vendedor IS NULL THEN
		PRINT "T O D O S"
	ELSE
		PRINT rm_par.r21_vendedor USING "&&&", " ", rm_par.tit_vend
	END IF
	
	PRINT COLUMN 33,  "** TIPO          : ";
	IF rm_par.flag_fact = 'T' THEN
		PRINT ' T O D A S'
	ELSE
		IF rm_par.flag_fact = 'F' THEN
			PRINT rm_par.flag_fact, ' FACTURADAS'
		ELSE
			PRINT rm_par.flag_fact, ' NO FACTURADAS'
		END IF
	END IF
	IF rm_par.fecha_ini IS NULL THEN
		PRINT COLUMN 48, "** FECHA INICIAL : ", 
				 rm_par.fecha_ini USING "dd-mm-yyyy",
				 "-  FECHA FINAL   : ", 
				 rm_par.fecha_fin USING "dd-mm-yyyy"
	ELSE
		SKIP 1 LINES
	END IF
	PRINT COLUMN 01, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 72, usuario
	SKIP 2 LINES
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 01,  "FECHA",
	      COLUMN 13,  "NUMERO",
	      COLUMN 21,  "CLIENTE",
	      COLUMN 63,  "VENDEDOR",
	      COLUMN 73,  fl_justifica_titulo("D", "VALOR NETO", 16)

	PRINT COLUMN 01,  "--------------",
	      COLUMN 13,  "--------",
	      COLUMN 21,  "------------------------------------------",
	      COLUMN 63,  "----------",
	      COLUMN 73,  "---------------------"

ON EVERY ROW
	PRINT COLUMN 01,  r_rep.fecha_ini USING "dd-mm-yyyy",
	      COLUMN 13,  r_rep.r21_numprof USING "######",
	      COLUMN 21,  r_rep.r21_nomcli[1, 40] CLIPPED,
	      COLUMN 63,  r_rep.siglas_vend,
	      COLUMN 73,  r_rep.r21_tot_neto  USING "#,###,###,##&.##",
	      COLUMN 94,  r_rep.ind_fact
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 73,  "----------------"
	PRINT COLUMN 60, "TOTALES ==>  ",
	      COLUMN 73,  SUM(r_rep.r21_tot_neto) USING "#,###,###,##&.##"
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Proforma'                 AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Factura'                  AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Imprimir'                 AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Archivo'                  AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
