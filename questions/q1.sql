-- 1. List the name of the student with id equal to v1 (id).
USE springboardopt;
SET @v1 = 1612521;

EXPLAIN ANALYZE SELECT name FROM Student WHERE id = @v1;
---> Filter: (Student.id = <cache>((@v1)))  (cost=41.00 rows=40) (actual time=0.306..1.199 rows=1 loops=1)
--  -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.077..1.079 rows=400 loops=1)

ALTER TABLE Student ADD PRIMARY KEY(id);

EXPLAIN ANALYZE SELECT name FROM Student WHERE id = @v1;
---> Rows fetched before execution  (cost=0.00..0.00 rows=1) (actual time=0.000..0.001 rows=1 loops=1

--total time decreased from 1.199 to .001 after putting PRIMARY KEY on id column

SELECT name FROM Student WHERE id = @v1;
/*
+---------------+
| name          |
+---------------+
| Eddy Harrison |
+---------------+
*/
