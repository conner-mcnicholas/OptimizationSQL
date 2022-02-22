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

EXPLAIN ANALYZE SELECT name FROM Student WHERE id IN (SELECT studId FROM Transcript WHERE crsCode = @v4);
/*
-> Nested loop inner join  (cost=1.22 rows=2) (actual time=0.096..0.108 rows=2 loops=1)
    -> Filter: (`<subquery2>`.studId is not null)  (cost=0.65..0.40 rows=2) (actual time=0.073..0.075 rows=2 loops=1)
        -> Table scan on <subquery2>  (cost=1.26..2.52 rows=2) (actual time=0.002..0.002 rows=2 loops=1)
            -> Materialize with deduplication  (cost=2.16..3.42 rows=2) (actual time=0.072..0.073 rows=2 loops=1)
                -> Filter: (Transcript.studId is not null)  (cost=0.70 rows=2) (actual time=0.043..0.056 rows=2 loops=1)
                    -> Index lookup on Transcript using crsind (crsCode=''MGT382'')  (cost=0.70 rows=2) (actual time=0.041..0.054 rows=2 loops=1)
    -> Single-row index lookup on Student using PRIMARY (id=`<subquery2>`.studId)  (cost=0.72 rows=1) (actual time=0.015..0.015 rows=1 loops=2)
*/

--Total time decreased from 1.2 to .064 after putting index on Transcript.crsCode and adding PRIMARY KEY on Student.id

EXPLAIN ANALYZE SELECT name from Student LEFT JOIN Transcript ON Student.id = Transcript.studId WHERE crsCode = @v4;

/*
-> Nested loop inner join  (cost=2.15 rows=2) (actual time=0.028..0.035 rows=2 loops=1)
    -> Filter: (Transcript.studId is not null)  (cost=0.70 rows=2) (actual time=0.018..0.023 rows=2 loops=1)
        -> Index lookup on Transcript using crsind (crsCode=''MGT382'')  (cost=0.70 rows=2) (actual time=0.017..0.022 rows=2 loops=1)
    -> Single-row index lookup on Student using PRIMARY (id=Transcript.studId)  (cost=0.68 rows=1) (actual time=0.005..0.005 rows=1 loops=2)

*/

--Time descreased further to .035 after converting the first WHERE IN clause to a LEFT JOIN on the ids, thus removing a table scan step from query plan

SELECT name from Student LEFT JOIN Transcript ON Student.id = Transcript.studId WHERE crsCode = @v4;
/*
+--------------+
| name         |
+--------------+
| Amber Hill   |
| Lucia Warren |
+--------------+
*/
