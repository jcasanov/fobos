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
	call ventas_jtm()

end main



function ventas_jtm()

set isolation to dirty read
select z01_codcli, z01_num_doc_id, r19_tot_neto subtotal,
	r19_tot_neto tot_iva, r19_oc_interna cuantos
	from rept019, cxct001
	where r19_compania = 10
	  and r19_codcli   = z01_codcli
	into temp t1
select * from t1 into temp t5

call proceso_obtener_ventas(v_cod_loc)
call proceso_obtener_ventas(loc_mat)
call consolidacion()
call obtener_clientes()
call salida_ventas()

end function



function proceso_obtener_ventas(cod_loc)
define cod_loc		like gent002.g02_localidad

call obtener_total_fact_af_df(cod_loc, 1)
call contar_fact_af_df(cod_loc)
call insertar_t1_ventas()

if cod_loc <> loc_mat then
	call insertar_datos_tal()
end if

call obtener_total_fact_af_df(cod_loc, 2)
call contar_fact_af_df_null(cod_loc)
call insertar_t1_ventas()

end function



function consolidacion()

select * from t1 where z01_codcli = -1 into temp t5
insert into t5
	select t1.z01_codcli, t1.z01_num_doc_id, sum(t1.subtotal) subtotal, 
		sum(t1.tot_iva) tot_iva, sum(t1.cuantos) cuantos
		from t1
		group by 1, 2
delete from t1
insert into t1 select * from t5
drop table t5

end function



function obtener_clientes()

unload to "cli_vta.txt"
	select t1.z01_codcli, t1.z01_num_doc_id, z01_nomcli
		from t1, cxct001
		where subtotal <> 0
		  and cxct001.z01_codcli = t1.z01_codcli
		 order by 1

end function



function salida_ventas()
define tot_neto		decimal(14,2)

unload to "upventas.txt" select * from t1 where subtotal <> 0 order by 1
select sum(subtotal) into tot_neto from t1 where subtotal <> 0 order by 1
display "El Total Ventas del Año ", v_anio using '&&&&', " del Mes ", v_mes
	using '&&', " es: ", tot_neto using "###,##&.##"
drop table t1

end function



function obtener_total_fact_af_df(cod_loc, flag)
define cod_loc		like gent002.g02_localidad
define flag		smallint
define query		char(1200)
define expr_sel		char(150)
define expr_cli		char(100)
define expr_tablas	char(100)

case flag
	when 1
		let expr_sel = "select unique z01_codcli, z01_num_doc_id, "
		let expr_cli = "z01_codcli        = r19_codcli "
		let expr_tablas = " from rept019, cxct001 "
		if cod_loc = loc_mat then
			let expr_tablas = " from acero_gc:rept019, ",
						"acero_gc:cxct001 "
		end if
	when 2
		let expr_sel = "select 0 z01_codcli, 'CLI. VARIOS' ",
					"z01_num_doc_id, "
		let expr_cli = "r19_codcli is null "
		let expr_tablas = " from rept019 "
		if cod_loc = loc_mat then
			let expr_tablas = " from acero_gc:rept019 "
		end if
end case
let query = expr_sel clipped, " r19_cod_tran, sum(r19_tot_bruto - ",
		"r19_tot_dscto) subtotal, ",
		"sum(r19_tot_neto - (r19_tot_bruto - r19_tot_dscto) ",
			"- r19_flete) tot_iva ",
		expr_tablas clipped,
		" where r19_compania     = 1 ",
	  	"  and r19_localidad     = ", cod_loc,
		"  and r19_cod_tran      in ('FA', 'AF')",
		"  and year(r19_fecing)  = ", v_anio,
		"  and month(r19_fecing) = ", v_mes,
		"  and ", expr_cli clipped,
		" group by 1, 2, 3 ",
		" into temp t2"
prepare temp_t1 from query
execute temp_t1
update t2 set subtotal = subtotal * (-1),
	      tot_iva  = tot_iva  * (-1)
	where r19_cod_tran <> 'FA'

end function



function contar_fact_af_df(cod_loc)
define cod_loc		like gent002.g02_localidad
define codcli		like cxct001.z01_codcli
define cedruc		like cxct001.z01_num_doc_id
define cont		integer

select z01_codcli, z01_num_doc_id, count(*) cuantos
	from cxct001
	where z01_codcli = -1
	group by 1, 2
	into temp t3
declare q_t2 cursor for
	select z01_codcli, z01_num_doc_id from t2 where r19_cod_tran = 'FA'
foreach q_t2 into codcli, cedruc
	let cont = contar_fa_sin_df(cod_loc, codcli)
	insert into t3 values(codcli, cedruc, cont)
end foreach

end function



function contar_fact_af_df_null(cod_loc)
define cod_loc		like gent002.g02_localidad
define codcli		like cxct001.z01_codcli
define cont		integer

select z01_codcli, z01_num_doc_id, count(*) cuantos
	from cxct001
	where z01_codcli = -1
	group by 1, 2
	into temp t3
let codcli = null
let cont = contar_fa_sin_df(cod_loc, codcli)
insert into t3 values(0, "CLI. VARIOS", cont)

end function



function contar_fa_sin_df(cod_loc, codcli)
define cod_loc		like gent002.g02_localidad
define r_r19		record like rept019.*
define codcli		like cxct001.z01_codcli
define tot_dev		decimal(14,2)
define cont		integer
define query		char(800)
define expr_cli		char(800)
define base		char(10)

let expr_cli = "r19_codcli      = ", codcli
if codcli is null then
	let expr_cli = "r19_codcli is null "
end if
let base = null
if cod_loc = loc_mat then
	let base = "acero_gc:"
end if
let query = "select * from ", base clipped, "rept019 ",
		"where r19_compania      = 1 ",
		"  and r19_localidad     = ", cod_loc,
		"  and r19_cod_tran      = 'FA' ",
		"  and year(r19_fecing)  = ", v_anio,
		"  and month(r19_fecing) = ", v_mes,
		"  and ", expr_cli clipped
prepare t_r19_c from query
declare q_r19_c cursor for t_r19_c
foreach q_r19_c into r_r19.*
	let tot_dev = 0
	select sum(r19_tot_neto) into tot_dev from rept019
		where r19_compania   = 1
		  and r19_localidad  = cod_loc
		  and r19_cod_tran   = 'DF'
		  and r19_tipo_dev   = r_r19.r19_cod_tran
		  and r19_num_dev    = r_r19.r19_num_tran
	if r_r19.r19_tot_neto = tot_dev then
		continue foreach
	end if
	let cont = cont + 1
end foreach
return cont

end function



function insertar_t1_ventas()

insert into t1
	select t2.z01_codcli, t2.z01_num_doc_id, sum(subtotal) subtot,
		sum(tot_iva) t_iva, 0 ctos
		from t2
		group by 1, 2, 5
update t1 set cuantos = (select cuantos from t3
				where t3.z01_codcli = t1.z01_codcli)
	where z01_codcli in (select z01_codcli from t3)
drop table t2
drop table t3

end function



function insertar_datos_tal()

select unique z01_codcli, z01_num_doc_id, sum(t23_tot_bruto - t23_tot_dscto)
	subtotal, sum(t23_val_impto) tot_iva
	from talt023, cxct001
	where t23_compania           = 1
	  and t23_localidad          = v_cod_loc
	  and t23_estado             in ('F', 'D')
	  and t23_num_factura        is not null
	  and year(t23_fec_factura)  = v_anio
	  and month(t23_fec_factura) = v_mes
	  and z01_codcli             = t23_cod_cliente
	group by 1, 2
	into temp t2
select unique z01_codcli codcli, z01_num_doc_id cedula,
	sum(t23_tot_bruto - t23_tot_dscto) subtotal1,sum(t23_val_impto) tot_iva1
	from talt023, talt028, cxct001
	where t23_compania           = 1
	  and t23_localidad          = v_cod_loc
	  and t23_estado             = 'D'
	  and year(t23_fec_factura)  = v_anio
	  and month(t23_fec_factura) = v_mes
	  and t28_compania           = t23_compania
	  and t28_localidad          = t23_localidad
	  and t28_ot_ant             = t23_orden
	  and date(t28_fec_factura)  = date(t28_fec_anula)
	  and z01_codcli             = t23_cod_cliente
	group by 1, 2
	into temp t9
update t2
	set subtotal = subtotal -
			(select subtotal1 from t9 where codcli = z01_codcli),
	    tot_iva  = tot_iva  -
			(select tot_iva1 from t9 where codcli = z01_codcli)
	where z01_codcli in (select codcli from t9)
drop table t9
select unique z01_codcli, z01_num_doc_id, count(*) cuantos
	from talt023, cxct001
	where t23_compania           = 1
	  and t23_localidad          = v_cod_loc
	  and t23_estado             in ('F', 'D')
	  and t23_num_factura        is not null
	  and year(t23_fec_factura)  = v_anio
	  and month(t23_fec_factura) = v_mes
	  and z01_codcli             = t23_cod_cliente
	group by 1, 2
	into temp t3
insert into t5
	select t2.z01_codcli, t2.z01_num_doc_id, sum(subtotal) subtot,
		sum(tot_iva) t_iva, cuantos
		from t2, t3
		where t2.z01_codcli = t3.z01_codcli
		group by 1, 2, 5
drop table t2
drop table t3
insert into t1 select * from t5
drop table t5

end function
