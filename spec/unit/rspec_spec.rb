require 'spec_helper'
require 'cleanroom/rspec'

describe 'RSpec matchers' do
  let(:klass) do
    Class.new do
      include Cleanroom

      def method1; end
      expose :method1

      def method2; end
    end
  end

  let(:instance) { klass.new }

  describe '#be_an_exposed_method_on' do
    context 'when given a class' do
      it 'is true when the method is exposed' do
        expect(:method1).to be_an_exposed_method_on(klass)
      end

      it 'is false when the method exists, but is not exposed' do
        expect(:method2).not_to be_an_exposed_method_on(klass)
      end

      it 'is false when the method is not exposed' do
        expect(:method3).not_to be_an_exposed_method_on(klass)
      end
    end

    context 'when given an instance' do
      it 'is true when the method is exposed' do
        expect(:method1).to be_an_exposed_method_on(instance)
      end

      it 'is false when the method exists, but is not exposed' do
        expect(:method2).not_to be_an_exposed_method_on(instance)
      end

      it 'is false when the method is not exposed' do
        expect(:method3).not_to be_an_exposed_method_on(instance)
      end
    end
  end

  describe '#have_exposed_method' do
    context 'when given a class' do
      it 'is true when the method is exposed' do
        expect(klass).to have_exposed_method(:method1)
      end

      it 'is false when the method exists, but is not exposed' do
        expect(klass).not_to have_exposed_method(:method2)
      end

      it 'is false when the method is not exposed' do
        expect(klass).not_to have_exposed_method(:method3)
      end
    end

    context 'when given an instance' do
      it 'is true when the method is exposed' do
        expect(instance).to have_exposed_method(:method1)
      end

      it 'is false when the method exists, but is not exposed' do
        expect(instance).not_to have_exposed_method(:method2)
      end

      it 'is false when the method is not exposed' do
        expect(instance).not_to have_exposed_method(:method3)
      end
    end
  end
end
