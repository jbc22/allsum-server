require 'rubygems'
require 'sinatra'
require 'datamapper'
require 'ssdeep'

VERSION = '0.1.0'

DataMapper::setup(:default, "mysql://root:@localhost/hashdb")
set :root, File.expand_path(File.join(File.dirname(__FILE__)))

module Allsum
  module Client
    module Models
      class Filename
        require 'dm-migrations'
        include DataMapper::Resource

        property :id,           Serial, :key => true
        property :filename,     Text, :lazy => false
        property :filetype,     String, :lazy => false
        property :created_at,   DateTime, :lazy => false
        property :datemodified, DateTime, :lazy => false
        property :size,         Integer, :lazy => false
        property :version,      Text, :lazy => false
        property :filepath,     Text, :lazy => false
        property :md5,          String, :lazy => false
        property :sha1,         String, :lazy => false
        property :sha256,       Text, :unique => true, :lazy => false
        property :fuzzyhash,    Text, :lazy => false

      end
    end
  end
end

class Filename

  MD5 = %r(^[a-fA-F\d]{32}$)
  SHA1 = %r(^[a-fA-F\d]{40}$)
  SHA256 = %r(^[a-fA-F\d]{64}$)

  def self.search(hash)

    @hashes = case hash
    when MD5
      puts "MD5"
      puts @hashes.inspect
      @hashes = Allsum::Client::Models::Filename.first(:md5 => hash)
    when SHA1
      puts "SHA1"
      @hashes = Allsum::Client::Models::Filename.first(:sha1 => hash)
      puts @hashes.inspect
    when SHA256
      puts "SHA256"
      @hashes = Allsum::Client::Models::Filename.first(:sha256 => hash)
    else
      puts "FUZZY"
      @hashes = Allsum::Client::Models::Filename.all
      matches = {}
      @hashes.each do |hash|
        percent = Ssdeep.fuzzy_compare(hash, hash.fuzzyhash)
        if percent > 80
          matches = {hash => percent}
        end
      end
    end
    return @hashes
  end
end

get '/' do
  erb :index
end

get '/search' do
  erb :no_match if !params.has_key?(:query) || params[:query].blank?
  @hashes = Filename.search(params[:query])
  puts @hashes.inspect
  if @hashes.nil?
    erb :no_match
  else
    erb :hashes
  end
end

get '/md5/:hash' do
  @hashes = Allsum::Client::Models::Filename.first(:md5 => params[:hash])
  if @hashes.nil?
    erb :no_match
  else
    erb :hashes
  end
end

get '/sha1/:hash' do
  @hashes = Allsum::Client::Models::Filename.first(:sha1 => params[:hash])
  if @hashes.nil?
    erb :no_match
  else
    erb :hashes
  end
end

get '/sha256/:hash' do
  @hashes = Allsum::Client::Models::Filename.first(:sha256 => params[:hash])
  if @hashes.nil?
    erb :no_match
  else
    erb :hashes
  end
end

get '/fuzzyhash/:hash' do
  @hashes = Allsum::Client::Models::Filename.all(:fuzzyhash => params[:hash])
  if @hashes.nil?
    erb :no_match
  else
    erb :hashes
  end
end

get '/about' do
  erb :about
end

get '/support' do
  erb :support
end

