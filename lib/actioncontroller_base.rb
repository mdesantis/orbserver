# Faccio settare ActionController::Base le informazioni che saranno passate tramite il modulo SessionInfo
class ActionController::Base

	include SessionInfo::Setter
	
	before_filter :set_session_info
	
	protected
	
	# Modificare l'hash definito in questo metodo per definire i valori che il controller passerà all'orbserver
	def set_session_info
		SessionInfo::Setter.session_info = { :user_id => session[:user_id],  :request_ip => request.remote_ip }
	end

end
