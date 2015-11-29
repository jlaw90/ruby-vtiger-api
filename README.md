# ruby vtiger client

This repo holds a very basic VTiger class that can be used for making
requests to the VTiger REST API


# Usage
Setting up the client:
````ruby
client = VTiger.new(host, path, user, key, true)
````

Logging in:
````ruby
puts "Login response:"
pp client.login
````

List all the module types that are available:
````ruby
puts "Querying for available types: "
pp client.listtypes
````

Describe a module:
````ruby
puts "Describing module: "
pp client.describe elementType: 'Contact'
````

Execute an SQL query:
````ruby
puts "Contact query request:"
pp client.query query: "SELECT id FROM Contact WHERE cf_2295 = 'C037793';"
````

Create a record:
````ruby
pp client.create method: :post, elementType: 'HeatBleed', element: {heatbleedname: 'OTDM Created', assigned_user_id: "19x156"}