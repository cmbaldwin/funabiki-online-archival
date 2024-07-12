module Rakuten
  module Items
    # Rakuten Items API
    # https://webservice.rms.rakuten.co.jp/merchant-portal/view/ja/common/1-1_service_index/itemapi2/searchitem/
    
    def query_active_items
      get('/items/search')
    end
  end
end
