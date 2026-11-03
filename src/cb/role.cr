require "./action"
require "./table"

abstract class CB::RoleAction < CB::APIAction
  cluster_identifier_setter cluster_id

  def validate
    check_required_args do |missing|
      missing << "cluster" if cluster_id.empty?
    end
  end
end

# Action to create a cluster role for the calling user.
class CB::RoleCreate < CB::RoleAction
  def run
    validate

    id = client.resolve_cluster_id cluster_id[:cluster]
    role = client.create_role id
    output << "Role #{role.name} created on cluster #{id}.\n"
  end
end

class CB::RoleList < CB::RoleAction
  format_setter format

  bool_setter? no_header

  private property cluster : CB::Model::Cluster?

  private property roles : Array(Hash(String, String)) = [] of Hash(String, String)

  private property team : CB::Model::Team?

  def run
    validate

    c = client.get_cluster cluster_id[:cluster]
    @cluster = c
    @team = client.get_team c.team_id

    r = client.list_roles c.id

    r.each do |role|
      @roles << {
        "role"    => role.name,
        "account" => role.name.starts_with?("u_") ? role.account_email.to_s : "system",
      }
    end

    case @format
    when CB::Format::JSON
      output_json
    when CB::Format::Default, CB::Format::Table
      output_default
    end
  end

  def output_default
    table = Table::TableBuilder.new(border: :none) do
      columns do
        add "Role"
        add "Account"
      end

      header unless no_header

      @roles.each do |role|
        row [role["role"], role["account"]]
      end
    end

    output << table.render << '\n'
  end

  def output_json
    output << {
      "cluster": @cluster.try &.name,
      "team":    @team.try &.name,
      "roles":   @roles,
    }.to_pretty_json << '\n'
  end
end

# Action to update a cluster role.
class CB::RoleUpdate < CB::RoleAction
  role_setter? role
  bool_setter? read_only
  bool_setter? rotate_password

  def validate
    super
    check_required_args do |missing|
      missing << "name" unless role
    end
  end

  def run
    validate

    if @role == "user"
      @role = Role.new "u_" + client.get_account.id
    end

    flavor = read_only ? "read" : "write" unless read_only.nil?

    id = client.resolve_cluster_id cluster_id[:cluster]
    role = client.update_role id, @role, {flavor: flavor, rotate_password: rotate_password}

    output << "Role #{role.name} updated on cluster #{id}.\n"
  end
end

class CB::RoleDelete < CB::RoleAction
  role_setter? role

  def validate
    super
    check_required_args do |missing|
      missing << "name" unless role
    end
  end

  def run
    validate

    if @role == "user"
      @role = Role.new "u_" + client.get_account.id
    end

    id = client.resolve_cluster_id cluster_id[:cluster]
    role = client.delete_role id, @role
    output << "Role #{role.name} deleted from cluster #{id}.\n"
  end
end
