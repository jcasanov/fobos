database acero_gm


define anio		smallint
define cod_trab		like rolt030.n30_cod_trab



main

	if num_args() <> 2 then
		display 'Falta el año y código de trabajador.'
		exit program
	end if
	let anio     = arg_val(1)
	let cod_trab = arg_val(2)
	call ejecuta_proceso()

end main



function ejecuta_proceso()
define r_n03		record like rolt003.*
define tot_neto		like rolt032.n32_tot_neto
define tot_gan		like rolt032.n32_tot_gan

display ' '
select nvl(sum(n32_tot_neto), 0), nvl(sum(n32_tot_gan), 0)
	into tot_neto, tot_gan
	from rolt032
	where n32_cod_trab = cod_trab
display 'El total ganado hasta ', anio using "&&&&", ' es  : ',
	tot_gan using "$#<,<<<,##&.##"
display 'El total recibido hasta ', anio using "&&&&", ' es: ',
	tot_neto using "$#<,<<<,##&.##"
declare q_n03 cursor for select * from rolt003 where n03_estado = 'A'
display ' '
foreach q_n03 into r_n03.*
	case r_n03.n03_frecuencia
		when 'Q'
			let fecha_ini = mdy(r_n03.n03_mes_ini,
						r_n03.n03_dia_ini, anio)
			let fecha_fin = mdy(r_n03.n03_mes_fin,
						r_n03.n03_dia_fin, anio)
	end case
end foreach

end function
