drop function if exists f_repair(b_dist double precision);

create or replace function f_repair(b_dist double precision)
returns void as $$
declare
c1 int;
c2 int;
gs geometry;
gu geometry;
cw1 int;
cw2 int;
a int[];
d int;
i int;
begin

create temporary table tmp as
select * from t_res order by area desc;

alter table tmp
add primary key (gid);

create temporary table tmp_res (gid integer primary key, area double precision, geom geometry);
create sequence s_tmp_res start 1;

select count(gid) into c1 from tmp;

cw1:=0;
cw2:=0;

d:=0;

while c1>0
loop
cw1:= cw1+1;

select geom into gs
from tmp limit 1;

select count(gid) into c2
from tmp
where st_distance(gs,geom)<=d;

	while c2>0
	loop
		cw2:=cw2+1;
		
		if c2>0 then
			select array_agg(gid),st_union(gs, st_union(geom)) into a,gu
			from tmp
			where st_distance(gs,geom)<=d;		
		else
			select array_agg(gid), st_union(geom) into a,gu
			from tmp
			where st_distance(gs,geom)<=d;
		end if;		

		gs:=st_concavehull(gu, 0.95);
		gs:=f_shaper(gs,b_dist);		

		for i in 1 .. array_upper(a, 1)
		loop
			delete from tmp where gid=a[i];
		end loop;
		
		select count(gid) into c2
		from tmp
		where st_distance(gs,geom)<=d;		
		
	end loop; 

	cw2=0;

	insert into tmp_res values(nextval('s_tmp_res'), st_area(gs),gs);

	select count(gid) into c1 from tmp;


end loop;

create table outputtable as
select * from tmp_res;

drop table tmp;
drop table tmp_res;

drop sequence s_tmp_res;
 
end;
$$ language plpgsql;