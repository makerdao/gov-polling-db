CREATE OR REPLACE FUNCTION api.hot_or_cold_weight_at_time(arg_unix INTEGER)
RETURNS TABLE (
	address character,
	total_weight decimal(78,18)
) AS $$
	WITH proxy_weights_temp AS (SELECT * FROM dschief.total_mkr_weight_all_proxies_at_time(arg_unix))
	SELECT hot as address, total_weight FROM proxy_weights_temp
	UNION (SELECT cold, total_weight FROM proxy_weights_temp);
$$ LANGUAGE sql STABLE STRICT;