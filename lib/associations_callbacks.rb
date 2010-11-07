module ActiveRecord::Associations::ClassMethods
	
	# Preposizioni alle chiamate has_many e has_and_belongs_to_many che aggiungono alle after callbacks
	# la notifica all'Orbserver
	#
	# Note:
	#	notify: metodo (di cui non c'è traccia sulle API nè di Ruby nè di Rails) che aggiunge un dato metodo
	#			a quelli osservabili dall'Observer. Per saperne di più (Zach Dennis, ti devo una birra!):
	#				http://www.mutuallyhuman.com/2009/1/6/using-custom-activerecord-events-callbacks
	#				
	def has_and_belongs_to_many_with_observed_callbacks(association_id, options = {}, &extension)

		observed_callbacks.each { |callback|
			create_notifing_callback_method(callback, :habtm)
			options.update( observed_callbacks_hash( { callback => options[callback] }, :habtm) )
		}

		has_and_belongs_to_many_without_observed_callbacks(association_id, options, &extension)	
	end
	
	def has_many_with_observed_callbacks(association_id, options = {}, &extension)

		observed_callbacks.each { |callback|
			create_notifing_callback_method(callback, :hm)
			options.update( observed_callbacks_hash( { callback => options[callback] }, :hm) )
		}

		has_many_without_observed_callbacks(association_id, options, &extension)
	end

	# alias_method_chain concatena il metodo di nome #{metodo}_with_#{descrizione_funzione} al metodo
	# #{metodo} , in modo da espanderne le funzionalità.
	#
	alias_method_chain :has_and_belongs_to_many, :observed_callbacks
	alias_method_chain :has_many, :observed_callbacks
	
	private
	
	# Callbacks osservate (sono tra le callbacks delle associazioni, definite da Rails)
	#
	def observed_callbacks
		[:after_add, :after_remove]
	end
	
	# Crea il metodo d'istanza di notifica all'Orbserver nella classe chiamante e assegna l'oggetto
	# interessato dalla callback alla variabile d'istanza @associated_object dell'oggetto del modello
	# che implementa l'associazione; l'oggetto potrà in questo modo venire utilizzato dall'Observer.
	#
	def create_notifing_callback_method(callback, association_initials)
		unless self.instance_methods.include?("notify_#{association_initials}_#{callback}")
		
			# Definisco un metodo che, tramite la chiamata della notify(:nome_metodo_d_istanza_del_modello)
			# notifica all'Observer l'esecuzione del metodo passato come argomento.
			#
			# FIXME: non ho ancora capito in base a cosa le callbacks delle associazioni passino l'oggetto
			#		 associato; infatti, a volte restituiscono l'oggetto corretto (UserType, ...),
			#		 altre volte (CourseUser :after_remove, ...) uno degli oggetti implicati nell'associazione.
			#		 Spero mi venga un'idea per ovviare al problema... 
			#
			#		 ***** edit *****
			#		 Ho scoperto che il metodo ritorna o un oggetto-associazione (UserType), oppure,
			#		 nel caso ritorni uno dei due oggetti coinvolti nell'associazione (xes. CourseUser -> User),
			#		 l'oggetto chiamante è l'altro oggetto associato; esempio: 
			#
			#			CourseUser -> notify_habtm_after_remove(oggetto_chiamato, mettiamo sia di tipo Course)
			#				self sarà di tipo User
			#
			#		 Ciò mi permette di vedere l'evento lanciato come <oggetto_chiamante> <callback> <oggetto_chiamato>
			#			(o viceversa); esempio:
			#
			#			User#<User.id> REMOVED from Course#<Course.id>
			#
			#		 che è il modo in cui ho deciso di implementare il log nell'Orbserver.
			#
			#		 Rimane comunque il fatto che non capisco in base a cosa Rails passi un oggetto del modello
			#		 alle callback delle associazioni (esempio lampante CourseUser: l'inserimento di un'associazione
			#		 lancia una CourseUser.instance.after_create(CourseUser.instance), l'eliminazione una
			#		 Course.instance.after_remove(User.instance)... vai a capì!
			#
			self.class_eval <<-"end_eval"
				protected
				def notify_#{association_initials}_#{callback}(ass_obj)
					@associated_object = ass_obj
					notify :#{association_initials}_#{callback}
				end
			end_eval
		end

	end

	# Accetta l'hash dell'argomento options con la callback e lo restituisce con il valore per la callback
	# di notifica all'Observer al suo interno.
	#
	def observed_callbacks_hash(callback_options, association_initials)

		return_hash = {}

		callback_options.each { |callback, value|
			notifing = :"notify_#{association_initials}_#{callback}"
			return_hash[callback] = 
				if value.is_a? Array
					value.push(notifing) unless value.include?(notifing)
				elsif value
					[value, notifing]
				else
					notifing
				end
		}
		return_hash
	end
			
end
