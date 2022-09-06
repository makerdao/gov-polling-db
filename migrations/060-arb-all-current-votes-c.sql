--testing to replace 58
CREATE OR REPLACE FUNCTION api.all_current_votes(arg_address CHAR)
RETURNS TABLE (
	poll_id integer,
	option_id_raw character,
	option_id integer,
	block_timestamp timestamp with time zone,
	chain_id integer
) AS $$
	WITH all_valid_mainnet_votes AS (
		SELECT v.voter, v.option_id, v.option_id_raw, v.poll_id, v.block_id, b.timestamp as block_timestamp, v.chain_id FROM polling.voted_event v
		JOIN polling.poll_created_event c ON c.poll_id=v.poll_id
		JOIN vulcan2x.block b ON v.block_id = b.id
		WHERE b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date)
	), 
	all_valid_arbitrum_votes AS (
		SELECT va.voter, va.option_id, va.option_id_raw, va.poll_id, va.block_id, 
		b.timestamp as block_timestamp, 
		va.chain_id FROM polling.voted_event_arbitrum va
		JOIN polling.poll_created_event c ON c.poll_id=va.poll_id
		JOIN vulcan2xarbitrum.block b ON va.block_id = b.id
		WHERE b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date)
	),
	distinct_mn_votes AS (
		SELECT DISTINCT ON (mnv.poll_id) 
		mnv.poll_id, 
		mnv.option_id_raw, 
		mnv.option_id, 
		mnv.block_timestamp,
		mnv.chain_id
		FROM all_valid_mainnet_votes mnv
		WHERE mnv.voter = (SELECT hot FROM dschief.all_active_vote_proxies(2147483647) WHERE cold = arg_address)
		OR mnv.voter = (SELECT cold FROM dschief.all_active_vote_proxies(2147483647) WHERE hot = arg_address)
		OR mnv.voter = arg_address
		ORDER BY mnv.poll_id DESC,
		mnv.block_timestamp DESC
	),
	distinct_arb_votes AS (
		SELECT DISTINCT ON (arbv.poll_id) 
		arbv.poll_id, 
		arbv.option_id_raw, 
		arbv.option_id, 
		arbv.block_timestamp, 
		arbv.chain_id
		FROM all_valid_arbitrum_votes arbv
		WHERE arbv.voter = (SELECT hot FROM dschief.all_active_vote_proxies(2147483647) WHERE cold = arg_address)
		OR arbv.voter = (SELECT cold FROM dschief.all_active_vote_proxies(2147483647) WHERE hot = arg_address)
		OR arbv.voter = arg_address
		ORDER BY arbv.poll_id DESC,
		arbv.block_timestamp DESC
	),
	combined_votes AS (
	select * from distinct_arb_votes
	UNION
	select * from distinct_mn_votes
	)
select distinct on (poll_id) * from combined_votes cv ORDER BY cv.poll_id DESC, cv.block_timestamp DESC
$$ LANGUAGE sql STABLE STRICT;