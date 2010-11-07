# == Prologo: l'Observer; vantaggi e svantaggi
#
# Gli Observer reagiscono alle callbacks di un modello permettendo l'implementazione
# di un comportamento ad eventi in una classe esterna, in modo da non dover caricare
# il modello con funzioni che non gli competono. Esempio:
#
# Questo Observer utilizza logger per loggare callbacks in modo specifico
#
#	class ContactObserver < ActiveRecord::Observer
#
#		def after_create(contact)
#			contact.logger.info('New contact added!')
#		end
#
#		def after_destroy(contact)
#			contact.logger.warn("Contact with an id of #{contact.id} was destroyed!")
#		end
#
#	end
# 
# Per il resto delle informazioni sull'Observer si rimanda alle API di Rails.
#
# == L'Orbserver
#
# Observer lavora per inclusione, cioè permette di dichiarare dei modelli da osservare,
# ma non dei modelli da non osservare, caratteristica utile per impostare un Observer che
# osservi tutti i modelli che abbiamo tranne alcuni che non ci interessano; motivo per cui
# si è resa necessaria l'implementazione della classe Orbserver.
#
# Nota: perché non inizializzare l'Observer con tutti i modelli che abbiamo, esclusi quelli 
# che non interessano?
#
# Perché Rails carica le classi nel momento in cui vengono chiamate per la prima volta; ciò implica
# che, nel momento in cui l'Observer viene inizializzato, non tutti i modelli saranno presenti
# (ed anzi in genere quasi nessuno).
#
# Orbserver lavora per esclusione: rende cieco (o meglio "orbo") l'Observer ai modelli
# specificati (ed alle relative sottoclassi), osservando invece tutti gli altri. Ciò è stato
# implementato creando un Observer che punta l'intero ActiveRecord::Base, ed un'istanza di
# classe che andrà a contenere i modelli che non interessano e che si avrà avuto cura di 
# "orbservare").
#
# == Inizializzazione di un Orbserver
#
# Per avviare un Orbserver è sufficiente definirne i parametri principali ed istanziarlo all'avvio
# (tramite MyOrbserver.instance).
# 
# == Configurare il proprio Orbserver
#
# Copiando il plugin, init.rb istanzia un ApplicationOrbserver con alcune impostazioni di default;
# è possibile modificare la classe ApplicationOrbserver per adattarla alle proprie esigenze, come
# anche definirne uno proprio ed istanziarlo.
#
# Nel file init.rb del plugin è possibile cambiare queste impostazioni.
#
class ActiveRecord::Orbserver < ActiveRecord::Observer # Dichiaro una classe Orbserver figlia di ActiveRecord::Observer
	
	# Modulo condiviso con ActionController::Base, serve a condividere con l'Orbserver parametri
	# di sessione utili (come per es. session[:user_id]). Vedere il modulo SessionInfo per i dettagli.
	include SessionInfo::Getter

	# :nodoc: Questa parte contiene i metodi di classe della classe stessa; le variabili @ dichiarate
	# all'interno di questa sezione saranno considerate variabili di classe (poiché Ruby le considera
	# variabili d'istanza di self, cioè di Orbserver, che è una classe)
	class << self

		# La classe osservata; è sempre ActiveRecord::Base
		def observed_class
			ActiveRecord::Base
		end

		# Rende l'Orbserver orbo ai modelli dichiarati ed alle loro sottoclassi; è possibile passare i modelli come simboli,
		# o passarne direttamente le classi (o anche un mixin dei due, per es. orbserve(User, :course))
		def orbserve(*models)
			models.flatten!
			models.collect! { |model| model.is_a?(Symbol) ? model.to_s.camelize.constantize : model }
			self.orbserved_classes.merge Set.new(models)
		end

		# Restituisce true se la classe passata fa parte dei modelli orbizzati, o se è una sottoclasse
		# di questi; altrimenti false
		def orbserved?(model)
			model = model.to_s.camelize.constantize if model.is_a?(Symbol)
			self.orbserved_classes.include?(model) || self.orbserved_subclasses?(model)
		end

		# Resetta l'Orbserver dandogli piena visibilità; non annullabile!!!
		def reset_orbservers!
			@orbserved_classes = Set.new
			self.observe(observed_class)
		end

		# Restituisce le classi orbservate
		def orbserved_classes
			@orbserved_classes ||= Set.new
		end

		# Restituisce true se il modello passatogli è una sottoclasse di uno dei modelli orbservati
		def orbserved_subclasses?(model)
			orbserved_classes.each do |klass|
				return true if klass.send(:subclasses).include? model
			end
			false
		end
		
		# Instanzia una nuova classe figlia di OrbserverLogger che prende il nome dall'Orbserver
		# in cui è richiamata (se non è già stata definita manualmente). Esempio:
		#
		#	class MyOrbserver < ActiveRecord::Orbserver
		#
		#		create_logger # Creo un logger di nome MyOrbserverLogger, accessibile
		#					  # tramite MyOrbserver::MyOrbserverLogger
		#
		#	end
		#
		# Una volta creato, il logger sarà il destinatario delle chiamate log_this() dell'Orbserver.
		#
		# == Impostare il Logger
		#
		# Di default, il nome del file di log è impostato come 'database_changes', risiederà
		# in "#{RAILS_ROOT}/log/" ed avrà estensione .log; inoltre, il livello del logger è impostato
		# ad INFO. È possibile cambiare il nome del log ed il livello passando i due parametri come
		# argomenti. Esempio:
		#
		#	class MyOrbserver < ActiveRecord::Orbserver
		#
		#		create_logger('my_log_filename', :warn) # Il nome del file sarà 'my_log_filename' ed
		#												# il livello del logger WARN. Il livello del
		#												# logger dev'essere passato come simbolo
		#
		#	end
		#
		def create_logger(filename = "database_changes", level = :info)
			logger_class = self.instantiate_logger_class
			begin
				log_level_const = ActiveSupport::BufferedLogger::Severity.const_get(level.to_s.upcase)
			rescue NameError
				raise NameError, "L'argomento 'level' deve essere un simbolo che identifichi una delle constanti presenti in ActiveSupport::BufferedLogger::Severity (esempi: :warn, :fatal)"
			end
			@logger = { :class => logger_class, :instance => logger_class.new("#{RAILS_ROOT}/log/#{filename}.log", log_level_const), :level => level }
		end
		
		def logger
			@logger ||= {}
		end
		
		protected
		# Instanzia la classe del log figlia di ActiveSupport::OrbserverLogger (il cui nome avrà
		# la forma "#{classe dell'Orbserver in cui è chiamata}Logger"), e la dichiara come costante
		# di classe; altrimenti dichiara come costante di classe quella già istanziata.
		#
		def instantiate_logger_class
			logger_class_name = "#{self.name}Logger"
			begin
				self.const_get(logger_class_name)
			rescue NameError
				self.const_set(logger_class_name, Class.new(ActiveSupport::OrbserverLogger))
			end
		end

	end

	protected
	
	# Chiama la corrispondente funzione dell'Orbserver genitore, questa volta preoccupandosi di controllare
	# che la classe passata non sia orbservata
	#
	def add_observer!(klass)
		super unless self.class.orbserved?(klass)
	end
	
	# Passa la stringa da loggare al logger associato all'Orbserver, o la printa se l'Orbserver
	# non è dichiarato.
	#
	# 	1. Cerco il log associato all'Orbserver; se non è dichiarato printo la stringa
	# 	2. Chiamo l'azione di scrittura sul logger a seconda del livello per cui è stato inizializzato.
	#
	def log_this(model_obj, callback, calling_obj = nil, association = false)
		logger = self.class.logger
		str = log_string(model_obj, callback, calling_obj, association)
		unless logger.empty? # 1.
			logger[:instance].send(logger[:level], str) # 2.
		else
			puts str
		end
	end
	
	# Metodo definito per loggare le associazioni, chiama la funzione di log passando come argomento anche l'oggetto
	# associato.
	def associated_callbacks_log(obj, callback)
		if obj.associated_object
			model_obj = obj.associated_object
			calling_obj = obj
		end
		log_this(model_obj, callback, calling_obj, true)
	end
	
	# Crea la stringa da loggare a seconda dell'oggetto e della callback.
	#
	# Note:
	# 	1. Estraggo la stringa dell'azione dalla callback (tramite una RegExp).
	#		Es. callback = :after_create; action = callback.to_s.[/_(.*)\z/, 1]; puts action # >> 'create'
	#	2. Definisco metodi per oggetti specifici
	#		a. action.past: restituisce il passato di un azione.
	#			Esempi: action = "update"; action.past # >> 'updated'
	#					action = "destroy"; action.past # >> 'destroyed'
	#		b. action.preposition: definito in caso l'azione sia un add o una remove, restituisce 'to' nel
	#			primo caso, 'from' nel secondo; altrimenti stringa vuota.
	# 	3. str: stringa di ritorno
	#	4.a. calling_obj: definito se la callback chiamata deriva da un'associazione (hm, habtm)
	# 	4.b. current_user: richiamato dall'ActionController::Base tramite il modulo condiviso SessionInfo
	#	4.c. request_ip: come sopra
	# 	5. Se l'azione è una update pesco i valori cambiati (tramite un metodo implementato
	#		in activerecord_base.rb)
	#		a. Valori precedenti alla update
	#		b. Valori successivi alla update
	#
	def log_string(model_obj, callback, calling_obj = nil, association = false)
		callback = callback.to_s
		action = callback[/_(.*)\z/, 1] # 1.
		def action.past; self + (self[/e\z/i] ? 'd' : 'ed') ; end # 2.a.
		def action.preposition; ['add','remove'].include?(self) ? (self == 'add' ? 'to' : 'from') : ''; end # 2.b.
		str = String.new # 3.
		# str << DateTime.now.strftime("%Y/%m/%d - %H:%M") +
		str << DateTime.now.to_s(:db) +
			" | #{model_obj.class.name}##{model_obj.id.to_s} #{action.past.upcase}" +
			(calling_obj ? " #{action.preposition} #{calling_obj.class.name}##{calling_obj.id.to_s}" : "") + # 4.a.
			" by User#" + (session_info[:user_id] ? session_info[:user_id].to_s : '<anonymous>') + # 4.b.
			" on " + (session_info[:request_ip] ? session_info[:request_ip].to_s : '<unknown ip address>') # 4.c.
		if action == "update" # 5.
			str << "\n\t#{callback.humanize.upcase} DETAILS (ONLY CHANGED VALUES):\n" + 
				"\t\tPREVIOUS VALUES: #{model_obj.focused_to_changed_values_full_inspect(:prev)}\n" + # 5.a.
				"\t\tACTUAL VALUES: #{model_obj.focused_to_changed_values_full_inspect(:succ)}" # 5.b.
		else
			str << "\n\t#{callback.humanize.upcase} DETAILS: #{model_obj.full_inspect}" unless association == true
		end
		str + "\n"
	end

end
