begin work;

	alter table "fobos".rept002
		drop constraint "fobos".ck_05_rept002;

commit work;
