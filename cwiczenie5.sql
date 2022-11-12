CREATE EXTENSION postgis; 

--utowrzenie tabeli z obiektami
CREATE TABLE obiekty(name VARCHAR, geom GEOMETRY);

--dodanie obiektów

--obiekt pierwszy
INSERT INTO obiekty VALUES('obiekt1', 
		ST_GeomFromText('COMPOUNDCURVE( (0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), (5 1, 6 1))',0));

--obiekt drugi
INSERT INTO obiekty VALUES ('obiekt2', 
	ST_GeomFromText('CURVEPOLYGON(COMPOUNDCURVE(
					CIRCULARSTRING(14 6, 16 4, 14 2),
					CIRCULARSTRING(14 2, 12 0, 10 2),
					(10 2, 10 6, 14 6)), CIRCULARSTRING(11 2, 13 2, 11 2))',0));

--obiekt trzeci
INSERT INTO obiekty VALUES('obiekt3', ST_GeomFromText('CURVEPOLYGON( 
										COMPOUNDCURVE( (7 15, 10 17),(10 17, 12 13),(12 13, 7 15) ))', 0));

--obiekt czwarty
INSERT INTO obiekty VALUES('obiekt4', 
			ST_GeomFromText('COMPOUNDCURVE(LINESTRING(20 20 , 25 25),(25 25 , 27 24 ),(27 24 , 25 22),(25 22 , 26 21),
													  (26 21 , 22 19),(22 19 , 20.5 19.5))',0))

--obiekt piąty
INSERT INTO obiekty VALUES('obiekt5', ST_GeomFromText('MULTIPOINT( (30 30 59),(38 32 234))', 0));

--obiekt szósty
INSERT INTO obiekty VALUES('obiekt6', ST_GeomFromText('GEOMETRYCOLLECTION( LINESTRING(1 1, 3 2), POINT(4 2))',0));

SELECT * FROM obiekty;


--zad 1
--Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej obiekt 3 i 4.
SELECT ST_Area(ST_Buffer(ST_ShortestLine(
	(SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'),
	(SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')),
						 5));

--zad 2
--Zamień obiekt 4na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te warunki.

UPDATE obiekty
SET geom = ST_GeomFromText('CURVEPOLYGON((20 20 , 25 25 , 27 24 , 25 22 , 26 21 , 22 19 , 20.5 19.5 , 20 20))') WHERE name = 'obiekt4';


--zad 3
--W tabeli obiekty,jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.

INSERT INTO obiekty VALUES
('obiekt7', (SELECT ST_Collect(ob3.geom, ob4.geom) FROM 
 	(SELECT geom FROM obiekty WHERE name='obiekt3') AS ob3, 
							(SELECT geom FROM obiekty WHERE name='obiekt4') AS ob4));

SELECT * FROM obiekty WHERE name = 'obiekt7';

--zad 4
--Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów niezawierających łuków.

SELECT SUM(ST_Area(ST_Buffer(geom,5))) FROM obiekty WHERE ST_HasArc(geom)=FALSE;


DROP table obiekty;