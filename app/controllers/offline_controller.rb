# The page Draft opens when it cannot reach home. The service worker keeps a copy and shows
# it in place of any page that fails to load. It holds no stories or sessions: the recent
# stories come from the phone's own storage, so the stored copy can never go stale.
class OfflineController < ApplicationController
  layout false

  def write; end
end
