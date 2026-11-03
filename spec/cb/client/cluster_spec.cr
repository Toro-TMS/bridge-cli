require "../../spec_helper"

require "../../../src/client/*"

Spectator.describe CB::Client do
  subject(client) { described_class.new TEST_TOKEN }

  describe "#flatten_clusters" do
    it "handles no clusters" do
      clusters = [] of CB::Model::Cluster
      expect(&.flatten_clusters(clusters)).to be_empty
    end

    it "handles clusters without replicas" do
      clusters = [CB::Model::Cluster.new(
        id: "pkdpq6yynjgjbps4otxd7il2u4",
        team_id: "l2gnkxjv3beifk6abkraerv7de",
        name: "abc",
        replicas: nil,
      )]

      result = client.flatten_clusters(clusters)
      expect(result.size).to eq 1
    end

    it "handles clusters with replicas" do
      clusters = [CB::Model::Cluster.new(
        id: "pkdpq6yynjgjbps4otxd7il2u4",
        team_id: "l2gnkxjv3beifk6abkraerv7de",
        name: "abc",
        replicas: [
          CB::Model::Cluster.new(
            id: "replica_id",
            team_id: "l2gnkxjv3beifk6abkraerv7de",
            name: "replica of abc",
            replicas: [
              CB::Model::Cluster.new(
                id: "replica_of_replica_id",
                team_id: "l2gnkxjv3beifk6abkraerv7de",
                name: "replica of replica",
                replicas: nil),
            ]),
        ],
      )]

      result = client.flatten_clusters(clusters)
      expect(result.size).to eq 3
    end
  end
end

Spectator.describe CB::Client do
  mock_client

  let(team) { Factory.team }
  let(cluster) { Factory.cluster(name: "test-cluster") }

  describe "#resolve_cluster_id" do
    it "returns an id untouched" do
      expect(client.resolve_cluster_id(CB::Identifier.new cluster.id)).to eq cluster.id
    end

    it "looks up a name" do
      expect(client).to receive(:get_teams).and_return [team]
      expect(client).to receive(:get_clusters).and_return [cluster]

      expect(client.resolve_cluster_id(CB::Identifier.new cluster.name)).to eq cluster.id
    end

    it "raises for an unknown name" do
      expect(client).to receive(:get_teams).and_return [team]
      expect(client).to receive(:get_clusters).and_return [cluster]

      expect { client.resolve_cluster_id(CB::Identifier.new "unknown-cluster") }.to raise_error Program::Error, /does not exist/
    end
  end
end
