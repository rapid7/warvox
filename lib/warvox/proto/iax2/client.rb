# -*- coding: binary -*-
require 'warvox/proto/iax2/constants'
require 'warvox/proto/iax2/codecs'
require 'warvox/proto/iax2/call'

require 'rex/socket'
require 'thread'
require 'digest/md5'
require 'timeout'

module WarVOX
module Proto
module IAX2
class Client

  attr_accessor :caller_number, :caller_name, :server_host, :server_port
  attr_accessor :username, :password, :sendkeys
  attr_accessor :sock, :monitor_thread, :sendkeys_thread, :mutex
  attr_accessor :src_call_idx
  attr_accessor :debugging
  attr_accessor :calls

  def initialize(uopts={})
    opts = {
      :caller_number => '15555555555',
      :caller_name   => '',
      :server_port   => IAX2_DEFAULT_PORT,
      :context       => { }
    }.merge(uopts)

    self.caller_name   = opts[:caller_name]
    self.caller_number = opts[:caller_number]
    self.server_host   = opts[:server_host]
    self.server_port   = opts[:server_port]
    self.username      = opts[:username]
    self.password      = opts[:password]
    self.debugging     = opts[:debugging]

    if opts[:sendkeys]
      self.sendkeys = opts[:sendkeys].unpack("C*").pack("C*")
    end

    self.sock = Rex::Socket::Udp.create(
      'PeerHost' => self.server_host,
      'PeerPort' => self.server_port,
      'Context'  => opts[:context]
    )

    self.monitor_thread = ::Thread.new { monitor_socket }
    self.mutex = ::Mutex.new
    self.src_call_idx = 0
    self.calls = {}
  end

  def shutdown
    self.monitor_thread.kill rescue nil
    if self.sendkeys_thread
      self.sendkeys_thread.kill rescue nil
    end
  end

  def create_call
    cid  = allocate_call_id()
    self.calls[ cid ] = IAX2::Call.new(self, cid)
  end

  #
  # Transport
  #

  def monitor_socket
    while true
      begin
        pkt, src = self.sock.recvfrom(65535)
        next if not pkt

        # Find the matching call object
        mcall = matching_call(pkt)
        next if not mcall

        if (pkt[0,1].unpack("C")[0] & 0x80) != 0
          prestate = mcall.state
          mcall.handle_control(pkt)

          # Start the sendkeys thread when the call is answered
          if mcall.state != prestate && mcall.state == :answered &&
             self.sendkeys && ! self.sendkeys_thread
            self.sendkeys_thread = Thread.new { sendkeys_runner(mcall) }
          end
        else
          # Dispatch the buffer via the call handler
          mcall.handle_audio(pkt)
        end
      rescue ::Exception => e
        dprint("monitor_socket: #{e.class} #{e} #{e.backtrace}")
        break
      end
    end
    self.sock.close rescue nil
  end

  def matching_call(pkt)
    return unless pkt && pkt.length > 4
    src_call = pkt[0,2].unpack('n')[0]
    dst_call = nil

    if (src_call & 0x8000 != 0)
      dst_call = pkt[2,2].unpack('n')[0]
      dst_call ^= 0x8000 if (dst_call & 0x8000 != 0)
    end

    src_call ^= 0x8000 if (src_call & 0x8000 != 0)

    # Find a matching call in our list
    mcall = self.calls.values.select {|x| x.dcall == src_call or (dst_call and x.scall == dst_call) }.first
    if not mcall
      dprint("Packet received for non-existent call #{[src_call, dst_call].inspect}  vs #{self.calls.values.map{|x| [x.dcall, x.scall]}.inspect}")
      return
    end
    mcall
  end

  def sendkeys_runner(call)
    begin
    self.sendkeys.each_char do |c|
      case c
      when ','
        dprint("#{Thread.current} Sleeping 1s...")
        sleep(1.0)
      when /^[0-9\#\*]$/
        dprint("#{Thread.current} Sending key #{c}")
        send_dtmf(call, c, :begin)
        sleep(0.3)
        send_dtmf(call, c, :end)
        sleep(0.3)
      else
        dprint("#{Thread.current} Unknown sendkey parameter: #{c}")
      end
    end
  rescue ::Exception => e
    dprint("Error in sendkeys: #{e.class} #{e} #{e.backtrace}")
  end
  end

  def allocate_call_id
    (self.src_call_idx += 1) & 0x7fff
  end

  def dprint(msg)
    return if not self.debugging
    $stderr.puts "[#{Time.now.to_s}] #{msg}"
  end

  def send_data(call, data, inc_seq = true )
    self.mutex.synchronize do
      r = self.sock.sendto(data, self.server_host, self.server_port, 0)
      if inc_seq
        call.oseq = (call.oseq + 1) & 0xff
      end
      r
    end
  end

  def send_ack(call)
    data =	[ IAX_SUBTYPE_ACK ].pack('C')
    send_data( call, create_pkt( call.scall, call.dcall, call.timestamp, call.oseq, call.iseq, IAX_TYPE_IAX, data ), false )
  end

  def send_pong(call, stamp)
    data =	[ IAX_SUBTYPE_PONG ].pack('C')
    send_data( call, create_pkt( call.scall, call.dcall, stamp, call.oseq, call.iseq, IAX_TYPE_IAX, data ) )
  end

  def send_lagrp(call, stamp)
    data =	[ IAX_SUBTYPE_LAGRP ].pack('C')
    send_data( call, create_pkt( call.scall, call.dcall, stamp, call.oseq, call.iseq, IAX_TYPE_IAX, data ) )
  end

  def send_invalid(call)
    data =	[ IAX_SUBTYPE_INVAL ].pack('C')
    send_data( call, create_pkt( call.scall, call.dcall, call.timestamp, call.oseq, call.iseq, IAX_TYPE_IAX, data ) )
  end

  def send_hangup(call)
    data =	[ IAX_SUBTYPE_HANGUP ].pack('C')
    send_data( call, create_pkt( call.scall, call.dcall, call.timestamp, call.oseq, call.iseq, IAX_TYPE_IAX, data ) )
  end

  def send_voice(call, audio)
    # TODO: Replace with the server-selected codec
    data = [IAX_CODEC_G711_MULAW].pack("C") + audio
    send_data( call, create_pkt( call.scall, call.dcall, call.timestamp, call.oseq, call.iseq, IAX_TYPE_VOICE, data ) )
  end

  def send_dtmf(call, code, action)
    itype = (action == :begin) ? IAX_TYPE_DTMF_BEGIN : IAX_TYPE_DTMF_END
    send_data( call, create_pkt( call.scall, call.dcall, call.timestamp, call.oseq, call.iseq, itype, code ) )
  end

  def send_new(call, number)
    data = [ IAX_SUBTYPE_NEW ].pack('C')

    cid = call.caller_number || self.caller_number
    cid = number if cid == 'SELF'
    data << create_ie(IAX_IE_PROTO_VERSION, [2].pack("n") )
    data << create_ie(IAX_IE_CALLING_NUMBER, cid )
    data << create_ie(IAX_IE_CALLING_NAME, call.caller_name || self.caller_name)
    data << create_ie(IAX_IE_CALLING_PRESENTATION, [1].pack("C") )
    data << create_ie(IAX_IE_CALLING_TYPE_NUMBER, [0].pack("C") )
    data << create_ie(IAX_IE_CALLING_TRANSIT_NETWORK_SELECT, [0].pack("n") )
    data << create_ie(IAX_IE_DESIRED_CODEC, [IAX_CODEC_G711_MULAW].pack("N") )
    data << create_ie(IAX_IE_ACTUAL_CODECS, [IAX_SUPPORTED_CODECS].pack("N") )
    data << create_ie(IAX_IE_USERNAME, self.username) if self.username
    data << create_ie(IAX_IE_CALLED_NUMBER, number)
    data << create_ie(IAX_IE_ORIGINAL_DID, number)
    data << create_ie(IAX_IE_CPE_ADSI_CAP, [0].pack("n"))
    data << create_ie(IAX_IE_CALL_TOKEN, call.call_token)
    data << create_ie(IAX_IE_FIRMWARE_BLOCK, IAX_VENDOR_STRING)

    send_data( call, create_pkt( call.scall, call.dcall, call.timestamp, call.oseq, call.iseq, IAX_TYPE_IAX, data ) )
  end

  def send_authrep_chall_response(call, chall)
    data =
      [ IAX_SUBTYPE_AUTHREP ].pack('C') +
      create_ie(IAX_IE_CHALLENGE_RESP, ::Digest::MD5.hexdigest( chall + self.password ))

    send_data( call, create_pkt( call.scall, call.dcall, call.timestamp, call.oseq, call.iseq, IAX_TYPE_IAX, data ) )
  end

  def send_regreq(call)
    data = [ IAX_SUBTYPE_REGREQ ].pack('C')
    data << create_ie(IAX_IE_USERNAME, self.username) if self.username
    data << create_ie(IAX_IE_REG_REFRESH, [IAX_DEFAULT_REG_REFRESH].pack('n'))

    send_data( call, create_pkt( call.scall, call.dcall, call.timestamp, call.oseq, call.iseq, IAX_TYPE_IAX, data ) )
  end

  def send_regreq_chall_response(call, chall)
    data =
      [ IAX_SUBTYPE_REGREQ ].pack('C') +
      create_ie(IAX_IE_USERNAME, self.username) +
      create_ie(IAX_IE_CHALLENGE_RESP, ::Digest::MD5.hexdigest( chall + self.password )) +
      create_ie(IAX_IE_REG_REFRESH, [IAX_DEFAULT_REG_REFRESH].pack('n'))

    send_data( call, create_pkt( call.scall, call.dcall, call.timestamp, call.oseq, call.iseq, IAX_TYPE_IAX, data ) )
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

end
end
end
end
