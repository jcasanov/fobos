DATABASE migracion



MAIN
DEFINE 	linea		CHAR(5) 

CALL startlog('errores')

IF num_args() <> 1 THEN
	DISPLAY 'Ingrese linea.'
	DISPLAY 'Uso: fglrun carga_archivo_precios linea' 
	EXIT PROGRAM
END IF

LET linea = arg_val(1)

DISPLAY 'Borrando la última lista de precios procesada...'
DELETE FROM te_new_precios

CREATE TEMP TABLE tbl_lista_precios(
	id		SERIAL,
	linea	VARCHAR(200)
)

DISPLAY 'Cargando una nueva lista de precios...'
LOAD FROM "/home/fobos/shared/precios.txt" INSERT INTO tbl_lista_precios(linea)

DISPLAY 'Se depurará la lista tomando en cuenta el proveedor.' 
DISPLAY 'Esto puede tomar algunos minutos, por favor espere...'
BEGIN WORK
	CASE linea
		WHEN 'KOMAT' 
			CALL depuracion_datos_komatsu()
		WHEN 'BOMAG' 
			CALL depuracion_datos_bomag()
		OTHERWISE
			DISPLAY 'LINEA DESCONOCIDA: ', linea 
	END CASE
COMMIT WORK
DISPLAY 'Proceso terminado, ahora puede actualizar la lista de precios con "actualiza_precios"'

END MAIN



FUNCTION depuracion_datos_komatsu()
DEFINE r_lista 			RECORD LIKE te_new_precios.*
DEFINE item_cargado		VARCHAR(20)
DEFINE cod_item			VARCHAR(20)
DEFINE precio_fob		DECIMAL(14,2)
DEFINE num_item_repetido INTEGER

LET cod_item = ''
LET num_item_repetido=0

DECLARE q_lista_komatsu CURSOR FOR 
	SELECT linea[1,14] codigo, trim(linea[48,62]) item, linea[38,46] precio, id 
	  FROM tbl_lista_precios ORDER BY id

FOREACH q_lista_komatsu INTO r_lista.*
        
	IF cod_item = r_lista.te_item THEN
		LET num_item_repetido= num_item_repetido + 1        
	ELSE
		LET cod_item = r_lista.te_item   
		LET num_item_repetido=0     
	END IF

	IF num_item_repetido <=1 THEN
		LET precio_fob = r_lista.te_fob /100 	
	END IF

	IF num_item_repetido =0 THEN
		INSERT INTO te_new_precios VALUES (r_lista.te_item, r_lista.te_nombre, precio_fob, 0)
	ELSE
		IF num_item_repetido =1 THEN
			UPDATE te_new_precios SET te_fob = precio_fob
			 WHERE te_item = r_lista.te_item 
		END IF
	END IF
END FOREACH

END FUNCTION



FUNCTION depuracion_datos_bomag()

SQL
	INSERT INTO te_new_precios(te_item, te_nombre, te_fob)  
	SELECT TRIM(linea[1,12]) codigo, MAX(TRIM(linea[14,54])) item,
		   MAX(CAST(TRIM(linea[55,72]) AS FLOAT) * 1.4596)  precio 
	  FROM tbl_lista_precios
	 GROUP BY 1 
END SQL

END FUNCTION
