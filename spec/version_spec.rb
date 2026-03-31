# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Spec do
  describe 'VERSION' do
    it 'is a version string' do
      expect(Legion::Spec::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end
end
