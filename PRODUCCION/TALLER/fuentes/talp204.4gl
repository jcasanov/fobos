------------------------------------------------------------------------------
-- Titulo           : talp204.4gl - Ingreso de Ordenes de Trabajo 
-- Elaboracion      : 10-sep-2001
-- Autor            : RCA
-- Formato Ejecucion: fglrun programa.4gl base modulo cia localidad (orden)
-- Ultima Correccion: 
-- Motivo Correccion:  
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- CANTIDAD MAXIMA DE FILAS
DEFINE rm_orden		RECORD LIKE talt023.*
DEFINE vm_ordfact	LIKE talt023.t23_orden
DEFINE vm_tipo		CHAR(1)
DEFINE comando          CHAR(100)
DEFINE r0		RECORD LIKE gent000.* ## Configuracion general
DEFINE r1		RECORD LIKE cxct001.* ## Clientes generales
DEFINE rt1		RECORD LIKE talt001.* ## Líneas de Talleres
DEFINE r2		RECORD LIKE talt002.* ## Secciones taller
DEFINE r3		RECORD LIKE talt003.* ## Mecanicos taller
DEFINE r4		RECORD LIKE talt004.* ## Marcas o Líneas taller
DEFINE r5		RECORD LIKE talt005.* ## Tipos O.T.
DEFINE r6		RECORD LIKE talt006.* ## Subtipos O.T.
DEFINE r10		RECORD LIKE talt010.* ## Vehículos Clientes Taller
DEFINE r13		RECORD LIKE gent013.* ## Monedas generales
DEFINE r14		RECORD LIKE gent014.* ## Factor conversion monedas
DEFINE r22		RECORD LIKE veht022.* ## Maestro de Veh. Vendidos Cía.
DEFINE r23		RECORD LIKE talt023.* ## Lee la O.T.
DEFINE r38		RECORD LIKE veht038.* ## Ordenes de Chequeo
DEFINE r50		RECORD LIKE gent050.* ## Modulo global
DEFINE rc2		RECORD LIKE cxct002.* ## Clientes Localidad
DEFINE rc3		RECORD LIKE cxct003.* ## Clientes Area Negocios
DEFINE f_neto_mo_tal	LIKE talt023.t23_val_mo_tal
DEFINE f_neto_rp_tal	LIKE talt023.t23_val_rp_tal
DEFINE f_neto_rp_alm	LIKE talt023.t23_val_rp_alm
DEFINE f_neto_val_mo_cti LIKE talt023.t23_val_mo_cti
DEFINE f_neto_val_mo_ext LIKE talt023.t23_val_mo_ext
DEFINE f_neto_val_rp_tal LIKE talt023.t23_val_rp_tal
DEFINE f_neto_val_rp_ext LIKE talt023.t23_val_rp_ext
DEFINE f_neto_val_rp_cti LIKE talt023.t23_val_rp_cti
DEFINE f_neto_val_rp_alm LIKE talt023.t23_val_rp_alm
DEFINE f_neto_val_otros1 LIKE talt023.t23_val_otros1
DEFINE f_neto_val_otros2 LIKE talt023.t23_val_otros2
DEFINE vm_flag_mant	CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp204.error')
CALL fgl_init4js()
IF num_args() <> 4 AND num_args() <> 6 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_ordfact  = arg_val(5)
LET vm_tipo     = arg_val(6)
LET vg_proceso = 'talp204'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL decide_consultas()

END MAIN



FUNCTION decide_consultas()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
OPEN WINDOW  w_mod AT 3, 3 WITH FORM '../forms/talf204_1'	
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
INITIALIZE rm_orden.* TO NULL
CASE
	WHEN num_args() = 4
		CALL funcion_master()
	WHEN num_args() = 6
		CALL funcion_master()
		#CALL control_consulta()
		#CALL otros_datos()
END CASE	

END FUNCTION



FUNCTION funcion_master()

LET vm_max_rows = 1000
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'PROCESOS'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Repuestos'
		HIDE OPTION 'Mano Obra'
		HIDE OPTION 'Ordenes Compra'
		HIDE OPTION 'Gastos de Viaje'
		HIDE OPTION 'Recalcula Valores'
		IF num_args() = 6 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Repuestos'
			SHOW OPTION 'Mano Obra'
			SHOW OPTION 'Ordenes Compra'
			CALL control_consulta()
			IF rm_orden.t23_estado = 'F' OR rm_orden.t23_estado = 'D' THEN
				SHOW OPTION 'Forma Pago'
			END IF
			IF rm_orden.t23_val_otros1 > 0 THEN
				SHOW OPTION 'Gastos de Viaje'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
		END IF
		IF vm_num_rows > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
  		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Repuestos'
			SHOW OPTION 'Mano Obra'
			SHOW OPTION 'Ordenes Compra'
			IF rm_orden.t23_val_otros1 > 0 THEN
				SHOW OPTION 'Gastos de Viaje'
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Eliminar'
				HIDE OPTION 'Repuestos'
				HIDE OPTION 'Mano Obra'
				HIDE OPTION 'Ordenes Compra'
				HIDE OPTION 'Gastos de Viaje'
			END IF
		ELSE
			SHOW OPTION 'Repuestos'
			SHOW OPTION 'Mano Obra'
			SHOW OPTION 'Ordenes Compra'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			IF rm_orden.t23_val_otros1 > 0 THEN
				SHOW OPTION 'Gastos de Viaje'
			END IF
		END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
       	COMMAND KEY('P') 'Repuestos' 'Detalle de Repuestos cargados a la Orden.'
		CALL fl_muestra_repuestos_orden_trabajo(vg_codcia, vg_codloc, rm_orden.t23_orden)
       	COMMAND KEY('O') 'Mano Obra' 'Detalle de Mano de Obra.'
		CALL fl_muestra_mano_obra_orden_trabajo(vg_codcia, vg_codloc, rm_orden.t23_orden)
       	COMMAND KEY('D') 'Ordenes Compra' 'Detalle de Ordenes de Compra.'
		CALL muestra_det_ord_compra_orden_trabajo(vg_codcia, vg_codloc,
                                                          rm_orden.t23_orden)
	COMMAND KEY('G') 'Gastos de Viaje' 'Muestra todos los gastos de viaje.'
		CALL ver_gastos_viaje()
       	COMMAND KEY('F') 'Forma Pago' 'Detalle forma de pago de la factura'
		IF rm_orden.t23_estado = 'F' OR 
			rm_orden.t23_estado = 'D' THEN
			CALL control_mostrar_forma_pago(rm_orden.*)
		END IF
	COMMAND KEY('X') 'Imprimir' 'Imprime la orden de trabajo.'
		CALL imprimir()
	COMMAND KEY('Z') 'Recalcula Valores'
		CALL proceso_recalcula_valores()
     	COMMAND KEY('E') 'Eliminar' 'Eliminar registro. '
  		CALL control_eliminacion()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION otros_datos()
MENU 'CONSULTAS'
	COMMAND KEY('O') 'Orden Compra' 'Consultar Orden de Compra'
		IF vm_num_rows > 0 THEN
--			CALL consulta_orden_compra()
		ELSE
      			CALL fgl_winmessage (vg_producto,'Orden de Trabajo no tiene cargado Orden de Compras.','exclamation')
		END IF	
	COMMAND KEY('R') 'Repuestos' 'Consultar Repuestos Almacén'
		IF vm_num_rows > 0 THEN
--			CALL consulta_repuestos_almacen()
		ELSE
      			CALL fgl_winmessage (vg_producto,'Orden de Trabajo no tiene cargados repuestos.','exclamation')
		END IF	
	COMMAND KEY('A') 'Abandonar' 'Salir del programa'
		EXIT MENU
END MENU

END FUNCTION


FUNCTION control_consulta()
DEFINE orden		LIKE talt023.t23_orden
DEFINE cod_cliente	LIKE talt023.t23_cod_cliente
DEFINE nom_cliente	LIKE talt023.t23_nom_cliente
DEFINE desc_cliest	LIKE talt023.t23_nom_cliente
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE codcia		LIKE talt023.t23_compania
DEFINE local		LIKE talt023.t23_localidad
DEFINE tipord		LIKE talt005.t05_tipord
DEFINE nombre		LIKE talt005.t05_nombre
DEFINE subtipo		LIKE talt006.t06_subtipo
DEFINE nomsubtipo	LIKE talt006.t06_nombre
DEFINE seccion		LIKE talt002.t02_seccion
DEFINE nomseccion	LIKE talt002.t02_nombre
DEFINE asemec		LIKE talt003.t03_mecanico
DEFINE nomasemec	LIKE talt003.t03_nombres
DEFINE tipomecase	LIKE talt003.t03_tipo
DEFINE numpre		LIKE talt023.t23_numpre
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE nomoneda		LIKE gent013.g13_nombre
DEFINE simbolo		LIKE gent013.g13_simbolo
DEFINE codesta		LIKE talt023.t23_codcli_est
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE chasis		LIKE talt023.t23_chasis
DEFINE placa		LIKE talt023.t23_placa
DEFINE modelo		LIKE talt023.t23_modelo
DEFINE color		LIKE veht005.v05_cod_color
DEFINE nomcolor		LIKE veht005.v05_descri_base
DEFINE factura		LIKE talt023.t23_num_factura
DEFINE ordenche 	LIKE talt023.t23_orden_cheq
DEFINE estado		LIKE veht038.v38_estado

CLEAR FORM
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON 	
	t23_orden,	t23_estado,	t23_cod_cliente,                   
	t23_tipo_ot,	t23_subtipo_ot, t23_descripcion, t23_seccion,
	t23_cod_asesor, t23_cod_mecani,	t23_numpre,	 t23_valor_tope,
	t23_moneda,	t23_fec_cierre, t23_tel_cliente, t23_codcli_est,
     	t23_fecini, 	t23_fecfin,	t23_cont_cred,	 t23_modelo,	
	t23_chasis, 	t23_placa,	t23_color,	 t23_orden_cheq,	
	t23_num_factura,
        t23_val_mo_tal, t23_val_mo_cti,
	t23_val_mo_ext, t23_val_rp_tal,
	t23_val_rp_ext, t23_val_rp_cti,
	t23_val_rp_alm, 
	t23_por_mo_tal, 
	t23_por_rp_tal, 
	t23_por_rp_alm, 
	t23_vde_mo_tal, 
	t23_vde_rp_tal, 
	t23_vde_rp_alm,
	t23_val_otros1,
	t23_val_otros2,
	t23_tot_bruto, 
	t23_tot_dscto, 
	t23_tot_neto 
	BEFORE CONSTRUCT
		CALL muestra_contadores()
	ON KEY(F2)
		IF INFIELD(t23_orden) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc, 'T') RETURNING orden, nom_cliente
			IF orden IS NOT NULL THEN
				LET rm_orden.t23_orden = orden
				DISPLAY BY NAME rm_orden.t23_orden  
			END IF
		END IF
		IF INFIELD(t23_cod_cliente) THEN
			CALL fl_ayuda_cliente_general() RETURNING cod_cliente, nom_cliente
			IF cod_cliente IS NOT NULL THEN
				LET rm_orden.t23_cod_cliente = cod_cliente
				LET rm_orden.t23_nom_cliente = nom_cliente
				DISPLAY BY NAME rm_orden.t23_cod_cliente  
  				DISPLAY BY NAME rm_orden.t23_nom_cliente
			END IF
		END IF
		IF INFIELD(t23_tipo_ot) THEN
			CALL fl_ayuda_tipo_orden_trabajo(vg_codcia) RETURNING tipord, nombre
			IF tipord IS NOT NULL THEN
				LET rm_orden.t23_tipo_ot = tipord
				DISPLAY BY NAME rm_orden.t23_tipo_ot
				DISPLAY nombre TO desc_tipo_ot  
			END IF
		END IF
		IF INFIELD(t23_subtipo_ot) THEN
			CALL fl_ayuda_subtipo_orden(vg_codcia, tipord) RETURNING nombre, subtipo, nomsubtipo 
			IF subtipo IS NOT NULL THEN
				LET rm_orden.t23_subtipo_ot = subtipo
				DISPLAY BY NAME rm_orden.t23_subtipo_ot
				DISPLAY nomsubtipo TO desc_subtipo_ot  
			END IF
		END IF
		IF INFIELD(t23_seccion) THEN
			CALL fl_ayuda_secciones_taller(vg_codcia) RETURNING seccion, nomseccion
			IF seccion IS NOT NULL THEN
				LET rm_orden.t23_seccion = seccion
				DISPLAY BY NAME rm_orden.t23_seccion
				DISPLAY nomseccion TO desc_seccion  
			END IF
		END IF
		IF INFIELD(t23_cod_asesor) THEN
			LET tipomecase = 'A' 
			CALL fl_ayuda_mecanicos(vg_codcia, tipomecase) RETURNING asemec, nomasemec
			IF asemec IS NOT NULL THEN
				LET rm_orden.t23_cod_asesor = asemec
				DISPLAY BY NAME rm_orden.t23_cod_asesor
				DISPLAY nomasemec TO desc_cod_asesor  
			END IF
		END IF
		IF INFIELD(t23_cod_mecani) THEN
			LET tipomecase = 'M' 
			CALL fl_ayuda_mecanicos(vg_codcia, tipomecase) RETURNING asemec, nomasemec
			IF asemec IS NOT NULL THEN
				LET rm_orden.t23_cod_mecani = asemec
				DISPLAY BY NAME rm_orden.t23_cod_mecani
				DISPLAY nomasemec TO desc_cod_mecani  
			END IF
		END IF
		IF INFIELD(t23_numpre) THEN
			CALL fl_ayuda_presupuestos_taller(vg_codcia, vg_codloc, 'A') RETURNING numpre, cod_cliente, nom_cliente 
			IF numpre IS NOT NULL THEN
				LET rm_orden.t23_numpre = numpre
				DISPLAY BY NAME rm_orden.t23_numpre
			END IF
		END IF
		IF INFIELD(t23_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING moneda, nomoneda,simbolo  
			IF moneda IS NOT NULL THEN
				LET rm_orden.t23_moneda = moneda
				DISPLAY BY NAME rm_orden.t23_moneda
			END IF
		END IF
		IF INFIELD(t23_codcli_est) THEN
			CALL fl_ayuda_cliente_general() RETURNING codesta, nomcli
			--CALL fl_ayuda_cliente_estadistico_tal(vg_codcia, vg_codloc) RETURNING codesta, nomcli
			IF codesta IS NOT NULL THEN
				LET rm_orden.t23_codcli_est = codesta
				LET desc_cliest		    = nomcli
				DISPLAY BY NAME rm_orden.t23_codcli_est, desc_cliest
			END IF
		END IF
		IF INFIELD(t23_modelo) THEN
			CALL fl_ayuda_chasis_cliente(vg_codcia, 'T') RETURNING modelo, chasis, placa, color, cod_cliente, nom_cliente
			IF chasis IS NOT NULL THEN
				LET rm_orden.t23_chasis = chasis
				LET rm_orden.t23_placa  = placa
				LET rm_orden.t23_color  = color
				LET rm_orden.t23_modelo = modelo
				LET rm_orden.t23_cod_cliente = cod_cliente
				LET rm_orden.t23_nom_cliente = nom_cliente
				DISPLAY BY NAME rm_orden.t23_cod_cliente
				DISPLAY BY NAME rm_orden.t23_nom_cliente
				DISPLAY BY NAME rm_orden.t23_chasis 
				DISPLAY BY NAME rm_orden.t23_placa
				DISPLAY BY NAME rm_orden.t23_color
				DISPLAY BY NAME rm_orden.t23_modelo
			END IF
		END IF
		IF INFIELD(t23_num_factura) THEN
			CALL fl_ayuda_facturas_tal(vg_codcia, vg_codloc, 'T') RETURNING factura, nomcli
			IF factura IS NOT NULL THEN
				LET rm_orden.t23_num_factura = factura
				DISPLAY BY NAME rm_orden.t23_num_factura
			END IF
		END IF
		IF INFIELD(t23_orden_cheq) THEN
			CALL fl_ayuda_orden_chequeo(vg_codcia, vg_codloc, 'A') RETURNING ordenche, estado
			IF ordenche IS NOT NULL THEN
				LET rm_orden.t23_orden_cheq = ordenche
				DISPLAY BY NAME rm_orden.t23_orden_cheq
			END IF
		END IF
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL lee_muestra_registro(vm_rows[vm_row_current])
			CALL muestra_contadores()
		END IF
		RETURN
	END IF
ELSE
	IF vm_tipo = 'O' THEN
		LET expr_sql = 't23_orden = ', vm_ordfact
	ELSE
		LET expr_sql = 't23_num_factura = ', vm_ordfact
	END IF
END IF
LET query = 'SELECT *, ROWID FROM talt023 ',
		'WHERE t23_compania  = ', vg_codcia, ' AND ', 
		'      t23_localidad = ', vg_codloc, ' AND ', 
		expr_sql CLIPPED
PREPARE cons FROM query
DECLARE q_orden CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_orden INTO rm_orden.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
      CALL fl_mensaje_consulta_sin_registros()
      IF num_args() <> 4 THEN
		EXIT PROGRAM
      END IF
      CLEAR FORM
      LET vm_row_current = 0
      CALL muestra_contadores()
      RETURN
END IF
LET vm_row_current = 1
CLOSE q_orden
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION control_modificacion()
DEFINE     	flag   CHAR(1)

IF vm_num_rows <= 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

LET vm_flag_mant = 'M'
IF rm_orden.t23_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Orden no está activa.', 'exclamation')
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM talt023 
	WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_orden.*
IF status < 0 THEN
        CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	COMMIT WORK
	RETURN
END IF
CALL ingresa_datos()
IF NOT int_flag THEN
    	UPDATE talt023 SET * = rm_orden.*
		WHERE CURRENT OF q_up
        CALL fl_mensaje_registro_modificado()
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
COMMIT WORK

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resp    		CHAR(6)
DEFINE i		SMALLINT

LET int_flag = 0
IF vm_num_rows = 0 THEN
      CALL fl_mensaje_consultar_primero()
      RETURN
END IF
IF rm_orden.t23_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Orden no está activa.', 'exclamation')
	RETURN
END IF
IF rm_orden.t23_tot_neto <> 0 THEN
	CALL fgl_winmessage(vg_producto, 'Orden tiene valores cargados.', 'exclamation')
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_blo CURSOR FOR SELECT * FROM talt023  
	WHERE ROWID = vm_rows[vm_row_current]
      	FOR UPDATE
OPEN q_blo
FETCH q_blo INTO rm_orden.*
IF status < 0 THEN
      CALL fl_mensaje_bloqueo_otro_usuario()
      WHENEVER ERROR STOP
      COMMIT WORK
      RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'Yes' THEN
      UPDATE talt023 set t23_estado = 'E' WHERE CURRENT OF q_blo
      LET int_flag = 1
      CALL fl_mensaje_registro_modificado()
      WHENEVER ERROR STOP	
      COMMIT WORK
      CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
CALL muestra_contadores()

END FUNCTION



FUNCTION control_ingreso()

LET vm_flag_mant = 'I'
OPTIONS INPUT WRAP
CLEAR FORM
CALL muestra_contadores()
INITIALIZE rm_orden.* TO NULL
LET rm_orden.t23_compania   = vg_codcia
LET rm_orden.t23_localidad  = vg_codloc
LET rm_orden.t23_cont_cred = 'C'
LET rm_orden.t23_fecing     = CURRENT
LET rm_orden.t23_fecini     = DATE(CURRENT)
LET rm_orden.t23_fecfin     = DATE(CURRENT)
LET rm_orden.t23_usuario    = vg_usuario 
LET rm_orden.t23_estado     = "A" 
LET rm_orden.t23_kilometraje= 0
LET rm_orden.t23_val_mo_tal = 0 
LET rm_orden.t23_val_mo_cti = 0
LET rm_orden.t23_val_mo_ext = 0
LET rm_orden.t23_val_rp_tal = 0
LET rm_orden.t23_val_rp_ext = 0
LET rm_orden.t23_val_rp_cti = 0
LET rm_orden.t23_val_rp_alm = 0
LET rm_orden.t23_val_otros1 = 0
LET rm_orden.t23_val_otros2 = 0
LET rm_orden.t23_por_mo_tal = 0 
LET rm_orden.t23_por_rp_tal = 0 
LET rm_orden.t23_por_rp_alm = 0 
LET rm_orden.t23_vde_mo_tal = 0
LET rm_orden.t23_vde_rp_tal = 0
LET rm_orden.t23_vde_rp_alm = 0
LET rm_orden.t23_tot_bruto  = 0
LET rm_orden.t23_tot_dscto  = 0
LET rm_orden.t23_val_impto  = 0
LET rm_orden.t23_tot_neto   = 0
DISPLAY BY NAME rm_orden.t23_fecing, rm_orden.t23_usuario, rm_orden.t23_estado

CALL ingresa_datos()
IF NOT int_flag THEN
	INSERT INTO talt023 values (rm_orden.*)
        CALL fl_mensaje_registro_ingresado()
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF		
CALL muestra_contadores()

END FUNCTION



FUNCTION ingresa_datos()
DEFINE resp   		CHAR(6)
DEFINE orden		LIKE talt023.t23_orden
DEFINE cod_cliente	LIKE talt023.t23_cod_cliente
DEFINE nom_cliente	LIKE talt023.t23_nom_cliente
DEFINE desc_cliest	LIKE talt023.t23_nom_cliente
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE codcia		LIKE talt023.t23_compania
DEFINE local		LIKE talt023.t23_localidad
DEFINE tipord		LIKE talt005.t05_tipord
DEFINE nombre		LIKE talt005.t05_nombre
DEFINE subtipo		LIKE talt006.t06_subtipo
DEFINE nomsubtipo	LIKE talt006.t06_nombre
DEFINE seccion		LIKE talt002.t02_seccion
DEFINE nomseccion	LIKE talt002.t02_nombre
DEFINE asemec		LIKE talt003.t03_mecanico
DEFINE nomasemec	LIKE talt003.t03_nombres
DEFINE tipomecase	LIKE talt003.t03_tipo
DEFINE numpre		LIKE talt023.t23_numpre
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE nomoneda		LIKE gent013.g13_nombre
DEFINE simbolo		LIKE gent013.g13_simbolo
DEFINE codesta		LIKE talt023.t23_codcli_est
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE chasis		LIKE talt023.t23_chasis
DEFINE placa		LIKE talt023.t23_placa
DEFINE modelo		LIKE talt023.t23_modelo
DEFINE color		LIKE veht005.v05_cod_color
DEFINE nomcolor		LIKE veht005.v05_descri_base
DEFINE factura		LIKE talt023.t23_num_factura
DEFINE ordenche 	LIKE talt023.t23_orden_cheq
DEFINE estado		LIKE veht038.v38_estado
DEFINE serimpto		LIKE gent000.g00_serial
DEFINE impto	 	LIKE talt023.t23_porc_impto
DEFINE labelimpto	LIKE gent000.g00_label_impto
DEFINE desc_seccion	LIKE talt002.t02_nombre
DEFINE desc_tipo_ot	LIKE talt005.t05_nombre
DEFINE desc_subtipo_ot	LIKE talt006.t06_nombre
DEFINE desc_cod_asesor  LIKE talt003.t03_nombres
DEFINE desc_cod_mecani	LIKE talt003.t03_nombres
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE f_orden		LIKE talt023.t23_orden
DEFINE por_mo_tal	LIKE talt023.t23_por_mo_tal
DEFINE por_rp_alm	LIKE talt023.t23_por_rp_alm
DEFINE verifica_chasis  LIKE talt023.t23_chasis

DEFINE codcli_ant	LIKE talt023.t23_cod_cliente

 
OPTIONS INPUT WRAP
LET int_flag = 0
LET por_mo_tal		    = 0
LET por_rp_alm		    = 0
LET rc3.z03_dcto_item_c     = 0 
LET rc3.z03_dcto_item_r     = 0
LET rc3.z03_dcto_mano_c     = 0
LET rc3.z03_dcto_mano_r     = 0


INPUT BY NAME 
rm_orden.t23_orden,	rm_orden.t23_cod_cliente,rm_orden.t23_nom_cliente, 
rm_orden.t23_tipo_ot,	rm_orden.t23_subtipo_ot, rm_orden.t23_descripcion, 
rm_orden.t23_seccion,	rm_orden.t23_cod_asesor, rm_orden.t23_cod_mecani,
rm_orden.t23_numpre, 	rm_orden.t23_valor_tope, rm_orden.t23_moneda,	
rm_orden.t23_fec_cierre,rm_orden.t23_tel_cliente,
rm_orden.t23_codcli_est,rm_orden.t23_fecini, 	 rm_orden.t23_fecfin,	
rm_orden.t23_cont_cred,	rm_orden.t23_porc_impto, rm_orden.t23_modelo,	
rm_orden.t23_chasis, 	rm_orden.t23_placa,	 rm_orden.t23_color,	
rm_orden.t23_kilometraje,rm_orden.t23_orden_cheq,
rm_orden.t23_por_mo_tal,
rm_orden.t23_por_rp_tal,
rm_orden.t23_por_rp_alm,
rm_orden.t23_val_otros1,
rm_orden.t23_val_otros2
		WITHOUT DEFAULTS                                          

	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED (
rm_orden.t23_orden,	rm_orden.t23_cod_cliente,rm_orden.t23_nom_cliente, 
rm_orden.t23_tipo_ot,	rm_orden.t23_subtipo_ot, rm_orden.t23_descripcion, 
rm_orden.t23_seccion,	rm_orden.t23_cod_asesor, rm_orden.t23_cod_mecani,
rm_orden.t23_numpre, 	rm_orden.t23_valor_tope, rm_orden.t23_moneda,	
rm_orden.t23_fec_cierre,rm_orden.t23_tel_cliente,
rm_orden.t23_codcli_est,rm_orden.t23_fecini, 	 rm_orden.t23_fecfin,	
rm_orden.t23_cont_cred,	rm_orden.t23_porc_impto, rm_orden.t23_modelo,	
rm_orden.t23_chasis, 	rm_orden.t23_placa,	 rm_orden.t23_color,	
rm_orden.t23_kilometraje,rm_orden.t23_orden_cheq,
rm_orden.t23_por_mo_tal,
rm_orden.t23_por_rp_tal,
rm_orden.t23_por_rp_alm,
rm_orden.t23_val_otros1,
rm_orden.t23_val_otros2) THEN
			RETURN
		END IF
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
				RETURNING resp
			IF resp = 'Yes' THEN
				--CALL lee_muestra_registro(vm_rows[vm_row_current])
				LET int_flag = 1
				RETURN
			END IF
	ON KEY (F2)
		IF INFIELD(t23_cod_cliente) THEN
			CALL fl_ayuda_cliente_general() RETURNING cod_cliente, nom_cliente
			IF cod_cliente IS NOT NULL THEN
				LET rm_orden.t23_cod_cliente = cod_cliente
				LET rm_orden.t23_nom_cliente = nom_cliente
				DISPLAY BY NAME rm_orden.t23_cod_cliente  
  				DISPLAY BY NAME rm_orden.t23_nom_cliente
			END IF
		END IF
		IF INFIELD(t23_tipo_ot) THEN
			CALL fl_ayuda_tipo_orden_trabajo(vg_codcia) RETURNING tipord, nombre
			IF tipord IS NOT NULL THEN
				LET rm_orden.t23_tipo_ot = tipord
				DISPLAY BY NAME rm_orden.t23_tipo_ot
				DISPLAY nombre TO desc_tipo_ot  
			END IF
		END IF
		IF INFIELD(t23_subtipo_ot) THEN
			CALL fl_ayuda_subtipo_orden(vg_codcia, rm_orden.t23_tipo_ot) RETURNING nombre, subtipo, nomsubtipo 
			IF subtipo IS NOT NULL THEN
				LET rm_orden.t23_subtipo_ot = subtipo
				DISPLAY BY NAME rm_orden.t23_subtipo_ot
				DISPLAY nomsubtipo TO desc_subtipo_ot  
			END IF
		END IF
		IF INFIELD(t23_seccion) THEN
			CALL fl_ayuda_secciones_taller(vg_codcia) RETURNING seccion, nomseccion
			IF seccion IS NOT NULL THEN
				LET rm_orden.t23_seccion = seccion
				DISPLAY BY NAME rm_orden.t23_seccion
				DISPLAY nomseccion TO desc_seccion  
			END IF
		END IF
		IF INFIELD(t23_cod_asesor) THEN
			LET tipomecase = 'A' 
			CALL fl_ayuda_mecanicos(vg_codcia, tipomecase) RETURNING asemec, nomasemec
			IF asemec IS NOT NULL THEN
				LET rm_orden.t23_cod_asesor = asemec
				DISPLAY BY NAME rm_orden.t23_cod_asesor
				DISPLAY nomasemec TO desc_cod_asesor  
			END IF
		END IF
		IF INFIELD(t23_cod_mecani) THEN
			LET tipomecase = 'M' 
			CALL fl_ayuda_mecanicos(vg_codcia, tipomecase) RETURNING asemec, nomasemec
			IF asemec IS NOT NULL THEN
				LET rm_orden.t23_cod_mecani = asemec
				DISPLAY BY NAME rm_orden.t23_cod_mecani
				DISPLAY nomasemec TO desc_cod_mecani  
			END IF
		END IF
		IF INFIELD(t23_numpre) THEN
			CALL fl_ayuda_presupuestos_taller(vg_codcia, vg_codloc, 'A') RETURNING numpre, cod_cliente, nom_cliente 
			IF numpre IS NOT NULL THEN
				LET rm_orden.t23_numpre = numpre
				DISPLAY BY NAME rm_orden.t23_numpre
			END IF
		END IF
		IF INFIELD(t23_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING moneda, nomoneda,simbolo  
			IF moneda IS NOT NULL THEN
				LET rm_orden.t23_moneda = moneda
				DISPLAY BY NAME rm_orden.t23_moneda
			END IF
		END IF
		IF INFIELD(t23_codcli_est) THEN
			CALL fl_ayuda_cliente_general() RETURNING codesta, nomcli
			--CALL fl_ayuda_cliente_estadistico_tal(vg_codcia, vg_codloc) RETURNING codesta, nomcli
			IF codesta IS NOT NULL THEN
				LET rm_orden.t23_codcli_est = codesta
				LET desc_cliest		    = nomcli
				DISPLAY BY NAME rm_orden.t23_codcli_est, desc_cliest
			END IF
		END IF
		IF INFIELD(t23_modelo) THEN
			CALL fl_ayuda_chasis_cliente(vg_codcia, 'T') RETURNING modelo, chasis, placa, color, cod_cliente, nom_cliente
			IF chasis IS NOT NULL THEN
				LET rm_orden.t23_chasis = chasis
				LET rm_orden.t23_placa  = placa
				LET rm_orden.t23_color  = color
				LET rm_orden.t23_modelo = modelo
				LET rm_orden.t23_cod_cliente = cod_cliente
				LET rm_orden.t23_nom_cliente = nom_cliente
				DISPLAY BY NAME rm_orden.t23_cod_cliente
				DISPLAY BY NAME rm_orden.t23_nom_cliente
				DISPLAY BY NAME rm_orden.t23_chasis 
				DISPLAY BY NAME rm_orden.t23_placa
				DISPLAY BY NAME rm_orden.t23_color
				DISPLAY BY NAME rm_orden.t23_modelo
			END IF
		END IF
		IF INFIELD(t23_num_factura) THEN
			CALL fl_ayuda_facturas_tal(vg_codcia, vg_codloc, 'T') RETURNING factura, nomcli
			IF factura IS NOT NULL THEN
				LET rm_orden.t23_num_factura = factura
				DISPLAY BY NAME rm_orden.t23_num_factura
			END IF
		END IF
		IF INFIELD(t23_orden_cheq) THEN
			CALL fl_ayuda_orden_chequeo(vg_codcia, vg_codloc, 'A') RETURNING ordenche, estado
			IF ordenche IS NOT NULL THEN
				LET rm_orden.t23_orden_cheq = ordenche
				DISPLAY BY NAME rm_orden.t23_orden_cheq
			END IF
		END IF
		IF INFIELD(t23_porc_impto) THEN
			CALL fl_ayuda_imptos() RETURNING serimpto, impto, labelimpto
			IF impto IS NOT NULL THEN
				LET rm_orden.t23_porc_impto = impto
				DISPLAY BY NAME rm_orden.t23_porc_impto
			END IF
		END IF
	ON KEY(F5)
		IF INFIELD (t23_cod_cliente) THEN
			LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp101 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
			RUN comando
		END IF

	ON KEY(F6)
		IF INFIELD (t23_modelo) THEN
			LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp200 ', vg_base, ' ', 'TA', vg_codcia
			RUN comando
		END IF


	AFTER FIELD t23_orden 
		IF rm_orden.t23_orden IS NULL THEN
			NEXT FIELD t23_orden
  		ELSE	
		LET f_orden = rm_orden.t23_orden
		DISPLAY rm_orden.t23_orden TO f_orden
		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_orden.t23_orden) RETURNING r23.*
		IF r23.t23_orden IS NOT NULL AND r23.t23_orden = rm_orden.t23_orden AND vm_flag_mant = 'I'  THEN
       			CALL fgl_winmessage(vg_producto,'Orden ya existe, consultela si desea mantenimiento o digite nuevo número para ingreso.','exclamation')
			INITIALIZE rm_orden.t23_orden TO NULL
			DISPLAY rm_orden.t23_orden TO f_orden
			NEXT FIELD t23_orden
		END IF
		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_orden.t23_orden) RETURNING r23.*
		CALL fl_lee_configuracion_facturacion() RETURNING r0.*
			IF r0.g00_porc_impto IS NULL THEN
       				CALL fgl_winmessage(vg_producto,'No existen impuestos definidos en el sistema.','exclamation')
				NEXT FIELD t23_orden
       			END IF   
			LET rm_orden.t23_porc_impto = r0.g00_porc_impto
			LET rm_orden.t23_moneda     = r0.g00_moneda_base
			LET rm_orden.t23_precision  = r0.g00_decimal_mb
			DISPLAY BY NAME rm_orden.t23_porc_impto, rm_orden.t23_moneda 
			CALL fl_lee_moneda(rm_orden.t23_moneda) RETURNING r13.*
			IF r13.g13_moneda IS NOT NULL THEN
				IF r13.g13_moneda = rm_orden.t23_moneda THEN
					DISPLAY r13.g13_nombre TO desc_moneda
					LET rm_orden.t23_paridad = 1
					DISPLAY BY NAME rm_orden.t23_paridad	
				END IF
			END IF
			CALL fl_lee_modulo(vg_modulo) RETURNING r50.* 
				IF r50.g50_modulo IS NULL THEN
       					CALL fgl_winmessage(vg_producto,'No existen Módulos definidos en el sistema.','exclamation')
					NEXT FIELD t23_orden
				ELSE
					LET modulo = r50.g50_modulo
				END IF
		END IF
	BEFORE FIELD t23_cod_cliente
		LET codcli_ant = rm_orden.t23_cod_cliente

	AFTER FIELD t23_cod_cliente 
		IF rm_orden.t23_cod_cliente IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_orden.t23_cod_cliente) RETURNING r1.*
			IF r1.z01_codcli IS NOT NULL THEN
				LET rm_orden.t23_cod_cliente = r1.z01_codcli
				LET rm_orden.t23_nom_cliente = r1.z01_nomcli
				IF r1.z01_paga_impto = 'N' THEN
					LET rm_orden.t23_porc_impto = 0
					LET rm_orden.t23_moneda     = r0.g00_moneda_base
					LET rm_orden.t23_precision  = r0.g00_decimal_mb
	    	    END IF
				IF r1.z01_paga_impto = 'S' THEN
					CALL fl_lee_configuracion_facturacion() RETURNING r0.*
					IF r0.g00_porc_impto IS NULL THEN
           				CALL fgl_winmessage(vg_producto,'No existen impuestos definidos en el sistema.','exclamation')
						NEXT FIELD t23_orden
   		    	 	END IF   
					LET rm_orden.t23_porc_impto = r0.g00_porc_impto
					LET rm_orden.t23_moneda     = r0.g00_moneda_base
					LET rm_orden.t23_precision  = r0.g00_decimal_mb
				END IF
				DISPLAY BY NAME rm_orden.t23_cod_cliente, rm_orden.t23_nom_cliente,
								rm_orden.t23_porc_impto, rm_orden.t23_moneda
				CALL fl_lee_cliente_areaneg(vg_codcia, vg_codloc, 
											r50.g50_areaneg_def, 
											rm_orden.t23_cod_cliente) 
					RETURNING rc3.*
				IF rc3.z03_areaneg IS NULL THEN
					CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, 
												  rm_orden.t23_cod_cliente)
						RETURNING rc2.*
					IF rc2.z02_codcli IS NULL THEN
       						CALL fgl_winmessage(vg_producto,'Cliente no habilitado para la Compañía/Localidad.','exclamation')
							INITIALIZE rm_orden.t23_cod_cliente TO NULL
							INITIALIZE rm_orden.t23_nom_cliente TO NULL
							CLEAR t23_cod_cliente
							CLEAR t23_nom_cliente
							NEXT FIELD t23_nom_cliente
					ELSE
--&& CONTROLAR LA LECTURA DEL REGISTRO SI rm_orden.t23_por_mo_tal TIENE VALORES
						IF rm_orden.t23_cont_cred = 'C' AND rm_orden.t23_cod_cliente <> codcli_ant THEN
							LET rm_orden.t23_por_mo_tal = rc2.z02_dcto_mano_c
							LET rm_orden.t23_por_rp_alm = rc2.z02_dcto_item_c
							--DISPLAY BY NAME rm_orden.t23_por_mo_tal
							--DISPLAY BY NAME rm_orden.t23_por_rp_alm
						END IF
						IF rm_orden.t23_cont_cred = 'R' AND rm_orden.t23_cod_cliente <> codcli_ant THEN
							LET rm_orden.t23_por_mo_tal = rc2.z02_dcto_mano_r
							LET rm_orden.t23_por_rp_alm = rc2.z02_dcto_item_r
							--DISPLAY BY NAME rm_orden.t23_por_mo_tal
							--DISPLAY BY NAME rm_orden.t23_por_rp_alm
						END IF
					END IF
				ELSE
					IF rm_orden.t23_cod_cliente <> codcli_ant THEN
						CALL descuento_cliente_area()
					END IF
				END IF 
			--DISPLAY BY NAME rm_orden.t23_por_mo_tal, 
			--	rm_orden.t23_por_rp_alm 
			CALL llama_totalizar()
			NEXT FIELD t23_tipo_ot
		ELSE
			CALL fl_lee_cliente_areaneg(vg_codcia, vg_codloc, r50.g50_areaneg_def, rm_orden.t23_cod_cliente) RETURNING rc3.*
			IF rc3.z03_codcli IS NULL THEN
       				CALL fgl_winmessage(vg_producto,'Cliente no habilitado para el Area de Negocios.','exclamation')
				INITIALIZE rm_orden.t23_cod_cliente TO NULL
				INITIALIZE rm_orden.t23_nom_cliente TO NULL
				CLEAR t23_cod_cliente
				CLEAR t23_nom_cliente
				NEXT FIELD t23_nom_cliente
			END IF
		END IF			

	END IF
			
	AFTER FIELD t23_tipo_ot
		IF rm_orden.t23_tipo_ot IS NULL THEN
			NEXT FIELD t23_tipo_ot
  		ELSE	
			CALL fl_lee_tipo_orden_taller(vg_codcia, rm_orden.t23_tipo_ot) RETURNING r5.* 
			IF r5.t05_tipord IS NULL THEN
       				CALL fgl_winmessage(vg_producto,'No existe Tipo de Orden.','exclamation')
				NEXT FIELD t23_tipo_ot
       			END IF   
			LET rm_orden.t23_tipo_ot     = r5.t05_tipord
			LET desc_tipo_ot	     = r5.t05_nombre
			IF r5.t05_cli_default IS NOT NULL THEN
				LET rm_orden.t23_cod_cliente = r5.t05_cli_default
				CALL fl_lee_cliente_general(rm_orden.t23_cod_cliente) RETURNING r1.* 
				LET rm_orden.t23_nom_cliente = r1.z01_nomcli
				DISPLAY BY NAME rm_orden.t23_nom_cliente
			END IF
			LET rm_orden.t23_valor_tope  = r5.t05_valtope_mb
			DISPLAY BY NAME rm_orden.t23_tipo_ot,
					desc_tipo_ot,
					rm_orden.t23_cod_cliente,
					rm_orden.t23_valor_tope
			IF r5.t05_factura = 'N' THEN	
				LET rm_orden.t23_porc_impto = 0
				DISPLAY BY NAME rm_orden.t23_porc_impto
  			END IF
		END IF

	AFTER FIELD t23_subtipo_ot
		IF rm_orden.t23_subtipo_ot IS NULL THEN
			NEXT FIELD t23_subtipo_ot
  		ELSE	
		CALL fl_lee_subtipo_orden_taller(vg_codcia, rm_orden.t23_tipo_ot, rm_orden.t23_subtipo_ot) RETURNING r6.* 
		IF r6.t06_subtipo IS NULL THEN
       			CALL fgl_winmessage(vg_producto,'No existe Subtipo de Orden.','exclamation')
			NEXT FIELD t23_subtipo_ot
       		END IF   
		LET rm_orden.t23_subtipo_ot = r6.t06_subtipo
		LET desc_subtipo_ot	    = r6.t06_nombre
		DISPLAY BY NAME rm_orden.t23_subtipo_ot, desc_subtipo_ot
		END IF

	AFTER FIELD t23_seccion
		IF rm_orden.t23_seccion IS NULL THEN
			NEXT FIELD t23_seccion
  		ELSE	
		CALL fl_lee_cod_seccion(vg_codcia, rm_orden.t23_seccion) RETURNING r2.*
		IF r2.t02_seccion IS NULL THEN
       			CALL fgl_winmessage(vg_producto,'No existe Sección.','exclamation')
			NEXT FIELD t23_seccion
       		END IF   
		LET rm_orden.t23_seccion = r2.t02_seccion
		LET desc_seccion	 = r2.t02_nombre
		DISPLAY BY NAME rm_orden.t23_seccion, desc_seccion
		END IF

	AFTER FIELD t23_cod_asesor
		IF rm_orden.t23_cod_asesor IS NULL THEN
			CLEAR desc_cod_asesor
			NEXT FIELD t23_cod_asesor
  		ELSE	
		CALL fl_lee_mecanico(vg_codcia, rm_orden.t23_cod_asesor) RETURNING r3.*
		IF r3.t03_mecanico IS NULL  THEN
       			CALL fgl_winmessage(vg_producto,'No existe Asesor.','exclamation')
			NEXT FIELD t23_cod_asesor
		ELSE
			IF  r3.t03_tipo = 'A' THEN
				LET rm_orden.t23_cod_asesor = r3.t03_mecanico
				LET desc_cod_asesor         = r3.t03_nombres
				DISPLAY BY NAME rm_orden.t23_cod_asesor, desc_cod_asesor
			ELSE
       			CALL fgl_winmessage(vg_producto,'No existe Asesor.','exclamation')
			NEXT FIELD t23_cod_asesor
			END IF
		END IF
		END IF

	BEFORE FIELD t23_cont_cred
		LET verifica_chasis = rm_orden.t23_chasis

	AFTER FIELD t23_cod_mecani
		IF rm_orden.t23_cod_mecani IS NULL THEN
			CLEAR desc_cod_mecani
			NEXT FIELD t23_cod_mecani
  		ELSE	
		CALL fl_lee_mecanico(vg_codcia, rm_orden.t23_cod_mecani) RETURNING r3.*
		IF r3.t03_mecanico IS NULL  THEN
       			CALL fgl_winmessage(vg_producto,'No existe Mecanico.','exclamation')
			NEXT FIELD t23_cod_mecani
		ELSE
			IF  r3.t03_tipo = 'M' THEN
				LET rm_orden.t23_cod_mecani = r3.t03_mecanico
				LET desc_cod_mecani         = r3.t03_nombres
				DISPLAY BY NAME rm_orden.t23_cod_mecani, desc_cod_mecani
			ELSE
       			CALL fgl_winmessage(vg_producto,'No existe Mecanico.','exclamation')
			NEXT FIELD t23_cod_mecani
			END IF
		END IF
		END IF
	AFTER FIELD t23_moneda
			IF rm_orden.t23_moneda = r0.g00_moneda_base THEN
				LET rm_orden.t23_paridad = 1
				DISPLAY BY NAME rm_orden.t23_paridad		
			ELSE
				CALL fl_lee_factor_moneda(rm_orden.t23_moneda, r0.g00_moneda_base) RETURNING r14.*
				IF r14.g14_serial IS NULL THEN
              				CALL fgl_winmessage(vg_producto,'No existen Factor de Coversion entre monedas.','exclamation')
					NEXT FIELD t23_moneda
				END IF
				LET rm_orden.t23_paridad = r14.g14_tasa
				DISPLAY BY NAME rm_orden.t23_paridad		
			END IF


	AFTER FIELD t23_modelo
		IF rm_orden.t23_modelo IS NULL THEN
			NEXT FIELD t23_modelo
  		ELSE	
		## Leo cxct002 los descuentos del modelo si el cliente 
		## tiene 0 en M.O. y Repuestos. 
		## (Ya habiendo leido en la cxct003)
		IF rm_orden.t23_cod_cliente IS NOT NULL  THEN
		    IF rm_orden.t23_cont_cred = 'C' THEN
			IF rc2.z02_dcto_item_c = 0 AND rc2.z02_dcto_mano_c = 0					THEN
				CALL fl_lee_tipo_vehiculo(vg_codcia, rm_orden.t23_modelo) RETURNING r4.*
				IF r4.t04_modelo IS NULL THEN
       					CALL fgl_winmessage(vg_producto,'No existe Modelo.','exclamation')
					NEXT FIELD t23_modelo
				ELSE
					LET rm_orden.t23_modelo = r4.t04_modelo
					DISPLAY BY NAME rm_orden.t23_modelo
					CALL fl_lee_linea_taller(vg_codcia, r4.t04_linea) RETURNING rt1.*
					IF rt1.t01_linea IS NULL THEN
       						CALL fgl_winmessage(vg_producto,'No existe Línea para este modelo.','exclamation')
						NEXT FIELD t23_modelo
					ELSE
					CALL descuento_linea() 
					END IF
				END IF
			END IF
		    ELSE
			IF rc2.z02_dcto_item_r = 0 AND rc2.z02_dcto_mano_r = 0					THEN
				CALL fl_lee_tipo_vehiculo(vg_codcia, rm_orden.t23_modelo) RETURNING r4.*
				IF r4.t04_modelo IS NULL THEN
       					CALL fgl_winmessage(vg_producto,'No existe Modelo.','exclamation')
					NEXT FIELD t23_modelo
				ELSE
					LET rm_orden.t23_modelo = r4.t04_modelo
					DISPLAY BY NAME rm_orden.t23_modelo
					CALL fl_lee_linea_taller(vg_codcia, r4.t04_linea) RETURNING rt1.*
					IF rt1.t01_linea IS NULL THEN
       						CALL fgl_winmessage(vg_producto,'No existe Línea para este modelo.','exclamation')
						NEXT FIELD t23_modelo
					ELSE
					CALL descuento_linea() 
					END IF
				END IF
			END IF
	
		    END IF
		END IF
		END IF


	AFTER FIELD t23_chasis		## Chequea que exista en talt010
		CALL fl_lee_vehiculo_cliente_taller(vg_codcia, rm_orden.t23_cod_cliente, rm_orden.t23_modelo, rm_orden.t23_chasis) RETURNING r10.*
		IF r10.t10_chasis <> verifica_chasis THEN
			IF rm_orden.t23_val_mo_tal > 0 OR rm_orden.t23_val_mo_ext > 0 THEN
       				CALL fgl_winmessage(vg_producto,'Mano de Obra cargada previamente, no puede cambiar el modelo del vehículo.','exclamation')
				NEXT FIELD t23_modelo
			END IF
		END IF
		IF r10.t10_chasis IS NOT NULL THEN
			LET rm_orden.t23_chasis = r10.t10_chasis
			DISPLAY BY NAME rm_orden.t23_chasis
		ELSE
       			CALL fgl_winmessage(vg_producto,'No existe chasis para ese cliente, escójalo o ingréselo','exclamation')
			NEXT FIELD t23_modelo	
		END IF

	AFTER FIELD t23_orden_cheq     	## Chequea si la O. Cheq. es de un
					## auto vendido por la compañía
	IF rm_orden.t23_orden_cheq IS NULL THEN
		CONTINUE INPUT
	END IF
		CALL fl_lee_orden_chequeo_veh(vg_codcia, vg_codloc, rm_orden.t23_orden_cheq) RETURNING r38.*
		IF r38.v38_orden_cheq IS NULL THEN
       			CALL fgl_winmessage(vg_producto,'No existe Orden de Chequeo.','exclamation')
			NEXT FIELD t23_orden_cheq
       		ELSE
			LET rm_orden.t23_orden_cheq = r38.v38_orden_cheq
			DISPLAY BY NAME rm_orden.t23_orden_cheq
			CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, r38.v38_codigo_veh) RETURNING r22.*
			IF r22.v22_codigo_veh IS NULL THEN
       				CALL fgl_winmessage(vg_producto,'No existe Serie de Vehículo en Maestro.','exclamation')
				NEXT FIELD t23_orden_cheq
			ELSE
				IF r22.v22_chasis <> rm_orden.t23_chasis THEN
       					CALL fgl_winmessage(vg_producto,'Orden de Cheque no corresponde al Cliente de la O.T.','exclamation')
					NEXT FIELD t23_orden_cheq
				ELSE
					NEXT FIELD NEXT	
				END IF
			END IF
       		END IF   

	AFTER FIELD t23_por_mo_tal        ## Debido a que se puede digitar
		CALL llama_totalizar()

	AFTER FIELD t23_por_rp_tal
		CALL llama_totalizar()	

	AFTER FIELD t23_por_rp_alm
		CALL llama_totalizar()
	AFTER FIELD t23_val_otros1
		CALL llama_totalizar()
	AFTER FIELD t23_val_otros2
		CALL llama_totalizar()

	AFTER INPUT
		CALL fl_lee_vehiculo_cliente_taller(vg_codcia, rm_orden.t23_cod_cliente, rm_orden.t23_modelo, rm_orden.t23_chasis) RETURNING r10.*
		IF r10.t10_chasis IS  NULL THEN
       			CALL fgl_winmessage(vg_producto,'No existe chasis para ese cliente, escójalo o ingréselo','exclamation')
			NEXT FIELD t23_modelo	
		END IF
		IF r10.t10_chasis <> verifica_chasis THEN
			IF rm_orden.t23_val_mo_tal > 0 OR rm_orden.t23_val_mo_ext > 0 THEN
       				CALL fgl_winmessage(vg_producto,'Mano de Obra cargada previamente, no puede cambiar el modelo del vehículo.','exclamation')
				NEXT FIELD t23_modelo
			END IF
		END IF
{
		-- &&
		-- CHEQUEA CLIENTE NUEVAMENTE PARA DESCUENTOS
		IF rm_orden.t23_cod_cliente IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_orden.t23_cod_cliente) RETURNING r1.*
		IF r1.z01_codcli IS NOT NULL THEN
			LET rm_orden.t23_cod_cliente = r1.z01_codcli
			LET rm_orden.t23_nom_cliente = r1.z01_nomcli
			DISPLAY BY NAME rm_orden.t23_cod_cliente,
					rm_orden.t23_nom_cliente
			CALL fl_lee_cliente_areaneg(vg_codcia, vg_codloc, 
				r50.g50_areaneg_def, rm_orden.t23_cod_cliente) 
				RETURNING rc3.*
		IF r1.z01_codcli IS NOT NULL THEN
			LET rm_orden.t23_cod_cliente = r1.z01_codcli
			LET rm_orden.t23_nom_cliente = r1.z01_nomcli
			DISPLAY BY NAME rm_orden.t23_cod_cliente,
					rm_orden.t23_nom_cliente
			CALL fl_lee_cliente_areaneg(vg_codcia, vg_codloc, 
				r50.g50_areaneg_def, rm_orden.t23_cod_cliente) 
				RETURNING rc3.*
			IF rc3.z03_areaneg IS NULL THEN
				CALL fl_lee_cliente_localidad(vg_codcia, 
					vg_codloc, rm_orden.t23_cod_cliente)
					RETURNING rc2.*
					IF rc2.z02_codcli IS NULL THEN
       						CALL fgl_winmessage(vg_producto,'Cliente no habilitado para la Compañía/Localidad.','exclamation')
						INITIALIZE rm_orden.t23_cod_cliente TO NULL
						INITIALIZE rm_orden.t23_nom_cliente TO NULL
						CLEAR t23_cod_cliente
						CLEAR t23_nom_cliente
						NEXT FIELD t23_nom_cliente
					ELSE
--&& CONTROLAR LA LECTURA DEL REGISTRO SI rm_orden.t23_por_mo_tal TIENE VALORES
						IF rm_orden.t23_cont_cred = 'C' AND rm_orden.t23_por_mo_tal = 0 THEN
							LET rm_orden.t23_por_mo_tal = rc2.z02_dcto_mano_c
							LET rm_orden.t23_por_rp_alm = rc2.z02_dcto_item_c
							--DISPLAY BY NAME rm_orden.t23_por_mo_tal
							--DISPLAY BY NAME rm_orden.t23_por_rp_alm
						END IF
						IF rm_orden.t23_cont_cred = 'R'
AND rm_orden.t23_por_mo_tal = 0 THEN
							LET rm_orden.t23_por_mo_tal = rc2.z02_dcto_mano_r
							LET rm_orden.t23_por_rp_alm = rc2.z02_dcto_item_r
							--DISPLAY BY NAME rm_orden.t23_por_mo_tal
							--DISPLAY BY NAME rm_orden.t23_por_rp_alm
						END IF
					END IF
			ELSE
				CALL descuento_cliente_area()
			END IF 
		ELSE
			CALL fl_lee_cliente_areaneg(vg_codcia, vg_codloc, r50.g50_areaneg_def, rm_orden.t23_cod_cliente) RETURNING rc3.*
			IF rc3.z03_codcli IS NULL THEN
       				CALL fgl_winmessage(vg_producto,'Cliente no habilitado para el Area de Negocios.','exclamation')
				INITIALIZE rm_orden.t23_cod_cliente TO NULL
				INITIALIZE rm_orden.t23_nom_cliente TO NULL
				CLEAR t23_cod_cliente
				CLEAR t23_nom_cliente
				NEXT FIELD t23_nom_cliente
			END IF
		END IF			
		END IF
		END IF
}
 
END INPUT
                                                                                
END FUNCTION



FUNCTION llama_totalizar()
	CALL fl_totaliza_orden_taller(rm_orden.*) RETURNING rm_orden.* 
	DISPLAY BY NAME rm_orden.t23_por_mo_tal
	DISPLAY BY NAME rm_orden.t23_por_rp_alm
	LET f_neto_mo_tal = rm_orden.t23_val_mo_tal - rm_orden.t23_vde_mo_tal 
	LET f_neto_val_mo_cti = rm_orden.t23_val_mo_cti 
	LET f_neto_val_mo_ext = rm_orden.t23_val_mo_ext
	LET f_neto_val_rp_ext = rm_orden.t23_val_rp_ext
	LET f_neto_val_rp_cti = rm_orden.t23_val_rp_cti
	LET f_neto_val_otros1 = rm_orden.t23_val_otros1
	LET f_neto_val_otros2 = rm_orden.t23_val_otros2
	LET f_neto_rp_alm = rm_orden.t23_val_rp_alm - rm_orden.t23_vde_rp_alm 
	LET f_neto_rp_tal = rm_orden.t23_val_rp_tal - rm_orden.t23_vde_rp_tal 
	DISPLAY BY NAME rm_orden.t23_vde_mo_tal	
	DISPLAY BY NAME f_neto_mo_tal
	DISPLAY BY NAME f_neto_val_mo_cti
	DISPLAY BY NAME f_neto_val_mo_ext
	DISPLAY BY NAME rm_orden.t23_vde_rp_tal	
	DISPLAY BY NAME f_neto_rp_tal
  	DISPLAY BY NAME rm_orden.t23_val_otros1	
  	DISPLAY BY NAME rm_orden.t23_val_otros2	
  	DISPLAY BY NAME f_neto_val_rp_ext	
  	DISPLAY BY NAME f_neto_val_rp_cti	
  	DISPLAY BY NAME f_neto_val_otros1	
  	DISPLAY BY NAME f_neto_val_otros2	
	DISPLAY BY NAME rm_orden.t23_vde_rp_alm	
	DISPLAY BY NAME f_neto_rp_alm
	DISPLAY BY NAME rm_orden.t23_tot_bruto
	DISPLAY BY NAME rm_orden.t23_tot_dscto
	DISPLAY BY NAME rm_orden.t23_val_impto
	DISPLAY BY NAME rm_orden.t23_tot_neto
END FUNCTION

{
FUNCTION totalizar(rm_orden)
DEFINE rm_orden RECORD LIKE talt023.*
	LET rm_orden.t23_vde_mo_tal = 
	    (rm_orden.t23_val_mo_tal * rm_orden.t23_por_mo_tal)/100

	LET rm_orden.t23_vde_rp_tal = 
	    (rm_orden.t23_val_rp_tal * rm_orden.t23_por_rp_tal)/100


	LET rm_orden.t23_vde_rp_alm = 
	    	(rm_orden.t23_val_rp_alm * rm_orden.t23_por_rp_alm)/100

	LET rm_orden.t23_tot_bruto =
		(rm_orden.t23_val_mo_tal + rm_orden.t23_val_mo_cti + 
		 rm_orden.t23_val_mo_ext + rm_orden.t23_val_rp_tal + 
		 rm_orden.t23_val_rp_ext + rm_orden.t23_val_rp_cti +
		 rm_orden.t23_val_rp_alm)
	LET rm_orden.t23_tot_dscto = 
		(rm_orden.t23_vde_mo_tal + rm_orden.t23_vde_rp_tal +
		 rm_orden.t23_vde_rp_alm)
	LET rm_orden.t23_val_impto =
		(((rm_orden.t23_tot_bruto - rm_orden.t23_tot_dscto) *
		   rm_orden.t23_porc_impto)/100)
	LET rm_orden.t23_tot_neto  =
		(rm_orden.t23_tot_bruto - rm_orden.t23_tot_dscto + 
		 rm_orden.t23_val_impto)

RETURN rm_orden.*

END FUNCTION
}


FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()
--CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_t28		RECORD LIKE talt028.*
DEFINE neto_mo_tal	LIKE talt023.t23_tot_neto
DEFINE neto_rp_tal	LIKE talt023.t23_tot_neto
DEFINE neto_rp_alm	LIKE talt023.t23_tot_neto

IF vm_num_rows <= 0 OR num_row <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_orden.* FROM talt023 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
IF rm_orden.t23_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	IF rm_orden.t23_estado = 'C' THEN
		DISPLAY 'CERRADA' TO tit_estado
	ELSE
		IF rm_orden.t23_estado = 'F' THEN
			DISPLAY 'FACTURADA' TO tit_estado
		ELSE
			IF rm_orden.t23_estado = 'E' THEN
				DISPLAY 'ELIMINADA' TO tit_estado
			ELSE
				IF rm_orden.t23_estado = 'D' THEN
					DISPLAY 'DEVUELTA' TO tit_estado
					SELECT * INTO r_t28.* FROM talt028
					   WHERE t28_compania  = vg_codcia AND 
	                                         t28_localidad = vg_codloc AND
	                                         t28_ot_ant    = rm_orden.t23_orden
					DISPLAY r_t28.t28_fec_anula TO
						fec_anula
				END IF
			END IF
		END IF
	END IF	
END IF

CALL fl_lee_tipo_orden_taller(vg_codcia, rm_orden.t23_tipo_ot) 
	RETURNING r5.*
IF r5.t05_tipord IS NOT NULL THEN
	IF rm_orden.t23_tipo_ot = r5.t05_tipord THEN
		DISPLAY r5.t05_nombre TO desc_tipo_ot
	END IF
END IF

CALL fl_lee_subtipo_orden_taller(vg_codcia, rm_orden.t23_tipo_ot, rm_orden.t23_subtipo_ot) 
	RETURNING r6.*
IF r6.t06_tipord IS NOT NULL THEN
	IF rm_orden.t23_tipo_ot = r6.t06_tipord THEN
		IF rm_orden.t23_subtipo_ot = r6.t06_subtipo THEN
			DISPLAY r6.t06_nombre TO desc_subtipo_ot
		END IF
	END IF
END IF

CALL fl_lee_moneda(rm_orden.t23_moneda) RETURNING r13.*
IF r13.g13_moneda IS NOT NULL THEN
	IF r13.g13_moneda = rm_orden.t23_moneda THEN
		DISPLAY r13.g13_nombre TO desc_moneda
	END IF
END IF


CALL fl_lee_mecanico(vg_codcia, rm_orden.t23_cod_mecani) RETURNING r3.*
IF r3.t03_mecanico IS NOT NULL AND r3.t03_tipo = 'M' THEN
	IF r3.t03_mecanico = rm_orden.t23_cod_mecani AND r3.t03_tipo = 'M' THEN
		DISPLAY r3.t03_nombres TO desc_cod_mecani
	END IF
END IF

CALL fl_lee_mecanico(vg_codcia, rm_orden.t23_cod_asesor) RETURNING r3.*
IF r3.t03_mecanico IS NOT NULL AND r3.t03_tipo = 'A' THEN
	IF r3.t03_mecanico = rm_orden.t23_cod_asesor AND r3.t03_tipo = 'A' THEN
		DISPLAY r3.t03_nombres TO desc_cod_asesor
	END IF
END IF

CALL fl_lee_cod_seccion(vg_codcia, rm_orden.t23_seccion) RETURNING r2.*
IF r2.t02_seccion IS NOT NULL THEN
	IF r2.t02_seccion = rm_orden.t23_seccion  THEN
		DISPLAY r2.t02_nombre TO desc_seccion
	END IF
END IF

CALL llama_totalizar()

DISPLAY BY NAME rm_orden.t23_orden        THRU rm_orden.t23_paridad,
		rm_orden.t23_fecini       THRU rm_orden.t23_val_rp_alm,
		rm_orden.t23_por_mo_tal   THRU rm_orden.t23_fecing

		DISPLAY rm_orden.t23_orden TO f_orden
END FUNCTION



FUNCTION descuento_cliente_loc()
## Lee porcentajes de descuento de la Compañía/Localidad del Cliente
IF rm_orden.t23_cont_cred = 'C' THEN
	LET rm_orden.t23_por_mo_tal = rc2.z02_dcto_mano_c
	LET rm_orden.t23_por_rp_alm = rc2.z02_dcto_item_c
ELSE
	LET rm_orden.t23_por_mo_tal = rc2.z02_dcto_mano_r
	LET rm_orden.t23_por_rp_alm = rc2.z02_dcto_item_r
END IF

END FUNCTION



FUNCTION descuento_cliente_area()
## Lee porcentajes de descuento del Area Negocio Cliente
IF rm_orden.t23_cont_cred = 'C' THEN
	LET rm_orden.t23_por_mo_tal = rc3.z03_dcto_mano_c
	LET rm_orden.t23_por_rp_alm = rc3.z03_dcto_item_c
ELSE
	LET rm_orden.t23_por_mo_tal = rc3.z03_dcto_mano_r
	LET rm_orden.t23_por_rp_alm = rc3.z03_dcto_item_r
END IF

END FUNCTION



FUNCTION descuento_linea()
## Lee porcentage de descuento por la Línea del Modelo
DEFINE por_mo_tal	LIKE talt023.t23_por_mo_tal
DEFINE por_rp_alm	LIKE talt023.t23_por_rp_alm

IF rm_orden.t23_cont_cred = 'C' THEN 
	LET rm_orden.t23_por_mo_tal = rt1.t01_dcto_mo_cont 
	LET rm_orden.t23_por_rp_alm = rt1.t01_dcto_rp_cont
	DISPLAY BY NAME rm_orden.t23_por_mo_tal, rm_orden.t23_por_rp_alm 
	LET por_mo_tal = rm_orden.t23_por_mo_tal
	LET por_rp_alm = rm_orden.t23_por_rp_alm
ELSE
	LET rm_orden.t23_por_mo_tal = rt1.t01_dcto_mo_cred 
	LET rm_orden.t23_por_rp_alm = rt1.t01_dcto_rp_cred
	DISPLAY BY NAME rm_orden.t23_por_mo_tal, rm_orden.t23_por_rp_alm 
	LET por_mo_tal = rm_orden.t23_por_mo_tal
	LET por_rp_alm = rm_orden.t23_por_rp_alm
END IF
END FUNCTION



FUNCTION muestra_contadores() 

DISPLAY vm_row_current, vm_num_rows TO vm_row_current3, vm_num_rows3
DISPLAY vm_row_current, vm_num_rows TO vm_row_current2, vm_num_rows2
DISPLAY vm_row_current, vm_num_rows TO vm_row_current1, vm_num_rows1

END FUNCTION


 
FUNCTION control_mostrar_forma_pago(r_ord)
DEFINE r_ord		RECORD LIKE talt023.*
DEFINE r_fp		RECORD LIKE talt025.*
DEFINE r_mod		RECORD LIKE talt004.*
DEFINE r_lin		RECORD LIKE talt001.*
DEFINE r_glin		RECORD LIKE gent020.*
DEFINE r_cp		RECORD LIKE cajt010.*
DEFINE r_dp		RECORD LIKE cajt011.*
DEFINE linea 		LIKE rept020.r20_linea
DEFINE i		SMALLINT
DEFINE num_ant		SMALLINT
DEFINE num_caj		SMALLINT
DEFINE num_cred		SMALLINT
DEFINE val_caja		DECIMAL(12,2)
DEFINE r_ant  ARRAY[100] OF RECORD
		t27_tipo	LIKE talt027.t27_tipo,
		t27_numero	LIKE talt027.t27_numero,
		t27_valor	LIKE talt027.t27_valor
	END RECORD
DEFINE r_caj  ARRAY[100] OF RECORD
		j11_codigo_pago	LIKE cajt011.j11_codigo_pago,
		nombre_bt	VARCHAR(20),
		j11_num_ch_aut	LIKE cajt011.j11_num_ch_aut,
		j11_moneda	LIKE cajt011.j11_moneda,
		j11_valor	LIKE cajt011.j11_valor
	END RECORD
DEFINE r_cred  ARRAY[100] OF RECORD
		t26_dividendo	LIKE talt026.t26_dividendo,
		t26_fec_vcto	LIKE talt026.t26_fec_vcto,
		t26_valor_cap	LIKE talt026.t26_valor_cap,
		t26_valor_int	LIKE talt026.t26_valor_int,
		tot_div		DECIMAL(12,2)
	END RECORD

CALL fl_lee_tipo_vehiculo(r_ord.t23_compania, r_ord.t23_modelo) 
	RETURNING r_mod.*
CALL fl_lee_linea_taller(r_ord.t23_compania, r_mod.t04_linea) 
	RETURNING r_lin.*
CALL fl_lee_grupo_linea(r_ord.t23_compania, r_lin.t01_grupo_linea)
	RETURNING r_glin.*
OPEN WINDOW w_fp AT 2,5 WITH FORM "../forms/talf204_2"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MESSAGE LINE LAST,
		  MENU LINE 0)
DISPLAY BY NAME r_ord.t23_num_factura
DISPLAY 'TP.'    TO tit_ant1
DISPLAY 'Número' TO tit_ant2
DISPLAY 'Valor'  TO tit_ant3
DISPLAY 'TP.'                 TO tit_caj1
DISPLAY 'Banco/Tarjeta'       TO tit_caj2 
DISPLAY 'No. Cheque/Tarjeta'  TO tit_caj3
DISPLAY 'Mo.'                 TO tit_caj4 
DISPLAY 'V a l o r'           TO tit_caj5
DISPLAY 'No.'                 TO tit_cred1
DISPLAY 'Fec.Vcto.'           TO tit_cred2
DISPLAY 'Valor Capital'       TO tit_cred3
DISPLAY 'Valor Interés'       TO tit_cred4
DISPLAY 'Valor Total'         TO tit_cred5
INITIALIZE r_fp.* TO NULL
LET r_fp.t25_valor_ant  = 0
LET r_fp.t25_valor_cred = 0
LET num_ant             = 0
LET num_caj             = 0
LET num_cred            = 0
SELECT * INTO r_fp.* FROM talt025
	WHERE t25_compania  = r_ord.t23_compania AND 
	      t25_localidad = r_ord.t23_localidad AND 
	      t25_orden     = r_ord.t23_orden
LET val_caja = r_ord.t23_tot_neto - r_fp.t25_valor_ant - r_fp.t25_valor_cred
DISPLAY BY NAME r_fp.t25_valor_ant, r_fp.t25_valor_cred, r_ord.t23_tot_neto,
		val_caja
IF r_fp.t25_orden IS NOT NULL THEN
	DECLARE q_dpa CURSOR FOR 
		SELECT t27_tipo, t27_numero, t27_valor
			FROM talt027
			WHERE t27_compania  = r_ord.t23_compania AND 
		              t27_localidad = r_ord.t23_localidad AND
		              t27_orden     = r_fp.t25_orden  
	LET num_ant = 1
	FOREACH q_dpa INTO r_ant[num_ant].*
		LET num_ant = num_ant + 1
	END FOREACH
	FREE q_dpa
	LET num_ant = num_ant - 1
	DECLARE q_dcr CURSOR FOR
		SELECT t26_dividendo, t26_fec_vcto, t26_valor_cap,
		       t26_valor_int, t26_valor_cap + t26_valor_int
			FROM talt026
			WHERE t26_compania  = r_ord.t23_compania AND 
			      t26_localidad = r_ord.t23_localidad AND 
		              t26_orden     = r_fp.t25_orden  
			ORDER BY 1
	LET num_cred = 1
	FOREACH q_dcr INTO r_cred[num_cred].*
		LET num_cred = num_cred + 1
	END FOREACH
	FREE q_dcr
	LET num_cred = num_cred - 1
END IF
DECLARE q_caj CURSOR FOR
	SELECT cajt010.*, cajt011.* FROM cajt010, cajt011
		WHERE j10_compania     = r_ord.t23_compania AND 
              	      j10_localidad    = r_ord.t23_localidad AND
      	      	      j10_areaneg      = r_glin.g20_areaneg AND
      	      	      j10_tipo_destino = 'FA' AND 
              	      j10_num_destino  = r_ord.t23_num_factura AND
      	      	      j10_compania     = j11_compania AND
      	              j10_localidad    = j11_localidad AND
      	              j10_tipo_fuente  = j11_tipo_fuente AND 
     	              j10_num_fuente   = j11_num_fuente
LET num_caj = 0
OPEN q_caj
WHILE TRUE
	FETCH q_caj INTO r_cp.*, r_dp.*
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	LET num_caj = num_caj + 1
	LET r_caj[num_caj].j11_codigo_pago  = r_dp.j11_codigo_pago
	LET r_caj[num_caj].j11_num_ch_aut   = r_dp.j11_num_ch_aut
	LET r_caj[num_caj].j11_moneda	    = r_dp.j11_moneda
	LET r_caj[num_caj].j11_valor	     = r_dp.j11_valor
	IF r_dp.j11_codigo_pago = 'CH' THEN
		SELECT g08_nombre INTO r_caj[num_caj].nombre_bt 
			FROM gent008
			WHERE g08_banco = r_dp.j11_cod_bco_tarj
	END IF
 	IF r_dp.j11_codigo_pago = 'TJ' THEN
		SELECT g10_nombre INTO r_caj[num_caj].nombre_bt 
			FROM gent010
			WHERE g10_tarjeta = r_dp.j11_cod_bco_tarj
	END IF
END WHILE
CLOSE q_caj
FREE q_caj
FOR i = 1 TO fgl_scr_size('r_ant')
	IF i <= num_ant THEN
		DISPLAY r_ant[i].* TO r_ant[i].*
	END IF
END FOR	
FOR i = 1 TO fgl_scr_size('r_caj')
	IF i <= num_caj THEN
		DISPLAY r_caj[i].* TO r_caj[i].*
	END IF
END FOR	
FOR i = 1 TO fgl_scr_size('r_cred')
	IF i <= num_cred THEN
		DISPLAY r_cred[i].* TO r_cred[i].*
	END IF
END FOR	
MENU ''
	BEFORE MENU
		IF num_ant <= fgl_scr_size('r_ant') THEN
			HIDE OPTION 'Anticipos'
		END IF
		IF num_cred <= fgl_scr_size('r_cred') THEN
			HIDE OPTION 'Crédito'
		END IF
		IF num_caj <= fgl_scr_size('r_caj') THEN
			HIDE OPTION 'Caja'
		END IF
	COMMAND 'Anticipos'
		IF num_ant > fgl_scr_size('r_ant') THEN
			CALL set_count(num_ant)
			DISPLAY ARRAY r_ant TO r_ant.*
				BEFORE DISPLAY
					CALL dialog.keysetlabel("ACCEPT","")
				AFTER DISPLAY
					CONTINUE DISPLAY
				ON KEY(INTERRUPT)
					EXIT DISPLAY
			END DISPLAY
		END IF
	COMMAND 'Crédito'
		IF num_cred > fgl_scr_size('r_cred') THEN
			CALL set_count(num_cred)
			DISPLAY ARRAY r_cred TO r_cred.*
				BEFORE DISPLAY
					CALL dialog.keysetlabel("ACCEPT","")
				AFTER DISPLAY
					CONTINUE DISPLAY
				ON KEY(INTERRUPT)
					EXIT DISPLAY
			END DISPLAY
		END IF
	COMMAND 'Caja'
		IF num_caj > fgl_scr_size('r_caj') THEN
			CALL set_count(num_caj)
			DISPLAY ARRAY r_caj TO r_caj.*
				BEFORE DISPLAY
					CALL dialog.keysetlabel("ACCEPT","")
				AFTER DISPLAY
					CONTINUE DISPLAY
				ON KEY(INTERRUPT)
					EXIT DISPLAY
			END DISPLAY
		END IF
	COMMAND 'Salir'
		EXIT MENU
END MENU
CLOSE WINDOW w_fp

END FUNCTION	



FUNCTION muestra_det_ord_compra_orden_trabajo(codcia, codloc, ord_trab)

DEFINE codcia		LIKE talt023.t23_compania
DEFINE codloc		LIKE talt023.t23_localidad
DEFINE ord_trab, orden	LIKE talt023.t23_orden
DEFINE rfd		RECORD LIKE talt028.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE estado 		LIKE talt023.t23_estado

DEFINE tot_neto		LIKE ordt010.c10_tot_compra
DEFINE i		SMALLINT
DEFINE max_rows		SMALLINT
DEFINE r_oc ARRAY[150] OF RECORD
	estado		LIKE ordt010.c10_estado,
	numero_oc	LIKE ordt010.c10_numero_oc,
	fecha		DATE,
	descripcion	LIKE ordt011.c11_descrip,
	total		LIKE ordt010.c10_tot_compra
END RECORD

LET max_rows = 150

OPEN WINDOW w_oc AT 6,4 WITH FORM "../forms/talf204_3"
	ATTRIBUTE(FORM LINE FIRST, MESSAGE LINE LAST, BORDER)
ERROR "Seleccionando datos . . . espere por favor" ATTRIBUTE(NORMAL)

DISPLAY 'E'           TO tit_col1
DISPLAY 'O.C.'        TO tit_col2
DISPLAY 'Fecha'       TO tit_col3
DISPLAY 'Descripcion' TO tit_col4
DISPLAY 'Valor Total' TO tit_col5

LET orden  = ord_trab
LET estado = rm_orden.t23_estado
WHILE estado = 'D'
	INITIALIZE rfd.* TO NULL
	SELECT * INTO rfd.* FROM talt028
		WHERE t28_compania  = codcia AND 
	              t28_localidad = codloc AND
	              t28_ot_ant    = orden
	IF status = NOTFOUND THEN
		CALL fgl_winmessage(vg_producto, 'Factura está devuelta y no consta en talt028', 'exclamation')
		RETURN
	END IF
	CALL fl_lee_orden_trabajo(codcia, codloc, rfd.t28_ot_nue) RETURNING r_t23.*
	LET estado = r_t23.t23_estado
	LET orden  = rfd.t28_ot_nue
END WHILE

DECLARE q_oc CURSOR FOR 
	SELECT c10_estado, c10_numero_oc, DATE(c10_fecing), c11_descrip, 
	       ((c11_precio - c11_val_descto) * (1 + c10_recargo / 100))
		FROM ordt010, ordt011
		WHERE c10_compania    = codcia
		  AND c10_localidad   = codloc
		  AND c10_ord_trabajo = orden
		  AND c11_compania    = c10_compania
		  AND c11_localidad   = c10_localidad
		  AND c11_numero_oc   = c10_numero_oc
		  AND c11_tipo        = 'S'
	UNION ALL
	SELECT c10_estado, c10_numero_oc, DATE(c10_fecing), c11_descrip, 
	     (((c11_cant_rec * c11_precio) - c11_val_descto) * 
		(1 + c10_recargo / 100))
		FROM ordt010, ordt011
		WHERE c10_compania    = codcia
		  AND c10_localidad   = codloc
		  AND c10_ord_trabajo = orden
		  AND c11_compania    = c10_compania
		  AND c11_localidad   = c10_localidad
		  AND c11_numero_oc   = c10_numero_oc
		  AND c11_tipo        = 'B'
	ORDER BY 3, 2

LET tot_neto = 0
LET i = 1
FOREACH q_oc INTO r_oc[i].*
	LET tot_neto = tot_neto + r_oc[i].total
	LET i = i + 1
	IF i > max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_oc
	RETURN
END IF

DISPLAY ord_trab TO num_ot
DISPLAY BY NAME tot_neto

CALL set_count(i)
DISPLAY ARRAY r_oc TO ra_oc.*
	BEFORE DISPLAY 
		CALL dialog.keysetlabel('ACCEPT', '')
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY

CLOSE WINDOW w_oc
	
END FUNCTION



FUNCTION proceso_recalcula_valores()

IF vm_num_rows <= 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL fl_recalcula_valores_ot(vg_codcia, vg_codloc, rm_orden.t23_orden)
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION ver_gastos_viaje()

DEFINE comando		VARCHAR(500)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', 
	      vg_separador, 'fuentes', vg_separador, '; fglrun talp212 ', 
              vg_base, ' ', 'TA', vg_codcia, vg_codloc, rm_orden.t23_orden

RUN comando

END FUNCTION



FUNCTION imprimir()

DEFINE comando		VARCHAR(500)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', 
	      vg_separador, 'fuentes', vg_separador, '; fglrun talp410 ', 
              vg_base, ' ', 'TA', vg_codcia, vg_codloc, rm_orden.t23_orden

RUN comando

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




