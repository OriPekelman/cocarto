module MockWfsServer
  # Run a fake WFS server for the duration of the test suite.
  # See test/fixtures/files/wfs/
  # See also https://georezo.net/wiki/main/standards/wfs for a quick description of the behaviour.
  # We only simulate GetCapabilities, DescribeFeatureType and GetFeature.
  extend ActiveSupport::Concern

  included do
    setup do
      @server = WEBrick::HTTPServer.new Port: 9090
      @server.mount_proc "/" do |req, res|
        operation = req.query["REQUEST"]
        res.body = file_fixture("wfs/#{operation}.xml").open
      end
      Thread.new { @server.start }
    end

    teardown do
      @server.stop
    end
  end
end
