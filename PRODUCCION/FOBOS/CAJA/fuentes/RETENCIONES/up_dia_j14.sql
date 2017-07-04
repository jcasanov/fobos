select j14_compania cia, j14_localidad loc, j14_tipo_fuente tipo,
	j14_num_fuente num, j14_cod_tran cod_t, j14_num_tran num_t,
	j14_num_ret_sri reten, j14_fecing fecha
	from cajt014
	where j14_tipo_comp is null
	into temp t1;
select count(*) tot_t1 from t1;
select t1.*, r40_tipo_comp tp, r40_num_comp num_d
	from t1, rept040, ctbt012
	where tipo          = 'PR'
	  and r40_compania  = cia
	  and r40_localidad = loc
	  and r40_cod_tran  = cod_t
	  and r40_num_tran  = num_t
	  and b12_compania  = r40_compania
	  and b12_tipo_comp = r40_tipo_comp
	  and b12_num_comp  = r40_num_comp
	  and b12_subtipo   = 8
union
select t1.*, t50_tipo_comp tp, t50_num_comp num_d
	from t1, talt050, ctbt012
	where tipo          = 'OT'
	  and t50_compania  = cia
	  and t50_localidad = loc
	  and t50_orden     = num
	  and t50_factura   = num_t
	  and b12_compania  = t50_compania
	  and b12_tipo_comp = t50_tipo_comp
	  and b12_num_comp  = t50_num_comp
	  and b12_subtipo   = 41
union
select t1.*, z40_tipo_comp tp, z40_num_comp num_d
	from t1, cajt010, cxct040
	where tipo            = 'SC'
	  and j10_compania    = cia
	  and j10_localidad   = loc
	  and j10_tipo_fuente = tipo
	  and j10_num_fuente  = num
	  and z40_compania    = j10_compania
	  and z40_localidad   = j10_localidad
	  and z40_codcli      = j10_codcli
	  and z40_tipo_doc    = j10_tipo_destino
	  and z40_num_doc     = j10_num_destino
	into temp t2;
drop table t1;
select count(*) tot_reg from t2;
select tipo, num, cod_t, num_t, reten, fecha from t2 order by fecha;
{--
begin work;
	update cajt014
		set j14_tipo_comp =
			(select unique tp from t2
				where cia   = j14_compania
				  and loc   = j14_localidad
				  and tipo  = j14_tipo_fuente
				  and num   = j14_num_fuente
				  and reten = j14_num_ret_sri),
		    j14_num_comp  =
			(select unique num_d from t2
				where cia   = j14_compania
				  and loc   = j14_localidad
				  and tipo  = j14_tipo_fuente
				  and num   = j14_num_fuente
				  and reten = j14_num_ret_sri)
	where j14_tipo_comp is null
	  and exists
		(select unique reten
			from t2
			where cia   = j14_compania
			  and loc   = j14_localidad
			  and tipo  = j14_tipo_fuente
			  and num   = j14_num_fuente);
commit work;
--}
drop table t2;
