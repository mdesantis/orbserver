# Classe utilizzata dall'Orbserver per loggare le callbacks dichiarate.
#
# == Definire il proprio Logger
#
# Nel caso si necessiti definire un proprio Logger, è possibile assegnarne direttamente
# un'istanza ad una costante di classe del proprio Orbserver nominata come #{OrbserverClassName}Logger;
# esso sarà utilizzato automaticamente dall'Orbserver. Esempio:
#
# 	class MyOrbserver < ActiveRecord::Orbserver
#
#		orbserve ActiveRecord::SessionStore::Session
#
#		class MyOrbserverLogger < ActiveSupport::OrbserverLogger
#	 
#			def hello
#				'hello!'
#			end
#
#		end
#
#		create_logger
#		puts self.logger.hello # stampa 'hello!'
#
# 	end
#
class ActiveSupport::OrbserverLogger < ActiveSupport::BufferedLogger

	# Note:
	#	1., 2. : hack per correggere un bug per cui, quando il log crea il file di log,
	#			 il primo record inserito sarà scritto alla fine della prima linea, che contiene
	#			 la notifica dell'avvenuta creazione del file, e non sulla seconda (motivo per
	#			 cui aggiungo un a capo nel log se il file non è ancora stato creato).
	def initialize(log, level = INFO)
		new_file = File.exist?(log) ? false : true # 1.
		super
		@log.write("\n") if new_file == true # 2.
	end

end
