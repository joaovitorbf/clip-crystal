require "http/server"
require "json"
require "./channel_cleaner"

front_html_file = File.new("frontend.html")
front_html = front_html_file.gets_to_end
front_html_file.close

channels = Hash(String, String).new
channel_timestamps = Hash(String, Time).new

start_channel_cleaner(channels, channel_timestamps)

server = HTTP::Server.new do |context|
  path = context.request.path
  method = context.request.method

  if path == "/" && method == "GET"
    context.response.status_code = 200
    context.response.content_type = "text/html"
    context.response.print front_html
  elsif path == "/update" && method == "POST"
    request_body = context.request.body.try &.gets_to_end

    if request_body
      begin
        data = JSON.parse(request_body)
        p! data
        channel = data["channel"]?.try &.as_s?
        content = data["content"]?.try &.as_s?
      rescue
        channel = nil
        content = nil
      end
    else
      channel = nil
      content = nil
    end

    if channel && content
      channels[channel] = content
      channel_timestamps[channel] = Time.utc
      context.response.status_code = 200
      context.response.content_type = "text/plain"
      context.response.print "Update successful"
    else
      context.response.status_code = 400
      context.response.content_type = "text/plain"
      context.response.print "Invalid request"
    end
  elsif path == "/fetch" && method == "GET"
    channel = context.request.query_params["channel"]?

    if channel
      content = channels.has_key?(channel) ? channels[channel] : ""
      context.response.status_code = 200
      context.response.content_type = "application/json"
      response_data = { "content" => content }
      context.response.print response_data.to_json
    else
      context.response.status_code = 400
      context.response.content_type = "text/plain"
      context.response.print "Channel parameter is required"
    end
  else
    context.response.status_code = 404
    context.response.content_type = "text/html"
    context.response.print "<h1>404 Not Found</h1>"
  end

end

address = server.bind_tcp 1323
puts "Listening on http://#{address}"
server.listen

# Hello, Doggo! :)
