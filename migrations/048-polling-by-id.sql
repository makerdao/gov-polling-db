CREATE OR REPLACE FUNCTION api.active_poll_by_id(arg_poll_id INTEGER)
RETURNS TABLE (
  creator character varying(66),
  poll_id INTEGER,
  block_created INTEGER,
  start_date INTEGER,
  end_date INTEGER,
  multi_hash character varying(66),
  url character varying(255)
) AS $$
	SELECT C.creator, C.poll_id, C.block_created, C.start_date, C.end_date, C.multi_hash, C.url
	FROM polling.poll_created_event AS C
	LEFT JOIN polling.poll_withdrawn_event AS W
	ON C.poll_id = W.poll_id AND C.creator = W.creator
	WHERE W.block_withdrawn IS NULL AND C.poll_id = arg_poll_id
	ORDER BY C.end_date;
$$ LANGUAGE sql STABLE STRICT;


CREATE OR REPLACE FUNCTION api.active_poll_by_multihash(arg_poll_multihash TEXT)
RETURNS TABLE (
  creator character varying(66),
  poll_id INTEGER,
  block_created INTEGER,
  start_date INTEGER,
  end_date INTEGER,
  multi_hash character varying(66),
  url character varying(255)
) AS $$
	SELECT C.creator, C.poll_id, C.block_created, C.start_date, C.end_date, C.multi_hash, C.url
	FROM polling.poll_created_event AS C
	LEFT JOIN polling.poll_withdrawn_event AS W
	ON C.poll_id = W.poll_id AND C.creator = W.creator
	WHERE W.block_withdrawn IS NULL AND C.multi_hash LIKE arg_poll_multihash
	ORDER BY C.end_date;
$$ LANGUAGE sql STABLE STRICT;