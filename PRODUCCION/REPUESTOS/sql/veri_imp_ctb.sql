--drop table t1;

create temp table t1
	(
		import		varchar(5,5),
		liq		varchar(5,5),
		pedido		varchar(8,5),
		val_liq_det	decimal(22,10),
		val_liq_cab	decimal(22,10),
		val_ctb		decimal(22,10),
		val_dif1	decimal(22,10),
		val_dif2	decimal(22,10)
	);

insert into t1
	select r19_num_tran, r29_numliq, r17_pedido,
		nvl(sum(r17_cantrec * r17_costuni_ing), 0),
		nvl(r28_tot_costimp, 0), nvl(abs(b13_valor_base), 0),
		0.00, 0.00
		from rept016, rept017, ctbt012, ctbt013, rept029,
			rept028, rept019
		where r16_estado    = 'P'
		  and r17_compania  = r16_compania
		  and r17_localidad = r16_localidad
		  and r17_pedido    = r16_pedido
		  and b12_compania  = r16_compania
		  --and b12_tipo_comp = 'DR'
		  and b12_origen    = 'A'
		  and b12_subtipo   = 15
		  and b13_compania  = b12_compania
		  and b13_tipo_comp = b12_tipo_comp
		  and b13_num_comp  = b12_num_comp
		  and b13_cuenta    = r16_aux_cont
		  and b13_pedido    = r16_pedido
		  and r29_compania  = r16_compania
		  and r29_localidad = r16_localidad
		  and r29_pedido    = r16_pedido
		  and r28_compania  = r29_compania
		  and r28_localidad = r29_localidad
		  and r28_numliq    = r29_numliq
		  and r19_compania  = r28_compania
		  and r19_localidad = r28_localidad
		  and r19_numliq    = r28_numliq
		group by 1, 2, 3, 5, 6, 7, 8;

update t1
	set val_dif1 = val_liq_det - val_ctb,
	    val_dif2 = val_liq_cab - val_ctb
	where 1 = 1;

select count(*) tot_reg from t1;
select count(*) tot_reg_dif from t1 where val_dif1 <> 0;
select * from t1 where val_dif1 <> 0 order by val_dif1, pedido;
unload to "import_serm.unl"
	select * from t1 where val_dif1 <> 0 order by val_dif1, pedido;

drop table t1;
