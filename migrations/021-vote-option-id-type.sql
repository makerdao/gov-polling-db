ALTER TABLE polling.voted_event
ADD COLUMN option_id_raw character varying(66);

ALTER TABLE polling.voted_event
ALTER COLUMN option_id DROP NOT NULL;

CREATE OR REPLACE FUNCTION polling.valid_votes_at_time_ranked_choice(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (
  voter character varying(66),
  option_id_raw character,
  block_id integer
) AS $$
	SELECT voter, option_id_raw, v.block_id FROM polling.voted_event v
	JOIN polling.poll_created_event c ON c.poll_id=v.poll_id
	JOIN vulcan2x.block b ON v.block_id = b.id
	WHERE EXTRACT (EPOCH FROM b.timestamp) <= arg_unix AND v.poll_id = arg_poll_id AND b.timestamp >= to_timestamp(c.start_date) AND b.timestamp <= to_timestamp(c.end_date);
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.votes_with_proxy_at_time_ranked_choice(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (
	voter character,
	option_id_raw character,
	block_id integer,
	proxy_otherwise_voter character,
	hot character,
	cold character
) AS $$
	SELECT voter, option_id_raw, block_id, COALESCE(proxy, voter) as proxy_otherwise_voter, hot, cold FROM polling.valid_votes_at_time_ranked_choice(arg_poll_id, arg_unix)
	LEFT JOIN dschief.all_active_vote_proxies_at_time(arg_unix)
	ON voter = hot OR voter = cold;
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION dschief.most_recent_vote_only_at_time_ranked_choice(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (
  voter character,
  option_id_raw character,
  block_id integer,
  proxy_otherwise_voter character,
  hot character,
  cold character
) AS $$
SELECT * FROM dschief.votes_with_proxy_at_time_ranked_choice(arg_poll_id,arg_unix)
WHERE (proxy_otherwise_voter, block_id) IN (
select proxy_otherwise_voter, MAX(block_id) as block_id
from dschief.votes_with_proxy_at_time_ranked_choice(arg_poll_id,arg_unix)
group by proxy_otherwise_voter);
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.vote_mkr_weights_at_time_ranked_choice(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (
	option_id_raw character,
	mkr_support NUMERIC
) AS $$
SELECT option_id_raw, weight FROM dschief.most_recent_vote_only_at_time_ranked_choice(arg_poll_id, arg_unix) v
LEFT JOIN dschief.total_mkr_weight_proxy_and_no_proxy_at_time(arg_unix)
ON voter = address
$$ LANGUAGE sql STABLE STRICT;