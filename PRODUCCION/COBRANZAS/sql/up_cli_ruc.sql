begin work;

--select z01_codcli, z01_estado, z01_personeria, z01_tipo_doc_id
select count(*) hay
	from cxct001
	where length(z01_num_doc_id) = 13
	  and (z01_personeria = 'N' or z01_tipo_doc_id <> 'R');

update cxct001
	set z01_personeria  = 'J',
	    z01_tipo_doc_id = 'R'
	where length(z01_num_doc_id) = 13
	  and (z01_personeria = 'N' or z01_tipo_doc_id <> 'R');

commit work;
