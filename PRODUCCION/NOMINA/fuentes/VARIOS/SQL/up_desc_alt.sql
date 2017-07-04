select unique n56_compania cia, n56_proceso pro, n56_cod_depto dep,
	n56_aux_val_vac[1, 8] aux1, n56_aux_val_adi[1, 8] aux2,
	n56_aux_otr_ing[1, 8] aux3, n56_aux_iess[1, 8] aux4,
	n56_aux_otr_egr[1, 8] aux5, n56_aux_banco[1, 8] aux6
	from rolt056
	where n56_compania = 1
	  and n56_estado   = 'A'
	into temp t1;
select pro, dep, aux1,
	(select a.b10_descripcion
		from ctbt010 a
		where a.b10_compania = cia
		  and a.b10_cuenta   =
			(select max(b.b10_cuenta)
			from ctbt010 b
			where b.b10_compania = a.b10_compania
			  and b.b10_cuenta   matches (aux1 || '*'))) nom1,
	aux2, (select a.b10_descripcion
		from ctbt010 a
		where a.b10_compania = cia
		  and a.b10_cuenta   =
			(select max(b.b10_cuenta)
			from ctbt010 b
			where b.b10_compania = a.b10_compania
			  and b.b10_cuenta   matches (aux2 || '*'))) nom2,
	aux3, (select a.b10_descripcion
		from ctbt010 a
		where a.b10_compania = cia
		  and a.b10_cuenta   =
			(select max(b.b10_cuenta)
			from ctbt010 b
			where b.b10_compania = a.b10_compania
			  and b.b10_cuenta   matches (aux3 || '*'))) nom3,
	aux4, (select a.b10_descripcion
		from ctbt010 a
		where a.b10_compania = cia
		  and a.b10_cuenta   =
			(select max(b.b10_cuenta)
			from ctbt010 b
			where b.b10_compania = a.b10_compania
			  and b.b10_cuenta   matches (aux4 || '*'))) nom4,
	aux5, (select a.b10_descripcion
		from ctbt010 a
		where a.b10_compania = cia
		  and a.b10_cuenta   =
			(select max(b.b10_cuenta)
			from ctbt010 b
			where b.b10_compania = a.b10_compania
			  and b.b10_cuenta   matches (aux5 || '*'))) nom5,
	aux6, (select a.b10_descripcion
		from ctbt010 a
		where a.b10_compania = cia
		  and a.b10_cuenta   =
			(select max(b.b10_cuenta)
			from ctbt010 b
			where b.b10_compania = a.b10_compania
			  and b.b10_cuenta   matches (aux6 || '*'))) nom6
	from t1
	into temp t2;
drop table t1;
select pro, dep, aux1,
	case when substr(nom1, -27, 27) = ' TERAN LOPEZ WALTER MICHAEL'
		then replace(nom1, substr(nom1, -27, 27), '')
	     when substr(nom1, -26, 26) = ' TERAN LOPEZ WALTER MICHAE'
		then replace(nom1, substr(nom1, -26, 26), '')
	     when substr(nom1, -22, 22) = ' TERAN LOPEZ WALTER MI'
		then replace(nom1, substr(nom1, -22, 22), '')
		else nom1
	end nom1,
	aux2,
	case when substr(nom2, -27, 27) = ' TERAN LOPEZ WALTER MICHAEL'
		then replace(nom2, substr(nom2, -27, 27), '')
	     when substr(nom2, -26, 26) = ' TERAN LOPEZ WALTER MICHAE'
		then replace(nom2, substr(nom2, -26, 26), '')
	     when substr(nom2, -22, 22) = ' TERAN LOPEZ WALTER MI'
		then replace(nom2, substr(nom2, -22, 22), '')
		else nom2
	end nom2,
	aux3,
	case when substr(nom3, -27, 27) = ' TERAN LOPEZ WALTER MICHAEL'
		then replace(nom3, substr(nom3, -27, 27), '')
	     when substr(nom3, -26, 26) = ' TERAN LOPEZ WALTER MICHAE'
		then replace(nom3, substr(nom3, -26, 26), '')
	     when substr(nom3, -22, 22) = ' TERAN LOPEZ WALTER MI'
		then replace(nom3, substr(nom3, -22, 22), '')
		else nom3
	end nom3,
	aux4,
	case when substr(nom4, -27, 27) = ' TERAN LOPEZ WALTER MICHAEL'
		then replace(nom4, substr(nom4, -27, 27), '')
	     when substr(nom4, -26, 26) = ' TERAN LOPEZ WALTER MICHAE'
		then replace(nom4, substr(nom4, -26, 26), '')
	     when substr(nom4, -22, 22) = ' TERAN LOPEZ WALTER MI'
		then replace(nom4, substr(nom4, -22, 22), '')
		else nom4
	end nom4,
	aux5,
	case when substr(nom5, -27, 27) = ' TERAN LOPEZ WALTER MICHAEL'
		then replace(nom5, substr(nom5, -27, 27), '')
	     when substr(nom5, -26, 26) = ' TERAN LOPEZ WALTER MICHAE'
		then replace(nom5, substr(nom5, -26, 26), '')
	     when substr(nom5, -22, 22) = ' TERAN LOPEZ WALTER MI'
		then replace(nom5, substr(nom5, -22, 22), '')
		else nom5
	end nom5,
	aux6,
	case when substr(nom6, -27, 27) = ' TERAN LOPEZ WALTER MICHAEL'
		then replace(nom6, substr(nom6, -27, 27), '')
	     when substr(nom6, -26, 26) = ' TERAN LOPEZ WALTER MICHAE'
		then replace(nom6, substr(nom6, -26, 26), '')
	     when substr(nom6, -22, 22) = ' TERAN LOPEZ WALTER MI'
		then replace(nom6, substr(nom6, -22, 22), '')
		else nom6
	end nom6
	from t2
	order by 1, 2;
select unique n52_compania cia, n52_aux_cont[1, 8] aux
	from rolt052
	into temp t1;
select aux, (select a.b10_descripcion
		from ctbt010 a
		where a.b10_compania = cia
		  and a.b10_cuenta   =
			(select max(b.b10_cuenta)
			from ctbt010 b
			where b.b10_compania = a.b10_compania
			  and b.b10_cuenta   matches (aux || '*'))) nom
	from t1
	into temp t3;
drop table t1;
select trim(aux) aux,
	trim(case when substr(nom, -27, 27) = ' TERAN LOPEZ WALTER MICHAEL'
		then replace(nom, substr(nom, -27, 27), '')
	     when substr(nom, -26, 26) = ' TERAN LOPEZ WALTER MICHAE'
		then replace(nom, substr(nom, -26, 26), '')
	     when substr(nom, -22, 22) = ' TERAN LOPEZ WALTER MI'
		then replace(nom, substr(nom, -22, 22), '')
	     when substr(nom, -16, 16) = 'TERAN LOPEZ WALT'
		then replace(nom, substr(nom, -16, 16), '')
	     when substr(nom, -22, 22) = ' VIVES MURILLO AURELIO'
		then replace(nom, substr(nom, -22, 22), '')
		else nom
	end) nom
	from t3
	into temp t4;
drop table t3;
select * from t4 order by 1;
drop table t2;
drop table t4;
