select r02_codigo, g02_nombre
	from acero_gm:rept002, acero_gm:gent002
	where r02_compania  = 1
	  and g02_compania  = r02_compania
	  and g02_localidad = r02_localidad
	into temp tmp_bod;
select (select g02_nombre from tmp_bod
		where r02_codigo = r91_bodega_ori) local_ori,
	(select g02_nombre from tmp_bod
		where r02_codigo = r91_bodega_dest) local_dest,
	acero_gm:rept092.*
	from acero_gm:rept091, acero_gm:rept092
	where r91_compania     = 1
	  and r91_localidad    in (2, 3)
	  and r91_cod_tran     = 'TR'
	  and date(r91_fecing) between mdy(10, 01, 2006) and mdy(10, 31, 2006)
	  and r92_compania     = r91_compania
	  and r92_localidad    = r91_localidad
	  and r92_cod_tran     = r91_cod_tran
	  and r92_num_tran     = r91_num_tran
	into temp tmp_gm;
drop table tmp_bod;
select r02_codigo, g02_nombre
	from acero_gc:rept002, acero_gc:gent002
	where r02_compania  = 1
	  and g02_compania  = r02_compania
	  and g02_localidad = r02_localidad
	into temp tmp_bod;
select (select g02_nombre from tmp_bod
		where r02_codigo = r91_bodega_ori) local_ori,
	(select g02_nombre from tmp_bod
		where r02_codigo = r91_bodega_dest) local_dest,
	acero_gc:rept092.*
	from acero_gc:rept091, acero_gc:rept092
	where r91_compania     = 1
	  and r91_localidad    = 1
	  and r91_cod_tran     = 'TR'
	  and date(r91_fecing) between mdy(10, 01, 2006) and mdy(10, 31, 2006)
	  and r92_compania     = r91_compania
	  and r92_localidad    = r91_localidad
	  and r92_cod_tran     = r91_cod_tran
	  and r92_num_tran     = r91_num_tran
	into temp tmp_gc;
drop table tmp_bod;
select r02_codigo, g02_nombre
	from acero_qm:rept002, acero_qm:gent002
	where r02_compania  = 1
	  and g02_compania  = r02_compania
	  and g02_localidad = r02_localidad
	into temp tmp_bod;
select (select g02_nombre from tmp_bod
		where r02_codigo = r91_bodega_ori) local_ori,
	(select g02_nombre from tmp_bod
		where r02_codigo = r91_bodega_dest) local_dest,
	acero_qm:rept092.*
	from acero_qm:rept091, acero_qm:rept092
	where r91_compania     = 1
	  and r91_localidad    in (1, 4)
	  and r91_cod_tran     = 'TR'
	  and date(r91_fecing) between mdy(10, 01, 2006) and mdy(10, 31, 2006)
	  and r92_compania     = r91_compania
	  and r92_localidad    = r91_localidad
	  and r92_cod_tran     = r91_cod_tran
	  and r92_num_tran     = r91_num_tran
	into temp tmp_qm;
drop table tmp_bod;
select r02_codigo, g02_nombre
	from acero_qs:rept002, acero_qs:gent002
	where r02_compania  = 1
	  and g02_compania  = r02_compania
	  and g02_localidad = r02_localidad
	into temp tmp_bod;
select (select g02_nombre from tmp_bod
		where r02_codigo = r91_bodega_ori) local_ori,
	(select g02_nombre from tmp_bod
		where r02_codigo = r91_bodega_dest) local_dest,
	acero_qs:rept092.*
	from acero_qs:rept091, acero_qs:rept092
	where r91_compania     = 1
	  and r91_localidad    = 3
	  and r91_cod_tran     = 'TR'
	  and date(r91_fecing) between mdy(10, 01, 2006) and mdy(10, 31, 2006)
	  and r92_compania     = r91_compania
	  and r92_localidad    = r91_localidad
	  and r92_cod_tran     = r91_cod_tran
	  and r92_num_tran     = r91_num_tran
	into temp tmp_qs;
drop table tmp_bod;
select local_ori, local_dest, date(r92_fecing) fecha_emi,r92_cant_ven cantidad,
	r92_item[1, 7] item, r72_desc_clase clase, r10_nombre nombre,
	r92_precio precio, r92_cant_ven * r92_precio tot_precio
	from tmp_gm, acero_gm:rept010, acero_gm:rept072
	where r10_compania     = r92_compania
	  and r10_codigo       = r92_item
	  and r72_compania     = r10_compania
	  and r72_linea        = r10_linea
	  and r72_sub_linea    = r10_sub_linea
	  and r72_cod_grupo    = r10_cod_grupo
	  and r72_cod_clase    = r10_cod_clase
union all
select local_ori, local_dest, date(r92_fecing) fecha_emi,r92_cant_ven cantidad,
	r92_item[1, 7] item, r72_desc_clase clase, r10_nombre nombre,
	r92_precio precio, r92_cant_ven * r92_precio tot_precio
	from tmp_gc, acero_gc:rept010, acero_gc:rept072
	where r10_compania     = r92_compania
	  and r10_codigo       = r92_item
	  and r72_compania     = r10_compania
	  and r72_linea        = r10_linea
	  and r72_sub_linea    = r10_sub_linea
	  and r72_cod_grupo    = r10_cod_grupo
	  and r72_cod_clase    = r10_cod_clase
union all
select local_ori, local_dest, date(r92_fecing) fecha_emi,r92_cant_ven cantidad,
	r92_item[1, 7] item, r72_desc_clase clase, r10_nombre nombre,
	r92_precio precio, r92_cant_ven * r92_precio tot_precio
	from tmp_qm, acero_qm:rept010, acero_qm:rept072
	where r10_compania     = r92_compania
	  and r10_codigo       = r92_item
	  and r72_compania     = r10_compania
	  and r72_linea        = r10_linea
	  and r72_sub_linea    = r10_sub_linea
	  and r72_cod_grupo    = r10_cod_grupo
	  and r72_cod_clase    = r10_cod_clase
union all
select local_ori, local_dest, date(r92_fecing) fecha_emi,r92_cant_ven cantidad,
	r92_item[1, 7] item, r72_desc_clase clase, r10_nombre nombre,
	r92_precio precio, r92_cant_ven * r92_precio tot_precio
	from tmp_qs, acero_qs:rept010, acero_qs:rept072
	where r10_compania     = r92_compania
	  and r10_codigo       = r92_item
	  and r72_compania     = r10_compania
	  and r72_linea        = r10_linea
	  and r72_sub_linea    = r10_sub_linea
	  and r72_cod_grupo    = r10_cod_grupo
	  and r72_cod_clase    = r10_cod_clase
	into temp tmp_guia;
drop table tmp_gm;
drop table tmp_gc;
drop table tmp_qm;
drop table tmp_qs;
select count(*) tot_gen from tmp_guia;
select local_ori, local_dest, count(*) tot_loc
	from tmp_guia
	group by 1, 2
	order by 1, 2;
unload to "guia_oct2006.unl"
	select local_ori, local_dest, fecha_emi, cantidad, item,
	clase || " " || nombre, precio, tot_precio
	from tmp_guia
	order by 1, 2;
select * from tmp_guia order by fecha_emi;
drop table tmp_guia;
