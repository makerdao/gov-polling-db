-- this function would be called by getNumUniqueVoters(pollId) in the sdk, replaces similar function in 003
CREATE OR REPLACE FUNCTION api.unique_voters(arg_poll_id INTEGER)
RETURNS TABLE (
  unique_voters BIGINT
) AS $$
	SELECT COUNT(DISTINCT voter) FROM polling.valid_votes(arg_poll_id) WHERE option_id != 0;
$$ LANGUAGE sql STABLE STRICT;