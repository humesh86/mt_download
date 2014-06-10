drop function if exists f_tableclean(seed integer, other integer[], distance double precision);

create or replace function f_tableclean(seed integer, other integer[], distance double precision)
returns void as $$
declare
r record;
begin

for r in select * from t where lbtyp = any(other)
loop
	if ((select count(gid) from t where st_distance(r.centr,geom) < distance and lbtyp = seed) >0) then
		continue;
	else
		delete from t where gid = r.gid; 
	end if;
end loop;

end;
$$ language plpgsql;