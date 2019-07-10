require('dotenv').config();
const pgp = require('pg-promise')();
const cn = {
    host: process.env.VL_DB_HOST,
    port: process.env.VL_DB_PORT,
    database: process.env.VL_DB_DATABASE,
    user: process.env.VL_DB_USER,
    password: process.env.VL_DB_PASSWORD
};
const db = pgp(cn);

const insertLock = (t, values) => { //todo, import this from dsChiefTransformers
  return t.none(
    `
INSERT INTO dschief.lock(contract_address, from_address, immediate_caller, lock, timestamp, log_index, tx_id, block_id) VALUES (\${contractAddress}, \${fromAddress}, \${immediateCaller}, \${lock}, \${timestamp}, \${logIndex}, \${txId}, \${blockId})`,
    values
  );
};

const insertPollCreated = (t, values) => {
  return t.none(
    `
INSERT INTO polling.poll_created_event
    (creator,block_created,poll_id,start_date,end_date,multi_hash,log_index,tx_id,block_id) 
    VALUES(\${creator}, \${block_created}, \${poll_id}, \${start_date}, \${end_date}, \${multi_hash}, \${log_index}, \${tx_id}, \${block_id});`,
    values
  );
};

test('can get poll created', async () => {
  /*await insertLock(db,{
      fromAddress: '0xfrom',
      immediateCaller: '0xcaller',
      lock: '3',
      contractAddress: '0xaddress',
      txId: 1,
      blockId: 1,
      logIndex: 3,
      timestamp: '2017-11-25 18:24:17+00',
    });*/
  const l = await db.any('SELECT * FROM dschief.lock');
  console.log('l', l);
  //expect(l.includes()).toBe(true);
});
