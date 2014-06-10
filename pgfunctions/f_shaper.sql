drop function if exists f_shaper(geom geometry, bdist integer);

create or replace function f_shaper(geom geometry, bdist double precision)
returns geometry as $$
declare
g geometry;
b integer;
begin

g:=$1;
b:=bdist;
g:=st_buffer(g,b);
g:=st_buffer(g,-(b+(b*0.01)));

return g;

end;
$$ language plpgsql;