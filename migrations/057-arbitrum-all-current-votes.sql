DROP FUNCTION IF EXISTS api.all_current_votes(CHAR);

--testing to replace 38
CREATE OR REPLACE FUNCTION api.all_current_votes(arg_address CHAR)
RETURNS TABLE (
	poll_id integer,
	option_id_raw character,
	option_id integer,
	block_timestamp_mn timestamp with time zone,
	chain_id integer,

	poll_id_arb integer, 
	option_id_raw_arb character, 
	option_id_arb integer, 
	block_timestamp_arb timestamp with time zone,
	chain_id_arb integer
) AS $$
	WITH all_valid_mainnet_votes AS (
		SELECT v.voter, v.option_id, v.option_id_raw, v.poll_id, v.block_id, b.timestamp as block_timestamp_mn, v.chain_id FROM polling.voted_event v
		JOIN polling.poll_created_event c ON c.poll_id=v.poll_id
		JOIN vulcan2x.block b ON v.block_id = b.id
		WHERE b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date)
	), 
	all_valid_arbitrum_votes AS (
		SELECT va.voter, va.option_id, va.option_id_raw, va.poll_id, 
		-- va.block_id, b.timestamp as block_timestamp_arb, 
		va.chain_id FROM polling.voted_event_arbitrum va
		JOIN polling.poll_created_event c ON c.poll_id=va.poll_id
		-- JOIN vulcan2xarbitrum.block b ON va.block_id = b.id
		-- WHERE b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date)
	)
	SELECT DISTINCT ON (mnv.poll_id) 
		mnv.poll_id, 
		mnv.option_id_raw, 
		mnv.option_id, 
		mnv.block_timestamp_mn,
		mnv.chain_id,

		arbv.poll_id AS poll_id_arb, 
		arbv.option_id_raw AS option_id_raw_arb, 
		arbv.option_id AS option_id_arb, 
		-- arbv.block_timestamp_arb AS block_timestamp_arb, 
		arbv.chain_id AS chain_id_arb
			FROM all_valid_mainnet_votes mnv
			JOIN all_valid_arbitrum_votes arbv ON arbv.poll_id = mnv.poll_id
				WHERE mnv.voter = (SELECT hot FROM dschief.all_active_vote_proxies(2147483647) WHERE cold = arg_address)
				OR mnv.voter = (SELECT cold FROM dschief.all_active_vote_proxies(2147483647) WHERE hot = arg_address)
				OR mnv.voter = arg_address
				OR arbv.voter = arg_address
				ORDER BY mnv.poll_id DESC,
				mnv.block_timestamp_mn DESC;
$$ LANGUAGE sql STABLE STRICT;