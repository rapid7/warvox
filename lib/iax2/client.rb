require 'iax2/constants'
require 'iax2/codecs'

require 'socket'
require 'thread'
require 'digest/md5'
require 'timeout'

module IAX2
class Client

	attr_accessor :caller_number, :caller_name, :server_host, :server_port
	attr_accessor :username, :password
	attr_accessor :sock, :monitor
	attr_accessor :itime
	attr_accessor :q_control, :q_audio
	attr_accessor :state
	attr_accessor :src_call_idx
	attr_accessor :oseq, :iseq
	attr_accessor :scall, :dcall
	attr_accessor :codec

	def initialize(opts={})
		{
			:caller_number => '15555555555',
			:caller_name   => 'Ruby IAX2',
			:server_port   => IAX2_DEFAULT_PORT
		}.merge(opts).each_pair do |k,v|
			if self.respond_to?("#{k}=")
				self.send("#{k}=", v)
			end
		end

		self.sock = ::UDPSocket.new
		self.sock.connect(self.server_host, self.server_port)
		self.itime = ::Time.now
		self.q_audio   = []
		self.q_control = ::Queue.new
		self.monitor   = ::Thread.new { monitor_socket }

		self.src_call_idx = 0
		reset_call
	end

#
# Client APIS
#

	def wait_for(*stypes)
		begin
			::Timeout.timeout( IAX_DEFAULT_TIMEOUT ) do
				while (res = self.q_control.pop )
					if stypes.include?(res[1])
						return res
					end
				end
			end
		rescue ::Timeout::Error
			return nil
		end
	end

	def register
		self.reset_call

		self.send_regreq
		dprint("Registering with Call ID #{self.scall}...")
		res = wait_for( IAX_SUBTYPE_REGAUTH )
		return if not res

		chall = nil
		if res[2][14] == "\x00\x03" and res[1][15]
			self.dcall = res[0][1]
			chall = res[2][15]
			dprint("REGAUTH: #{res[2].inspect}")
		end

		self.send_regreq_chall_response(chall)
		res = wait_for( IAX_SUBTYPE_REGACK )
		return if not res
		dprint("REGACK: #{res[2].inspect}")

		self.state = :registered

		true
	end


	def dial(number)
		self.reset_call

		dprint("Dialing Call ID #{self.scall}...")

		self.send_new(number)
		res = wait_for(IAX_SUBTYPE_AUTHREQ)
		return if not res

		chall = nil
		if res[2][14] == "\x00\x03" and res[1][15]
			self.dcall = res[0][1]
			chall = res[2][15]
			dprint("AUTHREQ: #{res[2].inspect}")
		end

		self.send_authrep_chall_response(chall)
		res = wait_for( IAX_SUBTYPE_ACCEPT)
		return if not res

		self.codec = res[2][IAX_IE_DESIRED_CODEC].unpack("N")[0]
		self.state = :ringing
		self.send_ack

		dprint("ACCEPT: CODEC=#{self.codec}")

		true
	end


#
# Transport
#


	def reset_call
		self.oseq  = 0
		self.iseq  = 0
		self.scall = allocate_call_id
		self.dcall = 0
		self.state = :none
	end

	def monitor_socket
		while true
			begin
				pkt, src = self.sock.recvfrom(65535)
				if pkt
					if (pkt[0,1].unpack("C")[0] & 0x80) != 0
						process_control(pkt)
					else
						# Mini-packets are just for audio data, add to the queue
						if self.state == :answered
							# dprint("Processing VOICE audio packet (#{pkt.length} bytes)... ")
							self.q_audio.push(pkt)
						else
							# dprint("Processing RINGER audio packet (#{pkt.length} bytes)... ")
						end
					end
				end
			rescue ::Exception => e
				dprint("monitor_socket: #{e.class} #{e} #{e.backtrace}")
				break
			end
		end
		self.sock.close rescue nil
	end

	def allocate_call_id
		res = ( self.src_call_idx += 1 )
		if ( res > 0x8000 )
			self.src_call_idx = 1
			res = 1
		end
		res
	end

	def timestamp
		(( ::Time.now - self.itime) * 1000.0 ).to_i & 0xffffffff
	end

	def process_control(pkt)
		src_call, dst_call, tstamp, out_seq, inp_seq, itype = pkt.unpack('nnNCCC')

		# Scrub the high bits out of the call IDs
		src_call ^= 0x8000 if (src_call & 0x8000 != 0)
		dst_call ^= 0x8000 if (dst_call & 0x8000 != 0)

		phdr = [ src_call, dst_call, tstamp, out_seq, inp_seq, itype ]

		info  = nil
		stype = pkt[11,1].unpack("C")[0]
		info  = process_elements(pkt, 12) if [IAX_TYPE_IAX, IAX_TYPE_CONTROL].include?(itype)

		# Handle REGACK even for other calls

		if dst_call != self.scall
			dprint("Incoming packet to inactive call: #{dst_call} vs #{self.scall}: #{phdr.inspect} #{stype.inspect} #{info.inspect}")
			return
		end

		# Increment the received sequence number
		self.iseq = (self.iseq + 1) & 0xff

		case itype
		when IAX_TYPE_CONTROL
			case stype
			when IAX_SUBTYPE_ANSWER
				dprint("ANSWERED")
				self.state = :answered if self.state == :ringing
				self.send_ack
			when 255
				dprint("STOP SOUNDS")
			end
		when IAX_TYPE_IAX
			dprint( ["RECV", phdr, stype, info].inspect )
			case stype
			when IAX_SUBTYPE_HANGUP
				dprint("HANGUP: #{self.q_audio.length} voice frames received")
				self.state = :hangup
				self.send_ack
			when IAX_SUBTYPE_LAGRQ
				self.send_ack
			when IAX_SUBTYPE_ACK
				# Nothing to do here
			when IAX_SUBTYPE_PING
				# Reply with PONG
			else
				q_control.push( [phdr, stype, info ] )
			end
		when IAX_TYPE_VOICE
			v_codec = stype

			if self.state == :answered
				# dprint("Processing [FULL] VOICE audio packet (#{pkt.length} bytes)... ")
				self.q_audio.push(pkt)
			else
				# dprint("Processing [FULL] RINGER audio packet (#{pkt.length} bytes)... ")
			end
			self.send_ack

		when nil
			dprint("Invalid control packet: #{pkt.unpack("H*")[0]}")
		end
	end

	def process_elements(data,off=0)
		res = {}
		while( off < data.length )
			ie_type = data[off    ,1].unpack("C")[0]
			ie_len  = data[off + 1,2].unpack("C")[0]
			res[ie_type] = data[off + 2, ie_len]
			off += ie_len + 2
		end
		res
	end

	def dprint(msg)
		$stderr.puts "[#{Time.now.to_s}] #{msg}"
	end


	def send_data(data)
		r = self.sock.send(data, 0, self.server_host, self.server_port)
		self.oseq = (self.oseq + 1) & 0xff
		r
	end


	def send_ack
		data =	[ IAX_SUBTYPE_ACK ].pack('C')
		send_data( create_pkt( self.scall, self.dcall, self.timestamp, self.oseq, self.iseq, IAX_TYPE_IAX, data ) )
	end

	def send_new(number)
		data =
			[ IAX_SUBTYPE_NEW ].pack('C') +
			create_ie(IAX_IE_CALLING_NUMBER, self.caller_number ) +
			create_ie(IAX_IE_CALLING_NAME, self.caller_name) +
			create_ie(IAX_IE_DESIRED_CODEC, [IAX_RAW_CODECS].pack("N") ) +
			create_ie(IAX_IE_ACTUAL_CODECS, [IAX_RAW_CODECS].pack("N") ) +
			create_ie(IAX_IE_USERNAME, self.username) +
			create_ie(IAX_IE_CALLED_NUMBER, number) +
			create_ie(IAX_IE_ORIGINAL_DID, number)

		send_data( create_pkt( self.scall, self.dcall, self.timestamp, self.oseq, self.iseq, IAX_TYPE_IAX, data ) )
	end

	def send_authrep_chall_response(chall)
		data =
			[ IAX_SUBTYPE_AUTHREP ].pack('C') +
			create_ie(IAX_IE_CHALLENGE_RESP, ::Digest::MD5.hexdigest( chall + self.password ))

		send_data( create_pkt( self.scall, self.dcall, self.timestamp, self.oseq, self.iseq, IAX_TYPE_IAX, data ) )
	end

	def send_regreq
		data =
			[ IAX_SUBTYPE_REGREQ ].pack('C') +
			create_ie(IAX_IE_USERNAME, self.username) +
			create_ie(IAX_IE_REG_REFRESH, [IAX_DEFAULT_REG_REFRESH].pack('n'))

		send_data( create_pkt( self.scall, self.dcall, self.timestamp, self.oseq, self.iseq, IAX_TYPE_IAX, data ) )
	end

	def send_regreq_chall_response(chall)
		data =
			[ IAX_SUBTYPE_REGREQ ].pack('C') +
			create_ie(IAX_IE_USERNAME, self.username) +
			create_ie(IAX_IE_CHALLENGE_RESP, ::Digest::MD5.hexdigest( chall + self.password )) +
			create_ie(IAX_IE_REG_REFRESH, [IAX_DEFAULT_REG_REFRESH].pack('n'))

		send_data( create_pkt( self.scall, self.dcall, self.timestamp, self.oseq, self.iseq, IAX_TYPE_IAX, data ) )
	end

	def create_ie(ie_type, ie_data)
		[ie_type, ie_data.length].pack('CC') + ie_data
	end

	def create_pkt(src_call, dst_call, tstamp, out_seq, inp_seq, itype, data)
		[
			src_call | 0x8000,  # High bit indicates a full packet
			dst_call,
			tstamp,
			out_seq & 0xff,     # Sequence numbers wrap at 8-bits
			inp_seq & 0xff,     # Sequence numbers wrap at 8-bits
			itype
		].pack('nnNCCC') + data
	end


	#
	# Audio processing
	#
	def each_audio_frame(&block)
		self.q_audio.each do |pkt|
			buff = (pkt[0,1].unpack("C")[0] & 0x80 == 0) ? pkt[4,pkt.length-4] : pkt[12,pkt.length-12]
			rawa = decode_audio_frame(buff)
			block.call(rawa) if rawa
		end
	end

	def decode_audio_frame(buff)
		case self.codec
		when IAX_CODEC_MULAW_G711
			IAX2::Codecs::MuLaw.decode(buff)
		else
			dprint("UNKNOWN CODEC: #{self.codec.inspect}")
			buff
		end
	end

end
end

