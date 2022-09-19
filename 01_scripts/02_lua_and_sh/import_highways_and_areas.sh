# Import von OSM-Daten über Osmium und osm2pgsql

cd ~/Documents/geo_experimente/osm/OSM/pbf_test

osmium tags-filter -O -v -o germany_1.osm.pbf germany-latest.osm.pbf w/highway!=area,rest_area,footway,cycleway,parking,parking_aisle,bridleway,motorway,motorway_link,steps,track,trunk,trunk_link,path,abandoned,bus_guideway,construction,corridor,elevator,escalator,private,proposed,planned,platform,raceway
osmium tags-filter -O -v -i -o germany_2.osm.pbf germany_1.osm.pbf /bridge name=*brücke 
osmium tags-filter -O -v -i -o germany_3.osm.pbf germany_2.osm.pbf /tunnel

# Import "step 1"
cd ~/Documents/@projects/howFar_howMuch_howMany/01_scripts/02_lua_and_sh/
osm2pgsql -H localhost -P 25432 -U gis -W -d gis -O flex -S highways.lua ~/Documents/geo_experimente/osm/OSM/pbf_test/germany_3.osm.pbf
HeWhoBuildsTheLand
