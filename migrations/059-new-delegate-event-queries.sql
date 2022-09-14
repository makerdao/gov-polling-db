--similar to function in 047 except we're getting events from the delegate_lock event table instead of the dschief lock table
-- this means contract_address is the delegate contract address, wheras is 047 immediate_caller is the delegate contract address
-- creating a separate function rather than replacing the old function since this is a breaking change
CREATE OR REPLACE FUNCTION api.mkr_delegated_to_v2(arg_address CHAR)
RETURNS TABLE (
  from_address character varying(66),
  immediate_caller character varying(66),
  delegate_contract_address character varying(66),
  lock_amount numeric(78,18),
  block_number integer,
  block_timestamp timestamp with time zone,
  hash character varying(66)
) AS $$
  WITH all_delegates AS (
    SELECT l.from_address, l.immediate_caller, l.lock, l.contract_address, v.number, v.timestamp, t.hash
    FROM dschief.delegate_lock l
    INNER JOIN vulcan2x.block v ON l.block_id = v.id
    INNER JOIN vulcan2x.transaction t ON l.tx_id = t.id
    WHERE l.immediate_caller = arg_address
    AND l.contract_address IN (SELECT vote_delegate FROM dschief.vote_delegate_created_event)
    GROUP BY l.from_address, l.immediate_caller, l.contract_address, v.timestamp, l.lock, v.number, t.hash
  )
  SELECT from_address, immediate_caller, contract_address, lock, number, timestamp, hash
  	FROM all_delegates
$$ LANGUAGE sql STABLE STRICT;

--similar to function in 054
--creating a separate function rather than replacing the old function since this is a breaking change
CREATE OR REPLACE FUNCTION api.mkr_locked_delegate_array_totals_v2(arg_address CHAR[], unixtime_start INTEGER, unixtime_end INTEGER)
RETURNS TABLE (
  from_address character varying(66),
  immediate_caller character varying(66),
  delegate_contract_address character varying(66),
  lock_amount numeric(78,18),
  block_number integer,
  block_timestamp timestamp with time zone,
  lock_total NUMERIC,
  hash character varying(66),
  caller_lock_total NUMERIC
) AS $$
  WITH all_locks AS (
    SELECT l.from_address, l.immediate_caller, l.contract_address, l.lock, v.number, v.timestamp, sum(lock) OVER (PARTITION BY 0 ORDER BY number ASC) AS lock_total, t.hash, sum(lock) OVER (PARTITION BY contract_address ORDER BY number ASC) AS caller_lock_total
    FROM dschief.delegate_lock l
    INNER JOIN vulcan2x.block v ON l.block_id = v.id
    INNER JOIN vulcan2x.transaction t ON l.tx_id = t.id
    WHERE l.contract_address = ANY (arg_address)
    GROUP BY l.from_address, l.immediate_caller, l.contract_address, l.lock, v.number, v.timestamp, t.hash
  )
  SELECT from_address, immediate_caller, contract_address, lock, number, timestamp, lock_total, hash, caller_lock_total
    FROM all_locks
    WHERE timestamp >= to_timestamp(unixtime_start)
    AND timestamp <= to_timestamp(unixtime_end);
$$ LANGUAGE sql STABLE STRICT;