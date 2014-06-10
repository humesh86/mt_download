drop function if exists f_dla(mmu int, distance double precision, b_dist double precision);

create or replace function f_dla(mmu double precision, distance double precision, b_dist double precision)
returns void as
$$
declare
r record;
c1 int;
c2 int;
cw1 int;
cw2 int;
gs geometry;
gu geometry;
gg geometry;	
d double precision;
idd int;
a int[];
mindist double precision;
gids int;
ingid int;	
begin

create table grav as
select * from outputtable;

alter table grav
add column mmucheck boolean;

alter table grav
add primary key (gid);

create index i_grav_area on grav (area);

create index i_grav_geom_gist on grav using gist(geom);

update grav
set mmucheck = false where area < mmu;

update grav
set mmucheck = true where area > mmu;

create index i_grav_mmucheck on grav (mmucheck);

select count(gid) into c1 from grav where mmucheck = false;

cw1:=0;
cw2:=0;

if distance <=5 then
	d:=distance+(distance*1.5);
elsif distance > 5 then
	d:=distance*1.2;
else
	d:=5;
end if;

while c1>0
loop
	cw1:= cw1+1;

	select gid, geom into gids,gs
	from grav
	where mmucheck = false
	limit 1;

	gg:=gs;

	select count(gid) into c2
	from grav
	where mmucheck = false and st_distance(gs,geom)<=d and st_distance(gs,geom)>0;

	while c2>0
	loop
		cw2:=cw2+1;
		
		if c2>1 then
			select array_agg(gid),st_union(gs, st_union(geom)) into a,gu
			from grav
			where mmucheck = false and st_distance(gs,geom)<=d;  		
		else
			select array_agg(gid), st_union(geom) into a,gu
			from grav
			where mmucheck = false and st_distance(gs,geom)<=d;  
		end if;		

		gs:=st_concavehull(gu, 0.95);
		gs:=f_shaper(gs,b_dist);		

		for i in 1 .. array_upper(a, 1)
		loop
			delete from grav where gid=a[i];
		end loop;
		
		select count(gid) into c2
		from grav
		where mmucheck = false and st_distance(gs,geom)<=d  and st_distance(gs,geom)>0;
		
	end loop; 

	cw2=0;

	if gg=gs then
			perform f_gravity(d,mmu,gs);

	else
		if st_area(gs)<mmu then
			
			perform f_gravity(d,mmu,gs);
		else
			ingid:=(select max(gid) from grav)+1;
			insert into grav values(ingid, st_area(gs),gs,1::boolean);
		end if;
	end if;

	select count(gid) into c1 from grav where mmucheck = false;

end loop;



end;
$$ language plpgsql