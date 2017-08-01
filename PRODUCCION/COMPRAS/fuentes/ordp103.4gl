--------------------------------------------------------------------------------
-- Titulo           : ordp103.4gl - Lista de precios de ítems por proveedor
-- Elaboracion      : 26-Jul-2017
-- Autor            : NPC
-- Formato Ejecucion: fglrun ordp103 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE rm_orden 		ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1		SMALLINT
DEFINE vm_columna_2		SMALLINT
DEFINE rm_par	 		RECORD 
							c04_codprov			LIKE ordt004.c04_codprov,
							p01_nomprov			LIKE cxpt001.p01_nomprov,
							c04_fecha_vigen		LIKE ordt004.c04_fecha_vigen,
							c04_usuario			LIKE ordt004.c04_usuario,
							c04_fecing			LIKE ordt004.c04_fecing
						END RECORD
DEFINE rm_detalle		ARRAY [2000] OF RECORD
							c04_cod_item  		LIKE ordt004.c04_cod_item,
							r10_nombre			LIKE rept010.r10_nombre,
							r10_precio_mb		LIKE rept010.r10_precio_mb,
							c04_pvp_prov_sug	LIKE ordt004.c04_pvp_prov_sug,
							c04_desc_prov		LIKE ordt004.c04_desc_prov,
							c04_costo_prov		LIKE ordt004.c04_costo_prov
						END RECORD
DEFINE rm_adi			ARRAY [2000] OF RECORD
							r10_codigo			LIKE rept010.r10_codigo,
							r10_precio_ant		LIKE rept010.r10_precio_ant,
							r72_desc_clase		LIKE rept072.r72_desc_clase,
							desc_item			LIKE rept010.r10_nombre
						END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp103.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN  -- Validar # parÃ¡metros correcto
	CALL fl_mostrar_mensaje('NÃºmero de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'ordp103'
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

CALL fl_nivel_isolation()
LET vm_max_det = 2000
LET lin_menu   = 0
LET row_ini    = 3
LET num_rows   = 22
LET num_cols   = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_ordp103 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
				MESSAGE LINE LAST, BORDER)
OPEN FORM f_ordf103_1 FROM "../forms/ordf103_1"
DISPLAY FORM f_ordf103_1
CALL muestra_contadores_det(0, 0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL botones_cabecera_forma()
LET vm_num_det = 0
CALL control_master()
CLOSE WINDOW w_ordp103
RETURN

END FUNCTION



FUNCTION control_master()

INITIALIZE rm_par.* TO NULL
LET rm_par.c04_fecha_vigen = TODAY
LET rm_par.c04_usuario     = vg_usuario
LET rm_par.c04_fecing      = CURRENT
WHILE TRUE
	CALL borrar_detalle()
	CALL muestra_contadores_det(0, 0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL cargar_detalle()
	WHILE TRUE
		CALL leer_detalle()
		IF int_flag THEN
			EXIT WHILE
		END IF
		CALL grabar_detalle()
	END WHILE
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE fec_ini		LIKE ordt004.c04_fecha_vigen

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(c04_codprov) THEN
			CALL fl_ayuda_proveedores()
				RETURNING r_p01.p01_codprov,
							r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET rm_par.c04_codprov = r_p01.p01_codprov
				LET rm_par.p01_nomprov = r_p01.p01_nomprov
				DISPLAY BY NAME rm_par.c04_codprov, rm_par.p01_nomprov
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD c04_fecha_vigen
		LET fec_ini = rm_par.c04_fecha_vigen
	AFTER FIELD c04_codprov
		IF rm_par.c04_codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_par.c04_codprov) RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el proveedor en la Compañía.','exclamation')
				NEXT FIELD c04_codprov
			END IF
			LET rm_par.p01_nomprov = r_p01.p01_nomprov
			DISPLAY BY NAME rm_par.p01_nomprov
			IF r_p01.p01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD c04_codprov
			END IF
		ELSE
			LET rm_par.p01_nomprov = NULL
			DISPLAY BY NAME rm_par.p01_nomprov
		END IF
	AFTER FIELD c04_fecha_vigen 
		IF rm_par.c04_fecha_vigen IS NULL THEN
			LET rm_par.c04_fecha_vigen = fec_ini     
			DISPLAY BY NAME rm_par.c04_fecha_vigen
		END IF
		IF rm_par.c04_fecha_vigen < TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de vigencia no puede ser menor a la de hoy.','exclamation')
			NEXT FIELD c04_fecha_vigen
		END IF
END INPUT

END FUNCTION



FUNCTION cargar_detalle()
DEFINE query		CHAR(1500)

LET query = 'SELECT c04_cod_item, r10_nombre, r10_precio_mb, ',
					'c04_pvp_prov_sug, c04_desc_prov, c04_costo_prov, ',
					'r10_codigo, r10_precio_mb AS prec_ant, r72_desc_clase, ',
					'r10_nombre AS desc_item ',
				' FROM ordt004, cxpt001, rept010, rept072 ',
				' WHERE c04_compania    = ', vg_codcia,
				'   AND c04_localidad   = ', vg_codloc,
				'   AND c04_codprov     = ', rm_par.c04_codprov,
				'   AND c04_fecha_vigen = "', rm_par.c04_fecha_vigen, '"',
				'   AND p01_codprov     = c04_codprov ',
				'   AND r10_compania    = c04_compania ',
				'   AND r10_cod_pedido  = c04_cod_item ',
				'   AND r72_compania    = r10_compania ',
				'   AND r72_linea       = r10_linea ',
				'   AND r72_sub_linea   = r10_sub_linea ',
				'   AND r72_cod_grupo   = r10_cod_grupo ',
				'   AND r72_cod_clase   = r10_cod_clase ',
			' INTO TEMP tmp_det '
PREPARE exec_query FROM query
EXECUTE exec_query
DECLARE q_det CURSOR FOR
		SELECT * FROM tmp_det
LET vm_num_det = 1
FOREACH q_det INTO rm_detalle[vm_num_det].*, rm_adi[vm_num_det].*
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
DROP TABLE tmp_det

END FUNCTION



FUNCTION leer_detalle()
DEFINE i, j, salir		SMALLINT
DEFINE k, l				SMALLINT
DEFINE resp				CHAR(6)

IF vm_num_det = 0 THEN
	LET vm_num_det = 1
END IF
CALL set_count(vm_num_det)
LET int_flag = 0
INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#LET int_flag = 0
	ON KEY(F5)
		LET i = arr_curr()
		LET j = scr_line()
		IF rm_adi[i].r10_codigo IS NOT NULL THEN
			CALL mostrar_item(rm_adi[i].r10_codigo)
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1", "")
		--#CALL dialog.keysetlabel("CONTROL-W", "")
	BEFORE ROW
		LET i          = arr_curr()
		LET j          = scr_line()
		LET vm_num_det = arr_count()
		IF i > vm_num_det THEN
			LET vm_num_det = vm_num_det + 1
		END IF
		CALL muestra_etiquetas(i)
		IF rm_adi[i].r10_codigo IS NOT NULL THEN
			--#CALL dialog.keysetlabel("F5", "Ver Item")
		ELSE
			--#CALL dialog.keysetlabel("F5", "")
		END IF
	AFTER FIELD c04_cod_item
		IF rm_detalle[i].c04_cod_item IS NOT NULL THEN
			IF NOT llena_fila_detalle(i, j) THEN
				CALL fl_mostrar_mensaje('Este código de pedido no existe en el maestro de ítems.', 'exclamation')
				NEXT FIELD c04_cod_item
			END IF
			IF rm_adi[i].r10_codigo IS NOT NULL THEN
				--#CALL dialog.keysetlabel("F5", "Ver Item")
			ELSE
				--#CALL dialog.keysetlabel("F5", "")
			END IF
		END IF
	AFTER INPUT
		LET salir = 0
		FOR k = 1 TO vm_num_det - 1
			FOR l = k + 1 TO vm_num_det
				IF rm_detalle[k].c04_cod_item = rm_detalle[l].c04_cod_item
				THEN
					CALL fl_mostrar_mensaje('El código ' || rm_detalle[k].c04_cod_item CLIPPED || ' esta repetido, por favor corrijalo.', 'exclamation')
					LET salir = 1
					EXIT FOR
				END IF
			END FOR
			IF salir THEN
				EXIT FOR
			END IF
		END FOR
		IF salir THEN
			CONTINUE INPUT
		END IF
		LET salir = 0
		FOR k = 1 TO vm_num_det
			IF ((rm_detalle[k].c04_pvp_prov_sug IS NULL AND
				 rm_detalle[k].c04_desc_prov IS NULL) OR
				(rm_detalle[k].c04_pvp_prov_sug IS NOT NULL AND
				 rm_detalle[k].c04_desc_prov IS NOT NULL))
			THEN
				CALL fl_mostrar_mensaje('El código ' || rm_detalle[k].c04_cod_item CLIPPED || ' SOLO debe tener PVP Sugerido o el descuento, por favor corrijalo.', 'exclamation')
				LET salir = 1
				EXIT FOR
			END IF
		END FOR
		IF salir THEN
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION llena_fila_detalle(i, j)
DEFINE i, j			SMALLINT
DEFINE resul		SMALLINT
DEFINE query		CHAR(1500)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*

INITIALIZE r_r10.*, r_r72.* TO NULL
LET query = 'SELECT rept010.*, rept072.* ',
				' FROM rept010, rept072 ',
				' WHERE r10_compania    = ', vg_codcia,
				'   AND r10_cod_pedido  = "',
							rm_detalle[i].c04_cod_item CLIPPED, '" ',
				'   AND r72_compania    = r10_compania ',
				'   AND r72_linea       = r10_linea ',
				'   AND r72_sub_linea   = r10_sub_linea ',
				'   AND r72_cod_grupo   = r10_cod_grupo ',
				'   AND r72_cod_clase   = r10_cod_clase '
PREPARE det_query FROM query
DECLARE q_linea CURSOR FOR det_query
OPEN q_linea
FETCH q_linea INTO r_r10.*, r_r72.*
LET rm_detalle[i].r10_nombre    = r_r10.r10_nombre
LET rm_detalle[i].r10_precio_mb = r_r10.r10_precio_mb
LET rm_adi[i].r10_codigo        = r_r10.r10_codigo
LET rm_adi[i].r10_precio_ant    = r_r10.r10_precio_mb
LET rm_adi[i].r72_desc_clase    = r_r72.r72_desc_clase
LET rm_adi[i].desc_item         = r_r10.r10_nombre
CLOSE q_linea
FREE q_linea
DISPLAY rm_detalle[i].* TO rm_detalle[j].*
DISPLAY BY NAME rm_adi[i].r72_desc_clase, rm_adi[i].desc_item
IF rm_detalle[i].r10_nombre IS NULL THEN
	LET resul = 0
ELSE
	LET resul = 1
END IF
RETURN resul

END FUNCTION



FUNCTION grabar_detalle()
DEFINE i, grabo			SMALLINT

BEGIN WORK
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT
	DELETE FROM ordt004
		WHERE c04_compania    = vg_codcia
		  AND c04_localidad   = vg_codloc
		  AND c04_codprov     = rm_par.c04_codprov
		  AND c04_fecha_vigen = rm_par.c04_fecha_vigen
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		SET LOCK MODE TO NOT WAIT
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se pudo eliminar el registro del proveedor ' || rm_par.p01_nomprov CLIPPED || ' con fecha de vigencia ' || rm_par.c04_fecha_vigen USING "dd-mm-yyyy" || '. Por favor llame al administrador.','exclamation')
		RETURN
	END IF
	LET grabo = 1
	FOR i = 1 TO vm_num_det
		INSERT INTO ordt004
			(c04_compania, c04_localidad, c04_codprov, c04_cod_item,
			 c04_fecha_vigen, c04_pvp_prov_sug, c04_desc_prov, c04_costo_prov,
			 c04_usuario, c04_fecing)
			VALUES (vg_codcia, vg_codloc, rm_par.c04_codprov,
					rm_detalle[i].c04_cod_item, rm_par.c04_fecha_vigen,
					rm_detalle[i].c04_pvp_prov_sug, rm_detalle[i].c04_desc_prov,
					rm_detalle[i].c04_costo_prov, rm_par.c04_usuario, CURRENT)
		IF STATUS <> 0 THEN
			ROLLBACK WORK
			WHENEVER ERROR STOP
			CALL fl_mostrar_mensaje('No se pudo insertar el registro del código de pedido ' || rm_detalle[i].c04_cod_item CLIPPED || '. Por favor llame al administrador.', 'exclamation')
			LET grabo = 0
			EXIT FOR
		END IF
		IF rm_detalle[i].r10_precio_mb = rm_adi[i].r10_precio_ant THEN
			CONTINUE FOR
		END IF
		UPDATE rept010
			SET r10_precio_mb   = rm_detalle[i].r10_precio_mb,
				r10_precio_ant  = rm_adi[i].r10_precio_ant,
				r10_fec_camprec = CURRENT
			WHERE r10_compania = vg_codcia
			  AND r10_codigo   = rm_adi[i].r10_codigo
		IF STATUS <> 0 THEN
			ROLLBACK WORK
			WHENEVER ERROR STOP
			CALL fl_mostrar_mensaje('No se pudo actualizar precio en el registro del código de pedido ' || rm_detalle[i].c04_cod_item CLIPPED || '. Por favor llame al administrador.', 'exclamation')
			LET grabo = 0
			EXIT FOR
		END IF
		IF NOT usuario_camprec(i) THEN
			ROLLBACK WORK
			WHENEVER ERROR STOP
			CALL fl_mostrar_mensaje('No se pudo registrar la actualización del precio en el código de pedido ' || rm_detalle[i].c04_cod_item CLIPPED || '. Por favor llame al administrador.', 'exclamation')
			LET grabo = 0
			EXIT FOR
		END IF
	END FOR
	SET LOCK MODE TO NOT WAIT
	IF NOT grabo THEN
		RETURN
	END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION usuario_camprec(i)
DEFINE i			SMALLINT
DEFINE r_r87		RECORD LIKE rept087.*
DEFINE query		VARCHAR(250)

INITIALIZE r_r87.* TO NULL
LET r_r87.r87_compania    = vg_codcia
LET r_r87.r87_localidad   = vg_codloc
LET r_r87.r87_item        = rm_adi[i].r10_codigo
LET query = 'SELECT ROUND(NVL(MAX(r87_secuencia), 0) + 1, 0) nue_sec ',
				' FROM rept087 ',
				' WHERE r87_compania  = ', r_r87.r87_compania,
				'   AND r87_localidad = ', r_r87.r87_localidad,
				'   AND r87_item      = ', r_r87.r87_item,
				' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
SELECT * INTO r_r87.r87_secuencia FROM t1
DROP TABLE t1
LET r_r87.r87_precio_act  = rm_detalle[i].r10_precio_mb
LET r_r87.r87_precio_ant  = rm_adi[i].r10_precio_ant
LET r_r87.r87_usu_camprec = vg_usuario
LET r_r87.r87_fec_camprec = CURRENT
INSERT INTO rept087 VALUES (r_r87.*)
IF STATUS = 0 THEN
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_par.* TO NULL
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0, 0)
FOR i = 1 TO fgl_scr_size('rm_detalle')
        INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
        CLEAR rm_detalle[i].*
END FOR
CLEAR r72_desc_clase, desc_item, num_row, max_row, c04_usuario, c04_fecing

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION botones_cabecera_forma()

--#DISPLAY "Items"			TO tit_col1
--#DISPLAY "Descripción"	TO tit_col2
--#DISPLAY "P. V. P."		TO tit_col3
--#DISPLAY "PVP Sug."		TO tit_col4
--#DISPLAY "%Des"			TO tit_col5
--#DISPLAY "Costo Pro"		TO tit_col6

END FUNCTION



FUNCTION muestra_etiquetas(i)
DEFINE i		SMALLINT

CALL muestra_contadores_det(i, vm_num_det)
DISPLAY BY NAME rm_adi[i].r72_desc_clase, rm_adi[i].desc_item

END FUNCTION



FUNCTION mostrar_item(item)
DEFINE item			LIKE rept020.r20_item
DEFINE param		VARCHAR(60)

LET param = ' "', item CLIPPED, '"'
CALL fl_ejecuta_comando('REPUESTOS', 'RE', 'repp108 ', param, 1)

END FUNCTION



FUNCTION imprimir_listado()
DEFINE i			INTEGER
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT listado_precio_items_proveedor TO PIPE comando
	FOR i = 1 TO vm_num_det
		OUTPUT TO REPORT listado_precio_items_proveedor(rm_detalle[i].*,
								rm_adi[i].*)
	END FOR
FINISH REPORT listado_precio_items_proveedor

END FUNCTION



REPORT listado_precio_items_proveedor(r_rep)
DEFINE r_rep 			RECORD
							c04_cod_item		LIKE ordt004.c04_cod_item,
							r10_nombre			LIKE rept010.r10_nombre,
							r10_precio_mb		LIKE rept010.r10_precio_mb,
							c04_pvp_prov_sug	LIKE ordt004.c04_pvp_prov_sug,
							c04_desc_prov		LIKE ordt004.c04_desc_prov,
							c04_costo_prov		LIKE ordt004.c04_costo_prov,
							r10_codigo			LIKE rept010.r10_codigo,
							r10_precio_ant		LIKE rept010.r10_precio_ant,
							r72_desc_clase		LIKE rept072.r72_desc_clase,
							desc_item			LIKE rept010.r10_nombre
						END RECORD
DEFINE r_cia			RECORD LIKE gent001.*
DEFINE usuario			VARCHAR(19,15)
DEFINE titulo			VARCHAR(80)
DEFINE modulo			VARCHAR(40)
DEFINE long				SMALLINT
DEFINE escape			SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi		SMALLINT
DEFINE act_12cpi		SMALLINT

OUTPUT
	TOP MARGIN		0
	LEFT MARGIN		0
	RIGHT MARGIN	132 
	BOTTOM MARGIN	4
	PAGE LENGTH		66

FORMAT

PAGE HEADER
	LET escape		= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET modulo      = "MODULO: COMPRAS"
	LET long        = LENGTH(modulo)
	LET usuario     = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO PRECIOS ITEMS PROVEEDOR', 80)
		RETURNING titulo
	CALL fl_lee_compania(vg_codcia) RETURNING r_cia.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_10cpi
	PRINT COLUMN 001, r_cia.g01_razonsocial,
  	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 026, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 052, "** FECHA VIGENCIA : ",
		rm_par.c04_fecha_vigen USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "ITEM",
	      COLUMN 016, "C L A S E",
	      COLUMN 047, "D E S C R I P C I O N",
	      COLUMN 082, "MARCA",
	      COLUMN 089, "   TOTAL BRUTO",
	      COLUMN 104, "  TOTAL DSCTO.",
	      COLUMN 119, "      SUBTOTAL"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_rep.c04_cod_item		CLIPPED,
	      COLUMN 008, r_rep.r72_desc_clase[1, 25]	CLIPPED,
	      COLUMN 034, r_rep.desc_item[1, 47]	CLIPPED,
	      COLUMN 089, r_rep.r10_precio_mb		USING "---,---,--&.##",
	      COLUMN 104, r_rep.c04_pvp_prov_sug	USING "---,---,--&.##",
	      COLUMN 119, r_rep.c04_costo_prov		USING "---,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

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
DISPLAY '<F5>      Eliminar Código'          AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
