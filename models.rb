class Models
  def self.generate what = :model
    require_models.each do |model|
      Array(what).each { |call_method| method(call_method)[model] }
    end
    true
  end

  def self.factory model
    factory_file_name = "spec/factories/#{model.name.underscore}.rb"
    unless File.exists?(factory_file_name)
      FileUtils.mkdir_p(File.dirname(factory_file_name))
      File.open(factory_file_name, "w") do |file|
        factory_for model, file
      end
    end
  end

  def self.factory_for model, file
    file << <<-EOT
FactoryBot.define do
  factory :#{model.name.underscore}, :class => '#{model.name}' do
#{factory_cols model}
  end
end
    EOT
  end

  def self.factory_cols model
    associations = model.reflections
    "".tap do |output_text|
      model.columns.each do |col|
        next if col.name == 'id'
        stripped_name = col.name.gsub(/_id$/, '').to_sym
        output_text << "\n    "
        assoc = associations[stripped_name]
        if assoc && [:has_one, :belongs_to].include?(assoc.macro)
          output_text << if assoc.options[:class_name]
                           "association :#{stripped_name.to_s}, factory: :#{assoc.options[:class_name].underscore}"
                         else
                           stripped_name.to_s
                         end
        else
          output_text << "#{preprocess_name col.name, col.type } #{factory_default_for(col.name, col.type)}"
        end
      end
    end
  end

  def self.preprocess_name name, type
    case name
    when /retry/
      "self.#{name}"
    when /e.*mail/, /name/
      if [:text, :string].include?(type)
        "sequence(:#{name})"
      else
        name
      end
    else
      name
    end
  end

  def self.factory_default_for name, type
    case type
    when :integer, :decimal
      "{1}"
    when :date
      "{Date.parse('2022-02-02)}"
    when :datetime
      "{DateTime.parse('2022-02-02 12:00:00')}"
    when :boolean
      "{true}"
    when :spatial
      "{nil}"
    else
      case name
      when /e.*mail/
        '{ |n| "test#{n}@example.com" }'
      when /name/
        '{ |n| "name#{n}" }'
      when /country/
        '{"GB"}'
      when /_ip$/
        '{"192.168.0.1"}'
      when /phone/
        '{"+44000000000"}'
      else
        '{"test123"}'
      end
    end
  end

  def self.model model
    test_file_name = "spec/models/#{model.name.underscore}_spec.rb"
    unless File.exists?(test_file_name)
      FileUtils.mkdir_p(File.dirname(test_file_name))
      File.open(test_file_name, "w") do |file|
        describe_model model, file
      end
    end
  end

  def self.describe_model model, file
    file << <<-EOT
require 'rails_helper'

describe #{model.name}, :type => :model do
  # let (:subject) { build :#{model.name.underscore} }
#{read_write_tests model}
#{associations model.reflections}
#{methods model}
end
    EOT
  end

  def self.read_write_tests model
    "  context \"validation\" do".tap do |output_text|
      model.validators.select { |val| val.is_a? ActiveModel::Validations::PresenceValidator }.map(&:attributes).
        flatten.each { |col| output_text << "\n    it { 次の値が入っていることを検証 :#{col} }" }
      model.validators.select { |val| !val.is_a? ActiveModel::Validations::PresenceValidator }.
        each { |col| output_text << "\n    it \"#{col.class.to_s.demodulize.underscore} test for #{col.attributes.map(&:to_sym).to_s}\"" }
    end << "\n  end"
  end

  def self.associations reflections
    "  context \"associations\" do".tap do |output_text|
      reflections.each_pair { |key, assoc| output_text << "\n    it { 値を検証 #{translate_assoc assoc.macro} :#{test_assoc_name assoc} }" }
    end << "\n  end"
  end

  def self.methods model
    "".tap do |output_text|
      instance = model.new
      (model.instance_methods(false) - model.columns.map(&:name).map(&:to_sym)).sort.each do |method|
        arity = instance.method(method).arity

        output_text <<
          "  context \"#{method}\" do\n" +
          "    it \"#{method} を実行し出力が正しいことを検証\" do\n" +
          "      subject.#{method} #{(1..arity).to_a.join(", ")}\n" +
          "    end\n" +
          "  end\n"
      end
    end
  end

  def self.translate_assoc macro
    macro.to_s.gsub(/belongs/, 'belong').gsub(/has/, 'have')
  end

  def self.test_assoc_name assoc
    case assoc.macro
    when /have_many/
      assoc.plural_name
    when /has_one/, /belongs_to/
      assoc.name
    else
      assoc.name
    end
  end

  class ModelDef
    attr_reader :file_name

    def initialize(file_name:)
      @file_name = file_name
    end

    def class_name
      @class_name ||= namespace.map(&:camelcase).join('::').constantize
    end

    private

    def required_file_name
      @required_file_name ||= file_name.sub('app/models/', '')[0..-4]
    end

    def namespace
      @namespace ||= begin
                       parts = required_file_name.split("/")
                       if parts.length > 1
                         parts[0..-1]
                       else
                         parts
                       end
                     end
    end
  end

  def self.require_models
    @model_list ||= [].tap do |model_list|
     Dir.glob('app/models/**/**').each do |file|
        next if File.directory?(file)|| !file.ends_with?('.rb') || file =~ %r{application_record}
        new_def = ModelDef.new(file_name: file)
        model_list << new_def.class_name
      end
    end
  end
end