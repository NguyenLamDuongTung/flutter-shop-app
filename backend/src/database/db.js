import mysql from 'mysql2/promise';

export function createDatabase(config) {
  const pool = mysql.createPool({
    host: config.host,
    port: config.port,
    database: config.name,
    user: config.user,
    password: config.password,

    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,

    charset: 'utf8mb4',

    decimalNumbers: true,

    supportBigNumbers: true,
    bigNumberStrings: false,
  });

  return {
    async query(sql, parameters = []) {
      const [rows] = await pool.execute(
        sql,
        parameters,
      );

      return rows;
    },

    async raw(sql) {
      const [rows] = await pool.query(sql);

      return rows;
    },

    async transaction(work) {
      const connection =
        await pool.getConnection();

      try {
        await connection.beginTransaction();

        const transactionDatabase = {
          async query(
            sql,
            parameters = [],
          ) {
            const [rows] =
              await connection.execute(
                sql,
                parameters,
              );

            return rows;
          },
        };

        const result = await work(
          transactionDatabase,
        );

        await connection.commit();

        return result;
      } catch (error) {
        await connection.rollback();

        throw error;
      } finally {
        connection.release();
      }
    },

    async close() {
      await pool.end();
    },
  };
}