------------------------------------------------------------------------------
-- Titulo               : maqp400.4gl --  Listado de Modelos X Clientes 
-- Elaboración          : Noviembre 18, 2004 
-- Autor                : JCM
-- Formato de Ejecución : fglrun maqp400 base modulo compañía 
-- Ultima Correción     : 
-- Motivo Corrección    :  

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_par RECORD
	m01_provincia	LIKE maqt001.m01_provincia,
	n_provincia	LIKE maqt001.m01_nombre,
	m11_canton	LIKE maqt011.m11_canton,
	n_canton	LIKE maqt002.m02_nombre,
	m10_linea	LIKE maqt010.m10_linea,
	n_linea		LIKE maqt005.m05_nombre,
	m11_codcli	LIKE maqt011.m11_codcli,
	n_cliente	LIKE cxct001.z01_nomcli
END RECORD

DEFINE rm_consulta	RECORD 
	provincia	LIKE maqt001.m01_provincia,
	canton		LIKE maqt011.m11_canton,
	n_canton	LIKE maqt002.m02_nombre,
	cliente		LIKE maqt011.m11_codcli,
	n_cliente	LIKE cxct001.z01_nomcli,
	secuencia	LIKE maqt011.m11_secuencia,
	linea		LIKE maqt010.m10_linea, 
	modelo		LIKE maqt011.m11_modelo, 
	serie		LIKE maqt011.m11_serie  
END RECORD

DEFINE vm_page 		SMALLINT
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT

DEFINE vm_lin		SMALLINT



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CALL startlog('../logs/maqp400.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 3 THEN   
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso  = 'maqp400'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		VARCHAR(1000)
DEFINE comando          VARCHAR(100)


LET vm_top	= 1
LET vm_left	= 2
LET vm_right	= 90
LET vm_bottom	= 4
LET vm_page	= 44

CALL fl_nivel_isolation()
OPEN WINDOW wf AT 3,2 WITH 14 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP, ACCEPT KEY F12
OPEN FORM frm_listado FROM '../forms/maqf400_1'
DISPLAY FORM frm_listado

LET int_flag = 0
INITIALIZE rm_par.* TO NULL 

WHILE (TRUE)
	CALL control_ingreso()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF INT_FLAG THEN
		EXIT WHILE
	END IF

	LET query = 'SELECT m02_provincia, m11_canton,  m02_nombre, '
                 || '       m11_codcli,    z01_nomcli,  m11_secuencia, '
                 || '       m10_linea,     m11_modelo,  m11_serie  '
                 || '  FROM maqt011, maqt010, maqt002, cxct001 ' 
                 || ' WHERE m11_compania = ' || vg_codcia    
	IF rm_par.m11_codcli IS NOT NULL THEN
		LET query = query || ' AND m11_codcli = ' || rm_par.m11_codcli 
	END IF
	IF rm_par.m10_linea IS NOT NULL THEN
		LET query = query || ' AND m11_codcli = "' 
				  || rm_par.m10_linea CLIPPED || '"'  
	END IF
	IF rm_par.m01_provincia IS NOT NULL THEN
		LET query = query || ' AND m02_provincia = ' || rm_par.m01_provincia 
	END IF
	IF rm_par.m11_canton IS NOT NULL THEN
		LET query = query || ' AND m11_canton = ' || rm_par.m11_canton 
	END IF
	LET query = query || ' AND m02_canton    = m11_canton    '
                          || ' AND z01_codcli    = m11_codcli    '  
			  || ' AND m10_compania  = m11_compania  '
			  || ' AND m10_modelo    = m11_modelo    '
                          || ' ORDER BY 1, 2, 4, 7, 8'

	PREPARE expresion FROM query
	DECLARE q_maq CURSOR FOR expresion
	OPEN q_maq
	FETCH q_maq INTO rm_consulta.*
	IF SQLCA.SQLCODE = NOTFOUND THEN
		CLOSE q_maq
		CALL fl_mensaje_consulta_sin_registros()
		RETURN
	END IF
	CLOSE q_maq
	START REPORT reporte_maquinas TO PIPE comando
	FOREACH q_maq INTO rm_consulta.*
		OUTPUT TO REPORT reporte_maquinas(rm_consulta.provincia)
	END FOREACH
	FINISH REPORT reporte_maquinas
END WHILE

END FUNCTION



FUNCTION control_ingreso()
DEFINE	r_z01		RECORD LIKE cxct001.*
DEFINE  r_m01		RECORD LIKE maqt001.*
DEFINE  r_m02 		RECORD LIKE maqt002.*
DEFINE  r_m05  		RECORD LIKE maqt005.*

LET int_flag = 0
INPUT BY NAME rm_par.*  WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		RETURN
	ON KEY (F2)
		IF infield(m01_provincia) THEN
			CALL fl_ayuda_provincias()
				RETURNING r_m01.* 
			IF r_m01.m01_provincia IS NOT NULL THEN
				LET rm_par.m01_provincia = r_m01.m01_provincia
				LET rm_par.n_provincia   = r_m01.m01_nombre
				DISPLAY BY NAME rm_par.m01_provincia,
						rm_par.n_provincia          
			END IF
			LET int_flag = 0
		END IF
{
		IF infield(bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia)
				RETURNING codbod, descbod
			IF codbod IS NOT NULL THEN
				LET rm_par.bodega = codbod
				DISPLAY codbod 	TO bodega
				DISPLAY descbod	TO desc_bodega
			END IF
			LET int_flag = 0
		END IF
		IF infield(linea) THEN
			CALL fl_ayuda_lineas_veh(vg_codcia)
				RETURNING codlinea, nomlinea
			IF codlinea IS NOT NULL THEN
				LET rm_par.linea = codlinea
				DISPLAY codlinea TO linea
				DISPLAY nomlinea TO desc_linea
			END IF
			LET int_flag = 0
		END IF
		IF infield(vendedor) THEN
			CALL fl_ayuda_vendedores_veh(vg_codcia)
				RETURNING codven, nomven
			IF codven IS NOT NULL THEN
				LET rm_par.vendedor = codven
				DISPLAY codven	TO vendedor
				DISPLAY nomven	TO desc_vendedor
			END IF
			LET int_flag = 0
		END IF
	AFTER INPUT  
		IF rm_par.inicial IS NULL OR rm_par.final IS NULL THEN
			CONTINUE INPUT
		END IF

		IF rm_par.inicial > rm_par.final THEN
			CALL fgl_winmessage('PHOBOS',
			   'La fecha inicial debe ser menor o igual que ' ||
			   'la fecha final.',
			   'exclamation')
			CONTINUE INPUT
		END IF
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_moneda.*
			IF r_moneda.g13_moneda IS NULL THEN
				CALL fgl_winmessage('PHOBOS',
					'No existe moneda',
					'exclamation')
				NEXT FIELD moneda
			ELSE
				DISPLAY r_moneda.g13_nombre TO desc_moneda
			END IF
		ELSE
			CLEAR desc_moneda	
		END IF
	AFTER FIELD bodega
		IF rm_par.bodega IS NOT NULL THEN
			CALL fl_lee_bodega_veh(vg_codcia, rm_par.bodega)
				RETURNING r_bodega.*
			IF r_bodega.v02_bodega IS NULL THEN
				CALL fgl_winmessage('PHOBOS',
					'Bodega no existe',
					'exclamation')
				NEXT FIELD bodega
			ELSE
				LET d_bodega = r_bodega.v02_nombre
				DISPLAY r_bodega.v02_nombre 	
					TO desc_bodega
			END IF
		ELSE
			CLEAR desc_bodega
		END IF
	AFTER FIELD linea
		 IF rm_par.linea IS NOT NULL THEN
			CALL fl_lee_linea_veh(vg_codcia, rm_par.linea)
				RETURNING r_linea.*
			IF r_linea.v03_linea IS NULL THEN

				CALL fgl_winmessage('PHOBOS',
					'Línea no existe',
					'exclamation')
				NEXT FIELD linea
			ELSE
				LET d_linea = r_linea.v03_nombre
				DISPLAY r_linea.v03_nombre TO desc_linea 	
			END IF
		ELSE
			CLEAR desc_linea
		END IF
	AFTER FIELD vendedor
		IF rm_par.vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_veh(vg_codcia, rm_par.vendedor)
				RETURNING r_vendedor.*
			IF r_vendedor.v01_vendedor IS NULL THEN
				CALL fgl_winmessage('PHOBOS', 
					'Vendedor no existe',
					'exclamation')
				NEXT FIELD vendedor
			ELSE
				LET d_vendedor = r_vendedor.v01_nombres
				DISPLAY r_vendedor.v01_nombres 
					TO desc_vendedor
			END IF
		ELSE
			CLEAR desc_vendedor
		END IF
}
END INPUT

END FUNCTION



REPORT reporte_maquinas(provincia)

DEFINE provincia	LIKE maqt001.m01_provincia
DEFINE r_m01    	RECORD LIKE maqt001.*
DEFINE r_m12    	RECORD LIKE maqt012.*
DEFINE uno		SMALLINT

DEFINE  usuario         VARCHAR(19,15)
DEFINE  titulo          VARCHAR(80)
DEFINE  modulo          VARCHAR(40)
DEFINE  i,long          SMALLINT

OUTPUT
	TOP 	MARGIN vm_top
	LEFT 	MARGIN vm_left
	RIGHT 	MARGIN vm_right
	BOTTOM	MARGIN vm_bottom
	PAGE 	LENGTH vm_page

FORMAT
	PAGE HEADER
		LET modulo	= 'Módulo: Maquinarias'
		LET long	= LENGTH(modulo)
		
		print '&l1O';		-- Modo landscape
		print '&k4S'	        -- Letra (12 cpi)
		CALL fl_justifica_titulo('D', 'USUARIO: ' || vg_usuario, 10) 
		RETURNING usuario
		CALL fl_justifica_titulo('C', 'LISTADO DE MAQUINAS EN SERVICIO POST-VENTA', '52')
		RETURNING titulo

        	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
              	      COLUMN 110, 'Página: ', PAGENO USING "&&&"

        	PRINT COLUMN 1,   modulo  CLIPPED,
		      COLUMN 44,  titulo,
                      COLUMN 100, UPSHIFT(vg_proceso)

	      	SKIP 1 LINES
	
		IF rm_par.m11_canton IS NOT NULL THEN
			PRINT COLUMN 20, '*** Cantón        : ', rm_par.m11_canton,
						            ' ', rm_par.n_canton	
		ELSE
			PRINT COLUMN 20, '*** Cantón        : T O D O S '
		END IF	

		IF rm_par.m10_linea IS NOT NULL THEN
			PRINT COLUMN 20, '*** Línea de venta: ', rm_par.m10_linea,
						            ' ', rm_par.n_linea	
		ELSE
			PRINT COLUMN 20, '*** Línea de venta: T O D O S '
		END IF	

		IF rm_par.m11_codcli IS NOT NULL THEN
			PRINT COLUMN 20, '*** Cliente       : ', rm_par.m11_codcli,
						            ' ', rm_par.n_cliente	
		ELSE
			PRINT COLUMN 20, '*** Cliente       : T O D O S '
		END IF	

		SKIP 1 LINES
		LET uno = 1
		LET vm_lin = 0

		INITIALIZE r_m01.* TO NULL
		SELECT * INTO r_m01.* FROM maqt001
		 WHERE m01_provincia = rm_consulta.provincia

		PRINT COLUMN 20, '*** Provincia: ' || UPSHIFT(r_m01.m01_nombre) 
	
		PRINT COLUMN 01, 'Fecha impresión: ', TODAY USING 'yyyy-mm-dd', 
				 1 SPACES, TIME,
	              COLUMN 110, usuario

		SKIP 1 LINES
		PRINT COLUMN 1,   'Cantón',
		      COLUMN 23,  'Cliente ',          
		      COLUMN 65,  'Línea',
		      COLUMN 72,  'Modelo',
		      COLUMN 89,  'Fec. Ult. Revisión',	
		      COLUMN 109, 'Horómetro'     

		PRINT COLUMN 1,   '----------------------',
		      COLUMN 23,  '-------------------------------------------',
		      COLUMN 60,  '--------',
		      COLUMN 67,  '------------------',
		      COLUMN 84,  '---------------------',
		      COLUMN 104, '------'; 
		print '&k2S'	        -- Letra (12 cpi)
                                                                                
	BEFORE GROUP OF provincia
		FOR i = vm_lin TO vm_page
			SKIP 1 LINES
		END FOR

	ON EVERY ROW
		LET vm_lin = vm_lin + 1
		INITIALIZE r_m12.* TO NULL
		DECLARE q_hor CURSOR FOR
			SELECT * FROM maqt012
			 WHERE m12_compania  = vg_codcia
			   AND m12_modelo    = rm_consulta.modelo
			   AND m12_secuencia = rm_consulta.secuencia
			ORDER BY m12_compania, m12_modelo, m12_secuencia,
                                 m12_fecha DESC

		OPEN  q_hor
		FETCH q_hor INTO r_m12.*
		CLOSE q_hor
		FREE  q_hor

		PRINT COLUMN 1,   rm_consulta.n_canton[1, 45] CLIPPED,
		      COLUMN 47,  rm_consulta.n_cliente[1, 40] CLIPPED,
		      COLUMN 89,  rm_consulta.linea CLIPPED,
		      COLUMN 96,  rm_consulta.modelo CLIPPED,
		      COLUMN 111, r_m12.m12_fecha USING 'dd-mm-yyyy',
		      COLUMN 123, r_m12.m12_horometro USING '##,###'
END REPORT



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
