class Path
	def initialize(starting_state, event, end_state)
		@starting_state = starting_state
		@event = event
		@end_state = end_state
	end

	def starting_state
		return @starting_state
	end

	def event
		return @event
	end

	def end_state
		return @end_state
	end
end