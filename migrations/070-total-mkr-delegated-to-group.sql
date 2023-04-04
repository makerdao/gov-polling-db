create or replace function api.total_mkr_delegated_to_group(delegates char[])
returns numeric as $$
  select sum(lock)
  from dschief.delegate_lock
  where contract_address = ANY (delegates)
$$ language sql stable strict;