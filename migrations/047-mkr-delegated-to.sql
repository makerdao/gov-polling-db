CREATE OR REPLACE FUNCTION api.mkr_delegated_to(arg_address CHAR)
RETURNS TABLE (
  from_address character varying(66), 
  immediate_caller character varying(66), 
  lock_amount numeric(78,18),
  block_number integer,
  block_timestamp timestamp with time zone,
  hash character varying(66)
) AS $$
  WITH all_delegates AS (
    SELECT l.from_address, l.immediate_caller, l.lock, v.number, v.timestamp, t.hash
    FROM dschief.lock l
    INNER JOIN vulcan2x.block v ON l.block_id = v.id
    INNER JOIN vulcan2x.transaction t ON l.tx_id = t.id
    WHERE l.from_address = arg_address
    AND l.immediate_caller IN (SELECT vote_delegate FROM dschief.vote_delegate_created_event)
    GROUP BY l.from_address, l.immediate_caller, v.timestamp, l.lock, v.number, t.hash
  )
  SELECT from_address, immediate_caller, lock, number, timestamp, hash
  	FROM all_delegates
$$ LANGUAGE sql STABLE STRICT;