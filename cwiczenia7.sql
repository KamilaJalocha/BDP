CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

--zad 2
--wgranie danych
raster2pgsql.exe -s 27700 -N -32767 -t 100x100 -I -C -M -d "D:\AGH\cw7\ras250_gb\data\*.tif" public.uk_250k | psql -d cw7 -h 
localhost -U postgres -p 5432

SELECT * FROM uk_250k;

--bazujac na wcześniejszym zestawie:

--dodajemy primary key
ALTER TABLE public.uk_250k
ADD COLUMN rid SERIAL PRIMARY KEY;

--utworzenie indeksu przestrzennego 
CREATE INDEX idx_uk_250k_gist ON public.uk_250k
USING gist (ST_ConvexHull(rast));

--dodanie raster constraints
SELECT AddRasterConstraints('public'::name, 'uk_250k'::name,'rast'::name);

--zad 3
CREATE TABLE public.uk_250k_union AS
SELECT ST_Union(p.rast)
FROM public.uk_250k AS p


CREATE TABLE public.uk_250k_union AS
SELECT ST_Union(ST_Clip(p.rast, v.geom, true)) AS raster
FROM public.uk_250k AS p, vectors.national_parks AS v
WHERE ST_Intersects(p.rast, v.geom) AND v.id = 1;

SELECT * FROM public.uk_250k_union

CREATE TABLE tmp_union AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(raster), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM public.uk_250k_union;

-- Zapisywanie pliku na dysku 

SELECT lo_export(loid, 'F:\KAMSSSSSS\bazy_obiekt\uk_250k_union.tiff')
FROM tmp_union;

-- Usuwanie obiektu

SELECT lo_unlink(loid)
FROM tmp_union;

DROP TABLE tmp_union;

--zad 4
--Pobranie danych OS Open Zoomstack 

--zad 5
--Załadowanie pliku do bazy danych (schemat vectors) wykonano przy użyciu programu QGiS.

SELECT ST_AsText(geom) FROM vectors.national_parks

--zad 6
CREATE TABLE public.uk_lake_district AS
SELECT ST_Clip(p.rast, vu.geom, true) AS raster
FROM public.uk_250k AS p, vectors.national_parks AS vu
WHERE ST_Intersects(p.rast, vu.geom) AND vu.id = 1;

SELECT * FROM public.uk_lake_district
DROP TABLE public.uk_lake_district

--zad 7

CREATE TABLE tmp_lake AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(raster), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM public.uk_lake_district;

-- Zapisywanie pliku na dysku 

SELECT lo_export(loid, 'F:\KAMSSSSSS\bazy_obiekt\uk_lake_district.tiff')
FROM tmp_lake;

-- Usuwanie obiektu

SELECT lo_unlink(loid)
FROM tmp_lake;

DROP TABLE tmp_lake;


--zad8
--pobranie danych ze strony 

--zad9
--załadowanie danych 
raster2pgsql.exe -s 32630 -N -32767 -t 1250x559 -I -C -M -d "D:\AGH\cw7\cos\*.jp2" sentinel.sentinel | psql -d cw7 -h localhost -U postgres -p 5432

SELECT * FROM sentinel.sentinel

--utworzenie indeksu przestrzennego 
CREATE INDEX idx_uk_250k_gist ON sentinel.sentinel
USING gist (ST_ConvexHull(rast));

--dodanie raster constraints
SELECT AddRasterConstraints('sentinel'::name, 'sentinel'::name,'rast'::name);

--zad 10

CREATE TABLE sentinel.sentinel_ndvi AS
WITH r AS (
SELECT s.rid,ST_Clip(s.rast, v.geom,true) AS rast
FROM sentinel.sentinel AS s, vectors.national_parks AS v
WHERE ST_Intersects(v.geom,s.rast) AND v.id = 1
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

SELECT * FROM sentinel.sentinel_ndvi

--zad 11

CREATE TABLE tmp_ndvi AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(raster), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM sentinel.sentinel_ndvi;

-- Zapisywanie pliku na dysku 

SELECT lo_export(loid, 'F:\KAMSSSSSS\bazy_obiekt\ndvi.tif')
FROM tmp_ndvi;

-- Usuwanie obiektu

SELECT lo_unlink(loid)
FROM tmp_ndvi;

DROP TABLE tmp_ndvi;


