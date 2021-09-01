-- this function only works with addresses that are proxies or unlinked addresses,
-- NOT hot or cold wallet addresses.
create or replace function polling.buggy_reverse_voter_weight(address character(42), block_id integer)
returns decimal(78,18) as $$
declare
  wallet_amount decimal(78,18);
  chief_amount decimal(78,18);
  proxy dschief.vote_proxy_created_event%rowtype;
  hot_wallet_amount decimal(78,18);
  cold_wallet_amount decimal(78,18);
begin
  select amount into wallet_amount from mkr.balances ba
  where ba.address = buggy_reverse_voter_weight.address
  and ba.block_id <= buggy_reverse_voter_weight.block_id
  order by ba.id desc limit 1;

  select amount into chief_amount from dschief.balances ba
  where ba.address = buggy_reverse_voter_weight.address
  and ba.block_id <= buggy_reverse_voter_weight.block_id
  order by ba.id desc limit 1;

  -- if address is a proxy, add balances for hot & cold wallets

  select * into proxy
  from dschief.vote_proxy_created_event vpc
  where vote_proxy = buggy_reverse_voter_weight.address
  and vpc.block_id <= buggy_reverse_voter_weight.block_id
  order by vpc.id desc limit 1;

  if proxy is not null then
    select amount into hot_wallet_amount from mkr.balances ba
    where ba.address = proxy.hot
    and ba.block_id <= buggy_reverse_voter_weight.block_id
    order by ba.id desc limit 1;

    select amount into cold_wallet_amount from mkr.balances ba
    where ba.address = proxy.cold
    and ba.block_id <= buggy_reverse_voter_weight.block_id
    order by ba.id desc limit 1;
  end if;

  return coalesce(wallet_amount, 0) + 
    coalesce(chief_amount, 0) + 
    coalesce(hot_wallet_amount, 0) +
    coalesce(cold_wallet_amount, 0);
end;
$$ language plpgsql stable strict;

CREATE OR REPLACE FUNCTION polling.buggy_votes(poll_id integer, block_id integer)
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
    polling.buggy_reverse_voter_weight(voter, buggy_votes.block_id)
  from polling.unique_votes(buggy_votes.poll_id) vv
  where vv.block_id <= buggy_votes.block_id
$$ language sql stable strict;

CREATE OR REPLACE FUNCTION polling.buggy_votes_at_time(poll_id integer, unixtime integer)
returns table (
  voter character(42), -- if vote was sent by a hot or cold wallet, this is a proxy address
  option_id integer,
  option_id_raw character,
  amount decimal(78,18)
) as $$
  select * from polling.buggy_votes(poll_id, (
    select id from vulcan2x.block where timestamp <= to_timestamp(unixtime)
    order by timestamp desc limit 1
  )) 
$$ language sql stable strict;

CREATE OR REPLACE FUNCTION api.buggy_vote_mkr_weights_at_time_ranked_choice(arg_poll_id INTEGER, arg_unix INTEGER)
RETURNS TABLE (option_id_raw character, mkr_support NUMERIC) AS $$
  select option_id_raw, amount
  from polling.buggy_votes_at_time(arg_poll_id, arg_unix)
$$ LANGUAGE sql STABLE STRICT;

