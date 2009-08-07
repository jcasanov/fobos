select z01_nomcli , talt010.*
  from talt010, cxct001
 where t10_modelo LIKE '%W%300%'
   and z01_codcli = t10_codcli
