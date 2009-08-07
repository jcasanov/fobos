select z26_codcli, z01_nomcli, z26_banco, g08_nombre, z26_num_cta,
       z26_num_cheque, z26_fecha_cobro, z26_valor
from cxct026, cxct001, gent008
where z26_compania  = 1
  and z26_localidad = 1
  and z26_estado = 'A'
  and z26_fecha_cobro >= today
  and z26_areaneg = 1
  and z01_codcli = z26_codcli
  and g08_banco  = z26_banco
