drop function if exists f_gravity(distance double precision,mmu double precision, gstart geometry);

create or replace function f_gravity(distance double precision,mmu double precision, gstart geometry)
returns void as $$
declare
mindist double precision;
gids int;
ingid int;
c2 int;
idd int;
d double precision;
ga geometry;
gs geometry;
begin

gs:=gstart;

d:=$1;
			
	select count(gid) into c2
	from grav
	where mmucheck = true and st_distance(gs,geom)<=d and st_distance(gs,geom)>0;

	if c2 > 0 then
		select min(st_distance(gs,geom)) into mindist
		from grav where mmucheck = true;

		select gid, geom into idd, ga
		from grav
		where mmucheck = true and st_distance(gs,geom)=mindist;

		delete from grav where gid = idd;
		delete from grav where geom = gs;

		select (f_connector(gs,ga,mindist)) into gs;
		
		ingid:=(select max(gid) from grav)+1;
					
		insert into grav values(ingid, st_area(gs),gs,1::boolean);

	else
		delete from grav where geom = gs;
	end if;


end;
$$ language plpgsql;