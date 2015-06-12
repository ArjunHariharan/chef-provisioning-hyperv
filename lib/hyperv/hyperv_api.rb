# Hyper-V API Library

class HyperV
  class Host
    def initialize(url, username, password)
      @url = url
      @username = username
      @password = password
    end

    def valid_server?(_server_name)
    end

    def create_server(_vm_options = {})
      # Hyper-V API should return the server-id immediately.
      # Server create process can be strated in the background.
    end

    def machine_status(_server_id)
    end

    def power_on(_server_id)
    end

    def get_hostname(_server_id)
    end

    def get_transport_type(_server_id)
    end

    def destroy_machine(_server_id)
    end

    def power_off(_server_id)
    end

    private

    def connection
      unless @connection
        # Make http connection with hyperv server.
        # @connection = New connection object
      end

      @connection
    end
  end
end
