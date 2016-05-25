require 'socket'
require 'uri'
require 'json'

WEB_ROOT = './public'
# map extensions to their content type
CONTENT_TYPE_MAPPING = {
  'html' => 'text/html'
}
# treat as binary data if content type cannot be found
DEFAULT_CONTENT_TYPE = 'application/octet-stream'

class Server
  def initialize
    @server = TCPServer.open(8080)
  end

  def run
    loop do
      socket  = @server.accept
      request = socket.recv(1024)
      
      request_header, request_body = request.split("\r\n\r\n", 2)
      request_type  = request_header.split(" ")[0]

      STDERR.puts request

      path = requested_file(request_header)
      path = File.join(path, 'index.html') if File.directory?(path)

      if File.exist?(path) && !File.directory?(path)
        File.open(path, "rb") do |file|
          socket.print "HTTP 1.1 200 OK\r\n" +
                       "Content-Type: #{content_type(file)}\r\n" +
                       "Content-Length: #{file.size}\r\n" +
                       "Connection: close \r\n"
          socket.print "\r\n"

          case request_type
          when "GET"
            # write contents of file to socket
            IO.copy_stream(file, socket)
          when "POST"
            # collect user parameters from POST request
            params = JSON.parse(request_body)
            user_data = "<li>#{params['viking']['name']}</li><li>#{params['viking']['email']}</li>"
            # collects contents of file and substitutes yield with posted parameters
            file = File.read(file).gsub("<%= yield %>", user_data)
            # write contents of file to socket
            socket.print file
          end
        end
      else
        message = "File not found\n"

        # respond with 404 error code
        socket.print "HTTP/1.1 404 Not Found\r\n" +
                     "Content-Type: text/plain\r\n" +
                     "Content-Length: #{message.size}\r\n" +
                     "Connection: close\r\n"
        socket.print "\r\n"

        socket.print message
      end

      socket.close
    end
  end

  private

    def content_type path
      ext = File.extname(path).split(".").last
      CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
    end

    def requested_file request_line
      request_uri = request_line.split(" ")[1]
      path        = URI.unescape(URI(request_uri).path)

      clean = []

      parts = path.split("/")

      parts.each do |part|
        next if part.empty? || part == "."
        part == '..' ? clean.pop : clean << part
      end

      File.join(WEB_ROOT, *clean)
    end
end

Server.new.run