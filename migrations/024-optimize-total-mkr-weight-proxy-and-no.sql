CREATE OR REPLACE FUNCTION dschief.total_mkr_weight_proxy_and_no_proxy_at_time(arg_unix INTEGER)
RETURNS TABLE (
  address character varying(66),
  weight decimal(78,18)
) AS $$
	WITH mkr_balances_temp AS (SELECT * FROM mkr.holders_at_time(arg_unix)),
	chief_balances_temp AS (SELECT * FROM dschief.balance_at_time(arg_unix)),
	total_mkr_weight_all_proxies_temp AS (
		SELECT hot, cold, proxy, COALESCE(b1,0)+COALESCE(b2,0)+COALESCE(c1,0)+COALESCE(c2,0)+COALESCE(c3,0) as total_weight
		FROM dschief.all_active_vote_proxies_at_time(arg_unix)
		LEFT JOIN (SELECT address, balance as b1 FROM mkr_balances_temp) mkr_b on hot = mkr_b.address --mkr balance in hot
		LEFT JOIN (SELECT address, balance as b2 FROM mkr_balances_temp) mkr_b1 on cold = mkr_b1.address --mkr balance in cold
		LEFT JOIN (SELECT address, balance as c1 FROM chief_balances_temp) ch_b1 on cold = ch_b1.address -- chief balance for cold
		LEFT JOIN (SELECT address, balance as c2 FROM chief_balances_temp) ch_b2 on hot = ch_b2.address -- chief balance for hot
		LEFT JOIN (SELECT address, balance as c3 FROM chief_balances_temp) ch_b3 on proxy = ch_b3.address -- chief balance for proxy)
	),
	hot_or_cold_temp AS (
		SELECT hot as address, total_weight FROM total_mkr_weight_all_proxies_temp
		UNION (SELECT cold, total_weight FROM total_mkr_weight_all_proxies_temp)
	),
	combined_chief_and_mkr_temp AS
		(SELECT m.address, COALESCE(m.balance,0) + COALESCE(d.balance,0) as mkr_and_chief_balance
		FROM mkr_balances_temp m
		FULL OUTER JOIN chief_balances_temp d
		ON m.address = d.address
	)
	SELECT COALESCE(a.address, p.address) as address, COALESCE(p.total_weight,a.mkr_and_chief_balance) as weight FROM hot_or_cold_temp p
	FULL OUTER JOIN combined_chief_and_mkr_temp a
	ON p.address = a.address;
$$ LANGUAGE sql STABLE STRICT;