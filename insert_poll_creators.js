require('dotenv').config();

const pgp = require('pg-promise')();
const authorizedCreatorsArray = (process.env.AUTHORIZED_CREATORS || '').split(',').map(creator => creator.toLowerCase());

const cn = {
  host: process.env.VL_DB_HOST,
  port: process.env.VL_DB_PORT,
  database: process.env.VL_DB_DATABASE,
  user: process.env.VL_DB_USER,
  password: process.env.VL_DB_PASSWORD
};

const db = pgp(cn);

const deleteQuery = 'DELETE FROM polling.creators';
const insertQuery = 'INSERT INTO polling.creators (address) VALUES ($1)';

function executeQueries(connection) {
  return connection.none(deleteQuery)
    .then(() => connection.tx(t => t.batch(authorizedCreatorsArray.map(creator => connection.none(insertQuery, creator)))))
    .catch(err => console.error('Error message: ', err.message, 'Stack trace: ', err.stack));
}

db.connect()
  .then(connection => {
    executeQueries(connection)
      .finally(() => connection.done());
  })
  .catch(err => console.error('Error message: ', err.message, 'Stack trace: ', err.stack));