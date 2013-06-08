database acero_gm



main

	call obtener_clientes()
	call borrar_arch_cli()

end main



function obtener_clientes()

set isolation to dirty read
select z01_codcli, z01_num_doc_id, z01_nomcli
	from cxct001
	where z01_codcli = -1
	into temp t1
load from "cli_vta.txt" insert into t1
load from "cli_nc.txt" insert into t1
load from "cli_nd.txt" insert into t1
unload to "upcliente.txt"
	select unique z01_codcli, z01_num_doc_id, z01_nomcli
		from t1
		order by 1
drop table t1

end function



function borrar_arch_cli()

run " rm cli_vta.txt"
run " rm cli_nc.txt"
run " rm cli_nd.txt"

end function
