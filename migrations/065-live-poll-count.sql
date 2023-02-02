create or replace function api.live_poll_count()
returns bigint as $$
  select count(*)
  from polling.poll_created_event
  where end_date > extract(epoch from now()) and start_date <= extract(epoch from now()) and poll_id not in (
	  select poll_id
	  from polling.poll_withdrawn_event
  )
$$ language sql stable strict;