drop function if exists voted_events_merged;
create function voted_events_merged(arg_proxy_block_id_mn integer)
returns table (
	poll_id 		integer,	
	address 		character(42),
	option_id       integer,
	option_id_raw   character varying(66),
	block_id   		integer,
	chain_id  		integer,
	block_timestamp	timestamp with time zone
) AS $$
	SELECT DISTINCT (poll_id) poll_id, address, option_id, option_id_raw, block_id, chain_id, timestamp 
    FROM (
		SELECT polling.unique_voter_address(voter, arg_proxy_block_id_mn) address, option_id, option_id_raw, block_id, poll_id, chain_id, b.timestamp 
		FROM polling.voted_event ve
		join vulcan2x.block b on ve.block_id = b.id
			UNION
		SELECT polling.unique_voter_address(voter, arg_proxy_block_id_mn) address, option_id, option_id_raw, block_id, poll_id, chain_id, ba.timestamp 
		FROM polling.voted_event_arbitrum vea
		join vulcan2xarbitrum.block ba on vea.block_id = ba.id
		) sub1
$$ language sql stable strict;

drop function if exists unique_votes;
CREATE OR REPLACE FUNCTION unique_votes(arg_poll_id INTEGER, arg_proxy_block_id_mn INTEGER)
RETURNS TABLE (
  voter character(42), -- if vote was sent by a hot or cold wallet, this is a proxy address
  option_id integer,
  option_id_raw character,
  block_id integer,
  chain_id integer
) AS $$
  select address, option_id, option_id_raw, block_id, chain_id
  from (
    -- middle query removes duplicates by unique address
    select 
      address,
      option_id,
      option_id_raw,
      block_id,
      chain_id,
      block_timestamp,
      row_number() over (partition by address order by block_timestamp desc) rownum from (
      -- innermost query looks up unique address
      select
      	address address,
        option_id, 
        option_id_raw, 
        v.block_id,
        v.chain_id,
        v.block_timestamp
      from voted_events_merged(arg_proxy_block_id_mn) v
      join polling.poll_created_event c on c.poll_id = v.poll_id
      where v.poll_id = arg_poll_id 
      and v.block_timestamp between to_timestamp(c.start_date) and to_timestamp(c.end_date)
    ) sub2
  ) sub1
  where rownum = 1;
$$ LANGUAGE sql STABLE STRICT;

drop function if exists polling.votes; -- must drop because return value changed
create function polling.votes(poll_id integer, block_id integer)
returns table (
  voter character(42), -- if vote was sent by a hot or cold wallet, this is a proxy address
  option_id integer,
  option_id_raw character,
  amount decimal(78,18),
  chain_id integer
) as $$
  select 
    voter,
    option_id, 
    option_id_raw,
    polling.reverse_voter_weight(voter, votes.block_id),
    chain_id
    	from unique_votes(votes.poll_id, votes.block_id) vv 
    	where vv.block_id <= votes.block_id
$$ language sql stable strict;

drop function if exists votes_at_time;
create function votes_at_time(poll_id integer, unixtime integer)
returns table (
  voter character(42), -- if vote was sent by a hot or cold wallet, this is a proxy address
  option_id integer,
  option_id_raw character,
  amount decimal(78,18),
  chain_id integer
) as $$
  select * from polling.votes(poll_id, (
    select id from vulcan2x.block where timestamp <= to_timestamp(unixtime)
    order by timestamp desc limit 1
  )) 
$$ language sql stable strict;

DROP FUNCTION IF EXISTS api.vote_address_mkr_weights_at_time;
CREATE FUNCTION api.vote_address_mkr_weights_at_time(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (voter CHARACTER, option_id INTEGER, option_id_raw CHARACTER, mkr_support NUMERIC, chain_id INTEGER) AS $$
  select voter, option_id, option_id_raw, amount, chain_id
  from polling.votes_at_time(arg_poll_id, arg_unix)
$$ LANGUAGE sql STABLE STRICT;