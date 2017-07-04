select p20_num_doc, p20_numero_oc
	from cxpt020
	where p20_compania  in (1, 2)
	  and p20_localidad in (1, 3)
	  and p20_tipo_doc  = 'FA'
	  and p20_num_doc   = '0010107133';
select p20_num_doc, p20_numero_oc
	from cxpt020
	where p20_compania  in (1, 2)
	  and p20_localidad in (1, 3)
	  and p20_tipo_doc  = 'FA'
	  and extend(p20_fecing, year to month) = '2006-01'
	  --and p20_numero_oc is null
	  and not exists (select 1 from ordt013
				where c13_compania  = p20_compania
				  and c13_localidad = p20_localidad
				  and c13_numero_oc = p20_numero_oc)
	order by 1;
