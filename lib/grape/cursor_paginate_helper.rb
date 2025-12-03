require 'grape'
require 'grape/api'
require 'active_record/cursor_paginator'

module Grape
  module CursorPaginateHelper
    extend Grape::API::Helpers

    DEFAULT_PAGE_SIZE = 10

    # Grape 3対応だが、Grape 2でも動作する（Ruby 3以降推奨）
    params :cursor_paginate do |**opts|
      opts.reverse_merge!(
        per_page: DEFAULT_PAGE_SIZE,
      )
      optional :per_page, type: Integer, default: opts[:per_page], desc: 'items per page'
      optional :cursor, type: String, default: nil,
                        desc: 'fetch items after or before this cursor'
      optional :direction, type: Symbol, default: ActiveRecord::CursorPaginator::DIRECTION_FORWARD, values: ActiveRecord::CursorPaginator::DIRECTIONS,
                           desc: 'paging direction :forward or :backward'
      optional :with_total, type: Boolean, default: false,
                            desc: 'if true, returns X-Total header'
    end

    def cursor_paginate(collection)
      page = ActiveRecord::CursorPaginator.new(collection,
                                               **[:per_page, :cursor, :direction].to_h {|k| [k, params[k]] })
      header 'X-Total',             page.total.to_s if params[:with_total]
      header 'X-Previous-Cursor',   page.start_cursor.to_s if page.previous_page?
      header 'X-Next-Cursor',       page.end_cursor.to_s if page.next_page?
      page.records
    end

    module DSLMethods
      # Grape 3対応だが、Grape 2でも動作する（Ruby 3以降推奨）
      def cursor_paginate(**opts)
        params do
          use(:cursor_paginate, **opts)
        end
      end
    end
    Grape::API::Instance.extend(DSLMethods)
  end
end
