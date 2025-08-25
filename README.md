# XML Framework

A Ruby framework for building web applications from XML templates with Rails and PostgreSQL integration.

## Installation

```bash
gem install xml_framework

Thought for 2sHere's how to use your XML Framework:

## Installation & Setup

**1. Build and install the gem:**

```shellscript
gem build xml_framework.gemspec
gem install xml_framework-0.1.0.gem
```

**2. Set your database connection:**

```shellscript
export DATABASE_URL="postgresql://username:password@localhost:5432/your_database"
```

## Usage Workflow

**3. Create a new project:**

```shellscript
xml_framework new my_university_app
cd my_university_app
```

**4. Inspect your database tables:**

```shellscript
xml_framework inspect
```

This shows all your database tables, columns, and data types.

**5. Generate XML from your database:**

```shellscript
# Auto-generate XML for all tables
xml_framework generate --auto --app-name "University Management System"

# Or generate for specific table only
xml_framework generate --table students

# Or generate for specific tables
xml_framework generate --tables users,courses,enrollments
```

**6. Render XML to HTML:**

```shellscript
xml_framework render
```

**7. Start the web server:**

```shellscript
xml_framework server
```

Visit `http://localhost:4567` to view your generated web application.

## Example Complete Workflow

```shellscript
# 1. Create project
xml_framework new student_portal
cd student_portal

# 2. Set database (replace with your credentials)
export DATABASE_URL="postgresql://admin:password@localhost:5432/school_db"

# 3. Inspect what tables you have
xml_framework inspect

# 4. Auto-generate XML from all tables
xml_framework generate --auto --app-name "Student Portal"

# 5. Convert XML to HTML
xml_framework render

# 6. View in browser
xml_framework server
```

The framework automatically creates dashboards with database statistics, data grids for each table with CRUD operations, and forms for data entry - all generated from your existing database structure. You can also manually edit the generated XML files to customize the interface according to your preferences.
