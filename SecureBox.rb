##
## Core functionality of the Secure Box
##
require './Path.rb'
require 'colorize'
require './Logger.rb'

class SecureBox
	# STATES
	# 100 - ARMED
	# 200 - DISARMED
	# 300 - SIREN
	# EVENTS
	# 400 - KEYPASS_SUCCESS
	# 500 - KEYPASS_FAIL
	# 600 - DOOR_OPEN
	# 700 - NOTIFY
	@@events = { 100 => 'ARMED', 200 => 'DISARMED', 300 => 'SIREN', 
				400 => 'KEYPASS_SUCCESS', 500 => 'KEYPASS_FAIL', 600 => 'DOOR_OPEN', 
				700 => 'NOTIFY' }
	
	@@beeps = { 100 => '', 200 => '', 300 => 'beep -f 1200 -r 5 -l 75', 
				400 => 'beep -f 261.6 -n -f 329.6 -n -f 392', 500 => 'beep -f 261.6 -n -f 311.1 -n -f 392', 600 => '', 
				700 => '' }

	@@state_paths = [ 	
						Path.new(100,400,200),
						Path.new(200,400,100),
						Path.new(200,500,200),
						Path.new(100,500,300),
						Path.new(100,600,100),
						Path.new(300,400,200)
					]

	@@seconds_to_check = 60

	def seconds_to_check
		# GET accessor for seconds_to_checkl
		return @@seconds_to_check
	end

	def state_paths
		# GET accessor for state_paths
		@@state_paths
	end

	def states
		# GET accessor for states
		return @@states
	end

	def events
		# GET accessor for events
		return @@events
	end

	def initialize
		# initializes the SecureBox
		@lock = Mutex.new
		@current_state = events[200]
		@invalid_keypass_counter = 0
		Logger.print("Initialized.", Logger.info)
		Logger.print("Current State is #{current_state}", Logger.details)
		beep(events.key("KEYPASS_SUCCESS"))
	end

	def current_state
		# GET accessor for current_state
		return @current_state
	end

	def process_event(event)
		# processes the event by picking the appropriate path based on the starting state, event and sets the current_state to end_state from the selected path
		Logger.print("Process_Event - #{events[event]}(#{event}) with Current_State - #{current_state}(#{events.key(current_state)})", Logger.log)
		path = @@state_paths.find { |p| p.event == event && p.starting_state == events.key(current_state) }
		if (path == nil)
			Logger.print("No path found for #{events[event]}(#{event}) with Current_State - #{current_state}(#{events.key(current_state)})", Logger.warning)
			return nil
		end
		previous_state = @current_state
		@current_state = events[path.end_state]
		initiate_trigger(event, @current_state, previous_state)
		Logger.print("Current State is #{@current_state}", Logger.details)
	end

	private

	def initiate_trigger(event, trigger_state, previous_state)
		# initiates triggers for each specific event. 
		# custom code goes here
		if event == events.key('DOOR_OPEN') and events.key(trigger_state) == events.key('ARMED')
			Logger.print("Event - #{events[event]}", Logger.log)
			Thread.new { trigger_door_open }
		elsif event == events.key('KEYPASS_FAIL') and events.key(trigger_state) == events.key('DISARMED')
			beep(events.key('KEYPASS_FAIL'))
			Logger.print("Event - #{events[event]}", Logger.log)
			Thread.new { trigger_keypass_fail_in_disarmed_state }
		elsif event == events.key('KEYPASS_FAIL') and events.key(previous_state) == events.key("ARMED")
			Logger.print("Event - #{events[event]}", Logger.log)
			Thread.new { trigger_siren_mode }
		end
	end

	def trigger_keypass_fail_in_disarmed_state
		Logger.print("Starting Thread: trigger_keypass_fail", Logger.info)
		siren = events.key('SIREN')
		@lock.synchronize {
			@invalid_keypass_counter = @invalid_keypass_counter + 1
			Logger.print("Incorrect Keycode - Attempt #{@invalid_keypass_counter.to_s}", Logger.warning)
			if (@invalid_keypass_counter > 5)
				beep(events.key('SIREN'))
				@current_state = events[siren]
				Thread.new { trigger_siren_mode }
				Logger.print("Current State is #{@current_state}", Logger.details)
			end
		}
		Logger.print("Stopping Thread: trigger_keypass_fail", Logger.info)
		Thread.kill
	end

	def trigger_door_open
		#start a timer, wait 60 seconds, change state to SIREN
		Logger.print("Starting Thread: trigger_door_open", Logger.info)
		disarmed = events.key('DISARMED')
		siren = events.key('SIREN')
		continue_check = true
		time_to_check_till = current_time_in_ms(60)
		pulse_counter = 0
		while (current_time_in_ms(0) < time_to_check_till) do
			sleep(1.0/5.0)
			@lock.synchronize {
				if (events.key(current_state) == disarmed)
					continue_check = false
				end
			} 
			if !continue_check
				break
			end
			pulse_counter = pulse_counter + 1
			if (pulse_counter % 20 == 0)
				Logger.print("#{current_state}(#{events.key(current_state)})", Logger.info)
			end
		end

		if continue_check
			@current_state = events[siren]
		end
		Logger.print("Stopping Thread: trigger_door_open", Logger.info)
		Logger.print("Current State is #{@current_state}", Logger.details)
		Thread.kill
	end

	def trigger_siren_mode
		Logger.print("Starting Thread: trigger_siren_mode", Logger.info)
		while (true) do
			if (events.key(current_state) == events.key("SIREN"))
				beep(events.key("SIREN"))
				sleep(5)
			else
				break
			end
		end
		Logger.print("Stopping Thread: trigger_siren_mode", Logger.info)
		Thread.kill
	end

	def current_time_in_ms(seconds_offset)
		# helper method to return current time in ms
		return ((Time.now + seconds_offset).to_f * 1000).to_i
	end

	def beep(event)
		system(@@beeps[event])
	end
end