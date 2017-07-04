select b10_compania cia, b10_cuenta cta,
	case when b10_cuenta[1, 8] = '51010404' then
		replace(b10_descripcion, 'FONDO RESERVA MEN. ',
			'FON.RES.PAG.TRABAJ.')
	     when b10_cuenta[1, 8] = '51010405' then
		replace(b10_descripcion, 'FONDO RESERVA ACU. ',
			'FON.RES.PAGAD IESS ')
	end nombre
	from ctbt010
	where b10_compania in (1, 2)
	  and (b10_cuenta  like '51010404%'
	   or  b10_cuenta  like '51010405%')
	  and b10_nivel    = 6
	into temp t1;
begin work;
	update ctbt010
		set b10_descripcion = (select nombre
					from t1
					where cia = b10_compania
					  and cta = b10_cuenta)
		where b10_compania in (1, 2)
		  and b10_cuenta   in (select cta from t1);
commit work;
drop table t1;
