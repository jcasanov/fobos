database aceros


define base	char(20)



main

	let base = arg_val(1)
	call ejecuta_proceso()

end main



function ejecuta_proceso()
define i, total_rep	integer
define r_p22		record like cxpt022.*
define fecha		like cxpt022.p22_fecing

database base
select p22_fecing fecing, count(*) total
	from cxpt022
	group by 1
	having count(*) > 1
	into temp t1
select count(*) into total_rep from t1
display 'Total de Transacciones: ', total_rep using "<<<<&"
declare q_p22 cursor with hold for
	select p22_compania, p22_localidad, p22_codprov, p22_tipo_trn,
		p22_num_trn, p22_fecing
		from cxpt022
		where p22_fecing in (select fecing from t1)
		order by 6, 3, 4, 5 desc
let fecha = current
let i     = 0
foreach q_p22 into r_p22.p22_compania, r_p22.p22_localidad, r_p22.p22_codprov,
		r_p22.p22_tipo_trn, r_p22.p22_num_trn, r_p22.p22_fecing
	if fecha = r_p22.p22_fecing then
		continue foreach
	end if
	display 'Actualizando: ', r_p22.p22_compania using "<<&&", ' ',
		r_p22.p22_localidad using "<<&&", ' ', r_p22.p22_codprov
		using "<<<&&", ' ', r_p22.p22_tipo_trn, '-',
		r_p22.p22_num_trn using "<<<<<<&", ' ', r_p22.p22_fecing
	begin work
		update cxpt022
			set p22_fecing = r_p22.p22_fecing + 1 units second
			where p22_compania  = r_p22.p22_compania
			  and p22_localidad = r_p22.p22_localidad
			  and p22_codprov   = r_p22.p22_codprov
			  and p22_tipo_trn  = r_p22.p22_tipo_trn
			  and p22_num_trn   = r_p22.p22_num_trn
	commit work
	let i     = i + 1
	let fecha = r_p22.p22_fecing
end foreach
drop table t1
display ' '
display 'Se actualizaron un total de ', i using "<<<<&", ' transacciones, el ',
	'fecing en 1 segundo. '
display 'Actualización Terminada. OK'

end function
