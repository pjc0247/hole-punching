require 'eventmachine'
load 'protocol.rb'

PORT = 9916

class Client < EM::Connection
	include EM::P::ObjectProtocol

	def post_init
		set_sock_opt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
		
		puts "connected "
	end
	def unbind
		puts "disconnected"
	end

	def receive_object(obj)
		case obj["type"]
			when SET_ID
				@id = obj["id"]
				puts "id -> #{@id}"
			when SET_PEER
				@peer = obj["id"]
				puts "peer -> #{@peer}"
		end
	end
end

EventMachine.run do
	EventMachine.connect("127.0.0.1", PORT, Client)
end
