CREATE OR REPLACE FUNCTION api.mkr_locked_delegate(arg_address CHAR, unixtime_start INTEGER, unixtime_end INTEGER)
RETURNS TABLE (
  from_address character varying(66), 
  immediate_caller character varying(66), 
  lock_amount numeric(78,18),
  block_number integer,
  block_timestamp timestamp with time zone,
  lock_total NUMERIC
) AS $$
  WITH all_locks AS (
    SELECT l.from_address, l.immediate_caller, l.lock, v.number, v.timestamp, sum(lock) OVER (PARTITION BY 0 ORDER BY number ASC) AS lock_total
    FROM dschief.lock l
    INNER JOIN vulcan2x.block v ON l.block_id = v.id
    WHERE l.immediate_caller = arg_address
    GROUP BY l.from_address, l.immediate_caller, l.lock, v.number, v.timestamp
  )
  SELECT from_address, immediate_caller, lock, number, timestamp, lock_total 
  	FROM all_locks
	  WHERE timestamp >= to_timestamp(unixtime_start)
    AND timestamp <= to_timestamp(unixtime_end);
$$ LANGUAGE sql STABLE STRICT;