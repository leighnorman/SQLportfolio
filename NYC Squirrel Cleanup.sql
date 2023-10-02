--Goal: Data cleanup of 2018 squirrel census.
--Source: NYC Open Data, 2018 Central Park Squirrel Census: https://data.cityofnewyork.us/Environment/2018-Central-Park-Squirrel-Census-Squirrel-Data/vfnx-vebw

--Cleanup
--Prelimary step in Excel: Removed 5 duplicate records from Unique_Squirrel_ID. This leaves 3018 unique records. 
--I could have also performed analysis without removing the dupes by using this query:
SELECT DISTINCT(Unique_Squirrel_ID)
FROM [2018 Central Park Squirrels]

--Generally, setting a primary key when importing data into SQL Server is much easier. MSSQL won't let you select any column as the primary key if it has any duplicates.
--For me, it was easier to pop this relatively small dataset into Excel and fix it there. 
--However, if I had a much larger dataset or needed to alter a table already in the database, I can check for duplicate rows this way.
SELECT unique_squirrel_id,COUNT(*)
FROM [2018 Central Park Squirrels]
GROUP BY unique_squirrel_id
HAVING COUNT(*) > 1;

--Then, to delete the duplicate records:
WITH CTE_Squirrel AS
(SELECT *, ROW_NUMBER() OVER (PARTITION BY unique_squirrel_id ORDER BY unique_squirrel_id) AS Row_Num
FROM [2018 Central Park Squirrels]
)
DELETE FROM CTE_Squirrel
WHERE Row_Num > 1;

--Finally, checking if all the duplicates are gone. If it worked, then this query shouldn't return anything. 
SELECT COUNT(*),Unique_Squirrel_ID
FROM [2018 Central Park Squirrels]
GROUP BY Unique_Squirrel_ID
HAVING COUNT(*) > 1;

--To save myself a headache (and shaking down Google for answers), I'll add a primary key constraint so the same data doesn't get added more than once. 
ALTER TABLE [2018 Central Park Squirrels]
ADD CONSTRAINT PK_Unique_Squirrel_ID PRIMARY KEY (unique_squirrel_id);
--This will be especially helpful for future collections. Now they can't make this unique squirrel ID error!

--I can also add a default value for the subjective fields. I'll put an example below, since there are too many subjective fields to do all these defaults for right now.
-- I'll fix "Other Interactions" since that one was almost always blank. 
ALTER TABLE [2018 Central Park Squirrels]
ADD CONSTRAINT Other_Interactions
DEFAULT 'None listed';
--A default constraint makes more sense here. Now, volunteers won't receive an error for fields they weren't required to fill out, nor will the dataset have so many NULLs.

--Now then, let's move on to the full dataset. 
SELECT *
FROM [2018 Central Park Squirrels];

--I am seeing many NULLs. This is expected, since some of this data is subjective, optional text fields. 
--For Color Notes, the primer says "Sighters occasionally added commentary on the squirrel fur conditions."
--Because of this, NULLs here doesn't suggest missing data, just optional fields. 
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
SET Highlight_Fur_Color = 'None noted'
WHERE Highlight_Fur_Color IS NULL;

UPDATE dbo.[2018 Central Park Squirrels]
SET Primary_Fur_Color = 'None noted'
WHERE Primary_Fur_Color IS NULL;

--That's the colors and location done. "Above Ground Sighter Measurement" also has NULLs. But "none noted" doesn't make sense for a numeric description (even though it's store as text)
--This column is odd because it's not one datatype - I made it "nvar" because it can be FALSE (squirrel wasn't above ground/was on ground) or a number (height from the ground).
--How many NULLs are there?

SELECT COUNT(*)
FROM dbo.[2018 Central Park Squirrels]
WHERE Above_Ground_Sighter_Measurement IS NULL;

--114 NULLs - that's significant enough to update them. The problem now is what are those NULLs telling me?  
--Saying '0' doesn't make sense, since the dataset already established 'FALSE' as its '0'. I could change the FALSEs to 0, though. Eastern Grey Squirrel don't burrow (i.e. having an above ground measure of less than 1), so a squirrel's measurement wouldn't be less than 0.
--That still doesn't help with the NULL issue. I'm going to put 'N/A' for now. If I change my mind, I can UPDATE later.

UPDATE dbo.[2018 Central Park Squirrels]
SET Above_Ground_Sighter_Measurement = 'N/A'
WHERE Above_Ground_Sighter_Measurement IS NULL

--Cleanup complete! 
