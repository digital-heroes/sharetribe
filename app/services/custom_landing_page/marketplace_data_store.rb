module CustomLandingPage
  module MarketplaceDataStore

    DEFAULT_COLOR = "4a90e2"

    module_function

    def marketplace_data(cid, locale)
      primary_color,
      twitter_handle,
      name_display_type = Community.where(id: cid)
                          .pluck(:custom_color1, :twitter_handle, :name_display_type)
                          .first

      name,
      slogan,
      description,
      search_placeholder,
      meta_title,
      meta_description,
      social_media_title,
      social_media_description = CommunityCustomization
                                 .where(community_id: cid, locale: locale)
                                 .pluck(:name, :slogan, :description, :search_placeholder,
                                        :meta_title, :meta_description,
                                        :social_media_title, :social_media_description)
                                 .first


      slogan             ||= I18n.t("common.default_community_slogan", locale: locale)
      description        ||= I18n.t("common.default_community_description", locale: locale)
      meta_description   = [meta_description, description, I18n.t("common.default_community_description", locale: locale)].find(&:present?)
      search_placeholder ||= I18n.t("landing_page.hero.search_placeholder", locale: locale)

      seo_service = SeoService.new(Community.find(cid))
      social_media_title ||= seo_service.title("#{name} - #{slogan}", :social, locale)
      social_media_description ||= seo_service.description(description, :social, locale)

      # In :keyword_and_location mode, we use fixed translation for location input.
      search_location_with_keyword_placeholder = I18n.t("landing_page.hero.search_location_placeholder", locale: locale)

      main_search = MarketplaceConfigurations
                    .where(community_id: cid)
                    .pluck(:main_search)
                    .first

      search_type =
        if main_search == "keyword_and_location"
          "keyword_and_location_search"
        elsif main_search == "location"
          "location_search"
        else
          "keyword_search"
        end

      color = primary_color.present? ? primary_color : DEFAULT_COLOR
      color_darken = ColorUtils.brightness(color, 85)

      slogan = split_long_words(seo_service.interpolate(slogan, locale))
      description = split_long_words(seo_service.interpolate(description, locale))
      title = [meta_title, "#{name} - #{slogan}"].find(&:present?)


      { "primary_color" => ColorUtils.css_to_rgb_array(color),
        "primary_color_darken" => ColorUtils.css_to_rgb_array(color_darken),
        "name" => name,
        "slogan" => slogan,
        "page_title" => seo_service.interpolate(title, locale),
        "description" => description,
        "search_type" => search_type,
        "search_placeholder" => search_placeholder,
        "search_location_with_keyword_placeholder" => search_location_with_keyword_placeholder,
        "twitter_handle" => twitter_handle,
        "name_display_type" => name_display_type,
        "social_media_title" => seo_service.interpolate(social_media_title, locale),
        "social_media_description" => seo_service.interpolate(social_media_description, locale),
        "meta_description" => seo_service.interpolate(meta_description, locale),
        "logo" => logo_image(cid)
      }
    end

    UNICODE_ZERO_WIDTH_SPACE = "\u200b"

    def split_long_words(value)
      value.to_s.gsub(/\S{18,}/){ |word| word.split(//).join(UNICODE_ZERO_WIDTH_SPACE) }
    end

    def logo_image(cid)
      community = Community.where(id: cid).first
      community && community.wide_logo.present? ? community.wide_logo.url(:header_highres) : nil
    end
  end
end
