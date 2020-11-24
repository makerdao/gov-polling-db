create or replace function api.vote_option_mkr_weights_at_time(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (
	option_id INTEGER,
	mkr_support NUMERIC
) AS $$
  select 
    option_id as option_id_raw, 
    sum(amount) as mkr_support 
  from polling.votes_at_time(arg_poll_id, arg_unix)
  group by option_id
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.vote_mkr_weights_at_time_ranked_choice(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (
	option_id_raw character,
	mkr_support NUMERIC
) AS $$
  select 
    option_id::character as option_id_raw, 
    amount as mkr_support 
  from polling.votes_at_time(arg_poll_id, arg_unix)
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.time_to_block_number(arg_unix INTEGER)
RETURNS TABLE (
	number INTEGER
) AS $$
  select number 
  from vulcan2x.block 
  where timestamp <= to_timestamp(arg_unix) 
  order by timestamp desc limit 1
$$ LANGUAGE sql STABLE STRICT;