require 'eventmachine'
load 'protocol.rb'
load 'methods.rb'

PORT = 9916

class Server < EM::Connection
	include EM::P::ObjectProtocol

	def post_init
		puts "con"
	end
	def unbind
		puts "discon"
	end

	def receive_object(obj)
		
	end
end

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
			when SET_METHOD
				@method = obj["method"]
				puts "method -> #{@method}"

				case @method
					when CLIENT
						# connect to obj["dst"]
						puts "connect to #{obj["dst"]}"
				end
			when OPEN_SERVER
				EventMachine.start_server("0.0.0.0", PORT+1, Server)

				packet = Hash.new
				packet["type"] = SERVER_READY
				send_object packet
			when CLOSE_SERVER
				
		end
	end
end

EventMachine.run do
	EventMachine.connect("127.0.0.1", PORT, Client)
end
