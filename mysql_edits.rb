require 'mysql2'

# Step 1: Connect to the MySQL database
client = Mysql2::Client.new(
  host: 'localhost',      # Replace with your MySQL host if different
  username: 'iuri',       # Replace with your MySQL username
  password: '121212',     # Replace with your MySQL password
  database: 'people_iuri' # Replace with the name of your MySQL database
)

# Step 2: Retrieve the first 10 records from the "people_iuri_Allerson" table
table_name = "people_iuri_Allerson"
results = client.query("SELECT id, firstname, lastname, email FROM #{table_name} LIMIT 10")

# Display the results
puts "First 10 records (id, firstname, lastname, email):"
results.each do |row|
  puts "#{row['id']}, #{row['firstname']}, #{row['lastname']}, #{row['email']}"
end

# Step 3: Find and display the count of people with the profession "doctor"
doctor_count = client.query("SELECT COUNT(*) as count FROM #{table_name} WHERE profession = 'doctor'")
puts "Number of people with the profession 'doctor': #{doctor_count.first['count']}"

# Step 4: Update the email2 column to change the email from "@gmail.com" to "@hotmail.com" for all people with the profession "Ecologist"
client.query("UPDATE #{table_name} SET email2 = REPLACE(email, '@gmail.com', '@hotmail.com') WHERE profession = 'Ecologist'")

# Step 5: Close the database connection
client.close
