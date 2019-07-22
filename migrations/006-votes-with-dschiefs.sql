CREATE OR REPLACE FUNCTION dschief.balance_on_block(arg_block_number INTEGER)
RETURNS TABLE (
  address character varying(66),
  balance decimal(78,18)
) AS $$
  	SELECT l.immediate_caller as address, SUM(l.lock) as balance
	FROM dschief.lock l 
	JOIN vulcan2x.block b ON b.id = l.block_id
	WHERE b.number <= arg_block_number
	GROUP BY l.immediate_caller
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.all_active_vote_proxies(arg_block_number INTEGER)
RETURNS TABLE (
  hot character varying(66),
  cold character varying(66),
  proxy character varying(66),
  proxy_mkr_weight decimal(78,18)
) AS $$
SELECT hot, cold, vote_proxy, proxy_mkr_weight
FROM dschief.vote_proxy_created_event
LEFT JOIN (SELECT address, balance as proxy_mkr_weight FROM dschief.balance_on_block(arg_block_number)) chief_table on vote_proxy = chief_table.address
WHERE proxy_mkr_weight > 0;
$$ LANGUAGE sql STABLE STRICT;


--This query would be called by getOptionVotingFor(pollId, address) in the sdk
CREATE OR REPLACE FUNCTION api.current_vote(arg_address CHAR, arg_poll_id INTEGER)
RETURNS TABLE (
	option_id INTEGER,
	block_id INTEGER
) AS $$
SELECT option_id, block_id FROM polling.valid_votes(arg_poll_id)
		WHERE voter = (SELECT hot FROM dschief.all_active_vote_proxies(arg_poll_id) WHERE cold = arg_address)
		OR voter = (SELECT cold FROM dschief.all_active_vote_proxies(arg_poll_id) WHERE hot = arg_address)
		OR voter = arg_address
		ORDER BY block_id DESC
		LIMIT 1;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.total_mkr_weight_all_proxies(arg_block_number INTEGER)
RETURNS TABLE (
  hot character varying(66),
  cold character varying(66),
  proxy character varying(66),
  total_weight decimal(78,18)
) AS $$
SELECT hot, cold, proxy, COALESCE(b1,0)+COALESCE(b2,0)+COALESCE(c1,0)+COALESCE(c2,0)+COALESCE(c3,0) as total_weight
FROM dschief.all_active_vote_proxies(arg_block_number)
LEFT JOIN (SELECT address, balance as b1 FROM mkr.holders_on_block(arg_block_number)) mkr_b on hot = mkr_b.address --mkr balance in hot
LEFT JOIN (SELECT address, balance as b2 FROM mkr.holders_on_block(arg_block_number)) mkr_b1 on cold = mkr_b1.address --mkr balance in cold
LEFT JOIN (SELECT address, balance as c1 FROM dschief.balance_on_block(arg_block_number)) ch_b1 on cold = ch_b1.address -- chief balance for cold
LEFT JOIN (SELECT address, balance as c2 FROM dschief.balance_on_block(arg_block_number)) ch_b2 on hot = ch_b2.address -- chief balance for hot
LEFT JOIN (SELECT address, balance as c3 FROM dschief.balance_on_block(arg_block_number)) ch_b3 on proxy = ch_b3.address; -- chief balance for proxy
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.combined_chief_and_mkr_balances(arg_block_number INTEGER)
RETURNS TABLE (
  address character varying(66),
  mkr_and_chief_balance decimal(78,18)
) AS $$
	SELECT m.address, COALESCE(m.balance,0) + COALESCE(d.balance,0) as mkr_and_chief_balance
	FROM mkr.holders_on_block(arg_block_number) m
	FULL OUTER JOIN dschief.balance_on_block(arg_block_number) d
	ON m.address = d.address;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.hot_or_cold_weight(arg_block_number INTEGER)
RETURNS TABLE (
	address character,
	total_weight decimal(78,18)
) AS $$
	SELECT * FROM (SELECT hot as address, total_weight FROM dschief.total_mkr_weight_all_proxies(arg_block_number)) h
	UNION (SELECT cold, total_weight FROM dschief.total_mkr_weight_all_proxies(arg_block_number));
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.total_mkr_weight_proxy_and_no_proxy(arg_block_number INTEGER)
RETURNS TABLE (
  address character varying(66),
  weight decimal(78,18)
) AS $$
SELECT a.address, COALESCE(p.total_weight,a.mkr_and_chief_balance) as weight FROM api.hot_or_cold_weight(arg_block_number) p
RIGHT JOIN api.combined_chief_and_mkr_balances(arg_block_number) a
ON p.address = a.address;
$$ LANGUAGE sql STABLE STRICT;

--this function would be called by getMkrWeight(address) in the sdk
CREATE OR REPLACE FUNCTION api.total_mkr_weight_proxy_and_no_proxy_by_address(arg_address CHAR, arg_block_number INTEGER)
RETURNS TABLE (
  address character varying(66),
  weight decimal(78,18)
) AS $$
SELECT * FROM dschief.total_mkr_weight_proxy_and_no_proxy(arg_block_number)
WHERE address = arg_address;
$$ LANGUAGE sql STABLE STRICT;


CREATE OR REPLACE FUNCTION dschief.votes_with_proxy(arg_poll_id INTEGER, arg_block_number INTEGER)
RETURNS TABLE (
	voter character,
	option_id integer,
	block_id integer,
	proxy_otherwise_voter character,
	hot character,
	cold character
) AS $$
	SELECT voter, option_id, block_id, COALESCE(proxy, voter) as proxy_otherwise_voter, hot, cold FROM polling.valid_votes(arg_poll_id)
	LEFT JOIN dschief.all_active_vote_proxies(arg_block_number)
	ON voter = hot OR voter = cold;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.most_recent_vote_only(arg_poll_id INTEGER, arg_block_number INTEGER)
RETURNS TABLE (
  voter character,
  option_id integer,
  block_id integer,
  proxy_otherwise_voter character,
  hot character,
  cold character
) AS $$
SELECT * FROM dschief.votes_with_proxy(arg_poll_id,arg_block_number)
WHERE (proxy_otherwise_voter, block_id) IN (
select proxy_otherwise_voter, MAX(block_id) as block_id
from dschief.votes_with_proxy(arg_poll_id,arg_block_number)
group by proxy_otherwise_voter);
$$ LANGUAGE sql STABLE STRICT;

-- this function would be called by getMkrAmtVoted(pollId, blockNumber)
CREATE OR REPLACE FUNCTION api.vote_option_mkr_weights(arg_poll_id INTEGER, arg_block_number INTEGER)
RETURNS TABLE (
	option_id INTEGER,
	mkr_support NUMERIC,
	block_timestamp TIMESTAMP WITH TIME ZONE
) AS $$
SELECT option_id, total_weight, b.timestamp FROM (SELECT option_id, SUM(weight) total_weight FROM dschief.most_recent_vote_only(arg_poll_id, arg_block_number) v
LEFT JOIN dschief.total_mkr_weight_proxy_and_no_proxy(arg_block_number)
ON voter = address
GROUP BY option_id) m
LEFT JOIN vulcan2x.block b ON b.number = arg_block_number;
$$ LANGUAGE sql STABLE STRICT;
