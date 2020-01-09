CREATE OR REPLACE FUNCTION polling.valid_votes_before_block(arg_poll_id INTEGER, arg_block_number INTEGER)
RETURNS TABLE (
  voter character varying(66),
  option_id integer,
  block_id integer
) AS $$
	SELECT voter, option_id, v.block_id FROM polling.voted_event v
	JOIN polling.poll_created_event c ON c.poll_id=v.poll_id
	JOIN vulcan2x.block b ON v.block_id = b.id
	WHERE b.number <= arg_block_number AND v.poll_id = arg_poll_id AND b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date);
$$ LANGUAGE sql STABLE STRICT;

-- replaces function in 006
CREATE OR REPLACE FUNCTION dschief.votes_with_proxy(arg_poll_id INTEGER, arg_block_number INTEGER)
RETURNS TABLE (
	voter character,
	option_id integer,
	block_id integer,
	proxy_otherwise_voter character,
	hot character,
	cold character
) AS $$
	SELECT voter, option_id, block_id, COALESCE(proxy, voter) as proxy_otherwise_voter, hot, cold FROM polling.valid_votes_before_block(arg_poll_id, arg_block_number)
	LEFT JOIN dschief.all_active_vote_proxies(arg_block_number)
	ON voter = hot OR voter = cold;
$$ LANGUAGE sql STABLE STRICT;