require "webrick"

module FixturesServer
  # Run a http server for fixtures for the duration of the test suite.
  # It’s started the first time start_fixtures_server is called, and never stops.
  def start_fixtures_server
    return unless @fixtures_server.nil? # There is no race condition here. When tests are run in parallel, it is done using subprocesses.

    @fixtures_server = WEBrick::HTTPServer.new(Port: 0, # Port 0 means automatic
      DocumentRoot: file_fixture_path)

    # Simulate a WFS server (using test/fixtures/files/wfs/)
    # See https://georezo.net/wiki/main/standards/wfs for a quick description of the behaviour.
    # We only simulate GetCapabilities, DescribeFeatureType and GetFeature.
    @fixtures_server.mount_proc "/wfs" do |req, res|
      operation = req.query["REQUEST"]
      res.body = file_fixture("wfs/#{operation}.xml").open
    end

    Thread.new { @fixtures_server.start }
  end

  def fixtures_server_url
    "http://#{`hostname`.strip}:#{@fixtures_server.config[:Port]}"
  end
end
