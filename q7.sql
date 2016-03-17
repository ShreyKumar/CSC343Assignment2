SET search_path TO uber,public;
select driver_id,
sum(case rating when '5' then 1 else 0 end) as r5,
sum(case rating when '4' then 1 else 0 end) as r4,
sum(case rating when '3' then 1 else 0 end) as r3,
sum(case rating when '2' then 1 else 0 end) as r2,
sum(case rating when '1' then 1 else 0 end) as r1,
sum(case rating when '0' then 1 else 0 end) as r0
from driverrating natural join dispatch group by driver_id;
