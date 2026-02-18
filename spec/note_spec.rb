require 'spec_helper'

describe Note do
  it 'is a valid ActiveRecord model' do
    expect(Note.new).to be_a(ActiveRecord::Base)
  end

  it 'has a name attribute' do
    note = Note.new(name: 'Test Note')
    expect(note.name).to eq('Test Note')
  end

  it 'can be saved to the database' do
    note = Note.create(name: 'Sample Note')
    expect(note.persisted?).to be true
    expect(note.id).not_to be_nil
  end
end
