# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_18_063343) do
  create_table "lesli_accounts", force: :cascade do |t|
    t.string "status", null: false
    t.string "name"
    t.string "email", null: false
    t.string "region", default: "america"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["deleted_at"], name: "index_lesli_accounts_on_deleted_at"
    t.index ["email"], name: "index_lesli_accounts_on_email", unique: true
    t.index ["user_id"], name: "index_lesli_accounts_on_user_id"
  end

  create_table "lesli_dashboard_accounts", force: :cascade do |t|
    t.string "name"
    t.integer "status", default: 0, null: false
    t.datetime "enabled_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id", null: false
    t.index ["account_id"], name: "index_lesli_dashboard_accounts_on_account_id", unique: true
    t.index ["deleted_at"], name: "index_lesli_dashboard_accounts_on_deleted_at"
  end

  create_table "lesli_dashboard_components", force: :cascade do |t|
    t.string "component", null: false
    t.integer "position", default: 1, null: false
    t.integer "size", default: 4, null: false
    t.json "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "dashboard_id", null: false
    t.index ["dashboard_id", "position"], name: "index_lesli_dashboard_components_on_dashboard_id_and_position"
    t.index ["dashboard_id"], name: "index_lesli_dashboard_components_on_dashboard_id"
  end

  create_table "lesli_dashboard_dashboards", force: :cascade do |t|
    t.string "name", null: false
    t.string "engine", null: false
    t.boolean "default", default: false, null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id", null: false
    t.index ["account_id", "engine"], name: "index_dashboard_active_default", unique: true, where: "\"default\" = true AND deleted_at IS NULL"
    t.index ["account_id", "engine"], name: "index_lesli_dashboard_dashboards_on_account_id_and_engine"
    t.index ["account_id"], name: "index_lesli_dashboard_dashboards_on_account_id"
    t.index ["deleted_at"], name: "index_lesli_dashboard_dashboards_on_deleted_at"
  end

  create_table "lesli_resources", force: :cascade do |t|
    t.string "identifier"
    t.string "label"
    t.string "engine"
    t.string "action"
    t.string "route"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.index ["deleted_at"], name: "index_lesli_resources_on_deleted_at"
    t.index ["parent_id"], name: "index_lesli_resources_on_parent_id"
  end

  create_table "lesli_roles", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.string "description"
    t.boolean "active"
    t.string "path_default"
    t.boolean "path_limited"
    t.boolean "isolated", default: false
    t.integer "permission_level", default: 10
    t.datetime "deployed_at"
    t.datetime "modified_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.index ["account_id"], name: "index_lesli_roles_on_account_id"
    t.index ["deleted_at"], name: "index_lesli_roles_on_deleted_at"
  end

  create_table "lesli_users", force: :cascade do |t|
    t.string "uid", null: false
    t.boolean "active", default: true, null: false
    t.string "alias"
    t.string "title"
    t.string "salutation"
    t.string "first_name"
    t.string "last_name"
    t.string "time_zone"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.string "unlock_token"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "password_expiration_at"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "confirmation_token"
    t.datetime "confirmation_sent_at"
    t.datetime "confirmed_at"
    t.string "telephone"
    t.string "telephone_confirmation_token"
    t.datetime "telephone_confirmation_sent_at"
    t.datetime "telephone_confirmed_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.index ["account_id", "active"], name: "index_lesli_users_on_account_id_and_active"
    t.index ["account_id", "confirmed_at"], name: "index_lesli_users_on_account_id_and_confirmed_at"
    t.index ["account_id", "created_at"], name: "index_lesli_users_on_account_id_and_created_at"
    t.index ["account_id", "deleted_at"], name: "index_lesli_users_on_account_id_and_deleted_at"
    t.index ["account_id", "last_sign_in_at"], name: "index_lesli_users_on_account_id_and_last_sign_in_at"
    t.index ["account_id", "locked_at"], name: "index_lesli_users_on_account_id_and_locked_at"
    t.index ["account_id", "locked_until"], name: "index_lesli_users_on_account_id_and_locked_until"
    t.index ["account_id"], name: "index_lesli_users_on_account_id"
    t.index ["confirmation_token"], name: "index_lesli_users_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_lesli_users_on_deleted_at"
    t.index ["email"], name: "index_lesli_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_lesli_users_on_reset_password_token", unique: true
    t.index ["uid"], name: "index_lesli_users_on_uid", unique: true
    t.index ["unlock_token"], name: "index_lesli_users_on_unlock_token", unique: true
  end

  add_foreign_key "lesli_accounts", "lesli_users", column: "user_id"
  add_foreign_key "lesli_dashboard_accounts", "lesli_accounts", column: "account_id"
  add_foreign_key "lesli_dashboard_components", "lesli_dashboard_dashboards", column: "dashboard_id"
  add_foreign_key "lesli_dashboard_dashboards", "lesli_dashboard_accounts", column: "account_id"
  add_foreign_key "lesli_resources", "lesli_resources", column: "parent_id"
  add_foreign_key "lesli_roles", "lesli_accounts", column: "account_id"
  add_foreign_key "lesli_users", "lesli_accounts", column: "account_id"
end
