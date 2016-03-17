SET search_path TO uber,public;

create view rated_client_ids as select rated_rides.client_id from total_rides inner join rated_rides on total_rides.client_id=rated_rides.client_id where total_rides.client_id=rated_rides.client_id and total_rides.count=rated_rides.count;

create view rated_rides as select count(request_id), client_id from request natural join driverrating group by request_id;

create view total_rides as select count(request_id), client_id from request group by client_id;


select client_id, email from client natural join rated_client_ids order by email ASC;

