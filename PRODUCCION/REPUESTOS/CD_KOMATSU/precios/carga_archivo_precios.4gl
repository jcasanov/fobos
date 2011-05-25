DATABASE migracion



MAIN

CALL startlog('errores')

DELETE FROM te_new_precios

CREATE TEMP TABLE precios_komatsu(
	id		SERIAL,
	linea	VARCHAR(200)
)

LOAD FROM "/home/fobos/shared/precios.txt" INSERT INTO precios_komatsu(linea)

BEGIN WORK
CALL depuracion_datos()
COMMIT WORK

END MAIN



FUNCTION depuracion_datos()
DEFINE r_z20            RECORD LIKE te_new_precios.*
DEFINE item_cargado	VARCHAR(20)
DEFINE cod_item		VARCHAR(20)
DEFINE precio1		VARCHAR(9)
DEFINE precio2		DECIMAL(14,2)
DEFINE num_item_repetido INTEGER

LET cod_item = ''
LET num_item_repetido=0

DECLARE q_doc CURSOR FOR SELECT linea[1,14] codigo, trim(linea[48,62]) item, linea[38,46] precio, id FROM precios_komatsu order by id
FOREACH q_doc INTO r_z20.*
        
	IF cod_item = r_z20.te_item THEN
		LET num_item_repetido= num_item_repetido + 1        
	ELSE
		LET cod_item = r_z20.te_item   
		LET num_item_repetido=0     
	END IF

	IF num_item_repetido <=1 THEN
		LET precio2= r_z20.te_fob /100 	
	END IF

	IF num_item_repetido =0 THEN
		INSERT INTO te_new_precios VALUES (r_z20.te_item, r_z20.te_nombre, precio2, 0)
	ELSE
		IF num_item_repetido =1 THEN
			UPDATE te_new_precios SET te_fob = precio2
			 WHERE te_item = r_z20.te_item 
		END IF
	END IF
END FOREACH

END FUNCTION
