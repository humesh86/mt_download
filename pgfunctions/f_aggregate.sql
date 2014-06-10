drop function if exists f_aggregate(distance double precision, seed_geom geometry, counter int);

create or replace function f_aggregate(distance double precision, seed_geom geometry, counter int)
returns geometry as $$
declare
gstart geometry;
gunion geometry;
a int[];
c_t int;
cw2 int;
d int;

begin

c_t:=$3;
cw2:=0;
d:=$1;
gstart:=$2;

while c_t >0
	loop
		
		cw2:=cw2+1;
	
		if cw2 >1 then
			select array_agg(gid), st_union(gstart,(st_union(geom))) into a,gunion
			from t
			where st_distance(gstart,geom)<=d;
		else
			select array_agg(gid), st_union(geom) into a,gunion
			from t
			where st_distance(gstart,geom)<=d;
		end if;

		gstart:=gunion;
		
		delete from t where gid = any(a);

		select count(gid) into c_t
		from t
		where st_distance(gstart,geom) <= d;
	
	end loop;
	
	return gstart;
end;
$$ language plpgsql

