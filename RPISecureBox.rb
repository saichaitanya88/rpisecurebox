require './SecureBox.rb'

# 400 - KEYPASS_SUCCESS
# 500 - KEYPASS_FAIL
# 600 - DOOR_OPEN
# 700 - NOTIFY

class RPISecureBox
	def initialize
		@secure_box = SecureBox.new
	end

	def keypass_success
		@secure_box.process_event(400)
	end

	def keypass_fail
		@secure_box.process_event(500)
	end

	def door_open
		@secure_box.process_event(600)
	end
	
	def secure_box
		return @secure_box
	end
end