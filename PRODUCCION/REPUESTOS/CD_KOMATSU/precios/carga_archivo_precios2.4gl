DATABASE migracion

MAIN

CALL startlog('errores')

BEGIN WORK
CALL depuracion_datos()
COMMIT WORK

END MAIN

FUNCTION depuracion_datos()

DEFINE r_z20            RECORD LIKE te_new_precios.*
DEFINE cod_item		VARCHAR(20)	 
DEFINE item_anterior    VARCHAR(50)
DEFINE precio1		DECIMAL(14,2)	--segun el caso, representa:
				      	-- 1.- al fob del 1er reg de un item   
				      	-- 2.- al fob del reg anterior al reg actual
DEFINE precio2		DECIMAL(14,2) 	-- si se repite el item, carga el fob actual
DEFINE num_item_repetido INTEGER 	-- lleva siempre 1 si encuentra q un item ya se cargo  		
LET cod_item = ''
LET num_item_repetido=0
LET item_anterior=''

--cargamos la tabla te_new_precios, q previamente se cargo a traves d un script
--a fin de establecer un precio fijo; para los items q se repiten
       
DECLARE q_doc CURSOR FOR SELECT * FROM te_new_precios order by 1

FOREACH q_doc INTO r_z20.* 

	IF cod_item = r_z20.te_item THEN
		LET num_item_repetido = 1 
		LET precio2 = r_z20.te_fob
	  ELSE
		LET cod_item = r_z20.te_item
		LET item_anterior = r_z20.te_nombre   
		LET num_item_repetido = 0
 		LET precio1 = r_z20.te_fob   
	END IF

	-- En esta condicion se ejecutara solo pa los casos en q exista items repetidos
	-- se actualizara los items a un precio unico, para este caso sera el item
	-- cuyo valor fob sea el mayor de todos(para un te_item en particular) 
	IF num_item_repetido =1 THEN

		IF   precio1 < precio2	THEN

			UPDATE te_new_precios SET te_fob = precio2
			WHERE
			te_item = r_z20.te_item		AND
			te_nombre = item_anterior	AND
                        te_fob    = precio1	

			LET precio1 =  precio2
		
		  ELSE	
			IF   precio1 > precio2  THEN

				UPDATE te_new_precios SET te_fob = precio1
	                        WHERE 
				te_item   =  r_z20.te_item 	AND
				te_nombre =  r_z20.te_nombre	AND
				te_fob	  =  r_z20.te_fob
	
        	        END IF	
		END IF

	END IF
	
END FOREACH

END FUNCTION
