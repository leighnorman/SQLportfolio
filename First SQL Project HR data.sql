--Insights: Most promoted empoyees have been with the company for under 5 years. The female-male split of promoted employees is proportional to the split for the company, suggesting a lack of gender bias in promotions. Almost all promoted employees have a bachelor's degree or above, but some departments, like Technology, do promote employees with below secondary educations. Sourcing is the most common recruitment method for promoted employees. 
--Goal: Explore characteristics of the company's best employees. 

--Today, I am conducting exploratory analysis on a Kaggle employee dataset. Credit to Möbius: https://www.kaggle.com/datasets/arashnic/hr-ana
--The dataset description says this is originally for a Phython prediction model exercise. I wanted to explore the dataset as is. Let's get started. 

SELECT *
FROM [Employee Data]

--Information about gender, department, trainings completed, and more. The most important column is "is_promoted". This indicates someone who will be promoted. 

-- I will separate my questions into two groups: just employees already slated for promotion, then all employees. 
-- I want to learn about the company's top employees, and then the company as a whole. Looking at the overall company can identify gaps in recognition or capabilities. 

--PROMOTED SECTION
--How many people were promoted?
SELECT COUNT(*) AS promoted_employees
FROM [Employee Data]
WHERE is_promoted = 1; 

-- 4668 total. How did we recruit these promoted employees? This will help us know where to focus our recruitment efforts. 
SELECT recruitment_channel, 
COUNT(*) AS number
FROM [Employee Data]
GROUP BY recruitment_channel
ORDER BY number DESC;

-- I want to see that as a percentage, for easier sharing. Going to use the "universal" way of calculating percentages. 
WITH tbl1 AS (
SELECT *
FROM [Employee Data]
WHERE is_promoted = 1) 

SELECT recruitment_channel, 
CONCAT(
ROUND((COUNT(*) *100/(SELECT COUNT(*) FROM tbl1)),2)
,'%') AS percentage_of_channel
FROM tbl1
GROUP By recruitment_channel
ORDER BY percentage_of_channel DESC;
-- 55% are "other", an undefined type. The 42% is sourcing and 2% is referred. Seems proactively looking for potential employees is a good way to find high quality employees. 

-- What level of education (college, grad school, neither) do promoted employees have? 
SELECT ISNULL(education,'N/A') AS edu,COUNT(employee_id) AS num_employees
FROM [Employee Data]
WHERE is_promoted = 1
GROUP BY education
ORDER BY num_employees DESC;
--Most are college educated, either bachelor's degree (3008) or master's (1471). 

--I added an "ISNULL" because 122 NULLS were showing. I'll replace those permanently. 
UPDATE [Employee Data]
SET education = 'N/A'
WHERE education IS NULL;

--Depending on the nature of the work (I assume Legal definitely requires a degree!), having a degree or not could prevent a promotion. Let's look at education degree by department.
SELECT department, education,COUNT(employee_id) AS employee_amount
FROM [Employee Data]
WHERE is_promoted = 1
GROUP BY department, education
ORDER BY department,COUNT(employee_id) DESC;
--Interesting - R&D has no "below secondary" promoted employees. Meanwhile, Legal has 43 promoted employees with bachelor's, 6 with a master's, AND 4 below secondary.
--Because the dataset doesn't say what role these employees were promoted to (ex. junior admin to admin, lead analyst to VP of customer data, etc.), it is possible for someone in a "highly specialized" department to get promoted without a degree. It is very low, however.
--Other departments, like Technology, have more below secondary promoted employees (31). Tech can be self-taught with bootcamps or courses, so that makes sense, too.

--How long have these employees been with the company?
SELECT length_of_service, COUNT(*) AS num_employees
FROM [Employee Data]
WHERE is_promoted = 1
GROUP BY length_of_service
ORDER BY COUNT(*) DESC;

-- That is a huge range! I'm going to put in into groups. These names are easier to read than the full range (from 1 to 34 years!). 
SELECT 
COUNT(CASE WHEN length_of_service <= 5 THEN 1 END) AS 'Early',
COUNT(CASE WHEN length_of_service BETWEEN 6 AND 10 THEN 1 END) AS 'Mid',
COUNT(CASE WHEN length_of_service >= 11 THEN 1 END) AS 'Late'
FROM [Employee Data]
WHERE is_promoted = 1;
-- Most are early to mid career with the company. 

-- What percentage of promoted employees are female? How many are male? Going to use OVER() to speed things up. 
SELECT gender, CONCAT(COUNT(*) *100 /SUM(COUNT(*)) OVER (),'%') AS Gender_Percentage
FROM [Employee Data]
WHERE is_promoted = 1
GROUP BY gender; 
--31% female, 68% male. 

--Is that proportional to the company's overall gender split?
SELECT gender, CONCAT(COUNT(*) *100 /SUM(COUNT(*)) OVER (),'%') AS Gender_Percentage
FROM [Employee Data]
GROUP BY gender; 
--Yes! 29% female, 70% male. Since one gender is not getting promoted more often (like 90% of men vs 10% of women), this suggests our promotional structure is more fair. Not perfect, but more fair.  

--On that note, let's transition to the full company roster. 

--ALL EMPLOYEES
-- When I was scrolling through the data, I saw a lot of NULLs for previous year rating. Is that related to length of service?
SELECT length_of_service
FROM [Employee Data]
WHERE previous_year_rating IS NULL
GROUP BY length_of_service;
--Yes it is. The rating is only ever NULL for people with one year of tenure, since don't have a "previous year" to reference. This is why I am not analyzing employees by just previous year rating.

--Before I ask questions about the departments, I want to see the size of each. This will help me set expectations. If a really big department only has 1 or 2 awards, then we need to reconsider their overall performance or how well we're recognizing their work.
SELECT department,
COUNT(*) AS size
FROM dbo.[Employee Data]
GROUP BY department
ORDER BY COUNT(*) DESC;
--Sales and Marketing is the largest at 16,840. 

--How many employees in each department have ever won an award? "Awards won" is a binary. A value of 1 means that employee has won an award in the previous year and a value of 0 means the employee has not won any award. The dataset does not specifically say how many awards an employee won. For example, Tom could have won 20 awards, but "awards_won" would still only show up as 1, or true.
--In order to SUM this, I'll convert awards_won into an integer temporarily. 
SELECT department, 
SUM(CONVERT(INT,awards_won)) AS total_awards
FROM dbo.[Employee Data]
GROUP BY department
ORDER BY total_awards DESC;
--Sales and Marketing has the most employees with awards at 361. The other award counts are in the same order as the department sizes, so that checks out.

--I want to look at employee retention. Is the company keeping people long-term, or are they getting out as soon as possible? 
--For that, let's look at length_of_service, aka tenure. Let's see the maximum and minimum.
SELECT MAX(length_of_service) AS max_tenure,MIN(length_of_service) AS min_tenure
FROM [Employee Data];
-- Shortest tenure is 1, and the highest is 37!

-- Because of the wide range, it's hard to gauge how long most people have stayed at the company. 
-- To make this easier, I'm going to put these into ranges of "early", "mid", and "late" career with the company, like before.  
SELECT 
COUNT(CASE WHEN length_of_service <= 5 THEN 1 END) AS 'Early',
COUNT(CASE WHEN length_of_service BETWEEN 6 AND 10 THEN 1 END) AS 'Mid',
COUNT(CASE WHEN length_of_service >= 11 THEN 1 END) AS 'Late'
FROM [Employee Data];
--Most empoyees here are early in their careers here. 

