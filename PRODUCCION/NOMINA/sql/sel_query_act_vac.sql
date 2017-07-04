select n33_compania cia, n33_cod_liqrol c_rol, n33_fecha_ini fec_ini,
	n33_fecha_fin fec_fin, n33_cod_trab cod_trab, n33_cod_rubro rub_11,
	n33_valor valor
	from rolt033
	where n33_compania   = 1
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_cod_rubro  = 11
	  and n33_valor      > 0
	into temp t1;

select n33_compania, n33_cod_liqrol, n33_fecha_ini, n33_fecha_fin,
	n33_cod_trab, n33_cod_rubro, n33_valor
	from rolt033
	where exists (select cia, c_rol, fec_ini, fec_fin, cod_trab from t1)
	  and n33_cod_rubro  = 12
	  and n33_valor      > 0
	into temp t2;

select t1.*, t2.*
	from t2, outer t1
	where n33_compania   = cia
	  and n33_cod_liqrol = c_rol
	  and n33_fecha_ini  = fec_ini
	  and n33_fecha_fin  = fec_fin
	  and n33_cod_trab   = cod_trab
	into temp t3;

select t1.*, t2.*
	from t1, outer t2
	where n33_compania   = cia
	  and n33_cod_liqrol = c_rol
	  and n33_fecha_ini  = fec_ini
	  and n33_fecha_fin  = fec_fin
	  and n33_cod_trab   = cod_trab
	into temp t4;

select count(*) hay_t1 from t1;

select count(*) hay_t2 from t2;

drop table t1;

drop table t2;

select count(*) tot_t3 from t3;

select count(*) tot_t4 from t4;

delete from t3 where cia is not null;

delete from t4 where n33_compania is not null;

select * from t3 order by 11 desc;

select * from t4 order by 4 desc;

begin work;

select a.*, b.n33_valor dias_trab
	from t3 a, rolt033 b
	where b.n33_compania   = 17
	  and b.n33_cod_liqrol = a.n33_cod_liqrol
	  and b.n33_fecha_ini  = a.n33_fecha_ini
	  and b.n33_fecha_fin  = a.n33_fecha_fin
	  and b.n33_cod_trab   = a.n33_cod_trab 
	  and b.n33_cod_rubro  = 1
	into temp t5;

insert into t5
	select a.*,
		case when b.n33_valor = 0 then 15 else b.n33_valor end case
		from t3 a, rolt033 b
		where b.n33_compania   = a.n33_compania
		  and b.n33_cod_liqrol = a.n33_cod_liqrol
		  and b.n33_fecha_ini  = a.n33_fecha_ini
		  and b.n33_fecha_fin  = a.n33_fecha_fin
		  and b.n33_cod_trab   = a.n33_cod_trab 
		  and b.n33_cod_rubro  = 1;

select * from t5;
select a.n33_compania, a.n33_cod_liqrol,
				a.n33_fecha_ini, a.n33_fecha_fin,
				a.n33_cod_trab
			from t5 a;
select dias_trab - a.n33_valor from t5 b, rolt033 a
				where b.n33_compania   = a.n33_compania
				  and b.n33_cod_liqrol = a.n33_cod_liqrol
				  and b.n33_fecha_ini  = a.n33_fecha_ini
				  and b.n33_fecha_fin  = a.n33_fecha_fin
				  and b.n33_cod_trab   = a.n33_cod_trab
				  and b.n33_cod_rubro  = 12;

update rolt033
	set n33_valor = (select dias_trab - n33_valor from t5 b
				where b.n33_compania   = n33_compania
				  and b.n33_cod_liqrol = n33_cod_liqrol
				  and b.n33_fecha_ini  = n33_fecha_ini
				  and b.n33_fecha_fin  = n33_fecha_fin
				  and b.n33_cod_trab   = n33_cod_trab
				  and b.n33_cod_rubro  = 12)
	where exists (select a.n33_compania, a.n33_cod_liqrol,
				a.n33_fecha_ini, a.n33_fecha_fin,
				a.n33_cod_trab
			from t5 a
			where a.n33_compania   = n33_compania
			  and a.n33_cod_liqrol = n33_cod_liqrol
			  and a.n33_fecha_ini  = n33_fecha_ini
			  and a.n33_fecha_fin  = n33_fecha_fin
			  and a.n33_cod_trab   = n33_cod_trab
			  and a.n33_cod_rubro  = 12)
	  and n33_cod_rubro  = 11
	  and n33_valor      = 0;

{
update rolt033
	set n33_horas_porc = (select n33_valor from rolt033 b
				where b.n33_compania   = n33_compania
				  and b.n33_cod_liqrol = n33_cod_liqrol
				  and b.n33_fecha_ini  = n33_fecha_ini
				  and b.n33_fecha_fin  = n33_fecha_fin
				  and b.n33_cod_trab   = n33_cod_trab 
				  and b.n33_cod_rubro  = 11)
	where exists (select a.n33_compania, a.n33_cod_liqrol,
				a.n33_fecha_ini, a.n33_fecha_fin,
				a.n33_cod_trab
			from t5 a)
	  and n33_cod_rubro  = 12
	  and n33_valor      > 0;

commit work;

drop table t3;

drop table t4;

drop table t5;
}
