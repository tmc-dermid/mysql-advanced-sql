-- Connect to database
USE maven_advanced_sql;

-- ASSIGNMENT 1: Duplicate values

-- View the students data
SELECT * FROM students
ORDER BY student_name;

-- Create a column that counts the number of times a student appears in the table
SELECT
	student_name,
    COUNT(*) AS dup_count
FROM students
GROUP BY student_name
ORDER BY student_name;

-- Return student ids, names and emails, excluding duplicates students
WITH dup_students_ranked AS (
	SELECT
		id,
		student_name,
		email,
		ROW_NUMBER() OVER(PARTITION BY student_name ORDER BY id DESC) AS student_count
	FROM students
)

SELECT
	id,
    student_name,
    email
FROM dup_students_ranked
WHERE student_count = 1
ORDER BY id;


-- ASSIGNMENT 2: Min / max value filtering

-- View the students and student grades tables
SELECT * FROM students;
SELECT * FROM student_grades;

-- For each student, return the classes they took and their final grades
SELECT
	s.student_name,
    sg.class_name,
    sg.final_grade
FROM students s
LEFT JOIN student_grades sg
	ON s.id = sg.student_id
ORDER BY s.student_name, sg.final_grade;
        
-- Return each student's top grade and corresponding class
-- GROUP BY + JOIN approach
WITH student_best_grades AS (
	SELECT
		s.id AS student_id,
		s.student_name,
		MAX(sg.final_grade) AS best_grade
	FROM students s
	INNER JOIN student_grades sg
		ON s.id = sg.student_id
	GROUP BY s.id, s.student_name
)

SELECT
	sbg.student_id,
	sbg.student_name,
    sg.class_name,
    sg.final_grade
FROM student_grades sg
INNER JOIN student_best_grades sbg
	ON sg.student_id = sbg.student_id
    AND sg.final_grade = sbg.best_grade
ORDER by sg.student_id;

-- Window Function approach
WITH student_grades_rank AS (
	SELECT
		sg.student_id,
		s.student_name,
		sg.class_name,
		sg.final_grade,
        RANK() OVER(PARTITION BY s.student_name ORDER BY sg.final_grade DESC) AS rank_num
	FROM students s
	INNER JOIN student_grades sg
		ON s.id = sg.student_id
)

SELECT
	student_id,
	student_name,
    class_name,
    final_grade
FROM student_grades_rank
WHERE rank_num = 1
ORDER BY student_id;

                    
-- ASSIGNMENT 3: Pivoting
-- Q: Create a summary table that shows the average grade for each department and grade level.
SELECT * FROM student_grades;
SELECT * FROM students;

-- Combine the students and student grades tables
SELECT *
FROM students s
LEFT JOIN student_grades sg
	ON s.id = sg.student_id
ORDER BY s.student_name, sg.final_grade;
        
-- View only the columns of interest
SELECT
	s.grade_level,
	sg.department,
    sg.final_grade
FROM students s
LEFT JOIN student_grades sg
	ON s.id = sg.student_id;
        
-- Pivot the grade_level column
SELECT
	sg.department,
    sg.final_grade,
    CASE WHEN s.grade_level = 9 THEN 1 ELSE 0 END AS freshman,
    CASE WHEN s.grade_level = 10 THEN 1 ELSE 0 END AS sophomore,
    CASE WHEN s.grade_level = 11 THEN 1 ELSE 0 END AS junior,
    CASE WHEN s.grade_level = 12 THEN 1 ELSE 0 END AS senior
FROM students s
LEFT JOIN student_grades sg
	ON s.id = sg.student_id;
        
-- Update the values to be final grades
SELECT
	sg.department,
    CASE WHEN s.grade_level = 9 THEN sg.final_grade ELSE NULL END AS freshman,
    CASE WHEN s.grade_level = 10 THEN sg.final_grade ELSE NULL END AS sophomore,
    CASE WHEN s.grade_level = 11 THEN sg.final_grade ELSE NULL END AS junior,
    CASE WHEN s.grade_level = 12 THEN sg.final_grade ELSE NULL END AS senior
FROM students s
LEFT JOIN student_grades sg
	ON s.id = sg.student_id;

-- Create the final summary table
SELECT
	sg.department,
    ROUND(AVG(CASE WHEN s.grade_level = 9 THEN sg.final_grade ELSE NULL END)) AS freshman,
    ROUND(AVG(CASE WHEN s.grade_level = 10 THEN sg.final_grade ELSE NULL END)) AS sophomore,
    ROUND(AVG(CASE WHEN s.grade_level = 11 THEN sg.final_grade ELSE NULL END)) AS junior,
    ROUND(AVG(CASE WHEN s.grade_level = 12 THEN sg.final_grade ELSE NULL END)) AS senior
FROM students s
LEFT JOIN student_grades sg
	ON s.id = sg.student_id
WHERE sg.department IS NOT NULL
GROUP BY sg.department
ORDER BY sg.department;
    

-- ASSIGNMENT 4: Rolling calculations

-- Calculate the total sales each month
WITH sales_sums AS (
	SELECT
		EXTRACT(year FROM order_date) AS year,
		EXTRACT(month FROM order_date) AS month,
		o.units * p.unit_price AS sales_sums
	FROM orders o
	INNER JOIN products p
		ON o.product_id = p.product_id
	ORDER BY year, month
)

SELECT
	year,
    month,
    SUM(sales_sums) AS total_sales
FROM sales_sums
GROUP BY year, month;

-- Add on the cumulative sum and 6 month moving average
WITH sales_sums AS (
	SELECT
		EXTRACT(year FROM order_date) AS year,
		EXTRACT(month FROM order_date) AS month,
		o.units * p.unit_price AS sales_sums
	FROM orders o
	INNER JOIN products p
		ON o.product_id = p.product_id
	ORDER BY year, month
),
ts AS (
	SELECT
		year,
		month,
		SUM(sales_sums) AS total_sales
	FROM sales_sums
	GROUP BY year, month
)

SELECT
	year,
    month,
    total_sales,
    SUM(total_sales) OVER(ORDER BY year, month) AS cumulative_sum,
    AVG(total_sales) OVER(ORDER BY year, month
						  ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS moving_avg
FROM ts;

