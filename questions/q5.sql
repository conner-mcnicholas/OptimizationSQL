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
CREATE INDEX crsind ON Course (deptId,crsCode);
ALTER TABLE Student ADD PRIMARY KEY(id);

/*EXPLAIN ANALYZE...
'-> Nested loop inner join  (cost=33.23 rows=27) (actual time=0.067..0.585 rows=30 loops=1)
    -> Nested loop inner join  (cost=13.79 rows=27) (actual time=0.030..0.182 rows=30 loops=1)
        -> Filter: (Course.crsCode is not null)  (cost=4.41 rows=26) (actual time=0.017..0.044 rows=26 loops=1)
            -> Covering index lookup on Course using crsind (deptId=(@v6))  (cost=4.41 rows=26) (actual time=0.016..0.040 rows=26 loops=1)
        -> Filter: (Transcript.studId is not null)  (cost=0.26 rows=1) (actual time=0.004..0.005 rows=1 loops=26)
            -> Index lookup on Transcript using crsind (crsCode=Course.crsCode)  (cost=0.26 rows=1) (actual time=0.004..0.005 rows=1 loops=26)
    -> Filter: <in_optimizer>(Transcript.studId,<exists>(select #3) is false)  (cost=0.63 rows=1) (actual time=0.013..0.013 rows=1 loops=30)
        -> Single-row index lookup on Student using PRIMARY (id=Transcript.studId)  (cost=0.63 rows=1) (actual time=0.003..0.003 rows=1 loops=30)
        -> Select #3 (subquery in condition; dependent)
            -> Limit: 1 row(s)  (cost=1.41 rows=1) (actual time=0.009..0.009 rows=0 loops=30)
                -> Filter: <if>(outer_field_is_not_null, <is_not_null_test>(Transcript.studId), true)  (cost=1.41 rows=2) (actual time=0.009..0.009 rows=0 loops=30)
                    -> Nested loop inner join  (cost=1.41 rows=2) (actual time=0.009..0.009 rows=0 loops=30)
                        -> Filter: (<if>(outer_field_is_not_null, ((<cache>(Transcript.studId) = Transcript.studId) or (Transcript.studId is null)), true) and (Transcript.crsCode is not null))  (cost=0.70 rows=2) (actual time=0.003..0.005 rows=1 loops=30)
                            -> Alternative plans for IN subquery: Index lookup unless studId IS NULL  (cost=0.70 rows=2) (actual time=0.003..0.005 rows=1 loops=30)
                                -> Index lookup on Transcript using studid (studId=<cache>(Transcript.studId) or NULL)  (actual time=0.003..0.005 rows=1 loops=30)
                                -> Table scan on Transcript  (never executed)
                        -> Covering index lookup on Course using crsind (deptId=(@v7), crsCode=Transcript.crsCode)  (cost=0.30 rows=1) (actual time=0.003..0.003 rows=0 loops=30)
'
*/

--total time dropped from 26.522 to .585 after adding indexes on Transcript.studId/crsCode, Course.crsCode, and PRIMARY KEY on Student.id

CREATE TEMPORARY TABLE depstud AS SELECT studId FROM Transcript, Course WHERE deptId = 'MGT'  AND Course.crsCode = Transcript.crsCode
AND studId NOT IN
(SELECT studId FROM Transcript, Course WHERE deptId =  'EE' AND Course.crsCode = Transcript.crsCode);
CREATE INDEX studind ON depstud(studId);

/*EXPLAIN ANALYZE EXPLAIN ANALYZE SELECT name FROM Student,depstud WHERE Student.id = depstud.studId;
-> Nested loop inner join  (cost=25.00 rows=30) (actual time=0.039..0.117 rows=30 loops=1)
  -> Filter: (depstud.studId is not null)  (cost=3.25 rows=30) (actual time=0.023..0.051 rows=30 loops=1)
      -> Covering index scan on depstud using studind  (cost=3.25 rows=30) (actual time=0.023..0.048 rows=30 loops=1)
  -> Single-row index lookup on Student using PRIMARY (id=depstud.studId)  (cost=0.63 rows=1) (actual time=0.002..0.002 rows=1 loops=30)
*/
--total time descreased down to .117 after creating temporary table from subquery and putting index on its studId column

SELECT name FROM Student,depstud WHERE Student.id = depstud.studId;
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
