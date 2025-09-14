require "spec"
require "http/client"
require "json"

it "serves the frontend on /" do
  response = HTTP::Client.get("http://localhost:1323/")
  response.status_code.should eq(200)
  response.headers["Content-Type"].should contain("text/html")
  response.body.should contain("<html")
end

it "returns 404 for unknown path" do
  response = HTTP::Client.get("http://localhost:1323/unknown")
  response.status_code.should eq(404)
  response.body.should contain("404")
end

it "rejects invalid /update requests" do
  response = HTTP::Client.post("http://localhost:1323/update", body: "invalid json")
  response.status_code.should eq(400)
  response.body.should contain("Invalid request")
end

it "accepts valid /update requests and updates channel" do
  body = {channel: "test", content: "hello"}.to_json
  response = HTTP::Client.post("http://localhost:1323/update", body: body)
  response.status_code.should eq(200)
  response.body.should contain("Update successful")
end

it "rejects too long content on /update" do
  long_content = "a" * 10_001
  body = {channel: "test", content: long_content}.to_json
  response = HTTP::Client.post("http://localhost:1323/update", body: body)
  response.status_code.should eq(413)
  response.body.should contain("Content too long")
end

it "fetches channel content via /fetch" do
  body = {channel: "fetchtest", content: "world"}.to_json
  HTTP::Client.post("http://localhost:1323/update", body: body)
  response = HTTP::Client.get("http://localhost:1323/fetch?channel=fetchtest")
  response.status_code.should eq(200)
  response.headers["Content-Type"].should contain("application/json")
  json = JSON.parse(response.body)
  json["content"].should eq("world")
end

it "returns empty string for unknown channel on /fetch" do
  response = HTTP::Client.get("http://localhost:1323/fetch?channel=unknown")
  response.status_code.should eq(200)
  json = JSON.parse(response.body)
  json["content"].should eq("")
end

it "requires channel param on /fetch" do
  response = HTTP::Client.get("http://localhost:1323/fetch")
  response.status_code.should eq(400)
  response.body.should contain("Channel parameter is required")
end
