# XML Framework

A Rails gem that builds your entire web UI from one XML file (`config/app.xml`). You define menus, dashboards, data grids, forms, filters, and reports in XML — the gem renders them with a Metronic admin theme, talks to PostgreSQL, and handles login and sessions.

**You do not create a controller or view for each screen.** You edit XML.

---

## Before you start

You need:

- Ruby 3.1+
- Rails 7.0+
- PostgreSQL installed and running
- Bundler

---

## You already ran `rails new my-app` — now do this

Below is everything you need, in order, starting from a fresh Rails app.

---

### 1. Go into your app folder

```bash
cd my-app
```

---

### 2. Add the gem to your Gemfile

Open `Gemfile` and add one of these lines at the bottom:

**If the gem is on your machine (local development):**

```ruby
gem 'xml_framework', path: 'xml_framework'
```

**If the gem is on GitHub:**

```ruby
gem 'xml_framework', git: 'https://github.com/ogaed/xml_framework.git'
```

Then install it:

```bash
bundle install
```

**What this does:** Rails can now load the XML Framework engine, controllers, views, theme CSS/JS, and helpers.

---

### 3. Run the install generator

```bash
rails generate xml_framework:install
```

**What this does:** Creates two files in your app:

| File | What it does |
|------|----------------|
| `config/initializers/xml_framework.rb` | On every Rails boot, reads `config/app.xml` and prepares the framework |
| `config/app.xml` | A sample XML UI (menus, dashboard, grids) — **this is where you define your application** |

If `config/app.xml` already exists, the generator will not overwrite it.

---

### 4. Mount the framework in your routes

Open `config/routes.rb`. **Replace** the default routes with:

```ruby
Rails.application.routes.draw do
  mount XmlFramework::Engine => '/'
end
```

**What this does:** The gem brings its own routes (`/dashboard`, `/login`, `/xml_app/:key`, `/jsondata`, `/datapost`, etc.). Mounting at `/` makes the XML app your whole website.

**Optional — mount under a prefix:**

```ruby
mount XmlFramework::Engine => '/admin'
```

Then the dashboard is at `http://localhost:3000/admin/dashboard` instead of `/dashboard`.

---

### 5. Set up PostgreSQL

The framework reads and writes data through PostgreSQL. Use the `database.yml` that `rails new` already created:

```yaml
# config/database.yml
development:
  adapter: postgresql
  database: my_app_development
  username: postgres
  password: your_password
  host: localhost
```

Or set a connection URL:

```bash
export DATABASE_URL="postgresql://postgres:your_password@localhost:5432/my_app_development"
```

Create the database:

```bash
rails db:create
```

If you have migrations:

```bash
rails db:migrate
```

**What this does:** Grids and forms in your XML need real tables. The `table` and field names in `config/app.xml` must match columns in this database.

---

### 6. Edit `config/app.xml` for your data

Open `config/app.xml`. This file controls:

- **App name** — shown in the sidebar and header
- **Menus** — left navigation
- **Desks** — each screen (dashboard, grid, form, filter, etc.)

Example: a menu item pointing to desk key `965`:

```xml
<MENU name="Students">965</MENU>
```

Example: a grid bound to a `students` table:

```xml
<DESK key="965" name="Students">
  <GRID table="students" keyfield="student_id">
    <TEXTFIELD title="Name">student_name</TEXTFIELD>
    <FORM table="students" keyfield="student_id">
      <TEXTFIELD title="Name">student_name</TEXTFIELD>
    </FORM>
  </GRID>
</DESK>
```

The text inside each field tag (`student_name`) must match a **column name** in PostgreSQL.

**What this does:** When a user opens `/xml_app/965`, the framework parses this XML, queries `students`, and renders a Metronic-styled grid with a form — no extra code from you.

---

### 7. Start the server

```bash
rails server
```

Open your browser:

| URL | What you see |
|-----|----------------|
| http://localhost:3000 | Redirects to the app |
| http://localhost:3000/login | Login page |
| http://localhost:3000/dashboard | Dashboard (desk key `1` in sample XML) |
| http://localhost:3000/xml_app/965 | Any screen by desk `key` |

**Demo login:** username `admin`, password `admin`

---

## That is the full install. What happens next?

Once the steps above are done, your Rails app works like this:

```
config/app.xml  →  framework parses XML  →  renders UI (Metronic theme)
                         ↓
                   PostgreSQL (your tables)
                         ↓
                   JSON API saves form data / loads grid rows
```

### Day-to-day work

1. **Change the UI** — edit `config/app.xml`, restart the server (or refresh if only data changed).
2. **Add a new screen** — add a `<DESK>` and a `<MENU>` entry; no new Rails files needed.
3. **Add a new field** — add a `<TEXTFIELD>` (or other field type) inside `<GRID>` or `<FORM>`.
4. **Restrict access** — add `access="admin"` or `role="manager"` on menus, desks, or tiles.

You still use normal Rails for things the gem does not cover (custom APIs, background jobs, etc.). The gem owns the XML-driven admin UI.

---

## What the gem gives you (you do not build these)

| Built in | Description |
|----------|-------------|
| Layout | Metronic sidebar, header, footer |
| Login / logout | Session-based auth |
| Dashboards | Stat tiles from SQL `COUNT` queries |
| Grids | AG Grid with pagination, sort, inline edit |
| Forms | Create / edit / delete via JSON POST |
| Filters | Drilldown trees and filter grids |
| Accordion | Multi-panel forms and sub-grids |
| Reports | Jasper PDF generation (optional) |
| Access control | `role` and `access` attributes on XML elements |

---

## Minimal `config/app.xml` example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<APP name="My School" org="org_id">

  <MENU name="Main">
    <MENU name="Students">100</MENU>
  </MENU>

  <DESK key="1" name="Dashboard">
    <DASHBOARD>
      <TILE table="students" title="Total Students" jumpview="100:0">
        <TEXTFIELD fnct="COUNT(*)">total</TEXTFIELD>
      </TILE>
    </DASHBOARD>
  </DESK>

  <DESK key="100" name="Students">
    <GRID table="students" keyfield="id">
      <TEXTFIELD title="Name">name</TEXTFIELD>
      <TEXTFIELD title="Email">email</TEXTFIELD>
      <FORM table="students" keyfield="id">
        <TEXTFIELD title="Name">name</TEXTFIELD>
        <TEXTFIELD title="Email">email</TEXTFIELD>
      </FORM>
    </GRID>
  </DESK>

</APP>
```

Save the file, ensure a `students` table exists with `id`, `name`, and `email` columns, then visit `/dashboard` and `/xml_app/100`.

---

## XML elements reference

| Category | Elements |
|----------|----------|
| Structure | `APP`, `MENU`, `DESK` |
| Views | `DASHBOARD`, `GRID`, `FORM`, `FILTER`, `ACCORDION`, `JASPER` |
| Filter tabs | `FILTERGRID`, `DRILLDOWN`, `FILTERFORM` |
| Form fields | `TEXTFIELD`, `TEXTAREA`, `COMBOBOX`, `COMBOLIST`, `CHECKBOX`, `TEXTDATE`, `TEXTDECIMAL`, `PICTURE`, `FILE`, `EDITOR`, `PASSWORD`, `MULTISELECT`, `HTML` |
| Grid columns | `TEXTFIELD`, `CHECKBOX`, `TEXTDATE`, `BROWSER`, `WEBLINK`, `PICTURE`, `EDITFIELD`, `BUTTON`, `ACTION`, `SEARCH` |
| Dashboard | `TILE`, `LINKS` / `LINK` |
| Actions | `ACTIONS` / `ACTION` |

---

## HTTP endpoints (used automatically by the UI)

| Route | Method | Purpose |
|-------|--------|---------|
| `/jsondata?view=965:0` | GET | Grid data |
| `/datapost` | POST | Save or delete a record |
| `/ajaxupdate` | POST | Inline grid edit |
| `/filters` | POST | Apply drilldown filter |
| `/reports` | POST | Generate PDF report |
| `/login` | POST | Sign in |
| `/logout` | DELETE | Sign out |

You normally do not call these yourself — the JavaScript client handles them.

---

## Access control in XML

```xml
<DESK access="admin" ...>
<MENU role="admissions" access="open" ...>
<TILE access="admin" ...>
```

| Attribute | Meaning |
|-----------|---------|
| `role="a,b"` | User must have one of these roles |
| `access="tag"` | User must have this access level |
| Super user | Bypasses all checks (set at login) |

---

## Optional: customize look and feel

The gem ships Metronic CSS/JS under `public/theme/` inside the gem. To override the layout in **your** Rails app, create:

```
my-app/app/views/layouts/application.html.erb
```

To override a single page:

```
my-app/app/views/xml_app/show.html.erb
```

Rails uses your app's views before the gem's.

---

## Optional: generate XML from an existing database

If you already have PostgreSQL tables and want a starting `app.xml`:

```bash
export DATABASE_URL="postgresql://user:pass@localhost:5432/mydb"
cd /opt/my_baraza/xml_framework
ruby -Ilib bin/xml_framework inspect
ruby -Ilib bin/xml_framework generate --auto --app-name "My App"
```

Copy the generated XML into your Rails app's `config/app.xml` and adjust menus and labels.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Blank or error page | Check `mount XmlFramework::Engine => '/'` in `config/routes.rb` |
| "Framework not loaded" | Ensure `config/app.xml` exists and XML is valid |
| Grid is empty | Check `database.yml`, table name, and column names in XML |
| Page looks unstyled | Hard-refresh browser; confirm engine is mounted so `/theme/style.bundle.css` loads |
| Login fails | Try `admin` / `admin`, or wire up your `entitys` user table |

Check `log/development.log` for details.

---

## Quick checklist

After `rails new my-app`, you should have done all of this:

- [ ] Added `gem 'xml_framework'` to `Gemfile`
- [ ] Ran `bundle install`
- [ ] Ran `rails generate xml_framework:install`
- [ ] Set `mount XmlFramework::Engine => '/'` in `config/routes.rb`
- [ ] Configured PostgreSQL in `config/database.yml`
- [ ] Ran `rails db:create`
- [ ] Edited `config/app.xml` to match your tables
- [ ] Ran `rails server`
- [ ] Logged in at `/login`

---

## License

MIT — see [LICENSE](LICENSE).
