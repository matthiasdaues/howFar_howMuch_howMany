drop table if exists osm.edges_dev cascade;
create table osm.edges_dev (
   	edge_id    bigint
 ,   from_node    bigint
 ,   to_node  bigint
 ,   geom       geometry(LineString,4326)
 ,   properties jsonb
 ,   valid_from date
 ,   valid_to   date
 )
 ;


 create index edge_dev_id_idx on osm.edges_dev using btree (edge_id);
 create index edge_dev_from_node_id_idx on osm.edges_dev using btree (from_node);
 create index edge_dev_to_node_id_idx on osm.edges_dev using btree (to_node);
 create index edge_dev_geom_idx on osm.edges_dev using gist (geom);

--truncate table osm.edges;

ql
union all 
select
    geohash_decode(
        st_geohash(
            st_lineinterpolatepoint(
                junction_edge::geometry,0.5
            ),10
        )
    ) as edge_id                                   
,   addr_location_id as from_node
,   junction_location_id as to_node
,   junction_edge as geom
,   null as properties
-- ,   0 as valid_from
-- ,   0 as valid_to
from
   osm.junctions_dev 
-- where
--    way_id = 22907279
