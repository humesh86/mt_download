drop function if exists f_mainfunction(distance double precision, mmu double precision, seed_lbtyp int, seed_area double precision, other int[], gopt boolean);

create or replace function f_mainfunction(distance double precision, mmu double precision, seed_lbtyp int, seed_area double precision, other int[], gopt boolean)
returns void as
$$
declare
counter integer;
count_dist integer;
c_t integer;
gstart geometry;
cw1 integer;
cw2 integer;
d double precision;
a int[];
r record;
r2 record;
vc integer;
goption boolean;
seed int;
srid integer;
	
begin

drop table if exists t;
drop table if exists t_res;
drop table if exists p_alpha;
drop table if exists outputtable;
drop table if exists grav;
drop table if exists inputtable_clean;

drop sequence if exists s_t_res;

--inputtable = table with geometries to generalize

if (seed_area) = 0 then
create table t as
select gid, lbtyp, geom, st_centroid(geom) as centr 
from inputtable where lbtyp=seed_lbtyp or 
(lbtyp = any(other) and flaeche < 3000);
else
create table t as
select gid, lbtyp, geom, st_centroid(geom) as centr 
from inputtable 
where (lbtyp=seed_lbtyp and flaeche <= seed_area) or
(lbtyp = any(other) and flaeche <= 3000);
end if;


alter table t
add primary key (gid);

create index i_t_lbtyp on t (lbtyp);

create index i_t_geom_gist on t using gist(geom);

create index i_t_centr_gist on t using gist(centr);

raise notice 'table created - geometries(%)', (select count(gid) from t);

perform f_tableclean(seed_lbtyp,other,10);

create table inputtable_clean as
select * from t;

srid:=(select st_srid(geom) from t limit 1);
d:=$1;

create table t_res (gid integer primary key, area double precision, geom geometry);
create sequence s_t_res start 1;

goption:=gopt;

if(goption) then
	create table p_alpha (id integer, geom geometry);
end if;


select count(gid) into counter
from t where lbtyp=seed_lbtyp; 

cw1:=0;
cw2:=0;
vc:=0;

while counter>0
loop
	cw1:= cw1+1;
	
	select geom into gstart
	from t where lbtyp = seed_lbtyp limit 1;	

	select count(gid) into c_t
	from t
	where st_distance(gstart,geom) <= d;

	--enter 2nd loop
	select (f_aggregate(d::double precision, gstart, c_t::int)) into gstart;
		
	--alpha hull or concave hull
	select (f_hull(goption,srid,0.95::double precision,gstart)) into gstart;

	insert into t_res values(nextval('s_t_res'), st_area(gstart),gstart);	
	
	select count(*) into counter
	from t where lbtyp = 1; 	
	
end loop;

perform f_repair(10::double precision);

if (mmu > 0) then
perform f_DLA(mmu::double precision,d::double precision,10::double precision);
end if;

raise notice 'finished';

end;
$$ language plpgsql