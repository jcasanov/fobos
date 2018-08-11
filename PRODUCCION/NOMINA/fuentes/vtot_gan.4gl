database aceros



define base		char(20)
define cod_trab		like rolt030.n30_cod_trab
define anio_ini		like rolt032.n32_ano_proceso
define anio_fin		like rolt032.n32_ano_proceso



main

	if num_args() <> 4 then
		display 'Parametros Incorrectos.'
		display 'Son: base cod_trab año_ini año_fin.'
		exit program
	end if
	let base     = arg_val(1)
	let cod_trab = arg_val(2)
	let anio_ini = arg_val(3)
	let anio_fin = arg_val(4)
	call activar_base()
	call validar_parametros()
	call muestra_tot_gan()

end main



function activar_base()
define r_g51		record like gent051.*

close database
whenever error continue
database base
if status < 0 then
	display 'No se pudo abrir base de datos: ', base
	exit program
end if
whenever error stop
initialize r_g51.* to null
select * into r_g51.* from gent051
	where g51_basedatos = base
if r_g51.g51_basedatos is null then
	display 'No existe base de datos: ', base
	exit program
end if

end function



function validar_parametros()
define r_n30		record like rolt030.*

call retorna_empleado(cod_trab) returning r_n30.*
if r_n30.n30_compania is null then
	display 'No existe el Empleado con C¢digo: ', cod_trab using "&&&&"
	exit program
end if
if anio_ini > year(today) then
	display 'El a¤o inicial no puede ser mayor al vigente.'
	exit program
end if
if anio_fin > year(today) then
	display 'El a¤o final no puede ser mayor al vigente.'
	exit program
end if
if anio_ini > anio_fin then
	display 'El a¤o final no puede ser menor al a¤o inicial.'
	exit program
end if

end function



function muestra_tot_gan()
define r_n30		record like rolt030.*
define r_n32		record like rolt032.*
define tot_net		decimal(14,2)
define tot_net_c	varchar(13)
define tot_gan		decimal(14,2)
define tot_gan_c	varchar(13)
define fila		smallint
define tecla		char(1)

declare q_n32 cursor for
	select * from rolt032
		where n32_compania   = 1
		  and n32_cod_liqrol in ('Q1', 'Q2')
		  and n32_cod_trab   = cod_trab
		  and n32_ano_proceso between anio_ini and anio_fin
		order by n32_fecha_ini
call muestra_cabecera(cod_trab)
let fila    = 1
let tot_net = 0
let tot_gan = 0
foreach q_n32 into r_n32.*
	display r_n32.n32_fecha_ini using "dd-mm-yyyy", ' ', 
		r_n32.n32_fecha_fin using "dd-mm-yyyy", ' ', 
		r_n32.n32_tot_ing  using "##,###,##&.##", ' ', 
		r_n32.n32_tot_egr  using "##,###,##&.##", ' ', 
		r_n32.n32_tot_neto using "##,###,##&.##", ' ', 
		r_n32.n32_tot_gan  using "##,###,##&.##"
	let tot_net = tot_net + r_n32.n32_tot_neto
	let tot_gan = tot_gan + r_n32.n32_tot_gan
	let fila    = fila + 1
	if fila > 21 then
		prompt "Presione una Tecla para continuar ... " for char tecla
		call muestra_cabecera(r_n32.n32_cod_trab)
		let fila = 1
	end if
end foreach
let tot_net_c = tot_net using "##,###,##&.##"
let tot_gan_c = tot_gan using "##,###,##&.##"
display 'El Total Recibido hasta ahora es: ', tot_net_c using "<<<<<<<<<<.&&"
display 'El Total Ganado hasta ahora es  : ', tot_gan_c using "<<<<<<<<<<.&&"

end function



function muestra_cabecera(cod_trabaj)
define cod_trabaj	like rolt030.n30_cod_trab
define r_n30		record like rolt030.*

call retorna_empleado(cod_trabaj) returning r_n30.*
display 'Empleado: ', r_n30.n30_cod_trab using "&&&&", ' ', r_n30.n30_nombres
display '    P E R I O D O    ', ' TOTAL INGRESO', '  TOTAL EGRESO',
	'    TOTAL NETO', '  TOTAL GANADO'

end function



function retorna_empleado(cod_trabaj)
define cod_trabaj	like rolt030.n30_cod_trab
define r_n30		record like rolt030.*

initialize r_n30.* to null
select * into r_n30.* from rolt030
	where n30_compania = 1
	  and n30_cod_trab = cod_trabaj
return r_n30.*

end function
