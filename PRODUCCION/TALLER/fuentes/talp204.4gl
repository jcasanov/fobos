--------------------------------------------------------------------------------
-- Titulo           : talp204.4gl - Ingreso de Ordenes de Trabajo 
-- Elaboracion      : 10-sep-2001
-- Autor            : RCA
-- Formato Ejecucion: fglrun programa.4gl base modulo cia localidad (orden)
-- Ultima Correccion: 22-Ago-2002
-- Motivo Correccion: Cambios para ACERO COMERCIAL
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows 		ARRAY[1000] OF INTEGER	-- ARREGLO DE ROWID DE FILAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- CANTIDAD MAXIMA DE FILAS
DEFINE vm_size_arr_ant	INTEGER
DEFINE vm_size_arr_cre	INTEGER
DEFINE vm_size_arr_caj	INTEGER
DEFINE rm_orden		RECORD LIKE talt023.*
DEFINE vm_ordfact	LIKE talt023.t23_orden
DEFINE vm_tipo		CHAR(1)
DEFINE comando          CHAR(100)
DEFINE r0		RECORD LIKE gent000.* ## Configuracion general
DEFINE r1		RECORD LIKE cxct001.* ## Clientes generales
DEFINE r_z01		RECORD LIKE cxct001.* ## Clientes generales
DEFINE rt1		RECORD LIKE talt001.* ## Líneas de Talleres
DEFINE r2		RECORD LIKE talt002.* ## Secciones taller
DEFINE r3		RECORD LIKE talt003.* ## Tecnicos taller
DEFINE r4		RECORD LIKE talt004.* ## Marcas o Líneas taller
DEFINE r5		RECORD LIKE talt005.* ## Tipos O.T.
DEFINE r6		RECORD LIKE talt006.* ## Subtipos O.T.
DEFINE r13		RECORD LIKE gent013.* ## Monedas generales
DEFINE r14		RECORD LIKE gent014.* ## Factor conversion monedas
--DEFINE r22		RECORD LIKE veht022.* ## Maestro de Veh. Vendidos Cía.
DEFINE r23		RECORD LIKE talt023.* ## Lee la O.T.
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
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_c10		RECORD LIKE ordt010.*
DEFINE rm_c13		RECORD LIKE ordt013.*
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE vm_nue_orden	LIKE talt023.t23_orden
DEFINE r_detalle	ARRAY[250] OF RECORD
				c14_cantidad	LIKE ordt014.c14_cantidad,
				c14_codigo	LIKE ordt014.c14_codigo,
				c14_descrip	LIKE ordt014.c14_descrip,
				c14_descuento	LIKE ordt014.c14_descuento,
				c14_precio	LIKE ordt014.c14_precio
			END RECORD
DEFINE r_oc		ARRAY[300] OF RECORD
				estado		LIKE ordt010.c10_estado,
				numero_oc	LIKE ordt010.c10_numero_oc,
				fecha		DATE,
				descripcion	LIKE ordt010.c10_referencia,
				total		LIKE ordt010.c10_tot_compra,
				marcar_ot	CHAR(1)
			END RECORD
DEFINE vm_ind_arr	SMALLINT
DEFINE vm_max_detalle	SMALLINT
DEFINE vm_act_cli	SMALLINT
DEFINE num_row_oc	SMALLINT
DEFINE max_row_oc	SMALLINT
DEFINE vm_nota_credito  LIKE cxct021.z21_tipo_doc
DEFINE vm_cliente_nc	LIKE cxct021.z21_codcli
DEFINE vm_fact_nue	LIKE ordt013.c13_factura
DEFINE vm_cuantos	INTEGER
DEFINE vm_elim_ot	CHAR(6)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp204.err')
--#CALL fgl_init4js()
		-- Validar # parámetros correcto
IF num_args() <> 4 AND num_args() <> 6 AND num_args() <> 7 THEN
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vm_ordfact = arg_val(5)
LET vm_tipo    = arg_val(6)
LET vg_proceso = 'talp204'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL decide_consultas()

END MAIN



FUNCTION decide_consultas()

CALL fl_nivel_isolation()
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_tal(vg_codcia) RETURNING int_flag
	IF int_flag THEN
		RETURN
	END IF
END IF
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
OPEN WINDOW  w_mod AT 3, 3 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
IF vg_gui = 1 THEN
	OPEN FORM f_tal FROM '../forms/talf204_1'	
ELSE
	OPEN FORM f_tal FROM '../forms/talf204_1c'
END IF
DISPLAY FORM f_tal
INITIALIZE rm_orden.* TO NULL
CASE
	WHEN num_args() = 4
		CALL funcion_master()
	WHEN num_args() = 6
		CALL funcion_master()
		#CALL control_consulta()
		#CALL otros_datos()
	WHEN num_args() = 7
		CALL funcion_master()
END CASE	

END FUNCTION


FUNCTION funcion_master()

CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*		   
LET vm_max_rows = 1000
LET max_row_oc  = 300
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'PROCESOS'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Detalle Proforma'
		HIDE OPTION 'Detalle Inv. Venta'
		HIDE OPTION 'Mano Obra'
		HIDE OPTION 'Ordenes Compra'
		HIDE OPTION 'Gastos de Viaje'
		HIDE OPTION 'Recalcula Valores'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Presupuesto'
		HIDE OPTION 'Proformas'
		HIDE OPTION 'Forma Pago'
		IF num_args() = 6 OR num_args() = 7 THEN
			--HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			IF num_args() = 6 THEN
				SHOW OPTION 'Presupuesto'
			END IF
			SHOW OPTION 'Detalle Proforma'
			SHOW OPTION 'Detalle Inv. Venta'
			SHOW OPTION 'Mano Obra'
			SHOW OPTION 'Ordenes Compra'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Proformas'
			CALL control_consulta()
			IF rm_orden.t23_estado = 'F' OR rm_orden.t23_estado = 'D' THEN
				SHOW OPTION 'Forma Pago'
			END IF
			IF rm_orden.t23_val_otros1 > 0 THEN
				SHOW OPTION 'Gastos de Viaje'
			END IF
		END IF
	{--
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Proformas'
			SHOW OPTION 'Presupuesto'
			SHOW OPTION 'Forma Pago'
		END IF
		IF vm_num_rows > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	--}
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
  		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			IF rm_orden.t23_estado <> 'E' THEN
				SHOW OPTION 'Eliminar'
			ELSE
				HIDE OPTION 'Eliminar'
			END IF
			SHOW OPTION 'Detalle Proforma'
			SHOW OPTION 'Detalle Inv. Venta'
			SHOW OPTION 'Mano Obra'
			SHOW OPTION 'Ordenes Compra'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Proformas'
			SHOW OPTION 'Presupuesto'
			SHOW OPTION 'Forma Pago'
			IF rm_orden.t23_val_otros1 > 0 THEN
				SHOW OPTION 'Gastos de Viaje'
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				IF rm_orden.t23_estado <> 'E' THEN
					SHOW OPTION 'Eliminar'
				ELSE
					HIDE OPTION 'Eliminar'
				END IF
				HIDE OPTION 'Detalle Proforma'
				HIDE OPTION 'Detalle Inv. Venta'
				HIDE OPTION 'Mano Obra'
				HIDE OPTION 'Ordenes Compra'
				HIDE OPTION 'Gastos de Viaje'
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Proformas'
				HIDE OPTION 'Presupuesto'
				HIDE OPTION 'Forma Pago'
			END IF
		ELSE
			SHOW OPTION 'Detalle Proforma'
			SHOW OPTION 'Detalle Inv. Venta'
			SHOW OPTION 'Mano Obra'
			SHOW OPTION 'Ordenes Compra'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			IF rm_orden.t23_estado <> 'E' THEN
				SHOW OPTION 'Eliminar'
			ELSE
				HIDE OPTION 'Eliminar'
			END IF
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Proformas'
			SHOW OPTION 'Presupuesto'
			SHOW OPTION 'Forma Pago'
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
		IF rm_orden.t23_estado <> 'E' THEN
			SHOW OPTION 'Eliminar'
		ELSE
			HIDE OPTION 'Eliminar'
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
		IF rm_orden.t23_estado <> 'E' THEN
			SHOW OPTION 'Eliminar'
		ELSE
			HIDE OPTION 'Eliminar'
		END IF
       	COMMAND KEY('V') 'Detalle Proforma' 'Detalle Proformas y Trans. cargadas a la Orden.'
		CALL fl_control_prof_trans(vg_codcia, vg_codloc, rm_orden.t23_orden)
       	COMMAND KEY('T') 'Detalle Inv. Venta' 'Detalle de Inventario cargado a la Orden.'
		CALL fl_muestra_repuestos_orden_trabajo(vg_codcia, vg_codloc, rm_orden.t23_orden, 'T')
	COMMAND KEY('X') 'Presupuesto' 'Muestra Presupuesto asociado a OT.'
		CALL ver_presupuesto()
       	COMMAND KEY('P') 'Proformas' 'Ver las proformas asociadas a esta orden.'
		CALL muestra_profromas_ot(vg_codcia, vg_codloc, rm_orden.t23_orden)
       	COMMAND KEY('O') 'Mano Obra' 'Detalle de Mano de Obra.'
		CALL fl_muestra_mano_obra_orden_trabajo(vg_codcia, vg_codloc, rm_orden.t23_orden, 1)
       	COMMAND KEY('D') 'Ordenes Compra' 'Detalle de Ordenes de Compra.'
		CALL fl_muestra_det_ord_compra_orden_trabajo(vg_codcia,
						vg_codloc, rm_orden.t23_orden,
						rm_orden.t23_estado)
	COMMAND KEY('G') 'Gastos de Viaje' 'Muestra todos los gastos de viaje.'
		CALL ver_gastos_viaje()
       	COMMAND KEY('F') 'Forma Pago' 'Detalle forma de pago de la factura'
		IF rm_orden.t23_estado = 'F' OR 
			rm_orden.t23_estado = 'D' THEN
			CALL control_mostrar_forma_pago(rm_orden.*)
		END IF
	COMMAND KEY('Z') 'Recalcula Valores'
		CALL proceso_recalcula_valores()
     	COMMAND KEY('E') 'Eliminar' 'Eliminar registro. '
  		CALL control_eliminacion()
		IF rm_orden.t23_estado <> 'E' THEN
			SHOW OPTION 'Eliminar'
		ELSE
			HIDE OPTION 'Eliminar'
		END IF
     	COMMAND KEY('K') 'Imprimir' 'Imprimir registro. '
		CALL imprimir()
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
      			--CALL fgl_winmessage (vg_producto,'Orden de Trabajo no tiene cargado Orden de Compras.','exclamation')
			CALL fl_mostrar_mensaje('Orden de Trabajo no tiene cargado Orden de Compras.','exclamation')
		END IF	
	COMMAND KEY('R') 'Repuestos' 'Consultar Repuestos Almacén'
		IF vm_num_rows > 0 THEN
--			CALL consulta_repuestos_almacen()
		ELSE
      			CALL fgl_winmessage (vg_producto,'Orden de Trabajo no tiene cargados repuestos.','exclamation')
			CALL fl_mostrar_mensaje('Orden de Trabajo no tiene cargados repuestos.','exclamation')
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
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1500)
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
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE nomcolor		LIKE veht005.v05_descri_base
DEFINE factura		LIKE talt023.t23_num_factura
DEFINE modelo		LIKE talt023.t23_modelo
DEFINE linea		LIKE talt004.t04_linea
--DEFINE estado		LIKE veht038.v38_estado

CLEAR FORM
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON 	
	t23_orden,	t23_estado,	t23_cod_cliente, t23_nom_cliente,
	t23_tipo_ot,	t23_subtipo_ot, t23_descripcion, t23_seccion,
	t23_cod_asesor, t23_cod_mecani,	t23_numpre,	 t23_valor_tope,
	t23_moneda,	t23_paridad,    t23_tel_cliente, t23_modelo,
	t23_cont_cred,  t23_porc_impto, t23_fecini, 	 t23_fecfin,
	t23_fec_cierre, t23_num_factura, t23_fec_factura, t23_val_mo_tal,
	t23_por_mo_tal, t23_vde_mo_tal, t23_val_mo_cti,  t23_val_mo_ext,
	t23_val_rp_tal, t23_por_rp_tal, t23_vde_rp_tal,  t23_val_rp_ext,
	t23_val_rp_cti, t23_val_rp_alm, t23_por_rp_alm,  t23_vde_rp_alm,
	t23_val_otros1, t23_val_otros2, t23_tot_bruto,   t23_tot_dscto, 
	t23_val_impto,  t23_tot_neto,   t23_usuario,     t23_fecing
	BEFORE CONSTRUCT
		CALL muestra_contadores()
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t23_orden) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc, 'T')
				RETURNING orden, nom_cliente
			IF orden IS NOT NULL THEN
				LET rm_orden.t23_orden = orden
				DISPLAY BY NAME rm_orden.t23_orden  
			END IF
		END IF
		IF INFIELD(t23_cod_cliente) THEN
			CALL fl_ayuda_cliente_general()
				RETURNING cod_cliente, nom_cliente
			IF cod_cliente IS NOT NULL THEN
				LET rm_orden.t23_cod_cliente = cod_cliente
--				LET rm_orden.t23_nom_cliente = nom_cliente
				DISPLAY BY NAME rm_orden.t23_cod_cliente  
  				DISPLAY BY NAME rm_orden.t23_nom_cliente
			END IF
		END IF
		IF INFIELD(t23_tipo_ot) THEN
			CALL fl_ayuda_tipo_orden_trabajo(vg_codcia)
				RETURNING tipord, nombre
			IF tipord IS NOT NULL THEN
				LET rm_orden.t23_tipo_ot = tipord
				DISPLAY BY NAME rm_orden.t23_tipo_ot
				DISPLAY nombre TO desc_tipo_ot  
			END IF
		END IF
		IF INFIELD(t23_subtipo_ot) THEN
			CALL fl_ayuda_subtipo_orden(vg_codcia, tipord)
				RETURNING nombre, subtipo, nomsubtipo 
			IF subtipo IS NOT NULL THEN
				LET rm_orden.t23_subtipo_ot = subtipo
				DISPLAY BY NAME rm_orden.t23_subtipo_ot
				DISPLAY nomsubtipo TO desc_subtipo_ot  
			END IF
		END IF
		IF INFIELD(t23_seccion) THEN
			CALL fl_ayuda_secciones_taller(vg_codcia)
				RETURNING seccion, nomseccion
			IF seccion IS NOT NULL THEN
				LET rm_orden.t23_seccion = seccion
				DISPLAY BY NAME rm_orden.t23_seccion
				DISPLAY nomseccion TO desc_seccion  
			END IF
		END IF
		IF INFIELD(t23_cod_asesor) THEN
			LET tipomecase = 'A' 
			CALL fl_ayuda_mecanicos(vg_codcia, tipomecase)
				RETURNING asemec, nomasemec
			IF asemec IS NOT NULL THEN
				LET rm_orden.t23_cod_asesor = asemec
				DISPLAY BY NAME rm_orden.t23_cod_asesor
				DISPLAY nomasemec TO desc_cod_asesor  
			END IF
		END IF
		IF INFIELD(t23_cod_mecani) THEN
			LET tipomecase = 'M' 
			CALL fl_ayuda_mecanicos(vg_codcia, tipomecase)
				RETURNING asemec, nomasemec
			IF asemec IS NOT NULL THEN
				LET rm_orden.t23_cod_mecani = asemec
				DISPLAY BY NAME rm_orden.t23_cod_mecani
				DISPLAY nomasemec TO desc_cod_mecani  
			END IF
		END IF
		IF INFIELD(t23_numpre) THEN
			CALL fl_ayuda_presupuestos_taller(vg_codcia, vg_codloc, 'T')
				RETURNING numpre, cod_cliente, nom_cliente 
			IF numpre IS NOT NULL THEN
				LET rm_orden.t23_numpre = numpre
				DISPLAY BY NAME rm_orden.t23_numpre
			END IF
		END IF
		IF INFIELD(t23_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING moneda, nomoneda,simbolo  
			IF moneda IS NOT NULL THEN
				LET rm_orden.t23_moneda = moneda
				DISPLAY BY NAME rm_orden.t23_moneda
			END IF
		END IF
		IF INFIELD(t23_modelo) THEN
			CALL fl_ayuda_tipos_vehiculos(vg_codcia)
				RETURNING modelo, linea
			IF modelo IS NOT NULL THEN
				LET rm_orden.t23_modelo = modelo
				DISPLAY BY NAME rm_orden.t23_modelo
			END IF
		END IF
		IF INFIELD(t23_num_factura) THEN
			CALL fl_ayuda_facturas_tal(vg_codcia, vg_codloc, 'T')
				RETURNING factura, nomcli
			IF factura IS NOT NULL THEN
				LET rm_orden.t23_num_factura = factura
				DISPLAY BY NAME rm_orden.t23_num_factura
			END IF
		END IF
		LET int_flag = 0
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
DEFINE flag   		CHAR(1)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE referencia	LIKE rept019.r19_referencia

IF vm_num_rows <= 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

LET vm_flag_mant = 'M'
IF rm_orden.t23_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Orden no esta activa.','exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM talt023 
	WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_orden.*
IF STATUS < 0 THEN
	ROLLBACK WORK
        CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL ingresa_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF
--LET rm_orden.t23_modelo = "SERVICIOS"
LET rm_orden.t23_usu_modifi = vg_usuario
LET rm_orden.t23_fec_modifi = CURRENT
CALL fl_totaliza_orden_taller(rm_orden.*) RETURNING rm_orden.*
UPDATE talt023 SET * = rm_orden.* WHERE CURRENT OF q_up
IF rm_orden.t23_cod_cliente IS NOT NULL THEN
	CALL fl_lee_cliente_general(rm_orden.t23_cod_cliente) RETURNING r_z01.*
	IF r_z01.z01_codcli IS NOT NULL THEN
		UPDATE rept019
			SET r19_codcli = r_z01.z01_codcli, 
		            r19_nomcli = r_z01.z01_nomcli,
		            r19_dircli = r_z01.z01_direccion1,
	   		    r19_telcli = r_z01.z01_telefono1,
		   	    r19_cedruc = rm_orden.t23_cedruc
		        WHERE r19_compania    = rm_orden.t23_compania
	  	          AND r19_localidad   = rm_orden.t23_localidad
		          AND r19_ord_trabajo = rm_orden.t23_orden
		LET referencia = 'O.T.: ', rm_orden.t23_orden USING '<<<<<<',
				', PRESUP.: ', rm_orden.t23_numpre
				USING '<<<<<<', ', ', r_z01.z01_nomcli CLIPPED
		UPDATE rept019
			SET r19_referencia = referencia
		        WHERE r19_compania         = rm_orden.t23_compania
	  	          AND r19_localidad        = rm_orden.t23_localidad
			  AND r19_cod_tran         = "TR"
		          AND r19_ord_trabajo      = rm_orden.t23_orden
			  AND r19_referencia[1, 5] = "O.T.:"
		CALL actualizar_proformas(r_z01.*, 'O')
		CALL actualizar_proformas(r_z01.*, 'P')
		IF NOT eliminar_preventa_anterior() THEN
			RETURN
		END IF
		UPDATE talt020
			SET t20_cod_cliente = r_z01.z01_codcli, 
		            t20_nom_cliente = r_z01.z01_nomcli,
		            t20_dir_cliente = r_z01.z01_direccion1,
	   		    t20_tel_cliente = r_z01.z01_telefono1,
		   	    t20_cedruc      = rm_orden.t23_cedruc
		        WHERE t20_compania  = rm_orden.t23_compania
	  	          AND t20_localidad = rm_orden.t23_localidad
		          AND t20_numpre    = rm_orden.t23_numpre
	END IF
END IF
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION actualizar_proformas(r_z01, tipo_pr)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE tipo_pr		CHAR(1)
DEFINE porc		LIKE rept021.r21_porc_impto
DEFINE exec_up		CHAR(800)
DEFINE num_ot_p		VARCHAR(100)

CASE tipo_pr
	WHEN 'O' LET num_ot_p = '   AND r21_num_ot     = ', rm_orden.t23_orden
	WHEN 'P' LET num_ot_p = '   AND r21_num_presup = ', rm_orden.t23_numpre
END CASE
IF r_z01.z01_codcli IS NOT NULL THEN
	LET exec_up = 'UPDATE rept021 SET r21_codcli = ',
				r_z01.z01_codcli CLIPPED, ','
ELSE
	LET exec_up = 'UPDATE rept021 SET '
END IF
IF r_z01.z01_paga_impto = 'N' THEN
	LET porc = 0.00
ELSE
	LET porc = rg_gen.g00_porc_impto
END IF
LET exec_up = exec_up CLIPPED, ' r21_porc_impto = ', porc, ', ',
			' r21_tot_neto = (r21_tot_bruto - ',
				'r21_tot_dscto) + ((r21_tot_bruto - ',
				'r21_tot_dscto) * ',
				porc, ' / 100) + ',
				'r21_flete, '
LET exec_up = exec_up CLIPPED,
		' r21_nomcli = "', rm_orden.t23_nom_cliente CLIPPED, '"'
IF rm_orden.t23_dir_cliente IS NOT NULL THEN
	LET exec_up = exec_up CLIPPED,
		', r21_dircli = "', rm_orden.t23_dir_cliente CLIPPED, '"'
END IF
IF rm_orden.t23_tel_cliente IS NOT NULL THEN
	LET exec_up = exec_up CLIPPED,
	   	', r21_telcli = "', rm_orden.t23_tel_cliente CLIPPED, '"'
END IF
IF r_z01.z01_codcli IS NOT NULL THEN
	LET exec_up = exec_up CLIPPED,
		   	', r21_cedruc = "', r_z01.z01_num_doc_id CLIPPED, '"'
END IF
LET exec_up = exec_up CLIPPED,
		' WHERE r21_compania   = ', rm_orden.t23_compania,
	  	'   AND r21_localidad  = ', rm_orden.t23_localidad,
		num_ot_p CLIPPED
PREPARE ex_up FROM exec_up
EXECUTE ex_up
LET exec_up = 'UPDATE rept022 '
IF r_z01.z01_paga_impto = 'N' THEN
	LET exec_up = exec_up CLIPPED,
			' SET r22_val_impto = 0 '
	ELSE
	LET exec_up = exec_up CLIPPED,
			' SET r22_val_impto = ((r22_cantidad * ',
						'r22_precio) - ',
						'r22_val_descto) * ',
						rg_gen.g00_porc_impto,
						' / 100 '
END IF
LET exec_up = exec_up CLIPPED,
		' WHERE r22_compania   = ', rm_orden.t23_compania,
	  	'   AND r22_localidad  = ', rm_orden.t23_localidad,
		'   AND r22_numprof   IN ',
			'(SELECT r21_numprof ',
				'FROM rept021 ',
				' WHERE r21_compania   = r22_compania ',
			  	'   AND r21_localidad  = r22_localidad',
				num_ot_p CLIPPED, ')'
PREPARE ex_up2 FROM exec_up
EXECUTE ex_up2

END FUNCTION



FUNCTION eliminar_preventa_anterior()
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_r24		RECORD LIKE rept024.*
DEFINE flag, i		SMALLINT

LET flag = 1
INITIALIZE r_r23.* TO NULL
SELECT r23_numprev
	FROM rept023
	WHERE r23_compania  = vg_codcia
	  AND r23_localidad = vg_codloc
	  AND r23_num_ot    = rm_orden.t23_orden
	INTO TEMP te_qulazo
WHENEVER ERROR CONTINUE
DECLARE q_elimpre CURSOR FOR
	SELECT * FROM rept023
		WHERE r23_compania  = vg_codcia
		  AND r23_localidad = vg_codloc
		  AND r23_numprev   IN (SELECT r23_numprev FROM te_qulazo)
	FOR UPDATE
OPEN q_elimpre
FETCH q_elimpre INTO r_r23.*
IF STATUS < 0 THEN
	DROP TABLE te_qulazo
	ROLLBACK WORK
	LET flag = 0
	CLOSE q_elimpre
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN flag
END IF
WHENEVER ERROR STOP
IF r_r23.r23_compania IS NULL THEN
	CLOSE q_elimpre
	DROP TABLE te_qulazo
	RETURN flag
END IF
FOREACH q_elimpre INTO r_r23.*
	IF r_r23.r23_cod_tran IS NOT NULL THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_cabecera_caja(r_r23.r23_compania, r_r23.r23_localidad, 'PR',
					r_r23.r23_numprev)
		RETURNING r_j10.*
	IF r_j10.j10_tipo_destino IS NULL THEN
		DELETE FROM cajt011 
			WHERE j11_compania    = r_j10.j10_compania 
			  AND j11_localidad   = r_j10.j10_localidad 
			  AND j11_tipo_fuente =	r_j10.j10_tipo_fuente 
			  AND j11_num_fuente  =	r_j10.j10_num_fuente 
		DELETE FROM cajt010 
			WHERE j10_compania    = r_j10.j10_compania 
			  AND j10_localidad   = r_j10.j10_localidad 
			  AND j10_tipo_fuente =	r_j10.j10_tipo_fuente 
			  AND j10_num_fuente  =	r_j10.j10_num_fuente 
	END IF
	DELETE FROM rept027
		WHERE r27_compania  = r_r23.r23_compania
		  AND r27_localidad = r_r23.r23_localidad
		  AND r27_numprev   = r_r23.r23_numprev
	DELETE FROM rept026
		WHERE r26_compania  = r_r23.r23_compania
		  AND r26_localidad = r_r23.r23_localidad
		  AND r26_numprev   = r_r23.r23_numprev
	DELETE FROM rept025
		WHERE r25_compania  = r_r23.r23_compania
		  AND r25_localidad = r_r23.r23_localidad
		  AND r25_numprev   = r_r23.r23_numprev
	DELETE FROM rept024
		WHERE r24_compania  = r_r23.r23_compania
		  AND r24_localidad = r_r23.r23_localidad
		  AND r24_numprev   = r_r23.r23_numprev
	DELETE FROM rept023 WHERE CURRENT OF q_elimpre
END FOREACH
DROP TABLE te_qulazo
CLOSE q_elimpre
FREE q_elimpre
RETURN flag

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resp    		CHAR(6)
DEFINE i, anulo_oc	SMALLINT
DEFINE mensaje		VARCHAR(150)
DEFINE cuantos		INTEGER

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF NOT (rm_orden.t23_estado <> 'F' AND rm_orden.t23_estado <> 'D') THEN
	LET mensaje = 'Orden esta '
	IF rm_orden.t23_estado = 'F' THEN
		LET mensaje = mensaje CLIPPED, ' FACTURADA'
	END IF
	IF rm_orden.t23_estado = 'D' THEN
		LET mensaje = mensaje CLIPPED, ' DEVUELTA'
	END IF
	LET mensaje = mensaje CLIPPED, ' y no puede ser ELIMINADA.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN
END IF
IF rm_orden.t23_tot_neto <> 0 THEN
	CALL fl_mostrar_mensaje('Orden tiene valores cargados.', 'info')
	--RETURN
END IF
BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_blo CURSOR FOR
		SELECT * FROM talt023
			WHERE ROWID = vm_rows[vm_row_current]
	      	FOR UPDATE
	OPEN q_blo
	FETCH q_blo INTO rm_orden.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	LET int_flag = 0
	CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
	IF resp <> 'Yes' THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		RETURN
	END IF
	SELECT COUNT(*)	INTO cuantos
		FROM ordt010
		WHERE c10_compania    = vg_codcia
		  AND c10_localidad   = vg_codloc
		  AND c10_ord_trabajo = rm_orden.t23_orden
		  AND c10_estado      = 'C'
	IF cuantos > 0 THEN
		LET int_flag = 0
		CALL fl_hacer_pregunta('Desea generar una nueva OT para reutilizarla junto con las Ordenes de Compra ?.', 'No')
			RETURNING vm_elim_ot
		IF vm_elim_ot <> 'Yes' THEN
			LET int_flag = 0
		END IF
	ELSE
		LET vm_elim_ot = 'No'
	END IF
	IF vm_elim_ot = 'Yes' THEN
		IF NOT obtener_num_orden_trabajo_nueva() THEN
			ROLLBACK WORK
			WHENEVER ERROR STOP
			RETURN
		END IF
	END IF
	IF NOT generar_transferencias_retorno() THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		RETURN
	END IF
	CALL control_anular_ordenes_de_compras() RETURNING anulo_oc
	UPDATE talt023
		SET t23_estado     = 'E',
		    t23_fec_elimin = CURRENT,
		    t23_usu_elimin = vg_usuario
		WHERE CURRENT OF q_blo
	WHENEVER ERROR STOP	
COMMIT WORK
IF vm_elim_ot = 'Yes' THEN
	BEGIN WORK
		CALL actualiza_ot_x_oc(vm_nue_orden)
	COMMIT WORK
END IF
IF anulo_oc THEN
	CALL eliminar_diarios_contables_recep_reten_oc_anuladas()
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()
CALL fl_mostrar_mensaje('Orden de Trabajo ha sido ELIMINADA.', 'info')

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_t04		RECORD LIKE talt004.*

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
{--
-- PUESTO POR NPC HASTA ARREGLAR EL MODELO 
INITIALIZE r_t04.* TO NULL
DECLARE q_mod CURSOR FOR SELECT * FROM talt004 WHERE t04_compania = vg_codcia
OPEN q_mod
FETCH q_mod INTO r_t04.*
--
--LET rm_orden.t23_modelo	    = 'SERVICIOS'
LET rm_orden.t23_modelo	    = r_t04.t04_modelo
--}
DISPLAY BY NAME rm_orden.t23_fecing, rm_orden.t23_usuario, rm_orden.t23_estado

CALL ingresa_datos()
IF NOT int_flag THEN
	INSERT INTO talt023 VALUES (rm_orden.*)
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
DEFINE linea		LIKE talt004.t04_linea
DEFINE r_t04		RECORD LIKE talt004.*
DEFINE run_prog		CHAR(10)
DEFINE r_t20		RECORD LIKE talt020.*

 
OPTIONS INPUT WRAP
LET int_flag = 0
LET por_mo_tal		    = 0
LET por_rp_alm		    = 0
LET rc3.z03_dcto_item_c     = 0 
LET rc3.z03_dcto_item_r     = 0
LET rc3.z03_dcto_mano_c     = 0
LET rc3.z03_dcto_mano_r     = 0
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF


INPUT BY NAME rm_orden.t23_orden, rm_orden.t23_cod_cliente,
	rm_orden.t23_nom_cliente, rm_orden.t23_tipo_ot, rm_orden.t23_subtipo_ot,
	rm_orden.t23_descripcion, rm_orden.t23_seccion, rm_orden.t23_cod_asesor,
	rm_orden.t23_cod_mecani, rm_orden.t23_numpre, rm_orden.t23_valor_tope,
	rm_orden.t23_moneda, rm_orden.t23_tel_cliente, rm_orden.t23_modelo,
	rm_orden.t23_cont_cred, rm_orden.t23_porc_impto, rm_orden.t23_fecini,
	rm_orden.t23_fecfin, rm_orden.t23_fec_cierre, rm_orden.t23_por_mo_tal,
	rm_orden.t23_por_rp_tal, rm_orden.t23_por_rp_alm,
	rm_orden.t23_val_otros1, rm_orden.t23_val_otros2
	WITHOUT DEFAULTS                                          
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_orden.t23_orden,
			rm_orden.t23_cod_cliente, rm_orden.t23_nom_cliente,
			rm_orden.t23_tipo_ot, rm_orden.t23_subtipo_ot,
			rm_orden.t23_descripcion, rm_orden.t23_seccion,
			rm_orden.t23_cod_asesor, rm_orden.t23_cod_mecani,
			rm_orden.t23_numpre, rm_orden.t23_valor_tope,
			rm_orden.t23_moneda, rm_orden.t23_tel_cliente,
			rm_orden.t23_modelo, rm_orden.t23_cont_cred,
			rm_orden.t23_porc_impto, rm_orden.t23_fecini,
			rm_orden.t23_fecfin, rm_orden.t23_fec_cierre,
			rm_orden.t23_por_mo_tal, rm_orden.t23_por_rp_tal,
			rm_orden.t23_por_rp_alm, rm_orden.t23_val_otros1,
			rm_orden.t23_val_otros2)
		THEN
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
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
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
		IF INFIELD(t23_modelo) THEN
{--
			CALL fl_ayuda_chasis_cliente(vg_codcia, 'T') RETURNING modelo, chasis, placa, color, cod_cliente, nom_cliente
			IF chasis IS NOT NULL THEN
				--LET rm_orden.t23_chasis = chasis
				--LET rm_orden.t23_placa  = placa
				--LET rm_orden.t23_color  = color
				LET rm_orden.t23_modelo = modelo
				LET rm_orden.t23_cod_cliente = cod_cliente
				LET rm_orden.t23_nom_cliente = nom_cliente
				DISPLAY BY NAME rm_orden.t23_modelo
				DISPLAY BY NAME rm_orden.t23_cod_cliente
				DISPLAY BY NAME rm_orden.t23_nom_cliente
				--DISPLAY BY NAME rm_orden.t23_chasis 
				--DISPLAY BY NAME rm_orden.t23_placa
				--DISPLAY BY NAME rm_orden.t23_color
			END IF
--}
			CALL fl_ayuda_tipos_vehiculos(vg_codcia)
				RETURNING modelo, linea
			IF modelo IS NOT NULL THEN
				LET rm_orden.t23_modelo = modelo
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
			CALL fl_lee_cliente_general(rm_orden.t23_cod_cliente)
				RETURNING r1.*
				IF r1.z01_paga_impto = 'N' THEN
					LET rm_orden.t23_porc_impto = 0
				ELSE
					LET rm_orden.t23_porc_impto = impto
				END IF
				DISPLAY BY NAME rm_orden.t23_porc_impto
			END IF
		END IF
	ON KEY(F5)
		IF INFIELD (t23_cod_cliente) THEN
			LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp101 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
			RUN comando
		END IF

	ON KEY(F6)
		IF INFIELD (t23_modelo) THEN
			LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, run_prog, 'talp200 ', vg_base, ' ', 'TA', vg_codcia
			RUN comando
		END IF

	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD t23_numpre
		IF rm_orden.t23_numpre IS NOT NULL THEN
			CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc, 
				rm_orden.t23_numpre)
				RETURNING r_t20.*
			IF r_t20.t20_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Presupuesto no existe.','exclamation')
				NEXT FIELD t23_numpre
			END IF
		END IF
	BEFORE FIELD t23_orden
		LET orden = rm_orden.t23_orden
	AFTER FIELD t23_orden 
		IF vm_flag_mant = 'M' THEN
			LET rm_orden.t23_orden = orden
			DISPLAY BY NAME rm_orden.t23_orden
		END IF
		IF rm_orden.t23_orden IS NULL THEN
			NEXT FIELD t23_orden
  		ELSE	
		LET f_orden = rm_orden.t23_orden
		DISPLAY rm_orden.t23_orden TO f_orden
		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_orden.t23_orden) RETURNING r23.*
		IF r23.t23_orden IS NOT NULL AND r23.t23_orden = rm_orden.t23_orden AND vm_flag_mant = 'I'  THEN
       			--CALL fgl_winmessage(vg_producto,'Orden ya existe, consultela si desea mantenimiento o digite nuevo número para ingreso.','exclamation')
			CALL fl_mostrar_mensaje('Orden ya existe, consultela si desea mantenimiento o digite nuevo número para ingreso.','exclamation')
			INITIALIZE rm_orden.t23_orden TO NULL
			DISPLAY rm_orden.t23_orden TO f_orden
			NEXT FIELD t23_orden
		END IF
		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_orden.t23_orden) RETURNING r23.*
		CALL fl_lee_configuracion_facturacion() RETURNING r0.*
			IF r0.g00_porc_impto IS NULL THEN
       				--CALL fgl_winmessage(vg_producto,'No existen impuestos definidos en el sistema.','exclamation')
				CALL fl_mostrar_mensaje('No existen impuestos definidos en el sistema.','exclamation')
				NEXT FIELD t23_orden
       			END IF   
			CALL calcular_impto()
			LET rm_orden.t23_moneda     = r0.g00_moneda_base
			LET rm_orden.t23_precision  = r0.g00_decimal_mb
			DISPLAY BY NAME rm_orden.t23_moneda 
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
       					--CALL fgl_winmessage(vg_producto,'No existen Módulos definidos en el sistema.','exclamation')
					CALL fl_mostrar_mensaje('No existen Módulos definidos en el sistema.','exclamation')
					NEXT FIELD t23_orden
				ELSE
					LET modulo = r50.g50_modulo
				END IF
		END IF
	BEFORE FIELD t23_cod_cliente
		LET codcli_ant = rm_orden.t23_cod_cliente

	AFTER FIELD t23_cod_cliente 
		IF rm_orden.t23_cod_cliente IS NOT NULL THEN
		CALL fl_lee_cliente_general(rm_orden.t23_cod_cliente)
			RETURNING r1.*
		IF r1.z01_codcli IS NOT NULL THEN
			LET rm_orden.t23_cod_cliente = r1.z01_codcli
			LET rm_orden.t23_nom_cliente = r1.z01_nomcli
			LET rm_orden.t23_dir_cliente = r1.z01_direccion1
			LET rm_orden.t23_tel_cliente = r1.z01_telefono1
			LET rm_orden.t23_cedruc      = r1.z01_num_doc_id
			IF rm_orden.t23_cod_cliente = rm_r00.r00_codcli_tal
			THEN
				CALL fl_lee_cliente_general(rm_r00.r00_codcli_tal)
					RETURNING r_z01.*  
				LET rm_orden.t23_cedruc = r_z01.z01_num_doc_id
			END IF
			DISPLAY BY NAME rm_orden.t23_cod_cliente,
					rm_orden.t23_nom_cliente,
					rm_orden.t23_tel_cliente
			CALL fl_lee_cliente_areaneg(vg_codcia, vg_codloc, 
				r50.g50_areaneg_def, rm_orden.t23_cod_cliente) 
				RETURNING rc3.*
			IF rc3.z03_areaneg IS NULL THEN
				CALL fl_lee_cliente_localidad(vg_codcia, 
					vg_codloc, rm_orden.t23_cod_cliente)
					RETURNING rc2.*
					IF rc2.z02_codcli IS NULL THEN
       						--CALL fgl_winmessage(vg_producto,'Cliente no habilitado para la Compañía/Localidad.','exclamation')
						CALL fl_mostrar_mensaje('Cliente no habilitado para la Compañía/Localidad.','exclamation')
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
       				--CALL fgl_winmessage(vg_producto,'Cliente no habilitado para el Area de Negocios.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no habilitado para el Area de Negocios.','exclamation')
				INITIALIZE rm_orden.t23_cod_cliente TO NULL
				INITIALIZE rm_orden.t23_nom_cliente TO NULL
				CLEAR t23_cod_cliente
				CLEAR t23_nom_cliente
				NEXT FIELD t23_nom_cliente
			END IF
		END IF			

		IF r1.z01_paga_impto IS NULL THEN
			NEXT FIELD t23_nom_cliente
		ELSE
		IF r1.z01_paga_impto = 'N' THEN
			LET rm_orden.t23_porc_impto = 0
			LET rm_orden.t23_moneda     = r0.g00_moneda_base
			LET rm_orden.t23_precision  = r0.g00_decimal_mb
			DISPLAY BY NAME rm_orden.t23_porc_impto, rm_orden.t23_moneda 
        	END IF
		IF r1.z01_paga_impto = 'S' THEN
			CALL fl_lee_configuracion_facturacion() RETURNING r0.*
			IF r0.g00_porc_impto IS NULL THEN
              			CALL fgl_winmessage(vg_producto,'No existen impuestos definidos en el sistema.','exclamation')
				CALL fl_mostrar_mensaje('No existen impuestos definidos en el sistema.','exclamation')
				NEXT FIELD t23_orden
        		END IF   
			LET rm_orden.t23_porc_impto = r0.g00_porc_impto
			LET rm_orden.t23_moneda     = r0.g00_moneda_base
			LET rm_orden.t23_precision  = r0.g00_decimal_mb
			DISPLAY BY NAME rm_orden.t23_porc_impto, rm_orden.t23_moneda 
			END IF
		END IF
		END IF
		CALL calcular_impto()
			
	AFTER FIELD t23_tipo_ot
		IF rm_orden.t23_tipo_ot IS NULL THEN
			NEXT FIELD t23_tipo_ot
  		ELSE	
			CALL fl_lee_tipo_orden_taller(vg_codcia, rm_orden.t23_tipo_ot) RETURNING r5.* 
			IF r5.t05_tipord IS NULL THEN
       				--CALL fgl_winmessage(vg_producto,'No existe Tipo de Orden.','exclamation')
				CALL fl_mostrar_mensaje('No existe Tipo de Orden.','exclamation')
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
		CALL calcular_impto()

	AFTER FIELD t23_subtipo_ot
		IF rm_orden.t23_subtipo_ot IS NULL THEN
			NEXT FIELD t23_subtipo_ot
  		ELSE	
		CALL fl_lee_subtipo_orden_taller(vg_codcia, rm_orden.t23_tipo_ot, rm_orden.t23_subtipo_ot) RETURNING r6.* 
		IF r6.t06_subtipo IS NULL THEN
       			--CALL fgl_winmessage(vg_producto,'No existe Subtipo de Orden.','exclamation')
			CALL fl_mostrar_mensaje('No existe Subtipo de Orden.','exclamation')
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
       			--CALL fgl_winmessage(vg_producto,'No existe Sección.','exclamation')
			CALL fl_mostrar_mensaje('No existe Sección.','exclamation')
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
       			--CALL fgl_winmessage(vg_producto,'No existe Asesor.','exclamation')
			CALL fl_mostrar_mensaje('No existe Asesor.','exclamation')
			NEXT FIELD t23_cod_asesor
		ELSE
			IF  r3.t03_tipo = 'A' THEN
				LET rm_orden.t23_cod_asesor = r3.t03_mecanico
				LET desc_cod_asesor         = r3.t03_nombres
				DISPLAY BY NAME rm_orden.t23_cod_asesor, desc_cod_asesor
			ELSE
       			--CALL fgl_winmessage(vg_producto,'No existe Asesor.','exclamation')
			CALL fl_mostrar_mensaje('No existe Asesor.','exclamation')
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
       			--CALL fgl_winmessage(vg_producto,'No existe Tecnico.','exclamation')
			CALL fl_mostrar_mensaje('No existe Tecnico.','exclamation')
			NEXT FIELD t23_cod_mecani
		ELSE
			IF  r3.t03_tipo = 'M' THEN
				LET rm_orden.t23_cod_mecani = r3.t03_mecanico
				LET desc_cod_mecani         = r3.t03_nombres
				DISPLAY BY NAME rm_orden.t23_cod_mecani, desc_cod_mecani
			ELSE
       			--CALL fgl_winmessage(vg_producto,'No existe Tecnico.','exclamation')
			CALL fl_mostrar_mensaje('No existe Tecnico.','exclamation')
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
              				--CALL fgl_winmessage(vg_producto,'No existen Factor de Coversion entre monedas.','exclamation')
					CALL fl_mostrar_mensaje('No existen Factor de Coversion entre monedas.','exclamation')
					NEXT FIELD t23_moneda
				END IF
				LET rm_orden.t23_paridad = r14.g14_tasa
				DISPLAY BY NAME rm_orden.t23_paridad		
			END IF

	AFTER FIELD t23_modelo
		IF rm_orden.t23_modelo IS NOT NULL THEN
			CALL fl_lee_tipo_vehiculo(vg_codcia,rm_orden.t23_modelo)
				RETURNING r_t04.*
			IF r_t04.t04_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe ese modelo registrado en la compañía.','exclamation')
				NEXT FIELD t23_modelo
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
		IF rm_orden.t23_modelo IS NULL THEN
			CALL fl_mostrar_mensaje('Digite modelo.', 'exclamation')
			NEXT FIELD t23_modelo
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
       						--CALL fgl_winmessage(vg_producto,'Cliente no habilitado para la Compañía/Localidad.','exclamation')
						CALL fl_mostrar_mensaje('Cliente no habilitado para la Compañía/Localidad.','exclamation')
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
       				--CALL fgl_winmessage(vg_producto,'Cliente no habilitado para el Area de Negocios.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no habilitado para el Area de Negocios.','exclamation')
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
	CALL calcular_impto()
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



FUNCTION calcular_impto()
DEFINE r_g00		RECORD LIKE gent000.*
DEFINE r_z01		RECORD LIKE cxct001.*

CALL fl_lee_configuracion_facturacion() RETURNING r_g00.*
IF rm_orden.t23_cod_cliente IS NOT NULL THEN
	CALL fl_lee_cliente_general(rm_orden.t23_cod_cliente) RETURNING r_z01.*
	IF r_z01.z01_paga_impto = 'N' THEN
		LET r_g00.g00_porc_impto = 0
	END IF
END IF
LET rm_orden.t23_porc_impto = r_g00.g00_porc_impto
LET rm_orden.t23_val_impto  = (rm_orden.t23_tot_bruto - rm_orden.t23_tot_dscto)
				* rm_orden.t23_porc_impto / 100
CALL fl_retorna_precision_valor(rm_orden.t23_moneda, rm_orden.t23_val_impto)
	RETURNING rm_orden.t23_val_impto
IF r_z01.z01_paga_impto = 'N' THEN
	LET rm_orden.t23_val_impto = 0
END IF
DISPLAY BY NAME rm_orden.t23_porc_impto, rm_orden.t23_val_impto

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
				ELSE
					CLEAR fec_anula
				END IF
			END IF
		END IF
	END IF
END IF
CALL fl_lee_tipo_orden_taller(vg_codcia, rm_orden.t23_tipo_ot) RETURNING r5.*
IF r5.t05_tipord IS NOT NULL THEN
	IF rm_orden.t23_tipo_ot = r5.t05_tipord THEN
		DISPLAY r5.t05_nombre TO desc_tipo_ot
	END IF
END IF
CALL fl_lee_subtipo_orden_taller(vg_codcia, rm_orden.t23_tipo_ot,
				rm_orden.t23_subtipo_ot)
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
DISPLAY BY NAME rm_orden.t23_orden        THRU rm_orden.t23_tel_cliente,
		rm_orden.t23_valor_tope   THRU rm_orden.t23_cod_mecani,
		rm_orden.t23_moneda,           rm_orden.t23_paridad,
		rm_orden.t23_tel_cliente, rm_orden.t23_modelo,
		rm_orden.t23_fec_factura,
  		rm_orden.t23_fecini       THRU rm_orden.t23_porc_impto,
		rm_orden.t23_val_mo_tal   THRU rm_orden.t23_val_rp_alm,
		rm_orden.t23_por_mo_tal   THRU rm_orden.t23_fec_factura,
		rm_orden.t23_usuario, rm_orden.t23_fecing, rm_orden.t23_numpre
{
--
rm_orden.t23_orden,     rm_orden.t23_cod_cliente,rm_orden.t23_nom_cliente,
rm_orden.t23_tipo_ot,   rm_orden.t23_subtipo_ot, rm_orden.t23_descripcion,
rm_orden.t23_seccion,   rm_orden.t23_cod_asesor, rm_orden.t23_cod_mecani,
rm_orden.t23_numpre,    rm_orden.t23_valor_tope, rm_orden.t23_moneda,
rm_orden.t23_fec_cierre,rm_orden.t23_tel_cliente,
rm_orden.t23_fecini,     rm_orden.t23_fecfin,
rm_orden.t23_cont_cred, rm_orden.t23_porc_impto,
rm_orden.t23_por_mo_tal,
rm_orden.t23_por_rp_tal,
rm_orden.t23_por_rp_alm,
rm_orden.t23_val_otros1,
rm_orden.t23_val_otros2
--
}	
	DISPLAY rm_orden.t23_orden TO f_orden
IF rm_orden.t23_orden = 'F' OR rm_orden.t23_orden = 'D' THEN
	CALL muestra_datos_proforma_facturas('19')
ELSE
	CALL muestra_datos_proforma_facturas('21')
END IF

END FUNCTION



FUNCTION muestra_datos_proforma_facturas(pref)
DEFINE pref		CHAR(2)
DEFINE tit_subtotal_pr	DECIMAL(14,2)
DEFINE tit_impuesto_pr	DECIMAL(14,2)
DEFINE tit_neto_pr	DECIMAL(14,2)
DEFINE tit_neto_ot_pr	DECIMAL(14,2)
DEFINE query		CHAR(800)
DEFINE expr_ord		VARCHAR(100)

LET expr_ord = '   AND r', pref CLIPPED, '_num_ot    = ', rm_orden.t23_orden
IF rm_orden.t23_orden = 'F' OR rm_orden.t23_orden = 'D' THEN
	LET expr_ord = '   AND r19_ord_trabajo = ', rm_orden.t23_orden
END IF
LET query = 'SELECT NVL(SUM(r', pref CLIPPED, '_tot_bruto - r', pref CLIPPED,
		'_tot_dscto), 0) tot_sub, NVL(SUM(r', pref CLIPPED,
		'_tot_neto - r', pref CLIPPED, '_tot_bruto + r', pref CLIPPED,
		'_tot_dscto - ', 'r', pref CLIPPED, '_flete), 0) tot_imp ',
		' FROM rept0', pref CLIPPED,
		' WHERE r', pref CLIPPED, '_compania  = ',rm_orden.t23_compania,
		'   AND r', pref CLIPPED, '_localidad =',rm_orden.t23_localidad,
		expr_ord CLIPPED,
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
SELECT * INTO tit_subtotal_pr, tit_impuesto_pr FROM t1
DROP TABLE t1
LET tit_neto_pr    = tit_subtotal_pr + tit_impuesto_pr
LET tit_neto_ot_pr = tit_neto_pr     + rm_orden.t23_tot_neto
DISPLAY BY NAME tit_subtotal_pr, tit_impuesto_pr, tit_neto_pr, tit_neto_ot_pr

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
--DISPLAY vm_row_current, vm_num_rows TO vm_row_current2, vm_num_rows2
DISPLAY vm_row_current, vm_num_rows TO vm_row_current1, vm_num_rows1

END FUNCTION


 
FUNCTION control_mostrar_forma_pago(r_ord)
DEFINE r_ord		RECORD LIKE talt023.*
DEFINE r_fp		RECORD LIKE talt025.*
DEFINE r_mod		RECORD LIKE talt004.*
DEFINE r_lin		RECORD LIKE talt001.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE r_glin		RECORD LIKE gent020.*
DEFINE r_cp		RECORD LIKE cajt010.*
DEFINE r_dp		RECORD LIKE cajt011.*
DEFINE linea 		LIKE rept020.r20_linea
DEFINE i, l		SMALLINT
DEFINE num_ant		SMALLINT
DEFINE num_caj		SMALLINT
DEFINE num_cred		SMALLINT
DEFINE val_caja		DECIMAL(12,2)
DEFINE r_ant		ARRAY[100] OF RECORD
				t27_tipo	LIKE talt027.t27_tipo,
				t27_numero	LIKE talt027.t27_numero,
				t27_valor	LIKE talt027.t27_valor
			END RECORD
DEFINE r_caj		ARRAY[100] OF RECORD
				j11_codigo_pago	LIKE cajt011.j11_codigo_pago,
				nombre_bt	VARCHAR(20),
				j11_num_ch_aut	LIKE cajt011.j11_num_ch_aut,
				j11_moneda	LIKE cajt011.j11_moneda,
				j11_valor	LIKE cajt011.j11_valor
			END RECORD
DEFINE r_cred		ARRAY[100] OF RECORD
				t26_dividendo	LIKE talt026.t26_dividendo,
				t26_fec_vcto	LIKE talt026.t26_fec_vcto,
				t26_valor_cap	LIKE talt026.t26_valor_cap,
				t26_valor_int	LIKE talt026.t26_valor_int,
				tot_div		DECIMAL(12,2)
			END RECORD
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_lee_tipo_vehiculo(r_ord.t23_compania, r_ord.t23_modelo) 
	RETURNING r_mod.*
CALL fl_lee_linea_taller(r_ord.t23_compania, r_mod.t04_linea) 
	RETURNING r_lin.*
CALL fl_lee_grupo_linea(r_ord.t23_compania, r_lin.t01_grupo_linea)
	RETURNING r_glin.*
LET lin_menu = 0
LET row_ini  = 2
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_fp AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_tal_2 FROM "../forms/talf204_2"
ELSE
	OPEN FORM f_tal_2 FROM "../forms/talf204_2c"
END IF
DISPLAY FORM f_tal_2
DISPLAY BY NAME r_ord.t23_num_factura
--#DISPLAY 'TP.'		TO tit_ant1
--#DISPLAY 'Número'		TO tit_ant2
--#DISPLAY 'Valor'  		TO tit_ant3
--#DISPLAY 'TP.'                TO tit_caj1
--#DISPLAY 'Banco/Tarjeta'      TO tit_caj2 
--#DISPLAY 'No. Cheque/Tarjeta' TO tit_caj3
--#DISPLAY 'Mo.'                TO tit_caj4 
--#DISPLAY 'V a l o r'          TO tit_caj5
--#DISPLAY 'No.'                TO tit_cred1
--#DISPLAY 'Fec.Vcto.'          TO tit_cred2
--#DISPLAY 'Valor Capital'      TO tit_cred3
--#DISPLAY 'Valor Interés'      TO tit_cred4
--#DISPLAY 'Valor Total'        TO tit_cred5
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
	LET r_caj[num_caj].j11_codigo_pago = r_dp.j11_codigo_pago
	LET r_caj[num_caj].j11_num_ch_aut  = r_dp.j11_num_ch_aut
	LET r_caj[num_caj].j11_moneda	   = r_dp.j11_moneda
	LET r_caj[num_caj].j11_valor       = r_dp.j11_valor
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
--#LET vm_size_arr_ant = fgl_scr_size('r_ant')
IF vg_gui = 0 THEN
	LET vm_size_arr_ant = 3
END IF
FOR i = 1 TO vm_size_arr_ant
	IF i <= num_ant THEN
		DISPLAY r_ant[i].* TO r_ant[i].*
	END IF
END FOR	
--#LET vm_size_arr_caj = fgl_scr_size('r_caj')
IF vg_gui = 0 THEN
	LET vm_size_arr_caj = 3
END IF
FOR i = 1 TO vm_size_arr_caj
	IF i <= num_caj THEN
		DISPLAY r_caj[i].* TO r_caj[i].*
	END IF
END FOR	
--#LET vm_size_arr_cre = fgl_scr_size('r_cred')
IF vg_gui = 0 THEN
	LET vm_size_arr_cre = 3
END IF
FOR i = 1 TO vm_size_arr_cre
	IF i <= num_cred THEN
		DISPLAY r_cred[i].* TO r_cred[i].*
	END IF
END FOR	
CALL muestra_contadores_fp(0, num_ant, 0, num_caj, 0, num_cred)
LET l = 0
IF vg_gui = 0 THEN
	LET l = 1
END IF
MENU 'OPCIONES'
	BEFORE MENU
		IF num_ant = 0 THEN
			HIDE OPTION 'Anticipos'
		END IF
		IF num_caj = 0 THEN
			HIDE OPTION 'Caja'
		END IF
		IF num_cred = 0 THEN
			HIDE OPTION 'Crédito'
		END IF
	COMMAND 'Anticipos'
		IF num_ant = 0 THEN
			CONTINUE MENU
		END IF
		CALL muestra_contadores_fp(l, num_ant, 0, num_caj, 0, num_cred)
		CALL set_count(num_ant)
		DISPLAY ARRAY r_ant TO r_ant.*
			ON KEY(INTERRUPT)
				EXIT DISPLAY
       			ON KEY(F1,CONTROL-W)
				CALL control_visor_teclas_caracter_2() 
			ON KEY(RETURN)
				LET i = arr_curr()
				CALL muestra_contadores_fp(i, num_ant, 0,
							num_caj, 0, num_cred)
			ON KEY(F5)
				LET i = arr_curr()
				CALL ver_documento_fav(r_ant[i].*)
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#CALL muestra_contadores_fp(i, num_ant, 0,
							--#num_caj, 0, num_cred)
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("F5","Documento")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#AFTER DISPLAY
				--#CONTINUE DISPLAY
		END DISPLAY
		CALL muestra_contadores_fp(0, num_ant, 0, num_caj, 0, num_cred)
	COMMAND 'Caja'
		IF num_caj = 0 THEN
			CONTINUE MENU
		END IF
		CALL muestra_contadores_fp(0, num_ant, l, num_caj, 0, num_cred)
		CALL set_count(num_caj)
		DISPLAY ARRAY r_caj TO r_caj.*
			ON KEY(INTERRUPT)
				EXIT DISPLAY
		        ON KEY(F1,CONTROL-W)
				CALL llamar_visor_teclas()
			ON KEY(RETURN)
				LET i = arr_curr()
				CALL muestra_contadores_fp(0, num_ant, i,
							num_caj, 0, num_cred)
			ON KEY(F5)
				CALL ver_forma_pago()
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#CALL muestra_contadores_fp(0, num_ant, i,
							--#num_caj, 0, num_cred)
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("F5","Forma Pago")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#AFTER DISPLAY
				--#CONTINUE DISPLAY
		END DISPLAY
		CALL muestra_contadores_fp(0, num_ant, 0, num_caj, 0, num_cred)
	COMMAND 'Crédito'
		IF num_cred = 0 THEN
			CONTINUE MENU
		END IF
		CALL muestra_contadores_fp(0, num_ant, 0, num_caj, l, num_cred)
		CALL set_count(num_cred)
		DISPLAY ARRAY r_cred TO r_cred.*
			ON KEY(INTERRUPT)
				EXIT DISPLAY
		        ON KEY(F1,CONTROL-W)
				CALL llamar_visor_teclas()
			ON KEY(RETURN)
				LET i = arr_curr()
				CALL muestra_contadores_fp(0, num_ant, 0,
							num_caj, i, num_cred)
			ON KEY(F5)
				LET i = arr_curr()
				INITIALIZE r_z20.* TO NULL
				SELECT * INTO r_z20.*
					FROM cxct020
					WHERE z20_compania=rm_orden.t23_compania
					  AND z20_localidad=
							rm_orden.t23_localidad
					  AND z20_codcli=
							rm_orden.t23_cod_cliente
					  AND z20_tipo_doc = 'FA'
					  AND z20_areaneg  = 2
					  AND z20_num_tran =
							rm_orden.t23_num_factura
					  AND z20_dividendo=
							r_cred[i].t26_dividendo
				CALL ver_documento_deu(r_z20.*)
			ON KEY(F6)
				LET i = arr_curr()
				INITIALIZE r_z20.* TO NULL
				SELECT * INTO r_z20.*
					FROM cxct020
					WHERE z20_compania=rm_orden.t23_compania
					AND z20_localidad=rm_orden.t23_localidad
					 AND z20_codcli=rm_orden.t23_cod_cliente
					  AND z20_tipo_doc = 'FA'
					  AND z20_areaneg  = 2
					  AND z20_num_tran =
							rm_orden.t23_num_factura
					  AND z20_dividendo=
							r_cred[i].t26_dividendo
				CALL muestra_movimientos_documento_cxc(
					r_z20.z20_compania, r_z20.z20_localidad,
					r_z20.z20_codcli, r_z20.z20_tipo_doc,
					r_z20.z20_num_doc, r_z20.z20_dividendo,
					r_z20.z20_areaneg)
				LET int_flag = 0
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#CALL muestra_contadores_fp(0, num_ant, 0,
							--#num_caj, i, num_cred)
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("F5","Documento")
				--#CALL dialog.keysetlabel("F6","Movimientos")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#AFTER DISPLAY
				--#CONTINUE DISPLAY
		END DISPLAY
		CALL muestra_contadores_fp(0, num_ant, 0, num_caj, 0, num_cred)
	COMMAND 'Salir'
		EXIT MENU
END MENU
CLOSE WINDOW w_fp

END FUNCTION	



FUNCTION muestra_contadores_fp(num_ant, max_ant, num_caj, max_caj, num_cre,
				max_cre)
DEFINE num_ant, max_ant	SMALLINT
DEFINE num_caj, max_caj	SMALLINT
DEFINE num_cre, max_cre	SMALLINT

DISPLAY BY NAME num_ant, max_ant, num_caj, max_caj, num_cre, max_cre

END FUNCTION	



FUNCTION ver_forma_pago()
DEFINE run_prog		CHAR(10)
DEFINE comando		CHAR(400)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador,
		'fuentes', vg_separador, run_prog, 'cajp203 ', vg_base,
		' "CG" ', vg_codcia, ' ', vg_codloc, ' "OT" ',rm_orden.t23_orden
RUN comando

END FUNCTION



FUNCTION ver_documento_deu(r_z20)
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp200 ',
		vg_base, ' "CO" ', vg_codcia, ' ', vg_codloc, ' ',
		r_z20.z20_codcli, ' "', r_z20.z20_tipo_doc, '" ',
		r_z20.z20_num_doc, ' ', r_z20.z20_dividendo
RUN comando

END FUNCTION



FUNCTION ver_documento_fav(r_ant)
DEFINE r_ant		RECORD
				t27_tipo	LIKE talt027.t27_tipo,
				t27_numero	LIKE talt027.t27_numero,
				t27_valor	LIKE talt027.t27_valor
			END RECORD
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp201 ',
		vg_base, ' "CO" ', vg_codcia, ' ', vg_codloc, ' ',
		rm_orden.t23_cod_cliente, ' "', r_ant.t27_tipo, '" ',
		r_ant.t27_numero
RUN comando

END FUNCTION



FUNCTION muestra_profromas_ot(codcia, codloc, orden)
DEFINE codcia		LIKE talt023.t23_compania
DEFINE codloc		LIKE talt023.t23_localidad
DEFINE orden		LIKE talt023.t23_orden
DEFINE param		VARCHAR(100)

IF orden IS NULL THEN
	RETURN
END IF
LET param = orden, ' O'
CALL fl_ejecuta_comando('TALLER', vg_modulo, 'talp213', param, 1)

END FUNCTION



FUNCTION proceso_recalcula_valores()

IF vm_num_rows <= 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL fl_recalcula_valores_ot(vg_codcia, vg_codloc, rm_orden.t23_orden)
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION ver_orden_compra(numero_oc)
DEFINE numero_oc	LIKE ordt010.c10_numero_oc
DEFINE param		VARCHAR(100)

LET param = numero_oc
CALL fl_ejecuta_comando('COMPRAS', 'OC', 'ordp200', param, 1)

END FUNCTION



FUNCTION ver_presupuesto()
DEFINE param		VARCHAR(100)

IF rm_orden.t23_numpre IS NULL THEN
	CALL fl_mostrar_mensaje('No hay un presupuesto asociado a esta OT.','exclamation')
	RETURN
END IF
LET param = rm_orden.t23_numpre, ' X'
CALL fl_ejecuta_comando('TALLER', vg_modulo, 'talp201', param, 1)

END FUNCTION



FUNCTION ver_gastos_viaje()
DEFINE param		VARCHAR(100)

LET param = rm_orden.t23_orden
CALL fl_ejecuta_comando('TALLER', vg_modulo, 'talp212', param, 1)

END FUNCTION



FUNCTION imprimir()
DEFINE param		VARCHAR(100)

LET param = rm_orden.t23_orden
CALL fl_ejecuta_comando('TALLER', vg_modulo, 'talp412', param, 1)

END FUNCTION



FUNCTION imprimir_transferencia(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE param		VARCHAR(100)

LET param = '"', cod_tran, '" ', num_tran
CALL fl_ejecuta_comando('REPUESTOS', 'RE', 'repp415', param, 1)

END FUNCTION



FUNCTION muestra_movimientos_documento_cxc(codcia, codloc, codcli, tipo_doc,
						num_doc, dividendo, areaneg)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE max_rows, i, col	SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(400)
DEFINE r_aux		ARRAY[100] OF RECORD
				loc		LIKE gent002.g02_localidad,
				tipo		LIKE cxct023.z23_tipo_favor
			END RECORD
DEFINE r_pdoc		ARRAY[100] OF RECORD
				z23_tipo_trn	LIKE cxct023.z23_tipo_trn,
				z23_num_trn	LIKE cxct023.z23_num_trn,
				z22_fecha_emi	LIKE cxct022.z22_fecha_emi,
				z22_referencia	LIKE cxct022.z22_referencia,
				val_pago	DECIMAL(14,2)
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE expr_loc		VARCHAR(50)
DEFINE expr_fec		VARCHAR(100)
DEFINE fecha1, fecha2	LIKE cxct022.z22_fecing

LET max_rows  = 100
LET num_rows2 = 16
LET num_cols  = 76
IF vg_gui = 0 THEN
	LET num_rows2 = 15
	LET num_cols  = 77
END IF
OPEN WINDOW w_mdoc AT 06, 03 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF dividendo > 0 THEN
	OPEN FORM f_movdoc FROM "../../COBRANZAS/forms/cxcf314_5"
ELSE
	OPEN FORM f_movdoc FROM "../../COBRANZAS/forms/cxcf314_6"
END IF
DISPLAY FORM f_movdoc
--#DISPLAY 'TP'                  TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'Fecha Pago'          TO tit_col3
--#DISPLAY 'R e f e r e n c i a' TO tit_col4 
--#DISPLAY 'V a l o r'           TO tit_col5
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli, 'exclamation')
	CLOSE WINDOW w_mdoc
	RETURN
END IF
DISPLAY BY NAME r_cli.z01_codcli, r_cli.z01_nomcli
IF dividendo <> 0 THEN
	CLEAR z23_tipo_doc, z23_num_doc, z23_div_doc
	DISPLAY tipo_doc, num_doc, dividendo
	     TO z23_tipo_doc, z23_num_doc, z23_div_doc
ELSE
	CLEAR z23_tipo_favor, z23_doc_favor
	DISPLAY tipo_doc, num_doc TO z23_tipo_favor, z23_doc_favor
END IF
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 1
LET expr_loc   = ' '
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND z23_localidad = ', codloc
END IF
LET fecha2   = EXTEND(TODAY, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr_fec = '   AND z22_fecing    <= "', fecha2, '"'
LET expr_sql = '   AND z23_tipo_doc   = ? ',
		'   AND z23_num_doc    = ? ',
		'   AND z23_div_doc    = ? '
IF dividendo = 0 THEN
	LET expr_sql = '   AND z23_tipo_favor = ? ',
			'   AND z23_doc_favor  = ? '
END IF
WHILE TRUE
	LET query = 'SELECT z23_tipo_trn, z23_num_trn, z22_fecha_emi, ',
			'   z22_referencia, z23_valor_cap + z23_valor_int, ',
			'   z23_localidad, z23_tipo_favor ',
	        	' FROM cxct023, cxct022 ',
			' WHERE z23_compania   = ? ', 
			expr_loc CLIPPED,
		        '   AND z23_codcli     = ? ',
			expr_sql CLIPPED,
			'   AND z22_compania   = z23_compania ',
			'   AND z22_localidad  = z23_localidad ',
			'   AND z22_codcli     = z23_codcli ',
			'   AND z22_tipo_trn   = z23_tipo_trn  ',
			'   AND z22_num_trn    = z23_num_trn ',
			expr_fec CLIPPED,
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE dpgc FROM query
	DECLARE q_dpgc CURSOR FOR dpgc
	LET i        = 1
	LET tot_pago = 0
	IF dividendo <> 0 THEN
		OPEN q_dpgc USING codcia, codcli, tipo_doc, num_doc, dividendo
	ELSE
		OPEN q_dpgc USING codcia, codcli, tipo_doc, num_doc
	END IF
	WHILE TRUE
		FETCH q_dpgc INTO r_pdoc[i].*, r_aux[i].*
		IF STATUS = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_pago = tot_pago + r_pdoc[i].val_pago 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dpgc
	FREE q_dpgc
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Documento no tiene movimientos.','exclamation')
		CLOSE WINDOW w_mdoc
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_pago
	DISPLAY ARRAY r_pdoc TO r_pdoc.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_muestra_forma_pago_caja(codcia, r_aux[i].loc,
							areaneg, codcli,
							r_pdoc[i].z23_tipo_trn,
							r_pdoc[i].z23_num_trn) 
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento_tran(codcli, r_pdoc[i].z23_tipo_trn,
					r_pdoc[i].z23_num_trn, r_aux[i].*)
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_det(i, num_rows)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> columna_1 THEN
		LET columna_2          = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1          = col 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_mdoc

END FUNCTION



FUNCTION mostrar_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION ver_documento_tran(codcli, tipo_trn, num_trn, loc, tipo)
DEFINE codcli		LIKE cxct022.z22_codcli
DEFINE tipo_trn		LIKE cxct022.z22_tipo_trn
DEFINE num_trn		LIKE cxct022.z22_num_trn
DEFINE loc		LIKE cxct022.z22_localidad
DEFINE tipo		LIKE cxct023.z23_tipo_favor
DEFINE prog		CHAR(10)
DEFINE param		VARCHAR(100)

LET prog = 'cxcp202 '
IF tipo IS NOT NULL THEN
	LET prog = 'cxcp203 '
END IF
LET param = codcli, ' ', tipo_trn, ' ', num_trn
CALL fl_ejecuta_comando('COBRANZAS', 'CO', prog, param, 1)

END FUNCTION



FUNCTION obtener_num_orden_trabajo_nueva()
DEFINE r_t24		RECORD LIKE talt024.*
DEFINE resul		SMALLINT
DEFINE mensaje		VARCHAR(100)

LET resul = 0
INITIALIZE rm_t23.* TO NULL
LET rm_t23.* = rm_orden.*
SELECT NVL(MAX(t23_orden), 0) + 1
	INTO vm_nue_orden
	FROM talt023
	WHERE t23_compania  = vg_codcia
	  AND t23_localidad = vg_codloc
LET rm_t23.t23_estado      = 'A'
LET rm_t23.t23_fec_cierre  = NULL
LET rm_t23.t23_num_factura = NULL
LET rm_t23.t23_fec_factura = NULL
LET rm_t23.t23_orden       = vm_nue_orden
LET rm_t23.t23_fecing      = CURRENT
LET rm_t23.t23_usuario     = vg_usuario
WHENEVER ERROR CONTINUE
INSERT INTO talt023 VALUES(rm_t23.*)
IF STATUS < 0 THEN
	CALL fl_mostrar_mensaje('Ha ocurrido un error al intenrar grabar la nueva OT. Por favor llame al administrador.', 'exclamation')
	RETURN resul
END IF
LET mensaje = 'La nueva OT es: ', vm_nue_orden USING "<<<<<&", '.'
CALL fl_mostrar_mensaje(mensaje, 'info')
DECLARE q_mano CURSOR FOR
	SELECT * FROM talt024
	WHERE t24_compania  = vg_codcia
	  AND t24_localidad = vg_codloc
	  AND t24_orden     = rm_orden.t23_orden
FOREACH q_mano INTO r_t24.*
	LET r_t24.t24_orden   = vm_nue_orden
	LET r_t24.t24_fecing  = CURRENT
	LET r_t24.t24_usuario = vg_usuario
	INSERT INTO talt024 VALUES (r_t24.*)
	IF STATUS < 0 THEN
		CALL fl_mostrar_mensaje('Ha ocurrido un error al intenrar grabar la MO de la nueva OT. Por favor llame al administrador.', 'exclamation')
		EXIT FOREACH
	END IF
	LET resul = 1
END FOREACH
IF resul THEN
	UPDATE ordt010
		SET c10_ord_trabajo = vm_nue_orden
		WHERE c10_compania    = vg_codcia
		  AND c10_localidad   = vg_codloc
		  AND c10_ord_trabajo = rm_orden.t23_orden
	IF STATUS < 0 THEN
		CALL fl_mostrar_mensaje('Ha ocurrido un error al intenrar actualizar las OC con la nueva OT. Por favor llame al administrador.', 'exclamation')
		LET resul = 0
	END IF
END IF
RETURN resul

END FUNCTION



FUNCTION generar_transferencias_retorno()
DEFINE r_transf		RECORD LIKE rept019.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE bodega		LIKE rept011.r11_bodega
DEFINE i		LIKE rept020.r20_orden
DEFINE item		LIKE rept011.r11_item
DEFINE cantidad		LIKE rept011.r11_stock_act
DEFINE cuantos		INTEGER
DEFINE mensaje 		VARCHAR(200)
DEFINE resul, resul2	SMALLINT

LET cod_tran = 'TR'
SELECT * FROM rept019 d
	WHERE d.r19_compania    = vg_codcia
	  AND d.r19_localidad   = vg_codloc
	  AND d.r19_cod_tran    = cod_tran
	  AND d.r19_ord_trabajo = rm_orden.t23_orden
	  AND EXISTS
		(SELECT * FROM rept020 a
			WHERE a.r20_compania  = d.r19_compania
			  AND a.r20_localidad = d.r19_localidad
			  AND a.r20_cod_tran  = d.r19_cod_tran
			  AND a.r20_num_tran  = d.r19_num_tran
			  AND a.r20_item     NOT IN
				(SELECT c.r20_item
					FROM rept019 b, rept020 c
					WHERE b.r19_compania  = a.r20_compania
					  AND b.r19_localidad = a.r20_localidad
					  AND b.r19_cod_tran  IN ("FA", "DF",
									"AF")
				        AND b.r19_ord_trabajo =d.r19_ord_trabajo
					  AND c.r20_compania  = b.r19_compania
					  AND c.r20_localidad = b.r19_localidad
					  AND c.r20_cod_tran  = b.r19_cod_tran
					  AND c.r20_num_tran  = b.r19_num_tran))
	INTO TEMP t_r19
SELECT COUNT(*) INTO cuantos FROM t_r19
IF cuantos = 0 THEN
	DROP TABLE t_r19
	LET mensaje = 'No hay material que retornar en OT: ',
			rm_orden.t23_orden USING "<<<<<<&"
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
	RETURN 1
END IF
LET vm_cuantos = 0
IF NOT generar_tr_ajuste_para_stock_act() THEN
	DROP TABLE t_r19
	RETURN 0
END IF
DECLARE qu_transf CURSOR FOR SELECT * FROM t_r19 ORDER BY r19_num_tran
LET resul = 1
FOREACH qu_transf INTO r_transf.*
	INITIALIZE r_r19.*, r_r20.* TO NULL
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE', 'AA',
						cod_tran)
		RETURNING num_tran
	IF num_tran <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_r19.r19_compania   = vg_codcia
    	LET r_r19.r19_localidad  = vg_codloc
    	LET r_r19.r19_cod_tran   = cod_tran
    	LET r_r19.r19_num_tran   = num_tran
    	LET r_r19.r19_cont_cred  = 'C'
    	LET r_r19.r19_referencia = 'OT: ', rm_orden.t23_orden USING '<<<<<&',
				' ', r_transf.r19_cod_tran CLIPPED, '-',
				r_transf.r19_num_tran USING '<<<<<&',
				'. POR ELIMINACION DE OT'
    	LET r_r19.r19_codcli 	= rm_orden.t23_cod_cliente
    	LET r_r19.r19_nomcli 	= rm_orden.t23_nom_cliente
    	LET r_r19.r19_dircli 	= rm_orden.t23_dir_cliente
    	LET r_r19.r19_telcli 	= rm_orden.t23_tel_cliente
    	LET r_r19.r19_cedruc 	= rm_orden.t23_cedruc
	DECLARE qu_ven CURSOR FOR
		SELECT r01_codigo FROM rept001
			WHERE r01_compania   = vg_codcia
			  AND r01_estado     = 'A'
			  AND r01_user_owner = vg_usuario
	OPEN qu_ven
	FETCH qu_ven INTO r_r19.r19_vendedor
	CLOSE qu_ven
	FREE qu_ven
	IF r_r19.r19_vendedor IS NULL THEN
		CALL fl_mostrar_mensaje('El Usuario ' || vg_usuario CLIPPED || ' no tiene Código de Vendedor asignado. Por favor consulte con el ADMINISTRADOR.', 'stop')
		LET resul = 0
		EXIT FOREACH
	END IF
    	LET r_r19.r19_ord_trabajo = rm_orden.t23_orden
    	LET r_r19.r19_descuento   = 0
    	LET r_r19.r19_porc_impto  = 0
    	LET r_r19.r19_tipo_dev    = r_transf.r19_cod_tran
    	LET r_r19.r19_num_dev     = r_transf.r19_num_tran
    	LET r_r19.r19_bodega_ori  = r_transf.r19_bodega_dest
    	LET r_r19.r19_bodega_dest = r_transf.r19_bodega_ori
    	LET r_r19.r19_moneda 	  = rm_orden.t23_moneda
	LET r_r19.r19_paridad     = rg_gen.g00_decimal_mb
    	LET r_r19.r19_precision   = rm_orden.t23_precision
    	LET r_r19.r19_tot_costo   = 0
    	LET r_r19.r19_tot_bruto   = 0
    	LET r_r19.r19_tot_dscto   = 0
    	LET r_r19.r19_tot_neto 	  = 0
    	LET r_r19.r19_flete 	  = 0
    	LET r_r19.r19_usuario 	  = vg_usuario
    	LET r_r19.r19_fecing 	  = CURRENT
	INSERT INTO rept019 VALUES (r_r19.*)
	DECLARE qu_dettr CURSOR FOR
		SELECT r20_item, r20_cant_ven, r20_orden
			FROM rept020
			WHERE r20_compania  = r_transf.r19_compania
			  AND r20_localidad = r_transf.r19_localidad
			  AND r20_cod_tran  = r_transf.r19_cod_tran
			  AND r20_num_tran  = r_transf.r19_num_tran
			ORDER BY r20_orden
	LET i = 0
	FOREACH qu_dettr INTO item, cantidad, i
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF
		LET mensaje = 'ITEM: ', item
 		IF r_r11.r11_stock_act <= 0 THEN
			LET mensaje = mensaje CLIPPED,
				' no tiene stock y se nesecita: ',
				cantidad USING '####&', '. No puede eliminar ',
				'esta Orden de Trabajo.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			LET resul = 0
			EXIT FOREACH
		END IF
 		IF r_r11.r11_stock_act < cantidad THEN
			LET mensaje = mensaje CLIPPED, ' solo tiene stock: ',
				r_r11.r11_stock_act USING '####&', 
				' y se nesecita: ', cantidad USING '####&',
				'. No puede eliminar esta Orden de Trabajo.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			LET resul = 0
			EXIT FOREACH
		END IF
    		LET r_r20.r20_compania 	 = r_r19.r19_compania
    		LET r_r20.r20_localidad	 = r_r19.r19_localidad
    		LET r_r20.r20_cod_tran 	 = r_r19.r19_cod_tran
    		LET r_r20.r20_num_tran 	 = r_r19.r19_num_tran
    		LET r_r20.r20_bodega 	 = r_r19.r19_bodega_ori
    		LET r_r20.r20_item 	 = item
    		LET r_r20.r20_orden 	 = i
    		LET r_r20.r20_cant_ped 	 = cantidad
    		LET r_r20.r20_cant_ven   = cantidad
    		LET r_r20.r20_cant_dev 	 = 0
    		LET r_r20.r20_cant_ent   = 0
    		LET r_r20.r20_descuento  = 0
    		LET r_r20.r20_val_descto = 0
		CALL fl_lee_item(r_r19.r19_compania, item) RETURNING r_r10.*
    		LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
    		LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
    		LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
    		LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
		IF r_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
			LET r_r10.r10_precio_mb = r_r10.r10_precio_ma
			LET r_r10.r10_costo_mb  = r_r10.r10_costo_ma
		END IF	
    		LET r_r20.r20_precio 	 = r_r10.r10_precio_mb
    		LET r_r20.r20_val_impto  = 0
    		LET r_r20.r20_costo 	 = r_r10.r10_costo_mb
    		LET r_r20.r20_fob 	 = r_r10.r10_fob
    		LET r_r20.r20_linea 	 = r_r10.r10_linea
    		LET r_r20.r20_rotacion 	 = r_r10.r10_rotacion
    		LET r_r20.r20_ubicacion  = '.'
    		LET r_r20.r20_stock_ant  = r_r11.r11_stock_act
		UPDATE rept011
			SET r11_stock_act = r11_stock_act - cantidad,
		            r11_egr_dia   = r11_egr_dia   + cantidad
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_ori
			  AND r11_item     = item 
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
    			LET r_r11.r11_stock_act = 0
			INSERT INTO rept011
				(r11_compania, r11_bodega, r11_item,
				 r11_ubicacion, r11_stock_ant, r11_stock_act,
				 r11_ing_dia, r11_egr_dia)
				VALUES(vg_codcia, r_r19.r19_bodega_dest,
					item, 'SN', 0, 0, 0, 0) 
		END IF
    		LET r_r20.r20_stock_bd   = r_r11.r11_stock_act
    		LET r_r20.r20_fecing     = CURRENT
		INSERT INTO rept020 VALUES (r_r20.*)
		UPDATE rept011
			SET r11_stock_act = r11_stock_act + cantidad,
			    r11_ing_dia   = r11_ing_dia   + cantidad
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_dest
			  AND r11_item     = item
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
					(cantidad * r_r20.r20_costo)
	END FOREACH
	IF NOT resul THEN
		EXIT FOREACH
	END IF
	IF i = 0 OR i IS NULL THEN
		DELETE FROM rept019
			WHERE r19_compania  = r_r19.r19_compania
			  AND r19_localidad = r_r19.r19_localidad
			  AND r19_cod_tran  = r_r19.r19_cod_tran
			  AND r19_num_tran  = r_r19.r19_num_tran
	ELSE
		UPDATE rept019
			SET r19_tot_costo = r_r19.r19_tot_costo,
			    r19_tot_bruto = r_r19.r19_tot_costo,
			    r19_tot_neto  = r_r19.r19_tot_costo
			WHERE r19_compania  = r_r19.r19_compania
			  AND r19_localidad = r_r19.r19_localidad
			  AND r19_cod_tran  = r_r19.r19_cod_tran
			  AND r19_num_tran  = r_r19.r19_num_tran 
		LET mensaje = 'Se genero la transferencia: ',
				r_r19.r19_num_tran USING "<<<<<<&", '.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
		CALL imprimir_transferencia(r_r19.r19_cod_tran,
						r_r19.r19_num_tran)
	END IF
END FOREACH
DROP TABLE t_r19
IF vm_cuantos > 0 THEN
	CALL transaccion_aj('A-') RETURNING resul2
	DROP TABLE tmp_aj
END IF
RETURN resul

END FUNCTION



FUNCTION generar_tr_ajuste_para_stock_act()
DEFINE r_transf		RECORD
				cia		LIKE rept019.r19_compania,
				loc		LIKE rept019.r19_localidad,
				tp		LIKE rept019.r19_cod_tran,
				num		LIKE rept019.r19_num_tran,
				bd_o		LIKE rept019.r19_bodega_ori,
				bd_d		LIKE rept019.r19_bodega_dest
			END RECORD
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE i		LIKE rept020.r20_orden
DEFINE item		LIKE rept011.r11_item
DEFINE cantidad		LIKE rept011.r11_stock_act
DEFINE cuantos		INTEGER
DEFINE resul		SMALLINT
DEFINE mensaje 		VARCHAR(200)

SELECT r20_item item_t2, NVL(SUM(r20_cant_ven), 0) tot_item
	FROM t_r19, rept020
	WHERE r20_compania  = r19_compania
	  AND r20_localidad = r19_localidad
	  AND r20_cod_tran  = r19_cod_tran
	  AND r20_num_tran  = r19_num_tran
	GROUP BY 1
	INTO TEMP tmp_ite
SELECT r19_compania cia, r19_localidad loc, r19_cod_tran tp, r19_num_tran num_t,
	r19_bodega_ori bd_o, r19_bodega_dest bd_d, r20_item item_t,
	r20_orden orden_t, r20_cant_ven cant_tr
	FROM t_r19, rept020, tmp_ite
	WHERE r20_compania  = r19_compania
	  AND r20_localidad = r19_localidad
	  AND r20_cod_tran  = r19_cod_tran
	  AND r20_num_tran  = r19_num_tran
	  AND item_t2       = r20_item
	  AND tot_item      > (NVL((SELECT r11_stock_act
					FROM rept011
					WHERE r11_compania = r19_compania
					  AND r11_bodega   = r19_bodega_dest
					  AND r11_item     = r20_item), 0))
	INTO TEMP tmp_tr
DROP TABLE tmp_ite
SELECT COUNT(*) INTO cuantos FROM tmp_tr
IF cuantos = 0 THEN
	DROP TABLE tmp_tr
	RETURN 1
END IF
SELECT cia cia2, loc loc2, tp tp2, num_t num2, bd_o, bd_d, item_t item2,
	orden_t ord2,
	(cant_tr - NVL((SELECT r11_stock_act
			FROM rept011
			WHERE r11_compania = cia
			  AND r11_bodega   = bd_o
			  AND r11_item     = item_t), 0)) cant_aj
	FROM tmp_tr
	WHERE cant_tr > (NVL((SELECT r11_stock_act
			FROM rept011
			WHERE r11_compania = cia
			  AND r11_bodega   = bd_o
			  AND r11_item     = item_t), 0))
	INTO TEMP tmp_aj
SELECT COUNT(*) INTO vm_cuantos FROM tmp_aj
IF vm_cuantos = 0 THEN
	DROP TABLE tmp_aj
ELSE
	UPDATE tmp_tr
		SET cant_tr = cant_tr - (NVL((SELECT cant_aj
						FROM tmp_aj
						WHERE cia2  = cia
						  AND loc2  = loc
						  AND tp2   = tp
						  AND num2  = num_t
						  AND item2 = item_t
						  AND ord2  = orden_t), 0))
		WHERE EXISTS (SELECT * FROM tmp_aj
				WHERE cia2 = cia
				  AND loc2 = loc
				  AND tp2  = tp
				  AND num2 = num_t)
	DELETE FROM tmp_tr WHERE (cant_tr <= 0 OR cant_tr IS NULL)
	CALL transaccion_aj('A+') RETURNING resul
END IF
LET cod_tran = 'TR'
DECLARE qu_transf2 CURSOR FOR
	SELECT UNIQUE cia, loc, tp, num_t, bd_o, bd_d
		FROM tmp_tr
		ORDER BY num_t
LET resul = 1
FOREACH qu_transf2 INTO r_transf.*
	INITIALIZE r_r19.*, r_r20.* TO NULL
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE', 'AA',
						cod_tran)
		RETURNING num_tran
	IF num_tran <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_r19.r19_compania   = vg_codcia
    	LET r_r19.r19_localidad  = vg_codloc
    	LET r_r19.r19_cod_tran   = cod_tran
    	LET r_r19.r19_num_tran   = num_tran
    	LET r_r19.r19_cont_cred  = 'C'
    	LET r_r19.r19_referencia = 'OT: ', rm_orden.t23_orden USING '<<<<<&',
				' ', r_transf.tp CLIPPED, '-',
				r_transf.num USING '<<<<<&',
				'. POR TRASPASO EN OT'
    	LET r_r19.r19_codcli 	= rm_orden.t23_cod_cliente
    	LET r_r19.r19_nomcli 	= rm_orden.t23_nom_cliente
    	LET r_r19.r19_dircli 	= rm_orden.t23_dir_cliente
    	LET r_r19.r19_telcli 	= rm_orden.t23_tel_cliente
    	LET r_r19.r19_cedruc 	= rm_orden.t23_cedruc
	DECLARE qu_ven2 CURSOR FOR
		SELECT r01_codigo
			FROM rept001
			WHERE r01_compania   = vg_codcia
			  AND r01_estado     = 'A'
			  AND r01_user_owner = vg_usuario
	OPEN qu_ven2
	FETCH qu_ven2 INTO r_r19.r19_vendedor
	CLOSE qu_ven2
	FREE qu_ven2
	IF r_r19.r19_vendedor IS NULL THEN
		CALL fl_mostrar_mensaje('El Usuario ' || vg_usuario CLIPPED || ' no tiene Código de Vendedor asignado. Por favor consulte con el ADMINISTRADOR.', 'stop')
		LET resul = 0
		EXIT FOREACH
	END IF
    	LET r_r19.r19_ord_trabajo = rm_orden.t23_orden
    	LET r_r19.r19_descuento   = 0
    	LET r_r19.r19_porc_impto  = 0
    	LET r_r19.r19_tipo_dev    = r_transf.tp
    	LET r_r19.r19_num_dev     = r_transf.num
    	LET r_r19.r19_bodega_ori  = r_transf.bd_o
    	LET r_r19.r19_bodega_dest = r_transf.bd_d
    	LET r_r19.r19_moneda 	  = rm_orden.t23_moneda
	LET r_r19.r19_paridad     = rg_gen.g00_decimal_mb
    	LET r_r19.r19_precision   = rm_orden.t23_precision
    	LET r_r19.r19_tot_costo   = 0
    	LET r_r19.r19_tot_bruto   = 0
    	LET r_r19.r19_tot_dscto   = 0
    	LET r_r19.r19_tot_neto 	  = 0
    	LET r_r19.r19_flete 	  = 0
    	LET r_r19.r19_usuario 	  = vg_usuario
    	LET r_r19.r19_fecing 	  = CURRENT
	INSERT INTO rept019 VALUES (r_r19.*)
	DECLARE qu_dettr2 CURSOR FOR
		SELECT item_t, cant_tr, orden_t
			FROM tmp_tr
			WHERE cia   = r_transf.cia
			  AND loc   = r_transf.loc
			  AND tp    = r_transf.tp
			  AND num_t = r_transf.num
			ORDER BY orden_t
	LET i = 0
	FOREACH qu_dettr2 INTO item, cantidad, i
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF
		LET mensaje = 'ITEM: ', item
 		IF r_r11.r11_stock_act <= 0 THEN
			LET mensaje = mensaje CLIPPED,
				' no tiene stock y se nesecita: ',
				cantidad USING '####&', '. No puede traspasar ',
				'a esta Orden de Trabajo.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			LET resul = 0
			EXIT FOREACH
		END IF
 		IF r_r11.r11_stock_act < cantidad THEN
			LET mensaje = mensaje CLIPPED, ' solo tiene stock: ',
				r_r11.r11_stock_act USING '####&', 
				' y se nesecita: ', cantidad USING '####&',
				'. No puede traspasar a esta Orden de Trabajo.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			LET resul = 0
			EXIT FOREACH
		END IF
    		LET r_r20.r20_compania 	 = r_r19.r19_compania
    		LET r_r20.r20_localidad	 = r_r19.r19_localidad
    		LET r_r20.r20_cod_tran 	 = r_r19.r19_cod_tran
    		LET r_r20.r20_num_tran 	 = r_r19.r19_num_tran
    		LET r_r20.r20_bodega 	 = r_r19.r19_bodega_ori
    		LET r_r20.r20_item 	 = item
    		LET r_r20.r20_orden 	 = i
    		LET r_r20.r20_cant_ped 	 = cantidad
    		LET r_r20.r20_cant_ven   = cantidad
    		LET r_r20.r20_cant_dev 	 = 0
    		LET r_r20.r20_cant_ent   = 0
    		LET r_r20.r20_descuento  = 0
    		LET r_r20.r20_val_descto = 0
		CALL fl_lee_item(r_r19.r19_compania, item) RETURNING r_r10.*
    		LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
    		LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
    		LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
    		LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
		IF r_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
			LET r_r10.r10_precio_mb = r_r10.r10_precio_ma
			LET r_r10.r10_costo_mb  = r_r10.r10_costo_ma
		END IF	
    		LET r_r20.r20_precio 	 = r_r10.r10_precio_mb
    		LET r_r20.r20_val_impto  = 0
    		LET r_r20.r20_costo 	 = r_r10.r10_costo_mb
    		LET r_r20.r20_fob 	 = r_r10.r10_fob
    		LET r_r20.r20_linea 	 = r_r10.r10_linea
    		LET r_r20.r20_rotacion 	 = r_r10.r10_rotacion
    		LET r_r20.r20_ubicacion  = '.'
    		LET r_r20.r20_stock_ant  = r_r11.r11_stock_act
		UPDATE rept011
			SET r11_stock_act = r11_stock_act - cantidad,
		            r11_egr_dia   = r11_egr_dia   + cantidad
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_ori
			  AND r11_item     = item 
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
    			LET r_r11.r11_stock_act = 0
			INSERT INTO rept011
				(r11_compania, r11_bodega, r11_item,
				 r11_ubicacion, r11_stock_ant, r11_stock_act,
				 r11_ing_dia, r11_egr_dia)
				VALUES(vg_codcia, r_r19.r19_bodega_dest,
					item, 'SN', 0, 0, 0, 0) 
		END IF
    		LET r_r20.r20_stock_bd   = r_r11.r11_stock_act
    		LET r_r20.r20_fecing     = CURRENT
		INSERT INTO rept020 VALUES (r_r20.*)
		UPDATE rept011
			SET r11_stock_act = r11_stock_act + cantidad,
			    r11_ing_dia   = r11_ing_dia   + cantidad
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_dest
			  AND r11_item     = item
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
					(cantidad * r_r20.r20_costo)
	END FOREACH
	IF NOT resul THEN
		EXIT FOREACH
	END IF
	IF i = 0 OR i IS NULL THEN
		DELETE FROM rept019
			WHERE r19_compania  = r_r19.r19_compania
			  AND r19_localidad = r_r19.r19_localidad
			  AND r19_cod_tran  = r_r19.r19_cod_tran
			  AND r19_num_tran  = r_r19.r19_num_tran
	ELSE
		UPDATE rept019
			SET r19_tot_costo = r_r19.r19_tot_costo,
			    r19_tot_bruto = r_r19.r19_tot_costo,
			    r19_tot_neto  = r_r19.r19_tot_costo
			WHERE r19_compania  = r_r19.r19_compania
			  AND r19_localidad = r_r19.r19_localidad
			  AND r19_cod_tran  = r_r19.r19_cod_tran
			  AND r19_num_tran  = r_r19.r19_num_tran 
		LET mensaje = 'Se genero la transferencia de traspaso',
				': ', r_r19.r19_num_tran USING "<<<<<<&", '.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
		CALL imprimir_transferencia(r_r19.r19_cod_tran,
						r_r19.r19_num_tran)
	END IF
END FOREACH
DROP TABLE tmp_tr
RETURN resul

END FUNCTION



FUNCTION transaccion_aj(cod_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE r_transf		RECORD
				cia		LIKE rept019.r19_compania,
				loc		LIKE rept019.r19_localidad,
				tp		LIKE rept019.r19_cod_tran,
				num		LIKE rept019.r19_num_tran,
				bd_o		LIKE rept019.r19_bodega_ori,
				bd_d		LIKE rept019.r19_bodega_dest
			END RECORD
DEFINE query		CHAR(300)
DEFINE resul		SMALLINT

IF cod_tran = 'A+' THEN
	LET query = 'SELECT UNIQUE cia2, loc2, tp2, num2, bd_o, bd_d ',
			' FROM tmp_aj ',
			' ORDER BY num2 '
ELSE
	LET query = 'SELECT UNIQUE cia2, loc2, tp2, num2, bd_d, bd_o ',
			' FROM tmp_aj ',
			' ORDER BY num2 '
END IF
PREPARE cons_aj FROM query
DECLARE qu_ajuste CURSOR FOR cons_aj
LET resul = 1
FOREACH qu_ajuste INTO r_transf.*
	IF NOT generar_ajuste(r_transf.*, cod_tran) THEN
		LET resul = 0
		EXIT FOREACH
	END IF
END FOREACH
RETURN resul

END FUNCTION



FUNCTION generar_ajuste(r_transf, cod_tran)
DEFINE r_transf		RECORD
				cia		LIKE rept019.r19_compania,
				loc		LIKE rept019.r19_localidad,
				tp		LIKE rept019.r19_cod_tran,
				num		LIKE rept019.r19_num_tran,
				bd_o		LIKE rept019.r19_bodega_ori,
				bd_d		LIKE rept019.r19_bodega_dest
			END RECORD
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_aju		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE i		LIKE rept020.r20_orden
DEFINE item		LIKE rept011.r11_item
DEFINE cantidad		LIKE rept011.r11_stock_act
DEFINE mensaje 		VARCHAR(200)

INITIALIZE r_r19.*, r_r20.*, r_aju.* TO NULL
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE', 'AA', cod_tran)
	RETURNING num_tran
IF num_tran <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_r19.r19_compania   = vg_codcia
LET r_r19.r19_localidad  = vg_codloc
LET r_r19.r19_cod_tran   = cod_tran
LET r_r19.r19_num_tran   = num_tran
LET r_r19.r19_cont_cred  = 'C'
LET r_r19.r19_referencia = 'OT: ', rm_orden.t23_orden USING '<<<<<&',
				' ', r_transf.tp CLIPPED, ' ',
				r_transf.num USING '<<<<<&',
				'. POR TRASPASO EN OT'
IF cod_tran = 'A-' THEN
	SELECT r19_cod_tran, r19_num_tran
		INTO r_aju.r19_cod_tran, r_aju.r19_num_tran
		FROM rept019
		WHERE r19_compania    = vg_codcia
		  AND r19_localidad   = vg_codloc
		  AND r19_cod_tran    = 'A+'
		  AND r19_tipo_dev    = r_transf.tp
		  AND r19_num_dev     = r_transf.num
		  AND r19_ord_trabajo = rm_orden.t23_orden
	LET r_r19.r19_referencia = 'OT: ', rm_orden.t23_orden USING '<<<<<&',
				' ', r_aju.r19_cod_tran CLIPPED, ' ',
				r_aju.r19_num_tran USING '<<<<<&',
				'. POR TRASPASO EN OT'
END IF
LET r_r19.r19_codcli 	= rm_orden.t23_cod_cliente
LET r_r19.r19_nomcli 	= rm_orden.t23_nom_cliente
LET r_r19.r19_dircli 	= rm_orden.t23_dir_cliente
LET r_r19.r19_telcli 	= rm_orden.t23_tel_cliente
LET r_r19.r19_cedruc 	= rm_orden.t23_cedruc
DECLARE qu_ven3 CURSOR FOR
	SELECT r01_codigo
		FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_estado     = 'A'
		  AND r01_user_owner = vg_usuario
OPEN qu_ven3
FETCH qu_ven3 INTO r_r19.r19_vendedor
CLOSE qu_ven3
FREE qu_ven3
IF r_r19.r19_vendedor IS NULL THEN
	CALL fl_mostrar_mensaje('El Usuario ' || vg_usuario CLIPPED || ' no tiene Código de Vendedor asignado. Por favor consulte con el ADMINISTRADOR.', 'stop')
	RETURN 0
END IF
LET r_r19.r19_ord_trabajo = rm_orden.t23_orden
LET r_r19.r19_descuento   = 0
LET r_r19.r19_porc_impto  = 0
LET r_r19.r19_bodega_ori  = r_transf.bd_d
LET r_r19.r19_bodega_dest = r_transf.bd_d
LET r_r19.r19_tipo_dev    = r_transf.tp
LET r_r19.r19_num_dev     = r_transf.num
LET r_r19.r19_moneda 	  = rm_orden.t23_moneda
LET r_r19.r19_paridad     = rg_gen.g00_decimal_mb
LET r_r19.r19_precision   = rm_orden.t23_precision
LET r_r19.r19_tot_costo   = 0
LET r_r19.r19_tot_bruto   = 0
LET r_r19.r19_tot_dscto   = 0
LET r_r19.r19_tot_neto 	  = 0
LET r_r19.r19_flete 	  = 0
LET r_r19.r19_usuario 	  = vg_usuario
LET r_r19.r19_fecing 	  = CURRENT
INSERT INTO rept019 VALUES (r_r19.*)
DECLARE qu_dettr3 CURSOR FOR
	SELECT item2, cant_aj, ord2
		FROM tmp_aj
		WHERE cia2  = r_transf.cia
		  AND loc2  = r_transf.loc
		  AND tp2   = r_transf.tp
		  AND num2  = r_transf.num
		ORDER BY ord2
LET i = 0
FOREACH qu_dettr3 INTO item, cantidad, i
	CALL fl_lee_stock_rep(vg_codcia, r_transf.bd_d, item) RETURNING r_r11.*
	IF r_r11.r11_compania IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
    	LET r_r20.r20_compania 	 = r_r19.r19_compania
    	LET r_r20.r20_localidad	 = r_r19.r19_localidad
    	LET r_r20.r20_cod_tran 	 = r_r19.r19_cod_tran
    	LET r_r20.r20_num_tran 	 = r_r19.r19_num_tran
    	LET r_r20.r20_bodega 	 = r_transf.bd_d
    	LET r_r20.r20_item 	 = item
    	LET r_r20.r20_orden 	 = i
    	LET r_r20.r20_cant_ped 	 = cantidad
    	LET r_r20.r20_cant_ven   = cantidad
	LET r_r20.r20_cant_dev 	 = 0
	LET r_r20.r20_cant_ent   = 0
	LET r_r20.r20_descuento  = 0
	LET r_r20.r20_val_descto = 0
	CALL fl_lee_item(r_r19.r19_compania, item) RETURNING r_r10.*
    	LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
    	LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
    	LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
    	LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
	IF r_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
		LET r_r10.r10_precio_mb = r_r10.r10_precio_ma
		LET r_r10.r10_costo_mb  = r_r10.r10_costo_ma
	END IF	
    	LET r_r20.r20_precio 	 = r_r10.r10_precio_mb
    	LET r_r20.r20_val_impto  = 0
    	LET r_r20.r20_costo 	 = r_r10.r10_costo_mb
    	LET r_r20.r20_fob 	 = r_r10.r10_fob
    	LET r_r20.r20_linea 	 = r_r10.r10_linea
    	LET r_r20.r20_rotacion 	 = r_r10.r10_rotacion
    	LET r_r20.r20_ubicacion  = '.'
    	LET r_r20.r20_stock_ant  = r_r11.r11_stock_act
	IF r_r20.r20_stock_ant IS NULL THEN
		LET r_r20.r20_stock_ant = 0
	END IF
	CALL fl_lee_stock_rep(vg_codcia, r_transf.bd_d, item) RETURNING r_r11.*
	IF r_r11.r11_compania IS NULL THEN
    		LET r_r11.r11_stock_act = 0
		IF cod_tran = 'A+' THEN
			INSERT INTO rept011
				(r11_compania, r11_bodega, r11_item,
				 r11_ubicacion, r11_stock_ant, r11_stock_act,
				 r11_ing_dia, r11_egr_dia)
				VALUES(vg_codcia, r_r19.r19_bodega_dest,
					item, 'SN', 0, cantidad, cantidad, 0)
		ELSE
			INSERT INTO rept011
				(r11_compania, r11_bodega, r11_item,
				 r11_ubicacion, r11_stock_ant, r11_stock_act,
				 r11_ing_dia, r11_egr_dia)
				VALUES(vg_codcia, r_r19.r19_bodega_dest,
					item, 'SN', 0, cantidad, 0, cantidad)
		END IF
	ELSE
		IF cod_tran = 'A+' THEN
			UPDATE rept011
				SET r11_stock_act = r11_stock_act + cantidad,
				    r11_ing_dia   = r11_ing_dia   + cantidad
				WHERE r11_compania = vg_codcia
				  AND r11_bodega   = r_transf.bd_d
				  AND r11_item     = item
		ELSE
			CALL fl_lee_stock_rep(vg_codcia, r_transf.bd_d, item)
				RETURNING r_r11.*
			IF r_r11.r11_compania IS NULL THEN
				LET r_r11.r11_stock_act = 0
			END IF
			LET mensaje = 'ITEM: ', item
			IF r_r11.r11_stock_act <= 0 THEN
				LET mensaje = mensaje CLIPPED,
				' no tiene stock y se nesecita: ',
				cantidad USING '####&', '. No puede ajustar ',
				'para esta Orden de Trabajo.'
				CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
				RETURN 0
			END IF
			IF r_r11.r11_stock_act < cantidad THEN
				LET mensaje = mensaje CLIPPED, ' solo tiene stock: ',
				r_r11.r11_stock_act USING '####&', 
				' y se nesecita: ', cantidad USING '####&',
				'. No puede ajustar para esta Orden de Trabajo.'
				CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
				RETURN 0
			END IF
			UPDATE rept011
				SET r11_stock_act = r11_stock_act - cantidad,
				    r11_egr_dia   = r11_egr_dia   + cantidad
				WHERE r11_compania = vg_codcia
				  AND r11_bodega   = r_transf.bd_d
				  AND r11_item     = item
		END IF
	END IF
	LET r_r20.r20_stock_bd   = r_r11.r11_stock_act
	LET r_r20.r20_fecing     = CURRENT
	INSERT INTO rept020 VALUES (r_r20.*)
	LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
				(cantidad * r_r20.r20_costo)
END FOREACH
IF i = 0 OR i IS NULL THEN
	DELETE FROM rept019
		WHERE r19_compania  = r_r19.r19_compania
		  AND r19_localidad = r_r19.r19_localidad
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran
ELSE
	UPDATE rept019
		SET r19_tot_costo = r_r19.r19_tot_costo,
		    r19_tot_bruto = r_r19.r19_tot_costo,
		    r19_tot_neto  = r_r19.r19_tot_costo
		WHERE r19_compania  = r_r19.r19_compania
		  AND r19_localidad = r_r19.r19_localidad
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran 
	LET mensaje = 'Se genero el ajuste para traspaso: ',
			r_r19.r19_cod_tran, ' ',
			r_r19.r19_num_tran USING "<<<<<<&", '.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
END IF
RETURN 1

END FUNCTION



FUNCTION control_anular_ordenes_de_compras()
DEFINE r_c00		RECORD LIKE ordt000.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE resp		CHAR(6)
DEFINE anulo_rp		SMALLINT
DEFINE mensaje		VARCHAR(200)
DEFINE cur_row		SMALLINT
DEFINE i_row, i_col	SMALLINT
DEFINE n_row, n_col	SMALLINT
DEFINE salir, dias	SMALLINT
DEFINE pago, tot_neto	DECIMAL(14,2)

LET anulo_rp = 0
INITIALIZE r_c10.* TO NULL
DECLARE q_c10 CURSOR FOR
	SELECT * FROM ordt010
		WHERE c10_compania    = vg_codcia
		  AND c10_localidad   = vg_codloc
		  AND c10_ord_trabajo = rm_orden.t23_orden
		  AND c10_estado      = 'C'
		ORDER BY c10_numero_oc
OPEN q_c10
FETCH q_c10 INTO r_c10.*
IF r_c10.c10_compania IS NULL THEN
	CLOSE q_c10
	FREE q_c10
	RETURN anulo_rp
END IF
CALL fl_lee_compania_orden_compra(vg_codcia) RETURNING r_c00.*
LET num_row_oc = 0
LET tot_neto   = 0
FOREACH q_c10 INTO r_c10.*
	IF vm_elim_ot = 'Yes' THEN
		CONTINUE FOREACH
	END IF
	LET dias = TODAY - r_c10.c10_fecha_fact
	IF (r_c00.c00_react_mes = 'S' AND
	   (YEAR(TODAY) <> YEAR(r_c10.c10_fecha_fact) OR
	    MONTH(TODAY) <> MONTH(r_c10.c10_fecha_fact))) OR
	   (r_c00.c00_react_mes = 'N' AND dias > r_c00.c00_dias_react)
	THEN
		CONTINUE FOREACH
	END IF
	SELECT NVL(SUM((p20_valor_cap + p20_valor_int) -
		(p20_saldo_cap + p20_saldo_int)), 0)
		INTO pago
		FROM ordt013, cxpt020
		WHERE c13_compania  = r_c10.c10_compania
		  AND c13_localidad = r_c10.c10_localidad
		  AND c13_numero_oc = r_c10.c10_numero_oc
		  AND c13_estado    = 'A'
		  AND p20_compania  = c13_compania
		  AND p20_localidad = c13_localidad
		  AND p20_codprov   = r_c10.c10_codprov
		  AND p20_num_doc   = c13_factura
		  AND p20_numero_oc = c13_numero_oc
	IF pago <> 0 THEN
		CONTINUE FOREACH
	END IF
	LET num_row_oc                   = num_row_oc + 1
	LET r_oc[num_row_oc].estado      = r_c10.c10_estado
	LET r_oc[num_row_oc].numero_oc   = r_c10.c10_numero_oc
	LET r_oc[num_row_oc].fecha       = DATE(r_c10.c10_fecing)
	LET r_oc[num_row_oc].descripcion = r_c10.c10_referencia
	LET r_oc[num_row_oc].total       = r_c10.c10_tot_compra
	LET r_oc[num_row_oc].marcar_ot   = 'S'
	LET tot_neto                     = tot_neto + r_c10.c10_tot_compra
	IF num_row_oc > max_row_oc THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pueden mostrar todas las Ordenes de Compra de esta Orden de Trabajo. Por favor llame al ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
END FOREACH
IF num_row_oc = 0 THEN
	RETURN anulo_rp
END IF
LET i_row = 04
LET n_row = 14
LET i_col = 07
LET n_col = 69
IF vg_gui = 0 THEN
	LET i_row = 05
	LET n_row = 14
	LET i_col = 06
	LET n_col = 70
END IF
OPEN WINDOW w_talf211_2 AT i_row, i_col WITH n_row ROWS, n_col COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_talf211_2 FROM "../forms/talf211_2"
ELSE
	OPEN FORM f_talf211_2 FROM "../forms/talf211_2c"
END IF
DISPLAY FORM f_talf211_2
MESSAGE "Seleccionando datos . . . espere por favor" ATTRIBUTE(NORMAL)
--#DISPLAY 'E'           TO tit_col1
--#DISPLAY 'O.C.'        TO tit_col2
--#DISPLAY 'Fecha'       TO tit_col3
--#DISPLAY 'Referencia'	 TO tit_col4
--#DISPLAY 'Total OC'    TO tit_col5
--#DISPLAY 'C'           TO tit_col6
DISPLAY rm_orden.t23_orden  TO num_ot
DISPLAY BY NAME tot_neto
OPTIONS INSERT KEY F30,
	DELETE KEY F31
LET salir = 0
WHILE NOT salir
	CALL set_count(num_row_oc)
	LET int_flag = 0
	INPUT ARRAY r_oc WITHOUT DEFAULTS FROM r_oc.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				CALL fl_mostrar_mensaje('Las Recepciones por Ordenes de Compra se anulan por el módulo de COMPRAS.', 'info')
	                	LET int_flag = 1
				LET salir    = 1
				EXIT INPUT
			END IF
		ON KEY(F1, CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET cur_row = arr_curr()
			CALL ver_orden_compra(r_oc[cur_row].numero_oc)
			LET int_flag = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("DELETE","")
		BEFORE ROW
			LET cur_row = arr_curr()
			DISPLAY BY NAME cur_row
			DISPLAY num_row_oc TO num_row
		BEFORE INSERT
			EXIT INPUT
		BEFORE DELETE
			EXIT INPUT
		AFTER INPUT
			LET salir = 1
	END INPUT
END WHILE
IF int_flag THEN
	CLOSE WINDOW w_talf211_2
	LET int_flag = 0
	RETURN anulo_rp
END IF
LET cur_row = 1
FOREACH q_c10 INTO r_c10.*
	IF r_oc[cur_row].numero_oc = r_c10.c10_numero_oc AND
	   r_oc[cur_row].marcar_ot = 'N'
	THEN
		CONTINUE FOREACH
	END IF
	LET mensaje = "Generando Anulación Recepción Orden de Compra ",
			r_c10.c10_numero_oc USING '<<<<<<<&',
			". Por favor espere ..."
	ERROR mensaje
	CALL control_anular_recepcion_orden_compra(r_c10.c10_numero_oc)
		RETURNING anulo_rp
	ERROR '                                                                            '
	LET cur_row = cur_row + 1
END FOREACH
CLOSE WINDOW w_talf211_2
LET int_flag = 0
RETURN anulo_rp

END FUNCTION



FUNCTION control_anular_recepcion_orden_compra(oc)
DEFINE oc 		LIKE ordt013.c13_numero_oc
DEFINE num_ret		LIKE cxpt028.p28_num_ret
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE anulo_rp, i	SMALLINT
DEFINE mensaje		VARCHAR(250)

LET vm_max_detalle  = 250
LET vm_nota_credito = 'NC'
INITIALIZE rm_c10.*, rm_c13.* TO NULL
WHENEVER ERROR CONTINUE
DECLARE q_ordt013 CURSOR FOR
        SELECT * FROM ordt013
               WHERE c13_compania  = vg_codcia
                 AND c13_localidad = vg_codloc
                 AND c13_numero_oc = oc
                 AND c13_estado    = 'A'
	FOR UPDATE
OPEN q_ordt013
FETCH q_ordt013 INTO rm_c13.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	LET mensaje = 'La recepción # ', rm_c13.c13_num_recep USING "<<<<&&",
			' por orden de compra # ',
			rm_c13.c13_numero_oc USING "<<<<<<<&",
			' esta bloqueada por otro usuario.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
IF rm_c13.c13_compania IS NULL THEN
	CLOSE q_ordt013
	FREE q_ordt013
	ROLLBACK WORK
	LET mensaje = 'La orden de compra # ',
			rm_c13.c13_numero_oc USING "<<<<<<<&",
		       ' no tiene ninguna recepción para que pueda ser anulada.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
LET anulo_rp = 0
FOREACH q_ordt013 INTO rm_c13.*
	DECLARE q_ordt014 CURSOR FOR
		SELECT c14_cantidad, c14_codigo, c14_descrip, c14_descuento,
			c14_precio
			FROM ordt014
			WHERE c14_compania  = rm_c13.c13_compania
			  AND c14_localidad = rm_c13.c13_localidad
			  AND c14_numero_oc = rm_c13.c13_numero_oc
			  AND c14_num_recep = rm_c13.c13_num_recep
	LET i = 1
	FOREACH q_ordt014 INTO r_detalle[i].*
		LET i = i + 1
		IF i > vm_max_detalle THEN
			CALL fl_mensaje_arreglo_incompleto()
			ROLLBACK WORK
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
	END FOREACH
	LET vm_ind_arr = i - 1
	IF vm_ind_arr = 0 THEN
		ROLLBACK WORK
		LET mensaje = 'La recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				' no tiene detalle.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
		WHENEVER ERROR STOP
		EXIT FOREACH
	END IF
	IF NOT validar_recep_oc() THEN
		EXIT FOREACH
	END IF
	WHENEVER ERROR CONTINUE 
	DECLARE q_ordt010 CURSOR FOR 
		SELECT * FROM ordt010
			WHERE c10_compania  = rm_c13.c13_compania
			  AND c10_localidad = rm_c13.c13_localidad
			  AND c10_numero_oc = rm_c13.c13_numero_oc
		FOR UPDATE
	OPEN q_ordt010 
	FETCH q_ordt010 INTO r_c10.*
	IF STATUS < 0 THEN
		ROLLBACK WORK 
		LET mensaje = 'La orden de compra # ',
				r_c10.c10_numero_oc USING "<<<<<<<&",
				' esta bloqueada por otro usuario.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	FOR i = 1 TO vm_ind_arr
		UPDATE ordt011
			SET c11_cant_rec = c11_cant_rec -
						r_detalle[i].c14_cantidad
			WHERE c11_compania  = r_c10.c10_compania
			  AND c11_localidad = r_c10.c10_localidad
			  AND c11_numero_oc = r_c10.c10_numero_oc
			  AND c11_codigo    = r_detalle[i].c14_codigo
		IF STATUS < 0 THEN
			ROLLBACK WORK 
			LET mensaje = 'No se pudo actualizar el detalle de la',
					' orden de compra # ',
					r_c10.c10_numero_oc USING "<<<<<<<&",
					'. Ha ocurrido un error de Base de ',
					'Datos, llame al ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
	END FOR 
	LET i = 0
	UPDATE ordt013 SET c13_estado    = 'E',
			   c13_fecha_eli = CURRENT
		WHERE c13_compania  = rm_c13.c13_compania
		  AND c13_localidad = rm_c13.c13_localidad
		  AND c13_numero_oc = rm_c13.c13_numero_oc
		  AND c13_num_recep = rm_c13.c13_num_recep
	IF STATUS < 0 THEN
		ROLLBACK WORK 
		LET mensaje = 'No se pudo eliminar la recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				'. Ha ocurrido un error de Base de ',
				'Datos, llame al ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	IF rm_c10.c10_tipo_pago = 'R' THEN
		LET valor_aplicado = control_rebaja_deuda()  
		IF valor_aplicado < 0 THEN
			ROLLBACK WORK
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
	END IF
	IF rm_c13.c13_tot_recep = rm_c10.c10_tot_compra THEN
		UPDATE ordt010 SET c10_estado = 'E' WHERE CURRENT OF q_ordt010
		IF STATUS < 0 THEN
			ROLLBACK WORK 
			LET mensaje = 'No se pudo actualizar el estado de la ',
					'orden de compra # ',
					r_c10.c10_numero_oc USING "<<<<<<<&",
					'. Ha ocurrido un error de Base de ',
					'Datos, llame al ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		UPDATE ordt010 SET c10_ord_trabajo = rm_orden.t23_orden
			WHERE CURRENT OF q_ordt010
		IF STATUS < 0 THEN
			ROLLBACK WORK 
			LET mensaje = 'No se pudo restaurar la OT anterior a ',
					'la orden de compra # ',
					r_c10.c10_numero_oc USING "<<<<<<<&",
					'. Ha ocurrido un error de Base de ',
					'Datos, llame al ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
	END IF		
	DECLARE q_cxpt028 CURSOR FOR 
		SELECT UNIQUE p28_num_ret
			FROM cxpt028
			WHERE p28_compania  = rm_c10.c10_compania
			  AND p28_localidad = rm_c10.c10_localidad
			  AND p28_codprov   = rm_c10.c10_codprov
			  AND p28_tipo_doc  = 'FA'
			  AND p28_num_doc   = rm_c13.c13_factura
	OPEN  q_cxpt028
	FETCH q_cxpt028 INTO num_ret
	CLOSE q_cxpt028
	FREE  q_cxpt028
	UPDATE cxpt027 SET p27_estado    = 'E',
			   p27_fecha_eli = CURRENT
		WHERE p27_compania  = rm_c10.c10_compania
		  AND p27_localidad = rm_c10.c10_localidad
		  AND p27_num_ret   = num_ret
	IF STATUS < 0 THEN
		ROLLBACK WORK 
		LET mensaje = 'No se pudo eliminar la retención de la ',
				'recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				'. Ha ocurrido un error de Base de ',
				'Datos, llame al ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	LET anulo_rp = 1
END FOREACH
RETURN anulo_rp

END FUNCTION



FUNCTION validar_recep_oc()
DEFINE r_p01	 	RECORD LIKE cxpt001.*
DEFINE r_c00	 	RECORD LIKE ordt000.*
DEFINE r_c01	 	RECORD LIKE ordt001.*
DEFINE r_t23	 	RECORD LIKE talt023.*
DEFINE dias		SMALLINT
DEFINE mensaje		VARCHAR(250)

CALL fl_lee_compania_orden_compra(vg_codcia) RETURNING r_c00.*
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc)
	RETURNING rm_c10.*
IF rm_c10.c10_numero_oc IS NULL THEN
	LET mensaje = 'No existe la orden de compra # ',
			rm_c13.c13_numero_oc USING "<<<<<<<&",
			' en la Compañía.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
IF rm_c10.c10_estado <> 'C' THEN
	LET mensaje = 'No se puede anular la recepción # ',
			rm_c13.c13_num_recep USING "<<<<&&",
			' por orden de compra # ',
			rm_c10.c10_numero_oc USING "<<<<<<<&",
			'. Tiene la OC estado = ', rm_c10.c10_estado, '.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
CALL fl_lee_proveedor(rm_c10.c10_codprov) RETURNING r_p01.*
IF r_p01.p01_codprov IS NULL THEN
	ROLLBACK WORK
	LET mensaje = 'No existe Proveedor ',
			rm_c10.c10_codprov USING "<<<<<<<&",
			' en la Compañía.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING r_c01.*
IF r_c01.c01_ing_bodega = 'S' AND r_c01.c01_modulo = 'RE' THEN
	LET mensaje = 'La orden de compra # ',
			rm_c10.c10_numero_oc USING "<<<<<<<&",
			' pertenece a Inventario y debe ser anulada por ',
			'Devolución de Compra Local.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF 
LET rm_c13.c13_interes = rm_c10.c10_interes
IF rm_c10.c10_ord_trabajo IS NOT NULL THEN
	CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_c10.c10_ord_trabajo)
		RETURNING r_t23.*
	IF r_t23.t23_estado <> 'A' THEN
		LET mensaje = 'La orden de trabajo # ',
				rm_c10.c10_ord_trabajo USING "<<<<<<<&",
				' asociada a la orden de compra # ',
				rm_c10.c10_numero_oc USING "<<<<<<<&",
				' tiene estado = ', r_t23.t23_estado, '.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
		RETURN 0
	END IF
END IF
LET dias = TODAY - rm_c10.c10_fecha_fact
IF (r_c00.c00_react_mes = 'S' AND (YEAR(TODAY) <> YEAR(rm_c10.c10_fecha_fact) OR
    MONTH(TODAY) <> MONTH(rm_c10.c10_fecha_fact))) OR
   (r_c00.c00_react_mes = 'N' AND dias > r_c00.c00_dias_react)
THEN
	LET mensaje = 'No se puede anular la recepción # ',
			rm_c13.c13_num_recep USING "<<<<&&",
			' por orden de compra # ',
			rm_c10.c10_numero_oc USING "<<<<<<<&",
			'. Revise la configuración de Compañías en el módulo',
			' de COMPRAS.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION control_rebaja_deuda()
DEFINE num_row		INTEGER
DEFINE i		SMALLINT
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE aplicado_cap	DECIMAL(14,2)
DEFINE aplicado_int	DECIMAL(14,2)
DEFINE valor_aplicar	DECIMAL(14,2)
DEFINE valor_favor	LIKE cxpt021.p21_valor
DEFINE tot_ret		DECIMAL(14,2)
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p21		RECORD LIKE cxpt021.*
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*

LET tot_ret = 0
SELECT p27_total_ret INTO tot_ret
	FROM cxpt027
	WHERE p27_compania  = rm_c13.c13_compania
	  AND p27_localidad = rm_c13.c13_localidad
	  AND p27_num_ret   = rm_c13.c13_num_ret 
INITIALIZE r_p21.* TO NULL
LET r_p21.p21_compania   = vg_codcia
LET r_p21.p21_localidad  = vg_codloc
LET r_p21.p21_codprov    = rm_c10.c10_codprov
LET r_p21.p21_tipo_doc   = vm_nota_credito
LET r_p21.p21_num_doc    = nextValInSequence('TE', vm_nota_credito)
LET r_p21.p21_referencia = 'ANULACION RECEPCION # ',
				rm_c13.c13_num_recep USING "<&", ' OC # ',
				rm_c13.c13_numero_oc USING "<<<<&"
LET r_p21.p21_fecha_emi  = TODAY
LET r_p21.p21_moneda     = rm_c10.c10_moneda
LET r_p21.p21_paridad    = rm_c10.c10_paridad
LET r_p21.p21_valor      = rm_c13.c13_tot_recep - tot_ret
LET r_p21.p21_saldo      = rm_c13.c13_tot_recep - tot_ret
LET r_p21.p21_subtipo    = 1
LET r_p21.p21_origen     = 'A'
LET r_p21.p21_usuario    = vg_usuario
LET r_p21.p21_fecing     = CURRENT
INSERT INTO cxpt021 VALUES(r_p21.*)
-- Para aplicar la nota de credito
DECLARE q_ddev CURSOR FOR 
	SELECT * FROM cxpt020
		WHERE p20_compania                  = vg_codcia
	          AND p20_localidad                 = vg_codloc
	          AND p20_codprov                   = rm_c10.c10_codprov
	          AND p20_tipo_doc                  = 'FA'
	          AND p20_num_doc                   = rm_c13.c13_factura
		  AND p20_saldo_cap + p20_saldo_int > 0
		FOR UPDATE
INITIALIZE r_p22.* TO NULL
LET r_p22.p22_compania  = vg_codcia
LET r_p22.p22_localidad = vg_codloc
LET r_p22.p22_codprov	= rm_c10.c10_codprov
LET r_p22.p22_tipo_trn  = 'AJ'
LET r_p22.p22_num_trn 	= fl_actualiza_control_secuencias(vg_codcia, vg_codloc,
				'TE', 'AA', r_p22.p22_tipo_trn)
IF r_p22.p22_num_trn <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_p22.p22_referencia  = r_p21.p21_referencia CLIPPED
LET r_p22.p22_fecha_emi   = TODAY
LET r_p22.p22_moneda 	  = rm_c10.c10_moneda
LET r_p22.p22_paridad 	  = rm_c10.c10_paridad
LET r_p22.p22_tasa_mora   = 0
LET r_p22.p22_total_cap   = 0
LET r_p22.p22_total_int   = 0
LET r_p22.p22_total_mora  = 0
LET r_p22.p22_subtipo 	  = 1
LET r_p22.p22_origen 	  = 'A'
LET r_p22.p22_fecha_elim  = NULL
LET r_p22.p22_tiptrn_elim = NULL
LET r_p22.p22_numtrn_elim = NULL
LET r_p22.p22_usuario 	  = vg_usuario
LET r_p22.p22_fecing 	  = CURRENT
INSERT INTO cxpt022 VALUES (r_p22.*)
LET num_row        = SQLCA.SQLERRD[6]
LET valor_favor    = r_p21.p21_valor 
LET i              = 0
LET valor_aplicado = 0
FOREACH q_ddev INTO r_p20.*
	LET valor_aplicar = valor_favor - valor_aplicado
	IF valor_aplicar = 0 THEN
		EXIT FOREACH
	END IF
	LET i            = i + 1
	LET aplicado_cap = 0
	LET aplicado_int = 0
	IF r_p20.p20_saldo_int <= valor_aplicar THEN
		LET aplicado_int = r_p20.p20_saldo_int 
	ELSE
		LET aplicado_int = valor_aplicar
	END IF
	LET valor_aplicar = valor_aplicar - aplicado_int
	IF r_p20.p20_saldo_cap <= valor_aplicar THEN
		LET aplicado_cap = r_p20.p20_saldo_cap 
	ELSE
		LET aplicado_cap = valor_aplicar
	END IF
	LET valor_aplicado       = valor_aplicado + aplicado_cap + aplicado_int
	LET r_p22.p22_total_cap  = r_p22.p22_total_cap + (aplicado_cap * -1)
	LET r_p22.p22_total_int  = r_p22.p22_total_int + (aplicado_int * -1)
    	LET r_p23.p23_compania   = vg_codcia
    	LET r_p23.p23_localidad  = vg_codloc
    	LET r_p23.p23_codprov	 = r_p22.p22_codprov
    	LET r_p23.p23_tipo_trn   = r_p22.p22_tipo_trn
    	LET r_p23.p23_num_trn    = r_p22.p22_num_trn
    	LET r_p23.p23_orden 	 = i
    	LET r_p23.p23_tipo_doc   = r_p20.p20_tipo_doc
    	LET r_p23.p23_num_doc 	 = r_p20.p20_num_doc
    	LET r_p23.p23_div_doc 	 = r_p20.p20_dividendo
    	LET r_p23.p23_tipo_favor = r_p21.p21_tipo_doc
    	LET r_p23.p23_doc_favor  = r_p21.p21_num_doc
    	LET r_p23.p23_valor_cap  = aplicado_cap * -1
    	LET r_p23.p23_valor_int  = aplicado_int * -1
    	LET r_p23.p23_valor_mora = 0
    	LET r_p23.p23_saldo_cap  = r_p20.p20_saldo_cap
    	LET r_p23.p23_saldo_int  = r_p20.p20_saldo_int
	INSERT INTO cxpt023 VALUES (r_p23.*)
	UPDATE cxpt020 SET p20_saldo_cap = p20_saldo_cap - aplicado_cap,
	                   p20_saldo_int = p20_saldo_int - aplicado_int
		WHERE CURRENT OF q_ddev
END FOREACH
UPDATE cxpt021 SET p21_saldo = p21_saldo - valor_aplicado
	WHERE p21_compania  = r_p21.p21_compania
	  AND p21_localidad = r_p21.p21_localidad
	  AND p21_codprov   = r_p21.p21_codprov
	  AND p21_tipo_doc  = r_p21.p21_tipo_doc
	  AND p21_num_doc   = r_p21.p21_num_doc
IF i = 0 THEN
	DELETE FROM cxpt022 WHERE ROWID = num_row
ELSE
	UPDATE cxpt022 SET p22_total_cap = r_p22.p22_total_cap,
	                   p22_total_int = r_p22.p22_total_int
		WHERE ROWID = num_row
END IF
RETURN valor_aplicado

END FUNCTION



FUNCTION nextValInSequence(modulo, tipo_tran)
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE tipo_tran 	LIKE rept019.r19_cod_tran
DEFINE retVal 		SMALLINT

SET LOCK MODE TO WAIT 
LET retVal   = -1
WHILE retVal = -1
	LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc,
							modulo, 'AA', tipo_tran)
	IF retVal = 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	IF retVal <> -1 THEN
		EXIT WHILE
	END IF
END WHILE
SET LOCK MODE TO NOT WAIT
RETURN retVal

END FUNCTION



FUNCTION eliminar_diarios_contables_recep_reten_oc_anuladas()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_c40		RECORD LIKE ordt040.*
DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE num_ret		LIKE cxpt027.p27_num_ret

DECLARE q_eli_cont CURSOR WITH HOLD FOR
	SELECT ordt010.*, ordt013.*
		FROM ordt010, ordt013
		WHERE c10_compania    = vg_codcia
		  AND c10_localidad   = vg_codloc
		  AND c10_ord_trabajo = rm_orden.t23_orden
		  AND c10_estado      = 'E'
		  AND c13_compania    = c10_compania
		  AND c13_localidad   = c10_localidad
		  AND c13_numero_oc   = c10_numero_oc
		  AND c13_estado      = c10_estado
		ORDER BY c10_numero_oc
FOREACH q_eli_cont INTO r_c10.*, r_c13.*
	INITIALIZE r_c40.*, num_ret TO NULL
	SELECT * INTO r_c40.* FROM ordt040
		WHERE c40_compania  = r_c13.c13_compania
		  AND c40_localidad = r_c13.c13_localidad
		  AND c40_numero_oc = r_c13.c13_numero_oc
		  AND c40_num_recep = r_c13.c13_num_recep
	IF r_c40.c40_compania IS NOT NULL THEN
		CALL eliminar_diario_contable(r_c40.c40_compania,
						r_c40.c40_tipo_comp,
						r_c40.c40_num_comp,
						r_c13.*, 1)
	END IF
	DECLARE q_obtret CURSOR FOR 
		SELECT UNIQUE p28_num_ret
			FROM cxpt028
			WHERE p28_compania  = r_c10.c10_compania
			  AND p28_localidad = r_c10.c10_localidad
			  AND p28_codprov   = r_c10.c10_codprov
			  AND p28_tipo_doc  = 'FA'
			  AND p28_num_doc   = r_c13.c13_factura
	OPEN  q_obtret
	FETCH q_obtret INTO num_ret
	CLOSE q_obtret
	FREE  q_obtret
	IF num_ret IS NOT NULL THEN
		CALL fl_lee_retencion_cxp(r_c13.c13_compania,
						r_c13.c13_localidad, num_ret)
			RETURNING r_p27.*
		IF r_p27.p27_tip_contable IS NOT NULL THEN
			IF r_p27.p27_estado = 'E' THEN
			       CALL eliminar_diario_contable(r_p27.p27_compania,
							r_p27.p27_tip_contable,
							r_p27.p27_num_contable,
							r_c13.*, 2)
			END IF
		END IF
	END IF
	CALL fl_genera_saldos_proveedor(r_c13.c13_compania, r_c13.c13_localidad,
					r_c10.c10_codprov)
END FOREACH

END FUNCTION



FUNCTION eliminar_diario_contable(codcia, tipo_comp, num_comp, r_c13, flag)
DEFINE codcia		LIKE ctbt012.b12_compania
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE flag		SMALLINT
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE mensaje		VARCHAR(250)
DEFINE mens_com		VARCHAR(100)

CALL fl_lee_comprobante_contable(codcia, tipo_comp, num_comp) RETURNING r_b12.*
IF r_b12.b12_compania IS NULL THEN
	CASE flag
		WHEN 1
			LET mens_com = 'contable para la recepción # ',
					r_c13.c13_num_recep USING "<<<<&&"
		WHEN 2
			LET mens_com = 'contable para la retención # ',
					r_c13.c13_num_ret USING "<<<<&&",
					'de la recepción # ',
					r_c13.c13_num_recep USING "<<<<&&"
	END CASE
	LET mensaje = 'No existe en la ctbt012 comprobante',
			mens_com CLIPPED,
			' por orden de compra # ',
			r_c13.c13_numero_oc USING "<<<<<<<&",
			' para el comprobante contable ',
			tipo_comp, '-', num_comp, '.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	RETURN
END IF
IF r_b12.b12_estado = 'E' THEN
	RETURN
END IF
CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
				r_b12.b12_num_comp, 'D')
SET LOCK MODE TO WAIT 5
UPDATE ctbt012 SET b12_estado     = 'E',
		   b12_fec_modifi = CURRENT 
	WHERE b12_compania  = r_b12.b12_compania
	  AND b12_tipo_comp = r_b12.b12_tipo_comp
	  AND b12_num_comp  = r_b12.b12_num_comp

END FUNCTION



FUNCTION cambiar_numero_fact_oc(orden_oc)
DEFINE orden_oc		LIKE ordt010.c10_numero_oc
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE i, lim		INTEGER
DEFINE query		CHAR(800)

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, orden_oc) RETURNING r_c10.*
INITIALIZE r_c13.* TO NULL
DECLARE q_recep CURSOR FOR
	SELECT * FROM ordt013
		WHERE c13_compania  = r_c10.c10_compania
		  AND c13_localidad = r_c10.c10_localidad
		  AND c13_numero_oc = orden_oc
		  AND c13_estado    = 'E'
OPEN q_recep
FETCH q_recep INTO r_c13.*
CLOSE q_recep
FREE q_recep
LET i   = 1
LET lim = LENGTH(r_c13.c13_factura)
CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, r_c10.c10_codprov, 'FA',
				r_c13.c13_factura, 1)
	RETURNING r_p20.*
WHILE TRUE
	LET vm_fact_nue = r_p20.p20_num_doc[1, 3],
				r_p20.p20_num_doc[5, lim] CLIPPED,
				i USING "<<<<<<&"
	CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
					r_c10.c10_codprov, 'FA',
					vm_fact_nue, 1)
		RETURNING r_p20.*
	IF r_p20.p20_compania IS NULL THEN
		EXIT WHILE
	END IF
	LET lim = LENGTH(vm_fact_nue)
	LET i   = i + 1
END WHILE
BEGIN WORK
WHENEVER ERROR STOP 
LET query = 'UPDATE ordt010 ',
		' SET c10_factura = "', vm_fact_nue CLIPPED, '"',
		' WHERE c10_compania  = ', vg_codcia,
		'   AND c10_localidad = ', vg_codloc,
		'   AND c10_numero_oc = ', r_c10.c10_numero_oc
PREPARE exec_up01 FROM query
EXECUTE exec_up01
LET query = 'UPDATE ordt013 ',
		' SET c13_factura  = "', vm_fact_nue CLIPPED, '", ',
		'     c13_num_guia = "', vm_fact_nue CLIPPED, '"',
		' WHERE c13_compania  = ', vg_codcia,
		'   AND c13_localidad = ', vg_codloc,
		'   AND c13_numero_oc = ', r_c10.c10_numero_oc,
		'   AND c13_estado    = "E" ',
		'   AND c13_num_recep = ', r_c13.c13_num_recep
PREPARE exec_up02 FROM query
EXECUTE exec_up02
DECLARE q_p23 CURSOR FOR
	SELECT * FROM cxpt023
		WHERE p23_compania  = vg_codcia
	          AND p23_localidad = vg_codloc
	          AND p23_codprov   = r_c10.c10_codprov
	          AND p23_tipo_doc  = 'FA'
	          AND p23_num_doc   = r_c13.c13_factura
OPEN q_p23
FETCH q_p23 INTO r_p23.*
IF STATUS = NOTFOUND THEN
	LET query = 'UPDATE cxpt020 ',
			' SET p20_num_doc = "', vm_fact_nue CLIPPED, '"',
			' WHERE p20_compania  = ', vg_codcia,
			'   AND p20_localidad = ', vg_codloc,
			'   AND p20_codprov   = ', r_c10.c10_codprov,
			'   AND p20_tipo_doc  = "FA" ',
			'   AND p20_num_doc   = "', r_c13.c13_factura, '"'
	PREPARE exec_up03 FROM query
	EXECUTE exec_up03
	COMMIT WORK
	RETURN
END IF
SELECT * FROM cxpt020
	WHERE p20_compania  = vg_codcia
          AND p20_localidad = vg_codloc
          AND p20_codprov   = r_c10.c10_codprov
          AND p20_tipo_doc  = 'FA'
          AND p20_num_doc   = r_c13.c13_factura
	INTO TEMP tmp_p20
LET query = 'UPDATE tmp_p20 ',
		' SET p20_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p20_compania  = ', vg_codcia,
		'   AND p20_localidad = ', vg_codloc,
		'   AND p20_codprov   = ', r_c10.c10_codprov,
		'   AND p20_tipo_doc  = "FA" ',
		'   AND p20_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up04 FROM query
EXECUTE exec_up04
INSERT INTO cxpt020 SELECT * FROM tmp_p20
LET query = 'UPDATE cxpt023 ',
		' SET p23_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p23_compania  = ', vg_codcia,
		'   AND p23_localidad = ', vg_codloc,
		'   AND p23_codprov   = ', r_c10.c10_codprov,
		'   AND p23_tipo_doc  = "FA" ',
		'   AND p23_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up05 FROM query
EXECUTE exec_up05
LET query = 'UPDATE cxpt025 ',
		' SET p25_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p25_compania  = ', vg_codcia,
		'   AND p25_localidad = ', vg_codloc,
		'   AND p25_codprov   = ', r_c10.c10_codprov,
		'   AND p25_tipo_doc  = "FA" ',
		'   AND p25_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up06 FROM query
EXECUTE exec_up06
LET query = 'UPDATE cxpt028 ',
		' SET p28_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p28_compania  = ', vg_codcia,
		'   AND p28_localidad = ', vg_codloc,
		'   AND p28_codprov   = ', r_c10.c10_codprov,
		'   AND p28_tipo_doc  = "FA" ',
		'   AND p28_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up07 FROM query
EXECUTE exec_up07
LET query = 'UPDATE cxpt041 ',
		' SET p41_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p41_compania  = ', vg_codcia,
		'   AND p41_localidad = ', vg_codloc,
		'   AND p41_codprov   = ', r_c10.c10_codprov,
		'   AND p41_tipo_doc  = "FA" ',
		'   AND p41_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up08 FROM query
EXECUTE exec_up08
LET query = 'DELETE FROM cxpt020 ',
		' WHERE p20_compania  = ', vg_codcia,
		'   AND p20_localidad = ', vg_codloc,
		'   AND p20_codprov   = ', r_c10.c10_codprov,
		'   AND p20_tipo_doc  = "FA" ',
		'   AND p20_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_del01 FROM query
EXECUTE exec_del01
WHENEVER ERROR STOP 
COMMIT WORK
DROP TABLE tmp_p20

END FUNCTION



FUNCTION actualiza_ot_x_oc(orden)
DEFINE orden		LIKE talt023.t23_orden
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE bien_serv	LIKE ordt001.c01_bien_serv
DEFINE tipo		LIKE ordt011.c11_tipo
DEFINE tot_rep, valor	DECIMAL(12,2)
DEFINE tot_mo		DECIMAL(12,2)

WHENEVER ERROR CONTINUE
DECLARE q_t23 CURSOR FOR
	SELECT * FROM talt023
		WHERE t23_compania  = vg_codcia
		  AND t23_localidad = vg_codloc
		  AND t23_orden	    = orden
	FOR UPDATE
OPEN q_t23
FETCH q_t23 INTO r_t23.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo actualizar los totales por mano de obra externa de la orden de trabajo. Registro bloqueado por otro usuario.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_ord CURSOR FOR
	SELECT ordt010.*, c01_bien_serv
		FROM ordt010, ordt001
		WHERE c10_compania    = r_t23.t23_compania
		  AND c10_localidad   = r_t23.t23_localidad
		  AND c10_ord_trabajo = r_t23.t23_orden
		  AND c10_estado      = 'C'
		  AND c01_tipo_orden  = c10_tipo_orden
		ORDER BY c10_numero_oc
LET r_t23.t23_val_rp_tal = 0
LET r_t23.t23_val_otros2 = 0
LET r_t23.t23_val_mo_cti = 0
LET r_t23.t23_val_rp_cti = 0
LET r_t23.t23_val_mo_ext = 0
LET r_t23.t23_val_rp_ext = 0
FOREACH q_ord INTO r_c10.*, bien_serv
	DECLARE q_detoc CURSOR FOR 
		SELECT c11_tipo, (c11_cant_ped * c11_precio) - c11_val_descto
			FROM ordt011
			WHERE c11_compania  = r_c10.c10_compania
			  AND c11_localidad = r_c10.c10_localidad
			  AND c11_numero_oc = r_c10.c10_numero_oc
			ORDER BY c11_secuencia
	LET tot_rep = 0
	LET tot_mo  = 0
	FOREACH q_detoc INTO tipo, valor
		LET valor = valor + (valor * r_c10.c10_recargo / 100)
		LET valor = fl_retorna_precision_valor(r_c10.c10_moneda, valor)
		IF tipo = 'B' THEN
			LET tot_rep = tot_rep + valor
		ELSE
			LET tot_mo  = tot_mo  + valor
		END IF
	END FOREACH
	IF bien_serv = 'B' THEN
		LET r_t23.t23_val_rp_tal = r_t23.t23_val_rp_tal + tot_rep
	ELSE
		IF bien_serv = 'I' THEN     -- Son Suministros
			LET r_t23.t23_val_otros2 = tot_rep + tot_mo
		ELSE
			CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc,
							r_c10.c10_codprov)
				RETURNING r_p02.*
			IF r_p02.p02_int_ext = 'I' THEN
				LET r_t23.t23_val_mo_cti = r_t23.t23_val_mo_cti
								+ tot_mo
				LET r_t23.t23_val_rp_cti = r_t23.t23_val_rp_cti
								+tot_rep
			ELSE
				LET r_t23.t23_val_mo_ext = r_t23.t23_val_mo_ext
								+ tot_mo
				LET r_t23.t23_val_rp_ext = r_t23.t23_val_rp_ext
								+ tot_rep
			END IF
		END IF
	END IF
END FOREACH
WHENEVER ERROR STOP
CALL fl_totaliza_orden_taller(r_t23.*) RETURNING r_t23.*
UPDATE talt023 SET * = r_t23.* WHERE CURRENT OF q_t23

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



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Crear Cliente'            AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Vehículo de Clientes'     AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Documento'            AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
