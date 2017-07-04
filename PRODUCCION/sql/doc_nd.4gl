database acero_gm


define v_cod_loc	smallint
define v_anio, v_mes	smallint



main

	if num_args() <> 3 then
		display 'Falta Localidad, Año y Mes.'
		exit program
	end if
	let v_cod_loc = arg_val(1)
	let v_anio    = arg_val(2)
	let v_mes     = arg_val(3)
	call obtener_doc_nd()

end main



function obtener_doc_nd()

set isolation to dirty read
select z01_codcli, z01_num_doc_id, z20_saldo_cap subtotal,z20_saldo_cap tot_iva,
	z20_num_doc cuantos
	from cxct020, cxct001
	where z20_compania = 10
	  and z01_estado   = 'Z'
	into temp t1

call sacar_nd_del_mes(v_cod_loc)
call obtener_clientes()
call salida_nd()

end function



function sacar_nd_del_mes(cod_loc)
define cod_loc		like gent002.g02_localidad

call generar_temp(cod_loc, 1)
call generar_temp(cod_loc, 2)
insert into t1
	select t2.z01_codcli, t2.z01_num_doc_id, subtotal, tot_iva, cuantos
		from t2, t3
		where t2.z01_codcli = t3.z01_codcli
drop table t2
drop table t3

end function



function obtener_clientes()

unload to "cli_nd.txt"
	select t1.z01_codcli, t1.z01_num_doc_id, z01_nomcli
		from t1, cxct001
		where subtotal <> 0
		  and tot_iva   > 0
		  and cxct001.z01_codcli = t1.z01_codcli
		 order by 1

end function



function salida_nd()
define tot_neto		decimal(14,2)

unload to "upnotdeb.txt"
	select z01_codcli, z01_num_doc_id, subtotal, tot_iva, cuantos
		from t1
		where tot_iva > 0
		order by 1
select sum(subtotal) into tot_neto from t1 where subtotal <> 0 order by 1
display "El Total N/D del Año ", v_anio using '&&&&', " del Mes ", v_mes
	using '&&', " es   : ", tot_neto using "###,##&.##"
drop table t1

end function



function generar_temp(cod_loc, tabla)
define cod_loc		like gent002.g02_localidad
define tabla		smallint
define query		char(1200)
define expr_sel		char(200)
define temporal		char(20)

case tabla
	when 1
		let expr_sel = "select z01_codcli, z01_num_doc_id, ",
					"sum((z20_valor_cap + z20_valor_int) ",
					"- z20_val_impto) subtotal, ",
					"sum(z20_val_impto) tot_iva "
		let temporal = " into temp t2 "
	when 2
		let expr_sel = "select z01_codcli, z01_num_doc_id, count(*) ",
					"cuantos"
		let temporal = " into temp t3 "
end case
let query = expr_sel clipped,
		" from cxct020, cxct001",
		" where z20_compania      = 1 ",
		"   and z20_localidad     = ", cod_loc,
		"   and z20_tipo_doc      = 'ND' ",
	  	"   and year(z20_fecing)  = ", v_anio,
	  	"   and month(z20_fecing) = ", v_mes,
		"   and z01_codcli        = z20_codcli ",
		" group by 1, 2 ",
		temporal clipped
prepare q_temp from query
execute q_temp

end function
