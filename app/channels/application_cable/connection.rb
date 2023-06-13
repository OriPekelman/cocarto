module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user # this checks whether a user is authenticated with devise
      if (verified_user = env["warden"].user)
        if verified_user.anonymous?
          verified_user.store_tokens_array_in_session(env["rack.session"]) # restore anonymous map tokens
        end
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
