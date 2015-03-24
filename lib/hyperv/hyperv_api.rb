# Hyper-V API Library

class HyperV
  class Host
    def initialize(url, username, password)
      @url = url
      @username = username
      @password = password
    end

    def valid_server?(server_name)

    end

    def create_server(vm_options = {})
      # Hyper-V API should return the server-id immediately.
      # Server create process can be strated in the background.
    end

    def machine_status(server_id)

    end

    def power_on(server_id)

    end

    def get_hostname(server_id)

    end

    def get_transport_type(server_id)

    end

    def destroy_machine(server_id)

    end

    def power_off(server_id)

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