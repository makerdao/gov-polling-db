create type order_direction_type as enum ('ASC', 'DESC');
create type order_by_type as enum ('DATE', 'MKR', 'DELEGATORS');

-- This function will be called dynamically by api.delegates() based on the user sorting preference
create or replace function dschief.delegates_by_date(include_expired boolean, order_direction order_direction_type default 'ASC')
returns setof dschief.vote_delegate_created_event as $$
with A as (
  select dels.*
  from dschief.vote_delegate_created_event dels
  left join vulcan2x.block blocks
  on dels.block_id = blocks.id
  where
    -- Check that the difference between the current date and the delegate creation date is lower than a year (31536000 seconds)
    (case when include_expired then true else extract(epoch from now()) - extract(epoch from blocks.timestamp) < 31536000 end)
)
select A.*
from A
order by 
  case when order_direction = 'ASC' then A.block_id else -A.block_id end asc;
$$ language sql stable strict;

-- This function will be called dynamically by api.delegates() based on the user sorting preference
create or replace function dschief.delegates_by_mkr(include_expired boolean, order_direction order_direction_type default 'DESC')
returns setof dschief.vote_delegate_created_event as $$
with A as (
  select dels.*
  from dschief.vote_delegate_created_event dels
  left join vulcan2x.block blocks
  on dels.block_id = blocks.id
  where
    -- Check that the difference between the current date and the delegate creation date is lower than a year (31536000 seconds)
    (case when include_expired then true else extract(epoch from now()) - extract(epoch from blocks.timestamp) < 31536000 end)
)
select A.*
from A
left join dschief.delegate_lock B
on A.vote_delegate = B.contract_address
group by A.vote_delegate, A.id, A.delegate, A.log_index, A.tx_id, A.block_id
order by 
  case when order_direction = 'ASC' then sum(coalesce(B.lock, 0)) else -sum(coalesce(B.lock, 0)) end asc;
$$ language sql stable strict;

-- This function will be called dynamically by api.delegates() based on the user sorting preference
create or replace function dschief.delegates_by_delegators(include_expired boolean, order_direction order_direction_type default 'DESC')
returns setof dschief.vote_delegate_created_event as $$
with A as (
  select dels.*
  from dschief.vote_delegate_created_event dels
  left join vulcan2x.block blocks
  on dels.block_id = blocks.id
  where
    -- Check that the difference between the current date and the delegate creation date is lower than a year (31536000 seconds)
    (case when include_expired then true else extract(epoch from now()) - extract(epoch from blocks.timestamp) < 31536000 end)
)
select A.*
from A
left join (
  select contract_address, count(immediate_caller) as delegators
  from (select immediate_caller, sum(lock) as delegations, contract_address
  from dschief.delegate_lock
  group by contract_address, immediate_caller) as D
  where delegations > 0
  group by contract_address
) B
on A.vote_delegate = B.contract_address
group by A.vote_delegate, A.id, A.delegate, A.log_index, A.tx_id, A.block_id, B.delegators
order by 
  case when order_direction = 'ASC' then coalesce(delegators, 0) else -coalesce(delegators, 0) end asc;
$$ language sql stable strict;

-- Function exposed to the API, it dynamically calls one of the other three based on the user input
create or replace function api.delegates(_first int, order_by order_by_type default 'DATE', order_direction order_direction_type default 'DESC', include_expired boolean default false)
returns setof dschief.vote_delegate_created_event as $$
begin
  if _first > 30 or _first < 1 then
    raise exception 'Parameter first only accepts a number between 1 and 30.';
    return;
  elsif order_by = 'MKR' then
    return query select * from dschief.delegates_by_mkr(include_expired, order_direction);
  elsif order_by = 'DELEGATORS' then
    return query select * from dschief.delegates_by_delegators(include_expired, order_direction);
  else
    return query select * from dschief.delegates_by_date(include_expired, order_direction);    
  end if;
end;
$$ language plpgsql stable strict;