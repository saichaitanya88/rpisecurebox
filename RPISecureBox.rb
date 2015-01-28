require './SecureBox.rb'
require './TRPISecureAPI.rb'
# 400 - KEYPASS_SUCCESS
# 500 - KEYPASS_FAIL
# 600 - DOOR_OPEN
# 700 - NOTIFY

class RPISecureBox
	def initialize
		@secure_box = SecureBox.new
		@api = TRPISecureAPI.new
	end

	def process_pin(pin)
		# takes key press
		# asks rpiSecureAPI.rb to provide credential
		if (pin.to_s.length > 0)
			if (@api.validate_pin(pin))
				keypass_success()
			else
				keypass_fail()
			end
		else
			return false
		end
	end

	def process_event(event)
		if (event == 600)
			door_open
		end
	end

	private

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