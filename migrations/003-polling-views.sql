CREATE OR REPLACE FUNCTION mkr.holders_on_block(arg_block_number INTEGER)
RETURNS TABLE (
  address character varying(66),
  balance decimal(78,18)
) AS $$
  	SELECT SUMS.address, COALESCE(SUMS.sum, 0) + COALESCE(SUBS.sum, 0) as balance 
  	FROM (SELECT receiver as address, SUM(t.amount) FROM mkr.transfer_event t JOIN vulcan2x.block b ON b.id = t.block_id WHERE b.number <= arg_block_number GROUP BY t.receiver) SUMS
	LEFT JOIN (SELECT sender as address, SUM(-t.amount) FROM mkr.transfer_event t JOIN vulcan2x.block b ON b.id = t.block_id WHERE b.number <= arg_block_number GROUP BY t.sender) SUBS ON (SUMS.address = SUBS.address);
$$ LANGUAGE sql STABLE STRICT;


CREATE OR REPLACE FUNCTION api.votes(arg_poll_id INTEGER)
RETURNS TABLE (
  option_id INTEGER,
  balance decimal(78,18)
) AS $$
  	SELECT t.option_id, SUM(t.balance) FROM (
		SELECT distinct ON (v.voter) * FROM polling.voted_event v 
		JOIN polling.poll_created_event c ON c.poll_id=v.poll_id
		JOIN mkr.holders_on_block(c.end_block) t ON v.voter = t.address 
		JOIN vulcan2x.block b ON v.block_id = b.id
		WHERE c.poll_id = arg_poll_id AND b.number >= c.start_block AND b.number <= c.end_block
		ORDER BY v.voter, v.block_id DESC
	) t
	GROUP BY t.option_id;
$$ LANGUAGE sql STABLE STRICT;