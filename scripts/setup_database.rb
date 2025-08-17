#!/usr/bin/env ruby

require 'pg'

# Database setup script for XML Framework
class DatabaseSetup
  def initialize
    @connection = PG.connect(
      host: ENV['DB_HOST'] || 'localhost',
      port: ENV['DB_PORT'] || 5432,
      dbname: 'postgres',  # Connect to default database first
      user: ENV['DB_USER'] || 'postgres',
      password: ENV['DB_PASSWORD'] || 'password'
    )
  end

  def setup
    create_database
    create_tables
    seed_data
    puts "Database setup completed successfully!"
  end

  private

  def create_database
    db_name = ENV['DB_NAME'] || 'xml_framework_db'
    
    begin
      @connection.exec("CREATE DATABASE #{db_name}")
      puts "Created database: #{db_name}"
    rescue PG::DuplicateDatabase
      puts "Database #{db_name} already exists"
    end
    
    @connection.close
    
    # Reconnect to the new database
    @connection = PG.connect(
      host: ENV['DB_HOST'] || 'localhost',
      port: ENV['DB_PORT'] || 5432,
      dbname: db_name,
      user: ENV['DB_USER'] || 'postgres',
      password: ENV['DB_PASSWORD'] || 'password'
    )
  end

  def create_tables
    # Create sample tables based on the XML structure
    
    # Organizations table
    @connection.exec(<<~SQL)
      CREATE TABLE IF NOT EXISTS orgs (
        org_id SERIAL PRIMARY KEY,
        org_name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # Applications table
    @connection.exec(<<~SQL)
      CREATE TABLE IF NOT EXISTS applying (
        applying_id SERIAL PRIMARY KEY,
        org_id INTEGER REFERENCES orgs(org_id),
        surname VARCHAR(100),
        first_name VARCHAR(100),
        middle_name VARCHAR(100),
        email VARCHAR(255),
        primary_telephone VARCHAR(20),
        application_date DATE DEFAULT CURRENT_DATE,
        paid BOOLEAN DEFAULT FALSE,
        status VARCHAR(50) DEFAULT 'Draft',
        mode_of_entry VARCHAR(20),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # Registrations table
    @connection.exec(<<~SQL)
      CREATE TABLE IF NOT EXISTS registrations (
        registration_id SERIAL PRIMARY KEY,
        org_id INTEGER REFERENCES orgs(org_id),
        applying_id INTEGER REFERENCES applying(applying_id),
        first_name VARCHAR(100),
        surname VARCHAR(100),
        middle_name VARCHAR(100),
        sex CHAR(1),
        email VARCHAR(255),
        birth_date DATE,
        existing_id VARCHAR(50),
        application_date DATE DEFAULT CURRENT_DATE,
        submit_date DATE,
        is_accepted BOOLEAN DEFAULT FALSE,
        is_rejected BOOLEAN DEFAULT FALSE,
        is_deferred BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # Students table
    @connection.exec(<<~SQL)
      CREATE TABLE IF NOT EXISTS students (
        student_id VARCHAR(50) PRIMARY KEY,
        org_id INTEGER REFERENCES orgs(org_id),
        registration_id INTEGER REFERENCES registrations(registration_id),
        student_name VARCHAR(255),
        sex CHAR(1),
        nationality VARCHAR(100),
        email VARCHAR(255),
        address TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # Majors table
    @connection.exec(<<~SQL)
      CREATE TABLE IF NOT EXISTS majors (
        major_id SERIAL PRIMARY KEY,
        org_id INTEGER REFERENCES orgs(org_id),
        major_name VARCHAR(255) NOT NULL,
        department_id INTEGER,
        application_fees DECIMAL(10,2),
        can_apply BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # Create views for the application
    @connection.exec(<<~SQL)
      CREATE OR REPLACE VIEW vw_applying AS
      SELECT a.*, o.org_name
      FROM applying a
      LEFT JOIN orgs o ON a.org_id = o.org_id
    SQL

    @connection.exec(<<~SQL)
      CREATE OR REPLACE VIEW vw_registrations AS
      SELECT r.*, a.paid, a.status, o.org_name
      FROM registrations r
      LEFT JOIN applying a ON r.applying_id = a.applying_id
      LEFT JOIN orgs o ON r.org_id = o.org_id
    SQL

    puts "Created database tables and views"
  end

  def seed_data
    # Insert sample organization
    @connection.exec(<<~SQL)
      INSERT INTO orgs (org_name) 
      VALUES ('University of Technology')
      ON CONFLICT DO NOTHING
    SQL

    # Insert sample majors
    @connection.exec(<<~SQL)
      INSERT INTO majors (org_id, major_name, application_fees, can_apply)
      VALUES 
        (1, 'Computer Science', 50.00, TRUE),
        (1, 'Engineering', 75.00, TRUE),
        (1, 'Business Administration', 45.00, TRUE),
        (1, 'Medicine', 100.00, TRUE)
      ON CONFLICT DO NOTHING
    SQL

    # Insert sample applications
    @connection.exec(<<~SQL)
      INSERT INTO applying (org_id, surname, first_name, middle_name, email, primary_telephone, paid, status, mode_of_entry)
      VALUES 
        (1, 'Smith', 'John', 'Michael', 'john.smith@email.com', '+1234567890', TRUE, 'Submitted', 'UTME'),
        (1, 'Johnson', 'Jane', 'Elizabeth', 'jane.johnson@email.com', '+1234567891', FALSE, 'Draft', 'DE'),
        (1, 'Williams', 'Robert', 'James', 'robert.williams@email.com', '+1234567892', TRUE, 'Submitted', 'UTME'),
        (1, 'Brown', 'Mary', 'Patricia', 'mary.brown@email.com', '+1234567893', TRUE, 'Submitted', 'TRANSFER')
      ON CONFLICT DO NOTHING
    SQL

    # Insert sample registrations
    @connection.exec(<<~SQL)
      INSERT INTO registrations (org_id, applying_id, first_name, surname, middle_name, sex, email, existing_id, is_accepted)
      VALUES 
        (1, 1, 'John', 'Smith', 'Michael', 'M', 'john.smith@email.com', 'STU001', TRUE),
        (1, 3, 'Robert', 'Williams', 'James', 'M', 'robert.williams@email.com', 'STU002', TRUE)
      ON CONFLICT DO NOTHING
    SQL

    puts "Seeded sample data"
  end
end

# Run the setup
if __FILE__ == $0
  setup = DatabaseSetup.new
  setup.setup
end
