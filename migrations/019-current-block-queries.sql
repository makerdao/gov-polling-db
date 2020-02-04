CREATE OR REPLACE FUNCTION dschief.balance_currently()
RETURNS TABLE (
  address character varying(66),
  balance decimal(78,18)
) AS $$
  	SELECT l.immediate_caller as address, SUM(l.lock) as balance
	FROM dschief.lock l 
	JOIN vulcan2x.block b ON b.id = l.block_id
	GROUP BY l.immediate_caller
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.all_active_vote_proxies_currently()
RETURNS TABLE (
  hot character varying(66),
  cold character varying(66),
  proxy character varying(66),
  proxy_mkr_weight decimal(78,18)
) AS $$
SELECT hot, cold, vote_proxy, proxy_mkr_weight
FROM dschief.vote_proxy_created_event
LEFT JOIN (SELECT address, balance as proxy_mkr_weight FROM dschief.balance_currently()) chief_table on vote_proxy = chief_table.address
WHERE proxy_mkr_weight > 0;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION mkr.holders_currently()
RETURNS TABLE (
address character varying(66),
balance decimal(78,18)
) AS $$
SELECT SUMS.address, COALESCE(SUMS.sum, 0) + COALESCE(SUBS.sum, 0) as balance FROM (
SELECT t.receiver as address, SUM(t.amount) FROM mkr.transfer_event t
GROUP BY t.receiver
) SUMS
LEFT JOIN (
SELECT sender as address, SUM(-t.amount) FROM mkr.transfer_event t 
GROUP BY t.sender
) SUBS ON (SUMS.address = SUBS.address);
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.total_mkr_weight_all_proxies_currently()
RETURNS TABLE (
  hot character varying(66),
  cold character varying(66),
  proxy character varying(66),
  total_weight decimal(78,18)
) AS $$
SELECT hot, cold, proxy, COALESCE(b1,0)+COALESCE(b2,0)+COALESCE(c1,0)+COALESCE(c2,0)+COALESCE(c3,0) as total_weight
FROM dschief.all_active_vote_proxies_currently()
LEFT JOIN (SELECT address, balance as b1 FROM mkr.holders_currently()) mkr_b on hot = mkr_b.address --mkr balance in hot
LEFT JOIN (SELECT address, balance as b2 FROM mkr.holders_currently()) mkr_b1 on cold = mkr_b1.address --mkr balance in cold
LEFT JOIN (SELECT address, balance as c1 FROM dschief.balance_currently()) ch_b1 on cold = ch_b1.address -- chief balance for cold
LEFT JOIN (SELECT address, balance as c2 FROM dschief.balance_currently()) ch_b2 on hot = ch_b2.address -- chief balance for hot
LEFT JOIN (SELECT address, balance as c3 FROM dschief.balance_currently()) ch_b3 on proxy = ch_b3.address; -- chief balance for proxy
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.hot_or_cold_weight_currently()
RETURNS TABLE (
	address character,
	total_weight decimal(78,18)
) AS $$
	SELECT * FROM (SELECT hot as address, total_weight FROM dschief.total_mkr_weight_all_proxies_currently()) h
	UNION (SELECT cold, total_weight FROM dschief.total_mkr_weight_all_proxies_currently());
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.combined_chief_and_mkr_balances_currently()
RETURNS TABLE (
  address character varying(66),
  mkr_and_chief_balance decimal(78,18)
) AS $$
	SELECT m.address, COALESCE(m.balance,0) + COALESCE(d.balance,0) as mkr_and_chief_balance
	FROM mkr.holders_currently() m
	FULL OUTER JOIN dschief.balance_currently() d
	ON m.address = d.address;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.total_mkr_weight_proxy_and_no_proxy_currently()
RETURNS TABLE (
  address character varying(66),
  weight decimal(78,18)
) AS $$
SELECT COALESCE(a.address, p.address) as address, COALESCE(p.total_weight,a.mkr_and_chief_balance) as weight FROM api.hot_or_cold_weight_currently() p
FULL OUTER JOIN api.combined_chief_and_mkr_balances_currently() a
ON p.address = a.address;
$$ LANGUAGE sql STABLE STRICT;

--this function would be called by getMkrWeight(address) in the sdk
CREATE OR REPLACE FUNCTION api.total_mkr_weight_proxy_and_no_proxy_by_address_currently(arg_address CHAR)
RETURNS TABLE (
  address character varying(66),
  weight decimal(78,18)
) AS $$
SELECT * FROM dschief.total_mkr_weight_proxy_and_no_proxy_currently()
WHERE address = arg_address;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.votes_with_proxy_currently(arg_poll_id INTEGER)
RETURNS TABLE (
	voter character,
	option_id integer,
	block_id integer,
	proxy_otherwise_voter character,
	hot character,
	cold character
) AS $$
	SELECT voter, option_id, block_id, COALESCE(proxy, voter) as proxy_otherwise_voter, hot, cold FROM polling.valid_votes(arg_poll_id)
	LEFT JOIN dschief.all_active_vote_proxies_currently()
	ON voter = hot OR voter = cold;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.most_recent_vote_only_currently(arg_poll_id INTEGER)
RETURNS TABLE (
  voter character,
  option_id integer,
  block_id integer,
  proxy_otherwise_voter character,
  hot character,
  cold character
) AS $$
SELECT * FROM dschief.votes_with_proxy_currently(arg_poll_id)
WHERE (proxy_otherwise_voter, block_id) IN (
select proxy_otherwise_voter, MAX(block_id) as block_id
from dschief.votes_with_proxy_currently(arg_poll_id)
group by proxy_otherwise_voter);
$$ LANGUAGE sql STABLE STRICT;

-- this function would be called by getMkrAmtVoted(pollId, blockNumber)
CREATE OR REPLACE FUNCTION api.vote_option_mkr_weights_currently(arg_poll_id INTEGER)
RETURNS TABLE (
	option_id INTEGER,
	mkr_support NUMERIC
) AS $$
SELECT option_id, SUM(weight) total_weight FROM dschief.most_recent_vote_only_currently(arg_poll_id) v
LEFT JOIN dschief.total_mkr_weight_proxy_and_no_proxy_currently()
ON voter = address
GROUP BY option_id
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION polling.valid_votes_currently(arg_poll_id INTEGER)
RETURNS TABLE (
  voter character varying(66),
  option_id integer,
  block_id integer
) AS $$
	SELECT voter, option_id, v.block_id FROM polling.voted_event v
	JOIN polling.poll_created_event c ON c.poll_id=v.poll_id
	JOIN vulcan2x.block b ON v.block_id = b.id
	WHERE v.poll_id = arg_poll_id AND b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date);
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.votes_with_proxy_currently(arg_poll_id INTEGER)
RETURNS TABLE (
	voter character,
	option_id integer,
	block_id integer,
	proxy_otherwise_voter character,
	hot character,
	cold character
) AS $$
	SELECT voter, option_id, block_id, COALESCE(proxy, voter) as proxy_otherwise_voter, hot, cold FROM polling.valid_votes_currently(arg_poll_id)
	LEFT JOIN dschief.all_active_vote_proxies_currently()
	ON voter = hot OR voter = cold;
$$ LANGUAGE sql STABLE STRICT;