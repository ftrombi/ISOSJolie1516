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
    .database = "file:db/DB_magazzinoPrinc"; // "." for memory-only
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
      "(4, 'ruota', FALSE)," +
      "(5, 'catena', FALSE)," +
      "(6, 'casco', TRUE)";
    update@Database( updateRequest )( ret );
    nullProcess
  };

  scope ( insertTable ) {
    install ( SQLException => println@Console("Errore in insert magazzino")() );
    updateRequest =
      "INSERT INTO magazzino(id, nazione, provincia, citta, via, cap) VALUES" + 
      "(1, 'italia', 'pr', 'parma', 'tanara', '43100')," + 
      "(2, 'italia', 'bo', 'bologna', 'irnerio', '40126')," +
      "(3, 'italia', 'mi', 'milano', 'statuto', '20122')"
    update@Database( updateRequest )( ret )
  };

  scope ( insertTable ) {
    install ( SQLException => println@Console("Errore in insert pezzo_magazzino")() );
    updateRequest =
      "INSERT INTO pezzo_magazzino(id_pezzo, id_magazzino, quantita, riservati) VALUES" +
      "(0, 1, 5, 0),"
      "(1, 1, 3, 0),"
      "(2, 1, 2, 0),"
      "(0, 2, 5, 0),"
      "(5, 2, 3, 0),"
      "(6, 2, 2, 0),"
      "(4, 3, 5, 0),"
      "(3, 3, 3, 0),"
      "(5, 3, 2, 0)"
  };


    // shutdown DB
    update@Database( "SHUTDOWN" )( ret );

    nullProcess
} // end main
