-- =============================================================================
-- Laboratory Work #3 - Advanced DML Operations
-- File: lab3_advanced_dml.sql
-- DBMS: PostgreSQL
--
-- How to run (psql):   psql -U postgres -f lab3_advanced_dml.sql
-- In pgAdmin/DataGrip: run the CREATE DATABASE part, connect to advanced_lab,
--                      then run everything from Part A (tables) onward.
-- =============================================================================


-- =============================================================================
-- Part A: Database and Table Setup
-- =============================================================================

-- 1. Create database and tables
DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab;

-- psql meta-command: connect to the new database
\c advanced_lab

DROP TABLE IF EXISTS employee_archive;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    department  VARCHAR(50),                         -- NULL allowed (no department yet)
    salary      INTEGER CHECK (salary >= 0),         -- NULL allowed; no DEFAULT, so DEFAULT = NULL
    hire_date   DATE,
    status      VARCHAR(20) NOT NULL DEFAULT 'Active'
                CHECK (status IN ('Active', 'Inactive', 'Terminated', 'Senior', 'Promoted'))
);

CREATE TABLE departments (
    dept_id     SERIAL PRIMARY KEY,
    dept_name   VARCHAR(50) NOT NULL UNIQUE,
    budget      INTEGER CHECK (budget >= 0),
    manager_id  INTEGER REFERENCES employees (emp_id)
                ON DELETE SET NULL                   -- manager deleted -> department keeps existing
);

CREATE TABLE projects (
    project_id    SERIAL PRIMARY KEY,
    project_name  VARCHAR(100) NOT NULL,
    dept_id       INTEGER REFERENCES departments (dept_id)
                  ON DELETE SET NULL,                -- department deleted -> project becomes unassigned
    start_date    DATE,
    end_date      DATE,
    budget        INTEGER CHECK (budget >= 0),
    CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);


-- ---------------------------------------------------------------------------
-- Sample data (used to test all queries below)
-- ---------------------------------------------------------------------------
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES
    ('Aibek',    'Nurlanov',   'IT',        95000,  '2018-03-15', 'Active'),     -- emp_id 1
    ('Dana',     'Serikova',   'IT',        72000,  '2021-06-01', 'Active'),     -- emp_id 2
    ('Arman',    'Kassymov',   'IT',        68000,  '2022-02-10', 'Active'),     -- emp_id 3
    ('Aliya',    'Tulegenova', 'IT',        120000, '2019-11-20', 'Active'),     -- emp_id 4
    ('Nurlan',   'Akhmetov',   'IT',        60000,  '2023-04-05', 'Active'),     -- emp_id 5
    ('Madina',   'Omarova',    'Sales',     48000,  '2020-08-12', 'Active'),     -- emp_id 6
    ('Yerlan',   'Bekov',      'Sales',     52000,  '2021-09-30', 'Active'),     -- emp_id 7
    ('Saule',    'Ismailova',  'Marketing', 45000,  '2022-05-18', 'Inactive'),   -- emp_id 8
    ('Timur',    'Zhakupov',   'Marketing', 39000,  '2019-02-01', 'Terminated'), -- emp_id 9
    ('Aigerim',  'Sadykova',   NULL,        32000,  '2023-06-15', 'Active'),     -- emp_id 10
    ('Kairat',   'Mukanov',    'Marketing', 67000,  '2020-03-01', 'Inactive');   -- emp_id 11

INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('IT',        150000, 1),
    ('Sales',     90000,  6),
    ('Marketing', 70000,  NULL);

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES
    ('ERP Migration',    1, '2024-01-15', '2025-06-30', 120000),
    ('Website Redesign', 1, '2022-03-01', '2022-12-15', 45000),
    ('Helpdesk Bot',     1, '2025-02-01', '2025-11-30', 30000),
    ('CRM Rollout',      2, '2024-05-01', '2025-03-31', 80000),
    ('Old Campaign',     3, '2021-01-10', '2022-06-30', 25000),
    ('Brand Launch',     3, '2023-02-01', '2024-08-31', 60000),
    ('Data Warehouse',   1, '2025-01-01', NULL,         200000);  -- no end date yet


-- =============================================================================
-- Part B: Advanced INSERT Operations
-- =============================================================================

-- 2. INSERT with column specification
-- Only 4 columns are listed; the rest get their defaults:
-- salary -> NULL, hire_date -> NULL, status -> 'Active'.
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (12, 'Asel', 'Karimova', 'IT');

-- emp_id was given manually, so the SERIAL sequence did not move (it is still at 11).
-- Without this line the next INSERT would try emp_id = 12 and fail with a duplicate key.
SELECT setval('employees_emp_id_seq', (SELECT MAX(emp_id) FROM employees));


-- 3. INSERT with DEFAULT values
-- salary has no DEFAULT clause, so DEFAULT gives NULL; status DEFAULT gives 'Active'.
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Ermek', 'Sultanov', 'Sales', DEFAULT, '2022-01-10', DEFAULT);

SELECT emp_id, first_name, salary, status
FROM employees
WHERE first_name = 'Ermek';


-- 4. INSERT multiple rows in single statement
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('HR',        60000, NULL),
    ('Finance',   85000, NULL),
    ('Logistics', 75000, NULL);


-- 5. INSERT with expressions
-- 50000 * 1.1 = 55000.0 (NUMERIC); PostgreSQL casts it to INTEGER on assignment.
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Gulnara', 'Abdirova', 'IT', 50000 * 1.1, CURRENT_DATE);

SELECT first_name, salary, hire_date
FROM employees
WHERE first_name = 'Gulnara';


-- 6. INSERT from SELECT (subquery)
-- LIKE copies column names, types and NOT NULL; the temp table disappears
-- automatically when the session ends.
CREATE TEMP TABLE temp_employees (LIKE employees);

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

SELECT emp_id, first_name, last_name, department
FROM temp_employees;


-- =============================================================================
-- Part C: Complex UPDATE Operations
-- =============================================================================

-- 7. UPDATE with arithmetic expressions
-- NULL * 1.10 = NULL, so employees with NULL salary stay NULL.
UPDATE employees
SET salary = salary * 1.10;


-- 8. UPDATE with WHERE clause and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01'
RETURNING emp_id, first_name, salary, hire_date, status;


-- 9. UPDATE using CASE expression
-- This query overwrites real department names (IT, Sales, ...) with salary levels.
-- It is run inside a transaction and rolled back so that the tasks below that
-- filter by 'IT' / 'Sales' still have meaningful data.
BEGIN;

UPDATE employees
SET department = CASE
                     WHEN salary > 80000                 THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'   -- also catches NULL salary (NULL > 80000 is not TRUE)
                 END
RETURNING emp_id, first_name, salary, department;

ROLLBACK;


-- 10. UPDATE with DEFAULT
-- department has no DEFAULT clause, so DEFAULT sets it to NULL.
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive'
RETURNING emp_id, first_name, department, status;


-- 11. UPDATE with subquery
-- Correlated subquery: for every department row, compute the average salary of
-- employees whose department name matches. AVG ignores NULL salaries.
-- EXISTS keeps departments without employees unchanged (otherwise budget = NULL).
UPDATE departments d
SET budget = (
        SELECT AVG(e.salary) * 1.20
        FROM employees e
        WHERE e.department = d.dept_name
    )
WHERE EXISTS (
        SELECT 1
        FROM employees e
        WHERE e.department = d.dept_name
    )
RETURNING dept_id, dept_name, budget;


-- 12. UPDATE multiple columns
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales'
RETURNING emp_id, first_name, salary, status;


-- =============================================================================
-- Part D: Advanced DELETE Operations
-- =============================================================================

-- 13. DELETE with simple WHERE condition
DELETE FROM employees
WHERE status = 'Terminated'
RETURNING emp_id, first_name, last_name, status;


-- 14. DELETE with complex WHERE clause
-- "department IS NULL" must be used; "department = NULL" is never TRUE.
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL
RETURNING emp_id, first_name, salary, hire_date, department;


-- 15. DELETE with subquery
-- employees.department stores the department NAME (VARCHAR), while dept_id is
-- INTEGER, so "dept_id NOT IN (SELECT department ...)" would fail with a type
-- error. The same logic is applied by comparing dept_name instead.
-- "IS NOT NULL" in the subquery is required: if the list contained a NULL,
-- NOT IN would return NULL for every row and nothing would be deleted.
DELETE FROM departments
WHERE dept_name NOT IN (
        SELECT DISTINCT department
        FROM employees
        WHERE department IS NOT NULL
    )
RETURNING dept_id, dept_name;


-- 16. DELETE with RETURNING clause
-- Projects with NULL end_date are kept (NULL < date is not TRUE).
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;


-- =============================================================================
-- Part E: Operations with NULL Values
-- =============================================================================

-- 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Bolat', 'Abenov', NULL, NULL, '2024-02-01')
RETURNING *;


-- 18. UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL
RETURNING emp_id, first_name, department;


-- 19. DELETE with NULL conditions
-- After task 18 no department is NULL anymore, so here rows are removed only
-- by the "salary IS NULL" part (employees from tasks 2, 3 and 17).
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL
RETURNING emp_id, first_name, salary, department;


-- =============================================================================
-- Part F: RETURNING Clause Operations
-- =============================================================================

-- 20. INSERT with RETURNING
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Zhanna', 'Kenzhebayeva', 'Sales', 70000, '2024-09-01')
RETURNING emp_id,
          first_name || ' ' || last_name AS full_name;


-- 21. UPDATE with RETURNING
-- In PostgreSQL 17 and earlier RETURNING only sees the NEW row, so the old
-- salary is calculated back as (new salary - 5000).
-- (PostgreSQL 18+ also allows: RETURNING emp_id, old.salary, new.salary)
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id,
          salary - 5000 AS old_salary,
          salary        AS new_salary;


-- 22. DELETE with RETURNING all columns
-- Deleting employees 1 and 4 also sets departments.manager_id to NULL
-- (ON DELETE SET NULL on the foreign key).
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;


-- =============================================================================
-- Part G: Advanced DML Patterns
-- =============================================================================

-- 23. Conditional INSERT
-- INSERT ... SELECT without FROM returns one row only if WHERE is TRUE,
-- so the employee is added only when no one with the same name exists.
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Ruslan', 'Abdrakhmanov', 'IT', 65000, '2025-03-10'
WHERE NOT EXISTS (
        SELECT 1
        FROM employees
        WHERE first_name = 'Ruslan'
          AND last_name  = 'Abdrakhmanov'
    );

-- Test: running the same INSERT again inserts 0 rows (the person already exists).
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Ruslan', 'Abdrakhmanov', 'IT', 65000, '2025-03-10'
WHERE NOT EXISTS (
        SELECT 1
        FROM employees
        WHERE first_name = 'Ruslan'
          AND last_name  = 'Abdrakhmanov'
    );


-- 24. UPDATE with JOIN logic using subqueries
-- The correlated subquery finds the budget of the employee's department:
-- budget > 100000 -> +10 %, otherwise -> +5 %.
-- EXISTS restricts the update to employees whose department exists in
-- the departments table (e.g. 'Unassigned' employees are not changed).
UPDATE employees e
SET salary = e.salary * CASE
                            WHEN (SELECT d.budget
                                  FROM departments d
                                  WHERE d.dept_name = e.department) > 100000
                                THEN 1.10
                            ELSE 1.05
                        END
WHERE EXISTS (
        SELECT 1
        FROM departments d
        WHERE d.dept_name = e.department
    )
RETURNING emp_id, first_name, department, salary;


-- 25. Bulk operations
-- One INSERT with 5 rows ...
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
    ('Daniyar', 'Kuanyshev',  'IT',        61000, '2025-01-20'),
    ('Kamila',  'Zhumabek',   'IT',        59000, '2025-02-14'),
    ('Askar',   'Temirov',    'IT',        64000, '2025-04-01'),
    ('Aruzhan', 'Nurpeisova', 'Marketing', 47000, '2025-05-05'),
    ('Sanzhar', 'Utepov',     'Marketing', 50000, '2025-06-18');

-- ... then one UPDATE for exactly these 5 employees (row-value IN list).
UPDATE employees
SET salary = salary * 1.10
WHERE (first_name, last_name) IN (
        ('Daniyar', 'Kuanyshev'),
        ('Kamila',  'Zhumabek'),
        ('Askar',   'Temirov'),
        ('Aruzhan', 'Nurpeisova'),
        ('Sanzhar', 'Utepov')
    )
RETURNING emp_id, first_name, last_name, salary;


-- 26. Data migration simulation
-- Archive table with the same structure as employees.
CREATE TABLE employee_archive (LIKE employees INCLUDING ALL);

-- Copy + delete in one transaction: either both happen or neither does,
-- so no employee can be lost or duplicated.
BEGIN;

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

COMMIT;

SELECT emp_id, first_name, last_name, status
FROM employee_archive;


-- 27. Complex business logic
-- DATE + INTEGER adds days and keeps the DATE type.
-- The subquery counts employees of the project's department
-- (projects.dept_id -> departments.dept_name -> employees.department).
-- NULL end_date stays NULL (NULL + 30 = NULL).
UPDATE projects p
SET end_date = p.end_date + 30
WHERE p.budget > 50000
  AND (
        SELECT COUNT(*)
        FROM employees e
        JOIN departments d ON d.dept_name = e.department
        WHERE d.dept_id = p.dept_id
      ) > 3
RETURNING project_id, project_name, dept_id, budget, end_date;


-- ---------------------------------------------------------------------------
-- Final state check
-- ---------------------------------------------------------------------------
SELECT * FROM employees   ORDER BY emp_id;
SELECT * FROM departments ORDER BY dept_id;
SELECT * FROM projects    ORDER BY project_id;
