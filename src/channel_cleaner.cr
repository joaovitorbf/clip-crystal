require "time"

CLEAR_INTERVAL = 10.seconds
CHANNEL_TIMEOUT = 60.seconds

def start_channel_cleaner(channels : Hash(String, String), channel_timestamps : Hash(String, Time))
  spawn do
    loop do
      now = Time.utc
      channel_timestamps.each do |channel, timestamp|
        if now - timestamp > CHANNEL_TIMEOUT
          channels.delete(channel)
          channel_timestamps.delete(channel)
        end
      end
      sleep CLEAR_INTERVAL
    end
  end
end
