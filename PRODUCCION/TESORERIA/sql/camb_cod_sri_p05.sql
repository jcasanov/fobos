select p05_compania cia, p05_codprov codp, p05_tipo_ret tip_r,
	p05_porcentaje porc, "312" cod_s, p05_fecha_ini_porc fec
	from cxpt005
	where p05_compania       = 1
	  and p05_tipo_ret       = "F"
	  and p05_porcentaje     = 1.00
	  and p05_codigo_sri     = "340"
	  and p05_fecha_ini_porc = mdy(02, 01, 2009)
	into temp t1;

select p05_compania cia, p05_codprov codp, p05_tipo_ret tip_r,
	p05_porcentaje porc, "340" cod_s, p05_fecha_ini_porc fec
	from cxpt005
	where p05_compania       = 1
	  and p05_tipo_ret       = "F"
	  and p05_porcentaje     = 1.00
	  and p05_codigo_sri     = "312"
	  and p05_fecha_ini_porc = mdy(02, 01, 2009)
	into temp t2;

begin work;

	delete from cxpt005
		where p05_codigo_sri = "340"
		  and exists
			(select 1 from t2
				where cia   = p05_compania
				  and codp  = p05_codprov
	  			  and tip_r = p05_tipo_ret
	  			  and porc  = p05_porcentaje
	  			  and fec   = p05_fecha_ini_porc);
		
	update cxpt005
		set p05_codigo_sri = (select cod_s
					from t1
					where cia   = p05_compania
					  and codp  = p05_codprov
		  			  and tip_r = p05_tipo_ret
		  			  and porc  = p05_porcentaje
		  			  and fec   = p05_fecha_ini_porc)
		where p05_codigo_sri = "340"
		  and exists
			(select 1 from t1
				where cia   = p05_compania
				  and codp  = p05_codprov
	  			  and tip_r = p05_tipo_ret
	  			  and porc  = p05_porcentaje
	  			  and fec   = p05_fecha_ini_porc);

--rollback work;
commit work;

drop table t1;
drop table t2;
