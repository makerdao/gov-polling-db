--Update to include votes made by delegate contracts
CREATE OR REPLACE FUNCTION api.all_current_votes(arg_address CHAR)
RETURNS TABLE (
	poll_id integer,
	option_id_raw character,
	option_id integer
) AS $$
	WITH all_valid_votes AS (
		SELECT voter, option_id, option_id_raw, v.poll_id, v.block_id FROM polling.voted_event v
		JOIN polling.poll_created_event c ON c.poll_id=v.poll_id
		JOIN vulcan2x.block b ON v.block_id = b.id
		WHERE b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date)
	)
	SELECT DISTINCT ON (poll_id) poll_id, option_id_raw, option_id FROM all_valid_votes
		WHERE voter = (SELECT hot FROM dschief.all_active_vote_proxies(2147483647) WHERE cold = arg_address)
		OR voter = (SELECT cold FROM dschief.all_active_vote_proxies(2147483647) WHERE hot = arg_address)
    OR voter = (SELECT vote_delegate FROM dschief.vote_delegate_created_event WHERE delegate = arg_address)
		OR voter = arg_address
		ORDER BY poll_id DESC,
		block_id DESC;
$$ LANGUAGE sql STABLE STRICT;

--Update to include votes made by delegate contracts
CREATE OR REPLACE FUNCTION api.current_vote(arg_address CHAR, arg_poll_id INTEGER)
RETURNS TABLE (
	option_id INTEGER,
	block_id INTEGER
) AS $$
SELECT option_id, block_id FROM polling.valid_votes(arg_poll_id)
		WHERE voter = (SELECT hot FROM dschief.all_active_vote_proxies(2147483647) WHERE cold = arg_address)
		OR voter = (SELECT cold FROM dschief.all_active_vote_proxies(2147483647) WHERE hot = arg_address)
    OR voter = (SELECT vote_delegate FROM dschief.vote_delegate_created_event WHERE delegate = arg_address)
		OR voter = arg_address
		ORDER BY block_id DESC
		LIMIT 1;
$$ LANGUAGE sql STABLE STRICT;

--Update to include votes made by delegate contracts
CREATE OR REPLACE FUNCTION api.current_vote_ranked_choice(arg_address CHAR, arg_poll_id INTEGER)
RETURNS TABLE (
	option_id_raw character,
	block_id INTEGER
) AS $$
SELECT option_id_raw, block_id FROM polling.valid_votes_at_time_ranked_choice(arg_poll_id, 2147483647)
		WHERE voter = (SELECT hot FROM dschief.all_active_vote_proxies(2147483647) WHERE cold = arg_address)
		OR voter = (SELECT cold FROM dschief.all_active_vote_proxies(2147483647) WHERE hot = arg_address)
    OR voter = (SELECT vote_delegate FROM dschief.vote_delegate_created_event WHERE delegate = arg_address)
		OR voter = arg_address
		ORDER BY block_id DESC
		LIMIT 1;
$$ LANGUAGE sql STABLE STRICT;