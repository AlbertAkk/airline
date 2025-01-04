# Airline Data Analysis Project
## Overview
This project analyzes airline passenger data to gain insights into flight operations, passenger demographics, and flight statuses. The dataset includes passenger information, flight details, and operational metrics, providing an opportunity to perform SQL-based data analysis on key areas such as flight delays, passenger demographics, and flight performance.

## Dataset
File: Airline_Dataset/Airline_Dataset.csv
Description: The dataset contains information related to passengers, flights, and airports, with the following columns:
- Passenger ID: Unique identifier for each passenger.
- First Name: First name of the passenger.
- Last Name: Last name of the passenger.
- Gender: Gender of the passenger.
- Age: Age of the passenger.
- Nationality: Nationality of the passenger.
- Airport Name: Name of the airport where the passenger boarded.
- Airport Country Code: Country code of the airport's location.
- Country Name: Name of the country the airport is located in.
- Airport Continent: Continent where the airport is situated.
- Continents: Continents involved in the flight route.
- Departure Date: Date when the flight departed.
- Arrival Airport: Destination airport of the flight.
- Pilot Name: Name of the pilot operating the flight.
- Flight Status: Current status of the flight (e.g., on-time, delayed, canceled).
  
Source: https://www.kaggle.com/datasets/iamsouravbanerjee/airline-dataset/data

## Sample Data

![image](https://github.com/user-attachments/assets/2fd0cd15-89a4-483b-b304-a8ce65503b61)

## Project Objectives:
The objective of this project is to analyze airline dataset and uncover insights to improve operations and understand passenger trends:

1.Data Cleaning & Preparation:

- Handle missing or invalid data (e.g., NULL values, duplicates).
- Standardize column formats (e.g., capitalizing names).
- Create derived columns (e.g., age group categorization).
  
2.Descriptive Analytics:

- Analyze passenger age, gender, and nationality distributions.
- Calculate flight status (on-time, delayed, canceled) percentages.
  
3.Popularity & Ranking:

- Identify the most popular destinations, pilots, and airports.
- Rank passengers by the number of flights taken.
  
4.Routes & Destinations:

- Analyze frequent flight routes and top destinations by country.
- Focus on Canadian passenger preferences.
  
5.Temporal Trends:

- Analyze seasonal travel patterns and monthly passenger counts.
- Identify the most popular months for travel by continent.

Other Insights:

- Identify airports with the highest flight delays.
- Determine popular age groups by continent.

## Sample Query

```
-- Find the top 5 airports with the highest average flight delay
SELECT airport_name, AVG(delay) AS avg_delay
FROM flights
WHERE flight_status = 'Delayed'
GROUP BY airport_name
ORDER BY avg_delay DESC
LIMIT 5;

-- Get the distribution of passengers by age group
SELECT
    CASE
        WHEN age < 18 THEN 'Under 18'
        WHEN age BETWEEN 18 AND 30 THEN '18-30'
        WHEN age BETWEEN 31 AND 45 THEN '31-45'
        WHEN age BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+' 
    END AS age_group,
    COUNT(*) AS total_passengers
FROM passengers
GROUP BY age_group
ORDER BY total_passengers DESC;

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
```
