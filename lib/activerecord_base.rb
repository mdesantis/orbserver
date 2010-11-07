# Definisco alcuni metodi utilizzati dall'Orbserver per loggare
class ActiveRecord::Base
	
	attr_reader :associated_object
	
	public
	# Identica alla attribute_for_inspect, solo ritorna i valori di tipo String nella propria
	# interezza, e non segati a 50 caratteri
	#
	def full_attribute_for_inspect(attr_name)
		value = read_attribute(attr_name)

		if value.is_a?(Date) || value.is_a?(Time)
			%("#{value.to_s(:db)}")
		else
			value.inspect
		end
	end
	
	# Metodo inspect che, invece di ritornare il valore dei tipi String troncato a 50 caratteri 
	# come la inspect originale di ActiveRecord::Base, ritorna l'intera stringa (in realtà non
	# cioè non compete al metodo stesso ma al metodo attribute_for_inspect, che viene però
	# richiamato da esso; questo metodo richiama invece full_attribute_for_inspect(name), definito
	# sopra, ed effettivamente si differenzia dalla inspect originale solamente in questo).
	#
	def full_inspect
		attributes_as_nice_string = self.class.column_names.collect { |name|
		if has_attribute?(name) || new_record?
			"#{name}: #{full_attribute_for_inspect(name)}"
		end
		}.compact.join(", ")
		"#<#{self.class} #{attributes_as_nice_string}>"
	end

	# Metodo inspect applicabile però solo ad oggetti che sono stati modificati; restituisce una inspect
	# solamente per i valori che sono stati cambiati. version: stabilisce se la inspect scriverà i valori
	# precedenti(:prev) o successivi(:succ) alla modifica.
	#
	# Lancia un'eccezione ArgumentError se viene passato un valore per version che sia diverso da :prev o :succ
	#
	def focused_to_changed_values_full_inspect(version)
		raise ArgumentError "L'argomento version accetta solo i valori :prev o :succ, mentre è stato inserito il valore #{version.inspect}" unless [:prev, :succ].include?(version)
		version = (version == :prev ? 0 : 1)
		if changed?
			attributes_as_nice_string = changed.collect { |name|
			if has_attribute?(name)
				"#{name}: #{changes[name][version].inspect}"
			end
			}.compact.join(", ")
			"#<#{self.class} #{attributes_as_nice_string}>"
		end
	end
	
end
