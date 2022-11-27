CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;
CREATE SCHEMA Jalocha;
CREATE SCHEMA rasters;
CREATE SCHEMA vectors;

--Przykład 1- ST_Intersetcs. 
CREATE TABLE jalocha.intersects AS SELECT 
	a.rast, b.municipality FROM rasters.dem AS a, vectors.porto_parishes AS b 
		WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';
		
SELECT * FROM jalocha.intersects;

--1. dodanie serial primary key:
ALTER TABLE jalocha.intersects add COLUMN rid SERIAL PRIMARY KEY;

--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_intersects_rast_gist ON jalocha.intersects USING gist (ST_ConvexHull(rast));

--3. dodanie raster constraints:
-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('jalocha'::name,'intersects'::name,'rast'::name);

--Przykład 2 - ST_Clip; Obcinanie rastra na podstawie wektora.
CREATE TABLE jalocha.clip AS SELECT 
	ST_Clip(a.rast, b.geom, true), b.municipality FROM rasters.dem AS a, vectors.porto_parishes AS b 	
		WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';
		
SELECT * FROM jalocha.clip;

--Przykład 3 - ST_Union; Połączenie wielu kafelków w jeden raster.
CREATE TABLE jalocha.union AS SELECT 	
	ST_Union(ST_Clip(a.rast, b.geom, true)) FROM rasters.dem AS a, vectors.porto_parishes AS b 
		WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);
		
SELECT * FROM jalocha.union;

--Tworzenie rastrów z wektorów (rastrowanie)
--Poniższe przykłady pokazują rastrowanie wektoru.

--Przykład 1 - ST_AsRaster.

CREATE TABLE jalocha.porto_parishes AS 
WITH r AS (
		SELECT rast FROM rasters.dem 
		LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast 
FROM vectors.porto_parishes AS a, r 
WHERE a.municipality ilike 'porto';

SELECT * FROM jalocha.porto_parishes;

--Przykład 2 - ST_Union.
DROP TABLE jalocha.porto_parishes; --> drop table porto_parishes first 
CREATE TABLE jalocha.porto_parishes AS 
WITH r AS (
		SELECT rast FROM rasters.dem
		LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r 
WHERE a.municipality ilike 'porto';

SELECT * FROM jalocha.porto_parishes;

--Przykład 3 - ST_Tile.
--Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile.

DROP TABLE jalocha.porto_parishes; --> drop table porto_parishes first
CREATE TABLE jalocha.porto_parishes AS
WITH r AS (
		SELECT rast FROM rasters.dem
		LIMIT 1 
)
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

SELECT * FROM jalocha.porto_parishes;

--Konwertowanie rastrów na wektory (wektoryzowanie)

--Przykład 1 - ST_Intersection.
CREATE TABLE jalocha.intersection AS 
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

SELECT * FROM jalocha.intersection;

--Przykład 2 - ST_DumpAsPolygons;  ST_DumpAsPolygons konwertuje rastry w wektory (poligony).
CREATE TABLE jalocha.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

SELECT * FROM jalocha.dumppolygons;

--Analiza rastrów

--Przykład 1 - ST_Band
--Funkcja ST_Band służy do wyodrębniania pasm z rastra
CREATE TABLE jalocha.landsat_nir AS 
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

SELECT * FROM jalocha.landsat_nir;

--Przykład 2 - ST_Clip
CREATE TABLE jalocha.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

SELECT * FROM jalocha.paranhos_dem;

--Przykład 3 - ST_Slope
CREATE TABLE jalocha.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM jalocha.paranhos_dem AS a;

SELECT * FROM jalocha.paranhos_slope;

--Przykład 4 - ST_Reclass;  Aby zreklasyfikować raster należy użyć funkcji ST_Reclass.
CREATE TABLE jalocha.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3','32BF',0)
FROM jalocha.paranhos_slope AS a;

SELECT * FROM jalocha.paranhos_slope_reclass;

--Przykład 5 - ST_SummaryStats;  Aby obliczyć statystyki rastra można użyć funkcji ST_SummaryStats.
SELECT st_summarystats(a.rast) AS stats
FROM jalocha.paranhos_dem AS a;

--Przykład 6 - ST_SummaryStats oraz Union;  Przy użyciu UNION można wygenerować jedną statystykę wybranego rastra.
SELECT st_summarystats(ST_Union(a.rast))
FROM jalocha.paranhos_dem AS a;

--Przykład 7 - ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
		SELECT st_summarystats(ST_Union(a.rast)) AS stats
		FROM jalocha.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--Przykład 8 - ST_SummaryStats w połączeniu z GROUP BY
--Aby wyświetlić statystykę dla każdego poligonu "parish" można użyć polecenia GROUP BY
WITH t AS (
		SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,b.geom,true))) AS stats
		FROM rasters.dem AS a, vectors.porto_parishes AS b
		WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

--Przykład 9 - ST_Value
--Funkcja ST_Value pozwala wyodrębnić wartość piksela z punktu lub zestawu punktów.
--Poniższy  przykład wyodrębnia punkty znajdujące się w tabeli vectors.places.
--Ponieważ geometria punktów jest wielopunktowa, a funkcja ST_Value wymaga geometriijednopunktowej, należy przekonwertować 
--geometrię wielopunktową na geometrięjednopunktową  za pomocą funkcji (ST_Dump(b.geom)).geom.
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM 
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

--Przykład 10 - ST_TPI
CREATE TABLE jalocha.tpi30 AS 
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem a;

SELECT * FROM jalocha.tpi30;

--Poniższa kwerenda utworzy indeks przestrzenny:
CREATE INDEX idx_tpi30_rast_gist ON jalocha.tpi30
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('jalocha'::name,'tpi30'::name,'rast'::name);

--ZADANIE DO SAMODZIELNEGO ROZWIĄZANIA 

CREATE TABLE jalocha.tpi30_p_intersects AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ILIKE 'porto';

--Indeks przestrzenny:
CREATE INDEX idx_tpi30_rast_gist ON jalocha.tpi30_p_intersects
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('jalocha'::name,'tpi30_p_intersects'::name,'rast'::name);


--Algebra map

--Wzór na NDVI:
--NDVI=(NIR-Red)/(NIR+Red)

--Przykład 1 - Wyrażenie Algebry Map
CREATE TABLE jalocha.porto_ndvi AS
WITH r AS (
		SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
		FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
		WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT  
		r.rid,ST_MapAlgebra(
				r.rast, 1,
				r.rast, 4,
					'([rast2.val] - [rast1.val]) / ([rast2.val] +[rast1.val])::float','32BF'
			) AS rast
FROM r;

SELECT * FROM jalocha.porto_ndvi;

--Poniższe zapytanie utworzy indeks przestrzenny na wcześniej stworzonej tabeli:
CREATE INDEX idx_porto_ndvi_rast_gist ON jalocha.porto_ndvi
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('jalocha'::name,'porto_ndvi'::name,'rast'::name);

--Przykład 2 – Funkcja zwrotna
--W pierwszym kroku należy utworzyć funkcję, które będzie wywołana później:
CREATE OR REPLACE FUNCTION jalocha.ndvi(
	value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
	--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
	RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

--W kwerendzie algebry map należy można wywołać zdefiniowaną wcześniej funkcję:
CREATE TABLE jalocha.porto_ndvi2 AS
WITH r AS (
		SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
		FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
		WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
		r.rid,ST_MapAlgebra(
			r.rast, ARRAY[1,4],
			'jalocha.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
					'32BF'::text
		) AS rast
FROM r;

SELECT * FROM jalocha.porto_ndvi2;

--Dodanie indeksu przestrzennego:
CREATE INDEX idx_porto_ndvi2_rast_gist ON jalocha.porto_ndvi2
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('jalocha'::name,'porto_ndvi2'::name,'rast'::name);


--Eksport danych

--Przykład 0 - Użycie QGIS

-- wyeksportowano warstwę porto_ndvi do pliku z rozszerzeniem .tiff. 

--Przykład 1 - ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM jalocha.porto_ndvi;

--Przykład 2 - ST_AsGDALRaster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM jalocha.porto_ndvi;

--Przykład 3 - Zapisywanie danych na dysku za pomocą dużego obiektu (large object, lo)

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM jalocha.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'F:\KAMSSSSSS\bazy_obiekt\porto_ndvi.tiff') --> Save the file in a place
--where the user postgres have access. In windows a flash drive usualy works fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

DROP TABLE tmp_out;

--Przykład 4 - Użycie Gdal
--Gdal obsługuje rastry z PostGISa. Polecenie gdal_translate eksportuje raster do dowolnego formatu
--obsługiwanego przez GDAL.

gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9
PG:"host=localhost port=5432 dbname=zajecia6 user=postgres
password=Grenade.22 schema=jalocha table=porto_ndvi mode=2"
porto_ndvi.tiff

--Publikowanie danych za pomocą MapServer
MAP
NAME 'map'
SIZE 800 650
STATUS ON
EXTENT -58968 145487 30916 206234
UNITS METERS
WEB
METADATA
'wms_title' 'Terrain wms'
'wms_srs' 'EPSG:3763 EPSG:4326 EPSG:3857'
'wms_enable_request' '*'
'wms_onlineresource'
'http://54.37.13.53/mapservices/srtm'
END
END
PROJECTION
'init=epsg:3763'
END
LAYER
NAME srtm
TYPE raster
STATUS OFF
DATA "PG:host=localhost port=5432 dbname='zajecia6' user='postgres'
password='Grenade.22' schema='rasters' table='dem' mode='2'" PROCESSING
"SCALE=AUTO"
PROCESSING "NODATA=-32767"
OFFSITE 0 0 0
METADATA
'wms_title' 'srtm'
END
END
END
