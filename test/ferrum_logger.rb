# Get the javascript logs from the browser, through Ferrum, Cuprite, and Capybara, in the minitest logs.
# Taken from https://github.com/rubycdp/cuprite/issues/113

class FerrumLogger
  def puts(log_str)
    _log_symbol, _log_time, log_body_str = log_str.strip.split(" ", 3)

    return if log_body_str.nil?

    log_body = JSON.parse(log_body_str)

    case log_body["method"]
    when "Runtime.consoleAPICalled"
      log_body["params"]["args"].each do |arg|
        case arg["type"]
        when "string"
          Kernel.puts arg["value"]
        when "object"
          Kernel.puts arg["preview"]["properties"].map { |x| [x["name"], x["value"]] }.to_h
          Kernel.puts arg["preview"]["description"]
        end
      end

    when "Runtime.exceptionThrown"
    # noop, this is already logged because we have "js_errors: true" in cuprite.

    when "Log.entryAdded"
      Kernel.puts "#{log_body["params"]["entry"]["url"]} - #{log_body["params"]["entry"]["text"]}"
    end
  end
end
