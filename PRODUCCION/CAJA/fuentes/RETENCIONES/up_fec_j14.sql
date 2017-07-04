select j14_compania cia, j14_localidad loc, j14_tipo_fuente tipo,
	j14_num_fuente num, j14_cod_tran cod_t, j14_num_tran num_t,
	j14_num_ret_sri reten, j14_fec_emi_fact fecha, z20_fecha_emi,
	j14_tipo_fue tf
	from cajt014, cxct020
	where j14_tipo_fuente  = 'SC'
	  and j14_tipo_fue     = 'PR'
	  and z20_compania     = j14_compania
	  and z20_localidad    = j14_localidad
	  and z20_tipo_doc     = 'FA'
	  and z20_areaneg      = 1
	  and z20_cod_tran     = j14_cod_tran
	  and z20_num_tran     = j14_num_tran
	  and z20_fecha_emi   <> j14_fec_emi_fact
union
select j14_compania cia, j14_localidad loc, j14_tipo_fuente tipo,
	j14_num_fuente num, j14_cod_tran cod_t, j14_num_tran num_t,
	j14_num_ret_sri reten, j14_fec_emi_fact fecha, z20_fecha_emi,
	j14_tipo_fue tf
	from cajt014, cxct020
	where j14_tipo_fuente  = 'SC'
	  and j14_tipo_fue     = 'OT'
	  and z20_compania     = j14_compania
	  and z20_localidad    = j14_localidad
	  and z20_tipo_doc     = 'FA'
	  and z20_areaneg      = 2
	  and z20_cod_tran     = j14_cod_tran
	  and z20_num_tran     = j14_num_tran
	  and z20_fecha_emi   <> j14_fec_emi_fact
	into temp t1;
select count(*) tot_reg from t1;
select tipo, num, reten, fecha, z20_fecha_emi from t1 order by z20_fecha_emi;
{--
begin work;
	update cajt014
		set j14_fec_emi_fact =
			(select z20_fecha_emi from t1
				where cia   = j14_compania
				  and loc   = j14_localidad
				  and tipo  = j14_tipo_fuente
				  and num   = j14_num_fuente
				  and tf    = j14_tipo_fue
				  and cod_t = j14_cod_tran
				  and num_t = j14_num_tran
				  and reten = j14_num_ret_sri
				  and fecha = j14_fec_emi_fact)
	where j14_tipo_fuente  = 'SC'
	  and exists
		(select reten from t1
			where cia   = j14_compania
			  and loc   = j14_localidad
			  and tipo  = j14_tipo_fuente
			  and num   = j14_num_fuente
			  and tf    = j14_tipo_fue
			  and cod_t = j14_cod_tran
			  and num_t = j14_num_tran
			  and fecha = j14_fec_emi_fact);
commit work;
--}
drop table t1;
