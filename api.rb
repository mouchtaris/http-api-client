# frozen_string_literal: true
require 'bundler/setup'
require 'uri'
require 'net/http'
require 'logger'
require 'hashie'
require 'json'
require 'yaml'

module HttpClient
  def info(*args)
    @logger.info(*args)
  end

  def open_http(url)
    info "Connecting to #{url}"
    Net::HTTP.new(url.host, url.port).tap do |http|
      if url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      yield http
    end
  end

  def postprocess_response(response)
    @response = response
    case response
    when Net::HTTPSuccess
      if response.content_type.casecmp('application/json') == 0
        json = JSON.parse(@response.body)
        @body = case json
                when Array then json.map(&Hashie::Mash.method(:new))
                when Hash then Hashie::Mash.new(json)
                end
      else
        @body = @response.body
      end
    else
      @body = nil
    end
  end

  def log_http_msg(headline, msg, pref)
    info "\n  #{headline}\n" \
          "#{msg.each_header.to_a.map { |k, v| "  #{pref} ~ #{k}: #{v}" }.join("\n")}\n" \
          "#{msg.body.each_line.map { |l| "  #{pref} | #{l}" }.join("\n")}"
  end

  def perform_request(request)
    open_http(request.uri) do |http|
      log_http_msg "#{request.method} #{request.uri.path}", request, '>>>'
      http.request(request)
          .tap { |response| log_http_msg "#{response.code} #{response.msg}", response, '<<<' }
          .tap(&method(:postprocess_response))
    end
  end

  def request_with_body(request, body)
    request
      .tap { |rq| rq.body = body }
  end

  def request_with_headers(request, headers)
    request
      .tap { |rq| rq.initialize_http_header(headers) }
  end

  def request_with_params(request, params)
    if params.nil?
      request
    elsif params.key?(:json)
      [request]
        .map { |rq| rq.content_type = 'application/json' }
        .map { |_rq| request_with_body(request, params[:json].to_json) }
        .first
    else
      raise ArgumentError
    end
  end

  def make_request(verb, path, headers, params)
    url = @url + path
    request = [Net::HTTP.const_get(verb).new(url)]
              .map { |rq| request_with_headers(rq, headers) }
              .map { |rq| request_with_params(rq, params) }
              .tap { |rq,| rq['Host'] = url.host }
              .first
    perform_request(request)
  end

  def post(path, params = nil, headers = {})
    make_request(:Post, path, headers, json: params)
  end

  def get(path, params = nil, headers = {})
    make_request(:Get, path, headers, json: params)
  end

  def patch(path, params = nil, headers = {})
    make_request(:Patch, path, headers, json: params)
  end

  def put(path, params = nil, headers = {})
    make_request(:Put, path, headers, json: params)
  end

  def make_auth_request(verb, path, params, headers)
    if @login
      auth = { 'Authorization' => "#{@login.token_type} #{@login.access_token}" }
      method(verb).call(path, params, auth.merge(headers))
    else
      raise 'Need to login first'
    end
  end

  def auth_post(path, params = nil, headers = {})
    make_auth_request(:post, path, params, headers)
  end

  def auth_get(path, params = nil, headers = {})
    make_auth_request(:get, path, params, headers)
  end

  def auth_patch(path, params = nil, headers = {})
    make_auth_request(:patch, path, params, headers)
  end

  def auth_put(path, params = nil, headers = {})
    make_auth_request(:put, path, params, headers)
  end
end

module MemoisingActions
  module ClassExtension
    def self.action(name, &block)
      varname = name.to_s.gsub(/^(post|get|patch|put|delete|head|options)_/, '')
      define_method(name) do
        instance_exec(&block)
        instance_variable_set(:"@#{varname}", @body)
      end
    end
  end

  class << self
    def included(target)
      target.singleton_class.class_exec do
        include ClassExtension
      end
    end
  end

end

#
# Your service API Client here
#
class ServiceApiClient
  include HttpClient
  include MemoisingActions

  def initialize(url, email, password, type)
    @url = URI.parse(url)
    @email = email
    @password = password
    @logger = ::Logger.new(STDERR)
                      .tap { |l| l.progname = @url.to_s }
    @type = type
  end
  attr_reader :email
  attr_reader :password
  attr_reader :type

  def signup
    post '/v1/users',
      address: {
        city: nil,
        line1: nil,
        line2: nil,
        zipcode: 55555,
        state: nil
      },
      email: email,
      full_name: "name for #{email}",
      password: password
  end

  action :login do
    # For example .. 
    post '/oauth/token',
         grant_type: 'password',
         username: email,
         password: password
  end

  action :get_me do
    auth_get '/v1/me'
  end

  action :post_message do
    auth_post '/v1/message',
              to: :you,
              type: 'sms',
              content: 'hello'
  end
end
