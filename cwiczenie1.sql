CREATE EXTENSION postgis; 

--utworzenie tabeli dla budynkow 
CREATE TABLE buildings(id INTEGER, geom GEOMETRY, name VARCHAR, height INTEGER); 

INSERT INTO buildings VALUES(1, ST_GeomFromText('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))',0), 'BuildingC', 5);
INSERT INTO buildings VALUES(2, ST_GeomFromText('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))',0), 'BuildingA', 7);
INSERT INTO buildings VALUES(3, ST_GeomFromText('POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))',0), 'BuildingB', 6);
INSERT INTO buildings VALUES(4, ST_GeomFromText('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))',0), 'BuildingF', 2);
INSERT INTO buildings VALUES(5, ST_GeomFromText('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))',0), 'BuildingD', 3);

--utworzenie tabeli dla drog
CREATE TABLE roads(id INTEGER, name VARCHAR, geom GEOMETRY);

INSERT INTO roads VALUES(1, 'roadX', ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)',0));
INSERT INTO roads VALUES(1, 'roadY', ST_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)',0));

--utworzenie tabeli dla punktow
CREATE TABLE pktinfo(id INTEGER, geom GEOMETRY, name VARCHAR, liczprac INTEGER);

INSERT INTO pktinfo VALUES(1, ST_GeomFromText('POINT(6 9.5)',0), 'K', 1);
INSERT INTO pktinfo VALUES(2, ST_GeomFromText('POINT(6.5 6)',0), 'J', 2);
INSERT INTO pktinfo VALUES(3, ST_GeomFromText('POINT(9.5 6)',0), 'I', 3);
INSERT INTO pktinfo VALUES(4, ST_GeomFromText('POINT(1 3.5)',0), 'G', 4);
INSERT INTO pktinfo VALUES(5, ST_GeomFromText('POINT(5.5 1.5)',0), 'H', 5);

--zad1
--Wyznacz całkowita dlugosc drog w analizowanym miescie. 

SELECT SUM(ST_Length(geom)) FROM roads;

--zad2
--Wypisz geometrie WKT, pole powierzchni oraz obwod poligonu reprezentującego budynek BuildingA

SELECT ST_AsText(geom) as WKT, ST_Perimeter(geom) as Perimeter, ST_Area(geom) as Area
FROM buildings WHERE name='BuildingA';

--zad3
--Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie. 

SELECT name, ST_Area(geom) as Area FROM buildings ORDER BY name;

--zad4
--Wypisz nazwy i obwody 2 budynków o największej powierzchni. 

SELECT name, ST_Perimeter(geom) as Perimeter FROM buildings ORDER BY ST_Area(geom) DESC limit 2;

--zad5
--Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.

SELECT min(ST_Distance(buildings.geom, pktinfo.geom)) AS distance 
FROM buildings, pktinfo WHERE buildings.name='BuildingC' AND pktinfo.name='G';

--zad6
--Wypisz pole powierzchni tej częsci budynku C, która znajduje sie w odległości większej niż 0.5 od budynku BuildingB

SELECT ST_Area(ST_Difference(ST_Union(buildingc.geom, buildingb.geom), ST_Buffer(buildingb.geom, 0.5)))
FROM buildings as buildingb, buildings as buildingc
WHERE buildingc.name='BuildingC' AND buildingb.name='BuildingB'

--zad7
--Wybierz te budynki, których centroid znajduje sie powyżej drogi roadX

SELECT buildings.name FROM buildings, roads WHERE roads.name='roadX' AND
ST_Y(ST_Centroid(buildings.geom)) > ST_Y(ST_Centroid(roads.geom)) ORDER BY buildings.name;

--zad8
--Oblicz pole powierzchni tych części budynku BuldingC i poligonu o współrzędnych 
--(4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.

SELECT ST_Area(ST_SymDifference(buildings.geom, ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))',0)))
AS Area FROM buildings WHERE buildings.name='BuildingC';


