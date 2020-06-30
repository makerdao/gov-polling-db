CREATE OR REPLACE FUNCTION dschief.all_active_vote_proxies_at_time(arg_unix INTEGER)
RETURNS TABLE (
  hot character varying(66),
  cold character varying(66),
  proxy character varying(66)
) AS $$
WITH max_table AS (SELECT hot_and_cold, MAX(block_id) FROM (
	SELECT hot as hot_and_cold, block_id FROM dschief.vote_proxy_created_event
	UNION
	SELECT cold, block_id FROM dschief.vote_proxy_created_event) u
	JOIN vulcan2x.block b ON b.id = block_id
	WHERE EXTRACT (EPOCH FROM b.timestamp) <= arg_unix
	GROUP BY hot_and_cold)
SELECT hot, cold, vote_proxy as proxy FROM dschief.vote_proxy_created_event e
LEFT JOIN max_table as cold_max
ON cold = cold_max.hot_and_cold
LEFT JOIN max_table as hot_max
ON hot = hot_max.hot_and_cold
JOIN vulcan2x.block b ON b.id = block_id
WHERE EXTRACT (EPOCH FROM b.timestamp) <= arg_unix
AND block_id >= cold_max.max
AND block_id >= hot_max.max;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.all_active_vote_proxies(arg_block_number INTEGER)
RETURNS TABLE (
  hot character varying(66),
  cold character varying(66),
  proxy character varying(66)
) AS $$
WITH max_table AS (SELECT hot_and_cold, MAX(block_id) FROM (
	SELECT hot as hot_and_cold, block_id FROM dschief.vote_proxy_created_event
	UNION
	SELECT cold, block_id FROM dschief.vote_proxy_created_event) u
	JOIN vulcan2x.block b ON b.id = block_id
	WHERE b.number <= arg_block_number
	GROUP BY hot_and_cold)
SELECT hot, cold, vote_proxy as proxy FROM dschief.vote_proxy_created_event e
LEFT JOIN max_table as cold_max
ON cold = cold_max.hot_and_cold
LEFT JOIN max_table as hot_max
ON hot = hot_max.hot_and_cold
JOIN vulcan2x.block b ON b.id = block_id
WHERE b.number <= arg_block_number
AND block_id >= cold_max.max
AND block_id >= hot_max.max;
$$ LANGUAGE sql STABLE STRICT;