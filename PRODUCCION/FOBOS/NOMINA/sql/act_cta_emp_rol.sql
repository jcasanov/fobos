select n30_num_doc_id cedula, n30_cta_trabaj ctaemp
	from rolt030
	where n30_compania = 999
	into temp tmp_cta;

load from "ctaemp.unl" insert into tmp_cta;

select count(*) tot_cta from tmp_cta;

select n30_compania cia, n30_cod_trab cod_t, n30_nombres empleado, cedula,
	'T' tipo_p, 19 banco, '1030843017' cuenta, 'A' tipo_c, ctaemp
	from rolt030, tmp_cta
	where n30_compania   = 1
	  and n30_estado     = 'A'
	  and n30_num_doc_id = cedula
	into temp tmp_emp;

drop table tmp_cta;

select count(*) tot_emp from tmp_emp;

--select * from tmp_emp order by empleado;

begin work;

	update rolt030
		set n30_tipo_pago    = (select tipo_p
					from tmp_emp
					where cia   = n30_compania
					  and cod_t = n30_cod_trab),
		    n30_bco_empresa  = (select banco
					from tmp_emp
					where cia   = n30_compania
					  and cod_t = n30_cod_trab),
		    n30_cta_empresa  = (select cuenta
					from tmp_emp
					where cia   = n30_compania
					  and cod_t = n30_cod_trab),
		    n30_tipo_cta_tra = (select tipo_c
					from tmp_emp
					where cia   = n30_compania
					  and cod_t = n30_cod_trab),
		    n30_cta_trabaj   = (select ctaemp
					from tmp_emp
					where cia   = n30_compania
					  and cod_t = n30_cod_trab)
		where n30_compania  = 1
		  and n30_cod_trab in (select cod_t
					from tmp_emp
					where cia = n30_compania);

	update rolt036
		set n36_tipo_pago    = (select tipo_p
					from tmp_emp
					where cia   = n36_compania
					  and cod_t = n36_cod_trab),
		    n36_bco_empresa  = (select banco
					from tmp_emp
					where cia   = n36_compania
					  and cod_t = n36_cod_trab),
		    n36_cta_empresa  = (select cuenta
					from tmp_emp
					where cia   = n36_compania
					  and cod_t = n36_cod_trab),
		    n36_cta_trabaj   = (select ctaemp
					from tmp_emp
					where cia   = n36_compania
					  and cod_t = n36_cod_trab)
		where n36_compania   = 1
		  and n36_proceso    = 'DT'
		  and n36_fecha_ini  = mdy(12, 01, 2007)
		  and n36_fecha_fin  = mdy(11, 30, 2008)
		  and n36_cod_trab  in (select cod_t
					from tmp_emp
					where cia = n36_compania);

commit work;

drop table tmp_emp;
