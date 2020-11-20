# use cases

for a poll:
- votes (address, MKR amount, option) at current block
- votes at block that matches poll end time

for a spell:
- votes (address, MKR amount) at current block
- votes at block that matches time when spell became hat

# warts

- GraphiQL live docs are the only way to see all API calls available
- no need for separate *_ranked_choice functions since we can convert to/from raw values
- should be two layers: one works with block number, one with timestamp

# vote weights function dependency tree

- vote_option_mkr_weights_at_time(poll_id, timestamp) (20)
  - dschief.most_recent_vote_only_at_time (18)
    - dschief.votes_with_proxy_at_time (18)
      - polling.valid_votes_at_time (18)
        - polling.voted_event
        - polling.poll_created_event
        - vulcan2x.block
      - dschief.all_active_vote_proxies_at_time (27)
        - dschief.vote_proxy_created_event
        - vulcan2x.block
  - dschief.total_mkr_weight_proxy_and_no_proxy_at_time (24)
    - mkr.holders_at_time (18)
      - mkr.transfer_event
      - vulcan2x.block
    - dschief.balance_at_time (18)
      - dschief.lock
      - vulcan2x.block
    - dschief.all_active_vote_proxies_at_time ⤴

# refactoring pseudocode

schema
  polls
    poll id
    hash
    etc.
    at_block
    block_id -> vulcan2x.block(id)
  votes
    poll id
    address
    at_block
    block_id -> vulcan2x.block(id)
  balances
    amount
    address
    owner_address
    at_block
    block_id -> vulcan2x.block(id)

balance for addr incl. proxy:
  select max(block_id)
  select sum(amount) 
    from balances 
    where (address = ?a or owner_address = ?a) 
    and at_block = ?b
    and block_id = ?c

# example repl usage

```
~/Code/makerdao/gov-polling-db polling-performance-spike* 1m 40s
❯ yarn repl
yarn run v1.22.10
$ node --experimental-repl-await -r ./loadenv.js ./repl
Using mainnet config
ℹ Ethereum providers #1
> await mbt.test.processRow(services.db, { from: '0x731c6f8c754fa404cfcc2ed8035ef79262f65702', to: '0x642ae78fafbb8032da552d619ad43f1d81e4dd7c', value: '1500000000000000003', tx_id: 1, block_id: 1 })
null
> await mbt.test.processRow(services.db, { from: '0x731c6f8c754fa404cfcc2ed8035ef79262f65702', to: '0x642ae78fafbb8032da552d619ad43f1d81e4dd7c', value: '1500000000000000003', tx_id: 1, block_id: 1 })
null
```

now the db should be:

```
user@127:database> select * from mkr.balances \G
-[ RECORD 1 ]-------------------------
id       | 6
address  | 0x642ae78fafbb8032da552d619ad43f1d81e4dd7c
amount   | 1.500000000000000003
tx_id    | 1
block_id | 1
-[ RECORD 2 ]-------------------------
id       | 7
address  | 0x731c6f8c754fa404cfcc2ed8035ef79262f65702
amount   | -1.500000000000000003
tx_id    | 1
block_id | 1
-[ RECORD 3 ]-------------------------
id       | 8
address  | 0x642ae78fafbb8032da552d619ad43f1d81e4dd7c
amount   | 3.000000000000000006
tx_id    | 1
block_id | 1
-[ RECORD 4 ]-------------------------
id       | 9
address  | 0x731c6f8c754fa404cfcc2ed8035ef79262f65702
amount   | -3.000000000000000006
tx_id    | 1
block_id | 1
```