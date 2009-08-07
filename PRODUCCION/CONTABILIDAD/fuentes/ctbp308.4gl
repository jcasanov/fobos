------------------------------------------------------------------------------
-- Titulo           : ctbp308.4gl - Consulta de comprobantes contables
-- Elaboracion      : 31-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp308 base m�dulo compa��a
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_ctb		RECORD LIKE ctbt012.*
DEFINE rm_ctb2		RECORD LIKE ctbt013.*
DEFINE vm_max_elm       SMALLINT
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_elm       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_fec_vcto	DATE
DEFINE vm_moneda 	LIKE ctbt012.b12_moneda
DEFINE vm_total_deb     LIKE ctbt013.b13_valor_base
DEFINE vm_total_cre     LIKE ctbt013.b13_valor_base
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_nivel_cta	LIKE ctbt001.b01_nivel
DEFINE rm_cab 		ARRAY [1000] OF RECORD
				b12_estado	LIKE ctbt012.b12_estado,
				b12_tipo_comp	LIKE ctbt012.b12_tipo_comp,
				b12_num_comp	LIKE ctbt012.b12_num_comp,
				b12_subtipo	LIKE ctbt012.b12_subtipo,
				b12_origen	LIKE ctbt012.b12_origen,
				b12_fec_proceso	LIKE ctbt012.b12_fec_proceso,
				--b12_fecing	LIKE ctbt012.b12_fecing,
				b12_glosa	LIKE ctbt012.b12_glosa
			END RECORD
DEFINE rm_det		ARRAY [1000] OF RECORD
				b13_cuenta	LIKE ctbt013.b13_cuenta,
				tit_descripcion	LIKE ctbt010.b10_descripcion,
				tit_debito  	LIKE ctbt013.b13_valor_base,
				tit_credito   	LIKE ctbt013.b13_valor_base
			END RECORD
DEFINE rm_descri	ARRAY [1000] OF RECORD
				tipo		LIKE ctbt013.b13_tipo_doc,
				glosa		LIKE ctbt013.b13_glosa
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp308.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'ctbp308'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT

CALL fl_nivel_isolation()
LET vm_max_elm  = 1000
LET vm_max_det  = 1000
CREATE TEMP TABLE tmp_detalle_comp(
		b13_cuenta	CHAR(12),
		tit_descripcion	VARCHAR(40,20),
		tit_debito	DECIMAL(14,2),
		tit_credito	DECIMAL(14,2),
		b13_valor_base	DECIMAL(14,2),
		b13_valor_aux	DECIMAL(14,2),
		b13_tipo_doc	CHAR(3),
		b13_glosa	VARCHAR(35,0)
	)
OPEN WINDOW w_mas AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf308_1"
DISPLAY FORM f_ctb
CALL mostrar_cabecera_forma()

SELECT MAX(b01_nivel) INTO vm_nivel_cta FROM ctbt001
IF vm_nivel_cta IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No se ha configurado el plan de cuentas.', 'stop')
	EXIT PROGRAM
END IF

FOR i = 1 TO vm_max_elm
	INITIALIZE rm_cab[i].* TO NULL
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE rm_det[i].*, rm_descri[i].* TO NULL
END FOR
INITIALIZE rm_ctb.*, rm_ctb2.* TO NULL
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_num_elm = 0
LET vm_num_det = 0
LET vm_scr_lin = 0
CALL muestra_contadores_cab(0)
CALL muestra_contadores_det(0)
MENU 'OPCIONES'
	COMMAND KEY ('C') 'Consultar'
		CALL control_consulta()
		CALL mostrar_cabecera_forma()
	COMMAND KEY('S') 'Salir'
                EXIT MENU
END MENU

END FUNCTION



FUNCTION mostrar_cabecera_forma()

DISPLAY 'E'           TO tit_col1
DISPLAY 'TP'          TO tit_col2
DISPLAY 'No.'         TO tit_col3
DISPLAY 'Sub.'        TO tit_col4
DISPLAY 'Fec. Proc.'  TO tit_col5
DISPLAY 'O'	      TO tit_col6
DISPLAY 'Descripci�n' TO tit_col7
DISPLAY 'Cuenta'      TO tit_col8
DISPLAY 'Descripci�n' TO tit_col9
DISPLAY 'D�bito'      TO tit_col10
DISPLAY 'Cr�dito'     TO tit_col11

END FUNCTION



FUNCTION control_consulta()
DEFINE j,l,col		SMALLINT
DEFINE query		VARCHAR(1500)
DEFINE expr_sql     VARCHAR(600)
DEFINE expr_cta     VARCHAR(600)
DEFINE expr_fec     VARCHAR(600)
DEFINE r_tip		RECORD LIKE ctbt004.*

DEFINE b13_cuenta	LIKE ctbt013.b13_cuenta
DEFINE r_b10		RECORD LIKE ctbt010.*


LET vm_num_elm   = 0
LET vm_num_det   = 0
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET col          = 2
CALL borrar_cabecera()
CALL borrar_detalle()
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON b12_estado,b12_tipo_comp,b12_num_comp,
	b12_subtipo, b12_origen, b12_fec_proceso,b12_glosa
	ON KEY(F2)
		IF INFIELD(b12_subtipo) THEN
			CALL fl_ayuda_subtipos_comprobantes(vg_codcia)
				RETURNING r_tip.b04_subtipo,
					  r_tip.b04_nombre
			IF r_tip.b04_subtipo IS NOT NULL THEN
				DISPLAY r_tip.b04_subtipo TO b12_subtipo
			END IF
		END IF
END CONSTRUCT
INITIALIZE rm_det[1].b13_cuenta TO NULL
CONSTRUCT BY NAME expr_cta ON b13_cuenta 
	ON KEY(F2)	
		IF INFIELD(b13_cuenta) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel_cta) 
				RETURNING r_b10.b10_cuenta, r_b10.b10_descripcion 
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_det[1].b13_cuenta = r_b10.b10_cuenta
				DISPLAY BY NAME rm_det[1].b13_cuenta
			END IF	
		END IF
END CONSTRUCT
IF expr_cta = ' 1=1 ' THEN
	LET expr_cta = ' ' 
ELSE
	LET expr_cta = ' AND EXISTS (SELECT b13_tipo_comp, b13_num_comp FROM ctbt013 ',
						   	   '  WHERE b13_compania  = b12_compania ',   
						       '    AND b13_tipo_comp = b12_tipo_comp ',   
						       '    AND b13_num_comp  = b12_num_comp ',   
						       '    AND b13_cuenta    = "', rm_det[1].b13_cuenta CLIPPED, 
							   '")'   
END IF

LET query = 'SELECT * FROM ctbt012',
			' WHERE b12_compania  = ', vg_codcia, ' AND ',
				expr_sql CLIPPED, expr_cta CLIPPED,
			' INTO TEMP tt_ctas '

PREPARE stmnt1 FROM query
EXECUTE stmnt1

LET expr_fec = ''
WHILE TRUE
	LET query = 'SELECT b12_estado, b12_tipo_comp, b12_num_comp,',
			' b12_subtipo, b12_origen, b12_fec_proceso, ',
			' b12_glosa, b12_moneda',
			' FROM tt_ctas',
			' WHERE b12_compania  = ', vg_codcia, expr_fec CLIPPED,
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET vm_num_elm = 1
	FOREACH q_deto INTO rm_cab[vm_num_elm].*, vm_moneda
		LET vm_num_elm = vm_num_elm + 1
		IF vm_num_elm > vm_max_elm THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_elm = vm_num_elm - 1
	IF vm_num_elm = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		CLEAR FORM
		RETURN
	END IF
	CALL set_count(vm_num_elm)
	LET int_flag = 0
	DISPLAY ARRAY rm_cab TO rm_cab.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
			CALL dialog.keysetlabel('F6', 'Ver Comprobante')
			CALL dialog.keysetlabel('F7', 'Filtrar')
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores_cab(j)
			CALL fl_lee_subtipo_comprob_contable(vg_codcia,
						rm_cab[j].b12_subtipo)
				RETURNING r_tip.*
			DISPLAY r_tip.b04_nombre TO tit_subtipo
			CALL muestra_detalle(rm_cab[j].b12_tipo_comp,
						rm_cab[j].b12_num_comp)
			LET int_flag = 0
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			CALL muestra_detalle_arr(rm_cab[j].b12_tipo_comp,
						rm_cab[j].b12_num_comp)
			LET int_flag = 0
		ON KEY(F6)
			CALL ver_comprobante(rm_cab[j].b12_tipo_comp,
					     rm_cab[j].b12_num_comp)
			LET int_flag = 0
		ON KEY(F7)
			LET expr_fec = filtrar_comprobantes()
			LET int_flag = 0
			EXIT DISPLAY
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 6
			EXIT DISPLAY
		ON KEY(F21)
			LET col = 7
			EXIT DISPLAY
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

DROP TABLE tt_ctas

END FUNCTION



FUNCTION muestra_detalle(tipo,num)
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE num		LIKE ctbt012.b12_num_comp
DEFINE valor_base	LIKE ctbt013.b13_valor_base
DEFINE valor_aux	LIKE ctbt013.b13_valor_aux
DEFINE query            VARCHAR(600)
DEFINE i		SMALLINT
DEFINE r_det		RECORD LIKE ctbt013.*

CALL borrar_detalle()
INITIALIZE r_det.* TO NULL
LET int_flag = 0
DELETE FROM tmp_detalle_comp
INSERT INTO tmp_detalle_comp 
	SELECT  b13_cuenta, b10_descripcion, 0, 0, b13_valor_base,
		b13_valor_aux, b13_tipo_doc, b13_glosa
		FROM ctbt013, ctbt010
                WHERE b13_compania  = vg_codcia AND
		      b13_tipo_comp = tipo AND
		      b13_num_comp  = num AND	
		      b13_compania  = b10_compania AND 	
		      b13_cuenta    = b10_cuenta
IF vm_moneda = rg_gen.g00_moneda_base THEN
	UPDATE tmp_detalle_comp	SET tit_debito  = b13_valor_base
		WHERE b13_valor_base >= 0
	UPDATE tmp_detalle_comp	SET tit_credito = b13_valor_base
		WHERE b13_valor_base < 0
ELSE
	UPDATE tmp_detalle_comp	SET tit_debito  = b13_valor_aux
		WHERE b13_valor_aux >= 0
	UPDATE tmp_detalle_comp	SET tit_credito = b13_valor_aux
		WHERE b13_valor_aux < 0
END IF
LET vm_num_det = 1
DECLARE q_decomp CURSOR FOR SELECT * FROM tmp_detalle_comp ORDER BY 1
FOREACH q_decomp INTO rm_det[vm_num_det].*, valor_base, valor_aux,
			rm_descri[vm_num_det].*
	CALL valor_base_aux(valor_base,valor_aux,vm_num_det)
        LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
                EXIT FOREACH
        END IF
END FOREACH
CLOSE q_decomp
FREE q_decomp
LET vm_num_det = vm_num_det - 1
IF vm_num_det > 0 THEN
        LET int_flag = 0
	CALL muestra_contadores_det(0)
	FOR i = vm_scr_lin TO 1 STEP -1
		IF i <= vm_num_det THEN
			DISPLAY rm_det[i].* TO rm_det[i].*
		END IF
	END FOR
END IF
CALL sacar_total()
IF int_flag THEN
	CALL borrar_detalle()
        RETURN
END IF

END FUNCTION



FUNCTION muestra_detalle_arr(tipo,num)
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE num		LIKE ctbt012.b12_num_comp
DEFINE i,j,col		SMALLINT
DEFINE query		VARCHAR(600)
DEFINE r_det		RECORD LIKE ctbt013.*

LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE
	LET query = 'SELECT b13_cuenta, tit_descripcion, tit_debito, ',
			' tit_credito FROM tmp_detalle_comp',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto2 FROM query
	DECLARE q_deto2 CURSOR FOR deto2
	LET vm_num_det = 1
	FOREACH q_deto2 INTO rm_det[vm_num_det].*
		LET vm_num_det = vm_num_det + 1
		IF vm_num_det > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_det = vm_num_det - 1
	CALL set_count(vm_num_det)
	DISPLAY ARRAY rm_det TO rm_det.*
		BEFORE ROW
			LET i = arr_curr()
	        	LET j = scr_line()
			CALL muestra_contadores_det(i)
			DISPLAY rm_descri[i].tipo  TO b13_tipo_doc
			DISPLAY rm_descri[i].glosa TO b13_glosa
		BEFORE DISPLAY
			LET vm_scr_lin = fgl_scr_size('rm_det')
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F22)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F23)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F24)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F25)
			LET col = 4
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		CALL muestra_contadores_det(0)
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

END FUNCTION



FUNCTION llenar_detalle(r_det)
DEFINE r_det		RECORD LIKE ctbt013.*
DEFINE r_ctb		RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia,r_det.b13_cuenta) RETURNING r_ctb.*
LET rm_det[vm_num_det].b13_cuenta      = r_det.b13_cuenta
LET rm_det[vm_num_det].tit_descripcion = r_ctb.b10_descripcion
CALL valor_base_aux(r_det.b13_valor_base,r_det.b13_valor_aux,vm_num_det)

END FUNCTION



FUNCTION valor_base_aux(valor_base,valor_aux,i)
DEFINE valor_base		LIKE ctbt013.b13_valor_base
DEFINE valor_aux		LIKE ctbt013.b13_valor_aux
DEFINE i			SMALLINT

IF vm_moneda = rg_gen.g00_moneda_base THEN
	IF valor_base >= 0 THEN
		LET rm_det[i].tit_debito  = valor_base
		LET rm_det[i].tit_credito = 0
	ELSE
		LET rm_det[i].tit_debito  = 0
		LET rm_det[i].tit_credito = valor_base
	END IF
ELSE
	IF valor_aux >= 0 THEN
		LET rm_det[i].tit_debito  = valor_aux
		LET rm_det[i].tit_credito = 0
	ELSE
		LET rm_det[i].tit_debito  = 0
		LET rm_det[i].tit_credito = valor_aux
	END IF
END IF

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total_deb = 0
LET vm_total_cre = 0
FOR i = 1 TO vm_num_det
	LET vm_total_deb = vm_total_deb + rm_det[i].tit_debito
	LET vm_total_cre = vm_total_cre + rm_det[i].tit_credito
END FOR
DISPLAY vm_total_deb TO tit_total_deb
DISPLAY vm_total_cre TO tit_total_cre

END FUNCTION



FUNCTION borrar_cabecera()
DEFINE i  		SMALLINT

CALL muestra_contadores_cab(0)
FOR i = 1 TO fgl_scr_size('rm_cab')
        INITIALIZE rm_cab[i].* TO NULL
        CLEAR rm_cab[i].*
END FOR
CLEAR tit_subtipo

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR b13_tipo_doc, b13_glosa, tit_total_deb, tit_total_cre

END FUNCTION



FUNCTION muestra_contadores_cab(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 1,61
DISPLAY cor, " de ", vm_num_elm AT 1, 65

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 10,61
DISPLAY cor, " de ", vm_num_det AT 10, 65

END FUNCTION



FUNCTION ver_comprobante(tipo_comp, num_comp)

DEFINE comando 		VARCHAR(255)

DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp

LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'CONTABILIDAD', vg_separador, 'fuentes', 
	      vg_separador, '; fglrun ctbp201 ', vg_base, ' ',
	      'CB ', vg_codcia, ' ', vg_codloc, ' ', tipo_comp, ' ', num_comp

RUN comando

END FUNCTION



FUNCTION filtrar_comprobantes()
DEFINE expr		CHAR(300)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

INITIALIZE fecha_ini, fecha_fin TO NULL

OPEN WINDOW w_b308_2 AT 10,20 WITH 7 ROWS, 60 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb_2 FROM "../forms/ctbf308_2"
DISPLAY FORM f_ctb_2

INPUT BY NAME fecha_ini, fecha_fin WITHOUT DEFAULTS 

CLOSE WINDOW w_b308_2

LET expr = ' AND (b12_fecing BETWEEN EXTEND("', fecha_ini, '", YEAR TO SECOND) ',
                           ' AND EXTEND("', fecha_fin, '", YEAR TO SECOND)) ',
			' OR ',
           ' (b12_fec_modifi BETWEEN EXTEND("', fecha_ini, '", YEAR TO SECOND) ',
                               ' AND EXTEND("', fecha_fin, '", YEAR TO SECOND)) '

RETURN expr

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe m�dulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compa��a: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compa��a no est� activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no est� activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
