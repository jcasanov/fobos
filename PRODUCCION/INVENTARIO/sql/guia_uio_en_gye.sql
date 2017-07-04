select r95_guia_remision guia, r95_num_sri numsri
	from rept095
	where r95_compania = 999
	into temp t1;

load from "guia_uio_en_gye.csv" delimiter ","
	insert into t1;

begin work;

	update rept095
		set r95_num_sri = (select numsri
					from t1
					where guia = r95_guia_remision)
		where r95_compania       = 1
		  and r95_localidad      = 1
		  and r95_guia_remision in (select guia from t1);

commit work;

drop table t1;
	
