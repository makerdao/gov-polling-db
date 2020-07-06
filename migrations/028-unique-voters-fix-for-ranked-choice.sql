-- replaces function in 009
CREATE OR REPLACE FUNCTION api.unique_voters(arg_poll_id INTEGER)
RETURNS TABLE (
  unique_voters BIGINT
) AS $$
	SELECT COUNT(DISTINCT voter) FROM
	(SELECT * FROM polling.valid_votes_at_time_ranked_choice(arg_poll_id,2147483647)
	WHERE (voter, block_id) IN (
	select voter, MAX(block_id) as block_id
	from polling.valid_votes_at_time_ranked_choice(arg_poll_id,2147483647)
	group by voter)) r
	WHERE option_id_raw != '0';
$$ LANGUAGE sql STABLE STRICT;