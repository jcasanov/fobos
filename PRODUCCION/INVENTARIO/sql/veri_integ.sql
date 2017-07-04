select local, date(fecing) fecha,
        sum(neto) tot_vta
	from integra@idsgyere:stock_gen
        where cod_tran in ('FA', 'DF', 'AF')
          and date(fecing) = today - 1 units day
        group by 1, 2
        order by 1, 2;

