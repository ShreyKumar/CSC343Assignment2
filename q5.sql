SET search_path TO uber,public;
SELECT 
t1.client_id,
(select DISTINCT sum(amount) from 
(select amount from 
request natural join billed 
where date_part('year', datetime)=date_part('year', t1.datetime) 
and date_part('month', datetime)=date_part('month', t1.datetime))
as amount)
as total,
concat(date_part('year', t1.datetime), ' ', date_part('month', t1.datetime)) 
as month,

case when 
(select avg(amount) from
(select amount from
request natural join billed
where date_part('year', datetime)=date_part('year', t1.datetime)
and date_part('month', datetime)=date_part('month', t1.datetime))
as amount) 
<=
(select sum(amount) from
(select amount from
request natural join billed
where date_part('year', datetime)=date_part('year', t1.datetime)
and date_part('month', datetime)=date_part('month', t1.datetime))
as amount) 
then 'at or above' 

else
'below'

end
as comparison 
from (request natural join billed) as t1 inner join 
(request natural join billed) as t2
on t1.client_id=t2.client_id
group by t1.client_id, t1.datetime, t1.amount
order by month ASC;
