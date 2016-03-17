SET search_path TO uber, public;

--1st criteria 
DROP VIEW IF EXISTS spent500before2014 CASCADE;
CREATE VIEW spent500before2014 AS (
	SELECT client_id, SUM(amount) AS billed
	FROM Request R JOIN Billed B USING (request_id)
	WHERE R.datetime < '2014-01-01 00:00:00'
	GROUP BY client_id
	HAVING SUM(amount) >= 500);

-- 2nd critia 

DROP VIEW IF EXISTS to10rides2014 CASCADE;
CREATE VIEW to10rides2014 AS (
	SELECT client_id, COUNT(*) AS numRides
	FROM Request R JOIN Billed B USING (request_id)
	WHERE R.datetime >= '2014-01-01 00:00:00' 
		AND R.datetime < '2015-01-01 00:00:00'
	GROUP BY client_id
	HAVING COUNT(*) <= 10 AND COUNT(*) >= 1);

-- drop view just in case 

--third criteria
DROP VIEW IF EXISTS less2015 CASCADE;
CREATE VIEW less2015 AS (
	SELECT R.client_id, COUNT(*) AS numRides
	FROM Request R JOIN Billed B USING (request_id)
	WHERE R.datetime >= '2015-01-01 00:00:00' 
		AND R.datetime < '2016-01-01 00:00:00'
	GROUP BY client_id
	HAVING COUNT(*) < (SELECT numRides 
		FROM to10rides2014 X
			WHERE R.client_id = X.client_id));

--get all the clients corresponding to each request_id
DROP VIEW IF EXISTS clientList CASCADE;
CREATE VIEW clientList AS (
	SELECT * 
		FROM ((
			SELECT client_id 
				FROM spent500before2014) 
				INTERSECT (
					SELECT client_id 
						FROM less2015)) AS d);

DROP VIEW IF EXISTS clientInfoEmail CASCADE;
CREATE VIEW clientInfoEmail AS (
	SELECT C.client_id,
		(C.firstname || ' ' || C.surname) AS name, email
	FROM clientList CL JOIN Client C USING (client_id)
	WHERE C.email IS NOT NULL);

DROP VIEW IF EXISTS clientInfoNOEmail CASCADE;
CREATE VIEW clientInfoNOEmail AS (
	SELECT C.client_id,
		(C.firstname || ' ' || C.surname) as name,
			CAST('unknown' AS TEXT) AS emails
	FROM clientList CL JOIN Client C USING (client_id)
	WHERE C.email IS NULL);
 

DROP VIEW IF EXISTS clientInfo CASCADE;
CREATE VIEW clientInfo AS (
	SELECT *
		FROM ((
			SELECT *
				FROM clientInfoEmail) UNION (
					SELECT *
						FROM clientInfoNOEmail)) d);


DROP VIEW IF EXISTS billedClientInfo CASCADE;
CREATE VIEW billedClientInfo AS (
	SELECT *
	FROM spent500before2014 JOIN clientInfo USING (client_id));

DROP VIEW IF EXISTS clientDecline CASCADE;
CREATE VIEW clientDecline AS (
	SELECT client_id, (to10rides2014.numRides - less2015.numRides) as decline
	FROM less2015 JOIN to10rides2014 USING (client_id));

SELECT client_id, name, email, billed, decline
FROM billedClientInfo JOIN clientDecline USING (client_id)
ORDER BY billed DESC;
