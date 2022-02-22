-- 5. List the names of students who have taken a course from department v6 (deptId), but not v7.
EXPLAIN ANALYZE SELECT name FROM Student,
	(SELECT studId FROM Transcript, Course WHERE deptId = @v6 AND Course.crsCode = Transcript.crsCode
	AND studId NOT IN
	(SELECT studId FROM Transcript, Course WHERE deptId = @v7 AND Course.crsCode = Transcript.crsCode)) as alias
WHERE Student.id = alias.studId;

/*
-> Filter: <in_optimizer>(Transcript.studId,<exists>(select #3) is false)  (cost=4112.69 rows=4000) (actual time=1.717..26.522 rows=30 loops=1)
    -> Inner hash join (Student.id = Transcript.studId)  (cost=4112.69 rows=4000) (actual time=0.888..2.029 rows=30 loops=1)
        -> Table scan on Student  (cost=0.06 rows=400) (actual time=0.016..0.973 rows=400 loops=1)
        -> Hash
            -> Filter: (Transcript.crsCode = Course.crsCode)  (cost=110.52 rows=100) (actual time=0.441..0.762 rows=30 loops=1)
                -> Inner hash join (<hash>(Transcript.crsCode)=<hash>(Course.crsCode))  (cost=110.52 rows=100) (actual time=0.439..0.738 rows=30 loops=1)
                    -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.015..0.233 rows=100 loops=1)
                    -> Hash
                        -> Filter: (Course.deptId = <cache>((@v6)))  (cost=10.25 rows=10) (actual time=0.067..0.357 rows=26 loops=1)
                            -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.053..0.280 rows=100 loops=1)
    -> Select #3 (subquery in condition; dependent)
        -> Limit: 1 row(s)  (cost=110.52 rows=1) (actual time=0.804..0.804 rows=0 loops=30)
            -> Filter: <if>(outer_field_is_not_null, <is_not_null_test>(Transcript.studId), true)  (cost=110.52 rows=100) (actual time=0.803..0.803 rows=0 loops=30)
                -> Filter: (<if>(outer_field_is_not_null, ((<cache>(Transcript.studId) = Transcript.studId) or (Transcript.studId is null)), true) and (Transcript.crsCode = Course.crsCode))  (cost=110.52 rows=100) (actual time=0.802..0.802 rows=0 loops=30)
                    -> Inner hash join (<hash>(Transcript.crsCode)=<hash>(Course.crsCode))  (cost=110.52 rows=100) (actual time=0.432..0.781 rows=34 loops=30)
                        -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.010..0.281 rows=100 loops=30)
                        -> Hash
                            -> Filter: (Course.deptId = <cache>((@v7)))  (cost=10.25 rows=10) (actual time=0.024..0.357 rows=32 loops=30)
                                -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.009..0.285 rows=100 loops=30)
*/
CREATE INDEX crsind ON Transcript (crsCode);
CREATE INDEX studid ON Transcript(studId);
CREATE INDEX crsind ON Course (crsCode);
ALTER TABLE Student ADD PRIMARY KEY(id);

/*EXPLAIN ANALYZE...
-> Nested loop inner join  (cost=21.33 rows=10) (actual time=0.095..0.756 rows=30 loops=1)
    -> Nested loop inner join  (cost=13.86 rows=10) (actual time=0.051..0.283 rows=30 loops=1)
        -> Filter: ((Course.deptId = <cache>((@v6))) and (Course.crsCode is not null))  (cost=10.25 rows=10) (actual time=0.029..0.136 rows=26 loops=1)
            -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.022..0.105 rows=100 loops=1)
        -> Filter: (Transcript.studId is not null)  (cost=0.27 rows=1) (actual time=0.004..0.005 rows=1 loops=26)
            -> Index lookup on Transcript using crsind (crsCode=Course.crsCode)  (cost=0.27 rows=1) (actual time=0.004..0.005 rows=1 loops=26)
    -> Filter: <in_optimizer>(Transcript.studId,<exists>(select #3) is false)  (cost=0.63 rows=1) (actual time=0.015..0.015 rows=1 loops=30)
        -> Single-row index lookup on Student using PRIMARY (id=Transcript.studId)  (cost=0.63 rows=1) (actual time=0.002..0.002 rows=1 loops=30)
        -> Select #3 (subquery in condition; dependent)
            -> Limit: 1 row(s)  (cost=1.42 rows=0) (actual time=0.012..0.012 rows=0 loops=30)
                -> Filter: <if>(outer_field_is_not_null, <is_not_null_test>(Transcript.studId), true)  (cost=1.42 rows=0) (actual time=0.012..0.012 rows=0 loops=30)
                    -> Nested loop inner join  (cost=1.42 rows=0) (actual time=0.012..0.012 rows=0 loops=30)
                        -> Filter: (<if>(outer_field_is_not_null, ((<cache>(Transcript.studId) = Transcript.studId) or (Transcript.studId is null)), true) and (Transcript.crsCode is not null))  (cost=0.70 rows=2) (actual time=0.004..0.006 rows=1 loops=30)
                            -> Alternative plans for IN subquery: Index lookup unless studId IS NULL  (cost=0.70 rows=2) (actual time=0.004..0.006 rows=1 loops=30)
                                -> Index lookup on Transcript using studid (studId=<cache>(Transcript.studId) or NULL)  (actual time=0.003..0.005 rows=1 loops=30)
                                -> Table scan on Transcript  (never executed)
                        -> Filter: (Course.deptId = <cache>((@v7)))  (cost=0.26 rows=0) (actual time=0.005..0.005 rows=0 loops=30)
                            -> Index lookup on Course using crsind (crsCode=Transcript.crsCode)  (cost=0.26 rows=1) (actual time=0.003..0.005 rows=1 loops=30)
*/

--total time dropped from 26.522 to .756 after adding indexes on Transcript.studId/crsCode, Course.crsCode, and PRIMARY KEY on Student.id

SELECT name FROM Student,(SELECT studId FROM Transcript, Course WHERE deptId = @v6 AND Course.crsCode = Transcript.crsCode
AND studId NOT IN
(SELECT studId FROM Transcript, Course WHERE deptId = @v7 AND Course.crsCode = Transcript.crsCode)) AS alias
WHERE Student.id = alias.studId;

/*
+-------------------+
| name              |
+-------------------+
| Brianna Armstrong |
| Ada Ross          |
| Jack Jones        |
| Sienna Mitchell   |
| Lucia Warren      |
| Lucia Warren      |
| Olivia Craig      |
| Lilianna Brown    |
| Jared Kelley      |
| Adele Morgan      |
| Adele Morgan      |
| Amber Hill        |
| Amber Hill        |
| Heather Crawford  |
| Samantha Evans    |
| Julia Campbell    |
| Eddy Harrison     |
| Amanda Davis      |
| Cherry Elliott    |
| Maria Howard      |
| Lucas Tucker      |
| Kristian Higgins  |
| Kristian Higgins  |
| Abraham Mitchell  |
| Dominik Bailey    |
| Maya Campbell     |
| Tara Harrison     |
| Deanna Holmes     |
| Robert Warren     |
| Briony Carter     |
+-------------------+
*/
