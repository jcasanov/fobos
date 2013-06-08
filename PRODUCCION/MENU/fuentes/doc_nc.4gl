database acero_gm


define v_cod_loc	smallint
define v_anio, v_mes	smallint
define loc_mat		smallint



main

	if num_args() <> 3 then
		display 'Falta Localidad, Año y Mes.'
		exit program
	end if
	let v_cod_loc = arg_val(1)
	let v_anio    = arg_val(2)
	let v_mes     = arg_val(3)
	let loc_mat   = 2
	call obtener_doc_nc()

end main



function obtener_doc_nc()

set isolation to dirty read
select z01_codcli, z01_num_doc_id, z21_saldo subtotal, z21_saldo tot_iva,
	z21_num_doc cuantos
	from cxct021, cxct001
	where z21_compania = 10
	  and z01_estado   = 'Z'
	into temp t1

call sacar_nc_del_mes(v_cod_loc, 1)
call sacar_nc_del_mes(loc_mat, 1)
call sacar_nc_del_mes(loc_mat, 0)
call obtener_clientes()
call salida_nc()

end function



function sacar_nc_del_mes(cod_loc, sino)
define sino		smallint
define cod_loc		like gent002.g02_localidad

call generar_temp(cod_loc, 1, sino)
call generar_temp(cod_loc, 2, sino)
insert into t1
	select t2.z01_codcli, t2.z01_num_doc_id, subtotal, tot_iva, cuantos
		from t2, t3
		where t2.z01_codcli = t3.z01_codcli
drop table t2
drop table t3

end function



function obtener_clientes()

unload to "cli_nc.txt"
	select t1.z01_codcli, t1.z01_num_doc_id, z01_nomcli
		from t1, cxct001
		where subtotal <> 0
		  and cxct001.z01_codcli = t1.z01_codcli
		 order by 1

end function



function salida_nc()
define tot_neto		decimal(14,2)

unload to "upnotcre.txt"
	select z01_codcli, z01_num_doc_id, sum(subtotal), sum(tot_iva),
		sum(cuantos)
		from t1
		group by 1, 2
		order by 1
select sum(subtotal) into tot_neto from t1 where subtotal <> 0 order by 1
display "El Total N/C del Año ", v_anio using '&&&&', " del Mes ", v_mes
	using '&&', " es   : ", tot_neto using "###,##&.##"
drop table t1

end function



function generar_temp(cod_loc, tabla, sino)
define cod_loc		like gent002.g02_localidad
define tabla		smallint
define sino		smallint
define query		char(1200)
define expr_sel		char(200)
define expr_nc		char(200)
define base		char(20)
define temporal		char(20)

let base = null
if cod_loc = loc_mat then
	let base = "acero_gc:"
end if
let expr_nc = "   and ((z21_cod_tran     = 'DF' or z21_origen = 'M') ",
	      "     or (z21_cod_tran     = 'FA' or z21_areaneg = 2)) "
if sino = 0 then
	let base = null
	let expr_nc = "   and z21_origen = 'M' "
end if
case tabla
	when 1
		let expr_sel = "select z01_codcli, z01_num_doc_id, ",
					"sum(z21_valor - z21_val_impto) ",
					"subtotal, sum(z21_val_impto) tot_iva "
		let temporal = " into temp t2 "
	when 2
		let expr_sel = "select z01_codcli, z01_num_doc_id, count(*) ",
					"cuantos"
		let temporal = " into temp t3 "
end case
let query = expr_sel clipped,
		" from ", base clipped, "cxct021, ", base clipped, "cxct001",
		" where z21_compania      = 1 ",
		"   and z21_localidad     = ", cod_loc,
		"   and z21_tipo_doc      = 'NC' ",
		expr_nc CLIPPED,
	  	"   and year(z21_fecing)  = ", v_anio,
	  	"   and month(z21_fecing) = ", v_mes,
		"   and z01_codcli        = z21_codcli ",
		" group by 1, 2 ",
		temporal clipped
prepare q_temp from query
execute q_temp

end function
