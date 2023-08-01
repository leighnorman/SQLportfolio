--Goal: Data cleanup of 2018 squirrel census.
--Source: NYC Open Data, 2018 Central Park Squirrel Census: https://data.cityofnewyork.us/Environment/2018-Central-Park-Squirrel-Census-Squirrel-Data/vfnx-vebw

--Prelimary step in Excel:
--Remove 5 duplicate records from Unique_Squirrel_ID. This leaves 3018 unique records. 
--I could have also performed analysis without removing the dupes by using:
SELECT DISTINCT(Unique_Squirrel_ID)
FROM [2018 Central Park Squirrels]

--Generally, setting a primary key when importing data is much easier. 
--However, if for some reason I didn't want to do that from the outset, I can check for duplicate rows this way.
SELECT unique_squirrel_id,COUNT(*)
FROM [2018 Central Park Squirrels]
GROUP BY unique_squirrel_id
HAVING COUNT(*) > 1;

SELECT COUNT(*)
FROM dbo.[2018 Central Park Squirrels];

--I am seeing many NULLs. This is expected, since some of this data is subjective, optional text fields. 
--For Color Notes, the primer says "Sighters occasionally added commentary on the squirrel fur conditions."
--Because of this, NULLs here doesn't suggest missing data. 
--Other Activities, Other Interactions, and Specific Location are all optional, descriptive fields
--I'm going to replace the NULLs with 'none noted'. This term fits how the data was collected: it's not that the squirrel didn't have any highlights *at all*, just that the volunteer didn't make a note of it. 

UPDATE dbo.[2018 Central Park Squirrels]
SET Color_notes = 'None noted'
WHERE Color_notes IS NULL

--Checking if it updated correctly. 

SELECT *
from DBO.[2018 Central Park Squirrels];

--Appears as expected. I'll do the rest. 

UPDATE dbo.[2018 Central Park Squirrels]
SET Specific_Location = 'None noted'
WHERE Specific_Location IS NULL;

UPDATE dbo.[2018 Central Park Squirrels]
SET Other_Interactions = 'None noted'
WHERE Other_Interactions IS NULL;

UPDATE dbo.[2018 Central Park Squirrels]
SET Highlight_Fur_Color = 'None noted'
WHERE Highlight_Fur_Color IS NULL;

UPDATE dbo.[2018 Central Park Squirrels]
SET Primary_Fur_Color = 'None noted'
WHERE Primary_Fur_Color IS NULL;

--That's the color and interactions done. "Above Ground Sighter Measurement" also has NULLs. But "none noted" doesn't make sense for a numeric description (even though it's store as text)
--This column is odd because it's not one datatype - I made it "nvar" because it can be FALSE (squirrel wasn't above ground/was on ground) or a number.
--How many NULLs are there?

SELECT COUNT(*)
FROM dbo.[2018 Central Park Squirrels]
WHERE Above_Ground_Sighter_Measurement IS NULL;

--114 NULLs - that's significant enough to update them. 
--Saying '0' makes no sense, since the dataset already established 'FALSE' as its '0'. I could change the FALSEs to 0, though...
--That still doesn't help with the NULL issue. I'm going to put 'N/A' for now. If I change my mind, I can UPDATE later.

UPDATE dbo.[2018 Central Park Squirrels]
SET Above_Ground_Sighter_Measurement = 'N/A'
WHERE Above_Ground_Sighter_Measurement IS NULL

--Cleanup complete! 

--Exploratory questions--

--1. Count of squirrels by color
SELECT Primary_Fur_Color, COUNT(*) AS Num_per_color
FROM dbo.[2018 Central Park Squirrels]
GROUP BY Primary_Fur_Color
ORDER BY 2 DESC;
-- Mostly grey squirrels. Makes sense. The Eastern Grey Squirrel comes in many colors, including cinnamon and black. The black color is a melanistic mutation. Cinnamon is just a grey squirrel variant, NOT a red squirrel, which is a different breed entirely.

--2. When are they out and about? Grey squirrels are crepuscular animals, meaning they are active at dawn and dusk. This is opposed to nocturnal (active mostly at night) and diurnal (active during the day).
SELECT Shift, COUNT(*) AS times_seen
FROM dbo.[2018 Central Park Squirrels]
GROUP BY Shift
ORDER BY Shift DESC;

-- That's an even split, as expected. Now, this data was collected in October 2018, so autumn. According to research, squirrels are very active during the fall when food is abundant (source: https://www.researchgate.net/publication/255182104_Daily_and_seasonal_activity_patterns_in_the_eastern_gray_squirrel).
-- Let's see what activities they got into during this busy time! Let's tally up activity types. 
-- Activities are in binary, 1 = yes, 0 = no. SUM won't help here. 

SELECT COUNT(*)
FROM dbo.[2018 Central Park Squirrels]
WHERE Eating = 1;