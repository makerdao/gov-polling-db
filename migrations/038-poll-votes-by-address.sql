CREATE OR REPLACE FUNCTION api.vote_address_mkr_weights_at_time(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (voter character, option_id INTEGER, mkr_support NUMERIC) AS $$
  select voter, option_id, sum(amount)
  from polling.votes_at_time(arg_poll_id, arg_unix)
  group by voter, option_id
$$ LANGUAGE sql STABLE STRICT;
