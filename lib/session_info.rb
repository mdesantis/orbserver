# SessionInfo: sfrutta le variabili thread-locali (variabili assegnabili ad un thread)
# per passare informazioni che è utile condividere (come, per esempio, le informazioni
# di sessione). Questo modello è incluso da Orbserver e da ActionController::Base, di
# modo che l'Orbserver possa venire a conoscenza di variabili che gli sono utili per
# loggare.
#
# Note:
#	* Thread.current: ritorna il thread in esecuzione al momento
#	* Getter e Setter: la classe Orbserver include il Getter, mentre ActionController::Base
#		il Setter; questo perché vogliamo che sia esclusivamente ActionController::Base a 
#		settare session, e solamente Orbserver a leggerlo.
#
module SessionInfo

	# Getter	
	module Getter
		# Note:
		# 	1. Ritorna la variabile thread-locale :user, se esiste, altimenti un hash vuoto
		#		(così non crashano le chiamate session_info[:key], che sono comode da scrivere)
		def session_info
			Thread.current[:session_info] ||= {} # 1.
		end
	end
	
	# Setter
	module Setter
		# Note:
		# 	1. Assegna una variabile thread-locale di nome :session_info con il valore definito nella classe chiamante
		def self.session_info=(session_info)
			Thread.current[:session_info] = session_info # 1.
		end
	end

end
