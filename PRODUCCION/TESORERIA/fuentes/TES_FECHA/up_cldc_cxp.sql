begin work;

select * from cxpt020
	where p20_numero_oc in (select c10_numero_oc from ordt010
				where c10_compania   = p20_compania
				  and c10_localidad  = p20_localidad
				  and c10_tipo_orden = 1
				  and c10_estado     not in ('A', 'P'))
	  and p20_origen    = 'A'
	into temp t1;

select count(*) tot_doc from t1;

select unique p20_compania cia, p20_localidad loc, p20_codprov codprov,
	p20_tipo_doc tipo_doc, p20_num_doc num_doc, p20_numero_oc num_oc,
	r19_cod_tran, r19_num_tran
	from rept019, t1
	where r19_compania   = p20_compania
	  and r19_localidad  = p20_localidad
	  and r19_cod_tran   = 'CL'
	  and r19_oc_externa = p20_num_doc
	  and r19_oc_interna = p20_numero_oc	
	into temp t2;

drop table t1;

select count(*) tot_cl from t2;

update cxpt020
	set p20_cod_tran = (select r19_cod_tran from t2
				where cia      = p20_compania
				  and loc      = p20_localidad
				  and codprov  = p20_codprov
				  and tipo_doc = p20_tipo_doc
				  and num_doc  = p20_num_doc),
	    p20_num_tran = (select r19_num_tran from t2
				where cia      = p20_compania
				  and loc      = p20_localidad
				  and codprov  = p20_codprov
				  and tipo_doc = p20_tipo_doc
				  and num_doc  = p20_num_doc)
	where exists (select cia, loc, codprov, tipo_doc, num_doc, num_oc
			from t2
			where cia      = p20_compania
			  and loc      = p20_localidad
			  and codprov  = p20_codprov
			  and tipo_doc = p20_tipo_doc
			  and num_doc  = p20_num_doc
			  and num_oc   = p20_numero_oc);

drop table t2;

select p21_compania cia, p21_localidad loc, p21_codprov codprov,
	p21_tipo_doc tipo_doc, p21_num_doc num_doc, 'DC' cod_tran,
	p21_referencia[28, (length(p21_referencia))] num_tran
	from cxpt021
	where p21_tipo_doc   = 'NC'
	  and p21_referencia matches 'DEVOLUCION (COMPRA LOCAL) #*'
	  and p21_origen     = 'A'
	into temp t1;

select count(*) tot_dc from t1;

update cxpt021
	set p21_cod_tran = (select cod_tran from t1
				where cia      = p21_compania
				  and loc      = p21_localidad
				  and codprov  = p21_codprov
				  and tipo_doc = p21_tipo_doc
				  and num_doc  = p21_num_doc),
	    p21_num_tran = (select num_tran from t1
				where cia      = p21_compania
				  and loc      = p21_localidad
				  and codprov  = p21_codprov
				  and tipo_doc = p21_tipo_doc
				  and num_doc  = p21_num_doc)
	where exists (select cia, loc, codprov, tipo_doc, num_doc
			from t1
			where cia      = p21_compania
			  and loc      = p21_localidad
			  and codprov  = p21_codprov
			  and tipo_doc = p21_tipo_doc
			  and num_doc  = p21_num_doc);

--drop table t2;

--commit work;
