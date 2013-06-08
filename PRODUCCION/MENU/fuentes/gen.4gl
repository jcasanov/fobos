define v_cod_loc	smallint
define v_anio_ini	smallint
define v_anio_fin	smallint
define v_mes_ini	smallint
define v_mes_fin	smallint



main

	if num_args() <> 5 then
		display "Falta Localidad, Año Inicial, Año Final, Mes Inicial o Mes Final."
		exit program
	end if
	let v_cod_loc  = arg_val(1)
	let v_anio_ini = arg_val(2)
	let v_anio_fin = arg_val(3)
	if v_anio_ini < 2003 then
		display "El Año Inicial no puede ser menor al 2003."
		exit program
	end if
	if v_anio_fin < 2003 then
		display "El Año Final no puede ser menor al 2003."
		exit program
	end if
	if v_anio_fin < v_anio_ini then
		display "El Año Final no puede ser menor al Año Inicial."
		exit program
	end if
	let v_mes_ini  = arg_val(4)
	let v_mes_fin  = arg_val(5)

	call ejecutar_prog()

end main



function ejecutar_prog()
define i, j		smallint

for i = v_anio_ini to v_anio_fin
	for j = 1 to 12
		if j < v_mes_ini then
			if i = v_anio_ini then
				continue for
			end if
		end if
		if j > v_mes_fin then
			if i = v_anio_fin then
				continue for
			end if
		end if
		call llamar_prog('vent_gye', i, j)
		call llamar_prog('doc_nc', i, j)
		call llamar_prog('doc_nd', i, j)
		call llamar_prog('cli_gye', i, j)
		call mover_arch('cliente', i, j)
		call mover_arch('notcre', i, j)
		call mover_arch('notdeb', i, j)
		call mover_arch('ventas', i, j)
		display ' '
	end for
end for

end function



function llamar_prog(prog, i, j)
define prog		char(10)
define i, j		smallint
define comando		varchar(100)

let comando = "fglgo ", prog clipped, " ", v_cod_loc, " ", i, " ", j
run comando

end function



function mover_arch(arch, i, j)
define arch		char(10)
define i, j		smallint
define comando		varchar(100)

let comando = " mv up", arch clipped, ".txt VENTAS", v_anio_ini using '&&&&',
		"/up", arch clipped, i using '&&&&', j using '&&', ".txt"
run comando

end function
