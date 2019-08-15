CREATE OR REPLACE FUNCTION dschief.total_mkr_weight_proxy_and_no_proxy(arg_block_number INTEGER)
RETURNS TABLE (
  address character varying(66),
  weight decimal(78,18)
) AS $$
SELECT COALESCE(a.address, p.address) as address, COALESCE(p.total_weight,a.mkr_and_chief_balance) as weight FROM api.hot_or_cold_weight(arg_block_number) p
FULL OUTER JOIN api.combined_chief_and_mkr_balances(arg_block_number) a
ON p.address = a.address;
$$ LANGUAGE sql STABLE STRICT;