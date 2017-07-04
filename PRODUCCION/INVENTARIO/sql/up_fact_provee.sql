begin work;

update rept019
	set r19_oc_externa = '014-004-0003678'
	where r19_compania  = 2
	  and r19_localidad = 7
	  and r19_cod_tran  = 'CL'
	  and r19_num_tran  = 3344;

update ordt010
	set c10_factura = '014-004-0003678'
	where c10_compania  = 2
	  and c10_localidad = 7
	  and c10_numero_oc = 4815;

update ordt013
	set c13_factura  = '014-004-0003678',
	    c13_num_guia = '014-004-0003678'
	where c13_compania  = 2
	  and c13_localidad = 7
	  and c13_numero_oc = 4815
	  and c13_num_recep = 1;

update cxpt020
	set p20_num_doc = '014-004-0003678'
	where p20_compania  = 2
          and p20_localidad = 7
          and p20_codprov   = 73
          and p20_tipo_doc  = 'FA'
          and p20_num_doc   = '014 004-0003678';

commit work;
