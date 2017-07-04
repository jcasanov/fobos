select p02_codprov as codprov,
	p02_banco_prov as bco,
	p02_cod_bco_tra as cod_bco,
	p02_cta_prov as cta_prov,
	p02_tip_cta_prov as tip_c,
	p02_contacto as contac,
	p02_email as correo
	from cxpt002
	where p02_compania = 999
	into temp t1;

load from "act_prov_bco_qm.csv" delimiter "," insert into t1;

begin work;

	update cxpt002
		set p02_banco_prov   = (select bco
					from t1
					where codprov = p02_codprov),
		    p02_cod_bco_tra  = (select cod_bco
					from t1
					where codprov = p02_codprov),
		    p02_cta_prov     = (select cta_prov
					from t1
					where codprov = p02_codprov),
		    p02_tip_cta_prov = (select tip_c
					from t1
					where codprov = p02_codprov),
		    p02_contacto     = (select contac
					from t1
					where codprov = p02_codprov),
		    p02_email        = (select correo
					from t1
					where codprov = p02_codprov)
		where p02_compania  = 1
		  and p02_codprov  in (select codprov from t1);

commit work;

drop table t1;
