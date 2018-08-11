select s21_localidad loc, s21_tipo_comp tc,
        round(sum(case when s21_tipo_comp <> "04"
                        then s21_monto_ret_rent
                        else s21_monto_ret_rent * (-1)
                end), 2) totret,
        round(sum(case when s21_tipo_comp <> "04"
                        then s21_monto_iva
                        else s21_monto_iva * (-1)
                end), 2) totiva,
        round(sum(case when s21_tipo_comp <> "04"
                        then s21_bas_imp_gr_iva
                        else s21_bas_imp_gr_iva * (-1)
                end), 2) totvta
        from srit021
        where s21_anio = 2013
          and s21_mes  = 1
        group by 1, 2
        into temp t1;
select * from t1 order by 1, 2;
select loc, round(sum(totvta), 2) tot, round(sum(totiva), 2) totiva,
	round(sum(totret), 2) totret
	from t1
	group by 1;
select round(sum(totvta), 2) totg,
	round(sum(totiva), 2) totivag,
	round(sum(totret), 2) totretg
	from t1;
drop table t1;
