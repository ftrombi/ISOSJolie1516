include "database.iol"
include "console.iol"

main {
  // Parametri
  with ( connectionInfo ) {
    .username = "acme";
    .password = "";
    .host = "";
    .port = 5434;
    .database = "file:db/DB_magazzinoPrincipale"; // "." for memory-only
    .driver = "hsqldb_embedded"
  };

  // Connessione a database
  connect@Database( connectionInfo )( void );

  // Creazione tabelle
  scope ( createTable ) {
    install ( SQLException => println@Console("Undefined problem during creation")() );
    updateRequest =
      "CREATE TABLE pezzo" + 
      "(id INTEGER PRIMARY KEY," + 
      "atomico BOOLEAN NOT NULL," +
      "nome VARCHAR(50) NOT NULL)";
    update@Database( updateRequest )( ret );

    updateRequest =
      "CREATE TABLE magazzino" +
      "(id INTEGER PRIMARY KEY," +
      "nazione VARCHAR(50) NOT NULL," +
      "provincia VARCHAR(50) NOT NULL," +
      "citta VARCHAR(50) NOT NULL," +
      "via VARCHAR(50) NOT NULL," +
      "cap VARCHAR(50) NOT NULL)";
    update@Database( updateRequest )( ret );

    updateRequest =
      "CREATE TABLE pezzo_magazzino" + 
      "(id_pezzo INTEGER NOT NULL," + 
      "id_magazzino INTEGER NOT NULL, " +
      "quantita INTEGER NOT NULL," +
      "FOREIGN KEY (id_pezzo) REFERENCES pezzo(id)," +
      "FOREIGN KEY (id_magazzino) REFERENCES magazzino(id)," +
      "PRIMARY KEY (id_pezzo, id_magazzino))";
    update@Database( updateRequest )( ret )

    };

    // shutdown DB
    update@Database( "SHUTDOWN" )( ret );

    nullProcess
} // end main