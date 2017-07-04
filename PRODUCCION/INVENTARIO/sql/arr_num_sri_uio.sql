select r38_compania cia, r38_localidad loc, r38_cod_tran cod, r38_num_tran num,
	r38_num_sri n_ant,
	case when r38_num_sri[14, 15] = '47'
		then r38_num_sri[01, 13] || '53' || r38_num_sri[16, 17]
	     when r38_num_sri[14, 15] = '48'
		then r38_num_sri[01, 13] || '54' || r38_num_sri[16, 17]
	     when r38_num_sri[14, 15] = '49'
		then r38_num_sri[01, 13] || '55' || r38_num_sri[16, 17]
	     when r38_num_sri[14, 15] = '50'
		then r38_num_sri[01, 13] || '56' || r38_num_sri[16, 17]
	     when r38_num_sri[14, 15] = '51'
		then r38_num_sri[01, 13] || '57' || r38_num_sri[16, 17]
	     when r38_num_sri[14, 15] = '52'
		then r38_num_sri[01, 13] || '58' || r38_num_sri[16, 17]
	end n_nue
	from rept038
	where r38_compania  = 1
	  and r38_localidad = 3
	  and r38_num_tran  between 200883 and 201364
	  and r38_num_sri   <> '004-001-000105464'
	into temp t1;
--select cod, num, n_ant, n_nue from t1 where n_nue is null order by 2;
begin work;
	update rept038
		set r38_num_sri = (select n_nue
					from t1
					where cia = r38_compania
					  and loc = r38_localidad
					  and cod = r38_cod_tran
					  and num = r38_num_tran)
		where r38_compania  = 1
		  and r38_localidad = 3
		  and r38_num_tran  in
			(select num
				from t1
				where cia = r38_compania
				  and loc = r38_localidad
				  and cod = r38_cod_tran
				  and num = r38_num_tran);
--rollback work;
commit work;
drop table t1;
