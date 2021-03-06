require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
	def self.table_name
		self.to_s.downcase.pluralize
	end

	def self.column_names
		column_names = []
		sql = "PRAGMA table_info('#{table_name}')"
		table_info = DB[:conn].execute(sql)
		DB[:conn].results_as_hash = true
		table_info.each  do |row|
			column_names << row["name"]
		end
		column_names.compact
	end

	self.column_names.each do |column_name|
		attr_accessor column_name.to_sym
	end

	def initialize(options={})
		options.each do |key, value|
			self.send("#{key}=", value)
		end
	end

	def table_name_for_insert
		self.class.table_name
	end

	def col_names_for_insert
		self.class.column_names.delete_if{|column_name| column_name == "id"}.join(", ")
	end

	def values_for_insert
		values = []
		self.class.column_names.each do |column_name|
			values << "'#{self.send(column_name)}'" unless send(column_name).nil?
		end
		values.join(", ")
	end

	def save
		sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
		DB[:conn].execute(sql)
		@id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
	end

	def self.find_by_name(name)
		sql = "SELECT * FROM #{table_name} WHERE name = '#{name}'"
		DB[:conn].execute(sql)
	end

	def self.find_by(attribute)
		sql = "SELECT * FROM #{table_name} WHERE #{attribute.keys[0].to_s} = '#{attribute.values[0]}'"
		DB[:conn].execute(sql)
	end
end