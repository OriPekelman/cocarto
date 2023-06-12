# == Schema Information
#
# Table name: map_tokens
#
#  id           :uuid             not null, primary key
#  access_count :integer          default(0), not null
#  name         :text             not null
#  role_type    :enum             not null
#  token        :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  map_id       :uuid             not null
#
# Indexes
#
#  index_map_tokens_on_map_id  (map_id)
#  index_map_tokens_on_token   (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#
require "test_helper"

class MapTokenTest < ActiveSupport::TestCase
  class Validations < MapTokenTest
    test "role can't be owner" do
      map_token = MapToken.new

      assert_nothing_raised { map_token.role_type = :editor }
      assert_raises(ArgumentError) { map_token.role_type = :owner }
    end
  end
end
