# geohash_decode and geohash_encode

## source

The functions geohash_decode and geohash_encode are adapted from this source (as mentioned [in this stackoverflow question](https://stackoverflow.com/questions/5997241/postgresql-is-there-a-function-that-will-convert-a-base-10-int-into-a-base-36-s)):
[base36 conversion in postgresql](https://www.rightbrainnetworks.com/2010/03/02/base36-conversion-in-postgresql/)

## usage

roughly 40ms     geohash_decode(st_geohash(geom,10)) as int

## caveat

---

created 2021-12-13 21:00