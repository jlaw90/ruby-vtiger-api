require 'json'
require 'net/http'
require 'digest/md5'

class VTiger
  attr_reader :uri, :path, :username, :access_key, :debug

  def initialize(host, path, username, access_key, debug = false)
    @uri = URI.parse(host)
    @path = path
    @username = username
    @access_key = access_key
    @debug = debug

    @http = Net::HTTP.new(@uri.host, @uri.port)
  end

  def login
    token = challenge_token

    resp = request('login',{ username: @username, accessKey: Digest::MD5.hexdigest(token + @access_key)}, :post)

    @session_id = resp['sessionName']

    resp
  end

  # When a method that doesn't exist is called, do a REST request (magic)
  def method_missing(operation, *args, &block)
    require_login

    params = args.fetch(0, {}).merge(sessionName: @session_id)
    method = params.delete(:method) || :get
    request(operation, params, method)
  end

  # Private methods
  private
  def escape(obj)
    return URI::escape(JSON.generate(obj)) if obj.is_a? Hash
    URI::escape(obj)
  end

  def request(operation, params, method = :get)
    path = "#{@path}"
    params[:operation] = operation.to_s
    paramstring = params.map { |k, v| "#{escape(k.to_s)}=#{escape(v)}" }.join('&')

    path = "#{path}?#{paramstring}" if method == :get
    req = case method
            when :get then
              Net::HTTP::Get.new(path)
            when :post then
              Net::HTTP::Post.new(path)
            else
              raise "Invalid request method: #{method}"
          end
    req.body = paramstring if method == :post


    puts "#{method} #{path}#{req.body.eql?('')? '': "    data: #{req.body}"}" if @debug

    resp = @http.request(req)

    result = JSON.parse(resp.body)

    puts "response: #{resp.body}" if @debug

    raise "#{operation} request failed: #{result['error']['code']} #{result['error']['message']}" unless result['success']

    result['result']
  end

  def challenge_token_invalid?
    @challenge_token.nil? or Time.now >= @challenge_expire
  end

# Re-generate the challenge key if expired or non-existant
  def challenge_token
    return @challenge_token unless challenge_token_invalid?

    result = request('getchallenge', { username: @username })

    time = Time.at(result['serverTime'])
    diff = Time.now - time
    expires = Time.at(result['expireTime'])
    @challenge_expire = (expires + diff) - 20 # Take off 20 seconds to accomodate network lag
    @challenge_token = result['token']

    @challenge_token
  end

  def require_login
    login if challenge_token_invalid?
  end
end