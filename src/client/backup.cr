require "./client"

module CB
  class Client
    def backup_list(id : Identifier)
      resp = get "clusters/#{resolve_cluster_id id}/backups"
      Array(CB::Model::Backup).from_json resp.body, root: "backups"
    end

    def backup_token(id : Identifier)
      resp = post "clusters/#{resolve_cluster_id id}/backup-tokens"
      CB::Model::BackupToken.from_json resp.body
    end

    def backup_start(id : Identifier)
      resp = put "clusters/#{resolve_cluster_id id}/actions/start-backup"
      Message.from_json resp.body
    end
  end
end
