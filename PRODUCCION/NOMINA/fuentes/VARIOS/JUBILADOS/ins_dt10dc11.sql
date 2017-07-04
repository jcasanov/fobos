begin work;

	insert into rolt048
		select n48_compania cia, 'JU' proc, 'DT' lq,
			mdy(12, 01, 2009) fec_ini, mdy(11, 30, 2010) fec_fin,
			n48_cod_trab cod_trab, n48_estado est,
			n48_ano_proceso anio, n48_mes_proceso mes,
			n48_moneda mone, n48_paridad pari,
			case when mdy(12, 01, 2009) < n30_fec_jub
				then (mdy(11, 30, 2010) - n30_fec_jub) + 1
				else 360
			end dias,
			case when mdy(12, 01, 2009) < n30_fec_jub
				then NVL((select b13_valor_base
					from ctbt013
					where b13_compania    = n48_compania
					  and b13_tipo_comp   = n48_tipo_comp
					  and b13_num_comp    = n48_num_comp
					  and b13_valor_base  > 0
					  and b13_valor_base <> n48_val_jub_pat)
					, 0)
				else n48_val_jub_pat
			end * 12 tot_gan,
			case when mdy(12, 01, 2009) < n30_fec_jub
				then NVL((select b13_valor_base
					from ctbt013
					where b13_compania    = n48_compania
					  and b13_tipo_comp   = n48_tipo_comp
					  and b13_num_comp    = n48_num_comp
					  and b13_valor_base  > 0
					  and b13_valor_base <> n48_val_jub_pat)
					, 0)
				else n48_val_jub_pat
			end valor,
			n48_tipo_pago tip, n48_bco_empresa banco,
			n48_cta_empresa cta, n48_cta_trabaj cta_t,
			n48_tipo_comp tp, n48_num_comp num, n48_usuario usuario,
			extend(mdy(11, 30, 2010), year to second) fecing
	from rolt048, rolt030
	where n48_ano_proceso = 2010
	  and n48_mes_proceso = 12
	  and n30_compania    = n48_compania
	  and n30_cod_trab    = n48_cod_trab;

		select n48_compania cia, 'JU' proc, 'DC' lq,
			mdy(03, 01, 2010) fec_ini, mdy(02, 28, 2011) fec_fin,
			n48_cod_trab cod_trab, n48_estado est,
			n48_ano_proceso anio, n48_mes_proceso mes,
			n48_moneda mone, n48_paridad pari,
			case when mdy(03, 01, 2010) < n30_fec_jub
				then (mdy(02, 28, 2011) - n30_fec_jub) + 1
				else 360
			end dias,
			case when mdy(03, 01, 2010) < n30_fec_jub
				then NVL((select b13_valor_base
					from ctbt013
					where b13_compania    = n48_compania
					  and b13_tipo_comp   = n48_tipo_comp
					  and b13_num_comp    = n48_num_comp
					  and b13_valor_base  > 0
					  and b13_valor_base <> n48_val_jub_pat)
					, 0)
				else 264
			end tot_gan,
			case when mdy(03, 01, 2010) < n30_fec_jub
				then NVL((select b13_valor_base
					from ctbt013
					where b13_compania    = n48_compania
					  and b13_tipo_comp   = n48_tipo_comp
					  and b13_num_comp    = n48_num_comp
					  and b13_valor_base  > 0
					  and b13_valor_base <> n48_val_jub_pat)
					, 0)
				else 264
			end valor,
			n48_tipo_pago tip, n48_bco_empresa banco,
			n48_cta_empresa cta, n48_cta_trabaj cta_t,
			n48_tipo_comp tp, n48_num_comp num, n48_usuario usuario,
			extend(mdy(02, 28, 2011), year to second) fecing
	from rolt048, rolt030
	where n48_ano_proceso = 2011
	  and n48_mes_proceso = 3
	  and n48_cod_trab    not in (26, 33, 63)
	  and n30_compania    = n48_compania
	  and n30_cod_trab    = n48_cod_trab
	union
		select n48_compania cia, 'JU' proc, 'DC' lq,
			mdy(03, 01, 2010) fec_ini, mdy(02, 28, 2011) fec_fin,
			n48_cod_trab cod_trab, n48_estado est,
			n48_ano_proceso anio, n48_mes_proceso mes,
			n48_moneda mone, n48_paridad pari,
			case when mdy(03, 01, 2010) < n30_fec_jub
				then (mdy(02, 28, 2011) - n30_fec_jub) + 1
				else 360
			end dias,
			case when mdy(03, 01, 2010) < n30_fec_jub
				then NVL((select b13_valor_base
					from ctbt013
					where b13_compania    = n48_compania
					  and b13_tipo_comp   = n48_tipo_comp
					  and b13_num_comp    = n48_num_comp
					  and b13_valor_base  > 0
					  and b13_valor_base <> n48_val_jub_pat)
					, 0)
				else 264
			end tot_gan,
			case when mdy(03, 01, 2010) < n30_fec_jub
				then NVL((select b13_valor_base
					from ctbt013
					where b13_compania    = n48_compania
					  and b13_tipo_comp   = n48_tipo_comp
					  and b13_num_comp    = n48_num_comp
					  and b13_valor_base  > 0
					  and b13_valor_base <> n48_val_jub_pat)
					, 0)
				else 264
			end valor,
			n48_tipo_pago tip, n48_bco_empresa banco,
			n48_cta_empresa cta, n48_cta_trabaj cta_t,
			n48_tipo_comp tp, n48_num_comp num, n48_usuario usuario,
			extend(mdy(02, 28, 2011), year to second) fecing
	from rolt048, rolt030
	where n48_ano_proceso = 2011
	  and n48_mes_proceso = 2
	  and n48_cod_trab    in (26, 33, 63)
	  and n30_compania    = n48_compania
	  and n30_cod_trab    = n48_cod_trab
	into temp t1;

	insert into rolt048
		select * from t1;

commit work;

drop table t1;
