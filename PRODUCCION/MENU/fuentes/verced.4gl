DATABASE acero_gm



DEFINE rm_z01		RECORD
				z01_codcli	like cxct001.z01_codcli,
				z01_num_doc_id	like cxct001.z01_num_doc_id,
				z01_nomcli	like cxct001.z01_nomcli
			end record
DEFINE cont		INTEGER
DEFINE salto1		VARCHAR(50)
DEFINE salto2		VARCHAR(15)
DEFINE resul, long	SMALLINT
DEFINE archivos	 	char(400)



MAIN

	if num_args() <> 1 and num_args() <> 2 then
		display 'Faltan parametros.'
		exit program
	end if
	let archivos = arg_val(1)
	call verifica()

END MAIN



function verifica()
define mes		char(2)
DEFINE r_z01		RECORD LIKE cxct001.*

set isolation to dirty read
SELECT z01_codcli, z01_num_doc_id, z01_nomcli FROM cxct001
	where z01_codcli = -1
	INTO TEMP te_cliente
if num_args() = 1 then
	call cargar_meses()
else
	let mes = arg_val(2) using "&&"
	call carga_cli_mes(mes)
end if
SELECT unique z01_codcli, z01_num_doc_id, z01_nomcli
	FROM te_cliente
	where z01_codcli <> 99
	into temp te_cliente1
drop table te_cliente
DECLARE q_lazo CURSOR FOR SELECT * FROM te_cliente1 ORDER BY z01_codcli
FOREACH q_lazo INTO rm_z01.*
	INITIALIZE r_z01.* TO NULL
	SELECT * INTO r_z01.* FROM cxct001 WHERE z01_codcli = rm_z01.z01_codcli
	IF r_z01.z01_codcli IS NULL THEN
		DISPLAY 'No existe el código de cliente: ',
			rm_z01.z01_codcli USING "<<<<<&"
		EXIT PROGRAM
	END IF
	IF r_z01.z01_tipo_doc_id = 'P' THEN
		CONTINUE FOREACH
	END IF
	CALL fl_validar_cedruc_dig_ver(rm_z01.z01_num_doc_id) RETURNING resul
	IF NOT resul THEN
		DISPLAY rm_z01.z01_codcli USING '&&&&&&', '|',
			rm_z01.z01_num_doc_id CLIPPED, '|'
	END IF
END FOREACH
drop table te_cliente1

end function



function cargar_meses()
define mes		char(2)
define i		smallint

for i = 1 to 12
	let mes = i using "&&"
	if not encontro_mes(mes) then
		continue for
	end if
	call carga_cli_mes(mes)
end for

end function



function encontro_mes(mes)
define mes		char(2)
define encontro, j	smallint

let j = 1
let encontro = 0
while (j < length(archivos))
	if archivos[j, j + 1] = mes and archivos[j + 2, j + 2] = '.' then
		let encontro = 1
		exit while
	end if
	let j = j + 1
end while
return encontro

end function



function carga_cli_mes(mes)
define mes		char(2)

case mes
	when '01'
	       load from "VENTAS2005/upcliente200501.txt" insert into te_cliente
	when '02'
	       load from "VENTAS2005/upcliente200502.txt" insert into te_cliente
	when '03'
	       load from "VENTAS2005/upcliente200503.txt" insert into te_cliente
	when '04'
	       load from "VENTAS2005/upcliente200504.txt" insert into te_cliente
	when '05'
	       load from "VENTAS2005/upcliente200505.txt" insert into te_cliente
	when '06'
	       load from "VENTAS2005/upcliente200506.txt" insert into te_cliente
	when '07'
	       load from "VENTAS2005/upcliente200507.txt" insert into te_cliente
	when '08'
	       load from "VENTAS2005/upcliente200508.txt" insert into te_cliente
	when '09'
	       load from "VENTAS2005/upcliente200509.txt" insert into te_cliente
	when '10'
	       load from "VENTAS2005/upcliente200510.txt" insert into te_cliente
	when '11'
	       load from "VENTAS2005/upcliente200511.txt" insert into te_cliente
	when '12'
	       load from "VENTAS2005/upcliente200512.txt" insert into te_cliente
end case

end function



FUNCTION fl_validar_cedruc_dig_ver(cedruc)
DEFINE cedruc		VARCHAR(15)
DEFINE valor		ARRAY[15] OF SMALLINT
DEFINE suma, i, lim	SMALLINT
DEFINE residuo_suma	SMALLINT

LET lim    = 10
LET cedruc = cedruc CLIPPED
IF (LENGTH(cedruc) <> lim) AND (LENGTH(cedruc) <> 13) THEN
	--CALL fl_mostrar_mensaje('El número de digitos de cédula/ruc es incorrecto.', 'exclamation')
	RETURN 0
END IF
IF (cedruc[1, 2] > 22) OR (cedruc[1, 2] = 00) THEN
	--CALL fl_mostrar_mensaje('Los digitos iniciales de cédula/ruc son incorrectos.', 'exclamation')
	RETURN 0
END IF
IF LENGTH(cedruc) = 13 THEN
	IF cedruc[11, 13] <> '001' OR cedruc[11, 12] <> '00' THEN
		--CALL fl_mostrar_mensaje('El número de digitos del ruc es incorrecto.', 'exclamation')
		RETURN 0
	END IF
END IF
FOR i = 1 TO lim
	LET valor[i] = 0
END FOR
LET residuo_suma = NULL
IF cedruc[3, 3] = 9 THEN
	LET valor[1]   = cedruc[1, 1] * 4
	LET valor[2]   = cedruc[2, 2] * 3
	LET valor[3]   = cedruc[3, 3] * 2
	LET valor[4]   = cedruc[4, 4] * 7
	LET valor[5]   = cedruc[5, 5] * 6
	LET valor[6]   = cedruc[6, 6] * 5
	LET valor[7]   = cedruc[7, 7] * 4
	LET valor[8]   = cedruc[8, 8] * 3
	LET valor[9]   = cedruc[9, 9] * 2
	LET valor[lim] = cedruc[lim, lim]
	LET suma       = 0
	FOR i = 1 TO lim - 1
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 11 - (suma mod 11)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 11 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
IF (cedruc[3, 3] = 6) OR (cedruc[3, 3] = 8) THEN
	LET valor[1]   = cedruc[1, 1] * 3
	LET valor[2]   = cedruc[2, 2] * 2
	LET valor[3]   = cedruc[3, 3] * 7
	LET valor[4]   = cedruc[4, 4] * 6
	LET valor[5]   = cedruc[5, 5] * 5
	LET valor[6]   = cedruc[6, 6] * 4
	LET valor[7]   = cedruc[7, 7] * 3
	LET valor[8]   = cedruc[8, 8] * 2
	LET valor[lim] = cedruc[9, 9]
	LET suma       = 0
	FOR i = 1 TO lim - 2
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 11 - (suma mod 11)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 11 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
IF ((cedruc[3, 3] < 3) OR (cedruc[3, 3] > 5)) AND (cedruc[3, 3] <> 7) THEN
	FOR i = 1 TO lim - 1
		LET valor[i] = cedruc[i, i]
		IF (i mod 2) <> 0 THEN
			LET valor[i] = valor[i] * 2
			IF valor[i] > 9 THEN
				LET valor[i] = valor[i] - 9
			END IF
		END IF
	END FOR
	LET valor[lim] = cedruc[lim, lim]
	LET suma       = 0
	FOR i = 1 TO lim - 1
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 10 - (suma mod 10)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 10 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
--CALL fl_mostrar_mensaje('El número de cédula/ruc no es valido.', 'exclamation')
RETURN 0

END FUNCTION
