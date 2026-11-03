require "./action"
require "./scope_checks/*"

class CB::Scope < CB::APIAction
  cluster_identifier_setter cluster_id
  property checks : Array(::Scope::Check.class) = [] of ::Scope::Check.class
  property database : String?
  property suite : String?

  def run
    check_required_args { |missing| missing << "cluster" if cluster_id.empty? }

    uri = client.get_role(cluster_id[:cluster], "default").uri
    raise Error.new "null uri" if uri.nil?

    # Accept only SCRAM with Channel Binding.
    #
    # https://github.com/will/crystal-pg#authentication-methods
    uri.query = "auth_methods=scram-sha-256-plus"

    if database.presence
      uri.path = database.to_s
    end

    self.suite = "quick" if checks.empty? && suite.nil?

    case suite
    when "all"
      self.checks = ::Scope::Check.all.map(&.type) - [::Scope::Mandelbrot]
    when "quick"
      self.checks += [::Scope::TableInfo, ::Scope::IndexHit, ::Scope::Blocking]
    when nil
    else
      raise Error.new("unknown suite '#{suite.inspect}'")
    end

    to_run = checks.uniq.sort_by!(&.name)

    DB.open(uri) do |db|
      to_run.map(&.new(db)).each do |c|
        @output << c << "\n"
      end
    end
  end
end
