require "./action"

module CB
  class LogDestinationDestroy < APIAction
    cluster_identifier_setter cluster_id
    eid_setter logdest_id

    def run
      check_required_args do |missing|
        missing << "cluster" if cluster_id.empty?
        missing << "logdest" unless logdest_id
      end

      client.destroy_log_destination client.resolve_cluster_id(cluster_id[:cluster]), logdest_id
      output.puts "log destination destroyed"
    end
  end
end
