------------------------------------------------------------------------------
-- Titulo           : repp431.4gl - Impresión de Ordenes de Despacho
-- Elaboracion      : 21-Dic-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp431 base módulo compañía localidad
--			[bodega] [orden]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r34		RECORD LIKE rept034.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp431.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base		   = arg_val(1)
LET vg_modulo		   = arg_val(2)
LET vg_codcia		   = arg_val(3)
LET vg_codloc		   = arg_val(4)
LET rm_r34.r34_bodega      = arg_val(5)
LET rm_r34.r34_num_ord_des = arg_val(6)
LET vg_proceso 		   = 'repp431'
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
DEFINE tecla 		INTEGER
DEFINE r_r02		RECORD LIKE rept002.*

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 10
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/repf431_1"
ELSE
	OPEN FORM f_rep FROM "../forms/repf431_1c"
END IF
DISPLAY FORM f_rep
CALL fl_lee_orden_despacho(vg_codcia, vg_codloc, rm_r34.r34_bodega, 
			   rm_r34.r34_num_ord_des)
	RETURNING rm_r34.*
IF rm_r34.r34_compania IS NULL THEN
	CALL fl_mensaje_consulta_sin_registros()
	EXIT PROGRAM
END IF
CALL fl_lee_bodega_rep(rm_r34.r34_compania, rm_r34.r34_bodega) RETURNING r_r02.*
DISPLAY BY NAME rm_r34.r34_num_ord_des, rm_r34.r34_bodega, r_r02.r02_nombre,
		rm_r34.r34_cod_tran, rm_r34.r34_num_tran
MESSAGE "                                           Presione una tecla para continuar "
LET tecla = fgl_getkey()
MESSAGE "                                                                             "
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE r_rep		RECORD
				r35_item	LIKE rept035.r35_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				unidades	LIKE rept010.r10_uni_med,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_des	LIKE rept035.r35_cant_des
			END RECORD
DEFINE r_g06		RECORD LIKE gent006.*
DEFINE r_g24		RECORD LIKE gent024.*
DEFINE r_r35		RECORD LIKE rept035.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_r88		RECORD LIKE rept088.*
DEFINE query		CHAR(1200)
DEFINE comando		VARCHAR(100)

INITIALIZE r_g06.*, r_g24.*, r_r88.* TO NULL
LET r_g06.g06_impresora = FGL_GETENV('PRINTER_DESP')
IF vg_codloc = 1 THEN
	SELECT * INTO r_r88.*
		FROM rept088
		WHERE r88_compania  = rm_r34.r34_compania
		  AND r88_localidad = rm_r34.r34_localidad
		  AND r88_cod_fact  = rm_r34.r34_cod_tran
		  AND r88_num_fact  = rm_r34.r34_num_tran
	IF r_r88.r88_compania IS NULL THEN
		SELECT * INTO r_r88.*
			FROM rept088
			WHERE r88_compania     = rm_r34.r34_compania
			  AND r88_localidad    = rm_r34.r34_localidad
			  AND r88_cod_fact_nue = rm_r34.r34_cod_tran
			  AND r88_num_fact_nue = rm_r34.r34_num_tran
	END IF
	IF r_r88.r88_compania IS NULL THEN
		DECLARE q_g24 CURSOR FOR
			SELECT * FROM gent024
				WHERE g24_compania  = rm_r34.r34_compania
				  AND g24_bodega    = rm_r34.r34_bodega
				ORDER BY g24_imprime DESC
		OPEN q_g24
		FETCH q_g24 INTO r_g24.*
		CLOSE q_g24
		FREE q_g24
		IF r_g24.g24_impresora IS NOT NULL THEN
			LET r_g06.g06_impresora = r_g24.g24_impresora
		END IF
	END IF
END IF
IF r_g06.g06_impresora IS NOT NULL THEN
	CALL fl_lee_impresora(r_g06.g06_impresora) RETURNING r_g06.*
	IF r_g06.g06_impresora IS NULL THEN
		CALL fl_control_reportes() RETURNING comando
		IF int_flag THEN
			RETURN
		END IF
	END IF
	if r_g06.g06_impresora = 'LPGUIAS' then
                let r_g06.g06_impresora = 'BODEGA2'
        end if
	LET comando = 'lpr -o raw -P ', r_g06.g06_impresora
ELSE
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		RETURN
	END IF
END IF
CALL fl_lee_compania(rm_r34.r34_compania) RETURNING rm_cia.*
CALL fl_lee_localidad(rm_r34.r34_compania, rm_r34.r34_localidad)
	RETURNING rm_loc.*
START REPORT rep_orden_desp TO PIPE comando
DECLARE q_detord CURSOR FOR
	SELECT * FROM rept035
		WHERE r35_compania    = rm_r34.r34_compania
		  AND r35_localidad   = rm_r34.r34_localidad
		  AND r35_bodega      = rm_r34.r34_bodega 
		  AND r35_num_ord_des = rm_r34.r34_num_ord_des
		ORDER BY r35_orden
OPEN q_detord
FETCH q_detord INTO r_r35.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe detalle de esta Orden de Despacho.','stop')
	EXIT PROGRAM
END IF
FOREACH q_detord INTO r_r35.* 
	CALL fl_lee_item(rm_r34.r34_compania, r_r35.r35_item)
		RETURNING r_r10.*
	CALL fl_lee_marca_rep(rm_r34.r34_compania, r_r10.r10_marca)
		RETURNING r_r73.*
	CALL fl_lee_clase_rep(rm_r34.r34_compania, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
		RETURNING r_r72.*
	LET r_rep.r35_item    = r_r35.r35_item
	LET r_rep.desc_clase  = r_r72.r72_desc_clase
	LET r_rep.unidades    = UPSHIFT(r_r10.r10_uni_med)
	LET r_rep.desc_marca  = r_r73.r73_desc_marca
	LET r_rep.descripcion = r_r10.r10_nombre
	LET r_rep.cant_des    = r_r35.r35_cant_des
	OUTPUT TO REPORT rep_orden_desp(r_rep.*)
END FOREACH
FINISH REPORT rep_orden_desp

END FUNCTION



REPORT rep_orden_desp(r_rep)
DEFINE r_rep		RECORD
				r35_item	LIKE rept035.r35_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				unidades	LIKE rept010.r10_uni_med,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_des	LIKE rept035.r35_cant_des
			END RECORD
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE orden		VARCHAR(10)
DEFINE proforma		VARCHAR(10)
DEFINE factura		VARCHAR(15)
DEFINE estado		VARCHAR(15)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	5
	PAGE LENGTH	44
FORMAT

PAGE HEADER
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra (12 cpi)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	--LET db 	    	= "\033W1"      # Activar doble ancho.
	--LET db_c    	= "\033W0"      # Cancelar doble ancho.
	CALL fl_lee_cabecera_transaccion_rep(rm_r34.r34_compania,
				rm_r34.r34_localidad, rm_r34.r34_cod_tran,
				rm_r34.r34_num_tran)
		RETURNING r_r19.*
	CALL fl_lee_vendedor_rep(rm_r34.r34_compania, r_r19.r19_vendedor)
		RETURNING r_r01.*
	CALL fl_lee_bodega_rep(rm_r34.r34_compania, rm_r34.r34_bodega)
		RETURNING r_r02.*
	SELECT * INTO r_r21.* FROM rept021
		WHERE r21_compania  = rm_r34.r34_compania
		  AND r21_localidad = rm_r34.r34_localidad
		  AND r21_cod_tran  = rm_r34.r34_cod_tran
		  AND r21_num_tran  = rm_r34.r34_num_tran
	LET orden	= rm_r34.r34_num_ord_des
	LET proforma	= r_r21.r21_numprof
	LET factura	= rm_r34.r34_num_tran
	LET estado	= retorna_estado()
	--SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 028, ASCII escape, ASCII act_dob1, ASCII act_dob2,
		--"www.acerocomercial.com",
	      COLUMN 032, "OD No.: ", orden, "  BODEGA: ",
		rm_r34.r34_bodega, "   ", rm_loc.g02_abreviacion CLIPPED,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_comp
	SKIP 1 LINES
	PRINT COLUMN 01, "CLIENTE (", r_r19.r19_codcli USING "&&&&&", ") : ",
					r_r19.r19_nomcli[1, 47] CLIPPED,
	      COLUMN 67, "ORDEN DESPACHO No. ", orden
	PRINT COLUMN 01, "CEDULA/RUC      : ", r_r19.r19_cedruc,
	      COLUMN 67, "ESTADO ORDEN     : ", estado
	PRINT COLUMN 01, "DIRECCION       : ", r_r19.r19_dircli,
	      COLUMN 67, "FECHA DE EMISION : ", rm_r34.r34_fec_entrega
						USING "dd-mm-yyyy"
	PRINT COLUMN 01, "TELEFONO        : ", r_r19.r19_telcli,
	      COLUMN 67, "BODEGA           : ", rm_r34.r34_bodega, " ",
					       r_r02.r02_nombre
	PRINT COLUMN 01, "ENTREGAR A      : ", rm_r34.r34_entregar_a,
	      COLUMN 67, "No. PROFORMA     : ", proforma,
			 "  No. FACT. : ", rm_r34.r34_cod_tran, " ", factura;
	IF r_r19.r19_cont_cred = 'C' THEN
		PRINT ' (CONTADO)'
	ELSE
		PRINT ' (CREDITO)'
	END IF
	PRINT COLUMN 01, "ENTREGAR EN     : ", rm_r34.r34_entregar_en
	PRINT COLUMN 01, "VENDEDOR        : ", r_r01.r01_nombres,
	      COLUMN 67, "ALMACEN          : ", rm_cia.g01_razonsocial
	--PRINT COLUMN 01, "LOCALIDAD       : ", rm_loc.g02_nombre,
	PRINT COLUMN 67, "RUC              : ", rm_loc.g02_numruc
	PRINT COLUMN 01, "FECHA IMPRESION : ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 67, "USUARIO          : ", vg_usuario,
	      COLUMN 125, UPSHIFT(vg_proceso) 
	SKIP 1 LINES
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT "-----------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 02,  "CODIGO",
	      COLUMN 20,  "DESCRIPCION",
	      COLUMN 81,  "MARCA",
	      COLUMN 113, "  CANTIDAD",
	      COLUMN 125, "MEDIDA"
	PRINT "-----------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	--OJO
	NEED 2 LINES
	PRINT COLUMN 02,  r_rep.r35_item,
	      COLUMN 20,  r_rep.desc_clase,
	      COLUMN 81,  r_rep.desc_marca
	PRINT COLUMN 22,  r_rep.descripcion,
	      COLUMN 113, r_rep.cant_des	USING "###,##&.##",
	      COLUMN 125, r_rep.unidades
	
PAGE TRAILER
	--NEED 4 LINES
	SKIP 2 LINES
	PRINT COLUMN 02, "UNICO DOCUMENTO VALIDO PARA RETIRAR PRODUCTOS";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION retorna_estado()

CASE rm_r34.r34_estado
	WHEN 'A'
		RETURN 'ACTIVA'
	WHEN 'D'
		RETURN 'DESPACHADA'
	WHEN 'P'
		RETURN 'PARCIAL'
	WHEN 'E'
		RETURN 'ELIMINADA'
END CASE

END FUNCTION
