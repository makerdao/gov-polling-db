create type delegation_metrics_entry as (
  delegator_count bigint,
  total_mkr_delegated numeric
);

create or replace function api.delegation_metrics()
returns delegation_metrics_entry as $$
  select count(*) as delegator_count, sum(delegations) as total_mkr_delegated
  from (select immediate_caller, sum(lock) as delegations
  from dschief.delegate_lock
  group by immediate_caller) A
  where delegations > 0
$$ language sql stable strict;