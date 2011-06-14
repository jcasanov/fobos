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

DEFINE r_lista 			RECORD LIKE te_new_precios.*
DEFINE cod_item			VARCHAR(20)	 
DEFINE item_anterior	VARCHAR(50)
DEFINE precio1			DECIMAL(14,2)	--segun el caso, representa:
										-- 1.- al fob del 1er reg de un item   
										-- 2.- al fob del reg anterior al reg actual
DEFINE precio2			DECIMAL(14,2) 	-- si se repite el item, carga el fob actual
DEFINE num_item_repetido INTEGER 		-- lleva siempre 1 si encuentra q un item ya se cargo  		
LET cod_item = ''
LET num_item_repetido=0
LET item_anterior=''

SQL
	INSERT INTO te_new_precios(te_item, te_nombre, te_fob)  
	SELECT TRIM(linea[1,12]) codigo, TRIM(linea[14,54]) item,
	(CAST(TRIM(linea[55,72]) AS FLOAT) * 1.4596)  precio FROM tbl_lista_precios;
END SQL

--leemos la tabla te_new_precios, q previamente se cargo 
--a fin de establecer un precio fijo; para los items q se repiten
       
DECLARE q_lista_bomag CURSOR FOR SELECT * FROM te_new_precios order by 1

FOREACH q_lista_bomag INTO r_lista.* 

	IF cod_item = r_lista.te_item THEN
		LET num_item_repetido = 1 
		LET precio2 = r_lista.te_fob
	ELSE
		LET cod_item = r_lista.te_item
		LET item_anterior = r_lista.te_nombre   
		LET num_item_repetido = 0
 		LET precio1 = r_lista.te_fob   
	END IF

	-- En esta condicion se ejecutara solo pa los casos en q exista items repetidos
	-- se actualizara los items a un precio unico, para este caso sera el item
	-- cuyo valor fob sea el mayor de todos(para un te_item en particular) 
	IF num_item_repetido =1 THEN
		IF   precio1 < precio2	THEN
			UPDATE te_new_precios SET te_fob = precio2
			WHERE te_item = r_lista.te_item		
			  AND te_nombre = item_anterior	
			  AND te_fob    = precio1	

			LET precio1 =  precio2
		ELSE	
			IF   precio1 > precio2  THEN
				UPDATE te_new_precios SET te_fob = precio1
	             WHERE te_item   =  r_lista.te_item 	
				   AND te_nombre =  r_lista.te_nombre	
				   AND te_fob	 =  r_lista.te_fob
			END IF	
		END IF
	END IF
END FOREACH

END FUNCTION
