# Orbserver di default. Modificarlo per adattarlo alle proprie esigenze
# (secondo le istruzioni contenute in ActiveRecord::Orbserver).
class ApplicationOrbserver < ActiveRecord::Orbserver

	orbserve ActiveRecord::SessionStore::Session
	create_logger
	
	# Callbacks che verranno loggate
	def after_create(obj)
		log_this(obj, :after_create)
	end
	
	def before_update(obj)
		log_this(obj, :before_update) if obj.changed?
	end
	
	def after_destroy(obj)
		log_this(obj, :after_destroy)
	end
	
	def hm_after_add(obj)
		associated_callbacks_log(obj, :after_add)
	end
	
	def hm_after_remove(obj)
		associated_callbacks_log(obj, :after_remove)
	end
	
	def habtm_after_add(obj)
		associated_callbacks_log(obj, :after_add)
	end
	
	def habtm_after_remove(obj)
		associated_callbacks_log(obj, :after_remove)
	end
	
end
