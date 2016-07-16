include "database.iol"
include "console.iol"

/** DB MAGAZZINO PRINCIPALE **/

main {
  // Impostazione parametri
  with ( connectionInfo ) {
    .username = "acme";
    .password = "";
    .host = "";
    .port = 5434;
    .database = "file:db/DB_magazzinoPrimario"; // "." for memory-only
    .driver = "hsqldb_embedded"
  };

  // Connessione a database
  connect@Database( connectionInfo )( void );

  scope ( insertTable ) {
    install ( SQLException => println@Console("Errore in insert pezzo")());
    updateRequest =
      "INSERT INTO pezzo(id, nome, atomico) VALUES" + 
      "(0, 'campanello', TRUE)," +
      "(1, 'faro', TRUE)," +
      "(2, 'sterzo', FALSE)," +
      "(3, 'sellino', FALSE)," +
      "(4, 'cerchione', FALSE)," +
      "(5, 'catena', FALSE)," +
      "(6, 'telaio', FALSE)," +
      "(7, 'manubrio', TRUE)," +
      "(8, 'camera aria', TRUE)," +
      "(9, 'gomme', FALSE)," +
      "(10, 'casco', TRUE)";
    update@Database( updateRequest )( ret );
    nullProcess
  };

  scope ( insertTable ) {
    install ( SQLException => println@Console("Errore in insert magazzino")() );
    updateRequest =
      "INSERT INTO magazzino(id, provincia, citta) VALUES" + 
      "(0, 'pr', 'parma')," + 
      "(1, 'bo', 'bologna')," +
      "(2, 'mi', 'milano')";
    update@Database( updateRequest )( ret )
  };

  scope ( insertTable ) {
    install ( SQLException => println@Console("Errore in insert pezzo_magazzino")() );
    updateRequest =
      "INSERT INTO pezzo_magazzino(id_pezzo, id_magazzino, quantita, riservati) VALUES" +
      "(0, 0, 5, 0)," +
      "(1, 0, 3, 0)," +
      "(2, 0, 2, 0)," +
      "(0, 1, 5, 0)," +
      "(5, 1, 3, 0)," +
      "(6, 1, 2, 0)," +
      "(4, 2, 5, 0)," +
      "(3, 2, 3, 0)," +
      "(5, 2, 2, 0)";
    update@Database( updateRequest )( ret )
  };


    // shutdown DB
    update@Database( "SHUTDOWN" )( ret );

    nullProcess
} // end main
