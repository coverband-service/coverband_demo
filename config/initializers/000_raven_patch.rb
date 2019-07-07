###
# Monkey patch a current bug in sentry send_event async
# https://github.com/getsentry/raven-ruby/issues/800
###
module Raven
  class Instance
    def capture_type(obj, options = {})
      unless configuration.capture_allowed?(obj)
        logger.debug("#{obj} excluded from capture: #{configuration.error_messages}")
        return false
      end

      message_or_exc = obj.is_a?(String) ? "message" : "exception"
      options[:configuration] = configuration
      options[:context] = context
      if (evt = Event.send("from_" + message_or_exc, obj, options))
        yield evt if block_given?
        if configuration.async?
          begin
            # We have to convert to a JSON-like hash, because background job
            # processors (esp ActiveJob) may not like weird types in the event hash
            # configuration.async.call(evt.to_json_compatible)
            configuration.async.call(evt)
          rescue => ex
            logger.error("async event sending failed: #{ex.message}")
            send_event(evt)
          end
        else
          send_event(evt)
        end
        Thread.current["sentry_#{object_id}_last_event_id".to_sym] = evt.id
        evt
      end
    end
  end
end
