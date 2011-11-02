require File.dirname(__FILE__) + '/environment'
require 'member'

get '/' do
  @member_count = $redis.scard 'members'
  erb :home
end

get '/add' do
  erb :add
end

get '/search' do
  @query = params[:q]
  @members = Member.with_keywords(*params[:q].split(' '))
  erb :list
end

get '/member/:username' do
  erb :member
end

post '/create' do
  erb :error and return unless params[:first_name] && params[:last_name] && params[:username] && params[:keywords] && params[:keywords].split(' ').any?

  Member.create(
    first_name: params[:first_name],
    last_name: params[:last_name],
    keywords: params[:keywords].split(' ')
  )

  redirect '/'
end
