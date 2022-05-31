# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
User.create!([
  {email: "elisee.reclus@commune.paris", password: "refleurir", password_confirmation: "refleurir"},
  {email: "cassini@carto.gouv.fr", password: "générations12345", password_confirmation: "générations12345"}
])
