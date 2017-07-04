select z20_compania cia, z20_localidad loc, z20_codcli cli, z20_tipo_doc tipo,
	z20_num_doc num, z20_dividendo divi, z20_cod_tran cod_t,
	z20_num_tran num_t, r26_numprev numprev,
	z20_fecha_emi fec_emi, z20_fecha_vcto fec_v,
	(z20_fecha_vcto + 30 units day) fec_vcto
	from cxct020, rept025, rept026
	where  z20_compania                    = 1
	  and  z20_localidad                   = 1
	  and  z20_codcli                      = 2951
	  and (z20_saldo_cap + z20_saldo_int)  > 0
	  and (z20_fecha_vcto - z20_fecha_emi) = 30
	  and  r25_compania                    = z20_compania
	  and  r25_localidad                   = z20_localidad
	  and  r25_cod_tran                    = z20_cod_tran
	  and  r25_num_tran                    = z20_num_tran
	  and  r26_compania                    = r25_compania
	  and  r26_localidad                   = r25_localidad
	  and  r26_numprev                     = r25_numprev
	  and  r26_dividendo                   = z20_dividendo
	into temp t1;
select count(*) tot_reg from t1;
select * from t1;
begin work;
	update cxct020
		set z20_fecha_vcto = (select fec_vcto
					from t1
					where cia  = z20_compania
					  and loc  = z20_localidad
					  and cli  = z20_codcli
					  and tipo = z20_tipo_doc
					  and num  = z20_num_doc
					  and divi = z20_dividendo)
	where z20_compania  = 1
	  and z20_localidad = 1
	  and z20_codcli    = 2951
	  and exists
		(select 1 from t1
			where cia  = z20_compania
			  and loc  = z20_localidad
			  and cli  = z20_codcli
			  and tipo = z20_tipo_doc
			  and num  = z20_num_doc
			  and divi = z20_dividendo);
	update rept026
		set r26_fec_vcto = (select fec_vcto
					from t1
					where cia     = r26_compania
					  and loc     = r26_localidad
					  and numprev = r26_numprev
					  and divi    = r26_dividendo)
	where r26_compania  = 1
	  and r26_localidad = 1
	  and exists
		(select 1 from t1
			where cia     = r26_compania
			  and loc     = r26_localidad
			  and numprev = r26_numprev
			  and divi    = r26_dividendo);
--rollback work;
commit work;
drop table t1;
