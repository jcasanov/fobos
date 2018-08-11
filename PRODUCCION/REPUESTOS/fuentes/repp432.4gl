------------------------------------------------------------------------------
-- Titulo           : repp432.4gl - Impresión de Notas de Entrega
-- Elaboracion      : 23-Dic-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp432 base módulo compañía localidad
--				[bodega] [nota]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r34		RECORD LIKE rept034.*
DEFINE rm_r36		RECORD LIKE rept036.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp432.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base			= arg_val(1)
LET vg_modulo			= arg_val(2)
LET vg_codcia			= arg_val(3)
LET vg_codloc			= arg_val(4)
LET rm_r36.r36_bodega		= arg_val(5)
LET rm_r36.r36_num_entrega	= arg_val(6)
LET vg_proceso 			= 'repp432'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		CHAR(1200)
DEFINE comando		VARCHAR(100)
DEFINE r_r37		RECORD LIKE rept037.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_rep		RECORD
				r37_item	LIKE rept037.r37_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				unidades	LIKE rept010.r10_uni_med,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_ent	LIKE rept037.r37_cant_ent
			END RECORD

	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT PROGRAM
	END IF
	CALL fl_lee_nota_entrega(vg_codcia, vg_codloc, rm_r36.r36_bodega,
				 rm_r36.r36_num_entrega)
		RETURNING rm_r36.*
	IF rm_r36.r36_compania IS NULL THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT PROGRAM
	END IF
	CALL fl_lee_orden_despacho(vg_codcia, vg_codloc, rm_r36.r36_bodega,
				   rm_r36.r36_num_ord_des)
		RETURNING rm_r34.*
	CALL fl_lee_compania(rm_r36.r36_compania) RETURNING rm_cia.*
	CALL fl_lee_localidad(rm_r36.r36_compania, rm_r36.r36_localidad)
		RETURNING rm_loc.*
	START REPORT rep_nota_entre TO PIPE comando
	DECLARE q_detnot CURSOR FOR
		SELECT * FROM rept037
			WHERE r37_compania    = rm_r36.r36_compania
			  AND r37_localidad   = rm_r36.r36_localidad
			  AND r37_bodega      = rm_r36.r36_bodega
			  AND r37_num_entrega = rm_r36.r36_num_entrega
			ORDER BY r37_orden
	OPEN q_detnot
	FETCH q_detnot INTO r_r37.*
	IF STATUS = NOTFOUND THEN
		CLOSE q_detnot
		CALL fl_mostrar_mensaje('No existe detalle de esta Nota de Entrega.','stop')
		EXIT PROGRAM
	END IF
	FOREACH q_detnot INTO r_r37.* 
		CALL fl_lee_item(rm_r36.r36_compania, r_r37.r37_item)
			RETURNING r_r10.*
		CALL fl_lee_marca_rep(rm_r36.r36_compania, r_r10.r10_marca)
			RETURNING r_r73.*
		CALL fl_lee_clase_rep(rm_r36.r36_compania, r_r10.r10_linea,
				r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
				r_r10.r10_cod_clase)
			RETURNING r_r72.*
		LET r_rep.r37_item    = r_r37.r37_item
		LET r_rep.desc_clase  = r_r72.r72_desc_clase
		LET r_rep.unidades    = UPSHIFT(r_r10.r10_uni_med)
		LET r_rep.desc_marca  = r_r73.r73_desc_marca
		LET r_rep.descripcion = r_r10.r10_nombre
		LET r_rep.cant_ent    = r_r37.r37_cant_ent
		OUTPUT TO REPORT rep_nota_entre(r_rep.*)
	END FOREACH
	FINISH REPORT rep_nota_entre

END FUNCTION



REPORT rep_nota_entre(r_rep)
DEFINE r_rep		RECORD
				r37_item	LIKE rept037.r37_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				unidades	LIKE rept010.r10_uni_med,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_ent	LIKE rept037.r37_cant_ent
			END RECORD
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE orden		VARCHAR(10)
DEFINE nota		VARCHAR(10)
DEFINE proforma		VARCHAR(10)
DEFINE factura		VARCHAR(15)
DEFINE estado		VARCHAR(15)
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
	CALL fl_lee_cabecera_transaccion_rep(rm_r36.r36_compania,
				rm_r36.r36_localidad, rm_r34.r34_cod_tran,
				rm_r34.r34_num_tran)
		RETURNING r_r19.*
	CALL fl_lee_vendedor_rep(rm_r36.r36_compania, r_r19.r19_vendedor)
		RETURNING r_r01.*
	CALL fl_lee_bodega_rep(rm_r36.r36_compania, rm_r36.r36_bodega_real)
		RETURNING r_r02.*
	SELECT * INTO r_r21.* FROM rept021
		WHERE r21_compania  = rm_r36.r36_compania
		  AND r21_localidad = rm_r36.r36_localidad
		  AND r21_cod_tran  = rm_r34.r34_cod_tran
		  AND r21_num_tran  = rm_r34.r34_num_tran
	LET orden	= rm_r36.r36_num_ord_des
	LET nota	= rm_r36.r36_num_entrega
	LET proforma	= r_r21.r21_numprof
	LET factura	= rm_r34.r34_num_tran
	LET estado	= retorna_estado()
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 01, "CLIENTE (", r_r19.r19_codcli USING "&&&&&", ") : ",
					r_r19.r19_nomcli[1, 47] CLIPPED,
	      COLUMN 67, "NOTA DE ENTREGA No. ", nota, 4 SPACES,
			 "ORDEN DESPACHO No. ", orden
	PRINT COLUMN 01, "CEDULA/RUC      : ", r_r19.r19_cedruc,
	      COLUMN 67, "ESTADO NOTA      : ", estado
	PRINT COLUMN 01, "DIRECCION       : ", r_r19.r19_dircli,
	      COLUMN 67, "FECHA DE EMISION : ", rm_r36.r36_fec_entrega
						USING "dd-mm-yyyy"
	PRINT COLUMN 01, "TELEFONO        : ", r_r19.r19_telcli,
	      COLUMN 67, "BODEGA ENTREGA   : ", rm_r36.r36_bodega_real, " ",
					       r_r02.r02_nombre
	PRINT COLUMN 01, "ENTREGADO A     : ", rm_r36.r36_entregar_a,
	      COLUMN 67, "No. PROFORMA     : ", proforma,
			 "  No. FACT. : ", rm_r34.r34_cod_tran, " ", factura;
	IF r_r19.r19_cont_cred = 'C' THEN
		PRINT ' (CONTADO)'
	ELSE
		PRINT ' (CREDITO)'
	END IF
	PRINT COLUMN 01, "ENTREGADO EN    : ", rm_r36.r36_entregar_en
	PRINT COLUMN 01, "VENDEDOR        : ", r_r01.r01_nombres,
	      COLUMN 67, "ALMACEN          : ", rm_cia.g01_razonsocial
	PRINT COLUMN 67, "RUC              : ", rm_loc.g02_numruc
	PRINT COLUMN 01, "FECHA IMPRESION : ", vg_fecha USING "dd-mm-yyyy",
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
	PRINT COLUMN 02,  r_rep.r37_item,
	      COLUMN 20,  r_rep.desc_clase,
	      COLUMN 81,  r_rep.desc_marca
	PRINT COLUMN 22,  r_rep.descripcion,
	      COLUMN 113, r_rep.cant_ent	USING "###,##&.##",
	      COLUMN 125, r_rep.unidades
	
PAGE TRAILER
	--NEED 4 LINES
	--SKIP 2 LINES
	PRINT COLUMN 02, "SALIDA LA MERCADERIA NO SE ACEPTAN DEVOLUCIONES"
	SKIP 3 LINES
	PRINT COLUMN 42, "-----------------------",
	      COLUMN 69, "-----------------------"
	PRINT COLUMN 42, "    RECIBI CONFORME    ",
	      COLUMN 69, "   ENTREGUE CONFORME   ";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION retorna_estado()

CASE rm_r36.r36_estado
	WHEN 'A'
		RETURN 'ACTIVA'
	WHEN 'E'
		RETURN 'ELIMINADA'
END CASE

END FUNCTION
