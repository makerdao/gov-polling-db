drop function if exists polling.votes; -- must drop because arguments changed
create function polling.votes(poll_id integer, block_id integer, poll_end_timestamp	timestamp with time zone)
returns table (
  voter character(42), -- if vote was sent by a hot or cold wallet, this is a proxy address
  option_id integer,
  option_id_raw character,
  amount decimal(78,18),
  chain_id integer,
  block_timestamp	timestamp with time zone,
  hash 			character varying(66)
) as $$
  select 
    voter,
    option_id,
    option_id_raw,
    polling.reverse_voter_weight(voter, votes.block_id),
    chain_id,
    block_timestamp,
    hash
    	from unique_votes(votes.poll_id, votes.block_id) vv 
    	where vv.block_timestamp <= poll_end_timestamp -- get the unique vote that is LTE to the poll end timestamp
$$ language sql stable strict;


create or replace function  polling.votes_at_time(poll_id integer, unixtime integer)
returns table (
  voter character(42), -- if vote was sent by a hot or cold wallet, this is a proxy address
  option_id integer,
  option_id_raw character,
  amount decimal(78,18),
  chain_id integer,
  block_timestamp	timestamp with time zone,
  hash 			character varying(66)
) as $$
  select * from polling.votes(poll_id, (
    -- get the L1 block at the endtime timestamp, or nearest one below it
    select id from vulcan2x.block where timestamp <= to_timestamp(unixtime)
    order by timestamp desc limit 1
  ), to_timestamp(unixtime))
$$ language sql stable strict;