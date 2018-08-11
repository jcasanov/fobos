--------------------------------------------------------------------------------
-- Titulo           : repp411.4gl - Impresión Ajuste de existencias
-- Elaboracion      : 07-Ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp411 base módulo compañía localidad 
--		      tipo_tran num_tran
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_tran	LIKE rept019.r19_cod_tran
DEFINE vm_num_tran	LIKE rept019.r19_num_tran
DEFINE vm_tipo_ajuste	VARCHAR(15)
DEFINE vm_ajuste_mas	LIKE rept019.r19_cod_tran
-- DEFINE vm_ajuste_menos	LIKE rept019.r19_cod_tran
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_r02		RECORD LIKE rept002.*
DEFINE rm_r19		RECORD LIKE rept019.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp411.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN   -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vm_tipo_tran = arg_val(5)
LET vm_num_tran  = arg_val(6)
LET vg_proceso   = 'repp411'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_ajuste_mas = 'A+'
-- LET vm_ajuste_menos = 'A-'
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		CHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE n_item		LIKE rept010.r10_nombre

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe compañía.','stop')
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, vm_tipo_tran, 
	vm_num_tran) RETURNING rm_r19.*
IF rm_r19.r19_num_tran IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe ajuste costo.','stop')
	CALL fl_mostrar_mensaje('No existe ajuste costo.','stop')
	EXIT PROGRAM
END IF
IF rm_r19.r19_cod_tran = vm_ajuste_mas THEN
	LET vm_tipo_ajuste = 'INCREMENTO'
ELSE
	LET vm_tipo_ajuste = 'DECREMENTO'
END IF
CALL fl_lee_moneda(rm_r19.r19_moneda) RETURNING rm_g13.*
IF rm_g13.g13_moneda IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe moneda.','stop')
	CALL fl_mostrar_mensaje('No existe moneda.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori) RETURNING rm_r02.*
IF rm_r02.r02_codigo IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe bodega.','stop')
	CALL fl_mostrar_mensaje('No existe bodega.','stop')
	EXIT PROGRAM
END IF
LET query = 'SELECT rept020.*, r10_nombre FROM rept020, rept010 ',
	    '	WHERE r20_compania  = ',  vg_codcia,
	    '  	  AND r20_localidad = ',  vg_codloc,
	    '	  AND r20_cod_tran  = "', vm_tipo_tran, '"',
	    '	  AND r20_num_tran  = ',  vm_num_tran,
	    '	  AND r10_compania  = r20_compania ',
	    '	  AND r10_codigo    = r20_item ',
	    '	ORDER BY r20_orden'
PREPARE deto FROM query
DECLARE q_deto CURSOR FOR deto
OPEN  q_deto
FETCH q_deto
IF STATUS = NOTFOUND THEN
	CLOSE q_deto
	CALL fl_mensaje_consulta_sin_registros()
	EXIT PROGRAM
END IF
CLOSE q_deto
START REPORT ajuste_existencia TO PIPE comando
FOREACH q_deto INTO r_r20.*, n_item
	CALL fl_lee_item(vg_codcia, r_r20.r20_item) RETURNING r_r10.*
	CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
		RETURNING r_r72.*
	OUTPUT TO REPORT ajuste_existencia(r_r20.r20_cant_ven,
				      r_r20.r20_item, r_r72.r72_desc_clase,
				      n_item)
END FOREACH
FINISH REPORT ajuste_existencia

END FUNCTION



REPORT ajuste_existencia(cant, item, clase, descripcion)
DEFINE cant		LIKE rept020.r20_cant_ven
DEFINE item		LIKE rept020.r20_item 
DEFINE clase     	LIKE rept072.r72_desc_clase
DEFINE descripcion	LIKE rept010.r10_nombre
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE numero		VARCHAR(15)
DEFINE long		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	0
	RIGHT  MARGIN	132
	BOTTOM MARGIN	3
	PAGE   LENGTH	44

FORMAT

PAGE HEADER
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET long        = LENGTH(modulo)
	LET numero      = rm_r19.r19_num_tran
	LET documento   = 'COMPROBANTE AJUSTE DE EXISTENCIA No. ', numero
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', documento CLIPPED, 80)
		RETURNING titulo
	LET titulo = modulo, titulo
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 01,  rm_cia.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 01,  titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	--print '&k2S' 		-- Letra condensada
--	cabecera del ajuste_existencia
	PRINT COLUMN 25,  fl_justifica_titulo('I', 'TIPO AJUSTE', 15), ': ',
			vm_tipo_ajuste,
	      COLUMN 105, 'FECHA DEL AJUSTE: ', DATE(rm_r19.r19_fecing)
						USING 'dd-mm-yyyy'
	PRINT COLUMN 25,  fl_justifica_titulo('I', 'BODEGA', 15), ': ', 
			rm_r02.r02_codigo, ' ', rm_r02.r02_nombre
	PRINT COLUMN 25,  fl_justifica_titulo('I', 'MONEDA', 15), ': ',
			rm_g13.g13_nombre
	PRINT COLUMN 25,  fl_justifica_titulo('I', 'REFERENCIA', 15), ': ',
	        	rm_r19.r19_referencia
--
	SKIP 1 LINES
	PRINT COLUMN 01, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
			1 SPACES, TIME,
	      COLUMN 123, usuario
	SKIP 1 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 01,  'CODIGO',
	      COLUMN 09,  'DESCRIPCION',
	      COLUMN 125, 'CANTIDAD'
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 01,  item[1,7],
	      COLUMN 09,  clase,
	      COLUMN 60,  descripcion[1,62],
	      COLUMN 123, cant           USING "---,--&.##"
	
ON LAST ROW
	PRINT COLUMN 123, '----------'
	PRINT COLUMN 112, 'TOTAL ==>  ', SUM(cant) USING '---,--&.##';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
