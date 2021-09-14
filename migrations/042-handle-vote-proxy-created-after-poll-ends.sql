-- replaces function in 033 to not count vote proxies that were created after the supplied block id
-- if the input is a hot or cold wallet, return the proxy address.
-- used to treat votes from hot & cold wallet for the same proxy as duplicates.
create or replace function polling.unique_voter_address(address character(42), arg_block_id integer)
returns character(42) as $$
  select coalesce(
    (
      select vote_proxy from dschief.vote_proxy_created_event 
      where address in (hot, cold)
      and block_id <= arg_block_id
      order by id desc limit 1
    ),
    address
  )
$$ language sql stable strict;

CREATE OR REPLACE FUNCTION polling.unique_votes(arg_poll_id INTEGER, arg_block_id INTEGER)
RETURNS TABLE (
  voter character(42), -- if vote was sent by a hot or cold wallet, this is a proxy address
  option_id integer,
  option_id_raw character,
  block_id integer
) AS $$
  select address, option_id, option_id_raw, block_id from (
    -- middle query removes duplicates by unique address
    select 
      address,
      option_id,
      option_id_raw,
      block_id,
      row_number() over (partition by address order by block_id desc) rownum from (
      -- innermost query looks up unique address
      select
        polling.unique_voter_address(voter, arg_block_id) address, 
        option_id, 
        option_id_raw, 
        v.block_id
      from polling.voted_event v
      join polling.poll_created_event c on c.poll_id = v.poll_id
      join vulcan2x.block b on v.block_id = b.id
      where v.poll_id = arg_poll_id 
      and b.timestamp between to_timestamp(c.start_date) and to_timestamp(c.end_date)
    ) sub2
  ) sub1
  where rownum = 1;
$$ LANGUAGE sql STABLE STRICT;

create or replace function polling.votes(poll_id integer, block_id integer)
returns table (
  voter character(42), -- if vote was sent by a hot or cold wallet, this is a proxy address
  option_id integer,
  option_id_raw character,
  amount decimal(78,18)
) as $$
  select 
    voter,
    option_id, 
    option_id_raw,polling.reverse_voter_weight
    (voter, votes.block_id)
  from polling.unique_votes(votes.poll_id, votes.block_id) vv
  where vv.block_id <= votes.block_id
$$ language sql stable strict;
