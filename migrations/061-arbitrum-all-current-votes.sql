-- Replaces 038 to handle votes from both chains
drop function if exists api.all_current_votes;
CREATE OR REPLACE FUNCTION api.all_current_votes(arg_address CHAR)
RETURNS TABLE (
	poll_id integer,
	option_id integer,
	option_id_raw character,
	block_timestamp timestamp with time zone,
	chain_id integer,
	mkr_support decimal(78,18),
	hash character varying(66)
) AS $$
	-- Results in all the votes between the start and end date of each poll voted by arg_address (per chain)
	WITH all_valid_mainnet_votes AS (
		SELECT 
			v.voter,
			v.option_id,
			v.option_id_raw, 
			v.poll_id, 
			v.block_id, 
			b.timestamp as block_timestamp, 
			v.chain_id,
			to_timestamp(c.end_date) as end_timestamp,
			t.hash
		FROM polling.voted_event v
		JOIN polling.poll_created_event c ON c.poll_id=v.poll_id
		JOIN vulcan2x.block b ON v.block_id = b.id
		JOIN vulcan2x.transaction t ON v.tx_id = t.id
		WHERE b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date)
		AND v.voter = (SELECT hot FROM dschief.all_active_vote_proxies(2147483647) WHERE cold = arg_address)
		OR v.voter = (SELECT cold FROM dschief.all_active_vote_proxies(2147483647) WHERE hot = arg_address)
		OR v.voter = arg_address
	), 
	all_valid_arbitrum_votes AS (
		SELECT 
			va.voter,
			va.option_id, 
			va.option_id_raw, 
			va.poll_id, 
			va.block_id, 
			b.timestamp as block_timestamp, 
			va.chain_id,
			to_timestamp(c.end_date) as end_timestamp,
			t.hash
		FROM polling.voted_event_arbitrum va
		JOIN polling.poll_created_event c ON c.poll_id=va.poll_id
		JOIN vulcan2xarbitrum.block b ON va.block_id = b.id
		JOIN vulcan2xarbitrum.transaction t ON va.tx_id = t.id
		WHERE b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date)
		AND va.voter = (SELECT hot FROM dschief.all_active_vote_proxies(2147483647) WHERE cold = arg_address)
		OR va.voter = (SELECT cold FROM dschief.all_active_vote_proxies(2147483647) WHERE hot = arg_address)
		OR va.voter = arg_address
	),
	-- Results in the most recent vote for each poll for an address (per chain)
	distinct_mn_votes AS (
		SELECT DISTINCT ON (mnv.poll_id) *
		FROM all_valid_mainnet_votes mnv
		ORDER BY mnv.poll_id DESC,
		mnv.block_timestamp DESC
	),
	distinct_arb_votes AS (
		SELECT DISTINCT ON (arbv.poll_id) *
		FROM all_valid_arbitrum_votes arbv
		ORDER BY arbv.poll_id DESC,
		arbv.block_timestamp DESC
	),
	-- Results in 1 distinct vote for both chains (if exists)
	combined_votes AS (
	select * from distinct_mn_votes cv
	UNION
	select * from distinct_arb_votes cva
	)
-- Results in 1 distinct vote for only one chain (the latest vote)
SELECT DISTINCT ON (poll_id) 
	cv.poll_id,
	cv.option_id,
	cv.option_id_raw, 
	cv.block_timestamp, 
	cv.chain_id,
	-- Gets the mkr support at the end of the poll, or at current time if poll has not ended
	polling.reverse_voter_weight(arg_address, (
		select id
		from vulcan2x.block 
		where timestamp <= (SELECT LEAST (CURRENT_TIMESTAMP, cv.end_timestamp))
		order by timestamp desc limit 1)) as amount,
	cv.hash
	FROM combined_votes cv 
	ORDER BY 
		cv.poll_id DESC, 
		cv.block_timestamp DESC
$$ LANGUAGE sql STABLE STRICT;