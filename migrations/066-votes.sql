-- Same code than 065 but without address
CREATE OR REPLACE FUNCTION api.all_current_votes(start integer default 0, limit integer default 10)
RETURNS TABLE (
  poll_id integer,
  option_id integer,
  option_id_raw character,
  block_timestamp timestamp with time zone,
  chain_id integer,
  mkr_support decimal(78,18),
  hash character varying(66)
) AS $$
  -- Results in all the votes between the start and end date of each poll (per chain)
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
  ),
  -- Results have to be unique on the combination of pollId / address
  distinct_mn_votes AS (
    SELECT *
    FROM all_valid_mainnet_votes mnv
    ORDER BY poll_id DESC,
    block_id DESC
    UNIQUE (mnv.poll_id, mnv.voter)
  ),
  distinct_arb_votes AS (
    SELECT *
    FROM all_valid_arbitrum_votes arbv
    ORDER BY poll_id DESC,
    block_id DESC
    UNIQUE (arbv.poll_id, arbv.voter)
  ),
  -- Results in 1 distinct vote for both chains (if exists)
  combined_votes AS (
  select * from distinct_mn_votes cv
  UNION
  select * from distinct_arb_votes cva
  )
-- Results in 1 distinct vote for only one chain (the latest vote)
SELECT
  cv.poll_id,
  cv.option_id,
  cv.option_id_raw, 
  cv.block_timestamp, 
  cv.chain_id,
  -- Gets the mkr support at the end of the poll, or at current time if poll has not ended
  -- need to pass in a vote proxy address if address has a vote proxy
  polling.reverse_voter_weight(polling.unique_voter_address(cv.voter, (
    select id
    from vulcan2x.block 
    where timestamp <= (SELECT LEAST (CURRENT_TIMESTAMP, cv.end_timestamp))
    order by timestamp desc limit 1)), (
    select id
    from vulcan2x.block 
    where timestamp <= (SELECT LEAST (CURRENT_TIMESTAMP, cv.end_timestamp))
    order by timestamp desc limit 1)) as amount,
  cv.hash
  FROM combined_votes cv 
  ORDER BY 
    cv.poll_id DESC, 
    cv.block_timestamp DESC
  OFFSET start
  LIMIT limit
  UNIQUE (cv.poll_id, cv.voter)
$$ LANGUAGE sql STABLE STRICT;