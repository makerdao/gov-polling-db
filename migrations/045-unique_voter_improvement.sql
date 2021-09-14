-- replaces function in 042 to handle case where linked wallet has a more recent vote proxy.
-- if the input is a hot or cold wallet, return the proxy address.
-- used to treat votes from hot & cold wallet for the same proxy as duplicates, and
-- to ensure that an address only has at most one active vote proxy
create or replace function polling.unique_voter_address(address character(42), arg_block_id integer)
returns character(42) as $$
  declare
    proxy dschief.vote_proxy_created_event%rowtype;
    linked_proxy dschief.vote_proxy_created_event%rowtype;
  begin
      select * into proxy from dschief.vote_proxy_created_event 
      where address in (hot, cold)
      and block_id <= arg_block_id
      order by id desc limit 1;

      -- if linked address has a more recent vote proxy, then proxy is not valid
      if proxy is not null then
        if address = proxy.hot then
          select * into linked_proxy from dschief.vote_proxy_created_event 
          where proxy.cold in (hot, cold)
          and block_id <= arg_block_id
          order by id desc limit 1;
        end if;

        if address = proxy.cold then
          select * into linked_proxy from dschief.vote_proxy_created_event 
          where proxy.hot in (hot, cold)
          and block_id <= arg_block_id
          order by id desc limit 1;
        end if;

        if linked_proxy is not null and linked_proxy.block_id > proxy.block_id then
          return address;
        end if;
      end if;

    return coalesce(proxy.vote_proxy,address);
  end;
$$ language plpgsql stable strict;