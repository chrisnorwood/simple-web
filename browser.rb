require 'socket'
require 'json'

class Browser
  attr_reader :host, :port, :path

  def initialize
    @host = 'localhost'
    @port = 8080
    @path = '/thanks.html'
    @request_type = prompt_user
    @request = ""
  end

  def run
    case @request_type
    when "POST"
      name   = prompt_name
      email  = prompt_email
      params = {'viking' => {'name'=>name, 'email'=>email}}.to_json

      @request = "POST #{path} HTTP/1.0\r\n" +
                 "User-Agent: RubyBrowser/1.0\r\n" +
                 "Content-Type: application/x-www-form-urlencoded\r\n" +
                 "Content-Length: #{params.length}\r\n\r\n" +
                 "#{params}"
    when "GET"
      @request = "GET #{path} HTTP/1.0\r\n\r\n" 
    end

    socket = TCPSocket.open(@host,@port)
    socket.print(@request)
    response = socket.read

    headers,body =  response.split("\r\n\r\n", 2)
    print body
  end

  private

  def prompt_user
    puts "What type of request would you like to make?"
    input = gets.chomp.downcase

    case input
    when "get" then "GET"
    when "post" then "POST"
    else 
      puts "Please enter 'get' or 'post'."
      puts "\n"
      prompt_user
    end
  end

  def prompt_name
    puts "What is your name?"
    gets.chomp
  end

  def prompt_email
    puts "What is your email?"
    gets.chomp
  end
end

Browser.new.run