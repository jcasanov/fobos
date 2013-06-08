GLOBALS "../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl"

FUNCTION fl_ayuda_grupo_activo(codcia)
DEFINE 	i,j	  INTEGER
DEFINE  max_rows  INTEGER
DEFINE  codcia	  LIKE actt001.a01_compania
DEFINE rh_gru	  ARRAY[100] OF RECORD
	a01_grupo_act	LIKE actt001.a01_grupo_act,
	a01_nombre	LIKE actt001.a01_nombre
	END RECORD

OPEN WINDOW w_hgru AT 5,10 WITH FORM "../forms/ayuf131"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
LET max_rows = 100
DISPLAY 'Código' TO tit_col1
DISPLAY 'Descripción' TO tit_col2
DECLARE qh_gru CURSOR FOR SELECT a01_grupo_act, a01_nombre FROM actt001
	WHERE a01_compania = codcia
	ORDER BY 2
LET i = 1
FOREACH qh_gru INTO rh_gru[i].*
	LET i = i + 1
	IF i > max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	CALL fgl_winmessage('PHOBOS','No hay grupo de activos  registrados','exclamation')
	INITIALIZE rh_gru[1].* TO NULL
	CLOSE WINDOW w_hgru
	RETURN rh_gru[1].*
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_gru TO rh_gru.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
END DISPLAY 
IF int_flag THEN
	INITIALIZE rh_gru[1].* TO NULL
	CLOSE WINDOW w_hgru
	RETURN rh_gru[1].*
END IF
CLOSE WINDOW w_hgru
LET i = arr_curr()
RETURN rh_gru[i].*

END FUNCTION



FUNCTION fl_ayuda_tipo_activo(codcia)
DEFINE 	i	  SMALLINT
DEFINE  max_rows  SMALLINT
DEFINE  codcia	  LIKE actt002.a02_compania
DEFINE rh_tip	  ARRAY[100] OF RECORD
	a02_tipo_act	LIKE actt002.a02_tipo_act,
	a02_nombre	LIKE actt002.a02_nombre
	END RECORD

OPEN WINDOW w_htip AT 5,10 WITH FORM "../forms/ayuf132"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
LET max_rows = 100
DISPLAY 'Código' TO tit_col1
DISPLAY 'Descripción' TO tit_col2
DECLARE qh_tip CURSOR FOR SELECT a02_tipo_act, a02_nombre FROM actt002
	WHERE a02_compania = codcia
	ORDER BY 2
LET i = 1
FOREACH qh_tip INTO rh_tip[i].*
	LET i = i + 1
	IF i > max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	CALL fgl_winmessage('PHOBOS','No hay tipo de activos registrados','exclamation')
	INITIALIZE rh_tip[1].* TO NULL
	CLOSE WINDOW w_htip
	RETURN rh_tip[1].*
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tip TO rh_tip.*
	ON KEY(RETURN)
		LET i = arr_curr()
		EXIT DISPLAY
	AFTER DISPLAY
		LET i = arr_curr()
END DISPLAY
IF int_flag THEN
	INITIALIZE rh_tip[1].* TO NULL
	CLOSE WINDOW w_htip
	RETURN rh_tip[1].*
END IF
CLOSE WINDOW w_htip
RETURN rh_tip[i].*

END FUNCTION



FUNCTION fl_ayuda_responsable(codcia)
DEFINE 	i	  SMALLINT
DEFINE  max_rows  SMALLINT
DEFINE  codcia	  LIKE actt003.a03_compania
DEFINE rh_res	  ARRAY[100] OF RECORD
	a03_responsable	LIKE actt003.a03_responsable,
	a03_nombres	LIKE actt003.a03_nombres
	END RECORD

OPEN WINDOW w_hres AT 5,10 WITH FORM "../forms/ayuf133"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
LET max_rows = 100
DISPLAY 'Código' TO tit_col1
DISPLAY 'Nombre' TO tit_col2
DECLARE qh_res CURSOR FOR SELECT a03_responsable, a03_nombres FROM actt003
	WHERE a03_compania = codcia
	ORDER BY 2
LET i = 1
FOREACH qh_res INTO rh_res[i].*
	LET i = i + 1
	IF i > max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	CALL fgl_winmessage('PHOBOS','No hay responsables registrados','exclamation')
	INITIALIZE rh_res[1].* TO NULL
	CLOSE WINDOW w_hres
	RETURN rh_res[1].*
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_res TO rh_res.*
	ON KEY (RETURN)
		LET i = arr_curr()
		EXIT DISPLAY
	AFTER DISPLAY
		LET i = arr_curr()
END DISPLAY		
IF int_flag THEN
	INITIALIZE rh_res[1].* TO NULL
	CLOSE WINDOW w_hres
	RETURN rh_res[1].*
END IF
CLOSE WINDOW w_hres
LET i = arr_curr()
RETURN rh_res[i].*

END FUNCTION


FUNCTION fl_lee_tipo_activo(cod_cia, bien)
DEFINE cod_cia          LIKE actt002.a02_compania
DEFINE bien		LIKE actt002.a02_tipo_act
DEFINE r                RECORD LIKE actt002.*
                                                                                
INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM actt002
        WHERE a02_compania = cod_cia AND a02_tipo_act = bien
RETURN r.*
                                                                                
END FUNCTION


FUNCTION fl_lee_grupo_activo(cod_cia, grupo)
DEFINE cod_cia          LIKE actt001.a01_compania
DEFINE grupo		LIKE actt001.a01_grupo_act
DEFINE r                RECORD LIKE actt001.*
                                                                                
INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM actt001
        WHERE a01_compania = cod_cia AND a01_grupo_act = grupo
RETURN r.*
                                                                                
END FUNCTION


FUNCTION fl_lee_responsable(cod_cia, responsable)
DEFINE cod_cia          LIKE actt003.a03_compania
DEFINE responsable	LIKE actt003.a03_nombres
DEFINE r                RECORD LIKE actt003.*
                                                                                
INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM actt003
        WHERE a03_compania = cod_cia AND a03_responsable = responsable
RETURN r.*
                                                                                
END FUNCTION


FUNCTION fl_ayuda_bien(codcia)
DEFINE 	i,j	  SMALLINT
DEFINE  max_rows  SMALLINT
DEFINE  codcia	  LIKE actt001.a01_compania
DEFINE rh_gru	  ARRAY[100] OF RECORD
	a10_codigo_bien	LIKE actt010.a10_codigo_bien,
	a10_descripcion	LIKE actt010.a10_descripcion
	END RECORD

OPEN WINDOW w_hgru AT 5,10 WITH FORM "../forms/ayuf134"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
LET max_rows = 100
DISPLAY 'Código' TO tit_col1
DISPLAY 'Descripción' TO tit_col2
DECLARE qh_bien CURSOR FOR 
	SELECT a10_codigo_bien, a10_descripcion FROM actt010
	WHERE a10_compania = codcia
	ORDER BY 2
LET i = 1
FOREACH qh_bien INTO rh_gru[i].*
	LET i = i + 1
	IF i > max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	CALL fgl_winmessage('PHOBOS','No hay grupo de activos  registrados','exclamation')
	INITIALIZE rh_gru[1].* TO NULL
	CLOSE WINDOW w_hgru
	RETURN rh_gru[1].*
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_gru TO rh_gru.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
END DISPLAY 
IF int_flag THEN
	INITIALIZE rh_gru[1].* TO NULL
	CLOSE WINDOW w_hgru
	RETURN rh_gru[1].*
END IF
CLOSE WINDOW w_hgru
LET i = arr_curr()
RETURN rh_gru[i].*

END FUNCTION


