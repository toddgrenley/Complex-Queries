
-- Practicing complex queries with the Olympics History dataset from Kaggle

SELECT *
FROM [Olympics Data]..athlete_events

SELECT *
FROM [Olympics Data]..noc_regions


-- 1) How many Olympic Games have been held?

SELECT COUNT(DISTINCT Games) AS TotalGames
FROM [Olympics Data]..athlete_events

-- 2) All Olympic Games held so far

SELECT DISTINCT Games
FROM [Olympics Data]..athlete_events

-- 3) The total number of nations to participate in each Games

SELECT Games, COUNT(DISTINCT NOC) AS NumOfCountries
FROM [Olympics Data]..athlete_events
GROUP BY Games
ORDER BY Games

-- 4) Years that have seen the highest and lowest participation

SELECT DISTINCT CONCAT(FIRST_VALUE(Games) OVER (ORDER BY NumOfCountries), ' - ', FIRST_VALUE(NumOfCountries) OVER (ORDER BY NumOfCountries)) AS LowestParticipation,
				CONCAT (FIRST_VALUE(Games) OVER (ORDER BY NumOfCountries DESC), ' - ', FIRST_VALUE(NumOfCountries) OVER (ORDER BY NumOfCountries DESC)) AS HighestParticipation
FROM (
	SELECT Games, COUNT(DISTINCT NOC) AS NumOfCountries
	FROM [Olympics Data]..athlete_events
	GROUP BY Games
	) s1

-- 5) Finding which nations have participated in every Olympic Games*

WITH t1 AS (
	SELECT COUNT(DISTINCT Games) AS TotalGames
	FROM [Olympics Data]..athlete_events),
	t2 AS (
	SELECT DISTINCT Region AS Country, Games
	FROM [Olympics Data]..athlete_events AS AE
	JOIN [Olympics Data]..noc_regions AS NR
		ON AE.NOC = NR.NOC),
	t3 AS (
	SELECT Country, COUNT(Country) AS NumOfGames
	FROM t2
	GROUP BY Country)
SELECT Country
FROM t3, t1
WHERE NumOfGames = TotalGames


-- 6) Finding the sports that have been played in every Summer Olympics

WITH t1 AS (
	SELECT COUNT(DISTINCT Games) AS TotalSummerGames
	FROM [Olympics Data]..athlete_events
	WHERE Season = 'Summer'),
	t2 AS (
	SELECT DISTINCT Sport, Games
	FROM [Olympics Data]..athlete_events
	WHERE Season = 'Summer'),
	t3 AS (
	SELECT Sport, COUNT(Sport) AS NumberOfGames
	FROM t2
	GROUP BY Sport)
SELECT Sport
FROM t3, t1
WHERE NumberOfGames = TotalSummerGames


-- 7) Finding the sports that were played only once*

WITH t1 AS (
	SELECT DISTINCT Sport, Games
	FROM [Olympics Data]..athlete_events),
	t2 AS (
	SELECT Sport, COUNT(Sport) AS NumOfGames
	FROM t1
	GROUP BY Sport)
SELECT Sport, NumOfGames, (SELECT Games FROM t1, t2 WHERE NumOfGames = 1)
FROM t2
WHERE NumOfGames = 1

-- 8) The total number of sports played in each Olympic Games

SELECT Games, COUNT(DISTINCT Sport) AS NumOfSports
FROM [Olympics Data]..athlete_events
GROUP BY Games
ORDER BY Games

-- 9) Info on the oldest athletes to win gold medals

SELECT *
FROM [Olympics Data]..athlete_events
WHERE Medal = 'Gold' AND Age = (
	SELECT MAX(Age)
	FROM [Olympics Data]..athlete_events
	WHERE Medal = 'Gold' AND Age <> 'NA')

-- 10) The ratio of male to female athletes in all Games

WITH t1 AS (
	SELECT CAST(COUNT(DISTINCT ID) AS float) AS TotalFemales
	FROM [Olympics Data]..athlete_events
	WHERE Sex = 'F'),
	t2 AS (
	SELECT CAST(COUNT(DISTINCT ID) AS float) AS TotalMales
	FROM [Olympics Data]..athlete_events
	WHERE Sex = 'M')
SELECT CONCAT('1:', ROUND(TotalMales/TotalFemales, 2)) AS Ratio
FROM t1, t2


-- 11) Top 5 Gold Medal Winners Ranked

SELECT *
FROM (
	SELECT *, DENSE_RANK() OVER (ORDER BY Medals DESC) AS Rank
	FROM (
		SELECT Name, COUNT(Medal) AS Medals
		FROM [Olympics Data]..athlete_events
		WHERE Medal = 'Gold'
		GROUP BY Name
		) s1) s2
WHERE Rank <= 5


-- 12) Top 5 Medal Winners Ranked

SELECT *
FROM (
	SELECT *, DENSE_RANK() OVER (ORDER BY Medals DESC) AS Rank
	FROM (
		SELECT Name, COUNT(Medal) AS Medals
		FROM [Olympics Data]..athlete_events
		WHERE Medal <> 'NA'
		GROUP BY Name
		) s1) s2
WHERE Rank <= 5

-- 13) Top 5 Winningest Countries (Most Medals) Ranked

SELECT *
FROM (
	SELECT *, DENSE_RANK() OVER (ORDER BY TotalMedals DESC) AS Rank
	FROM (
		SELECT Region AS Country, COUNT(Medal) AS TotalMedals
		FROM [Olympics Data]..athlete_events AS AE
		JOIN [Olympics Data]..noc_regions AS NR
			ON AE.NOC = NR.NOC
		WHERE Medal <> 'NA'
		GROUP BY Region) s1) s2
WHERE Rank <= 5


-- 14) List of Total Medals won by each country (using PIVOT function first)

SELECT *
FROM (
	SELECT Region AS Country, Medal, COUNT(Medal) AS TotalMedals
	FROM [Olympics Data]..athlete_events AS AE
	JOIN [Olympics Data]..noc_regions AS NR
		ON AE.NOC = NR.NOC
	WHERE Medal <> 'NA'
	GROUP BY Region, Medal
	) AS MedalData
PIVOT (
	MAX(TotalMedals)
	FOR Medal IN ([Gold],[Silver],[Bronze])
	) AS PivotTable
ORDER BY Gold DESC, Silver DESC, Bronze DESC

-- Or using CASE statements which is considerably simpler here

SELECT Region AS Country,
	SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold,
	SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver,
	SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze,
	SUM(CASE WHEN Medal = 'NA' THEN 1 ELSE 0 END) AS NA
FROM [Olympics Data]..athlete_events AS AE
JOIN [Olympics Data]..noc_regions AS NR
	ON AE.NOC = NR.NOC
GROUP BY Region
ORDER BY Gold DESC, Silver DESC, Bronze DESC


-- 15) List of Gold, Silver, and Bronze won by each country in each Olympics

SELECT Games, Region AS Country,
	SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold,
	SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver,
	SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze,
	SUM(CASE WHEN Medal = 'NA' THEN 1 ELSE 0 END) AS NA
FROM [Olympics Data]..athlete_events AS AE
JOIN [Olympics Data]..noc_regions AS NR
	ON AE.NOC = NR.NOC
GROUP BY Games, Region
ORDER BY Games


-- 16) Which countries won the most Gold, Silver, and Bronze in each Olympics

SELECT DISTINCT Games, 
				CONCAT(FIRST_VALUE(Country) OVER (PARTITION BY Games ORDER BY Gold DESC), ' - ', MAX(Gold) OVER (PARTITION BY Games ORDER BY Gold DESC)) AS Gold,
				CONCAT(FIRST_VALUE(Country) OVER (PARTITION BY Games ORDER BY Silver DESC), ' - ', MAX(Silver) OVER (PARTITION BY Games ORDER BY Silver DESC)) AS Silver,
				CONCAT(FIRST_VALUE(Country) OVER (PARTITION BY Games ORDER BY Bronze DESC), ' - ', MAX(Bronze) OVER (PARTITION BY Games ORDER BY Bronze DESC)) AS Bronze
FROM (
SELECT Games, Region AS Country,
	SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold,
	SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver,
	SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze,
	SUM(CASE WHEN Medal = 'NA' THEN 1 ELSE 0 END) AS NA
FROM [Olympics Data]..athlete_events AS AE
JOIN [Olympics Data]..noc_regions AS NR
	ON AE.NOC = NR.NOC
GROUP BY Games, Region) s1
GROUP BY Games, Country, Gold, Silver, Bronze
ORDER BY Games


-- 17) Which countries won the most Gold, Silver, and Bronze in each Olympics plus Totals

SELECT DISTINCT Games,
				CONCAT(FIRST_VALUE(Country) OVER (PARTITION BY Games ORDER BY Gold DESC), ' - ', MAX(Gold) OVER (PARTITION BY Games ORDER BY Gold DESC)) AS Gold,
				CONCAT(FIRST_VALUE(Country) OVER (PARTITION BY Games ORDER BY Silver DESC), ' - ', MAX(Silver) OVER (PARTITION BY Games ORDER BY Silver DESC)) AS Silver,
				CONCAT(FIRST_VALUE(Country) OVER (PARTITION BY Games ORDER BY Bronze DESC), ' - ', MAX(Bronze) OVER (PARTITION BY Games ORDER BY Bronze DESC)) AS Bronze,
				CONCAT(FIRST_VALUE(Country) OVER (PARTITION BY Games ORDER BY Total DESC), ' - ', MAX(Total) OVER (PARTITION BY Games ORDER BY Total DESC)) AS Total
FROM (
SELECT Games, Region AS Country,
	SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold,
	SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver,
	SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze,
	SUM(CASE WHEN Medal <> 'NA' THEN 1 ELSE 0 END) AS Total,
	SUM(CASE WHEN Medal = 'NA' THEN 1 ELSE 0 END) AS NA
FROM [Olympics Data]..athlete_events AS AE
JOIN [Olympics Data]..noc_regions AS NR
	ON AE.NOC = NR.NOC
GROUP BY Games, Region) s1
GROUP BY Games, Country, Gold, Silver, Bronze, Total
ORDER BY Games

-- 18) Which countries have won Silver/Bronze, but not Gold

SELECT Country, Gold, Silver, Bronze
FROM (
	SELECT Region AS Country,
		SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS Gold,
		SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS Silver,
		SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze,
		SUM(CASE WHEN Medal = 'NA' THEN 1 ELSE 0 END) AS NA
	FROM [Olympics Data]..athlete_events AS AE
	JOIN [Olympics Data]..noc_regions AS NR
		ON AE.NOC = NR.NOC
	GROUP BY Region) s1
WHERE Gold = 0 AND (Silver > 0 OR Bronze > 0)
ORDER BY Silver DESC, Bronze DESC

-- 19) Which sport India has won the most medals in

SELECT Sport, TotalMedals
FROM (
	SELECT *, RANK() OVER (ORDER BY TotalMedals DESC) AS Rank
	FROM (
		SELECT Sport, COUNT(Medal) AS TotalMedals
		FROM [Olympics Data]..athlete_events AS AE
		JOIN [Olympics Data]..noc_regions AS NR
			ON AE.NOC = NR.NOC
		WHERE Region = 'India' AND Medal <> 'NA'
		GROUP BY Sport) s1) s2
WHERE Rank = 1

-- 20) All Olympic Games where India medaled in hockey as well as the number of medals

SELECT Region AS Country, Sport, Games, COUNT(Medal) AS TotalMedals
FROM [Olympics Data]..athlete_events AS AE
JOIN [Olympics Data]..noc_regions AS NR
	ON AE.NOC = NR.NOC
WHERE Region = 'India' AND Sport = 'Hockey' AND Medal <> 'NA'
GROUP BY Region, Sport, Games
ORDER BY TotalMedals DESC