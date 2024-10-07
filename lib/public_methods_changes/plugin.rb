# frozen_string_literal: true

module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  # @example Ensure people are well warned about merging on Mondays
  #
  #          my_plugin.warn_on_mondays
  #
  # @see  Sergey Pustovalov/danger-public_methods_changes
  # @tags monday, weekends, time, rattata
  #
  class DangerPublicMethodsChanges < Plugin
    # An attribute that you can read/write from your Dangerfile
    #
    # @return   [Array<String>]
    attr_accessor :ignore_files, :ignore_classes, :ignore_methods

    def initialize(dangerfile, ignore_files: [], ignore_classes: [], ignore_methods: [])
      super(dangerfile)

      @ignore_files = ignore_files
      @ignore_classes = ignore_classes
      @ignore_methods = ignore_methods
    end

    # A method that you can call from your Dangerfile
    # @return   [Array<String>]
    #
    def check_public_methods_changes
      base_public_methods = load_public_methods(git.base_commit)
      head_public_methods = load_public_methods(git.head_commit)

      base_public_methods.each do |class_name, methods|
        head_methods = head_public_methods[class_name] || Set.new

        removed_methods = methods - head_methods
        added_methods = head_methods - methods

        unless removed_methods.empty?
          fail "In class `#{class_name}` удалены публичные методы: #{removed_methods.to_a.join(', ')}"
        end

        unless added_methods.empty?
          warn "В классе `#{class_name}` добавлены публичные методы: #{added_methods.to_a.join(', ')}"
        end
      end
    end

    private

    def load_public_methods(commit)
      public_methods = {}

      commit.files.each do |file|
        next if ignore_files.include?(file)
        next unless file.end_with?(".rb")

        begin
          content = file.content
          load_file_content(content)
        rescue StandardError => e
          warn "Cannot load file `#{file.path}`: #{e.message}"
          next
        end

        ObjectSpace.each_object(Class) do |klass|
          class_name = klass.name
          next if ignore_classes.include?(class_name)

          public_methods[class_name] = klass.public_instance_methods - ignore_methods
        end
      end
    end

    def load_file_content(content)
      Object.new.instance_eval(content)
    end
  end
end
