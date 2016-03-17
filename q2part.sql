SET search_path TO uber, public;

select
sum(
case when
(select date_part('year', dropoff.datetime) 
from dropoff inner join request on dropoff.request_id=request.request_id
) = 2015
then
1
else
0
end
) - 
sum(
case when
(select date_part('year', dropoff.datetime)
from dropoff inner join request on dropoff.request_id=request.request_id
) = 2014
then
1
else
0
end
); 
