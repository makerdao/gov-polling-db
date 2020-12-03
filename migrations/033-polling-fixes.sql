drop index if exists dschief.vote_proxy_created_event_vote_proxy_idx;
create index vote_proxy_created_event_vote_proxy_idx on dschief.vote_proxy_created_event (vote_proxy);

-- this function only works with addresses that are proxies or unlinked addresses,
-- NOT hot or cold wallet addresses.
create or replace function polling.reverse_voter_weight(address character(42), block_id integer)
returns decimal(78,18) as $$
declare
  wallet_amount decimal(78,18);
  chief_amount decimal(78,18);
  proxy dschief.vote_proxy_created_event%rowtype;
  hot_wallet_amount decimal(78,18);
  cold_wallet_amount decimal(78,18);
begin
  select amount into wallet_amount from mkr.balances ba
  where ba.address = reverse_voter_weight.address
  and ba.block_id <= reverse_voter_weight.block_id
  order by ba.id desc limit 1;

  select amount into chief_amount from dschief.balances ba
  where ba.address = reverse_voter_weight.address
  and ba.block_id <= reverse_voter_weight.block_id
  order by ba.id desc limit 1;

  -- if address is a proxy, add balances for hot & cold wallets

  select * into proxy
  from dschief.vote_proxy_created_event vpc
  where vote_proxy = reverse_voter_weight.address
  and vpc.block_id <= reverse_voter_weight.block_id
  order by vpc.id desc limit 1;

  if proxy is not null then
    select amount into hot_wallet_amount from mkr.balances ba
    where ba.address = proxy.hot
    and ba.block_id <= reverse_voter_weight.block_id
    order by ba.id desc limit 1;

    select amount into cold_wallet_amount from mkr.balances ba
    where ba.address = proxy.cold
    and ba.block_id <= reverse_voter_weight.block_id
    order by ba.id desc limit 1;
  end if;

  return coalesce(wallet_amount, 0) + 
    coalesce(chief_amount, 0) + 
    coalesce(hot_wallet_amount, 0) +
    coalesce(cold_wallet_amount, 0);
end;
$$ language plpgsql stable strict;

-- if the input is a hot or cold wallet, return the proxy address.
-- used to treat votes from hot & cold wallet for the same proxy as duplicates.
create or replace function polling.unique_voter_address(address character(42))
returns character(42) as $$
  select coalesce(
    (
      select vote_proxy from dschief.vote_proxy_created_event 
      where address in (hot, cold)
      order by id desc limit 1
    ),
    address
  )
$$ language sql stable strict;

CREATE OR REPLACE FUNCTION polling.unique_votes(arg_poll_id INTEGER)
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
        polling.unique_voter_address(voter) address, 
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

drop function if exists polling.votes; -- must drop because return value changed
create function polling.votes(poll_id integer, block_id integer)
returns table (
  voter character(42), -- if vote was sent by a hot or cold wallet, this is a proxy address
  option_id integer,
  option_id_raw character,
  amount decimal(78,18)
) as $$
  select 
    voter,
    option_id, 
    option_id_raw,
    polling.reverse_voter_weight(voter, votes.block_id)
  from polling.unique_votes(votes.poll_id) vv
  where vv.block_id <= votes.block_id
$$ language sql stable strict;

drop function if exists polling.votes_at_block; -- must drop because return value changed
create function polling.votes_at_block(poll_id integer, block_number integer)
returns table (
  voter character(42), -- if vote was sent by a hot or cold wallet, this is a proxy address
  option_id integer,
  option_id_raw character,
  amount decimal(78,18)
) as $$
  select * from polling.votes(poll_id, (
    select id from vulcan2x.block where number = block_number
  )) 
$$ language sql stable strict;

drop function if exists polling.votes_at_time; -- must drop because return value changed
create function polling.votes_at_time(poll_id integer, unixtime integer)
returns table (
  voter character(42), -- if vote was sent by a hot or cold wallet, this is a proxy address
  option_id integer,
  option_id_raw character,
  amount decimal(78,18)
) as $$
  select * from polling.votes(poll_id, (
    select id from vulcan2x.block where timestamp <= to_timestamp(unixtime)
    order by timestamp desc limit 1
  )) 
$$ language sql stable strict;

create or replace function api.vote_option_mkr_weights_at_time(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (option_id INTEGER, mkr_support NUMERIC) AS $$
  select option_id, sum(amount)
  from polling.votes_at_time(arg_poll_id, arg_unix)
  group by option_id
$$ LANGUAGE sql STABLE STRICT;

CREATE OR REPLACE FUNCTION api.vote_mkr_weights_at_time_ranked_choice(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (option_id_raw character, mkr_support NUMERIC) AS $$
  select option_id_raw, amount
  from polling.votes_at_time(arg_poll_id, arg_unix)
$$ LANGUAGE sql STABLE STRICT;
