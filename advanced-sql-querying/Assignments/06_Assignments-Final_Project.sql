-- =-= FINAL PROJECT =-=

-- PART I: SCHOOL ANALYSIS
-- 1. View the schools and school details tables
SELECT * FROM schools;
SELECT * FROM school_details;

-- 2. In each decade, how many schools were there that produced players?
SELECT
    FLOOR(yearID / 10) * 10 AS decade,
    COUNT(DISTINCT schoolID) AS num_schools
FROM schools
GROUP BY decade
ORDER BY decade;

-- 3. What are the names of the top 5 schools that produced the most players?
SELECT
	sd.name_full,
	COUNT(DISTINCT s.playerID) AS num_players
FROM schools s
INNER JOIN school_details sd
	ON s.schoolID = sd.schoolID
GROUP BY sd.name_full
ORDER BY num_players DESC
LIMIT 5;


-- 4. For each decade, what were the names of the top 3 schools that produced the most players?
WITH school_num_players AS (
	SELECT
		FLOOR(s.yearID / 10) * 10 AS decade,
		sd.name_full,
		COUNT(DISTINCT s.playerID) AS num_players
	FROM schools s
	INNER JOIN school_details sd
		ON s.schoolID = sd.schoolID
	GROUP BY decade, sd.name_full
	ORDER BY decade
),
school_num_players_ranked AS (
	SELECT
		decade,
		name_full,
		num_players,
		ROW_NUMBER() OVER(PARTITION BY decade ORDER BY num_players DESC) AS row_num
	FROM school_num_players
)

SELECT
	decade,
    name_full,
    num_players
FROM school_num_players_ranked
WHERE row_num <= 3
ORDER BY decade DESC, num_players DESC;


-- PART II: SALARY ANALYSIS
-- 1. View the salaries table
SELECT * FROM salaries;

-- 2. Return the top 20% of teams in terms of average annual spending
WITH salary_totals AS (
	SELECT
		yearID,
		teamID,
		SUM(salary) AS salary_total
	FROM salaries
	GROUP BY yearID, teamID
),
teams_20per AS (
	SELECT
		teamID,
		AVG(salary_total) AS avg_salary,
		NTILE(5) OVER(ORDER BY AVG(salary_total) DESC) AS salary_total_pct
	FROM salary_totals
	GROUP BY teamID
)

SELECT
	teamID,
    ROUND(avg_salary / 1000000, 1) AS avg_salary_millions
FROM teams_20per
WHERE salary_total_pct = 1;

-- 3. For each team, show the cumulative sum of spending over the years
WITH salary_totals AS (
	SELECT
		yearID,
		teamID,
		SUM(salary) AS salary_total
	FROM salaries
	GROUP BY yearID, teamID
),
cum_sum AS (
	SELECT
		yearID,
		teamID,
		SUM(salary_total) OVER(PARTITION BY teamID ORDER BY yearID) AS cumulative_sum
	FROM salary_totals
)

SELECT
	yearID,
    teamID,
    ROUND(cumulative_sum / 1000000, 1) AS cumulative_sum_millions
FROM cum_sum;

-- 4. Return the first year that each team's cumulative spending surpassed 1 billion
WITH salary_totals AS (
	SELECT
		yearID,
		teamID,
		SUM(salary) AS salary_total
	FROM salaries
	GROUP BY yearID, teamID
),
cum_sum AS (
	SELECT
		yearID,
		teamID,
		SUM(salary_total) OVER(PARTITION BY teamID ORDER BY yearID) AS cumulative_sum
	FROM salary_totals
),
cum_sum_billions AS (
	SELECT
		yearID,
        teamID,
        cumulative_sum,
        ROW_NUMBER() OVER(PARTITION BY teamID ORDER BY cumulative_sum) AS row_num
	FROM cum_sum
	WHERE cumulative_sum >= 1000000000
)

SELECT
	yearID,
    teamID,
    ROUND(cumulative_sum / 1000000000, 2) AS cumulative_sum_billions
FROM cum_sum_billions
WHERE row_num = 1;


-- PART III: PLAYER CAREER ANALYSIS
-- 1. View the players table and find the number of players in the table
SELECT * FROM players;
SELECT COUNT(playerID) FROM players;


-- 2. For each player, calculate their age at their first game, their last game, and their career length (all in years).
-- Sort from longest career to shortest career.
WITH birth_dates AS (
	SELECT
		nameGiven,
		CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE) AS birth_date,
        debut,
        finalGame
	FROM players
)

SELECT
	nameGiven,
	TIMESTAMPDIFF(YEAR, birth_date, debut) AS starting_age,
	TIMESTAMPDIFF(YEAR, birth_date, finalGame) AS ending_age,
    TIMESTAMPDIFF(YEAR, debut, finalGame) AS career_length
FROM birth_dates
ORDER BY career_length DESC;

-- 3. What team did each player play on for their starting and ending years?
SELECT * FROM players;
SELECT * FROM salaries;

-- Approach 1 (An experiment):
CREATE TEMPORARY TABLE debut_team AS
	SELECT
		p.playerID,
		p.nameGiven,
		p.debut,
		s.teamID,
		s.yearID
	FROM players p
	INNER JOIN salaries s
		ON p.playerID = s.playerID
		AND YEAR(p.debut) = s.yearID;
    
CREATE TEMPORARY TABLE final_team AS
	SELECT
		p.playerID,
		p.nameGiven,
		p.finalGame,
		s.teamID,
		s.yearID
	FROM players p
	INNER JOIN salaries s
		ON p.playerID = s.playerID
		AND YEAR(p.finalGame) = s.yearID;
        
SELECT
	dt.nameGiven,
    YEAR(dt.debut) AS starting_year,
    dt.teamID,
    YEAR(ft.finalGame) AS ending_year,
    ft.teamID
FROM debut_team dt
INNER JOIN final_team ft
	ON dt.playerID = ft.playerID
ORDER BY dt.nameGiven;

-- Approach 2:
SELECT
	p.nameGiven,
	s1.yearID AS starting_year,
	s1.teamID AS starting_team,
	s2.yearID AS ending_year,
    s2.teamID AS ending_team
FROM players p
INNER JOIN salaries s1
	ON p.playerID = s1.playerID
	AND YEAR(p.debut) = s1.yearID
INNER JOIN salaries s2
	ON p.playerID = s2.playerID
	AND YEAR(p.finalGame) = s2.yearID
ORDER BY p.nameGiven;
        
        
-- 4. How many players started and ended on the same team and also played for over a decade?
SELECT
	p.nameGiven,
	s1.yearID AS starting_year,
	s1.teamID AS starting_team,
	s2.yearID AS ending_year,
	s2.teamID AS ending_team
FROM players p
INNER JOIN salaries s1
	ON p.playerID = s1.playerID
	AND YEAR(p.debut) = s1.yearID
INNER JOIN salaries s2
	ON p.playerID = s2.playerID
	AND YEAR(p.finalGame) = s2.yearID
WHERE s1.teamID = s2.teamID
	AND s2.yearID - s1.yearID > 10;


-- PART IV: PLAYER COMPARISON ANALYSIS
-- 1. View the players table
SELECT * FROM players;

-- 2. Which players have the same birthday?
WITH birth_dates AS (
	SELECT
		nameGiven,
		CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE) AS birth_date
	FROM players
)

SELECT
	birth_date,
    GROUP_CONCAT(nameGiven ORDER BY birth_date SEPARATOR ', ') AS players
FROM birth_dates
WHERE birth_date IS NOT NULL
GROUP BY birth_date;

-- 3. Create a summary table that shows for each team, what percent of players bat right, left and both (Pivoting)
WITH bats_pivoted AS (
	SELECT
		s.teamID,
        COUNT(s.playerID) AS num_players,
		SUM(CASE WHEN p.bats = 'R' THEN 1 ELSE 0 END) AS bats_right,
		SUM(CASE WHEN p.bats = 'L' THEN 1 ELSE 0 END) AS bats_left,
		SUM(CASE WHEN p.bats = 'B' THEN 1 ELSE 0 END) AS bats_both
	FROM salaries s
	LEFT JOIN players p
		ON s.playerID = p.playerID
	GROUP BY s.teamID
)

SELECT
	teamID,
    ROUND((bats_right / num_players) * 100, 1) AS bats_right_p,
    ROUND((bats_left / num_players) * 100, 1) AS bats_left_p,
    ROUND((bats_both / num_players) * 100, 1) AS bats_both_p
FROM bats_pivoted
ORDER BY teamID;

-- 4. How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference?
WITH avg_h_w_decades AS (
	SELECT
		FLOOR(YEAR(debut) / 10) * 10 AS decade,
		AVG(height) AS avg_height,
		AVG(weight) AS avg_weight
	FROM players
	GROUP BY decade
)

SELECT
	decade,
    avg_height - LAG(avg_height) OVER(ORDER BY decade) AS height_prev,
    avg_weight - LAG(avg_weight) OVER(ORDER BY decade) AS weight_prev
FROM avg_h_w_decades
WHERE decade IS NOT NULL;

