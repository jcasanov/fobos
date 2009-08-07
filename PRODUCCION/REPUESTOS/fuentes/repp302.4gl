------------------------------------------------------------------------------
-- Titulo           : repp302.4gl - Consulta de Item Pedidos
-- Elaboracion      : 06-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp302 base módulo compañía localidad [pedido]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_rep		RECORD LIKE rept016.*
DEFINE rm_rep2		RECORD LIKE rept017.*
DEFINE rm_rep3		RECORD LIKE rept010.*
DEFINE vm_pedido	LIKE rept016.r16_pedido
DEFINE vm_max_elm       SMALLINT
DEFINE vm_num_elm       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_repd		ARRAY [1000] OF RECORD
				r17_item	LIKE rept017.r17_item,
				tit_descripcion	LIKE rept010.r10_nombre,
				tit_cantidad	SMALLINT,
				r17_pedido	LIKE rept017.r17_pedido,
				r16_fec_llegada	LIKE rept016.r16_fec_llegada
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp302'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i,j,l,col	SMALLINT
DEFINE query		VARCHAR(500)

CALL fl_nivel_isolation()
LET vm_max_elm = 1000
OPEN WINDOW w_rep AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/repf302_1"
FOR i = 1 TO vm_max_elm
	INITIALIZE rm_repd[i].* TO NULL
END FOR
INITIALIZE rm_rep.*, rm_rep2.*, rm_rep3.* TO NULL
IF num_args() = 5 THEN
	LET vm_pedido = arg_val(5)
	--SELECT r17_item, r10_nombre, r17_cantped - r17_cantrec cantidad,
	SELECT r17_item, r10_nombre, r17_cantped cantidad,
		r17_pedido, r16_fec_llegada
		FROM rept016, rept017, rept010
			WHERE r16_compania  = vg_codcia AND 
			      r16_localidad = vg_codloc AND
			      r16_pedido    = vm_pedido AND
			      r17_compania  = r16_compania AND
			      r17_localidad = r16_localidad AND
			      r17_pedido    = r16_pedido AND 
			      --r17_cantrec   < r17_cantped AND
			      r17_compania  = r10_compania AND 
			      r17_item      = r10_codigo
		INTO TEMP tmp_detalle_rep
ELSE
	SELECT r17_item, r10_nombre, r17_cantped - r17_cantrec cantidad,
		r17_pedido, r16_fec_llegada
		FROM rept016, rept017, rept010
			WHERE r16_compania  = vg_codcia AND 
			      r16_localidad = vg_codloc AND
			      r17_compania  = r16_compania AND
			      r17_localidad = r16_localidad AND
			      r17_pedido    = r16_pedido AND 
			      r17_cantrec   < r17_cantped AND
			      r17_compania  = r10_compania AND 
			      r17_item      = r10_codigo
		INTO TEMP tmp_detalle_rep
END IF
SELECT COUNT(*) INTO vm_num_elm FROM tmp_detalle_rep
IF vm_num_elm = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1] = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE
	DISPLAY FORM f_rep
	DISPLAY 'Item'        TO tit_col1
	DISPLAY 'Descripción' TO tit_col2
	DISPLAY 'Cant.'       TO tit_col3
	DISPLAY 'Pedidos'     TO tit_col4
	DISPLAY 'Fec. Lle.'   TO tit_col5
	LET query = 'SELECT * FROM tmp_detalle_rep ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET i = 1
	FOREACH q_deto INTO rm_repd[i].*
		LET i = i + 1
		IF i > vm_max_elm THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT PROGRAM
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rm_repd TO rm_repd.*
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores(j,i)
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			CALL ver_pedido(j)
			LET int_flag = 0
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
		ON KEY(F19)
			LET col = 5
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

END FUNCTION



FUNCTION muestra_contadores(cor,num)
DEFINE cor,num	         SMALLINT
                                                                                
DISPLAY "" AT 21,1
DISPLAY cor, " de ", num AT 21, 4
                                                                                
END FUNCTION



FUNCTION ver_pedido(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun repp204 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia,' ', vg_codloc, ' ',
	'"', rm_repd[i].r17_pedido, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
