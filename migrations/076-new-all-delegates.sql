-- Drop existing functions
DROP FUNCTION IF EXISTS dschief.all_delegates();
DROP FUNCTION IF EXISTS api.all_delegates();

CREATE OR REPLACE FUNCTION dschief.all_delegates()
RETURNS TABLE (
  delegate character varying(66),
  vote_delegate character varying(66),
  delegate_version int
) AS $$
SELECT delegate, vote_delegate, delegate_version
FROM dschief.vote_delegate_created_event
$$ LANGUAGE sql STABLE STRICT;


--This query would be called by allDelegates() in the sdk
CREATE OR REPLACE FUNCTION api.all_delegates()
RETURNS TABLE (
  delegate character varying(66),
  vote_delegate character varying(66),
  delegate_version int,
  block_timestamp TIMESTAMP WITH TIME ZONE
) AS $$
SELECT delegate, vote_delegate, delegate_version, b.timestamp
FROM dschief.vote_delegate_created_event d
LEFT JOIN vulcan2x.block b
ON d.block_id = b.id;
$$ LANGUAGE sql STABLE STRICT;