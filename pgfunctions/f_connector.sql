drop function if exists f_connector(g1 geometry, g2 geometry, dist double precision);

create or replace function f_connector(g1 geometry, g2 geometry, dist double precision)
returns geometry as $$
declare
g geometry;
begin

g:=st_union(g1,g2);
g:=st_buffer(g,dist);
g:=st_buffer(g,-(dist+(dist*0.01)));

return g;

end;
$$ language plpgsql;