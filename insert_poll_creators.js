require('dotenv').config();

const pgp = require('pg-promise')();

const db = pgp({
  host: process.env.VL_DB_HOST,
  port: process.env.VL_DB_PORT,
  database: process.env.VL_DB_DATABASE,
  user: process.env.VL_DB_USER,
  password: process.env.VL_DB_PASSWORD
});

const authorizedCreatorsArray = (process.env.AUTHORIZED_CREATORS || '').split(',').map(creator => creator.toLowerCase());

const deleteQuery = 'DELETE FROM polling.creators';
const insertQuery = 'INSERT INTO polling.creators (address) VALUES ($1)';

async function executeQueries() {
  try {
    await db.none(deleteQuery);
    console.log('All previous creators deleted.');

    for (const creator of authorizedCreatorsArray) {
      await db.none(insertQuery, creator);
      console.log(`Creator ${creator} added successfully.`);
    }

    console.log('All authorized creators added successfully.');
  } catch (err) {
    console.error('Error: ', err);
  }
}

executeQueries().catch(err => console.error('Error: ', err));