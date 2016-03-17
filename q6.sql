SET search_path TO uber, public;

-- get all riders and count times they have taken uber in a year

CREATE VIEW YearlyUberDrivers as
SELECT r.client_id, EXTRACT('year' FROM r.datetime) as year, count(*) as count
FROM Request r, Pickup p
WHERE r.request_id = p.request_id
GROUP BY r.client_id, year;


-- create a view that has all the clients
CREATE VIEW ClientsOnly as
SELECT distinct client_id
FROM Client;


-- Create a view that has all the years that somebody rode an Uber
CREATE VIEW YearOnly as
SELECT distinct year
FROM YearlyUberDrivers;


-- create a view that has all possible combinations of clients and years.
-- this will allow us to find combinations that do not exist
CREATE VIEW ShouldHave as
SELECT client_id, year
FROM ClientsOnly, YearOnly;


-- Find the combinations that did not exist and pad them with 0's in count
CREATE VIEW DidNotHappen as
SELECT client_id, Year, 0 as count
FROM ((SELECT * FROM ShouldHave)
       EXCEPT
      (SELECT client_id, year FROM YearlyUberDrivers)) a;


-- Combine the did nots with the ones that did happen
CREATE VIEW BothInstances as
SELECT *
FROM ((SELECT * FROM YearlyUberDrivers) UNION (SELECT * FROM DidNotHappen)) foo;


-- get the highest rider(s)
CREATE VIEW HighestRiders as
SELECT *
FROM BothInstances 
WHERE count >= all (SELECT count FROM BothInstances);


-- get a view that does not include the highest rider
CREATE VIEW NotHighestRiders as
SELECT *
FROM ((SELECT * FROM BothInstances)
       EXCEPT
      (SELECT * FROM HighestRiders)) nh;


-- get the second highest rider(s)
CREATE VIEW SecondHighestRiders as
SELECT *
FROM NotHighestRiders
WHERE count >= all (SELECT count FROM NotHighestRiders);




-- get a view that does not include the highest or second highest rider
CREATE VIEW NotHighestTwoRiders as
SELECT *
FROM ((SELECT * FROM NotHighestRiders) 
       EXCEPT
      (SELECT * FROM SecondHighestRiders)) nsh;


-- get the third highest rider(s)
CREATE VIEW ThirdHighestRiders as
SELECT *
FROM NotHighestTwoRiders
WHERE count >= all (SELECT count FROM NotHighestTwoRiders);



-- get the lowest rider(s)
CREATE VIEW LowestRiders as
SELECT *
FROM BothInstances
WHERE count <= all (SELECT count FROM BothInstances);



-- create a view that does not have the lowest rider(s)
CREATE VIEW NotLowestRiders as
SELECT *
FROM ((SELECT * FROM BothInstances)
       EXCEPT
      (SELECT * FROM LowestRiders)) nl;

-- get the Second Lowest rider(s)
CREATE VIEW SecondLowestRiders as
SELECT *
FROM NotLowestRiders
WHERE count <= all (SELECT count FROM NotLowestRiders);



-- create a view that not have the lowest two rider
CREATE VIEW NotLowestTwoRiders as
SELECT *
FROM ((SELECT * FROM NotLowestRiders)
       EXCEPT
      (SELECT * FROM SecondLowestRiders)) nsl;

-- get the third Lowest rider(s)
CREATE VIEW ThirdLowestRiders as
SELECT *
FROM NotLowestTwoRiders
WHERE count <= all (SELECT count FROM NotLowestTwoRiders);



--output the final answer
SELECT client_id, year, count as rides
FROM ((SELECT * FROM HighestRiders)
       UNION
      (SELECT * FROM SecondHighestRiders)
       UNION
      (SELECT * FROM ThirdHighestRiders) 
       UNION 
      (SELECT * FROM LowestRiders) 
       UNION
      (SELECT * FROM SecondLowestRiders) 
       UNION 
      (SELECT * FROM ThirdLowestRiders)) final
ORDER BY rides desc, year, client_id;




