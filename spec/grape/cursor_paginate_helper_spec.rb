# frozen_string_literal: true

require 'spec_helper'

class FakeAPI < Grape::API
  helpers Grape::CursorPaginateHelper
  resource :fake do
    desc 'cursor_paginate'
    cursor_paginate per_page: 10
    get '/cursor_paginate' do
      present cursor_paginate(Post.order(:display_index)).map(&:attributes).to_json
    end

    desc 'with aliases'
    cursor_paginate per_page: 10
    get '/cursor_paginate_with_aliases' do
      present cursor_paginate(Post.select('posts.*, display_index as alias').order(:alias), aliases: { alias: 'display_index' }).map(&:attributes).to_json
    end
  end
end

RSpec.describe Grape::CursorPaginateHelper do
  include Rack::Test::Methods

  it 'has a version number' do
    expect(Grape::CursorPaginateHelper::VERSION).not_to be nil
  end

  let(:endpoint) { '/fake/cursor_paginate' }

  def app
    FakeAPI
  end

  before do
    Temping.teardown
    Temping.create(:post) do
      with_columns do |t|
        t.integer :display_index
      end
    end
  end

  let!(:post_count) { 6 }
  let(:relation) { Post.order(display_index: :desc) }

  before do
    (0...post_count).each do |i|
      Post.create(display_index: i)
    end
  end

  # テスト終了後に定義した定数を削除する
  after(:all) { Object.send :remove_const, :FakeAPI }

  context 'with total' do
    it 'returns X-Total header' do
      params =  {
        per_page: 2,
        with_total: true,
      }
      uri = "#{endpoint}?#{params.to_query}"
      get uri
      expect(last_response.headers['X-Total']).to eq post_count.to_s
      next_cursor = last_response.headers['X-Next-Cursor']
      expect(JSON.parse(Base64.strict_decode64(next_cursor))).to eq [{ 'display_index' => 1 }, { 'id' => 2 }]
      expect(last_response.status).to eq 200
      expect(JSON.parse(last_response.body).count).to eq 2
      expect(JSON.parse(last_response.body).last).to eq({ 'display_index' => 1, 'id' => 2 })
    end
  end

  context 'without total' do
    it 'does not return X-Total header' do
      params = {
        per_page: 2,
      }
      uri = "#{endpoint}?#{params.to_query}"
      get uri
      expect(last_response.headers['X-Total']).to eq nil
      next_cursor = last_response.headers['X-Next-Cursor']
      expect(JSON.parse(Base64.strict_decode64(next_cursor))).to eq [{ 'display_index' => 1 }, { 'id' => 2 }]
      expect(last_response.status).to eq 200
      items = JSON.parse(last_response.body)
      expect(items.count).to eq 2
      expect(items.last).to eq({ 'display_index' => 1, 'id' => 2 })
    end
  end

  context 'with cursor' do
    it 'returns X-Previous-Cursor header' do
      cursor = Base64.strict_encode64([{ 'display_index' => 1 }, { 'id' => 2 }].to_json)
      params = {
        per_page: 2,
        cursor: cursor,
      }
      uri = "#{endpoint}?#{params.to_query}"
      get uri
      expect(last_response.headers['X-Total']).to eq nil
      next_cursor = last_response.headers['X-Next-Cursor']
      expect(JSON.parse(Base64.strict_decode64(next_cursor))).to eq [{ 'display_index' => 3 }, { 'id' => 4 }]
      prev_cursor = last_response.headers['X-Previous-Cursor']
      expect(JSON.parse(Base64.strict_decode64(prev_cursor))).to eq [{ 'display_index' => 2 }, { 'id' => 3 }]
      expect(last_response.status).to eq 200
      items = JSON.parse(last_response.body)
      expect(items.count).to eq 2
      expect(items.last).to eq({ 'display_index' => 3, 'id' => 4 })
    end
  end

  context 'backward' do
    it 'returns X-Previous-Cursor header' do
      cursor = Base64.strict_encode64([{ 'display_index' => 2 }, { 'id' => 3 }].to_json)
      params = {
        per_page: 2,
        cursor: cursor,
        direction: :backward,
      }
      uri = "#{endpoint}?#{params.to_query}"
      get uri
      expect(last_response.headers['X-Total']).to eq nil
      next_cursor = last_response.headers['X-Next-Cursor']
      expect(JSON.parse(Base64.strict_decode64(next_cursor))).to eq [{ 'display_index' => 1 }, { 'id' => 2 }]
      prev_cursor = last_response.headers['X-Previous-Cursor']
      expect(prev_cursor).to eq nil
      expect(last_response.status).to eq 200
      items = JSON.parse(last_response.body)
      expect(items.count).to eq 2
      expect(items.last).to eq({ 'display_index' => 1, 'id' => 2 })
    end
  end

  context 'with aliases' do
    let(:endpoint) { '/fake/cursor_paginate_with_aliases' }
    it 'returns X-Total header' do
      params =  {
        per_page: 2,
        with_total: true,
      }
      uri = "#{endpoint}?#{params.to_query}"
      get uri
      expect(last_response.headers['X-Total']).to eq post_count.to_s
      next_cursor = last_response.headers['X-Next-Cursor']
      expect(JSON.parse(Base64.strict_decode64(next_cursor))).to eq [{ 'alias' => 1 }, { 'id' => 2 }]
      expect(last_response.status).to eq 200
      expect(JSON.parse(last_response.body).count).to eq 2
      expect(JSON.parse(last_response.body).last).to eq({ 'alias' => 1, 'id' => 2 })
    end
  end
end
