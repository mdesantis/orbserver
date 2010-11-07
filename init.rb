# Carico i files richiesti dal plugin per funzionare
require 'associations_callbacks'
require 'orbserver'
require 'orbserver_logger'
require 'session_info'
require 'activerecord_base'
require 'actioncontroller_base'

# Commentare la seguente riga nel caso non si abbia intenzione di utilizzare l'orbserver di default (ApplicationOrbserver) e si preferisca definirne un altro
require 'application_orbserver'

# Inizializzo l'Orbserver
ApplicationOrbserver.instance
