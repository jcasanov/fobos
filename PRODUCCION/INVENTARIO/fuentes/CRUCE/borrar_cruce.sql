rollback work;
begin work;
delete from rept041
	where r41_cod_tr = 'TR'
	  and r41_num_tr = 34504;
delete from rept020
	where r20_cod_tran = 'TR'
	  and r20_num_tran in (34504, 34505);
delete from rept019
	where r19_cod_tran = 'TR'
	  and r19_num_tran in (34504, 34505);
delete from cxct023
	where z23_codcli   = 317
	  and z23_tipo_trn = 'AJ'
	  and z23_num_trn  = 10405;
delete from cxct022
	where z22_codcli   = 317
	  and z22_tipo_trn = 'AJ'
	  and z22_num_trn  = 10405;
delete from cxct021
	where z21_cod_tran = 'DF'
	  and z21_num_tran = 5710;
update cxct020
	set z20_saldo_cap = z20_valor_cap
	where z20_cod_tran = 'FA'
	  and z20_num_tran = 48491;
delete from rept020
	where r20_cod_tran = 'DF'
	  and r20_num_tran = 5710;
delete from rept019
	where r19_cod_tran = 'DF'
	  and r19_num_tran = 5710;
update rept034
	set r34_estado = 'P'
	where r34_cod_tran = 'FA'
	  and r34_num_tran = 48491;
update rept020
	set r20_cant_dev = 0
	where r20_cod_tran = 'FA'
	  and r20_num_tran = 48491;
update rept019
	set r19_tipo_dev = null,
	    r19_num_dev  = null
	where r19_cod_tran = 'FA'
	  and r19_num_tran = 48491;
update rept011
	set r11_stock_act = 390,
	    r11_stock_ant = 310
	where r11_compania = 1
	  and r11_bodega   = '60'
	  and r11_item     = '10126';
update rept011
	set r11_stock_act = -80,
	    r11_stock_ant = -180
	where r11_compania = 1
	  and r11_bodega   = '99'
	  and r11_item     = '10126';
update gent015
	set g15_numero = 5709
	where g15_compania  = 1
	  and g15_localidad = 1
	  and g15_modulo    = 'RE'
	  and g15_bodega    = 'AA'
	  and g15_tipo      = 'DF';
update gent015
	set g15_numero = 34503
	where g15_compania  = 1
	  and g15_localidad = 1
	  and g15_modulo    = 'RE'
	  and g15_bodega    = 'AA'
	  and g15_tipo      = 'TR';
update gent015
	set g15_numero = 14118
	where g15_compania  = 1
	  and g15_localidad = 1
	  and g15_modulo    = 'CO'
	  and g15_bodega    = 'AA'
	  and g15_tipo      = 'NC';
commit work;
