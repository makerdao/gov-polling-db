CREATE OR REPLACE FUNCTION mkr.holders_on_block(arg_block_number INTEGER)
RETURNS TABLE (
  address character varying(66),
  balance decimal(78,18)
) AS $$
  	SELECT SUMS.address, COALESCE(SUMS.sum, 0) + COALESCE(SUBS.sum, 0) as balance 
  	FROM (SELECT receiver as address, SUM(t.amount) FROM mkr.transfer_event t JOIN vulcan2x.block b ON b.id = t.block_id WHERE b.number <= arg_block_number GROUP BY t.receiver) SUMS
	LEFT JOIN (SELECT sender as address, SUM(-t.amount) FROM mkr.transfer_event t JOIN vulcan2x.block b ON b.id = t.block_id WHERE b.number <= arg_block_number GROUP BY t.sender) SUBS ON (SUMS.address = SUBS.address);
$$ LANGUAGE sql STABLE STRICT;