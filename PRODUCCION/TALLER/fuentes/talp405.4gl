--------------------------------------------------------------------------------
-- Titulo           : talp405.4gl - Listado de Ordenes de Trabajo	      --
-- Elaboracion      : 04-ABR-2002					      --
-- Autor            : GVA						      --
-- Formato Ejecucion: fglrun talp4 base módulo compañía localidad	      --
-- Ultima Correccion: 							      --
-- Motivo Correccion: 							      --
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_t23		RECORD LIKE talt023.*

DEFINE rm_g13		RECORD LIKE gent013.*

DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT

DEFINE vm_tot_utilidad	DECIMAL(14,2)
DEFINE vm_tot_egresos	DECIMAL(14,2)
DEFINE vm_tot_ingresos	DECIMAL(14,2)
DEFINE vm_tot_viajes	DECIMAL(14,2)

DEFINE vm_ot		LIKE talt023.t23_orden
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_moneda	LIKE gent013.g13_moneda

DEFINE expr_ot 		VARCHAR(100)
DEFINE expr_fecha	VARCHAR(250)
DEFINE expr_estado	VARCHAR(100)
DEFINE vm_estado	CHAR(1)

DEFINE vm_ind_gastos	SMALLINT
DEFINE rm_det_gastos	ARRAY[250] OF RECORD
	estado		LIKE talt030.t30_estado,
	num_gasto	LIKE talt030.t30_num_gasto,
	fecha_ini	LIKE talt030.t30_fec_ini_viaje,
	fecha_fin	LIKE talt030.t30_fec_fin_viaje,
	descripcion	LIKE talt031.t31_descripcion,
	valor		LIKE talt031.t31_valor
	END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp405.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)

LET vg_proceso = 'talp405'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 13 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT NO WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/talf405_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(600)
DEFINE comando 		VARCHAR(100)
DEFINE r_report 	RECORD
	orden		LIKE talt023.t23_orden,
	cliente		LIKE talt023.t23_nom_cliente,
	fecha		DATE,
	total_ot	LIKE talt023.t23_tot_neto,
	estado_ot	LIKE talt023.t23_estado
	END RECORD

LET vm_top    = 0
LET vm_left   = 20
LET vm_right  = 90
LET vm_bottom = 4
LET vm_page   = 66

LET vm_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO nom_moneda
LET vm_fecha_fin = TODAY
LET vm_estado    = 'F'

WHILE TRUE
	LET vm_tot_utilidad = 0
	LET vm_tot_ingresos = 0
	LET vm_tot_egresos   = 0
	INITIALIZE vm_ot, rm_t23.* TO NULL
	CLEAR t23_nom_cliente
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF

	LET query = 'SELECT t23_orden, t23_nom_cliente, DATE(t23_fecing),',
			'   t23_tot_neto, t23_estado',
			'  FROM talt023 ',
			'WHERE t23_compania  =',vg_codcia,
			'  AND t23_localidad =',vg_codloc,
			'  AND ',expr_ot CLIPPED, ' ',
			'  AND t23_moneda = "',vm_moneda,'"',
			'  AND ',expr_estado CLIPPED,
			'  AND ',expr_fecha CLIPPED,
			' ORDER BY 3'

	PREPARE reporte FROM query
	DECLARE q_reporte CURSOR FOR reporte
	OPEN    q_reporte
	FETCH   q_reporte
	IF STATUS = NOTFOUND THEN
		CLOSE q_reporte
		FREE  q_reporte
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	START REPORT report_ordenes_trabajo TO PIPE comando
	CLOSE q_reporte

	FOREACH q_reporte INTO r_report.* 
		OUTPUT TO REPORT report_ordenes_trabajo(r_report.*)
		IF int_flag THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FINISH REPORT report_ordenes_trabajo
END WHILE 

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_t23		RECORD LIKE talt023.*

INITIALIZE r_t23.* TO NULL

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME vm_fecha_ini, vm_fecha_fin, vm_moneda, vm_estado, vm_ot 
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(vm_moneda) THEN
        		CALL fl_ayuda_monedas()
	               		RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		END IF
		IF INFIELD(vm_ot) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc, 'T')
				RETURNING r_t23.t23_orden, r_t23.t23_nom_cliente
			IF r_t23.t23_orden IS NOT NULL THEN
				LET rm_t23.t23_orden       = r_t23.t23_orden
				LET rm_t23.t23_nom_cliente = 
							r_t23.t23_nom_cliente
				DISPLAY BY NAME rm_t23.t23_orden, 
						rm_t23.t23_nom_cliente
			END IF	
		END IF
		LET int_flag = 0
	AFTER FIELD vm_moneda
		IF vm_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(vm_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la moneda en la Compañía.','exclamation')
				CLEAR nom_moneda
				NEXT FIELD vm_moneda
			ELSE
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		ELSE
			CLEAR nom_moneda
		END IF
	AFTER FIELD vm_ot 
		IF vm_ot IS NOT NULL THEN
			CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, vm_ot) 
				RETURNING r_t23.*		
			IF r_t23.t23_orden IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la Orden de Trabajo en la Compañía.','exclamation')
				INITIALIZE rm_t23.* TO NULL
				CLEAR t23_nom_cliente
				NEXT FIELD t23_orden
			ELSE
				LET rm_t23.* = r_t23.*
				DISPLAY BY NAME rm_t23.t23_nom_cliente 
			END IF
		ELSE
			CLEAR t23_nom_cliente
		END IF
	AFTER INPUT 
		IF vm_ot IS NOT NULL THEN
			LET expr_ot = 't23_orden =',vm_ot
			LET expr_fecha  = '1=1'
			LET expr_estado = '1=1'
		ELSE
			IF vm_fecha_ini IS NULL THEN
				NEXT FIELD vm_fecha_ini
			END IF
			IF vm_fecha_fin IS NULL THEN
				NEXT FIELD vm_fecha_fin
			END IF
			IF vm_moneda IS NULL THEN
				NEXT FIELD vm_moneda
			END IF
			IF vm_fecha_fin < vm_fecha_ini THEN
				CALL fgl_winmessage(vg_producto,'La fecha final debe ser menor a la fecha inicial.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
			LET expr_ot    = '1=1'
			LET expr_fecha = 'DATE(t23_fecing) BETWEEN "',vm_fecha_ini,'"', ' AND ', '"',vm_fecha_fin,'"'
			CASE vm_estado
				WHEN 'F'
					LET expr_estado = 't23_estado = "F"'
				WHEN 'A'
					LET expr_estado = 't23_estado = "A"'
				WHEN 'T'
					LET expr_estado = 't23_estado IN ("A","F","C")'
			END CASE
		END IF
END INPUT

END FUNCTION



REPORT report_ordenes_trabajo(orden, cliente, fecha_ot, total_ot, estado_ot)
DEFINE orden		LIKE talt023.t23_orden
DEFINE cliente		LIKE talt023.t23_nom_cliente
DEFINE fecha_ot		DATE
DEFINE total_ot		LIKE talt023.t23_tot_neto 
DEFINE estado_ot	LIKE talt023.t23_estado 

DEFINE estado_oc	LIKE ordt010.c10_estado 
DEFINE numero_oc	LIKE ordt010.c10_numero_oc 
DEFINE fecha_oc		DATE 
DEFINE descrip_oc	VARCHAR(30) 
DEFINE subtotales_oc	DECIMAL(12,2) 
DEFINE total_oc		DECIMAL(12,2) 
DEFINE tit_estado_ot	VARCHAR(10) 

DEFINE tot_viajes	LIKE talt030.t30_tot_gasto
DEFINE i 		SMALLINT


OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page
FORMAT

PAGE HEADER
	print 'E'; 
	print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	        -- Letra (12 cpi)

	CASE estado_ot
		WHEN 'A'
			LET tit_estado_ot = 'ACTIVA'
		WHEN 'F'
			LET tit_estado_ot = 'FACTURADA'
		WHEN 'C'
			LET tit_estado_ot = 'CERRADA'
	END CASE

	PRINT COLUMN 1, rg_cia.g01_razonsocial
	PRINT COLUMN 1,
		fl_justifica_titulo('C',
				'LISTADO DE GASTOS POR ORDENES DE TRABAJO',50)

	print '&k2S'	        -- Letra (16 cpi)
	SKIP 1 LINES

	PRINT COLUMN 1, 'Fecha de Impresión: ',
	      COLUMN 23, TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 60,'Página: ', 
	      COLUMN 83, PAGENO	USING '&&&'

	SKIP 1 LINES

	IF vm_ot IS NOT NULL THEN
		PRINT COLUMN 1,  'No Orden:',
		      COLUMN 23, fl_justifica_titulo('I', vm_ot, 8),
		      COLUMN 40, 'Estado: ', tit_estado_ot,
		      COLUMN 60, 'Fecha:',
		      COLUMN 67, rm_t23.t23_fecing
		PRINT COLUMN 1,  'Cliente:',
		      COLUMN 23, rm_t23.t23_nom_cliente
	ELSE
		PRINT COLUMN 1,  'Fecha Inicial: ',
	      	      COLUMN 23, vm_fecha_ini,
	      	      COLUMN 60, 'Fecha Final: ',
	      	      COLUMN 76, vm_fecha_fin
		PRINT COLUMN 1, ' '		-- Debe ser las misma cantidad
						-- de print en el if and else
						-- sino ocurre un error
	END IF
	PRINT COLUMN 1, 'Moneda:',
	      COLUMN 23, rm_g13.g13_nombre
	PRINT COLUMN 1, 'Usuario: ',
	      COLUMN 23, vg_usuario,
	      COLUMN 79, 'TALP499'

	PRINT '-------------------------------------------------------------------------------------'
ON EVERY ROW
CASE estado_ot
	WHEN 'A'
		LET tit_estado_ot = 'ACTIVA'
	WHEN 'F'
		LET tit_estado_ot = 'FACTURADA'
	WHEN 'C'
		LET tit_estado_ot = 'CERRADA'
END CASE

NEED 8 LINES

--SKIP 1 LINES

DECLARE q_oc CURSOR FOR 
	SELECT c10_estado, c10_numero_oc, DATE(c10_fecing), c11_descrip, 
	       (c11_precio - c11_val_descto) * (1 + c10_porc_impto / 100) 
		FROM ordt010, ordt011
		WHERE c10_compania    = vg_codcia
		  AND c10_localidad   = vg_codloc
		  AND c10_ord_trabajo = orden
		  AND c11_compania    = c10_compania
		  AND c11_localidad   = c10_localidad
		  AND c11_numero_oc   = c10_numero_oc
		  AND c11_tipo        = 'S'
	UNION 
	SELECT c10_estado, c10_numero_oc, DATE(c10_fecing), c11_descrip, 
	       ((c11_cant_rec * c11_precio) - c11_val_descto) * 
	       (1 + c10_porc_impto / 100) 
		FROM ordt010, ordt011
		WHERE c10_compania    = vg_codcia
		  AND c10_localidad   = vg_codloc
		  AND c10_ord_trabajo = orden
		  AND c11_compania    = c10_compania
		  AND c11_localidad   = c10_localidad
		  AND c11_numero_oc   = c10_numero_oc
		  AND c11_tipo        = 'B'
	ORDER BY 3, 2

	OPEN q_oc
	FETCH q_oc
	IF status = NOTFOUND THEN
		PRINT COLUMN 1,  'No Orden:',
		      COLUMN 15, fl_justifica_titulo('I',orden,8),
		      COLUMN 35, 'Estado: ',tit_estado_ot,
	      	      COLUMN 60, 'Fecha:',
	      	      COLUMN 76, fecha_ot
		PRINT COLUMN 1,  'Cliente:',
		      COLUMN 15, cliente,
		      COLUMN 60, 'Total:',
		      COLUMN 70, total_ot USING '#,###,###,##&.##'  
		SKIP 1 LINES
		PRINT COLUMN 11,'No tiene ordenes de compras la Orden de Trabajo'
		SKIP 1 LINES

		-- Busca los gastos por viajes de la orden de trabajo
		CALL control_busca_gastos_ot(orden)

		LET tot_viajes = 0
		IF vm_ind_gastos > 0 THEN
			PRINT COLUMN 11, '-----',
	      		      COLUMN 14, '----------',
	      		      COLUMN 24, '------------',
	      		      COLUMN 38, '--------------------------------',
	      		      COLUMN 70, '----------------'  
			PRINT COLUMN 11, 'E',
			      COLUMN 14, 'No Gasto',
			      COLUMN 24, 'Fec. Ini.',
			      COLUMN 36, 'Fec. Fin',
			      COLUMN 48, 'Descripción',
			      COLUMN 81, 'Valor' 
			PRINT COLUMN 11, '-----',
	      		      COLUMN 14, '----------',
	      		      COLUMN 24, '------------',
	      		      COLUMN 38, '--------------------------------',
	      		      COLUMN 70, '----------------'  

			FOR i = 1 TO vm_ind_gastos
				PRINT COLUMN 11, rm_det_gastos[i].estado,
			      	      COLUMN 14, fl_justifica_titulo('I',
						 rm_det_gastos[i].num_gasto,8),
				      COLUMN 24, rm_det_gastos[i].fecha_ini,
			      	      COLUMN 36, rm_det_gastos[i].fecha_fin,
			      	      COLUMN 48, 
					     rm_det_gastos[i].descripcion[1,21],
			      	      COLUMN 72, rm_det_gastos[i].valor 
						 USING '###,###,##&.##' 
				LET tot_viajes = tot_viajes + 
						 rm_det_gastos[i].valor
			END FOR	
			PRINT COLUMN 70, '----------------'
			PRINT COLUMN 11, 'TOTAL',
	      		      COLUMN 70, tot_viajes USING '#,###,###,##&.##'
			SKIP 1 LINES
		END IF 

		IF estado_ot = 'F' THEN
			PRINT COLUMN 11,  'Utilidad --->',
		      	      COLUMN 70,  total_ot - tot_viajes 
					  USING '#,###,###,##&.&&'
			LET vm_tot_utilidad = vm_tot_utilidad + total_ot -
					      tot_viajes	
			LET vm_tot_ingresos = vm_tot_ingresos + total_ot
			LET vm_tot_egresos  = vm_tot_egresos  + tot_viajes
			SKIP 1 LINES
		END IF

		PRINT '-------------------------------------------------------------------------------------'
		SKIP 1 LINES
		CLOSE q_oc
		FREE  q_oc
		RETURN
	END IF
	CLOSE q_oc
	
	LET total_oc = 0
	IF vm_ot IS NULL THEN
		PRINT COLUMN 1,  'No Orden:',
		      COLUMN 15, fl_justifica_titulo('I',orden,8),
		      COLUMN 35, 'Estado: ',tit_estado_ot,
	      	      COLUMN 60, 'Fecha:',
	      	      COLUMN 76, fecha_ot
		PRINT COLUMN 1,  'Cliente:',
	      	      COLUMN 15, cliente,
		      COLUMN 60, 'Total:',
		      COLUMN 70, total_ot USING '#,###,###,##&.##'  
	END IF
	PRINT COLUMN 11, '-----',
	      COLUMN 14, '----------',
	      COLUMN 24, '------------',
	      COLUMN 38, '--------------------------------',
	      COLUMN 70, '----------------'  
	
	PRINT COLUMN 11, 'E',
	      COLUMN 14, 'No O.C.',
	      COLUMN 24, 'Fecha',
	      COLUMN 38, 'Descripción',
	      COLUMN 81, 'Valor'  

	PRINT COLUMN 11, '-----',
	      COLUMN 14, '----------',
	      COLUMN 24, '------------',
	      COLUMN 38, '--------------------------------',
	      COLUMN 70, '----------------'  
	FOREACH q_oc INTO estado_oc, numero_oc, fecha_oc, 
			  descrip_oc, subtotales_oc 
		PRINT COLUMN 11, estado_oc, 
		      COLUMN 14, fl_justifica_titulo('I',numero_oc,8),
		      COLUMN 24, fecha_oc,
		      COLUMN 38, descrip_oc[1,30],
		      COLUMN 70, subtotales_oc USING '#,###,###,##&.##'  
		LET total_oc = total_oc + subtotales_oc
	END FOREACH
	FREE  q_oc
	
	PRINT COLUMN 70, '----------------'
	PRINT COLUMN 11, 'TOTAL',
	      COLUMN 70, total_oc USING '#,###,###,##&.##'

--
	-- Busca los gastos por viajes de la orden de trabajo
	CALL control_busca_gastos_ot(orden)

	LET tot_viajes = 0
	IF vm_ind_gastos > 0 THEN
		SKIP 1 LINES
		PRINT COLUMN 11, '-----',
      		      COLUMN 14, '----------',
      		      COLUMN 24, '------------',
      		      COLUMN 38, '--------------------------------',
      		      COLUMN 70, '----------------'  
		PRINT COLUMN 11, 'E',
		      COLUMN 14, 'No Gasto',
		      COLUMN 24, 'Fec. Ini.',
		      COLUMN 36, 'Fec. Fin',
		      COLUMN 48, 'Descripción',
		      COLUMN 81, 'Valor' 
		PRINT COLUMN 11, '-----',
      		      COLUMN 14, '----------',
      		      COLUMN 24, '------------',
      		      COLUMN 38, '--------------------------------',
      		      COLUMN 70, '----------------'  

		FOR i = 1 TO vm_ind_gastos
			PRINT COLUMN 11, rm_det_gastos[i].estado,
		      	      COLUMN 14, fl_justifica_titulo('I',
					 rm_det_gastos[i].num_gasto,8),
			      COLUMN 24, rm_det_gastos[i].fecha_ini,
		      	      COLUMN 36, rm_det_gastos[i].fecha_fin,
		      	      COLUMN 48, rm_det_gastos[i].descripcion[1,23],
		      	      COLUMN 72, rm_det_gastos[i].valor
					 USING '###,###,##&.##' 
			LET tot_viajes = tot_viajes + rm_det_gastos[i].valor
		END FOR	
		PRINT COLUMN 70, '----------------'
		PRINT COLUMN 11, 'TOTAL',
      		      COLUMN 70, tot_viajes USING '#,###,###,##&.##'
	END IF
--
	IF estado_ot = 'F' THEN
		SKIP 1 LINES 
		PRINT COLUMN 11,  'Utilidad --->',
		      COLUMN 70,  total_ot - total_oc - tot_viajes
				  USING '#,###,###,##&.&&'
		LET vm_tot_utilidad = vm_tot_utilidad + total_ot - total_oc - 
				      tot_viajes
		LET vm_tot_egresos  = vm_tot_egresos  + total_oc + tot_viajes
		LET vm_tot_ingresos = vm_tot_ingresos + total_ot  
	END IF

	SKIP 1 LINES 
	
	PRINT '-------------------------------------------------------------------------------------'

ON LAST ROW
	SKIP 1 LINES

	print '&k4S'	        -- Letra (12 cpi)

	PRINT COLUMN 05, 'Total Ingresos --->',
	      COLUMN 30, vm_tot_ingresos USING '###,###,###,##&.##' 
	PRINT COLUMN 05, 'Total Egresos  --->',
	      COLUMN 30, vm_tot_egresos USING '###,###,###,##&.##' 
	PRINT COLUMN 30, '------------------'
	PRINT COLUMN 05, 'Total Utilidad --->',
	      COLUMN 30, vm_tot_utilidad USING '###,###,###,##&.##' 


END REPORT



FUNCTION control_busca_gastos_ot(ot)
DEFINE ot 	LIKE talt023.t23_orden
DEFINE i 	SMALLINT

DECLARE q_talt030 CURSOR FOR
	SELECT t30_estado, t30_num_gasto, t30_fec_ini_viaje,
	       t30_fec_fin_viaje, t31_descripcion, t31_valor, t31_secuencia
	  	 FROM talt030, talt031
		WHERE t30_compania  = vg_codcia
		  AND t30_localidad = vg_codloc
		  AND t30_num_ot    = ot
		  AND t30_moneda    = vm_moneda
		  AND t30_estado    = 'A'
		  AND t30_compania  = t31_compania
		  AND t30_localidad = t31_localidad
		  AND t30_num_gasto = t31_num_gasto
		  AND t30_moneda    = t31_moneda
		ORDER BY t30_num_gasto, t30_fec_ini_viaje, t31_secuencia

LET i = 1
FOREACH q_talt030 INTO rm_det_gastos[i].*
	LET i = i + 1
	IF i > 250 THEN
		EXIT FOREACH
	END IF
END FOREACH
FREE q_talt030

LET vm_ind_gastos = 0
LET vm_ind_gastos = i - 1

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE vm_fecha_ini, vm_fecha_fin TO NULL

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
