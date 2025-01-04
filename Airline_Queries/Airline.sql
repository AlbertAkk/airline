-- ===============================
-- 1. DATA CLEANING AND PREPARATION
-- ===============================

-- Check for NULL values in names
SELECT *
FROM Airline_Dataset
WHERE First_Name IS NULL OR Last_Name IS NULL;

-- Standardize column formats (capitalize first letter)
UPDATE Airline_Dataset
SET First_Name = UPPER(LEFT(First_Name, 1)) + LOWER(SUBSTRING(First_Name, 2, LEN(First_Name)));

-- Create derived column Age_Group
ALTER TABLE Airline_Dataset
ADD Age_Group NVARCHAR(50);

-- Assign Age_Group values
UPDATE Airline_Dataset
SET Age_Group = CASE
    WHEN Age < 18 THEN 'Minor'
    WHEN Age BETWEEN 18 AND 35 THEN 'Young Adult'
    WHEN Age BETWEEN 36 AND 60 THEN 'Adult'
    ELSE 'Senior'
END;

-- Remove duplicate records
DELETE FROM Airline_Dataset
WHERE Passenger_ID IN (
    SELECT Passenger_ID
    FROM Airline_Dataset
    GROUP BY Passenger_ID, Departure_Date, Arrival_Airport
    HAVING COUNT(*) > 1
);

-- Handle invalid data in Arrival_Airport
UPDATE Airline_Dataset
SET Arrival_Airport = 'Unknown'
WHERE Arrival_Airport = '0';

-- ===============================
-- 2. DESCRIPTIVE ANALYTICS
-- ===============================

-- Passenger Age Distribution
SELECT Age_Group, COUNT(*) AS Count
FROM Airline_Dataset
GROUP BY Age_Group
ORDER BY Count DESC;

-- Gender Distribution
SELECT Gender, COUNT(*) AS Passenger_Count
FROM Airline_Dataset
GROUP BY Gender;

-- Count flights by status
SELECT 
    Flight_Status, 
    COUNT(*) AS Flight_Count, 
    100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS Percentage
FROM Airline_Dataset
GROUP BY Flight_Status;

-- Average age by nationality
SELECT 
    Nationality, 
    AVG(Age) AS Avg_Age
FROM Airline_Dataset
GROUP BY Nationality
ORDER BY Avg_Age DESC;

-- ===============================
-- 3. POPULARITY AND RANKING
-- ===============================

-- Most Popular Destinations
SELECT Arrival_Airport, COUNT(*) AS Passenger_Count
FROM Airline_Dataset
WHERE Arrival_Airport <> 'Unknown'
GROUP BY Arrival_Airport
ORDER BY Passenger_Count DESC;

-- Top Pilots by Flight Count
SELECT Pilot_Name, COUNT(*) AS Flight_Count
FROM Airline_Dataset
GROUP BY Pilot_Name
ORDER BY Flight_Count DESC;

-- Most Active Airports by Continent
SELECT Airport_Continent, COUNT(*) AS Flight_Count
FROM Airline_Dataset
GROUP BY Airport_Continent
ORDER BY Flight_Count DESC;

-- Top Nationalities by Passenger Count
SELECT 
    Nationality, 
    COUNT(*) AS Passenger_Count
FROM Airline_Dataset
GROUP BY Nationality
ORDER BY Passenger_Count DESC;

-- Rank passengers by number of flights taken
SELECT Passenger_ID, First_Name, Last_Name, Nationality, 
       COUNT(*) AS Flight_Count,
       RANK() OVER (PARTITION BY Nationality ORDER BY COUNT(*) DESC) AS Rank
FROM Airline_Dataset
GROUP BY Passenger_ID, First_Name, Last_Name, Nationality
ORDER BY Flight_Count;

-- ===============================
-- 4. ROUTES AND DESTINATIONS
-- ===============================

-- Most frequent flight routes
SELECT 
    Airport_Name AS Departure_Airport, 
    Arrival_Airport, 
    COUNT(*) AS Flight_Count
FROM Airline_Dataset
GROUP BY Airport_Name, Arrival_Airport
ORDER BY Flight_Count DESC;

-- Top destination by country
WITH RankedDestinations AS (
    SELECT 
        Country_Name, 
        Arrival_Airport, 
        COUNT(*) AS Flight_Count,
        ROW_NUMBER() OVER (PARTITION BY Country_Name ORDER BY COUNT(*) DESC) AS Rank
    FROM Airline_Dataset
    GROUP BY Country_Name, Arrival_Airport
)
SELECT 
    Country_Name, 
    Arrival_Airport, 
    Flight_Count
FROM RankedDestinations
WHERE Rank = 1
ORDER BY Country_Name;

-- Destination preferences for Canadian passengers
SELECT First_Name, Last_Name, Arrival_Airport, 
       (SELECT COUNT(*) 
        FROM Airline_Dataset AS A_D2 
        WHERE A_D2.Arrival_Airport = A_D1.Arrival_Airport) AS Popularity
FROM Airline_Dataset AS A_D1
WHERE Nationality = 'Canada' AND Arrival_Airport <> 'Unknown'
ORDER BY Popularity DESC;

-- ===============================
-- 5. TEMPORAL TRENDS
-- ===============================

-- Seasonal Travel Trends
SELECT 
    CASE 
        WHEN MONTH(Departure_Date) = 1 THEN 'January'
        WHEN MONTH(Departure_Date) = 2 THEN 'February'
        WHEN MONTH(Departure_Date) = 3 THEN 'March'
        WHEN MONTH(Departure_Date) = 4 THEN 'April'
        WHEN MONTH(Departure_Date) = 5 THEN 'May'
        WHEN MONTH(Departure_Date) = 6 THEN 'June'
        WHEN MONTH(Departure_Date) = 7 THEN 'July'
        WHEN MONTH(Departure_Date) = 8 THEN 'August'
        WHEN MONTH(Departure_Date) = 9 THEN 'September'
        WHEN MONTH(Departure_Date) = 10 THEN 'October'
        WHEN MONTH(Departure_Date) = 11 THEN 'November'
        WHEN MONTH(Departure_Date) = 12 THEN 'December'
    END AS Travel_Month, 
    COUNT(*) AS Passenger_Count
FROM Airline_Dataset
GROUP BY MONTH(Departure_Date)
ORDER BY MONTH(Departure_Date);

-- Cumulative Passenger Counts by Month
SELECT 
    YEAR(Departure_Date) AS Travel_Year,
    DATENAME(month, Departure_Date) AS Travel_Month,
    COUNT(*) AS Monthly_Passenger_Count,
    SUM(COUNT(*)) OVER (PARTITION BY YEAR(Departure_Date) ORDER BY MONTH(Departure_Date)) AS Cumulative_Passenger_Count
FROM Airline_Dataset
GROUP BY YEAR(Departure_Date), MONTH(Departure_Date), DATENAME(month, Departure_Date);

-- Most popular months for each continent
WITH MonthlyFlights AS (
    SELECT 
        Airport_Continent, 
        DATENAME(MONTH, Departure_Date) AS Month, 
        COUNT(*) AS Flight_Count
    FROM Airline_Dataset
    GROUP BY Airport_Continent, DATENAME(MONTH, Departure_Date), MONTH(Departure_Date)
)
SELECT 
    Airport_Continent, 
    Month, 
    Flight_Count
FROM (
    SELECT 
        Airport_Continent, 
        Month, 
        Flight_Count, 
        RANK() OVER (PARTITION BY Airport_Continent ORDER BY Flight_Count DESC) AS Rank
    FROM MonthlyFlights
) RankedFlights
WHERE Rank = 1;

-- ===============================
-- 6. OTHER INSIGHTS
-- ===============================

-- Delays by airport
SELECT 
    Airport_Name, 
    COUNT(*) AS Delayed_Flights
FROM Airline_Dataset
WHERE Flight_Status = 'Delayed'
GROUP BY Airport_Name
ORDER BY Delayed_Flights DESC;

-- CTE for Popular Age Groups by Continent
WITH AgeGroupCounts AS (
    SELECT 
        Airport_Continent, 
        Age_Group, 
        COUNT(*) AS Group_Count
    FROM Airline_Dataset
    GROUP BY Airport_Continent, Age_Group
),
RankedAgeGroups AS (
    SELECT 
        Airport_Continent, 
        Age_Group, 
        Group_Count, 
        RANK() OVER (PARTITION BY Airport_Continent ORDER BY Group_Count DESC) AS Rank
    FROM AgeGroupCounts
)
SELECT 
    Airport_Continent, 
    Age_Group, 
    Group_Count, 
    Rank
FROM RankedAgeGroups
WHERE Rank <= 3;
