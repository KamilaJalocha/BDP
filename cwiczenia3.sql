CREATE EXTENSION postgis;

--zad 1
--Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana pomiędzy 2018 a 2019).

--bez nowej tabeli
SELECT * FROM T2019_KAR_BUILDINGS AS bud
LEFT JOIN T2018_KAR_BUILDINGS AS bud2 ON ST_AsText(bud.geom) = ST_AsText(bud2.geom)
WHERE bud2.geom IS NULL;

--nowa tabela
SELECT T2019_KAR_BUILDINGS.* 
	INTO newbud FROM T2019_KAR_BUILDINGS 
		LEFT JOIN T2018_KAR_BUILDINGS ON ST_AsText(T2019_KAR_BUILDINGS.geom) = ST_AsText(T2018_KAR_BUILDINGS.geom)
WHERE T2018_KAR_BUILDINGS.geom IS NULL;


--zad 2
--Zaimportuj dane dotyczące POIs z obu lat. 
--Znajdź ile nowych POI pojawiło się w promieniu 500m od wyremontowanych lub wybudowanych budynków, który zostały znalezione w 1 zadaniu. 
--Policz je wg ich kategorii. 

SELECT T2019_KAR_POI_TABLE.type AS typ, 
COUNT(DISTINCT T2019_KAR_POI_TABLE.*) AS ilosc_obiektow
 FROM newbud,T2019_KAR_POI_TABLE LEFT JOIN T2018_KAR_POI_TABLE ON T2019_KAR_POI_TABLE.geom = T2018_KAR_POI_TABLE.geom
	WHERE T2018_KAR_POI_TABLE.geom IS NULL
		AND ST_DWithin(newbud.geom, T2019_KAR_POI_TABLE.geom, 500)
GROUP BY typ
	


--zad 3
--Utwórz nową tabelę o nazwie streets_reprojected, któa zawierać będzie dane z tabeli T_2019_KAR__STREETS przetransformowane 
-- do układu współrzędnych DHDN.Berlin/Cassini. 

CREATE TABLE streets_reprojected AS 
   (SELECT gid,link_id, st_name,ref_in_id, nref_in_id, func_class, speed_cat, fr_speed_l, to_speed_l, dir_travel, ST_Transform(geom,3068) AS geom
 	 FROM T2019_KAR_STREETS);
	 
SELECT * FROM streets_reprojected;


--zad 4 
--Stwórz tabelę o nazwie input_points i dodaj do niej dwa rekordy geometrii punktowej. Przyjmij układ współrzędnych GPS. 

CREATE TABLE input_points(id INTEGER PRIMARY KEY, geom GEOMETRY);

INSERT INTO input_points (id, geom)
	VALUES (1, ST_GeomFromText('POINT(8.36093 49.03174)', 4326)),
	   	   (2, ST_GeomFromText('POINT(8.39876 49.00644)', 4326));
	   
SELECT * FROM input_points;
 

--zad 5
--Zaktualizuj dane w tabeli input_points tak aby punkty te były w układzie współrzędnych DHDN.Berlin/Cassini.
--Wyświetl współrzędne za pomocą funkcji ST_AsText. 

UPDATE input_points 
	SET geom = ST_Transform(geom, 3068);

SELECT ST_AsText(geom) FROM input_points;


--zad 6
--Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200m od linii zbudowanej z punktów w tabeli 
--input_points. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj reprojekcji geometrii, aby była zgodna z resztą tabel.

SELECT * FROM T2019_KAR_STREET_NODE AS streets
	WHERE ST_DWithin(ST_Transform(streets.geom, 3068), (SELECT ST_MakeLine(points.geom) FROM input_points AS points), 200)


--zad 7
--Policz jak wiele sklepów sportowych ('Sporting Goods Store' - tabela POIs) znajduje się w odległości 300m od parków(LAND_USE_A)

SELECT COUNT(DISTINCT(pt.geom))
	FROM T2019_KAR_POI_TABLE AS pt, T2019_KAR_LAND_USE_A AS lu
		WHERE pt.type = 'Sporting Goods Store' AND lu.type = 'Park (City/County)'
			AND ST_DWithin(pt.geom, lu.geom, 300);
			

		
--zad 8 
--Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). 
--Zapisz znalezioną geometrię do osobnej tabeli o nazwie 'T2019_KAR_BRIDGES'.

SELECT ST_Intersection(rw.geom, wl.geom) INTO T2019_KAR_BRIDGES
FROM T2019_KAR_RAILWAYS AS rw, T2019_KAR_WATER_LINES AS wl;
