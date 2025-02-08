--Bellabeat will like to understand how other smart device users use their devices 
--to monitor and improve their health and wellness to help them unlock new growth opportunities for the company.

USE Bellabeat
GO

--DATA EXPLORATON 

SELECT *
FROM dailyActivity_merged


SELECT COUNT(DISTINCT Id) AS amount_of_users, MIN(CAST(ActivityDate AS date)) AS start_date, MAX(CAST(ActivityDate AS date)) AS end_date
FROM dailyActivity_merged
 
--there are 35 users, observation period between 2016-03-12 and 2016-04-12

SELECT  *
FROM weightLogInfo_merged

SELECT COUNT(DISTINCT Id), MIN(CAST(Date AS date)) AS start_date, MAX(CAST(Date AS date)) AS end_date
FROM weightLogInfo_merged

--only 11 users have weightrecords, observation period between 2016-03-30 and 2016-04-12

SELECT *
FROM minuteSleep_merged

SELECT COUNT(DISTINCT Id), MIN(CAST(date AS date)) AS start_date, MAX(CAST(date AS date)) AS end_date
FROM minuteSleep_merged

--only 23 users use Bellabeat to track their sleep, observation period between 2016-03-11 and 2016-04-12


SELECT *
FROM hourlyCalories_merged

SELECT COUNT(DISTINCT Id), MIN(CAST(ActivityHour AS date)) AS start_date, MAX(CAST(ActivityHour AS date)) AS end_date
FROM hourlyCalories_merged

--34 users, observation period between 2016-03-12 and 2016-04-12

SELECT *
FROM hourlySteps_merged

SELECT COUNT(DISTINCT Id), MIN(CAST(ActivityHour AS date)) AS start_date, MAX(CAST(ActivityHour AS date)) AS end_date
FROM hourlySteps_merged

--34 users, observation period between 2016-03-12 and 2016-04-12


SELECT TOP 100 *
FROM heartrate_seconds_merged

SELECT COUNT(DISTINCT Id), MIN(CAST(Time AS date)) AS start_date, MAX(CAST(Time AS date)) AS end_date
FROM heartrate_seconds_merged

--only 14 users use Bellabeat to track their heartrate, observation period between 2016-03-29 and 2016-04-12

SELECT *
FROM hourlyIntensities_merged

SELECT COUNT(DISTINCT Id), MIN(CAST(ActivityHour AS date)) AS start_date, MAX(CAST(ActivityHour AS date)) AS end_date
FROM hourlyIntensities_merged

--34 users, observation period between 2016-03-12 and 2016-04-12


-- in dailyActivity_merged there are also observations about steps and calories

--check if observations the same in these tables

--check steps
--firstly, check for duplicate entries
SELECT Id, CAST(ActivityDate AS date) AS date, COUNT(TotalSteps) AS entries
FROM dailyActivity_merged
WHERE TotalSteps != 0
GROUP BY Id, CAST(ActivityDate AS date)
HAVING COUNT(TotalSteps) > 1
-- no duplicates

SELECT Id, ActivityHour, COUNT(StepTotal)
FROM hourlySteps_merged
WHERE StepTotal != 0 
GROUP BY Id, ActivityHour
HAVING COUNT(StepTotal) > 1
-- no duplicates


WITH act_steps AS (
SELECT Id, CAST(ActivityDate AS date) AS date, TotalSteps
FROM dailyActivity_merged
WHERE TotalSteps != 0),
steps AS (
SELECT Id, CAST(ActivityHour AS date) AS date, SUM(CAST(StepTotal AS decimal)) as DailySteps
FROM hourlySteps_merged
GROUP BY Id, CAST(ActivityHour AS date)
HAVING SUM(CAST(StepTotal AS decimal)) != 0)
SELECT st.Id, st.date, DailySteps, act.Id, act.date, TotalSteps
FROM act_steps act
FULL JOIN steps st ON act.Id = st.Id AND act.date = st.date
ORDER BY 1, 2, 4, 5

--apparently, a lot of missing data in dailyActivity_merged and some missing data in hourlySteps_merged (mostly in April)
--let's create a table that contains all data from hourlySteps_merged (since this table is dedicated for steps) and if there are missing data, 
--that's not missing in dailyActivity_merged, add them to final table

WITH act_steps AS (
SELECT Id, CAST(ActivityDate AS date) AS date, TotalSteps
FROM dailyActivity_merged
WHERE TotalSteps != 0),
steps AS (
SELECT Id, CAST(ActivityHour AS date) AS date, SUM(CAST(StepTotal AS decimal)) as DailySteps
FROM hourlySteps_merged
GROUP BY Id, CAST(ActivityHour AS date)
HAVING SUM(CAST(StepTotal AS decimal)) != 0)
SELECT COALESCE(st.Id, act.Id) AS Id, COALESCE(st.date, act.date) AS date, COALESCE(DailySteps, TotalSteps) AS steps
INTO daily_steps
FROM act_steps act
FULL JOIN steps st ON act.Id = st.Id AND act.date = st.date
ORDER BY 1, 2

SELECT * FROM daily_steps

--check calories

--check for duplicates
SELECT Id, ActivityDate, COUNT(Calories)
FROM dailyActivity_merged
GROUP BY Id, ActivityDate
HAVING COUNT(Calories) > 1
--no duplicates

SELECT Id, ActivityHour, COUNT(Calories)
FROM hourlyCalories_merged
GROUP BY Id, ActivityHour
HAVING COUNT(Calories) > 1
--no duplicates

WITH act_calories AS (
SELECT Id, CAST(ActivityDate AS date) AS date, Calories
FROM dailyActivity_merged
WHERE Calories != 0),
Calories AS (
SELECT Id, CAST(ActivityHour AS date) AS date, SUM(CAST(Calories AS decimal)) as DailyCalories
FROM hourlyCalories_merged
GROUP BY Id, CAST(ActivityHour AS date))
SELECT cl.Id, cl.date, DailyCalories, act.Id, act.date, Calories
FROM act_calories act
FULL JOIN Calories cl ON act.Id = cl.Id AND act.date =cl.date
ORDER BY 1, 2, 4, 5
--apparently, a lot of missing data in dailyActivity_merged and some missing data in hourlyCalories_merged (mostly in April)
--let's create a table that contains all data from hourlyCalories_merged (since this table is dedicated for calories) and if there are missing data, 
--that's not missing in dailyActivity_merged, add them to final table

WITH act_calories AS (
SELECT Id, CAST(ActivityDate AS date) AS date, Calories
FROM dailyActivity_merged
WHERE Calories != 0),
Calories AS (
SELECT Id, CAST(ActivityHour AS date) AS date, SUM(CAST(Calories AS decimal)) as DailyCalories
FROM hourlyCalories_merged
GROUP BY Id, CAST(ActivityHour AS date))
SELECT COALESCE(cl.Id, act.Id) AS Id, COALESCE(cl.date, act.date) AS date,  COALESCE(DailyCalories, Calories) AS Calories
INTO daily_calories
FROM act_calories act
FULL JOIN Calories cl ON act.Id = cl.Id AND act.date =cl.date
ORDER BY 1, 2

SELECT * FROM daily_calories


--for what purposes do users use the app?
SELECT DISTINCT act.Id, 
ISNULL(SIGN(w.id), 0) AS weight,
ISNULL(SIGN(s.id), 0) AS sleep,
ISNULL(SIGN(c.id), 0) AS calories,
ISNULL(SIGN(h.id), 0) AS heart_rate,
ISNULL(SIGN(i.id), 0) AS intensities,
ISNULL(SIGN(st.id), 0) AS steps
FROM dailyActivity_merged act
LEFT JOIN weightLogInfo_merged w ON act.id = w.id
LEFT JOIN minuteSleep_merged s ON act.id = s.id
LEFT JOIN (SELECT DISTINCT Id FROM hourlyCalories_merged) c ON act.id = c.id
LEFT JOIN (SELECT DISTINCT Id FROM heartrate_seconds_merged) h ON act.id = h.id
LEFT JOIN (SELECT DISTINCT Id FROM hourlyIntensities_merged) i ON act.id = i.id
LEFT JOIN (SELECT DISTINCT Id FROM hourlySteps_merged) st ON act.id = st.id
 
 --user 4388161847 doesn't use the application for any purpouse

SELECT *
FROM dailyActivity_merged
WHERE Id = '4388161847'
ORDER BY ActivityDate

--for user id 4388161847 ActivityDate between 3/29/2016 and 4/5/2016, no much data


-- find out how many percent of users use apps for a specific purpose
WITH purposes AS (
SELECT DISTINCT act.Id, 
ISNULL(SIGN(w.id), 0) AS weight,
ISNULL(SIGN(s.id), 0) AS sleep,
ISNULL(SIGN(c.id), 0) AS calories,
ISNULL(SIGN(h.id), 0) AS heart_rate,
ISNULL(SIGN(i.id), 0) AS intensities,
ISNULL(SIGN(st.id), 0) AS steps
FROM dailyActivity_merged act
LEFT JOIN weightLogInfo_merged w ON act.id = w.id
LEFT JOIN minuteSleep_merged s ON act.id = s.id
LEFT JOIN (SELECT DISTINCT Id FROM hourlyCalories_merged) c ON act.id = c.id
LEFT JOIN (SELECT DISTINCT Id FROM heartrate_seconds_merged) h ON act.id = h.id
LEFT JOIN (SELECT DISTINCT Id FROM hourlyIntensities_merged) i ON act.id = i.id
LEFT JOIN (SELECT DISTINCT Id FROM hourlySteps_merged) st ON act.id = st.id)
SELECT ROUND(SUM(weight)*100/COUNT(Id), 2) AS weight, 
ROUND(SUM(sleep)*100/COUNT(Id), 2) AS sleep, 
ROUND(SUM(calories)*100/COUNT(Id), 2) AS calories, 
ROUND(SUM(heart_rate)*100/COUNT(Id), 2) AS heart_rate, 
ROUND(SUM(intensities)*100/COUNT(Id), 2) AS intensities, 
ROUND(SUM(steps)*100/COUNT(Id), 2) AS steps
FROM purposes
--calories, intensities and steps are the most popular features among users

--ANALYZE RELATIONSHIP 

--which days of the week are users more active?
SELECT DATENAME(WEEKDAY, date) as day_of_week, SUM(steps) as total_steps
FROM daily_steps
GROUP BY DATENAME(WEEKDAY, date)
ORDER BY 2 DESC
--On Saturday, Sunday and Monday users walk more than 10,000 steps

--find sleep time for each day
-- according to the data dictionary 1 = asleep, 2 = restless, 3 = awake

--check for duplicates
SELECT Id, CAST(date AS datetime), COUNT(value)
FROM minuteSleep_merged
WHERE value = 1
GROUP BY Id, CAST(date AS datetime)
HAVING COUNT(value) > 1
ORDER BY 1, 2
--there are duplicates with Id 4319703577 and date after 2016-04-04

--creating new table without duplicates and with daily sleeping time
SELECT Id, awaking_day, FORMAT(ROUND(SUM(sleep_time), 0), '0') AS sleep_time
INTO daily_sleep
FROM(
SELECT Id, logId, MAX(CAST(date_time AS date)) AS awaking_day, 
DATEDIFF(MINUTE, MIN(date_time), MAX(date_time))/60.0 AS sleep_time
FROM(
SELECT Id, CAST(date AS datetime) AS date_time, logId, 
ROW_NUMBER() OVER(PARTITION BY Id, CAST(date AS datetime), logId ORDER BY Id) AS dupl
FROM minuteSleep_merged
WHERE value = 1) row_query
WHERE dupl = '1'
GROUP BY Id, logId) logid_query
--user Id 7007744171 has only observations with 1 hour of daily time sleep (which is impossible), so I am excluding this data so as not to distort potential insights 
WHERE Id != '7007744171'
GROUP BY Id, awaking_day
ORDER BY 1, 2

SELECT * FROM daily_sleep

--when do users sleep the most
SELECT DATENAME(WEEKDAY, awaking_day) AS dayweek, AVG(CAST(sleep_time AS decimal(10, 2))) AS avg_sleep
FROM daily_sleep
GROUP BY DATENAME(WEEKDAY, awaking_day)
ORDER BY 2 DESC
--users sleep the most on Saturday and Sunday, and on Friday and Tuesday the least

--get deepier into sleep analysis

--for further visualization

--sleepVs.steps
SELECT st.Id, date, sleep_time, steps
FROM daily_steps st
JOIN daily_sleep sl ON st.Id = sl.Id AND st.date = sl.awaking_day
ORDER BY 1, 2

--sleepVs.calories
SELECT sl.Id, awaking_day, sleep_time, calories
FROM daily_sleep sl
JOIN daily_calories cl ON sl.Id = cl.Id and sl.awaking_day = cl.date
ORDER BY 1, 2

WITH heartrate AS (
SELECT Id, CAST(Time AS date) AS date, ROUND(AVG(CAST(value AS decimal)), 0) AS avg_heartrate
FROM heartrate_seconds_merged
GROUP BY Id, CAST(Time AS date))
SELECT sl.Id, awaking_day, sleep_time, avg_heartrate
FROM daily_sleep sl
JOIN heartrate hr ON sl.Id = hr.Id AND sl.awaking_day = hr.date
--A normal resting heart rate for adults ranges from 60 to 100 beats per minute.
WHERE avg_heartrate < 60 OR avg_heartrate > 100
ORDER BY 1, 2

--sleepVs.intensity
WITH daily_intensity AS (
SELECT Id, CAST(ActivityHour AS date) AS date, SUM(CAST(TotalIntensity AS decimal)) AS intensity
FROM hourlyIntensities_merged
GROUP BY Id,  CAST(ActivityHour AS date)
HAVING SUM(CAST(TotalIntensity AS decimal)) != 0)
SELECT sl.Id, awaking_day, sleep_time, intensity
FROM daily_intensity intens
JOIN daily_sleep sl ON intens.Id = sl.Id AND intens.date = sl.awaking_day
ORDER BY 1, 2

--intensityVs.BMI
WITH daily_intensity AS (
SELECT Id, CAST(ActivityHour AS date) AS date, SUM(CAST(TotalIntensity AS decimal)) AS intensity
FROM hourlyIntensities_merged
GROUP BY Id,  CAST(ActivityHour AS date)
HAVING SUM(CAST(TotalIntensity AS decimal)) != 0)
SELECT i.Id, AVG(intensity) AS avg_intensity, AVG(CAST(BMI AS decimal)) AS avg_bmi
FROM weightLogInfo_merged w
JOIN daily_intensity i ON i.Id = w.Id
GROUP BY i.Id
ORDER BY 2 DESC, 3 

SELECT w.Id, AVG(CAST(SedentaryMinutes AS decimal)) AS avg_SedentaryMinutes, AVG(CAST(BMI AS decimal)) AS avg_bmi
FROM dailyActivity_merged act
JOIN weightLogInfo_merged w ON act.Id = w.Id
GROUP BY w.Id
ORDER BY 2 DESC

--BMIVs.Heartrate
SELECT h.Id, AVG(CAST(BMI AS decimal)) AS avg_bmi, ROUND(AVG(CAST(value AS decimal)), 0) AS avg_heartrate
FROM heartrate_seconds_merged h
JOIN weightLogInfo_merged w ON h.Id = w.Id
GROUP BY h.Id

--only 4 users track both weight and heartrate, 2 users have higher BMI than normal, but there is no information about age or muscle mass 
