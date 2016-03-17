SET search_path TO uber,public;

--month first table
create view months as select dropoff.request_id, dropoff.datetime, client_id from dropoff inner join request on request.request_id=dropoff.request_id;


--another month for comparison
create view months_second as select dropoff.datetime, client_id from dropoff inner join request on request.request_id=dropoff.request_id;

--final answer without an email
create view answer_no_email as select count(*) as months, months.client_id from months, months_second where date_part('month', months.datetime)!= date_part('month', months_second.datetime) and date_part('year', months.datetime)!= date_part('year', months_second.datetime) group by months.client_id;

--final answer
select client.client_id, email, (case when months is NULL then 0 else months end) from answer_no_email right outer join client on answer_no_email.client_id=client.client_id order by months desc;

