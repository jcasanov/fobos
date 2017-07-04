--rollback work;

begin work;

delete from rept011
	where r11_compania = 1
	  and r11_bodega   = '04'
	  and r11_item     in ('69448', '92952', '92976', '94783', '94790',
				'94791', '94792', '94793', '94794', '94795',
				'94796', '94797');

commit work;
