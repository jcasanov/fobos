select z21_codcli, z21_tipo_doc, z21_num_doc, z21_fecha_emi,
	z23_tipo_favor, z23_doc_favor
        from cxct021, outer cxct023
        where z23_compania   = z21_compania
          and z23_localidad  = z21_localidad
          and z23_codcli     = z21_codcli
          and z23_tipo_favor = z21_tipo_doc
          and z23_doc_favor  = z21_num_doc
	into temp t1;
delete from t1 where z23_tipo_favor is not null;
select count(*) from t1;
select * from t1;
drop table t1;
