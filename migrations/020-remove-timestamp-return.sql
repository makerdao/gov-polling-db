DROP FUNCTION IF EXISTS api.vote_option_mkr_weights_at_time(INTEGER, INTEGER);

-- this function would be called by getMkrAmtVoted(pollId, blockNumber)
CREATE OR REPLACE FUNCTION api.vote_option_mkr_weights_at_time(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (
	option_id INTEGER,
	mkr_support NUMERIC
) AS $$
SELECT option_id, SUM(weight) total_weight FROM dschief.most_recent_vote_only_at_time(arg_poll_id, arg_unix) v
LEFT JOIN dschief.total_mkr_weight_proxy_and_no_proxy_at_time(arg_unix)
ON voter = address
GROUP BY option_id
$$ LANGUAGE sql STABLE STRICT;