# steps towards a routing enabled road network

## I. Creating the "Transport Graph"

1. import all highways with type, name and surface tags as attributes
2. add the area_type attribute for all non-road-types by
   1. find the st_intersects spatial relation to enclosing features and
      1. add the "landuse" tag
      2. add the "leisure" tag
      3. add the tags as arrays to compensate for paths crossing several type areas
3. Prune the road network based on 
   1. road type
   2. area type
   3. e.g.: footpath in non-residential areas like cemetaries / parks, cycle way
   4. ruleset: tbd
   5. doubling-tag: 
      1. one-sided = 0
      2. to double = 1
4. Duplication
   1. duplicate all edges with tag = 1
   2. construct intersections with all edges having tag = 0

### Functions and order of execution

1. create_edges_and_vertices     => 00_create_edges_table.sql
2. chop_lines_and_extract_nodes  => 

## II. Creating the "Access Graph"

1. build the junctions from road to address
   1. find the nearest edge
   2. graft the touchpoint into the edge
   3. segment the enhanced edge

## III. Create a simplified logical graph

1. identify nodes having degree = 2
2. collaps contiguous edges consisting of such nodes into one logical edge
      1. add the length of the constituent edges
      2. collect the node_ids with degree 2 into an array ordered by path index
3. collect the edge geometries into a geometry collection of linestring primitives

The result of this sketched out process will be a detailed road network graph. In residential areas it will be a fine grained street side differentiating routing network. Those fine grained near-terminus parts will be connected with far ranging logical edges in non-residential areas. 

The routing will be calculated on the logical edges only. The dataset will preserve the prior geometry as a geometry array or multigeometry, thus combining a logical network with its physical representation within one data structure.