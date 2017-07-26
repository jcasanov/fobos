DATABASE aceros



DEFINE base1, base2	CHAR(20)
DEFINE codcia1, codcia2	LIKE gent001.g01_compania
DEFINE codigo		LIKE rept003.r03_codigo



MAIN

	IF num_args() <> 5 THEN
		DISPLAY 'Parametros Incorrectos. BASE_ORIGEN BASE_DESTINO ',
			'COMPAÑIA_ORIGEN COMPAÑIA_DESTINO DIVISION'
		EXIT PROGRAM
	END IF
	LET base1   = arg_val(1)
	LET base2   = arg_val(2)
	LET codcia1 = arg_val(3)
	LET codcia2 = arg_val(4)
	LET codigo  = arg_val(5)
	CALL ejecuta_proceso()
	DISPLAY 'Actualización Terminada OK.'

END MAIN



FUNCTION ejecuta_proceso()
DEFINE r_div		RECORD
				codigo		LIKE rept003.r03_codigo,
				nombre		LIKE rept003.r03_nombre
			END RECORD
DEFINE r_lin		RECORD
				codigo		LIKE rept070.r70_linea,
				linea		LIKE rept070.r70_sub_linea,
				nombre		LIKE rept070.r70_desc_sub
			END RECORD
DEFINE r_grp		RECORD
				codigo		LIKE rept071.r71_linea,
				linea		LIKE rept071.r71_sub_linea,
				grupo		LIKE rept071.r71_cod_grupo,
				nombre		LIKE rept071.r71_desc_grupo
			END RECORD
DEFINE r_cla		RECORD
				codigo		LIKE rept072.r72_linea,
				linea		LIKE rept072.r72_sub_linea,
				grupo		LIKE rept072.r72_cod_grupo,
				clase		LIKE rept072.r72_cod_clase,
				nombre		LIKE rept072.r72_desc_clase
			END RECORD
DEFINE r_ite		RECORD
				codigo		LIKE rept010.r10_codigo,
				nombre		LIKE rept010.r10_nombre,
				divi		LIKE rept010.r10_linea,
				linea		LIKE rept010.r10_sub_linea,
				grupo		LIKE rept010.r10_cod_grupo,
				clase		LIKE rept010.r10_cod_clase
			END RECORD
DEFINE i		INTEGER

DATABASE base1
SET ISOLATION TO DIRTY READ
DISPLAY 'Descargando jerarquía e ítems de la división ', codigo CLIPPED,
	'. Por favor espere ...'
UNLOAD TO "division.unl"
	SELECT r03_codigo, r03_nombre
		FROM rept003
		WHERE r03_compania = codcia1
		  AND r03_codigo   = codigo
UNLOAD TO "linea.unl"
	SELECT r70_linea, r70_sub_linea, r70_desc_sub
		FROM rept070
		WHERE r70_compania = codcia1
		  AND r70_linea    = codigo
UNLOAD TO "grupo.unl"
	SELECT r71_linea, r71_sub_linea, r71_cod_grupo, r71_desc_grupo
		FROM rept071
		WHERE r71_compania = codcia1
		  AND r71_linea    = codigo
UNLOAD TO "clase.unl"
	SELECT r72_linea, r72_sub_linea, r72_cod_grupo, r72_cod_clase,
		r72_desc_clase
		FROM rept072
		WHERE r72_compania = codcia1
		  AND r72_linea    = codigo
UNLOAD TO "item.unl"
	SELECT r10_codigo, r10_nombre, r10_linea, r10_sub_linea, r10_cod_grupo,
		r10_cod_clase
		FROM rept010
		WHERE r10_compania = codcia1
		  AND r10_linea    = codigo
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base2
WHENEVER ERROR STOP
SET ISOLATION TO DIRTY READ
DISPLAY ' '
DISPLAY 'Subiendo la información ...'
SELECT r03_codigo, r03_nombre
	FROM rept003
	WHERE r03_compania = 23
	INTO TEMP tmp_r03
SELECT r70_linea, r70_sub_linea, r70_desc_sub
	FROM rept070
	WHERE r70_compania = 23
	INTO TEMP tmp_r70
SELECT r71_linea, r71_sub_linea, r71_cod_grupo, r71_desc_grupo
	FROM rept071
	WHERE r71_compania = 23
	INTO TEMP tmp_r71
SELECT r72_linea, r72_sub_linea, r72_cod_grupo, r72_cod_clase,
	r72_desc_clase
	FROM rept072
	WHERE r72_compania = 23
	INTO TEMP tmp_r72
SELECT r10_codigo, r10_nombre, r10_linea, r10_sub_linea, r10_cod_grupo,
	r10_cod_clase
	FROM rept010
	WHERE r10_compania = 23
	INTO TEMP tmp_r10
LOAD FROM "division.unl" INSERT INTO tmp_r03
LOAD FROM "linea.unl"    INSERT INTO tmp_r70
LOAD FROM "grupo.unl"    INSERT INTO tmp_r71
LOAD FROM "clase.unl"    INSERT INTO tmp_r72
LOAD FROM "item.unl"     INSERT INTO tmp_r10
DISPLAY ' '
DISPLAY 'Actualizando división. Por favor espere ...'
DECLARE q_r03 CURSOR FOR SELECT * FROM tmp_r03
LET i = 0
FOREACH q_r03 INTO r_div.*
	UPDATE rept003
		SET r03_nombre = r_div.nombre
		WHERE r03_compania IN (codcia1, codcia2)
		  AND r03_codigo   = r_div.codigo
	DISPLAY 'Actualizando la división ', r_div.codigo CLIPPED, '.'
	LET i = i + 1
END FOREACH
DISPLAY 'Se actualizaron un total de ', i USING "<<<<<&", ' divisiones. Ok'
DISPLAY ' '
DISPLAY 'Actualizando líneas. Por favor espere ...'
DECLARE q_r70 CURSOR FOR SELECT * FROM tmp_r70
LET i = 0
FOREACH q_r70 INTO r_lin.*
	UPDATE rept070
		SET r70_desc_sub = r_lin.nombre
		WHERE r70_compania  IN (codcia1, codcia2)
		  AND r70_linea     = r_lin.codigo
		  AND r70_sub_linea = r_lin.linea
	DISPLAY 'Actualizando la línea ', r_lin.linea CLIPPED, '.'
	LET i = i + 1
END FOREACH
DISPLAY 'Se actualizaron un total de ', i USING "<<<<<&", ' líneas. Ok'
DISPLAY ' '
DISPLAY 'Actualizando Grupos. Por favor espere ...'
DECLARE q_r71 CURSOR FOR SELECT * FROM tmp_r71
LET i = 0
FOREACH q_r71 INTO r_grp.*
	UPDATE rept071
		SET r71_desc_grupo = r_grp.nombre
		WHERE r71_compania  IN (codcia1, codcia2)
		  AND r71_linea     = r_grp.codigo
		  AND r71_sub_linea = r_grp.linea
		  AND r71_cod_grupo = r_grp.grupo
	DISPLAY 'Actualizando el Grupo ', r_grp.grupo CLIPPED, '.'
	LET i = i + 1
END FOREACH
DISPLAY 'Se actualizaron un total de ', i USING "<<<<<&", ' Grupos. Ok'
DISPLAY ' '
DISPLAY 'Actualizando Clases. Por favor espere ...'
DECLARE q_r72 CURSOR FOR SELECT * FROM tmp_r72
LET i = 0
FOREACH q_r72 INTO r_cla.*
	UPDATE rept072
		SET r72_desc_clase = r_cla.nombre
		WHERE r72_compania  IN (codcia1, codcia2)
		  AND r72_linea     = r_cla.codigo
		  AND r72_sub_linea = r_cla.linea
		  AND r72_cod_grupo = r_cla.grupo
		  AND r72_cod_clase = r_cla.clase
	DISPLAY 'Actualizando el Clase ', r_cla.clase CLIPPED, '.'
	LET i = i + 1
END FOREACH
DISPLAY 'Se actualizaron un total de ', i USING "<<<<<&", ' Clases. Ok'
DISPLAY ' '
DISPLAY 'Actualizando Items. Por favor espere ...'
DECLARE q_r10 CURSOR FOR SELECT * FROM tmp_r10
LET i = 0
FOREACH q_r10 INTO r_ite.*
	UPDATE rept010
		SET --r10_nombre    = r_ite.nombre,
		    r10_linea     = r_ite.divi,
		    r10_sub_linea = r_ite.linea,
		    r10_cod_grupo = r_ite.grupo,
		    r10_cod_clase = r_ite.clase
		WHERE r10_compania IN (codcia1, codcia2)
		  AND r10_codigo   = r_ite.codigo
	DISPLAY 'Actualizando el Item ', r_ite.codigo CLIPPED, '.'
	LET i = i + 1
END FOREACH
DISPLAY 'Se actualizaron un total de ', i USING "<<<<<&", ' Items. Ok'
DISPLAY ' '

END FUNCTION
