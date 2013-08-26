require 'eventmachine'
require 'thread'
load 'protocol.rb'

PORT = 9916

class RelayServer < EM::Connection
	include EM::P::ObjectProtocol

	attr_reader :alive, :id
	attr_accessor :peer

	@@idx = 0
	@@clients = Hash.new
	@@not_paired = Array.new
	
	def post_init
		@id = @@idx
		@@idx += 1
		@@clients[@id] = self
		@alive = true

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
		@@clients[obj["dst"]].send_object obj
	end
end

EventMachine.run do
	EventMachine.start_server("0.0.0.0", PORT, RelayServer)
end
