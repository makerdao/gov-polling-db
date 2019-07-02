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