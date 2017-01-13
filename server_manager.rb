print "Requiring Libraries ... "
t = Time.now
require "socket"
require "open3"

#require 'pry'
#require "paint"
require "tty-spinner"

puts "Done! [#{Time.now - t}]"

class ServerManager

  SERVER_RX = /^Server\sIP\:\s+([\d\.]+\:\d+)$/
  STATUS_RX = /^Status:\s+(OFFLINE|ONLINE)$/
  PORT_RX = /^>\s([\w\/]+)\s+\w+\s+(\d+)/

  ANSI_RX = /\e\[(\d+)m/

  TELNET_RETRIES = 100
  REPL_BANNER = """
  Status: %s
  IP    : %s
  Ports :
  """

  def initialize(script_name,telnet_password)
    @server_script = File.expand_path("~/" + script_name)
    @telnet_password = telnet_password
    @server_status = parse_server_details()
  end

  def monitor()
    loop do
      @server_status = parse_server_details()
      if @server_status[:status] == "OFFLINE" then
        spin = TTY::Spinner.new("[:spinner] Starting Server ...")
        spin.auto_spin
        res = `#{@server_script} start`
        if res.index("OK") then
          spin.success("Done!")
        else
          spin.error("Error!")
        end
      end
      spin = TTY::Spinner.new("[:spinner] Waiting for telnet on 8081 ...")
      spin.auto_spin
      retries = TELNET_RETRIES
      until retries == 0 do
        retries -= 1
        sleep 0.8
        begin
          sock = TCPSocket.new "127.0.0.1",8081
        rescue => e
          # puts e.inspect
          next
        end
        if sock.gets == "Please enter password:\r\n" then
          spin.success("Online!")
        else
          spin.error("ERROR")
        end
        sock.close
        break
      end

      if retries == 0
        spin.error("Error")
        puts "No Connection to telnet Server established. Retrying"
        next
      end

      sock = TCPSocket.new "127.0.0.1", 8081
      sock.gets
      sock.puts @telnet_password

      loop do
        # evtl user input lesen
        begin
          cmd = STDIN.read_nonblock(4096)
        rescue IO::WaitReadable
          cmd = nil
        end
        if cmd
          case cmd
          when /^server\s+(.+)$/
            server_command = cmd.match(/(s|server)\s+(.+)$/)[2]
            puts "Executing : " + server_command
            print "Command: "
            sock.puts server_command
          when /^(q|quit)/
            puts "Quitting"
            return
          when /^(r|restart)/
            #restart
            puts "Restarting Server"
            spin = TTY::Spinner.new("[:spinner] Stopping Server ...")
            spin.auto_spin
            res = `#{@server_script} stop`
            if res.lines.last =~ /OK/
              spin.success("Done!")
              break
            else
              spin.error("Error")
              return
            end
          else
            puts "Unknown Command: " + cmd
          end
        end

        # evtl telnet output lesen
        begin
          log = sock.read_nonblock(4096)
        rescue IO::WaitReadable
          retry if IO.select([sock],nil,nil,1)
          log = nil
        rescue IO::EOFError
          puts "Telnet Closed!"
          break
        end
        if log
          if log =~ /^\s*$/
            puts "\r" + (" " * 9)
          else
            puts "\r" + log
          end
          print "Command: "
        end
      end
      #break
    end
  end
private
  def print_banner()
    printf REPL_BANNER%[@server_status[:status][0],@server_status[:ip]]
    @server_status[:ports].each{|pair| puts "  %-10s: %s"%pair}
    puts ""
  end

  def parse_server_details()
    details = `#{@server_script + " details"}`
    details.gsub!(ANSI_RX, '')
    ret = {}
    ret[:ip] = details.match(SERVER_RX)[1]
    ret[:status] = details.scan(STATUS_RX).flatten[0]
    ret[:ports] = details.scan(PORT_RX).to_h
    return ret
  end
end
