select r38_compania cia, r38_localidad loc, r38_tipo_doc td,
	r38_tipo_fuente tf, r38_cod_tran cod_t, r38_num_tran num_t,
	r38_num_sri[1, 10] || "00" || r38_num_sri[11, 15] num_sri
	from rept038
	where r38_compania  = 1
	  and r38_localidad = 1
	  and r38_cod_tran  = 'FA'
	  and exists (select 1 from rept019
			where r19_compania   = r38_compania
			  and r19_localidad  = r38_localidad
			  and r19_cod_tran   = r38_cod_tran
			  and r19_num_tran   = r38_num_tran
			  and r19_fecing    >= '2011-06-13 09:41:16')
	  and length(r38_num_sri) < 17
union
select r38_compania cia, r38_localidad loc, r38_tipo_doc td,
	r38_tipo_fuente tf, r38_cod_tran cod_t, r38_num_tran num_t,
	r38_num_sri[1, 10] || "00" || r38_num_sri[11, 15] num_sri
	from rept038
	where r38_compania    = 1
	  and r38_localidad   = 1
	  and r38_tipo_fuente = 'OT'
	  and r38_cod_tran    = 'FA'
	  and exists (select 1 from talt023
			where t23_compania     = r38_compania
			  and t23_localidad    = r38_localidad
			  and t23_num_factura  = r38_num_tran
			  and t23_fec_factura >= '2011-06-13 09:41:16')
	  and length(r38_num_sri) < 17
	into temp t1;
select * from t1 order by num_sri;
begin work;
	update rept038
		set r38_num_sri = (select num_sri
					from t1
					where cia   = r38_compania
					  and loc   = r38_localidad
					  and td    = r38_tipo_doc
					  and tf    = r38_tipo_fuente
					  and cod_t = r38_cod_tran
					  and num_t = r38_num_tran)
		where r38_compania  = 1
		  and r38_localidad = 1
		  and r38_cod_tran  = 'FA'
		  and exists (select 1 from t1
				where cia   = r38_compania
				  and loc   = r38_localidad
				  and td    = r38_tipo_doc
				  and tf    = r38_tipo_fuente
				  and cod_t = r38_cod_tran
				  and num_t = r38_num_tran);
--rollback work;
commit work;
drop table t1;
