DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab;

\c advanced_lab

DROP TABLE IF EXISTS employee_archive;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    department  VARCHAR(50),
    salary      INTEGER CHECK (salary >= 0),
    hire_date   DATE,
    status      VARCHAR(20) NOT NULL DEFAULT 'Active'
                CHECK (status IN ('Active', 'Inactive', 'Terminated', 'Senior', 'Promoted'))
);

CREATE TABLE departments (
    dept_id     SERIAL PRIMARY KEY,
    dept_name   VARCHAR(50) NOT NULL UNIQUE,
    budget      INTEGER CHECK (budget >= 0),
    manager_id  INTEGER REFERENCES employees (emp_id)
                ON DELETE SET NULL
);

CREATE TABLE projects (
    project_id    SERIAL PRIMARY KEY,
    project_name  VARCHAR(100) NOT NULL,
    dept_id       INTEGER REFERENCES departments (dept_id)
                  ON DELETE SET NULL,
    start_date    DATE,
    end_date      DATE,
    budget        INTEGER CHECK (budget >= 0),
    CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES
    ('Aibek',    'Nurlanov',   'IT',        95000,  '2018-03-15', 'Active'),
    ('Dana',     'Serikova',   'IT',        72000,  '2021-06-01', 'Active'),
    ('Arman',    'Kassymov',   'IT',        68000,  '2022-02-10', 'Active'),
    ('Aliya',    'Tulegenova', 'IT',        120000, '2019-11-20', 'Active'),
    ('Nurlan',   'Akhmetov',   'IT',        60000,  '2023-04-05', 'Active'),
    ('Madina',   'Omarova',    'Sales',     48000,  '2020-08-12', 'Active'),
    ('Yerlan',   'Bekov',      'Sales',     52000,  '2021-09-30', 'Active'),
    ('Saule',    'Ismailova',  'Marketing', 45000,  '2022-05-18', 'Inactive'),
    ('Timur',    'Zhakupov',   'Marketing', 39000,  '2019-02-01', 'Terminated'),
    ('Aigerim',  'Sadykova',   NULL,        32000,  '2023-06-15', 'Active'),
    ('Kairat',   'Mukanov',    'Marketing', 67000,  '2020-03-01', 'Inactive');

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
    ('Data Warehouse',   1, '2025-01-01', NULL,         200000);

INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (12, 'Asel', 'Karimova', 'IT');

SELECT setval('employees_emp_id_seq', (SELECT MAX(emp_id) FROM employees));

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Ermek', 'Sultanov', 'Sales', DEFAULT, '2022-01-10', DEFAULT);

SELECT emp_id, first_name, salary, status
FROM employees
WHERE first_name = 'Ermek';

INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('HR',        60000, NULL),
    ('Finance',   85000, NULL),
    ('Logistics', 75000, NULL);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Gulnara', 'Abdirova', 'IT', 50000 * 1.1, CURRENT_DATE);

SELECT first_name, salary, hire_date
FROM employees
WHERE first_name = 'Gulnara';

CREATE TEMP TABLE temp_employees (LIKE employees);

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

SELECT emp_id, first_name, last_name, department
FROM temp_employees;

UPDATE employees
SET salary = salary * 1.10;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01'
RETURNING emp_id, first_name, salary, hire_date, status;

BEGIN;

UPDATE employees
SET department = CASE
                     WHEN salary > 80000                 THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
                 END
RETURNING emp_id, first_name, salary, department;

ROLLBACK;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive'
RETURNING emp_id, first_name, department, status;

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

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales'
RETURNING emp_id, first_name, salary, status;

DELETE FROM employees
WHERE status = 'Terminated'
RETURNING emp_id, first_name, last_name, status;

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL
RETURNING emp_id, first_name, salary, hire_date, department;

DELETE FROM departments
WHERE dept_name NOT IN (
        SELECT DISTINCT department
        FROM employees
        WHERE department IS NOT NULL
    )
RETURNING dept_id, dept_name;

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Bolat', 'Abenov', NULL, NULL, '2024-02-01')
RETURNING *;

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL
RETURNING emp_id, first_name, department;

DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL
RETURNING emp_id, first_name, salary, department;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Zhanna', 'Kenzhebayeva', 'Sales', 70000, '2024-09-01')
RETURNING emp_id,
          first_name || ' ' || last_name AS full_name;

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id,
          salary - 5000 AS old_salary,
          salary        AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Ruslan', 'Abdrakhmanov', 'IT', 65000, '2025-03-10'
WHERE NOT EXISTS (
        SELECT 1
        FROM employees
        WHERE first_name = 'Ruslan'
          AND last_name  = 'Abdrakhmanov'
    );

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Ruslan', 'Abdrakhmanov', 'IT', 65000, '2025-03-10'
WHERE NOT EXISTS (
        SELECT 1
        FROM employees
        WHERE first_name = 'Ruslan'
          AND last_name  = 'Abdrakhmanov'
    );

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

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
    ('Daniyar', 'Kuanyshev',  'IT',        61000, '2025-01-20'),
    ('Kamila',  'Zhumabek',   'IT',        59000, '2025-02-14'),
    ('Askar',   'Temirov',    'IT',        64000, '2025-04-01'),
    ('Aruzhan', 'Nurpeisova', 'Marketing', 47000, '2025-05-05'),
    ('Sanzhar', 'Utepov',     'Marketing', 50000, '2025-06-18');

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

CREATE TABLE employee_archive (LIKE employees INCLUDING ALL);

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

SELECT * FROM employees   ORDER BY emp_id;
SELECT * FROM departments ORDER BY dept_id;
SELECT * FROM projects    ORDER BY project_id;