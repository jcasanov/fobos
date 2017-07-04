select p23_compania cia1, p23_localidad loc1, p23_codprov cp1,
	p23_tipo_trn tt1, p23_num_trn num1, p23_tipo_doc td1,
	p23_num_doc num_d1, p23_div_doc div1, p23_valor_cap val_c1,
	p23_valor_int val_i1
	from cxpt023
	where p23_compania  = 1
	  and p23_localidad = 1
	  and p23_codprov   = 1057
	  and p23_tipo_trn  = "PG"
	  and p23_num_trn   = 11642
	into temp t1;

begin work;

	update cxpt023
		set p23_valor_cap = (select val_c1 * (-1)
					from t1
					where cia1   = p23_compania
					  and loc1   = p23_localidad
					  and cp1    = p23_codprov
					  and td1    = p23_tipo_doc
					  and num_d1 = p23_num_doc
					  and div1   = p23_div_doc),
		    p23_valor_int = (select val_i1 * (-1)
					from t1
					where cia1   = p23_compania
					  and loc1   = p23_localidad
					  and cp1    = p23_codprov
					  and td1    = p23_tipo_doc
					  and num_d1 = p23_num_doc
					  and div1   = p23_div_doc)
		where p23_compania  = 1
		  and p23_localidad = 1
		  and p23_codprov   = 1057
		  and p23_tipo_trn  = "AJ"
		  and p23_num_trn   = 23724;

	select cia1, loc1, cp1, td1, num_d1, div1,
		sum(p23_valor_cap) sal_c1, sum(p23_valor_int) sal_i1
		from t1, cxpt023
		where cia1   = p23_compania
		  and loc1   = p23_localidad
		  and cp1    = p23_codprov
		  and td1    = p23_tipo_doc
		  and num_d1 = p23_num_doc
		  and div1   = p23_div_doc
		group by 1, 2, 3, 4, 5, 6
		into temp t2;

	drop table t1;

	update cxpt023
		set p23_saldo_cap = (p23_valor_cap + (select sal_c1
					from t2
					where cia1   = p23_compania
					  and loc1   = p23_localidad
					  and cp1    = p23_codprov
					  and td1    = p23_tipo_doc
					  and num_d1 = p23_num_doc
					  and div1   = p23_div_doc)) * (-1),
		    p23_saldo_int = (p23_valor_int + (select sal_i1
					from t2
					where cia1   = p23_compania
					  and loc1   = p23_localidad
					  and cp1    = p23_codprov
					  and td1    = p23_tipo_doc
					  and num_d1 = p23_num_doc
					  and div1   = p23_div_doc)) * (-1)
		where p23_compania  = 1
		  and p23_localidad = 1
		  and p23_codprov   = 1057
		  and p23_tipo_trn  = "AJ"
		  and p23_num_trn   = 23724;

	update cxpt020
		set p20_saldo_cap = (select sal_c1 * (-1)
					from t2
					where cia1   = p20_compania
					  and loc1   = p20_localidad
					  and cp1    = p20_codprov
					  and td1    = p20_tipo_doc
					  and num_d1 = p20_num_doc
					  and div1   = p20_dividendo),
		    p20_saldo_int = (select sal_i1 * (-1)
					from t2
					where cia1   = p20_compania
					  and loc1   = p20_localidad
					  and cp1    = p20_codprov
					  and td1    = p20_tipo_doc
					  and num_d1 = p20_num_doc
					  and div1   = p20_dividendo)
		where p20_compania  = 1
		  and p20_localidad = 1
		  and p20_codprov   = 1057
		  and exists
			(select 1 from t2
				where cia1   = p20_compania
				  and loc1   = p20_localidad
				  and cp1    = p20_codprov
				  and td1    = p20_tipo_doc
				  and num_d1 = p20_num_doc
				  and div1   = p20_dividendo);

--rollback work;
commit work;

drop table t2;
