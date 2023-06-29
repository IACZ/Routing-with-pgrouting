--Install pgRouting extension
CREATE EXTENSION IF NOT EXISTS pgrouting;

--Create dedicated schema for routing
CREATE SCHEMA IF NOT EXISTS routing;

/*It is asumed that the data from the NWB and snelheden have been loaded
in tables routing.wegvakken_fixed and routing.snelheden*/

--Drop tables 
DROP TABLE IF EXISTS routing.wegvakken_fixed;

--pgRouting requires LineStrings as datatype for geometry Yinstead of MultiLineStrings.
--ST_Dump performs the transformation
--ST_Transform changes the SRID of the map to WGS-84
CREATE TABLE routing.wegvakken_fixed	AS
SELECT  st_transform((ST_Dump(geom)).geom, 4326) as geoms, 
	ST_Length(geom) as geom_length,
	* 
FROM routing."Wegvakken"
;
	
--Adding the travel time per wvk_id
ALTER TABLE routing.wegvakken_fixed
add column idle_driving_time_in_sec FLOAT;

--When the max speed is "ombekend", then it is assumed that the speed is 30 kph
UPDATE  routing.wegvakken_fixed WV
SET idle_driving_time_in_sec = CASE
									WHEN maxshd='Onbekend' 
									THEN (lengte::float)*3600/(1000*30) 
									ELSE (lengte::float)*3600/(1000*maxshd::INT) 
								END
FROM public."Snelheden_01062023" AS SD
WHERE WV.wvk_id = SD.wvk_id;

--Roads without a speed value  (NULL) is assumed that they have an speed = 30 kph.
UPDATE routing.wegvakken_fixed 
SET idle_driving_time_in_sec = (geom_length::float)*3600/(1000*30)
WHERE idle_driving_time_in_sec IS NULL ;

--Remove geometry with old SRID
ALTER TABLE ROUTING.wegvakken_fixed
DROP COLUMN geom;

--Rename geoms field to geom
ALTER TABLE ROUTING.wegvakken_fixed
RENAME COLUMN geoms to geom;

--Adding needed fields to create the topology for routing
ALTER TABLE routing.wegvakken_fixed ADD COLUMN source integer;
ALTER TABLE routing.wegvakken_fixed ADD COLUMN target integer;

--Function to create the topology for routing
--This can take a lot of time depending of your DB specifications.
--Filtering unnecessary roads can reduce processing time
--The output is an additional table routing.wegvakken_fixed_vertices_pgr
SELECT pgr_createTopology(
     'routing.wegvakken_fixed', -- network table name (NWB)
     0.000001, -- snapping tolerance with disconnected edges
     'geom', 
     'id', 
     'source', 
     'target' );

--Function to analiyze the topology table (dead ends, gaps, isolated edges, etc)	
SELECT  pgr_analyzeGraph('routing.wegvakken_fixed', 0.00001, 'geom', 'id');

--Create alternative costs to get different routes based on your requirements
--Adding cost to the table will improve performace
ALTER TABLE routing.wegvakken_fixed ADD COLUMN direction_cost_freeflow double precision;
ALTER TABLE routing.wegvakken_fixed ADD COLUMN direction_reverse_cost_freeflow double precision;
Update routing.wegvakken_fixed set direction_cost_freeflow = CASE WHEN (rijrichtng = 'T') OR (rijrichtng = 'O') THEN -1 ELSE (idle_driving_time_in_sec) END;
Update routing.wegvakken_fixed set direction_reverse_cost_freeflow = CASE WHEN (rijrichtng = 'H') OR (rijrichtng = 'O') then -1 ELSE (idle_driving_time_in_sec) END;
ALTER TABLE routing.wegvakken_fixed ADD COLUMN direction_cost_length double precision;
ALTER TABLE routing.wegvakken_fixed ADD COLUMN direction_reverse_cost_length double precision;
Update routing.wegvakken_fixed set direction_cost_length = CASE WHEN (rijrichtng = 'T') OR (rijrichtng = 'O') THEN -1 ELSE (ST_Length(geom)) END;
Update routing.wegvakken_fixed set direction_reverse_cost_length = CASE WHEN (rijrichtng = 'H') OR (rijrichtng = 'O') then -1 ELSE (ST_Length(geom)) END;


/*Basic geolocation querys. They will yild the nearest node where 
the route can start or end.*/
--Maastricht
SELECT topo.id 
  FROM routing.wegvakken_fixed_vertices_pgr as topo
  ORDER BY topo.the_geom <-> ST_SetSRID(
    ST_MakePoint( 5.6882906, 50.8498157 ),
  4326)
  LIMIT 1;

--Groningen
 SELECT topo.id 
  FROM routing.wegvakken_fixed_vertices_pgr as topo
  ORDER BY topo.the_geom <-> ST_SetSRID(
    ST_MakePoint( 6.57386,53.21687  ),
  4326)
  LIMIT 1;

--Amsterdam
SELECT topo.id 
   FROM routing.wegvakken_fixed_vertices_pgr as topo
   ORDER BY topo.the_geom <-> ST_SetSRID(
     ST_MakePoint( 4.4871586,51.9143807  ),
   4326)
   LIMIT 1

--Utrecht
SELECT topo.id 
  FROM routing.wegvakken_fixed_vertices_pgr as topo
  ORDER BY topo.the_geom <-> ST_SetSRID(
    ST_MakePoint( 5.11414,52.08979  ),
  4326)
  LIMIT 1;
 
 --Rotterdam
SELECT topo.id 
  FROM routing.wegvakken_fixed_vertices_pgr as topo
  ORDER BY topo.the_geom <-> ST_SetSRID(
    ST_MakePoint( 4.90788,52.36994  ),
  4326)
  LIMIT 1;

--Routing query using Dijkstra algorithm
SELECT shp_wegvakken_fixed.geom FROM 
(SELECT * FROM pgr_dijkstra('select id as id, source, target,
					   direction_cost_length as cost,
					   direction_reverse_cost_freeflow as reverse_cost 
					   from routing.wegvakken_fixed', 33263, 66283)) as route 
LEFT OUTER JOIN routing.wegvakken_fixed shp_wegvakken_fixed 
ON shp_wegvakken_fixed.id = route.edge;








 