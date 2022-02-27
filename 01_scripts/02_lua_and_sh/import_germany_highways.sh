# Import von OSM-Daten über Osmium und osm2pgsql

cd ~/Documents/geo_experimente/osm/OSM

osmium tags-filter --overwrite -v -o berlin.osm.pbf berlin-latest.osm.pbf w/highway r/boundary=administrative rw/building:* nrw/addr:* nrw/type:building



# osm2pgsql -H localhost -P 25432 -U gis -W -d gis -O flex -S highways.lua hamburg.osm.pbf
osm2pgsql -H localhost -P 25432 -U gis -W -d gis -O flex -S buildings.lua germany.osm.pbf
osm2pgsql -H localhost -P 25432 -U gis -W -d gis -O flex -S addr.lua germany.osm.pbf


# test the file for missing objects
osmium getid germany-latest.osm.pbf w43636167 -o test.osm.pbf

# Import "generic"
osm2pgsql -H localhost -P 25432 -U gis -W -d gis -O flex -S generic.lua germany-latest.osm.pbf

