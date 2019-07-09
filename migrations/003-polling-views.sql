CREATE OR REPLACE FUNCTION mkr.holders_on_block(arg_block_number INTEGER)
RETURNS TABLE (
  address character varying(66),
  balance decimal(78,18)
) AS $$
  	SELECT SUMS.address, COALESCE(SUMS.sum, 0) + COALESCE(SUBS.sum, 0) as balance 
  	FROM (SELECT receiver as address, SUM(t.amount) FROM mkr.transfer_event t JOIN vulcan2x.block b ON b.id = t.block_id WHERE b.number <= arg_block_number GROUP BY t.receiver) SUMS
	LEFT JOIN (SELECT sender as address, SUM(-t.amount) FROM mkr.transfer_event t JOIN vulcan2x.block b ON b.id = t.block_id WHERE b.number <= arg_block_number GROUP BY t.sender) SUBS ON (SUMS.address = SUBS.address);
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.mkr_balance_on_block(arg_address CHAR, arg_block_number INTEGER)
RETURNS TABLE (
	address character varying(66),
	balance decimal(78,18)
) AS $$
	SELECT * FROM dschief.balance_on_block(arg_block_number)
	WHERE address = arg_address;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.valid_votes(arg_poll_id INTEGER)
RETURNS TABLE (
  voter character,
  option_id integer,
  log_index integer,
  tx_id integer,
  block_id integer
) AS $$
	SELECT voter, option_id, v.log_index, v.tx_id, v.block_id FROM polling.voted_event v
	JOIN polling.poll_created_event c ON c.poll_id=v.poll_id
	JOIN vulcan2x.block b ON v.block_id = b.id
	WHERE v.poll_id = 1 AND b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date)
	AND v.poll_id = arg_poll_id;
$$ LANGUAGE sql STABLE STRICT;

-- this function would be called by getNumUniqueVoters(pollId) in the sdk
CREATE OR REPLACE FUNCTION api.unique_voters(arg_poll_id INTEGER)
RETURNS TABLE (
  unique_voters BIGINT
) AS $$
	SELECT COUNT(DISTINCT voter) FROM api.valid_votes(arg_poll_id);
$$ LANGUAGE sql STABLE STRICT;

-- this function would be called by getAllWhitelistedPolls() in the sdk
CREATE OR REPLACE FUNCTION api.active_polls()
RETURNS TABLE (
  creator character varying(66),
  poll_id INTEGER,
  block_created INTEGER,
  start_date INTEGER,
  end_date INTEGER,
  multi_hash character varying(66)
) AS $$
	SELECT C.creator, C.poll_id, C.block_created, C.start_date, C.end_date, C.multi_hash
	FROM polling.poll_created_event AS C
	LEFT JOIN polling.poll_withdrawn_event AS W
	ON C.poll_id = W.poll_id AND C.creator = W.creator
	WHERE W.block_withdrawn IS NULL
	ORDER BY C.end_date;
$$ LANGUAGE sql STABLE STRICT;