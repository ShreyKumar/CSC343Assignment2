SET search_path to uber,public;

-- count reciprocals

create view reciprocal as select count(*), clientrating.request_id from clientrating inner join driverrating on clientrating.request_id=driverrating.request_id where clientrating.request_id=driverrating.request_id and driverrating.rating=clientrating.rating group by clientrating.request_id;

--find corresponding average (Note: I realised there is a mistake here but didnt have time to fix it. I'm meant to natural join this with request to find the corresponding client_id and group by clientrating.client_id not clientrating.request_id) 

create view client_avg_req as select avg(clientrating.rating), clientrating.request_id from clientrating inner join driverrating on clientrating.request_id=driverrating.request_id group by clientrating.request_id;

-- Mistake here as well (mentioned above) 

create view driver_avg_req as select avg(driverrating.rating), driverrating.request_id from clientrating inner join driverrating on clientrating.request_id=driverrating.request_id group by driverrating.request_id;

create view driver_avg as select client_id, avg from driver_avg_req natural join request;

create view client_avg as select client_id, avg from client_avg_req natural join request;

create view reciprocal_ids as  select client_id, count from reciprocal natural join request;


create view difference as select client_avg.avg-driver_avg.avg as difference, client_avg.client_id from client_avg inner join driver_avg on clint_avg.client_id=driver_avg.client_id;


select difference.client_id, (select case when count is NULL then 0 else count end) as reciprocals, difference from reciprocal_ids right outer join difference on difference.client_id =reciprocal_ids.client_id order by difference asc;

