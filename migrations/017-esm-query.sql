CREATE OR REPLACE FUNCTION api.all_esm_joins()
RETURNS TABLE (
  tx_from character varying(66),
  tx_hash character varying(66),
  join_amount decimal(78,18),
  block_timestamp TIMESTAMP WITH TIME ZONE
) AS $$
SELECT j.from_address, t.hash, j.join_amount, b.timestamp
FROM esm.mkr_joins j
LEFT JOIN vulcan2x.transaction t
ON j.tx_id = t.id
LEFT JOIN vulcan2x.block b
ON j.block_id = b.id;
$$ LANGUAGE sql STABLE STRICT;