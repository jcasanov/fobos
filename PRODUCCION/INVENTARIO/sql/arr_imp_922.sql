select r19_compania cia, r19_localidad loc, r19_cod_tran tp, r19_num_tran num,
	r20_bodega bd, r20_item item, r20_cant_ven cant, r20_stock_ant sto_ant,
	r20_costant_mb cos_ant, r20_costnue_mb cos_nue, r19_numliq num_l
	from rept019, rept020
	where r19_compania  = 1
	  and r19_localidad = 3
	  and r19_cod_tran  = 'IM'
	  and r19_numliq    = 922
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	into temp t1;

select * from t1;

begin work;

	update rept010
		set r10_costo_mb   = nvl(r10_costrepo_mb, 0),
		    r10_costult_mb = nvl(r10_costrepo_mb, 0)
		where r10_compania = 1
		  and r10_codigo   in
			(select item
				from t1
				where cia  = r10_compania
				  and item = r10_codigo);

	update rept010
		set r10_costrepo_mb = (select cos_ant
					from t1
					where cia  = r10_compania
					  and item = r10_codigo)
		where r10_compania = 1
		  and r10_codigo   in
			(select item
				from t1
				where cia  = r10_compania
				  and item = r10_codigo);

	update rept011
		set r11_stock_act = r11_stock_act -
					(select cant
						from t1
						where cia  = r11_compania
						  and bd   = r11_bodega
						  and item = r11_item),
		    r11_stock_ant = (select sto_ant
					from t1
					where cia  = r11_compania
					  and bd   = r11_bodega
					  and item = r11_item)
		where r11_compania = 1
		  and exists
			(select 1 from t1
				where cia  = r11_compania
				  and bd   = r11_bodega
				  and item = r11_item);

	update rept016
		set r16_estado = 'L'
		where r16_compania  = 1
		  and r16_localidad = 3
		  and r16_pedido    in
			(select r29_pedido
				from rept029
				where r29_compania  = r16_compania
				  and r29_localidad = r16_localidad
				  and r29_numliq    in
						(select unique num_l from t1));

	update rept017
		set r17_estado = 'L'
		where r17_compania  = 1
		  and r17_localidad = 3
		  and r17_pedido    in
			(select r29_pedido
				from rept029
				where r29_compania  = r17_compania
				  and r29_localidad = r17_localidad
				  and r29_numliq    in
						(select unique num_l from t1));

	update rept028
		set r28_estado = 'A'
		where r28_compania  = 1
		  and r28_localidad = 3
		  and r28_numliq    in (select unique num_l from t1);

	delete from rept020
		where r20_compania  = 1
		  and r20_localidad = 3
		  and exists
			(select 1 from t1
				where cia = r20_compania
				  and loc = r20_localidad
				  and tp  = r20_cod_tran
				  and num = r20_num_tran);

	delete from rept019
		where r19_compania  = 1
		  and r19_localidad = 3
		  and exists
			(select 1 from t1
				where cia = r19_compania
				  and loc = r19_localidad
				  and tp  = r19_cod_tran
				  and num = r19_num_tran);

--rollback work;
commit work;

drop table t1;
