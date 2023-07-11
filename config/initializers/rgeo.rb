# https://github.com/rgeo/rgeo/blob/main/doc/Which-factory-should-I-use.md
# Use Geos if available
RGEO_FACTORY = RGeo::Cartesian.preferred_factory(srid: 4326)
