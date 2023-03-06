
-- LeetCode Answers



-- 175. Combine Two Tables

SELECT firstName, lastName, city, state
FROM Person
LEFT JOIN Address
    ON Person.personId = Address.personId

-- 176. Second Highest Salary

SELECT MAX(salary) AS SecondHighestSalary
FROM Employee
WHERE salary < (SELECT MAX(salary) FROM Employee)

-- 177. Nth Highest Salary



-- 178. Rank Scores

SELECT score, DENSE_RANK() OVER (ORDER BY score DESC) AS rank
FROM Scores

-- 180. Consecutive Numbers

SELECT DISTINCT L1.num AS ConsecutiveNums
FROM Logs L1
JOIN Logs L2
    ON L1.id = L2.id - 1
JOIN Logs L3
    ON L2.id = L3.id - 1
WHERE L1.num = L2.num AND L2.num = L3.num

SELECT DISTINCT L1.num AS ConsecutiveNums
FROM Logs L1, Logs L2, Logs L3
WHERE L1.id = L2.id - 1 AND L2.id = L3.id - 1
    AND L1.num = L2.num AND L2.num = L3.num

-- 181. Employees Earning More Than Their Managers

SELECT E2.name AS Employee
FROM Employee AS E1
JOIN Employee AS E2
    ON E1.id = E2.managerId
WHERE E2.salary > E1.salary

-- 182. Duplicate Emails

SELECT email
FROM (
    SELECT email, COUNT(email) AS num
    FROM Person
    GROUP BY email
    ) s1
WHERE num > 1

SELECT email
FROM Person
GROUP BY email
HAVING COUNT(email) > 1

-- 183. Customers Who Never Order

SELECT name AS Customers
FROM Customers
WHERE id NOT IN (SELECT customerId FROM Orders)

-- 184. Department Highest Salary

SELECT Department, Employee, Salary
FROM (
    SELECT D.name AS Department, E.name AS Employee, Salary,
        RANK() OVER (PARTITION BY departmentId ORDER BY salary DESC) AS Rank
    FROM Employee AS E
    JOIN Department AS D
        ON E.departmentId = D.id
        )  s1
WHERE Rank = 1

-- 185. Department Top 3 Salaries

SELECT D.name AS Department, E.name AS Employee, Salary
FROM Employee AS E
JOIN Department AS D
    ON E.departmentId = D.id
WHERE (
    SELECT COUNT(DISTINCT salary) 
    FROM Employee AS t1
    WHERE t1.departmentId = D.id AND t1.salary >= E.salary
    ) <= 3
AND D.name IS NOT NULL
ORDER BY D.id DESC

-- 196. Delete Duplicate Emails

DELETE p2
FROM Person AS p1
JOIN Person AS p2
    ON p1.email = p2.email
WHERE p1.id < p2.id

-- 197. Rising Temperature

SELECT w1.id 
FROM Weather w1, Weather w2
WHERE DATEDIFF(day, w2.recordDate, w1.recordDate) = 1 
AND w1.temperature > w2.temperature

SELECT w1.id 
FROM Weather w1
JOIN Weather w2
    ON DATEADD(day, -1, w1.recordDate) = w2.recordDate
    AND w1.temperature > w2.temperature

SELECT w1.id 
FROM Weather w1
JOIN Weather w2
    ON DATEDIFF(day, w2.recordDate, w1.recordDate) = 1 
    AND w1.temperature > w2.temperature

SELECT w1.id 
FROM Weather AS w1
JOIN Weather AS w2
    ON DATEDIFF(day, w2.recordDate, w1.recordDate) = 1
WHERE w1.temperature > w2.temperature

-- 262. Rides and Users

WITH Data AS (
    SELECT request_at, status
    FROM Trips AS T
    WHERE EXISTS (SELECT 1 FROM Users AS U WHERE U.banned = 'No' AND U.users_id = T.client_id)
    AND EXISTS (SELECT 1 FROM Users AS U WHERE U.banned = 'No' AND U.users_id = T.driver_id)
	AND CAST(request_at AS date) BETWEEN CAST('2013-10-01' AS date) AND CAST('2013-10-03' AS date)
    ),
Requests AS (
    SELECT request_at, CAST(COUNT(*) AS float) AS Requests
    FROM Data
    GROUP BY request_at
    ),
Cancels AS (
    SELECT request_at, CAST(COUNT(*) AS float) AS Cancels
    FROM Data
    WHERE status LIKE 'cancelled%'
    GROUP BY request_at
    )
SELECT R.request_at AS Day, ROUND(COALESCE(Cancels, 0)/Requests, 2) AS "Cancellation Rate"
FROM Requests AS R
LEFT JOIN Cancels AS C
    ON R.request_at = C.request_at


-- 511. Game Play Analysis I

SELECT player_id, MIN(event_date) AS first_login
FROM Activity
GROUP BY player_id

-- 584. Find Customer Referee

SELECT name
FROM Customer
WHERE referee_id <> 2 OR referee_id IS NULL

-- 586. Customer Placing the Largest Number of Orders

SELECT MAX(customer_number) AS customer_number
FROM (
    SELECT customer_number, COUNT(customer_number) AS Count
    FROM Orders
    GROUP BY customer_number
    ) s1

SELECT TOP 1 customer_number
FROM Orders
GROUP BY customer_number
ORDER BY COUNT(customer_number) DESC

-- 595. Big Countries

SELECT name, population, area
FROM World
WHERE area >= 3000000 OR population >= 25000000

-- 596. Classes More Than 5 Students

SELECT class
FROM (
    SELECT class, COUNT(class) AS Count
    FROM Courses
    GROUP BY class
    ) s1
WHERE Count >= 5

SELECT class
FROM Courses
GROUP BY class
HAVING COUNT(student) >= 5

-- 601. Human Traffic of Stadium

WITH t1 AS (
    SELECT *, id - ROW_NUMBER() OVER (ORDER BY id) AS diff
    FROM Stadium
    WHERE people >= 100),
    t2 AS (
    SELECT *, COUNT(*) OVER (PARTITION BY diff ORDER BY diff) AS cnt
    FROM t1)
SELECT id, visit_date, people
FROM t2
WHERE t2.cnt >= 3

SELECT id, visit_date, people
FROM Stadium
WHERE people >= 100
AND ((id + 1 IN (SELECT id FROM Stadium WHERE people >= 100) AND id + 2 IN (SELECT id FROM Stadium WHERE people >= 100))
OR (id + 1 IN (SELECT id FROM Stadium WHERE people >= 100) AND id - 1 IN (SELECT id FROM Stadium WHERE people >= 100))
OR (id - 1 IN (SELECT id FROM Stadium WHERE people >= 100) AND id - 2 IN (SELECT id FROM Stadium WHERE people >= 100)))

-- 607. Sales Person*

SELECT SP.name AS name, SP.sales_id, C.com_id, C.name AS Company
FROM SalesPerson AS SP
LEFT JOIN Orders AS O
    ON SP.sales_id = O.sales_id
LEFT JOIN Company AS C
    ON O.com_id = C.com_id
WHERE

SELECT name
FROM SalesPerson
WHERE sales_id NOT IN (
    SELECT sales_id 
    FROM Orders AS O 
    LEFT JOIN Company AS C
        ON O.com_id = C.com_id
    WHERE name = 'RED')

-- 608. Tree Node

SELECT id, 
    CASE WHEN p_id IS NULL THEN 'Root'
         WHEN id IN (SELECT p_id FROM Tree) THEN 'Inner'
         ELSE 'Leaf'
    END AS Type
FROM Tree

-- 620. Not Boring Movies

SELECT *
FROM Cinema
WHERE id % 2 <> 0 AND description <> 'boring'
ORDER BY rating DESC

-- 626. Exchange Seats

SELECT 
    CASE WHEN id % 2 = 1 THEN LEAD(id, 1, id) OVER (ORDER BY id)
         WHEN id % 2 = 0 THEN id - 1
         END AS id, student
FROM Seat
ORDER BY id

SELECT
    CASE WHEN id % 2 = 1 THEN LEAD(id, 1, id) OVER (ORDER BY id)
         ELSE LAG(id) OVER (ORDER BY id)
         END AS id, student
FROM Seat
ORDER BY id

-- 627. Swap Salary

UPDATE Salary
SET sex = CASE WHEN sex = 'm' THEN 'f'
               ELSE 'm'
               END

-- 1050. Actors and Directors Who Cooperated At Least Three Times

SELECT actor_id, director_id
FROM ActorDirector
GROUP BY actor_id, director_id
HAVING COUNT(timestamp) >= 3