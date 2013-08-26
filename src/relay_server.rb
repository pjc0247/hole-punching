require 'eventmachine'
require 'thread'
load 'protocol.rb'
load 'methods.rb'

PORT = 9916

class RelayServer < EM::Connection
	include EM::P::ObjectProtocol

	attr_reader :alive, :id, :avaliable
	attr_accessor :peer

	@@idx = 0
	@@clients = Hash.new
	@@not_paired = Array.new
	
	def post_init
		@id = @@idx
		@@idx += 1
		@@clients[@id] = self
		@alive = true
		@avaliavble = nil

		set_sock_opt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

		puts "new connection.. #{@id}"

		packet = Hash.new
		packet["type"] = SET_ID
		packet["id"] = @id
		send_object packet


		if @@not_paired.count > 0
			@peer = @@not_paired.first
			@peer.peer = self
			@@not_paired.delete @peer

			packet["type"] = SET_PEER
			packet["id"] = @id
			@peer.send_object packet

			packet["id"] = @peer.id
			send_object packet

			packet["type"] = OPEN_SERVER
			send_object packet
		else
			@@not_paired.push self
		end
	end
	def unbind
		@@clients.delete self
		@alive = false

		puts "lost connection.. #{@id}"
	end

	def receive_object(obj)
		if obj["type"] == DUMMY
		elsif obj["type"] == SERVER_READY
			begin
				c = TCPSocket.new "127.0.0.1", PORT+1
				c.close

				@avaliable = true

				packet = Hash.new
				packet["type"] = SET_METHOD
				packet["method"] = SERVER
				send_object packet

				packet["method"] = CLIENT
				@peer.send_object packet
			rescue
				@avaliable = false

				packet = Hash.new
				packet["type"] = CLOSE_SERVER
				send_object packet

				if @peer.avaliable == nil
					packet["type"] = OPEN_SERVER
					@peer.send_object packet
				elsif @peer.avaliable == false
					packet["type"] = SET_METHOD
					packet["method"] = RELAY
					send_object packet

					packet["type"] = SET_METHOD
					packet["method"] = RELAY
					@peer.send_object packet
				end
			end
		else		
			@@clients[obj["dst"]].send_object obj
		end
	end
end

EventMachine.run do
	EventMachine.start_server("0.0.0.0", PORT, RelayServer)
end
