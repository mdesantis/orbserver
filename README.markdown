Orbserver
=========

La classe Orbserver: 

	- permette di osservare automaticamente tutte le sottoclassi di ActiveRecord::Base (i modelli), escludendo alcune classi che non vogliamo osservare (e le relative sottoclassi).
	
	- estende le callbacks che notificano l'observer, comprendendo anche quelle delle associazioni (has_many, has_and_belongs_to_many)
	
	- implementa funzionalità per loggare le instanze dei modelli, ed anche parametri di sessione relativi alla momento in cui le suddette instanze subiscono un cambiamento.


Scelta del nome
===============

Ho chiamato questo plugin 'Orbserver' poiché è un'Observer applicato all'intera ActiveRecord::Base escluse alcune classi specificate, alle quali viene reso 'orbo'.


Installazione
=============

Copiare il plugin all'interno della cartella #{RAILS\_ROOT}/vendor/plugins e riavviare il server. Al momento della creazione/modifica/cancellazione di un'instanza di una classe figlia di ActiveRecord che non sia ActiveRecord::SessionStore::Session ('orbservato' di default), dovreste leggere la notifica della callback nel file #{RAILS\_ROOT}/log/database_changes.


Architettura
============

Il plugin si avvale dei seguenti sorgenti:

	- lib/orbserver.rb : implementazione della classe ActiveRecord::Orbserver , che estende la classe ActiveRecord::Observer .
	
	- lib/application_orbserver.rb : definisce la classe ApplicationOrbserver, che estende Orbserver; definisce le classi da orbservare, attiva il logging e definisce i metodi da eseguire nel momento in cui il modello chiama le callbacks relative al CUD (create, update, delete). È la classe che viene instanziata da init.rb .
	
	- lib/activerecord_base.rb : definisce la inspect che sarà scritta nel log. Ne ho dovuta definire un'altra poiché la inspect che definisce Rails per le instanze di ActiveRecord::Base non printa tutto l'oggetto, ma si limita a 30 lettere (o giù di lì, non ricordo con precisione) per campo. Dato che vogliamo che venga loggato tutto l'oggetto per intero, ho definito una full_inspect (utilizzabile, tra l'altro, anche direttamente da un'instanza dei modelli).
	
	- lib/orbserver_logger.rb : classe che definisce il logger dell'orbserver; estende BufferedLogger, che è un logger ottimizzato per essere utilizzato in produzione.
	
	- lib/associations_callbacks.rb : integra la classe ActiveRecord::Associations::ClassMethods, aggiungendo alle callbacks delle associazioni la notify all'observer, in quanto non sono supportate dall'observer definito da Rails

	- lib/session_info.rb : definisce il modulo SessionInfo , condiviso da ActiveRecord::Orbserver e da ActionController::Base , utilizzato per passare attributi del controller all'orbserver, di modo che l'orbserver sia in grado di leggere variabili interessanti ai fini di logging (id utente, indirizzo ip, ...).
	
	- lib/actioncontroller_base.rb : integra ActionController::Base , facendogli definire gli attributi da passare all'orbserver.
	
	- init.rb : inizializza l'orbserver
	

Per i dettagli delle classi, rimando ai commenti al codice delle stesse.


Configurazioni
==============

	- Classi da orbservare : tramite il metodo orbserve in lib/application_orbserver.rb è possibile definire le classi da orbservare. Il metodo accetta costanti o simboli, è possibile darne una sola o un array.

	Esempi:
	
		orbserve ActiveRecord::SessionStore::Session
		orbserve User
		orbserve [:user, :course]
		
		
	- Log : tramite il metodo create_logger in lib/application_orbserver.rb è possibile cambiare il nome al file di log (di default database_changes.log) e il log_level (di default :info).
	
	Esempi:
	
		create_logger
		create_logger 'orbserver_log', :warn
	
	
	- Parametri di sessione : modificare l'hash definito nel metodo set_session_info in lib/actioncontroller_base.rb per definire le variabili relative al controller che saranno leggibili dall'orbserver
	
	Esempi:
	
		SessionInfo::Setter.session_info = { :user_id => session[:user_id],  :request_ip => request.remote_ip }


Copyright (c) 2010 Maurizio De Santis, released under the MIT license
