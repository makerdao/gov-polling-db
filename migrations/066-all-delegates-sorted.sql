create type order_direction_type as enum ('ASC', 'DESC');

create or replace function api.delegates(order_direction order_direction_type default 'ASC')
returns setof dschief.vote_delegate_created_event as $$
select *
from dschief.vote_delegate_created_event
order by 
  (case when order_direction = 'ASC' then block_id end) asc,
  (case when order_direction = 'DESC' then block_id end) desc;
$$ language sql stable strict;

create or replace function api.delegates_by_mkr(order_direction order_direction_type default 'DESC')
returns setof dschief.vote_delegate_created_event as $$
select A.id, A.delegate, A.vote_delegate, A.log_index, A.tx_id, A.block_id
from dschief.vote_delegate_created_event A
left join dschief.delegate_lock B
on A.vote_delegate = B.contract_address
group by A.vote_delegate, A.id, A.delegate, A.log_index, A.tx_id, A.block_id
order by
  (case when order_direction = 'ASC' then sum(coalesce(B.lock, 0)) end) asc,
  (case when order_direction = 'DESC' then sum(coalesce(B.lock, 0)) end) desc;
$$ language sql stable strict;

create or replace function api.delegates_by_delegators(order_direction order_direction_type default 'DESC')
returns setof dschief.vote_delegate_created_event as $$
select A.id, A.delegate, A.vote_delegate, A.log_index, A.tx_id, A.block_id
from dschief.vote_delegate_created_event A
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
  (case when order_direction = 'ASC' then coalesce(delegators, 0) end) asc,
  (case when order_direction = 'DESC' then coalesce(delegators, 0) end) desc;
$$ language sql stable strict;