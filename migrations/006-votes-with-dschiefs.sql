CREATE OR REPLACE FUNCTION dschief.balance_on_block(arg_block_number INTEGER)
RETURNS TABLE (
  address character varying(66),
  hot     character varying(66),
  cold    character varying(66),
  balance decimal(78,18)
) AS $$
  	SELECT l.immediate_caller as address, p.hot, p.cold, SUM(l.lock) as balance
	FROM dschief.lock l 
	LEFT JOIN dschief.vote_proxy_created_event p ON p.vote_proxy = l.immediate_caller
	JOIN vulcan2x.block b ON b.id = l.block_id
	WHERE b.number <= arg_block_number
	GROUP BY l.immediate_caller, p.hot, p.cold
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.balance_on_block(arg_address CHAR, arg_block_number INTEGER)
RETURNS TABLE (
  address character varying(66),
  hot     character varying(66),
  cold    character varying(66),
  balance decimal(78,18)
) AS $$
	SELECT * FROM dschief.balance_on_block(arg_block_number)
	WHERE address = arg_address;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.current_vote(arg_address CHAR, arg_poll_id INTEGER)
RETURNS TABLE (
	option_id INTEGER,
	block_id INTEGER
) AS $$
SELECT option_id, block_id FROM api.valid_votes(arg_poll_id)
		WHERE voter = (SELECT hot FROM api.associated_proxy_address(arg_address))
		OR voter = (SELECT cold FROM api.associated_proxy_address(arg_address))
		OR voter = arg_address
ORDER BY block_id DESC
LIMIT 1;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.all_active_vote_proxies(arg_block_number INTEGER)
RETURNS TABLE (
  hot character varying(66),
  cold character varying(66),
  proxy character varying(66),
  proxy_mkr_weight decimal(78,18)
) AS $$
SELECT cold, hot, vote_proxy, proxy_mkr_weight
FROM dschief.vote_proxy_created_event
LEFT JOIN (SELECT address, balance as proxy_mkr_weight FROM dschief.balance_on_block(arg_block_number)) chief_table on vote_proxy = chief_table.address
WHERE proxy_mkr_weight > 0;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.total_mkr_weight_all_proxies(arg_block_number INTEGER)
RETURNS TABLE (
  hot character varying(66),
  cold character varying(66),
  proxy character varying(66),
  total_weight decimal(78,18)
) AS $$
SELECT hot, cold, proxy, COALESCE(b1,0)+COALESCE(b2,0)+COALESCE(c1,0)+COALESCE(c2,0)+COALESCE(c3,0) as total_weight
FROM api.all_active_vote_proxies(arg_block_number)
LEFT JOIN (SELECT address, balance as b1 FROM mkr.holders_on_block(arg_block_number)) mkr_b on hot = mkr_b.address /*mkr balance in hot*/
LEFT JOIN (SELECT address, balance as b2 FROM mkr.holders_on_block(arg_block_number)) mkr_b1 on cold = mkr_b1.address /*mkr balance in cold*/
LEFT JOIN (SELECT address, balance as c1 FROM dschief.balance_on_block(arg_block_number)) ch_b1 on cold = ch_b1.address /*chief balance for cold*/
LEFT JOIN (SELECT address, balance as c2 FROM dschief.balance_on_block(arg_block_number)) ch_b2 on hot = ch_b2.address /*chief balance for hot*/
LEFT JOIN (SELECT address, balance as c3 FROM dschief.balance_on_block(arg_block_number)) ch_b3 on proxy = ch_b3.address; /*chief balance for proxy*/
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

CREATE OR REPLACE FUNCTION api.total_mkr_weight_proxy_and_no_proxy(arg_block_number INTEGER)
RETURNS TABLE (
  address character varying(66),
  weight decimal(78,18)
) AS $$
SELECT COALESCE(a1.address, a2.address) address, COALESCE(total_weight, a1.mkr_and_chief_balance, a2.mkr_and_chief_balance) weight
FROM api.total_mkr_weight_all_proxies(arg_block_number) p
FULL OUTER JOIN api.combined_chief_and_mkr_balances(arg_block_number) a1
ON p.cold = a1.address
FULL OUTER JOIN api.combined_chief_and_mkr_balances(arg_block_number) a2
ON p.hot = a2.address;
$$ LANGUAGE sql STABLE STRICT;


CREATE OR REPLACE FUNCTION api.vote_option_mkr_weights(arg_poll_id INTEGER, arg_block_number INTEGER)
RETURNS TABLE (
	option_id INTEGER,
	mkr_support NUMERIC
) AS $$
SELECT option_id, SUM(COALESCE(t1.total_weight, 0) + COALESCE(t2.total_weight, 0)) as mkr_support FROM api.valid_votes(arg_poll_id) v
LEFT JOIN api.total_mkr_weight_all_addresses(arg_block_number) t1 ON v.voter = t1.hot
LEFT JOIN api.total_mkr_weight_all_addresses(arg_block_number) t2 ON v.voter = t2.cold
GROUP BY option_id;
$$ LANGUAGE sql STABLE STRICT;


CREATE OR REPLACE FUNCTION polling.votes(arg_poll_id INTEGER)
RETURNS TABLE (
  option_id INTEGER,
  balance decimal(78,18)
) AS $$
  	SELECT t.option_id, SUM(COALESCE(mkr_balance, 0) + COALESCE(l_a_balance, 0) + COALESCE(l_h_balance, 0)) FROM (
		SELECT distinct ON (v.voter) v.voter, v.option_id, t.balance as mkr_balance, l_a.balance as l_a_balance, l_h.balance as l_h_balance FROM polling.voted_event v 
		JOIN polling.poll_created_event c ON c.poll_id=v.poll_id
		JOIN mkr.holders_on_block(c.end_date) t ON v.voter = t.address 
		LEFT JOIN dschief.balance_on_block(c.end_date) l_a ON v.voter = l_a.address
		LEFT JOIN dschief.balance_on_block(c.end_date) l_h ON v.voter = l_h.hot
		JOIN vulcan2x.block b ON v.block_id = b.id
		WHERE c.poll_id = arg_poll_id AND b.number >= c.start_date AND b.number <= c.end_date
		ORDER BY v.voter, v.block_id DESC
	) t
	GROUP BY t.option_id;
$$ LANGUAGE sql STABLE STRICT;