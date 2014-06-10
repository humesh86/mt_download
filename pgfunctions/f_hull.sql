drop function if exists f_hull(alpha boolean, srid integer, ch double precision, geometry geometry);

create or replace function f_hull(alpha boolean, srid integer, ch double precision, sgeometry geometry)
returns geometry as $$
declare

gh geometry;
r2 record;

begin

if(alpha) then
	delete from p_alpha;

	for r2 in select path[2] as id, geom from st_dumppoints(sgeometry)
	loop
		insert into p_alpha values(r2.id, r2.geom);			
	end loop;
	
	select pgr_pointsaspolygon('select id, st_x(geom) as x, st_y(geom) as y
					from p_alpha') into gh;
		
	if(st_isvalid(gh)) then
		gh:=st_setsrid(gh,srid);
		raise notice'VALID!!!';		
	else
		gh:=st_concavehull(sgeometry,ch);
		gh:=st_setsrid(gh,srid);
		raise notice'NOT VALID';
	end if;
else
	gh:=st_concavehull(sgeometry,ch);
	gh:=st_setsrid(gh,srid);
end if;

return gh;

end;
$$ language plpgsql;