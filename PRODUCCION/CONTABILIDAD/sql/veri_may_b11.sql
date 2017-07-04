select b12_compania as cia, b13_cuenta as cuenta,
	nvl(sum(b13_valor_base), 0.00) saldo
	from ctbt012, ctbt013
	where b12_compania           = 1
	  and b12_estado             = 'M'
	  and year(b13_fec_proceso) <= 2010
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b13_valor_base        <> 0
	group by 1, 2
	into temp tmp_sal;
select b11_ano as anio, cuenta, saldo, ((b11_db_ano_ant +
					b11_db_mes_01 +
					b11_db_mes_02 +
					b11_db_mes_03 +
					b11_db_mes_04 +
					b11_db_mes_05 +
					b11_db_mes_06 +
					b11_db_mes_07 +
					b11_db_mes_08 +
					b11_db_mes_09 +
					b11_db_mes_10 +
					b11_db_mes_11 +
					b11_db_mes_12) -
				      (b11_cr_ano_ant +
					b11_cr_mes_01 +
					b11_cr_mes_02 +
					b11_cr_mes_03 +
					b11_cr_mes_04 +
					b11_cr_mes_05 +
					b11_cr_mes_06 +
					b11_cr_mes_07 +
					b11_cr_mes_08 +
					b11_cr_mes_09 +
					b11_cr_mes_10 +
					b11_cr_mes_11 +
					b11_cr_mes_12)) as sal_b11
	from ctbt011, tmp_sal
	where b11_compania      = cia
	  and b11_cuenta        = cuenta
	  and b11_ano           = 2010
	  and ((b11_db_ano_ant +
		b11_db_mes_01 +
		b11_db_mes_02 +
		b11_db_mes_03 +
		b11_db_mes_04 +
		b11_db_mes_05 +
		b11_db_mes_06 +
		b11_db_mes_07 +
		b11_db_mes_08 +
		b11_db_mes_09 +
		b11_db_mes_10 +
		b11_db_mes_11 +
		b11_db_mes_12) -
	      (b11_cr_ano_ant +
		b11_cr_mes_01 +
		b11_cr_mes_02 +
		b11_cr_mes_03 +
		b11_cr_mes_04 +
		b11_cr_mes_05 +
		b11_cr_mes_06 +
		b11_cr_mes_07 +
		b11_cr_mes_08 +
		b11_cr_mes_09 +
		b11_cr_mes_10 +
		b11_cr_mes_11 +
		b11_cr_mes_12)) <> saldo
	into temp t1;
drop table tmp_sal;
select * from t1 order by anio, cuenta;
drop table t1;
