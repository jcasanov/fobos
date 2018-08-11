database acero_qm


main
	set isolation to dirty read
	call ejecutar_proceso()

end main



function ejecutar_proceso()
define r_z02		record like cxct002.*
define tot_cli, i	integer

display 'Cargando información por favor espere ...'
select z02_codcli, z02_referencia, z02_credit_dias
	from cxct002
	where z02_compania = 99
	into temp t1
load from "clientes_uio.unl" insert into t1
select count(*) into tot_cli from t1
display 'Se cargaron un total de ', tot_cli using "<<<<<&", ' clientes ...'
if tot_cli = 0 then
	exit program
end if
display ' '
delete from t1 where z02_codcli = 0
declare q_t1 cursor for select * from t1 order by z02_codcli
let i = 0
foreach q_t1 into r_z02.z02_codcli, r_z02.z02_referencia, r_z02.z02_credit_dias
	display 'Actualizando referencia y crédito días del cliente: ',
		r_z02.z02_codcli using "<<<<<<&"
	update cxct002
		set z02_credit_dias = r_z02.z02_credit_dias,
		    z02_referencia  = r_z02.z02_referencia
		where z02_compania  = 1
		  and z02_localidad in (3, 4)
		  and z02_codcli    = r_z02.z02_codcli
	let i = i + 1
end foreach
display ' '
display 'Se actualizaron un total de ', i using "<<<<<<&", ' clientes. OK '
drop table t1

end function
