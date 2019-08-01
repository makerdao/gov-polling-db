--replaces function in 006
CREATE OR REPLACE FUNCTION api.current_vote(arg_address CHAR, arg_poll_id INTEGER)
RETURNS TABLE (
	option_id INTEGER,
	block_id INTEGER
) AS $$
SELECT option_id, block_id FROM polling.valid_votes(arg_poll_id)
		WHERE voter = (SELECT hot FROM dschief.all_active_vote_proxies(2147483647) WHERE cold = arg_address)
		OR voter = (SELECT cold FROM dschief.all_active_vote_proxies(2147483647) WHERE hot = arg_address)
		OR voter = arg_address
		ORDER BY block_id DESC
		LIMIT 1;
$$ LANGUAGE sql STABLE STRICT;