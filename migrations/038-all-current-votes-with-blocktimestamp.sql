DROP FUNCTION IF EXISTS api.all_current_votes(CHAR);

--Replaces 025-all-current-votes. Adds block timestamp as a field to return from this query.
CREATE OR REPLACE FUNCTION api.all_current_votes(arg_address CHAR)
RETURNS TABLE (
	poll_id integer,
	option_id_raw character,
	option_id integer,
	block_timestamp timestamp with time zone
) AS $$
	WITH all_valid_votes AS (
		SELECT voter, option_id, option_id_raw, v.poll_id, v.block_id, b.timestamp as block_timestamp FROM polling.voted_event v
		JOIN polling.poll_created_event c ON c.poll_id=v.poll_id
		JOIN vulcan2x.block b ON v.block_id = b.id
		WHERE b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date)
	)
	SELECT DISTINCT ON (poll_id) poll_id, option_id_raw, option_id, block_timestamp FROM all_valid_votes
		WHERE voter = (SELECT hot FROM dschief.all_active_vote_proxies(2147483647) WHERE cold = arg_address)
		OR voter = (SELECT cold FROM dschief.all_active_vote_proxies(2147483647) WHERE hot = arg_address)
		OR voter = arg_address
		ORDER BY poll_id DESC,
		block_id DESC;
$$ LANGUAGE sql STABLE STRICT;