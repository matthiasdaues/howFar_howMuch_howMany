# steps towards a routing enabled road network

1. import all highways with type, name and surface tags as attributes
   1. scripts
      1. 
2. add the area_type attribute for all non-road-types by
   1. find the st_intersects spatial relation to enclosing features and
      1. adding the "landuse" tag
      2. adding the "leisure" tag
      3. adding the tags as arrays to compensate for paths crossing several type areas
3. create the "junction"-data set
4. analyze all roads / paths that are not identified as nearest road and
   1. cut them into "real" graph edges
   2. identify all nodes with degree 2
   3. collapse all continuous connections between nodes of degree 3 into edges by
      1. adding the length of the constituent edges
      2. collecting the node_ids with degree 2 into an array ordered by path index
      3. collecting the edge geometries into a geometry collection of linestring primitives
5. !! as an alternative to 2.1 all non-road-types that are not nearest line to an address coordinate could be eliminated from step 4

As a result we should have a detailed road network graph in residential areas whose fine grained near-terminus parts are connected with long ranging logical edges in non-residential areas.

_____________________


1. import all highways with type, name and surface tags as attributes
   1. scripts
      1. 
2. add the area_type attribute for all non-road-types by
   1. find the st_intersects spatial relation to enclosing features and
      1. adding the "landuse" tag
      2. adding the "leisure" tag
      3. adding the tags as arrays to compensate for paths crossing several type areas
3. Prune the road network based on 
   1. road type
   2. area type
   3. e.g.: footpath in non-residential areas like cemetaries / parks, cycle way
   4. ruleset: