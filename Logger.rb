class Logger

	def self.info
		return 'info'
	end

	def self.warning
		return 'warning'
	end

	def self.details
		return 'details'
	end

	def self.log
		return 'log'
	end

	def self.error
		return 'error'
	end

	def self.mode
		@debug = true
	end

	def self.print (message, priority)
		if !mode
			return nil
		end

		if (priority == info)
			puts "#{message}".blue
		elsif (priority == warning)
			puts "#{message}".yellow
		elsif (priority == error)
			puts "#{message}".red
		elsif (priority == details)
			puts "#{message}".cyan
		elsif (priority == log)
			puts "#{message}".light_black
		end
	end

end