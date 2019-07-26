require('dotenv').config();
const pgp = require('pg-promise')();
const { request } = require('graphql-request');
const cn = {
  host: process.env.VL_DB_HOST,
  port: process.env.VL_DB_PORT,
  database: process.env.VL_DB_DATABASE,
  user: process.env.VL_DB_USER,
  password: process.env.VL_DB_PASSWORD
};
const db = pgp(cn);

class Counter {
  constructor() {
    this.count = 0;
  }
  next() {
    return ++this.count;
  }
  current() {
    return this.count;
  }
}

const TransactionCount = new Counter();
const BlockCount = new Counter();
const PollCount = new Counter();

async function insertBlockAndTransaction() {
  await insertBlock(db, {
    number: BlockCount.next(),
    hash: '0x' + BlockCount.current(),
    timestamp: new Date(BlockCount.current() * 1000).toISOString() //for simplicity the timestamp is blockNumber of seconds after Unix time started
  });
  await insertTransaction(db, {
    id: TransactionCount.next(),
    hash: '0x' + TransactionCount.current(),
    to_address: '0x731c6f8c754fa404cfcc2ed8035ef79262f65702',
    from_address: '0x00daa9a2d88bed5a29a6ca93e0b7d860cd1d403f',
    block_id: BlockCount.current(),
    nonce: 1,
    value: 0,
    gas_limit: 3000000,
    gas_price: 1000000000,
    data: 0xc0406226
  });
}

const insertTransaction = (t, values) => {
  return t.none(
    `INSERT INTO vulcan2x.transaction
    (id,hash,to_address,from_address,block_id,nonce,value,gas_limit,gas_price,data) 
    VALUES(\${id}, \${hash}, \${to_address}, \${from_address}, \${block_id}, \${nonce}, \${value}, \${gas_limit}, \${gas_price}, \${data});`,
    values
  );
};

const insertBlock = (t, values) => {
  return t.none(
    `INSERT INTO vulcan2x.block
    (number, hash, timestamp)
    VALUES(\${number}, \${hash}, \${timestamp});`,
    values
  );
};

const insertLock = (t, values) => {
  return t.none(`INSERT INTO dschief.lock(contract_address, from_address, immediate_caller, lock, log_index, tx_id, block_id) VALUES (\${contractAddress}, \${fromAddress}, \${immediateCaller}, \${lock}, \${logIndex}, \${txId}, \${blockId})`,
    values
  );
};

const insertVote = (t, values) => {
  return t.none(`INSERT INTO polling.voted_event
    (voter,poll_id,option_id,log_index,tx_id,block_id) 
    VALUES(\${voter}, \${poll_id}, \${option_id}, \${log_index}, \${tx_id}, \${block_id});`,
    values
  );
};

const insertPollCreated = (t, values) => {
  return t.none(`INSERT INTO polling.poll_created_event
    (creator,block_created,poll_id,start_date,end_date,multi_hash,url,log_index,tx_id,block_id) 
    VALUES(\${creator}, \${block_created}, \${poll_id}, \${start_date}, \${end_date}, \${multi_hash}, \${url}, \${log_index}, \${tx_id}, \${block_id});`,
    values
  );
};

afterAll(() => {
  db.$pool.end();
});

describe('active poll', () => {
  const POLL_CREATOR = "0xcreator";
  const POLL_START_DATE = 0;
  const POLL_END_DATE = 3;
  const POLL_MULTI_HASH = "MuLtIhAsH";
  const POLL_URL = "https://makerdao.com";

  test('can add an active poll', async () => {
    await insertBlockAndTransaction();
    await insertPollCreated(db, {
      creator: POLL_CREATOR,
      block_created: BlockCount.current(),
      poll_id: PollCount.next(),
      start_date: POLL_START_DATE,
      end_date: POLL_END_DATE,
      url: POLL_URL,
      multi_hash: POLL_MULTI_HASH,
      log_index: BlockCount.current(),
      tx_id: TransactionCount.current(),
      block_id: BlockCount.current()
    });
    const p = await db.any('SELECT * FROM api.active_polls()');
    expect(!!p[0]).toBe(true);
  });

  test('can get an active poll via graphql', async () => {
    const query = `{
      activePolls(first: 1) {
        nodes {
          creator
          pollId
          blockCreated
          startDate
          endDate
          multiHash
          url
        }
      }
    }`

    const { activePolls } = await request('http://localhost:3001/v1', query);
    expect(activePolls).toBeDefined();
    const poll = activePolls.nodes[0];
    expect(poll).toBeDefined();
    expect(poll.creator).toBe(POLL_CREATOR);
    expect(poll.multiHash).toBe(POLL_MULTI_HASH);
    expect(poll.url).toBe(POLL_URL);
  });
})



test('can add a valid vote', async () => {
  const active_polls = await db.any('SELECT * FROM api.active_polls()');
  const firstPoll = active_polls[0];
  await insertBlockAndTransaction();
  await insertVote(db, {
    voter: '0xvoter1',
    poll_id: firstPoll.poll_id,
    option_id: 1,
    log_index: BlockCount.current(),
    tx_id: TransactionCount.current(),
    block_id: firstPoll.start_date + 1
  });
  const v = await db.any('SELECT * FROM polling.valid_votes(1)');
  expect(!!v[0]).toBe(true);
});




test('can get a lock entry', async () => {
  await insertBlockAndTransaction();
  await insertLock(db, {
    fromAddress: '0xfrom',
    immediateCaller: '0xcaller',
    lock: "3",
    contractAddress: '0xaddress',
    txId: TransactionCount.current(),
    blockId: BlockCount.current(),
    logIndex: "3",
  });
  const l = await db.any('SELECT * FROM dschief.lock');
  expect(!!l[0]).toBe(true);
});

