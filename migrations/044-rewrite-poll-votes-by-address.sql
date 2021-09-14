CREATE OR REPLACE FUNCTION api.vote_address_mkr_weights_at_time(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (voter CHARACTER, option_id INTEGER, option_id_raw CHARACTER, mkr_support NUMERIC) AS $$
  select voter, option_id, option_id_raw, amount
  from polling.votes_at_time(arg_poll_id, arg_unix)
$$ LANGUAGE sql STABLE STRICT;