# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Dutchie::RequireWritingConnection do
  subject(:cop) { described_class.new }

  context "when a write call is not wrapped in connected_to(role: :writing)" do
    it "registers an offense for create" do
      expect_offense(<<~RUBY)
        ReferralCode.create(code: code)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/RequireWritingConnection: Wrap this write in `connected_to(role: :writing)`. This code can be reached from a GET request, which ActiveRecord::Middleware::DatabaseSelector routes to a read replica, and an unwrapped write there will raise ActiveRecord::ReadOnlyError.
      RUBY
    end

    it "registers an offense for save!" do
      expect_offense(<<~RUBY)
        record.save!
        ^^^^^^^^^^^^ Dutchie/RequireWritingConnection: Wrap this write in `connected_to(role: :writing)`. This code can be reached from a GET request, which ActiveRecord::Middleware::DatabaseSelector routes to a read replica, and an unwrapped write there will raise ActiveRecord::ReadOnlyError.
      RUBY
    end

    it "registers an offense for touch" do
      expect_offense(<<~RUBY)
        plus_api_key.touch(:last_request_at)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dutchie/RequireWritingConnection: Wrap this write in `connected_to(role: :writing)`. This code can be reached from a GET request, which ActiveRecord::Middleware::DatabaseSelector routes to a read replica, and an unwrapped write there will raise ActiveRecord::ReadOnlyError.
      RUBY
    end
  end

  context "when the write call is wrapped in connected_to(role: :writing)" do
    it "does not register an offense with a do/end block" do
      expect_no_offenses(<<~RUBY)
        ApplicationRecord.connected_to(role: :writing) do
          ReferralCode.create(code: code)
        end
      RUBY
    end

    it "does not register an offense with a brace block" do
      expect_no_offenses(<<~RUBY)
        ApplicationRecord.connected_to(role: :writing) { create_unique_code }
      RUBY
    end

    it "does not register an offense when connected_to is called without an explicit receiver" do
      expect_no_offenses(<<~RUBY)
        connected_to(role: :writing) do
          record.save!
        end
      RUBY
    end
  end

  context "edge cases" do
    it "registers an offense for connected_to(role: :reading), since it doesn't force the writing role" do
      expect_offense(<<~RUBY)
        ApplicationRecord.connected_to(role: :reading) do
          record.save!
          ^^^^^^^^^^^^ Dutchie/RequireWritingConnection: Wrap this write in `connected_to(role: :writing)`. This code can be reached from a GET request, which ActiveRecord::Middleware::DatabaseSelector routes to a read replica, and an unwrapped write there will raise ActiveRecord::ReadOnlyError.
        end
      RUBY
    end

    it "does not register an offense for unrelated method calls" do
      expect_no_offenses(<<~RUBY)
        record.find_by(code: code)
      RUBY
    end
  end
end
