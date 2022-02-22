-- 4. List the names of students who have taken a course taught by professor v5 (name).
SELECT name FROM Student,
	(SELECT studId FROM Transcript,
		(SELECT crsCode, semester FROM Professor
			JOIN Teaching
			WHERE Professor.name = @v5 AND Professor.id = Teaching.profId) as alias1
	WHERE Transcript.crsCode = alias1.crsCode AND Transcript.semester = alias1.semester) as alias2
WHERE Student.id = alias2.studId;

/*EXPLAIN ANALYZE
-> Nested loop inner join  (cost=61.28 rows=1) (actual time=2.820..2.820 rows=0 loops=1)
    -> Nested loop inner join  (cost=53.81 rows=10) (actual time=2.819..2.819 rows=0 loops=1)
        -> Nested loop inner join  (cost=46.33 rows=10) (actual time=2.818..2.818 rows=0 loops=1)
            -> Filter: ((Teaching.crsCode is not null) and (Teaching.profId is not null))  (cost=10.25 rows=100) (actual time=0.072..0.598 rows=100 loops=1)
                -> Table scan on Teaching  (cost=10.25 rows=100) (actual time=0.067..0.526 rows=100 loops=1)
            -> Filter: ((Transcript.semester = Teaching.semester) and (Transcript.studId is not null))  (cost=0.26 rows=0) (actual time=0.022..0.022 rows=0 loops=100)
                -> Index lookup on Transcript using crsind (crsCode=Teaching.crsCode)  (cost=0.26 rows=1) (actual time=0.015..0.020 rows=1 loops=100)
        -> Single-row index lookup on Student using PRIMARY (id=Transcript.studId)  (cost=0.63 rows=1) (never executed)
    -> Filter: (Professor.`name` = <cache>((@v5)))  (cost=0.63 rows=0) (never executed)
        -> Single-row index lookup on Professor using PRIMARY (id=Teaching.profId)  (cost=0.63 rows=1) (never executed)
*/

CREATE TEMPORARY TABLE ambstud AS
SELECT studId FROM Transcript,
		(SELECT crsCode, semester FROM Professor
			JOIN Teaching
			WHERE Professor.name = @v5 AND Professor.id = Teaching.profId) as alias1
	WHERE Transcript.crsCode = alias1.crsCode AND Transcript.semester = alias1.semester;

ALTER TABLE ambstud ADD PRIMARY KEY (studId);
ALTER TABLE Student ADD PRIMARY KEY(id);


EXPLAIN ANALYZE SELECT name FROM Student,ambstud;
/*
-> Nested loop inner join  (cost=1.83 rows=1) (actual time=0.046..0.046 rows=0 loops=1)
	  -> Covering index scan on ambstud using PRIMARY  (cost=1.10 rows=1) (actual time=0.044..0.044 rows=0 loops=1)
	  -> Single-row index lookup on Student using PRIMARY (id=ambstud.studId)  (cost=0.72 rows=1) (never executed)
*/

--Total time dropped from 2.82 to .046 after adding PRIMARY KEY to Student.id, and creating temp table to store subquery + addding PRIMARY KEY to its col studId

SELECT name FROM Student,ambstud;
--Empty set 
