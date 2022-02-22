-- 3. List the names of students who have taken course v4 (crsCode).
EXPLAIN ANALYZE SELECT name FROM Student WHERE id IN (SELECT studId FROM Transcript WHERE crsCode = @v4);
---> Inner hash join (Student.id = `<subquery2>`.studId)  (cost=414.91 rows=400) (actual time=0.597..1.200 rows=2 loops=1)
--    -> Table scan on Student  (cost=5.04 rows=400) (actual time=0.017..0.738 rows=400 loops=1)
--    -> Hash
--        -> Table scan on <subquery2>  (cost=0.26..2.62 rows=10) (actual time=0.002..0.002 rows=2 loops=1)
--            -> Materialize with deduplication  (cost=11.51..13.88 rows=10) (actual time=0.313..0.314 rows=2 loops=1)
--                -> Filter: (Transcript.studId is not null)  (cost=10.25 rows=10) (actual time=0.128..0.294 rows=2 loops=1)
--                    -> Filter: (Transcript.crsCode = <cache>((@v4)))  (cost=10.25 rows=10) (actual time=0.126..0.291 rows=2 loops=1)
--                        -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.046..0.234 rows=100 loops=1)

CREATE INDEX crsind ON Transcript (crsCode);
ALTER TABLE Student ADD PRIMARY KEY(id);

---> Nested loop inner join  (cost=1.22 rows=2) (actual time=0.057..0.064 rows=2 loops=1)
--    -> Filter: (`<subquery2>`.studId is not null)  (cost=0.65..0.40 rows=2) (actual time=0.044..0.045 rows=2 loops=1)
--        -> Table scan on <subquery2>  (cost=1.26..2.52 rows=2) (actual time=0.001..0.001 rows=2 loops=1)
--            -> Materialize with deduplication  (cost=2.16..3.42 rows=2) (actual time=0.044..0.044 rows=2 loops=1)
--                -> Filter: (Transcript.studId is not null)  (cost=0.70 rows=2) (actual time=0.025..0.034 rows=2 loops=1)
--                    -> Index lookup on Transcript using crsind (crsCode=(@v4))  (cost=0.70 rows=2) (actual time=0.024..0.033 rows=2 loops=1)
--    -> Single-row index lookup on Student using PRIMARY (id=`<subquery2>`.studId)  (cost=0.72 rows=1) (actual time=0.008..0.008 rows=1 loops=2)

--Total time decreased from 1.2 to .064 after putting index on Transcript.crsCode and adding PRIMARY KEY on Student.id

SELECT name FROM Student WHERE id IN (SELECT studId FROM Transcript WHERE crsCode = @v4);
/*
+--------------+
| name         |
+--------------+
| Amber Hill   |
| Lucia Warren |
+--------------+
*/
