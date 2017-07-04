set isolation to dirty read;

select * from rept010
	where r10_compania = 1
	  and r10_codigo   = '26045'
	into temp t_r10_1;
select * from rept010
	where r10_compania = 1
	  and r10_codigo   = '26145'
	into temp t_r10_2;

select *, r11_item item_a
	from rept011
	where r11_compania  = 1
	  and r11_bodega   in (select r02_codigo
				from rept002
				where r02_compania   = r11_compania
				  and r02_localidad in (1, 2))
	  and r11_item      = '26045'
	into temp t_r11_1;
select *, r11_item item_a
	from rept011
	where r11_compania  = 1
	  and r11_bodega   in (select r02_codigo
				from rept002
				where r02_compania   = r11_compania
				  and r02_localidad in (1, 2))
	  and r11_item      = '26145'
	into temp t_r11_2;

select *, r31_item item_a
	from rept031
	where r31_compania  = 1
	  and r31_bodega   in (select r02_codigo
				from rept002
				where r02_compania   = r31_compania
				  and r02_localidad in (1, 2))
	  and r31_item      = '26045'
	into temp t_r31_1;
select *, r31_item item_a
	from rept031
	where r31_compania  = 1
	  and r31_bodega   in (select r02_codigo
				from rept002
				where r02_compania   = r31_compania
				  and r02_localidad in (1, 2))
	  and r31_item      = '26145'
	into temp t_r31_2;

select *, r11_item item_a
	from resp_exis
	where r11_compania  = 1
	  and r11_bodega   in (select r02_codigo
				from rept002
				where r02_compania   = r11_compania
				  and r02_localidad in (1, 2))
	  and r11_item      = '26045'
	into temp t_res_1;
select *, r11_item item_a
	from resp_exis
	where r11_compania  = 1
	  and r11_bodega   in (select r02_codigo
				from rept002
				where r02_compania   = r11_compania
				  and r02_localidad in (1, 2))
	  and r11_item      = '26145'
	into temp t_res_2;

select r23_compania cia, r23_localidad loc, r23_numprof numprof,
	r23_numprev numprev, r23_cod_tran cod, r23_num_tran num, r24_item item,
	'26045' item_a
	from rept023, rept024
	where r23_compania   = 1
	  and r23_localidad in (1, 2)
	  and r24_compania   = r23_compania
	  and r24_localidad  = r23_localidad
	  and r24_numprev    = r23_numprev
	  and r24_item       = '26045'
	into temp t1;
select count(*) tot_t1 from t1;
select r23_compania cia, r23_localidad loc, r23_numprof numprof,
	r23_numprev numprev, r23_cod_tran cod, r23_num_tran num, r24_item item,
	'26145' item_a
	from rept023, rept024
	where r23_compania   = 1
	  and r23_localidad in (1, 2)
	  and r24_compania   = r23_compania
	  and r24_localidad  = r23_localidad
	  and r24_numprev    = r23_numprev
	  and r24_item       = '26145'
	into temp t2;
select count(*) tot_t2 from t2;
select r19_compania cia, r19_localidad loc, numprof, numprev, r19_cod_tran cod,
	r19_num_tran num, r20_bodega bod, r20_orden orden, r20_item item,
	'26045' item_a
	from rept019, rept020, outer t1
	where r19_compania   = 1
	  and r19_localidad in (1, 2)
	  and r20_compania   = r19_compania
	  and r20_localidad  = r19_localidad
	  and r20_cod_tran   = r19_cod_tran
	  and r20_num_tran   = r19_num_tran
	  and cia            = r20_compania
	  and loc            = r20_localidad
	  and cod            = r20_cod_tran
	  and num            = r20_num_tran
	  and r20_item       = '26045'
	into temp t3;
select count(*) tot_t3 from t3;
drop table t1;
select r19_compania cia, r19_localidad loc, numprof, numprev, r19_cod_tran cod,
	r19_num_tran num, r20_bodega bod, r20_orden orden, r20_item item,
	'26145' item_a
	from rept019, rept020, outer t2
	where r19_compania   = 1
	  and r19_localidad in (1, 2)
	  and r20_compania   = r19_compania
	  and r20_localidad  = r19_localidad
	  and r20_cod_tran   = r19_cod_tran
	  and r20_num_tran   = r19_num_tran
	  and cia            = r20_compania
	  and loc            = r20_localidad
	  and cod            = r20_cod_tran
	  and num            = r20_num_tran
	  and r20_item       = '26145'
	into temp t4;
select count(*) tot_t4 from t4;
drop table t2;

select * from te_stofis
	where te_compania   = 1
	  and te_item       = '26045'
	into temp t_sto_1;
select * from te_stofis
	where te_compania   = 1
	  and te_item       = '26145'
	into temp t_sto_2;

select * from rept092
	where r92_compania   = 1
	  and r92_item       = '26045'
	into temp t_r92_1;
select * from rept092
	where r92_compania   = 1
	  and r92_item       = '26145'
	into temp t_r92_2;

select * from rept089
	where r89_compania   = 1
	  and r89_localidad in (1, 2)
	  and r89_item       = '26045'
	into temp t_r89_1;
select * from rept089
	where r89_compania   = 1
	  and r89_localidad in (1, 2)
	  and r89_item       = '26145'
	into temp t_r89_2;

select * from rept087
	where r87_compania   = 1
	  and r87_localidad in (1, 2)
	  and r87_item       = '26045'
	into temp t_r87_1;
select * from rept087
	where r87_compania   = 1
	  and r87_localidad in (1, 2)
	  and r87_item       = '26145'
	into temp t_r87_2;

select * from rept086
	where r86_compania = 1
	  and r86_item     = '26045'
	into temp t_r86_1;
select * from rept086
	where r86_compania = 1
	  and r86_item     = '26145'
	into temp t_r86_2;

select * from rept012
	where r12_compania = 1
	  and r12_item     = '26045'
	into temp t_r12_1;
select * from rept012
	where r12_compania = 1
	  and r12_item     = '26145'
	into temp t_r12_2;

update t_r12_1 set r12_item = '26145' where 1 = 1;
update t_r12_2 set r12_item = '26045' where 1 = 1;
update t_r11_1 set r11_item = '26145' where 1 = 1;
update t_r11_2 set r11_item = '26045' where 1 = 1;
update t_res_1 set r11_item = '26145' where 1 = 1;
update t_res_2 set r11_item = '26045' where 1 = 1;
update t_r86_1 set r86_item = '26145' where 1 = 1;
update t_r86_2 set r86_item = '26045' where 1 = 1;
update t_r87_1 set r87_item = '26145' where 1 = 1;
update t_r87_2 set r87_item = '26045' where 1 = 1;
update t_r89_1 set r89_item = '26145' where 1 = 1;
update t_r89_2 set r89_item = '26045' where 1 = 1;
update t_r92_1 set r92_item = '26145' where 1 = 1;
update t_r92_2 set r92_item = '26045' where 1 = 1;
update t_sto_1 set te_item = '26145' where 1 = 1;
update t_sto_2 set te_item = '26045' where 1 = 1;

update t3 set item = '26145' where 1 = 1;
update t4 set item = '26045' where 1 = 1;

begin work;

delete from te_stofis
	where te_compania   = 1
	  and te_item      in ('26145', '26045');
insert into te_stofis select * from t_sto_1;
insert into te_stofis select * from t_sto_2;

delete from rept092
	where r92_compania   = 1
	  and r92_item      in ('26145', '26045');
insert into rept092 select * from t_r92_1;
insert into rept092 select * from t_r92_2;

delete from rept089
	where r89_compania   = 1
	  and r89_localidad in (1, 2)
	  and r89_item      in ('26145', '26045');
insert into rept089 select * from t_r89_1;
insert into rept089 select * from t_r89_2;

delete from rept087
	where r87_compania   = 1
	  and r87_localidad in (1, 2)
	  and r87_item      in ('26145', '26045');
insert into rept087 select * from t_r87_1;
insert into rept087 select * from t_r87_2;

delete from rept086
	where r86_compania = 1
	  and r86_item     in ('26145', '26045');
insert into rept086 select * from t_r86_1;
insert into rept086 select * from t_r86_2;

delete from rept012
	where r12_compania = 1
	  and r12_item     in ('26145', '26045');
insert into rept012 select * from t_r12_1;
insert into rept012 select * from t_r12_2;

delete from resp_exis
	where r11_compania  = 1
	  and r11_bodega   in (select unique a.r11_bodega
				from t_res_1 a
				where a.r11_compania = resp_exis.r11_compania
				  and a.r11_bodega   = resp_exis.r11_bodega)
	  and r11_item      = '26045'
	  and exists (select 1 from t_res_1 a
			where a.r11_compania = resp_exis.r11_compania
			  and a.r11_bodega   = resp_exis.r11_bodega
			  and a.item_a       = resp_exis.r11_item);
delete from resp_exis
	where r11_compania  = 1
	  and r11_bodega   in (select unique a.r11_bodega
				from t_res_2 a
				where a.r11_compania = resp_exis.r11_compania
				  and a.r11_bodega   = resp_exis.r11_bodega)
	  and r11_item      = '26145'
	  and exists (select 1 from t_res_2 a
			where a.r11_compania = resp_exis.r11_compania
			  and a.r11_bodega   = resp_exis.r11_bodega
			  and a.item_a       = resp_exis.r11_item);
insert into resp_exis
	select a.r11_compania, a.r11_bodega, a.r11_item, a.r11_ubicacion,
		a.r11_ubica_ant, a.r11_stock_ant, a.r11_stock_act,
		a.r11_ing_dia, a.r11_egr_dia, a.r11_fec_ultvta,
		a.r11_tip_ultvta, a.r11_num_ultvta, a.r11_fec_ulting,
		a.r11_tip_ulting, a.r11_num_ulting, a.r11_fec_corte
	from t_res_1 a;
insert into resp_exis
	select a.r11_compania, a.r11_bodega, a.r11_item, a.r11_ubicacion,
		a.r11_ubica_ant, a.r11_stock_ant, a.r11_stock_act,
		a.r11_ing_dia, a.r11_egr_dia, a.r11_fec_ultvta,
		a.r11_tip_ultvta, a.r11_num_ultvta, a.r11_fec_ulting,
		a.r11_tip_ulting, a.r11_num_ulting, a.r11_fec_corte
	from t_res_2 a;

delete from rept031
	where r31_compania  = 1
	  and r31_bodega   in (select unique a.r31_bodega
				from t_r31_1 a
				where a.r31_compania = rept031.r31_compania
				  and a.r31_bodega   = rept031.r31_bodega)
	  and r31_item      = '26045'
	  and exists (select 1 from t_r31_1 a
			where a.r31_compania = rept031.r31_compania
			  and a.r31_bodega   = rept031.r31_bodega
			  and a.item_a       = rept031.r31_item);
delete from rept031
	where r31_compania  = 1
	  and r31_bodega   in (select unique a.r31_bodega
				from t_r31_2 a
				where a.r31_compania = rept031.r31_compania
				  and a.r31_bodega   = rept031.r31_bodega)
	  and r31_item      = '26145'
	  and exists (select 1 from t_r31_2 a
			where a.r31_compania = rept031.r31_compania
			  and a.r31_bodega   = rept031.r31_bodega
			  and a.item_a       = rept031.r31_item);
insert into rept031
	select a.r31_compania, a.r31_ano, a.r31_mes, a.r31_bodega, a.r31_item,
		a.r31_stock, a.r31_costo_mb, a.r31_costo_ma, a.r31_precio_mb,
		a.r31_precio_ma
	from t_r31_1 a;
insert into rept031
	select a.r31_compania, a.r31_ano, a.r31_mes, a.r31_bodega, a.r31_item,
		a.r31_stock, a.r31_costo_mb, a.r31_costo_ma, a.r31_precio_mb,
		a.r31_precio_ma
	from t_r31_2 a;

delete from rept011
	where r11_compania  = 1
	  and r11_bodega   in (select unique a.r11_bodega
				from t_r11_1 a
				where a.r11_compania = rept011.r11_compania
				  and a.r11_bodega   = rept011.r11_bodega)
	  and r11_item      = '26045'
	  and exists (select 1 from t_r11_1 a
			where a.r11_compania = rept011.r11_compania
			  and a.r11_bodega   = rept011.r11_bodega
			  and a.item_a       = rept011.r11_item);
delete from rept011
	where r11_compania  = 1
	  and r11_bodega   in (select unique a.r11_bodega
				from t_r11_2 a
				where a.r11_compania = rept011.r11_compania
				  and a.r11_bodega   = rept011.r11_bodega)
	  and r11_item      = '26145'
	  and exists (select 1 from t_r11_2 a
			where a.r11_compania = rept011.r11_compania
			  and a.r11_bodega   = rept011.r11_bodega
			  and a.item_a       = rept011.r11_item);
insert into rept011
	select a.r11_compania, a.r11_bodega, a.r11_item, a.r11_ubicacion,
		a.r11_ubica_ant, a.r11_stock_ant, a.r11_stock_act,
		a.r11_ing_dia, a.r11_egr_dia, a.r11_fec_ultvta,
		a.r11_tip_ultvta, a.r11_num_ultvta, a.r11_fec_ulting,
		a.r11_tip_ulting, a.r11_num_ulting
	from t_r11_1 a;
insert into rept011
	select a.r11_compania, a.r11_bodega, a.r11_item, a.r11_ubicacion,
		a.r11_ubica_ant, a.r11_stock_ant, a.r11_stock_act,
		a.r11_ing_dia, a.r11_egr_dia, a.r11_fec_ultvta,
		a.r11_tip_ultvta, a.r11_num_ultvta, a.r11_fec_ulting,
		a.r11_tip_ulting, a.r11_num_ulting
	from t_r11_2 a;

update rept024
	set r24_item = (select item
			from t3
			where cia     = r24_compania
			  and loc     = r24_localidad
			  and numprev = r24_numprev
			  and item_a  = r24_item)
	where r24_item = '26045'
	  and exists (select * from t3
			where cia     = r24_compania
			  and loc     = r24_localidad
			  and numprev = r24_numprev
			  and item_a  = r24_item);
update rept024
	set r24_item = (select item
			from t4
			where cia     = r24_compania
			  and loc     = r24_localidad
			  and numprev = r24_numprev
			  and item_a  = r24_item)
	where r24_item = '26145'
	  and exists (select * from t4
			where cia     = r24_compania
			  and loc     = r24_localidad
			  and numprev = r24_numprev
			  and item_a  = r24_item);
update rept022
	set r22_item = (select item
			from t3
			where cia     = r22_compania
			  and loc     = r22_localidad
			  and numprof = r22_numprof
			  and item_a  = r22_item)
	where r22_item = '26045'
	  and exists (select * from t3
			where cia     = r22_compania
			  and loc     = r22_localidad
			  and numprof = r22_numprof
			  and item_a  = r22_item);
update rept022
	set r22_item = (select item
			from t4
			where cia     = r22_compania
			  and loc     = r22_localidad
			  and numprof = r22_numprof
			  and item_a  = r22_item)
	where r22_item = '26145'
	  and exists (select * from t4
			where cia     = r22_compania
			  and loc     = r22_localidad
			  and numprof = r22_numprof
			  and item_a  = r22_item);
update rept020
	set r20_item = '26145'
	where r20_item = '26045'
	  and exists (select * from t3
			where cia    = r20_compania
			  and loc    = r20_localidad
			  and cod    = r20_cod_tran
			  and num    = r20_num_tran
			  and bod    = r20_bodega
			  and item_a = r20_item
			  and orden  = r20_orden);
update rept020
	set r20_item = '26045'
	where r20_item = '26145'
	  and exists (select * from t4
			where cia    = r20_compania
			  and loc    = r20_localidad
			  and cod    = r20_cod_tran
			  and num    = r20_num_tran
			  and bod    = r20_bodega
			  and item_a = r20_item
			  and orden  = r20_orden);

select r35_compania cia, r35_localidad loc, r35_bodega bod, r35_num_ord_des od,
	r35_item item, r35_orden orden
	from t3 a, rept034 b, rept035 c
	where b.r34_compania    = a.cia
	  and b.r34_localidad   = a.loc
	  and b.r34_cod_tran    = a.cod
	  and b.r34_num_tran    = a.num
	  and c.r35_compania    = b.r34_compania
	  and c.r35_localidad   = b.r34_localidad
	  and c.r35_bodega      = b.r34_bodega
	  and c.r35_num_ord_des = b.r34_num_ord_des
	  and c.r35_item        = item_a
	into temp t_r35_1;
select r35_compania cia, r35_localidad loc, r35_bodega bod, r35_num_ord_des od,
	r35_item item, r35_orden orden
	from t4 a, rept034 b, rept035 c
	where b.r34_compania    = a.cia
	  and b.r34_localidad   = a.loc
	  and b.r34_cod_tran    = a.cod
	  and b.r34_num_tran    = a.num
	  and c.r35_compania    = b.r34_compania
	  and c.r35_localidad   = b.r34_localidad
	  and c.r35_bodega      = b.r34_bodega
	  and c.r35_num_ord_des = b.r34_num_ord_des
	  and c.r35_item        = item_a
	into temp t_r35_2;
update rept035
	set r35_item = '26145'
	where r35_item = '26045'
	  and exists (select *
			from t_r35_1
			where cia   = r35_compania
			  and loc   = r35_localidad
			  and bod   = r35_bodega
			  and od    = r35_num_ord_des
			  and item  = r35_item
			  and orden = r35_orden);
update rept035
	set r35_item = '26045'
	where r35_item = '26145'
	  and exists (select *
			from t_r35_2
			where cia   = r35_compania
			  and loc   = r35_localidad
			  and bod   = r35_bodega
			  and od    = r35_num_ord_des
			  and item  = r35_item
			  and orden = r35_orden);

select r37_compania cia, r37_localidad loc, r37_bodega bod, r37_num_entrega n_e,
	r37_item item, r37_orden orden
	from t3 a, rept034 b, rept036, rept037 c
	where b.r34_compania    = a.cia
	  and b.r34_localidad   = a.loc
	  and b.r34_cod_tran    = a.cod
	  and b.r34_num_tran    = a.num
	  and r36_compania      = b.r34_compania
	  and r36_localidad     = b.r34_localidad
	  and r36_bodega        = b.r34_bodega
	  and r36_num_ord_des   = b.r34_num_ord_des
	  and c.r37_compania    = r36_compania
	  and c.r37_localidad   = r36_localidad
	  and c.r37_bodega      = r36_bodega
	  and c.r37_num_entrega = r36_num_entrega
	  and c.r37_item        = item_a
	into temp t_r37_1;
select r37_compania cia, r37_localidad loc, r37_bodega bod, r37_num_entrega n_e,
	r37_item item, r37_orden orden
	from t4 a, rept034 b, rept036, rept037 c
	where b.r34_compania    = a.cia
	  and b.r34_localidad   = a.loc
	  and b.r34_cod_tran    = a.cod
	  and b.r34_num_tran    = a.num
	  and r36_compania      = b.r34_compania
	  and r36_localidad     = b.r34_localidad
	  and r36_bodega        = b.r34_bodega
	  and r36_num_ord_des   = b.r34_num_ord_des
	  and c.r37_compania    = r36_compania
	  and c.r37_localidad   = r36_localidad
	  and c.r37_bodega      = r36_bodega
	  and c.r37_num_entrega = r36_num_entrega
	  and c.r37_item        = item_a
	into temp t_r37_2;
update rept037
	set r37_item = '26145'
	where r37_item = '26045'
	  and exists (select *
			from t_r37_1
			where cia   = r37_compania
			  and loc   = r37_localidad
			  and bod   = r37_bodega
			  and n_e   = r37_num_entrega
			  and item  = r37_item
			  and orden = r37_orden);
update rept037
	set r37_item = '26045'
	where r37_item = '26145'
	  and exists (select *
			from t_r37_2
			where cia   = r37_compania
			  and loc   = r37_localidad
			  and bod   = r37_bodega
			  and n_e   = r37_num_entrega
			  and item  = r37_item
			  and orden = r37_orden);

update rept010
	set r10_nombre      = (select r10_nombre from t_r10_2),
	    r10_estado      = (select r10_estado from t_r10_2),
	    r10_tipo        = (select r10_tipo from t_r10_2),
	    r10_peso        = (select r10_peso from t_r10_2),
	    r10_uni_med     = (select r10_uni_med from t_r10_2),
	    r10_cantpaq     = (select r10_cantpaq from t_r10_2),
	    r10_cantveh     = (select r10_cantveh from t_r10_2),
	    r10_partida     = (select r10_partida from t_r10_2),
	    r10_modelo      = (select r10_modelo from t_r10_2),
	    r10_cod_pedido  = (select r10_cod_pedido from t_r10_2),
	    r10_cod_comerc  = (select r10_cod_comerc from t_r10_2),
	    r10_cod_util    = (select r10_cod_util from t_r10_2),
	    r10_linea       = (select r10_linea from t_r10_2),
	    r10_sub_linea   = (select r10_sub_linea from t_r10_2),
	    r10_cod_grupo   = (select r10_cod_grupo from t_r10_2),
	    r10_cod_clase   = (select r10_cod_clase from t_r10_2),
	    r10_marca       = (select r10_marca from t_r10_2),
	    r10_rotacion    = (select r10_rotacion from t_r10_2),
	    r10_paga_impto  = (select r10_paga_impto from t_r10_2),
	    r10_fob         = (select r10_fob from t_r10_2),
	    r10_monfob      = (select r10_monfob from t_r10_2),
	    r10_precio_mb   = (select r10_precio_mb from t_r10_2),
	    r10_precio_ma   = (select r10_precio_ma from t_r10_2),
	    r10_costo_mb    = (select r10_costo_mb from t_r10_2),
	    r10_costo_ma    = (select r10_costo_ma from t_r10_2),
	    r10_costult_mb  = (select r10_costult_mb from t_r10_2),
	    r10_costult_ma  = (select r10_costult_ma from t_r10_2),
	    r10_costrepo_mb = (select r10_costrepo_mb from t_r10_2),
	    r10_usu_cosrepo = (select r10_usu_cosrepo from t_r10_2),
	    r10_fec_cosrepo = (select r10_fec_cosrepo from t_r10_2),
	    r10_cantped     = (select r10_cantped from t_r10_2),
	    r10_cantback    = (select r10_cantback from t_r10_2),
	    r10_comentarios = (select r10_comentarios from t_r10_2),
	    r10_precio_ant  = (select r10_precio_ant from t_r10_2),
	    r10_fec_camprec = (select r10_fec_camprec from t_r10_2),
	    r10_proveedor   = (select r10_proveedor from t_r10_2),
	    r10_filtro      = (select r10_filtro from t_r10_2),
	    r10_electrico   = (select r10_electrico from t_r10_2),
	    r10_color       = (select r10_color from t_r10_2),
	    r10_serie_lote  = (select r10_serie_lote from t_r10_2),
	    r10_stock_max   = (select r10_stock_max from t_r10_2),
	    r10_stock_min   = (select r10_stock_min from t_r10_2),
	    r10_vol_cuft    = (select r10_vol_cuft from t_r10_2),
	    r10_dias_mant   = (select r10_dias_mant from t_r10_2),
	    r10_dias_inv    = (select r10_dias_inv from t_r10_2),
	    r10_sec_item    = (select r10_sec_item from t_r10_2),
	    r10_usuario     = (select r10_usuario from t_r10_2),
	    r10_fecing      = (select r10_fecing from t_r10_2),
	    r10_feceli      = (select r10_feceli from t_r10_2)
	where r10_compania = 1
	  and r10_codigo   = '26045';
update rept010
	set r10_nombre      = (select r10_nombre from t_r10_1),
	    r10_estado      = (select r10_estado from t_r10_1),
	    r10_tipo        = (select r10_tipo from t_r10_1),
	    r10_peso        = (select r10_peso from t_r10_1),
	    r10_uni_med     = (select r10_uni_med from t_r10_1),
	    r10_cantpaq     = (select r10_cantpaq from t_r10_1),
	    r10_cantveh     = (select r10_cantveh from t_r10_1),
	    r10_partida     = (select r10_partida from t_r10_1),
	    r10_modelo      = (select r10_modelo from t_r10_1),
	    r10_cod_pedido  = (select r10_cod_pedido from t_r10_1),
	    r10_cod_comerc  = (select r10_cod_comerc from t_r10_1),
	    r10_cod_util    = (select r10_cod_util from t_r10_1),
	    r10_linea       = (select r10_linea from t_r10_1),
	    r10_sub_linea   = (select r10_sub_linea from t_r10_1),
	    r10_cod_grupo   = (select r10_cod_grupo from t_r10_1),
	    r10_cod_clase   = (select r10_cod_clase from t_r10_1),
	    r10_marca       = (select r10_marca from t_r10_1),
	    r10_rotacion    = (select r10_rotacion from t_r10_1),
	    r10_paga_impto  = (select r10_paga_impto from t_r10_1),
	    r10_fob         = (select r10_fob from t_r10_1),
	    r10_monfob      = (select r10_monfob from t_r10_1),
	    r10_precio_mb   = (select r10_precio_mb from t_r10_1),
	    r10_precio_ma   = (select r10_precio_ma from t_r10_1),
	    r10_costo_mb    = (select r10_costo_mb from t_r10_1),
	    r10_costo_ma    = (select r10_costo_ma from t_r10_1),
	    r10_costult_mb  = (select r10_costult_mb from t_r10_1),
	    r10_costult_ma  = (select r10_costult_ma from t_r10_1),
	    r10_costrepo_mb = (select r10_costrepo_mb from t_r10_1),
	    r10_usu_cosrepo = (select r10_usu_cosrepo from t_r10_1),
	    r10_fec_cosrepo = (select r10_fec_cosrepo from t_r10_1),
	    r10_cantped     = (select r10_cantped from t_r10_1),
	    r10_cantback    = (select r10_cantback from t_r10_1),
	    r10_comentarios = (select r10_comentarios from t_r10_1),
	    r10_precio_ant  = (select r10_precio_ant from t_r10_1),
	    r10_fec_camprec = (select r10_fec_camprec from t_r10_1),
	    r10_proveedor   = (select r10_proveedor from t_r10_1),
	    r10_filtro      = (select r10_filtro from t_r10_1),
	    r10_electrico   = (select r10_electrico from t_r10_1),
	    r10_color       = (select r10_color from t_r10_1),
	    r10_serie_lote  = (select r10_serie_lote from t_r10_1),
	    r10_stock_max   = (select r10_stock_max from t_r10_1),
	    r10_stock_min   = (select r10_stock_min from t_r10_1),
	    r10_vol_cuft    = (select r10_vol_cuft from t_r10_1),
	    r10_dias_mant   = (select r10_dias_mant from t_r10_1),
	    r10_dias_inv    = (select r10_dias_inv from t_r10_1),
	    r10_sec_item    = (select r10_sec_item from t_r10_1),
	    r10_usuario     = (select r10_usuario from t_r10_1),
	    r10_fecing      = (select r10_fecing from t_r10_1),
	    r10_feceli      = (select r10_feceli from t_r10_1)
	where r10_compania = 1
	  and r10_codigo   = '26145';

commit work;
--rollback work;

drop table t_r10_1;
drop table t_r10_2;
drop table t_r11_1;
drop table t_r11_2;
drop table t_res_1;
drop table t_res_2;
drop table t_r12_1;
drop table t_r12_2;
drop table t_r31_1;
drop table t_r31_2;
--drop table t_r35_1;
--drop table t_r35_2;
drop table t_r86_1;
drop table t_r86_2;
drop table t_r87_1;
drop table t_r87_2;
drop table t_r89_1;
drop table t_r89_2;
drop table t_r92_1;
drop table t_r92_2;
drop table t_sto_1;
drop table t_sto_2;

drop table t3;
drop table t4;
