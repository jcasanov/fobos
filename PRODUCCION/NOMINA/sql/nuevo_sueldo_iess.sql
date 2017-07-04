select g02_numruc ruc, "0009" sucursal, year(today) anio,
	n30_num_doc_id[1,2] mes, "MSU" tipo, n30_num_doc_id cedula,
	n30_num_doc_id nuevo_sueldo
	from gent002, rolt030
	where g02_compania  = 15
	  and g02_localidad = 17
	  and n30_compania  = g02_compania
	  and n30_estado    = 'A'
	into temp t1;
insert into t1
	select g02_numruc ruc, "0009" sucursal, year(today) anio,
		lpad(month(today), 2, 0) mes, "MSU" tipo, n30_num_doc_id cedula,
		lpad(n30_sueldo_mes, 14, 0) nuevo_sueldo
		from gent002, rolt030
		where g02_compania  = 1
		  and g02_localidad = 1
		  and n30_compania  = g02_compania
		  and n30_estado    = 'A';
unload to "nuevosue.txt" delimiter ";"
	select * from t1;
drop table t1;
