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
    respond(context, 200, "text/html", front_html)
  elsif path == "/update" && method == "POST"
    request_body = context.request.body.try &.gets_to_end

    if request_body
      begin
        data = JSON.parse(request_body)
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
      if content.size > 10_000
        respond(context, 413, "text/plain", "Content too long (max 10,000 characters)")
      elsif channels.size < 50 || channels.has_key?(channel)
        channels[channel] = content
        channel_timestamps[channel] = Time.utc
        respond(context, 200, "text/plain", "Update successful")
      else
        respond(context, 403, "text/plain", "Channel limit reached (50)")
      end
    else
      respond(context, 400, "text/plain", "Invalid request")
    end
  elsif path == "/fetch" && method == "GET"
    channel = context.request.query_params["channel"]?

    if channel
      content = channels.has_key?(channel) ? channels[channel] : ""
      respond(context, 200, "application/json", { "content" => content }.to_json)
    else
      respond(context, 400, "text/plain", "Channel parameter is required")
    end
  else
    respond(context, 404, "text/html", "<h1>404 Not Found</h1>")
  end

end

address = server.bind_tcp 1323
puts "Listening on http://#{address}"
server.listen

def respond(context, status_code, content_type, body)
  context.response.status_code = status_code
  context.response.content_type = content_type
  context.response.print body
end

# Hello, Doggo! :)
