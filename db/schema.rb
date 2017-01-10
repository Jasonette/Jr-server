# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170110090703) do

  create_table "jrs", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.string   "description"
    t.string   "platform"
    t.string   "classname"
    t.string   "version"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "sha"
    t.text     "readme"
    t.index ["classname"], name: "index_jrs_on_classname", unique: true
    t.index ["name"], name: "index_jrs_on_name", unique: true
    t.index ["url"], name: "index_jrs_on_url", unique: true
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text     "content"
    t.string   "searchable_type"
    t.integer  "searchable_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

end
