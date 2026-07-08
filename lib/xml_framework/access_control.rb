module XmlFramework
  class AccessControl
    attr_reader :roles, :access_levels, :super_user

    def initialize(session_store)
      @roles = Array(session_store.session[:roles])
      @access_levels = Array(session_store.session[:access_levels])
      @super_user = session_store.session[:super_user] == true
    end

    def check_access(role: nil, access: nil)
      return true if role.blank? && access.blank?
      return true if super_user

      if role.present?
        role.split(',').map(&:strip).any? { |r| roles.include?(r) }
      elsif access.present?
        access_levels.include?(access.to_s)
      else
        true
      end
    end

    def can_view?(element)
      return true unless element.is_a?(Hash)

      check_access(role: element[:role], access: element[:access])
    end

    def filter_menu_items(items)
      items.filter_map do |item|
        next unless can_view?(item)

        filtered = item.dup
        if item[:children]&.any?
          filtered[:children] = filter_menu_items(item[:children])
          next if filtered[:children].empty? && item[:key].blank?
        end
        filtered
      end
    end
  end
end
