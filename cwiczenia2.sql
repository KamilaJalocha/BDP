CREATE EXTENSION postgis;

--zad4
--Wyznacz liczbę budynków położonych w odległości mniejszej niż 1000m od głównych rzek. 
-- Budynki spełniające to kryterium zapisz do osobnej tabeli tableB. 

SELECT bud.gid, bud.cat, bud.f_codedesc, bud.geom INTO tableB 
FROM public.popp AS bud, public.majrivers AS riv
WHERE bud.f_codedesc = 'Building'
AND ST_Within(bud.geom,(ST_Buffer(riv.geom, 1000)));

SELECT * FROM tableB


--zad5
--Utwórz tabele o nazwie airportsNew. Z tabeli airports zaimportuj nazwy lotnisk, ich geometrię, a także atrybut elev reprezentujący wysokość
--n.p.m. 

CREATE TABLE airportsNew AS(
SELECT name,geom,elev FROM public.airports);

--a Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.

SELECT name AS westairport, ST_X(an.geom) AS xmin FROM airportsNew AS an ORDER BY xmin ASC LIMIT 1;
SELECT name AS eastairport, ST_X(an.geom) AS xmax FROM airportsNew AS an ORDER BY xmax DESC LIMIT 1; 

--Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie środkowym drogi pomiędzy lotniskami
--znalezionymi w punkcie a. Lotnisko nazwij airportB. Wysokość n.p.m przyjmij dowolną. 

INSERT INTO airportsNew(name,geom,elev) VALUES ('airportB',
(SELECT ST_Centroid(ST_Makeline (
	(SELECT geom FROM airportsNew WHERE name = 'ANNETTE ISLAND'), 
	(SELECT geom FROM airportsNew WHERE name = 'ATKA')))),111);


--zad6
--Wyznacz pole powierzchni obszaru, który oddalony jest o mniej niż 1000 jednostek od najkrótszej linii łączącej 
--jezioro o nazwie 'Iliamna Lake' i lotnisko o nazwie 'AMBLER'. 

SELECT ST_Area(ST_Buffer(ST_ShortestLine (pa.geom, pl.geom), 1000))
	FROM public.lakes AS pl, public.airports AS pa
		WHERE pl.names='Iliamna Lake' AND pa.name='AMBLER';
		
		
--zad7
--Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących poszczególne typy drzew znajdujących się 
--na obszarze tundry i bagien. 

SELECT SUM(ST_Area(tr.geom)),tr.vegdesc
	FROM public.trees AS tr, public.tundra AS tun, public.swamp AS sw
		WHERE ST_Within(tr.geom,tun.geom) OR ST_Within(tr.geom,sw.geom)
		GROUP BY tr.vegdesc






--UPDATE public.majrivers SET geom = ST_SETSRID(geom,3338)

