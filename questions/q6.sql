-- 6. List the names of students who have taken all courses offered by department v8 (deptId).
SELECT name FROM Student,
	(SELECT studId
	FROM Transcript
		WHERE crsCode IN
		(SELECT crsCode FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching))
		GROUP BY studId
		HAVING COUNT(*) <=
			(SELECT COUNT(*) FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching))) as alias
WHERE id = alias.studId;

/*
EXPLAIN ANALYZE ...
-> Nested loop inner join  (cost=1041.00 rows=0) (actual time=2.152..3.745 rows=19 loops=1)
    -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.052..0.908 rows=400 loops=1)
    -> Covering index lookup on alias using <auto_key0> (studId=Student.id)  (actual time=0.001..0.001 rows=0 loops=400)
        -> Materialize  (cost=0.00..0.00 rows=0) (actual time=2.636..2.648 rows=19 loops=1)
            -> Filter: (count(0) <= (select #5))  (actual time=1.968..1.983 rows=19 loops=1)
                -> Table scan on <temporary>  (actual time=0.001..0.005 rows=19 loops=1)
                    -> Aggregate using temporary table  (actual time=1.229..1.236 rows=19 loops=1)
                        -> Nested loop inner join  (cost=1020.25 rows=10000) (actual time=0.779..1.189 rows=19 loops=1)
                            -> Filter: (Transcript.crsCode is not null)  (cost=10.25 rows=100) (actual time=0.016..0.246 rows=100 loops=1)
                                -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.015..0.223 rows=100 loops=1)
                            -> Single-row index lookup on <subquery3> using <auto_distinct_key> (crsCode=Transcript.crsCode)  (actual time=0.001..0.001 rows=0 loops=100)
                                -> Materialize with deduplication  (cost=120.52..120.52 rows=100) (actual time=0.902..0.907 rows=19 loops=1)
                                    -> Filter: (Course.crsCode is not null)  (cost=110.52 rows=100) (actual time=0.416..0.704 rows=19 loops=1)
                                        -> Filter: (Teaching.crsCode = Course.crsCode)  (cost=110.52 rows=100) (actual time=0.415..0.698 rows=19 loops=1)
                                            -> Inner hash join (<hash>(Teaching.crsCode)=<hash>(Course.crsCode))  (cost=110.52 rows=100) (actual time=0.413..0.683 rows=19 loops=1)
                                                -> Table scan on Teaching  (cost=0.13 rows=100) (actual time=0.012..0.221 rows=100 loops=1)
                                                -> Hash
                                                    -> Filter: (Course.deptId = 'MAT')  (cost=10.25 rows=10) (actual time=0.024..0.337 rows=19 loops=1)
                                                        -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.010..0.269 rows=100 loops=1)
                -> Select #5 (subquery in condition; run only once)
                    -> Aggregate: count(0)  (cost=211.25 rows=1000) (actual time=0.709..0.709 rows=1 loops=1)
                        -> Nested loop inner join  (cost=111.25 rows=1000) (actual time=0.394..0.698 rows=19 loops=1)
                            -> Filter: ((Course.deptId = 'MAT') and (Course.crsCode is not null))  (cost=10.25 rows=10) (actual time=0.022..0.279 rows=19 loops=1)
                                -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.015..0.219 rows=100 loops=1)
                            -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=Course.crsCode)  (actual time=0.002..0.002 rows=1 loops=19)
                                -> Materialize with deduplication  (cost=20.25..20.25 rows=100) (actual time=0.404..0.409 rows=97 loops=1)
                                    -> Filter: (Teaching.crsCode is not null)  (cost=10.25 rows=100) (actual time=0.007..0.215 rows=100 loops=1)
                                        -> Table scan on Teaching  (cost=10.25 rows=100) (actual time=0.007..0.194 rows=100 loops=1)
*/
CREATE TEMP TABLE matstud AS SELECT studId
FROM Transcript
WHERE crsCode IN
(SELECT crsCode FROM Course WHERE deptId = 'MAT' AND crsCode IN (SELECT crsCode FROM Teaching))
GROUP BY studId
HAVING COUNT(*) <=
(SELECT COUNT(*) FROM Course WHERE deptId = 'MAT' AND crsCode IN (SELECT crsCode FROM Teaching));

ALTER TABLE matstud ADD PRIMARY KEY(studId);
ALTER TABLE Student ADD PRIMARY KEY(id);

/*
EXPLAIN ANALYZE...
-'-> Nested loop inner join  (cost=16.68 rows=19) (actual time=0.047..0.100 rows=19 loops=1)
    -> Covering index scan on matstud using PRIMARY  (cost=2.90 rows=19) (actual time=0.022..0.027 rows=19 loops=1)
    -> Single-row index lookup on Student using PRIMARY (id=matstud.studId)  (cost=0.63 rows=1) (actual time=0.004..0.004 rows=1 loops=19)
'*/
--Total time decreased from 3.8 to .047 after creating temporary table for both subqueries and adding the studid col and Student.id as PRIMARY KEYs

SELECT name FROM Student, matstud WHERE Student.id = matstud.studId;
/*
+------------------+
| name             |
+------------------+
| Sienna Foster    |
| Dominik Morris   |
| Marcus Williams  |
| Harold Brown     |
| Aiden Nelson     |
| Emily Barrett    |
| Miller Craig     |
| Jack Miller      |
| Leonardo Hall    |
| Lydia Holmes     |
| Emma Adams       |
| Nicholas Riley   |
| Miley Cunningham |
| Maddie Cooper    |
| Alford Thompson  |
| Abigail Farrell  |
| Steven Mitchell  |
| Joyce Robinson   |
| James Andrews    |
+------------------+
*/
