SET search_path TO uber, public;

--get all the drivers that have been dispatched to pick up client
--store their source location 
CREATE VIEW drivers_resp_source as 
SELECT driver_id, r.request_id, source, 
       date_trunc('month', r.datetime) as date
FROM Dispatch d, Request r
WHERE d.request_id = r.request_id;

--get all the drivers that have been dispatched to pick up client
--store their destination location 
CREATE VIEW drivers_resp_dest as
SELECT driver_id, r.request_id, destination,             
       date_trunc('month', r.datetime) as date
FROM Dispatch d, Request r
WHERE d.request_id = r.request_id;

-- get source location to pick up the client 
CREATE VIEW source_point as
SELECT driver_id, request_id, location, date
FROM drivers_resp_source drs, Place p
WHERE drs.source = p.name;

-- Obtain the point of the Destination
CREATE VIEW dest_point as
SELECT driver_id, request_id, location, date
FROM drivers_resp_dest drd, Place p
WHERE drd.destination = p.name;

-- merge source_point and dest_point so we have the total distance of 
-- each ride
CREATE VIEW total_dist as
SELECT sp.driver_id, sp.request_id,
      (sp.location <@> dp.location) as distance, sp.date
FROM source_point sp, dest_point dp
WHERE sp.request_id = dp.request_id;


-- get the cost for each ride
CREATE VIEW total_cost as
SELECT driver_id, td.request_id, distance, date, amount
FROM total_dist td, Billed b
WHERE td.request_id = b.request_id;


-- filter so has the 2014 rides
CREATE VIEW only_2014 as
SELECT driver_id, sum(distance) as total_dist,
     ('0'||CAST(EXTRACT('month' FROM date) as text)) as month,
      sum(amount) as TotalAmount
FROM total_cost
WHERE EXTRACT('year' FROM date) = 2014
GROUP BY driver_id, EXTRACT('month' FROM date);


-- filter so only has the 2015 rides
CREATE VIEW RidesIn15 as
SELECT driver_id, sum(distance) as total_dist,
      ('0'||CAST(EXTRACT('month' FROM date) as text)) as month,
      sum(amount) as TotalAmount
FROM total_cost
WHERE EXTRACT('year'FROM date) = 2015
GROUP BY driver_id, EXTRACT('month' FROM date);


-- generate all the months that are there in 2014
CREATE VIEW AllMonths14 as
SELECT to_char(DATE '2014-01-01' +
       (interval '1' month * generate_series(0,11)), 'MM') as month;


-- generate all the months that are there in 2015
CREATE VIEW AllMonths15 as
SELECT to_char(DATE '2015-01-01' +
       (interval '1' month * generate_series(0,11)), 'MM') as month;



-- get all the drivers that are listed in the database
CREATE VIEW AllDrivers as
SELECT driver_id 
FROM Driver;

-- create a ShouldHave for 2014
CREATE VIEW ShouldHave14 as
SELECT driver_id, month
FROM AllDrivers, AllMonths14;

-- create a should have for 2015
CREATE VIEW ShouldHave15 as
SELECT driver_id, month
FROM AllDrivers, AllMonths15;



-- Find the tuples that did not occur that should have occured in 14
CREATE VIEW DidNot14 as
SELECT driver_id, 0 as total_dist, month, 0 as TotalAmount
FROM ((SELECT * FROM ShouldHave14)
      EXCEPT
      (SELECT driver_id, CAST(month as text) as month FROM only_2014))
       a; 

-- Find the tuples that did not occur that should have occured in 15
CREATE VIEW DidNot15 as
SELECT driver_id, 0 as total_dist, month, 0 as TotalAmount 
FROM ((SELECT * FROM ShouldHave15)
      EXCEPT
      (SELECT driver_id, CAST(month as text) as month FROM RidesIn15)) 
      b;


-- union the DidNot14 with only_2014 to get all valid combinations
CREATE VIEW Valid14 as
SELECT driver_id, month, total_dist, TotalAmount
FROM ((SELECT driver_id, CAST(month as text) as month, total_dist,
       TotalAmount FROM only_2014)
      UNION
      (SELECT driver_id, CAST(month as text) as month, total_dist,
       TotalAmount FROM DidNot14)) c;

-- union the DidNot15 with RidesIn15 to get all valid combinations
CREATE VIEW Valid15 as
SELECT driver_id, month, total_dist, TotalAmount
FROM ((SELECT driver_id, CAST(month as text) as month, total_dist, 
      TotalAmount FROM RidesIn15)
      UNION
      (SELECT driver_id, CAST(month as text) as month, total_dist, 
       TotalAmount FROM DidNot15)) d;


-- aggregate Valid14
CREATE VIEW fourteen_join as
SELECT driver_id, month, sum(total_dist) as  mileage_2014,
sum(TotalAmount) as billings_2014
FROM Valid14
GROUP BY driver_id, month;



-- aggregate Valid15
CREATE VIEW fifteen_join as
SELECT driver_id, month,
sum(total_dist) as mileage_2015, sum(TotalAmount) as billings_2015
FROM Valid15
GROUP BY driver_id, month;

-- join the two tables together
CREATE VIEW final_join as
SELECT * FROM fourteen_join JOIN fifteen_join using (driver_id, month)
ORDER BY driver_id, month;  

-- final answer
SELECT driver_id, month, mileage_2014, billings_2014, mileage_2015,
       billings_2015, (billings_2015 - billings_2014) as billings_increase,
       (mileage_2015 - mileage_2014) as mileage_increase
FROM final_join
ORDER BY driver_id, month;

