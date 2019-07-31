-- replaces function in 007, which replaces function in 003
CREATE OR REPLACE FUNCTION api.unique_voters(arg_poll_id INTEGER)
RETURNS TABLE (
  unique_voters BIGINT
) AS $$
	SELECT COUNT(DISTINCT voter) FROM
	(SELECT * FROM polling.valid_votes(arg_poll_id)
	WHERE (voter, block_id) IN (
	select voter, MAX(block_id) as block_id
	from polling.valid_votes(arg_poll_id)
	group by voter)) r
	WHERE option_id != 0;
$$ LANGUAGE sql STABLE STRICT;