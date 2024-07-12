module Oroshi::DashboardHelper
  def dashboard_nav_link(text, path, active: false)
    # frame_target is the tab_name with dashboard_ in front of it and with underscores instead of -
    link_to text, path, class: "nav-link #{'active' if active}", role: 'tab',
                        aria: { controls: 'v-pills-dashboard-frame', selected: active.to_s },
                        data: {
                          bs_toggle: 'pill', bs_target: '#v-pills-dashboard-frame',
                          action: 'click->oroshi--dashboard#loadTabContent:passive'
                        }
  end

  def dashboard_tab_pane(path)
    content_tag :div, class: 'tab-pane card-body fade show active',
                      id: 'v-pills-dashboard-frame', role: 'tabpanel',
                      aria: { labelledby: 'v-pills-dashboard-frame-tab' }, tabindex: '0' do
      turbo_frame_tag 'dashboard_frame', src: path do
        render partial: 'oroshi/shared/spinner'
      end
    end
  end

  def dashboard_frame_tab_link(text, path, tab_name, active: false)
    link_to text, path, id: "nav-#{tab_name}-tab", class: "nav-link #{'active' if active}", role: 'tab',
                        aria: { controls: "nav-#{tab_name}", selected: active.to_s },
                        data: {
                          bs_toggle: 'tab', bs_target: "#nav-#{tab_name}",
                          action: 'click->oroshi--dashboard#reloadTabContent:passive',
                          reload_target: tab_name
                        },
                        type: 'button'
  end

  def dashboard_frame_tab_pane(tab_name, path, active: false)
    content_tag :div, class: "tab-pane fade #{'show active' if active}",
                      id: "nav-#{tab_name}", role: 'tabpanel',
                      aria: { labelledby: "nav-#{tab_name}-tab" }, tabindex: '0' do
      turbo_frame_tag tab_name, src: path do
        render partial: 'oroshi/shared/spinner'
      end
    end
  end

  def print_product_variation_cost_estimate(explanation)
    html = ''
    html << "<b>#{explanation['title']}</b><br>"
    html << "#{explanation['shipping_receptacle']}<br>"
    html << "#{explanation['packagings']}<br>"
    explanation['materials'].each do |material, data|
      html << "<i>#{material}の #{data[:text]}</i><br>（#{data[:work]}）<br>"
    end
    html.html_safe
  end
end
